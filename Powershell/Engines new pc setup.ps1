# This script will install required software. There are built in waiting periods to allow installers to
# wrap up their installs and avoid skipping installs. It also includes a handy progress bar :)

# Initialize Variables
$InstallStep = 0

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
        # Install Software and copy shortcuts to public folder
        & 'D:\Agent_Install.exe' /s
        Start-Sleep -seconds 90
        D:\WindowsSensor.MaverickGyr.exe /install /quiet /norestart CID=9CA4E0CBDE9647388A71E856B45ADFE9-13
        Start-Sleep -seconds 300
        Write-Output "Agents Installed"
        continue
    }
    if ($InstallStep -eq 3) {
        $InstallStep++
        & 'D:\CutePDF\Setup.exe' -s
        & 'D:\CutePDF\CuteWriter28' /verysilent /no3d 
        & 'D:\FortiClientVPN.msi' /passive
        Start-Sleep -seconds 120
        regedit 'D:\vpn.reg'
        & 'D:\AcroRdrDC2300620320_en_US.exe' /sAll
        Write-Output "VPN and PDF Tools Installed"
        & "D:\Firefox Installer.exe" -ms -ma
        Start-Sleep -seconds 60
        & "D:\ChromeSetup.exe" /silent /install
        Start-Sleep -seconds 60
        Write-Output "Browsers Installed"
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
        # this bat will set power settings again and map per-user network shares
        Copy-Item 'D:\public desktop\map drives and power settings.bat' 'C:\Users\Public\Desktop\map drives and power settings.bat'
        Write-Output "Shortcuts copied"
        continue
    }
    if ($InstallStep -eq 7) {
        $InstallStep++
        # Install optional features and prerequisites needed for AX
        dism /online /enable-feature /featurename:NetFx3 /norestart
        dism /online /enable-feature /featurename:Windows-Identity-Foundation /norestart
        Write-Output "Features enabled"
        & 'D:\AX\Prerequisite\MSChart.exe' /passive
        Start-Sleep -seconds 60
        & 'D:\AX\Prerequisite\OpenXMLSDKv2.msi' /passive
        Start-Sleep -seconds 60
        & 'D:\AX\Prerequisite\ReportViewer.exe' /passive
        Start-Sleep -seconds 60
        & 'D:\AX\Prerequisite\vcredist_x64.exe' /q
        Start-Sleep -seconds 60
        & 'D:\AX\Prerequisite\vcredist_x86.exe' /q
        Start-Sleep -seconds 60
        & 'D:\AX\Prerequisite\vstor_redist.exe' /passive
        Start-Sleep -seconds 60
        Write-Output "AX PreReqs installed"
        continue
    }
    if ($InstallStep -eq 8) {
        $InstallStep++
        # Uninstall office clicktorun
        & 'D:\Deployment Tool\setup.exe' /configure 'D:\Deployment Tool\uninstall.xml'
        Write-Output "office clicktorun uninstalled"
        continue
    }
    if ($InstallStep -eq 9) {
        $InstallStep++
        # Mount and install office 
        $isoPath = 'D:\SW_DVD5_Office_2016_64Bit_English_MLF_X20-42479.ISO'
        Mount-DiskImage -ImagePath $isoPath -PassThru
        & 'E:\setup.exe' /adminfile 'D:\office.msp'
        Write-Output "Office 2016 Installed"
        continue
    }
    else {
        $InstallStep++
        continue
    }
    Start-Sleep -Milliseconds 25
}
Write-Output "Setup Complete"
Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');