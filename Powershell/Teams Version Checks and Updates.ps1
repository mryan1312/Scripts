$UserFolders = Get-ChildItem -Path "C:\Users" -directory
foreach ($Folder in $UserFolders) {
    $LocTeamsPath = Join-Path $Folder.FullName "AppData\Local\Microsoft\Teams\current\Teams.exe"
    if (Test-Path $LocTeamsPath) {
        [Version]$teamsVersionCheck = (Get-Item $LocTeamsPath).VersionInfo.FileVersion
    }
    [Version]$cveFixedVer = "1.6.0.18681"
    if ($teamsVersionCheck -lt $cveFixedVer) {
        $WAPPPath = Join-Path $Folder.FullName "AppData\Local\Microsoft\WindowsApps\ms-teams.exe"
        $appDatPath = Join-Path $Folder.FullName "AppData\Roaming\Microsoft\Teams"
        $LocAppDatPath = Join-Path $Folder.FullName "AppData\Local\Microsoft\Teams"
        if (Test-Path $WAPPPath) {
            Remove-Item -Path $WAPPPath -Force
            Write-Host "Deleted $WAPPPath for " $Folder.FullName
        }
        if (Test-Path $appDatPath) {
            Remove-Item -Path $appDatPath -Recurse -Include *.* -Force
            Write-Host "Deleted $appDatPath for " $Folder.FullName
        }
        if (Test-Path $LocTeamsPath) {
            Remove-Item -Path $LocAppDatPath -Recurse -Include *.* -Force
            Write-Host "Deleted $LocAppDatPath for " $Folder.FullName
        }
    }
}
# Check for machine-wide installer and update if necessary
$contentFilter = '.*(classic-teams-app-version).*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*\n.*[0-9]{4}.*\n.*\n.*">(\d\.[0-9]{2}\.[0-9]{2}\.[0-9]{4})'
$versionURL = "https://learn.microsoft.com/en-us/officeupdates/teams-app-versioning"
$htmlRaw = $(Invoke-WebRequest -usebasicparsing -URI $versionURL).Content
$contentMatch = $htmlRaw | Select-String -Pattern "$contentFilter"
[Version]$versionNumber = $contentMatch.Matches.Groups[2].Value
$teamsExe = "C:\Program Files (x86)\Teams Installer\Teams.exe"
if (Test-Path $teamsExe) {
    [Version]$exeVersion = (Get-Item $teamsExe).VersionInfo.FileVersion
    if ($exeVersion -lt $versionNumber) {
        Invoke-WebRequest -Uri "https://aka.ms/teams64bitmsi" -outFile "C:\Users\Public\Downloads\teams.msi"
    }
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Get-Package -name "Teams Machine-Wide Installer" | Uninstall-Package
    msiexec /i "C:\Users\Public\Downloads\teams.msi"
}

if (get-appxpackage *teams*) { 
    taskkill /im "ms-teams.exe" /f
    get-appxpackage -allusers *teams* | remove-appxpackage -allusers
    remove-item -Path "C:\Program Files\WindowsApps\MSTeams_*_x64__8wekyb3d8bbwe\*" -Recurse -Force
}
