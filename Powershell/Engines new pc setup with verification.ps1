# This script will install required software. There are built in waiting periods to allow installers to
# wrap up their installs and avoid skipping installs. It also includes a handy progress bar :)

# Initialize Variables
$ToInstallCount = 18
$CrowdstrikeKey = Get-Content D:\Crowdstrike.txt -Raw
$InstallStep = 0
$SuccessCount = 0
$FailedInstalls = [System.Collections.ArrayList]::new()

Clear-Host
for($I = 0; $I -lt 11; $I++ ) {
    $OuterLoopProgressParameters = @{
        Activity         = 'Installing Software'
        Status           = 'Progress->'
        PercentComplete  = $I * 10
        CurrentOperation = 'Please Wait'

    }
    Write-Progress @OuterLoopProgressParameters
    # Utilizing the InstallStep variable to segment installations and write
    # to progress bar.
    if ($InstallStep -eq 0) {
        # Set plan settings to keep awake
        set-TimeZone -Name "Central Standard Time"
        powercfg /change standby-timeout-ac 0
        powercfg /change standby-timeout-dc 0
        powercfg /change monitor-timeout-ac 0
        powercfg /change monitor-timeout-dc 0
        # Writing new lines for cleaner terminal output
        Write-Output "`n"
        Write-Output "`n"
        Write-Output "`n"
        Write-Output "`n"
        Write-Output "`n"
        Write-Output "Power Plan Set"
        $InstallStep++
        continue
    }
    if ($InstallStep -eq 1) {
        $InstallStep++
        # Install automate and crowdstrike agents
        & 'D:\Agent_Install.exe' /s
        Start-Sleep -seconds 90
        if (sc.exe query ltservice | findstr "RUNNING") {
            $SuccessCount++
            Write-Output "Automate Agent Installed"
        }
        else {
            $FailedInstalls.add("Automate Agent")
        } 
        D:\WindowsSensor.MaverickGyr.exe /install /quiet /norestart CID=$CrowdstrikeKey
        Start-Sleep -seconds 300
        if (sc.exe query csagent | findstr "RUNNING") {
            $SuccessCount++
            Write-Output "Crowdstrike Agent Installed"
        }
        else {
            $FailedInstalls.add("Crowdstrike Agent")
        } 
        continue
    }
    if ($InstallStep -eq 3) {
        $InstallStep++
        & 'D:\CutePDF\Setup.exe' -s
        if ($?) {
            $SuccessCount++
            Write-Output "Ghostscript Installed"
        }
        else {
            $FailedInstalls.add("Ghostscript")
        } 
        & 'D:\CutePDF\CuteWriter28' /verysilent /no3d
        if (get-package *cute*) {
            $SuccessCount++
            Write-Output "CuteWriter Installed"
        }
        else {
            $FailedInstalls.add("CutePDF")
        } 
        & 'D:\FortiClientVPN.msi' /passive
        Start-Sleep -seconds 120
        if (get-package *forti*) {
            $SuccessCount++
            Write-Output "Forticlient Installed"
        }
        else {
            $FailedInstalls.add("Forticlient VPN")
        } 
        regedit 'D:\vpn.reg'
        & 'D:\AcroRdrDC2300620320_en_US.exe' /sAll
        if ($?) {
            $SuccessCount++
            Write-Output "Acrobat Reader Installed"
        }
        else {
            $FailedInstalls.add("Acrobat Reader")
        } 
        & "D:\Firefox Installer.exe" -ms -ma
        Start-Sleep -seconds 60
        if (get-package *firefox*) {
            $SuccessCount++
            Write-Output "Firefox Installed"
        }
        else {
            $FailedInstalls.add("Firefox")
        } 
        & "D:\ChromeSetup.exe" /silent /install
        Start-Sleep -seconds 60
        if (get-package *chrome*) {
            $SuccessCount++
            Write-Output "Chrome Installed"
        }
        else {
            $FailedInstalls.add("Chrome")
        } 
        continue
    }
    if ($InstallStep -eq 5) {
        $InstallStep++
        # Copying office shortcuts to the public desktop
        Copy-Item 'D:\public desktop\Excel 2016.lnk' 'C:\Users\Public\Desktop\Excel 2016.lnk'
        Copy-Item 'D:\public desktop\OneNote 2016.lnk' 'C:\Users\Public\Desktop\OneNote 2016.lnk'
        Copy-Item 'D:\public desktop\Outlook 2016.lnk' 'C:\Users\Public\Desktop\Outlook 2016.lnk'
        Copy-Item 'D:\public desktop\PowerPoint 2016.lnk' 'C:\Users\Public\Desktop\PowerPoint 2016.lnk'
        Copy-Item 'D:\public desktop\Publisher 2016.lnk' 'C:\Users\Public\Desktop\Publisher 2016.lnk'
        Copy-Item 'D:\public desktop\Word 2016.lnk' 'C:\Users\Public\Desktop\Word 2016.lnk'
        Copy-Item 'D:\public desktop\map drives and power settings.bat' 'C:\Users\Public\Desktop\map drives and power settings.bat'
        Write-Output "Shortcuts copied"
        continue
    }
    if ($InstallStep -eq 7) {
        $InstallStep++
        # Install optional features and prerequisites needed for AX
        dism /online /enable-feature /featurename:NetFx3 /norestart
        if ($?) {
            $SuccessCount++
            Write-Output "DotNet 3.5 Installed"
        }
        else {
            $FailedInstalls.add("DotNet 3.5")
        } 
        dism /online /enable-feature /featurename:Windows-Identity-Foundation /norestart
        if ($?) {
            $SuccessCount++
            Write-Output "Identity Foundation Installed"
        }
        else {
            $FailedInstalls.add("Windows Identity Foundation")
        } 
        & 'D:\AX\Prerequisite\MSChart.exe' /passive
        Start-Sleep -seconds 60
        if (get-package *chart*) {
            $SuccessCount++
            Write-Output "Chart Controls Installed"
        }
        else {
            $FailedInstalls.add("MS Chart Controls")
        } 
        & 'D:\AX\Prerequisite\OpenXMLSDKv2.msi' /passive
        Start-Sleep -seconds 60
        if (get-package *xml*) {
            $SuccessCount++
            Write-Output "Open XML Installed"
        }
        else {
            $FailedInstalls.add("OpenXML SDK v2")
        } 
        & 'D:\AX\Prerequisite\ReportViewer.exe' /passive
        Start-Sleep -seconds 60
        if (get-package *report*) {
            $SuccessCount++
            Write-Output "Report Viewer Installed"
        }
        else {
            $FailedInstalls.add("MS Report Viewer")
        } 
        & 'D:\AX\Prerequisite\vcredist_x86.exe' /q
        Start-Sleep -seconds 60
        if (get-package *9.0.30729*) {
            $SuccessCount++
            Write-Output "VC Redis x86 Installed"
        }
        else {
            $FailedInstalls.add("Visual C++ 2008 Redis x86")
        }
        & 'D:\AX\Prerequisite\vcredist_x64.exe' /q
        Start-Sleep -seconds 60
        if (get-package *9.0.30729.6161*) {
            $SuccessCount++
            Write-Output "VC Redis x64 Installed"
        }
        else {
            $FailedInstalls.add("Visual C++ 2008 Redis x64")
        } 
        & 'D:\AX\Prerequisite\vstor_redist.exe' /passive
        Start-Sleep -seconds 60
        if (get-package *studio*) {
            $SuccessCount++
            Write-Output "Visual Studio Tools Installed"
        }
        else {
            $FailedInstalls.add("Visual Studio Tools for Office 2010 Redis")
        } 
        continue
    }
    if ($InstallStep -eq 8) {
        $InstallStep++
        # Uninstall office clicktorun
        & 'D:\Deployment Tool\setup.exe' /configure 'D:\Deployment Tool\uninstall.xml'
        if ($?) {
            $SuccessCount++
        }
        else {
            $FailedInstalls.add("Click-to-Run Uninstall")
        } 
        Write-Output "Office Clicktorun Uninstalled"
        continue
    }
    if ($InstallStep -eq 9) {
        $InstallStep++
        # Mount and install office 
        $isoPath = 'D:\SW_DVD5_Office_2016_64Bit_English_MLF_X20-42479.ISO'
        Mount-DiskImage -ImagePath $isoPath -PassThru
        & 'E:\setup.exe' /adminfile 'D:\office.msp'
        if ($?) {
            $SuccessCount++
        }
        if ($? -eq $false) {
            $FailedInstalls.add("Office 2016")
        }
        Dismount-DiskImage -ImagePath $isoPath -PassThru 
        Write-Output "Office 2016 Installed"
        continue
    }
    else {
        $InstallStep++
        continue
    }
    Start-Sleep -Milliseconds 25
}
Write-Output ("Setup Complete. Successfully installed " + $successCount + " out of " + $ToInstallCount + " applications.")
Write-Output "The following installs have failed and need to be done manually:"
Write-Output $FailedInstalls
Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');