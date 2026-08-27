#Requires -Version 7.4
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Copies multiple users' OneDrive contents to individual folders in a
    SharePoint Online document library.

.DESCRIPTION
    - Copies top-level files and folders from each OneDrive Documents library.
    - Uses SharePoint Online server-side copy jobs.
    - Preserves subfolder structure.
    - Uses an absolute destination URL because the source OneDrive and
      destination SharePoint site use different hostnames.
    - Creates missing destination folders.
    - Continues after individual item or user failures.
    - Produces detailed and per-user CSV logs.
    - Does not delete source content.

.SETUP INSTRUCTIONS
    1. Install-Module PnP.PowerShell -Scope CurrentUser
    2. Import-Module PnP.PowerShell
    3. Register the application in your Azure AD tenant. Below is an example the command 
        to do that for the greenlab tenant. Adjust the -Tenant and -ApplicationName 
        parameters for your own tenant:
    4. Register-PnPEntraIDAppForInteractiveLogin `
        -ApplicationName "GreenLab PnP Migration" `
        -Tenant "gogreenlab.onmicrosoft.com"
    5. Copy the generated Application (client) ID and use it with the -ClientId parameter.
    6. Ensure the registered application has permissions: Sites.ReadWrite.All and User.Read.All. 
        These should be prompted during the first run of the application generation.
    7. Update the $MigrationMappings array with your source OneDrive URLs and destination site/library information.
    8. Run the script with the -ClientId parameter and optional flags as shown in the examples.

.EXAMPLE
    Test Beth Hood only:

    .\Copy-GreenLabOneDrives.ps1 `
        -ClientId "YOUR-CLIENT-ID" `
        -OnlyUser "Beth Hood" `
        -PersistLogin

.EXAMPLE
    Process every configured user:

    .\Copy-GreenLabOneDrives.ps1 `
        -ClientId "YOUR-CLIENT-ID" `
        -PersistLogin

.EXAMPLE
    Process every user and overwrite conflicting destination items:

    .\Copy-GreenLabOneDrives.ps1 `
        -ClientId "YOUR-CLIENT-ID" `
        -PersistLogin `
        -OverwriteExisting
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ClientId,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputFolder = ".\OneDriveMigrationLogs",

    [Parameter()]
    [string]$OnlyUser,

    [Parameter()]
    [switch]$OverwriteExisting,

    [Parameter()]
    [switch]$IgnoreVersionHistory,

    [Parameter()]
    [switch]$PersistLogin
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ===========================================================================
# Migration mappings
# ===========================================================================

$MigrationMappings = @(
    [pscustomobject]@{
        SourceOneDriveUrl  = "https://gogreenlab-my.sharepoint.com/personal/jhedges_greenlab_com"
        DestinationSiteUrl = "https://gogreenlab.sharepoint.com/sites/OnedriveFiles"
        DestinationLibrary = "Shared Documents"
        DestinationFolder  = "Jim Hedges"
    },
    [pscustomobject]@{
        SourceOneDriveUrl  = "https://gogreenlab-my.sharepoint.com/personal/kphipps_greenlab_com"
        DestinationSiteUrl = "https://gogreenlab.sharepoint.com/sites/OnedriveFiles"
        DestinationLibrary = "Shared Documents"
        DestinationFolder  = "Kelly Phipps"
    }
)

$SourceLibraryName = "Documents"

# ===========================================================================
# Helper functions
# ===========================================================================

function Write-Status {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )

    $color = switch ($Level) {
        "Info"    { "Cyan" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
    }

    $label = switch ($Level) {
        "Info"    { "INFO" }
        "Success" { "OK" }
        "Warning" { "WARN" }
        "Error"   { "ERROR" }
    }

    Write-Host (
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] " +
        "[$label] $Message"
    ) -ForegroundColor $color
}

function Connect-PnPSite {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$ApplicationId,

        [Parameter()]
        [switch]$UsePersistedLogin
    )

    $parameters = @{
        Url                = $Url
        ClientId           = $ApplicationId
        Interactive        = $true
        ReturnConnection   = $true
        ValidateConnection = $true
        ErrorAction        = "Stop"
    }

    if ($UsePersistedLogin) {
        $parameters.PersistLogin = $true
    }

    Connect-PnPOnline @parameters
}

