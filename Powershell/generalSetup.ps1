# Script will get a list of software to install for user. Script will generate an install script to download and install the selected software directly from vendors.  
# Script will verify installs and give user a log of succeeds / fails at the end. 
# This will be company independant with generic software commonly used.

# Variable initialization
$toInstall = @{}
$appCount = 0
$appSuccess = 0
$appFails = @()
$appList = Import-Csv "SoftwareSources.csv" | Group-Object -AsHashTable -Property ID
$workingDirectory = "c:\general install\"
$logFile = $workingDirectory+"Install Log.txt"

# Create working directory
New-Item -Path "c:\" -Name "general install" -ItemType "directory"
New-Item -Path $workingDirectory -Name "Install Log.txt" -ItemType "file" -Value "Starting Install: "#+Get-Date

# Get user install requests
Write-Host "Available applications:`n"
Write-Host $appList.keys
$Choosing = $true
While ($choosing -eq $true) {
    $selection = Read-Host "Please enter a selection"
    if ($selection -in $appList.keys) {
        $toInstall[$selection] = $appList.$selection
        $continue = Read-Host "Continue? y/n"
        if ($continue -eq "y"){
            continue
        }
        if ($continue -eq "n") {
            $choosing = $false
        }

    }
    else {
        Write-Host "Not a valid selection."
        continue 
    }
}


# Iterate through requested installs
for (each in $toInstall) {

}
# Cleanup working directory

# Report outcomes
Write-Host "Successfully installed "+$appSuccess+" out of "+$appCount+" applications."
Out-File -Append -FilePath $logFile "Successfully installed "+$appSuccess+" out of "+$appCount+" applications."
if ($appSuccess -lt $appCount) {
    Write-Host "Some installs have failed:"
    Write-Host $appFails
    Out-File -Append -FilePath $logFile "Some installs have failed:"
    Out-File -Append -FilePath $logFile $appFails
}