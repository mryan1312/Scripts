### Processes daily firewall reports and outputs a report with callouts where blocked sessions exceed a defined threshold ###
### For Questions/Comments/Suggestions: madams@kalmersolutions.com

# Modify these variables to suit your environment. The Regex will need to be set to catch the different interface names in the reports.
$DataPath = "\Users\madams\Kalmer Investments LLC\Fortinet - Daily Reports"
$CalloutThreshhold = 100
$ReportPath = "\Users\madams\Downloads\"+"$(Get-Date -Format "MM-dd-yyy")"+".txt"
$WANBlockRegex = '.+Top 50 Source IP Blocked on (lan3)?(Port1 \(WAN\))?(WAN)?(WAN[1-3])?( ATT MIS)?(Spectrum \(wan\))?(dmz)?(Fidelity \(wan2\))?###'
$PortBlockRegex = '.+Top 50 Source IP Blocked on (lan3)?(Port1 \(WAN\))?(WAN)?(WAN[1-3])?( ATT MIS)?(Spectrum \(wan\))?(dmz)?(Fidelity \(wan2\))? by (PORT)?(Port)?###'

# Separate functions, because the output was not jiving 
function Get-WanBlocks($csvinput) {
    $csvPath = $csvinput    
    # Read the file line-by-line
    $lines = Get-Content -Path $csvPath | ForEach-Object { $_ -replace '"', '' }

    # Initialize variables
    $currentSection = $null
    $data = @{}

    foreach ($line in $lines) {
        # Check for section headers
        if ($line -match '###(.+)###') {
            $currentSection = $matches[0]
            $data[$currentSection] = @()
            continue
        }

        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # Process data lines
        if ($currentSection -and $line -notmatch '###.+###') {
            $data[$currentSection] += $line
        }
    }

    # Parse each section into objects
    foreach ($section in $data.Keys) {
        if ($section -match $WANBlockRegex ) {
            #Write-Output "Processing $section..."
            $WANheader, $WANrows = $data[$section][0], $data[$section][1..($data[$section].Count - 1)]
            $WANBlockedObjects = $WANrows | ConvertFrom-Csv -Header ($WANheader -split ',')
        }
    }
    return $WANBlockedObjects
}
function Get-PortBlocks($csvinput) {
    $csvPath = $csvinput    

    # Read the file line-by-line
    $lines = Get-Content -Path $csvPath | ForEach-Object { $_ -replace '"', '' }

    # Initialize variables
    $currentSection = $null
    $data = @{}

    foreach ($line in $lines) {
        # Check for section headers (e.g., [Section1])
        if ($line -match '###(.+)###') {
            $currentSection = $matches[0]
            $data[$currentSection] = @()
            continue
        }

        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        # Process data lines
        if ($currentSection -and $line -notmatch '###.+###') {
            $data[$currentSection] += $line
        }
    }

    # Parse each section into objects
    foreach ($section in $data.Keys) {
        if ($section -match $PortBlockRegex) {
            #Write-Output "Processing $section..."
            $Portheader, $Portrows = $data[$section][0], $data[$section][1..($data[$section].Count - 1)]
            $BlockedPortObjects = $Portrows | ConvertFrom-Csv -Header ($Portheader -split ',')
        }
    }
    return $BlockedPortObjects
}

# Enumerating csv files in the Data Path
$DataFiles = Get-ChildItem $DataPath | Where-Object { $_.Name -like "*.csv" }
# Iterate through each file found
ForEach ($file in $DataFiles) {
    $WBOCallouts = @()
    $PBOCallouts = @()
    $WANBlockedObjects = $null
    # Setting up formatting for the output report
    "#########################" | Out-File -FilePath $reportPath -Append
    "Processing: "+$file.baseName | Out-File -FilePath $reportPath -Append
    "" | Out-File -FilePath $reportPath -Append
    $WANBlockedObjects = Get-WANBlocks($file.FullName)
    #Initialize array to store callouts of interest
    if ($null -ne $WANBlockedObjects) {
        foreach ($row in $WANBlockedObjects) {
            if ([int]$row.blocked_sessions -ge $CalloutThreshhold) {
                $WBOCallouts += [PSCustomObject]@{"ID"=$row.ID; "Src IP"=$row.srcip; "Blocks"=$row.blocked_sessions; "Resolve"=$(Try {[System.Net.Dns]::GetHostEntry($row.srcip).HostName} Catch {"NXDOMAIN"})}
            }
        }
    }
    else {"!!! Did not find any applicable interfaces in this report !!!" | Out-File -FilePath $ReportPath -Append}
    # What to do if callout array has data
    If ($WBOCallouts.length -gt 0) {
        "Found the following callouts:" | Out-File -FilePath $reportPath -Append
        $WBOCallouts | Format-Table | Out-File -FilePath $reportPath -Append
        $BlockedPortObjects = Get-PortBlocks($file.FullName)
        # iterate through each item and find matching source IPs in the blocked by port section
        foreach ($BPOitem in $WBOCallouts) {
            foreach ($PBOitem in $BlockedPortObjects) {
                if ($PBOitem.srcip -eq $BPOitem."Src IP") {
                    $PBOCallouts += [PSCustomObject]@{"ID"=$PBOitem.ID; "Src IP"=$PBOitem.srcip; "Dest IP"=$PBOitem.destip; "Port"=$PBOitem.port; "Blocks"=$PBOitem.blocked_sessions}
                }
            }
        }
        "Also Found these similar blocks by port:" | Out-File -FilePath $reportPath -Append
        $PBOCallouts | Format-Table | Out-File -FilePath $reportPath -Append
        "" | Out-File -FilePath $reportPath -Append
    }
    else {
        "No Callouts for this report." | Out-File -FilePath $reportPath -Append
        "" | Out-File -FilePath $ReportPath -Append
    }
}