function Get-AbsoluteDestinationFolderUrl {
    param(
        [Parameter(Mandatory)]
        [string]$SiteUrl,

        [Parameter(Mandatory)]
        [string]$Library,

        [Parameter(Mandatory)]
        [string]$Folder
    )

    $site = $SiteUrl.TrimEnd("/")
    $libraryPath = $Library.Trim("/")
    $folderPath = $Folder.Trim("/")

    return "$site/$libraryPath/$folderPath"
}

function Get-ItemName {
    param(
        [Parameter(Mandatory)]
        [object]$Item
    )

    if ($null -ne $Item.PSObject.Properties["Name"] -and
        -not [string]::IsNullOrWhiteSpace([string]$Item.Name)) {

        return [string]$Item.Name
    }

    if ($null -ne $Item.PSObject.Properties["FileLeafRef"] -and
        -not [string]::IsNullOrWhiteSpace([string]$Item.FileLeafRef)) {

        return [string]$Item.FileLeafRef
    }

    if ($null -ne $Item.PSObject.Properties["ServerRelativeUrl"]) {
        return Split-Path `
            -Path ([string]$Item.ServerRelativeUrl) `
            -Leaf
    }

    return "Unknown item"
}

function Get-ItemType {
    param(
        [Parameter(Mandatory)]
        [object]$Item
    )

    if ($null -ne $Item.PSObject.Properties["FileSystemObjectType"]) {
        if ([string]$Item.FileSystemObjectType -eq "Folder") {
            return "Folder"
        }

        return "File"
    }

    if ($Item.GetType().Name -eq "Folder") {
        return "Folder"
    }

    if ($Item.GetType().Name -eq "File") {
        return "File"
    }

    return "Unknown"
}

function Get-ItemServerRelativeUrl {
    param(
        [Parameter(Mandatory)]
        [object]$Item
    )

    if ($null -ne $Item.PSObject.Properties["ServerRelativeUrl"] -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$Item.ServerRelativeUrl
        )) {

        return [string]$Item.ServerRelativeUrl
    }

    if ($null -ne $Item.PSObject.Properties["FileRef"] -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$Item.FileRef
        )) {

        return [string]$Item.FileRef
    }

    throw "Could not determine the source server-relative URL."
}

function Export-MigrationLogs {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IList]$DetailRecords,

        [Parameter(Mandatory)]
        [System.Collections.IList]$SummaryRecords,

        [Parameter(Mandatory)]
        [string]$DetailPath,

        [Parameter(Mandatory)]
        [string]$SummaryPath
    )

    if ($DetailRecords.Count -gt 0) {
        $DetailRecords |
            Export-Csv `
                -Path $DetailPath `
                -NoTypeInformation `
                -Encoding UTF8
    }

    if ($SummaryRecords.Count -gt 0) {
        $SummaryRecords |
            Export-Csv `
                -Path $SummaryPath `
                -NoTypeInformation `
                -Encoding UTF8
    }
}

# ===========================================================================
# Prepare mappings and logs
# ===========================================================================

if (-not [string]::IsNullOrWhiteSpace($OnlyUser)) {
    $MigrationMappings = @(
        $MigrationMappings |
            Where-Object {
                $_.DestinationFolder -eq $OnlyUser
            }
    )

    if ($MigrationMappings.Count -eq 0) {
        throw "No migration mapping was found for '$OnlyUser'."
    }
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

New-Item `
    -Path $OutputFolder `
    -ItemType Directory `
    -Force |
    Out-Null

$detailLogPath = Join-Path `
    -Path $OutputFolder `
    -ChildPath "OneDrive-Copy-Detail-$timestamp.csv"

$summaryLogPath = Join-Path `
    -Path $OutputFolder `
    -ChildPath "OneDrive-Copy-Summary-$timestamp.csv"

$detailResults = [System.Collections.Generic.List[object]]::new()
$summaryResults = [System.Collections.Generic.List[object]]::new()

Write-Status "Mappings to process: $($MigrationMappings.Count)"
Write-Status "Detail log: $detailLogPath"
Write-Status "Summary log: $summaryLogPath"

if ($OverwriteExisting) {
    Write-Status `
        -Message "Existing destination items may be overwritten." `
        -Level Warning
}

if ($IgnoreVersionHistory) {
    Write-Status `
        -Message "Only the latest version of each file will be copied." `
        -Level Warning
}

# ===========================================================================
# Connect to each unique destination site
# ===========================================================================

$destinationConnections = @{}

$uniqueDestinationSites = @(
    $MigrationMappings |
        Select-Object `
            -ExpandProperty DestinationSiteUrl `
            -Unique
)

foreach ($destinationSiteUrl in $uniqueDestinationSites) {
    Write-Status "Connecting to destination: $destinationSiteUrl"

    $destinationConnections[$destinationSiteUrl] = Connect-PnPSite `
        -Url $destinationSiteUrl `
        -ApplicationId $ClientId `
        -UsePersistedLogin:$PersistLogin

    Write-Status `
        -Message "Connected to destination site." `
        -Level Success
}

