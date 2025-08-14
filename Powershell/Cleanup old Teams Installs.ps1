$currentDate = Get-Date
# Get list of all domain user profiles and iterate through them
$userList = Get-WMIObject Win32_UserAccount <#-filter "LocalAccount=False"#> | Select-Object -ExpandProperty Name
foreach ($user in $userList) {
    Write-Host "#################################################"
    Write-Host "Processing user "$user
    $userData = net user $user /domain
    $userSID = get-WmiObject -Query "Select * from Win32_UserAccount where name='$user'" | Select-Object -ExpandProperty SID
    # Try to determine user profile path
    try {
        $profilePath = Get-CimInstance -Query "Select * from Win32_UserProfile where SID='$userSID'" | Select-Object -ExpandProperty LocalPath
        Write-Host "Profile path found at "$profilePath
    }
    catch {
        $profilePath = $null
    }
    # If user profile path exists, continue processing
    if ($null -ne $profilePath) {
        try {
            # Slicing userdata variable as it is one big string rather than an object 
            $lastLogon = [datetime]$userData[20].Substring(29,9)
            Write-Host "Last Logon "$lastLogon
        }
        catch {
            # If account has never logged in, set arbitrary date.
            $lastLogon = [datetime]::new(2025, 1, 1)
        }
        # Check if account last login is greater than 30 days, and continue processing
        if (($currentDate - $lastLogon).Days -gt 30) {
            Write-Host "Profile is stale. Attempting Teams removal."
            $WAPPPath = Join-Path $profilePath "AppData\Local\Microsoft\WindowsApps\ms-teams.exe"
            $appDatPath = Join-Path $profilePath "AppData\Roaming\Microsoft\Teams"
            $LocAppDatPath = Join-Path $profilePath "AppData\Local\Microsoft\Teams"
            # Delete the file if it exists
            if (Test-Path $WAPPPath) {
                try {
                    Remove-Item -Path $WAPPPath -Force
                    Write-Host "Deleted $WAPPPath for $user"
                } catch {
                    Write-Warning "Failed to delete $WAPPPath for $user"
                }
            } else {
                Write-Host "File $WAPPPath does not exist for $user"
            }
            if (Test-Path $appDatPath) {
                try {
                    Remove-Item -Path $appDatPath -Recurse -Include *.* -Force
                    Write-Host "Deleted $appDatPath for $user"
                } catch {
                    Write-Warning "Failed to delete $appDatPath for $user"
                }
            } else {
                Write-Host "File $appDatPath does not exist for $user"
            }
            if (Test-Path $LocAppDatPath) {
                try {
                    Remove-Item -Path $LocAppDatPath -Recurse -Include *.* -Force
                    Write-Host "Deleted $LocAppDatPath for $user"
                } catch {
                    Write-Warning "Failed to delete $LocAppDatPath for $user"
                }
            } else {
                Write-Host "File $LocAppDatPath does not exist for $user"
            }
        }
    }
    else {
        Write-Host "User $user does not have a local profile path."
    }
}
