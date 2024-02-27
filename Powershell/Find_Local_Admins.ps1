# Use adsi searcher to search for all computers in AD
$AD = [adsisearcher]"objectcategory=computer"
$Computers = $AD.FindAll()
# get the computer names to generate a target list
$TargetList = @($Computers.Properties.name)
$FailedList = @()
$FailedText = "The following hosts failed to return any value and should be checked manually:"
$TargetCount = $TargetList.Length
# Need to update the following to work with your domain
$DomainName = "kalmer.local"
$AdminCred = "ksadmin"
$BlockBreak = "=============================="
$CheckCount = 0
$FilePath = "Result.txt"
Out-File -FilePath $FilePath
$ErrorActionPreference= 'silentlycontinue'
$DomainCredentials = Get-Credential $DomainName\$AdminCred

$BlockBreak | Out-File -Append -FilePath $FilePath
for($I = 0; $I -lt $TargetCount+1; $I++ ) {
    $OuterLoopProgressParameters = @{
        Activity         = 'Checking Local Admins'
        Status           = 'Progress->'
        PercentComplete  = ($I / ($TargetCount+1)) * 100
        CurrentOperation = 'Please Wait'

    }
    Write-Progress @OuterLoopProgressParameters
    $ResultObject = $TargetList | Select-Object -Index $checkCount
    #Write-Host $ResultObject 
    $MemberList = Invoke-Command -ComputerName $ResultObject -Credential $DomainCredentials -ScriptBlock { (net localgroup administrators).where({$_ -match '-{79}'},'skipuntil') -notmatch '-{79}|The command completed' }
    if ($null -ne $MemberList) {
        $ResultObject | Out-File -Append -FilePath $FilePath
        $MemberList | Out-File -Append -FilePath $FilePath
        $BlockBreak | Out-File -Append -FilePath $FilePath
    }
    else {
        # Currently not working. Object is not being added to the array, leading to empty array at script finish
        $FailedList.Add($ResultObject.ToString())
    }
    $MemberList = ""
    $CheckCount++
        if ($CheckCount -eq ($TargetCount)) {
        $BlockBreak | Out-File -Append -FilePath $FilePath
        $FailedText | Out-file -Append -FilePath $FilePath
        $FailedList | Out-File -Append -FilePath $FilePath
        $BlockBreak | Out-File -Append -FilePath $FilePath
    }
    
}