# ===========================================================================
# Process each user
# ===========================================================================

$mappingNumber = 0

foreach ($mapping in $MigrationMappings) {
    $mappingNumber++
    $userStarted = Get-Date

    $sourceConnection = $null
    $sourceItemCount = 0
    $successfulItems = 0
    $failedItems = 0
    $userStatus = "Pending"
    $userError = $null

    Write-Host ""
    Write-Host ("=" * 78) -ForegroundColor DarkGray

    Write-Status (
        "[$mappingNumber/$($MigrationMappings.Count)] " +
        "Processing $($mapping.DestinationFolder)"
    )

    try {
        $destinationConnection =
            $destinationConnections[$mapping.DestinationSiteUrl]

        if ($null -eq $destinationConnection) {
            throw "No destination connection is available."
        }

        # Validate destination library.
        $destinationList = Get-PnPList `
            -Identity $mapping.DestinationLibrary `
            -Connection $destinationConnection `
            -ErrorAction Stop

        if ($null -eq $destinationList) {
            throw (
                "Destination library '$($mapping.DestinationLibrary)' " +
                "was not found."
            )
        }

        # Create the destination folder using the destination connection.
        $destinationSiteRelativePath = (
            "$($mapping.DestinationLibrary.Trim('/'))/" +
            "$($mapping.DestinationFolder.Trim('/'))"
        )

        Write-Status (
            "Ensuring destination folder exists: " +
            $destinationSiteRelativePath
        )

        Resolve-PnPFolder `
            -SiteRelativePath $destinationSiteRelativePath `
            -Connection $destinationConnection `
            -ErrorAction Stop |
            Out-Null

        # IMPORTANT:
        # Copy-PnPFile is executed using the source OneDrive connection.
        # The target must therefore be an absolute URL when crossing from
        # gogreenlab-my.sharepoint.com to gogreenlab.sharepoint.com.
        $destinationAbsoluteUrl =
            Get-AbsoluteDestinationFolderUrl `
                -SiteUrl $mapping.DestinationSiteUrl `
                -Library $mapping.DestinationLibrary `
                -Folder $mapping.DestinationFolder

        $expectedDestinationHost =
            ([uri]$mapping.DestinationSiteUrl).Host

        $actualDestinationHost =
            ([uri]$destinationAbsoluteUrl).Host

        if ($actualDestinationHost -ne $expectedDestinationHost) {
            throw (
                "Destination hostname mismatch. Expected " +
                "'$expectedDestinationHost', generated " +
                "'$actualDestinationHost'."
            )
        }

        Write-Status "Copy destination: $destinationAbsoluteUrl"

        # Connect to source OneDrive.
        Write-Status (
            "Connecting to source: " +
            $mapping.SourceOneDriveUrl
        )

        $sourceConnection = Connect-PnPSite `
            -Url $mapping.SourceOneDriveUrl `
            -ApplicationId $ClientId `
            -UsePersistedLogin:$PersistLogin

        Write-Status `
            -Message "Connected to source OneDrive." `
            -Level Success

        # Validate source library.
        $sourceList = Get-PnPList `
            -Identity $SourceLibraryName `
            -Connection $sourceConnection `
            -ErrorAction Stop

        if ($null -eq $sourceList) {
            throw (
                "Source library '$SourceLibraryName' was not found."
            )
        }

        # Retrieve only the top-level files and folders.
        Write-Status "Reading top-level OneDrive content."

        $sourceItems = @(
            Get-PnPFolderItem `
                -FolderSiteRelativeUrl $SourceLibraryName `
                -Connection $sourceConnection `
                -ErrorAction Stop |
                Where-Object {
                    (Get-ItemName -Item $_) -ne "Forms"
                }
        )

        $sourceItemCount = $sourceItems.Count

        if ($sourceItemCount -eq 0) {
            $userStatus = "Empty"

            Write-Status `
                -Message "The source Documents library is empty." `
                -Level Warning

            continue
        }

        Write-Status `
            -Message "Found $sourceItemCount top-level items." `
            -Level Success

        $itemNumber = 0

        foreach ($item in $sourceItems) {
            $itemNumber++
            $itemStarted = Get-Date

            $itemName = Get-ItemName -Item $item
            $itemType = Get-ItemType -Item $item
            $sourceServerRelativeUrl =
                Get-ItemServerRelativeUrl -Item $item

            Write-Status (
                "[$itemNumber/$sourceItemCount] Copying " +
                "$itemType '$itemName'"
            )

            try {
                $copyParameters = @{
                    SourceUrl   = $sourceServerRelativeUrl
                    TargetUrl   = $destinationAbsoluteUrl
                    Force       = $true
                    NoWait      = $true
                    Connection  = $sourceConnection
                    ErrorAction = "Stop"
                }

                if ($OverwriteExisting) {
                    $copyParameters.Overwrite = $true
                }

                if ($IgnoreVersionHistory) {
                    $copyParameters.IgnoreVersionHistory = $true
                }

                $copyJob = Copy-PnPFile @copyParameters

                if ($null -eq $copyJob) {
                    throw "Copy-PnPFile did not return a job object."
                }

                Write-Status "Copy job submitted; waiting for completion."

                # Receive-PnPCopyMoveJobStatus uses the job object itself.
                # It does not need a separate -Connection parameter.
                $jobStatus = Receive-PnPCopyMoveJobStatus `
                    -Job $copyJob `
                    -Wait `
                    -Connection $sourceConnection `
                    -ErrorAction Stop

                if ($null -eq $jobStatus) {
                    throw "The copy job returned no final status."
                }

                if ([int]$jobStatus.JobState -ne 0) {
                    $jobDetails = $null

                    foreach ($propertyName in @(
                        "ErrorMessage",
                        "Logs",
                        "JobState"
                    )) {
                        $property =
                            $jobStatus.PSObject.Properties[$propertyName]

                        if ($null -ne $property -and
                            $null -ne $property.Value) {

                            $jobDetails = [string]$property.Value
                            break
                        }
                    }

                    throw (
                        "Copy job ended in state " +
                        "$($jobStatus.JobState). Details: $jobDetails"
                    )
                }

                $itemEnded = Get-Date
                $successfulItems++

                $detailResults.Add([pscustomobject]@{
                    UserFolder         = $mapping.DestinationFolder
                    SourceOneDriveUrl   = $mapping.SourceOneDriveUrl
                    DestinationSiteUrl  = $mapping.DestinationSiteUrl
                    DestinationLibrary = $mapping.DestinationLibrary
                    DestinationFolder  = $mapping.DestinationFolder
                    ItemName           = $itemName
                    ItemType           = $itemType
                    SourceUrl           = $sourceServerRelativeUrl
                    DestinationUrl      = $destinationAbsoluteUrl
                    Status              = "Success"
                    JobState            = [int]$jobStatus.JobState
                    Started             = $itemStarted
                    Ended               = $itemEnded
                    DurationSeconds     = [math]::Round(
                        ($itemEnded - $itemStarted).TotalSeconds,
                        2
                    )
                    Error               = $null
                })

                Write-Status `
                    -Message "Copied '$itemName' successfully." `
                    -Level Success
            }
            catch {
                $itemEnded = Get-Date
                $failedItems++

                $detailResults.Add([pscustomobject]@{
                    UserFolder         = $mapping.DestinationFolder
                    SourceOneDriveUrl   = $mapping.SourceOneDriveUrl
                    DestinationSiteUrl  = $mapping.DestinationSiteUrl
                    DestinationLibrary = $mapping.DestinationLibrary
                    DestinationFolder  = $mapping.DestinationFolder
                    ItemName           = $itemName
                    ItemType           = $itemType
                    SourceUrl           = $sourceServerRelativeUrl
                    DestinationUrl      = $destinationAbsoluteUrl
                    Status              = "Failed"
                    JobState            = $null
                    Started             = $itemStarted
                    Ended               = $itemEnded
                    DurationSeconds     = [math]::Round(
                        ($itemEnded - $itemStarted).TotalSeconds,
                        2
                    )
                    Error               = $_.Exception.Message
                })

                Write-Status `
                    -Message (
                        "Failed to copy '$itemName': " +
                        $_.Exception.Message
                    ) `
                    -Level Error
            }
            finally {
                Export-MigrationLogs `
                    -DetailRecords $detailResults `
                    -SummaryRecords $summaryResults `
                    -DetailPath $detailLogPath `
                    -SummaryPath $summaryLogPath
            }
        }

        if ($failedItems -eq 0) {
            $userStatus = "Success"
        }
        elseif ($successfulItems -gt 0) {
            $userStatus = "Partial Success"
        }
        else {
            $userStatus = "Failed"
        }
    }
    catch {
        $userStatus = "Failed"
        $userError = $_.Exception.Message

        Write-Status `
            -Message (
                "Migration failed for " +
                "'$($mapping.DestinationFolder)': $userError"
            ) `
            -Level Error
    }
    finally {
        $userEnded = Get-Date

        $summaryResults.Add([pscustomobject]@{
            UserFolder         = $mapping.DestinationFolder
            SourceOneDriveUrl   = $mapping.SourceOneDriveUrl
            DestinationSiteUrl  = $mapping.DestinationSiteUrl
            DestinationLibrary = $mapping.DestinationLibrary
            DestinationFolder  = $mapping.DestinationFolder
            SourceItemCount     = $sourceItemCount
            SuccessfulItems     = $successfulItems
            FailedItems         = $failedItems
            Status              = $userStatus
            Started             = $userStarted
            Ended               = $userEnded
            DurationMinutes     = [math]::Round(
                ($userEnded - $userStarted).TotalMinutes,
                2
            )
            Error               = $userError
        })

        Export-MigrationLogs `
            -DetailRecords $detailResults `
            -SummaryRecords $summaryResults `
            -DetailPath $detailLogPath `
            -SummaryPath $summaryLogPath

        Write-Status (
            "Completed $($mapping.DestinationFolder): " +
            "status=$userStatus; successful=$successfulItems; " +
            "failed=$failedItems"
        ) -Level $(if ($userStatus -eq "Success") {
            "Success"
        }
        elseif ($userStatus -eq "Empty") {
            "Warning"
        }
        else {
            "Error"
        })
    }
}

# ===========================================================================
# Final totals
# ===========================================================================

$totalSuccessfulItems = @(
    $detailResults |
        Where-Object Status -eq "Success"
).Count

$totalFailedItems = @(
    $detailResults |
        Where-Object Status -eq "Failed"
).Count

$successfulUsers = @(
    $summaryResults |
        Where-Object Status -eq "Success"
).Count

$partialUsers = @(
    $summaryResults |
        Where-Object Status -eq "Partial Success"
).Count

$failedUsers = @(
    $summaryResults |
        Where-Object Status -eq "Failed"
).Count

$emptyUsers = @(
    $summaryResults |
        Where-Object Status -eq "Empty"
).Count

Write-Host ""
Write-Host ("=" * 78) -ForegroundColor DarkGray

Write-Status "Migration processing complete."
Write-Status `
    -Message "Successful users: $successfulUsers" `
    -Level Success

Write-Status `
    -Message "Partially successful users: $partialUsers" `
    -Level $(if ($partialUsers -gt 0) {
        "Warning"
    }
    else {
        "Success"
    })

Write-Status `
    -Message "Failed users: $failedUsers" `
    -Level $(if ($failedUsers -gt 0) {
        "Error"
    }
    else {
        "Success"
    })

Write-Status `
    -Message "Empty OneDrives: $emptyUsers" `
    -Level $(if ($emptyUsers -gt 0) {
        "Warning"
    }
    else {
        "Success"
    })

Write-Status `
    -Message "Successfully copied top-level items: $totalSuccessfulItems" `
    -Level Success

Write-Status `
    -Message "Failed top-level items: $totalFailedItems" `
    -Level $(if ($totalFailedItems -gt 0) {
        "Error"
    }
    else {
        "Success"
    })

Write-Status "Detail log: $detailLogPath"
Write-Status "Summary log: $summaryLogPath"