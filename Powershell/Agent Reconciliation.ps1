### Reconciles active agents against different platforms. ###
### For questions / comments / help, reach out: madams@kalmersolutions.com ###

## Create new psobject, Cname, ad, tlocker etc
## foreach > if property sideindicator > change property in new psobject for determined side
## Export new psobject to csv 

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
 
$ADCSV = $null
$TLCSV = $null
$CWACSV = $null
$CSCSV = $null
$ADGCSV = $null

function Get-Folder($initialDirectory="") {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}
function Export-Report {
    # Setting Export Dir
    $ExportDir = Get-Folder

    # Import and format CSV data
    if ($null -ne $script:ADCSV) {
        $ADData = Import-Csv $script:ADCSV | ForEach-Object {
            $_.Name = $_.Name.ToLower()
            $_
        }
        $ADData| Add-Member -MemberType AliasProperty -Name CName -Value "Name" -Force
    }
    if ($null -ne $script:TLCSV) {
        $TLData = Import-Csv $script:TLCSV | ForEach-Object {
            $_."Host Name" = $_."Host Name".ToLower()
            $_
        }
        $TLData | Add-Member -MemberType AliasProperty -Name CName -Value "Host Name" -Force
    }
    if ($null -ne $script:CWACSV) {
        $CWAData = Import-Csv $script:CWACSV | ForEach-Object {
            $_."Computer Name" = $_."Computer Name".ToLower()
            $_
        }
        $CWAData| Add-Member -MemberType AliasProperty -Name CName -Value "Computer Name" -Force
    }
    if ($null -ne $script:CSCSV) {
        $CSData = Import-Csv $script:CSCSV | ForEach-Object {
            $_."Hostname" = $_."Hostname".ToLower()
            $SplitName = $_."Hostname".split(".")
            $_."Hostname" = $SplitName[0]
            $_
        }
        $CSDAta| Add-Member -MemberType AliasProperty -Name CName -Value "Hostname" -Force
    }
    if ($null -ne $script:ADGCSV) {
        $ADGData = Import-Csv $script:ADGCSV | ForEach-Object {
            $_."Device Name" = $_."Device Name".ToLower()
            $_
        }
        $ADGData| Add-Member -MemberType AliasProperty -Name CName -Value "Device Name" -Force
    }
   
    # Compare the data AD VS Others
    if ($null -ne $script:ADCSV) {
        Write-Output "Below are the comparison Results. The side indicator points to /n hosts that are in one platform and not the other." >> $ExportDir/ADResult.txt
        if ($null -ne $script:TLCSV) {
            $ADTLcomparisonResult = Compare-Object $ADData $TLData -Property CName
            Write-Output "AD vs. Threatlocker" >> $ExportDir/ADResult.txt
            $ADTLcomparisonResult | Format-Table -AutoSize >> $ExportDir/ADResult.txt
        }
        if ($null -ne $script:CWACSV) {
            $ADCWAcomparisonResult = Compare-Object $($ADData | Where-Object {$_."OperatingSystem" -like "Windows *"}) $CWAData -Property CName
            Write-Output "AD vs. Automate" >> $ExportDir/ADResult.txt
            $ADCWAcomparisonResult | Format-Table -AutoSize >> $ExportDir/ADResult.txt
        }
        if ($null -ne $script:CSCSV) {
            $ADCScomparisonResult = Compare-Object $ADData $CSData -Property CName
            Write-Output "AD vs. Crowdstrike" >> $ExportDir/ADResult.txt
            $ADCScomparisonResult | Format-Table -AutoSize >> $ExportDir/ADResult.txt
        }
        if ($null -ne $script:ADGCSV) {
            $ADADGcomparisonResult = Compare-Object $($ADData | Where-Object {$_.OperatingSystem -eq "Mac OS X"-or $_.OperatingSystem -eq "macOS"}) $ADGData -Property CName
            Write-Output "AD vs. Addigy" >> $ExportDir/ADResult.txt
            $ADADGcomparisonResult | Format-Table -AutoSize >> $ExportDir/ADResult.txt
        }
    }
   
    # Compare the data CWA VS Others
    if ($null -ne $script:CWACSV) {
        Write-Output "Below are the comparison Results. The side indicator points to /n hosts that are in one platform and not the other." >> $ExportDir/CWAResult.txt
        if ($null -ne $script:TLCSV) {
            $CWATLcomparisonResult = Compare-Object $CWAData $($TLData | Where-Object {$_."Operating System" -like "Windows *"}) -Property CName
            Write-Output "Automate vs. Threatlocker" >> $ExportDir/CWAResult.txt
            $CWATLcomparisonResult | Format-Table -AutoSize >> $ExportDir/CWAResult.txt
        }
        if ($null -ne $script:ADCSV) {
            $CWAADcomparisonResult = Compare-Object $CWAData $($ADData | Where-Object {$_.OperatingSystem -like "Windows *"}) -Property CName
            Write-Output "Automate vs. AD" >> $ExportDir/CWAResult.txt
            $CWAADcomparisonResult | Format-Table -AutoSize >> $ExportDir/CWAResult.txt
        }
        if ($null -ne $script:CSCSV) {
            $CWACScomparisonResult = Compare-Object $CWAData $($CSData | Where-Object {$_.Platform -eq "Windows"}) -Property CName
            Write-Output "Automate vs. Crowdstrike" >> $ExportDir/CWAResult.txt
            $CWACScomparisonResult | Format-Table -AutoSize >> $ExportDir/CWAResult.txt
        }
    }

    # Compare the data ADG VS Others
    if ($null -ne $script:ADGCSV) {
        Write-Output "Below are the comparison Results. The side indicator points to hosts that are in one platform and not the other." >> $ExportDir/ADGResult.txt
        if ($null -ne $script:TLCSV) {
            $ADGTLcomparisonResult = Compare-Object $ADGData $($TLData | Where-Object {$_.Group -eq "MAC"}) -Property CName
            Write-Output "Addigy vs. Threatlocker" >> $ExportDir/ADGResult.txt
            $ADGTLcomparisonResult | Format-Table -AutoSize >> $ExportDir/ADGResult.txt
        }
        if ($null -ne $script:CSCSV) {
            $ADGCScomparisonResult = Compare-Object $ADGData $($CSData | Where-Object {$_.Platform -eq "Mac"}) -Property CName
            Write-Output "Addigy vs. Crowdstrike" >> $ExportDir/ADGResult.txt
            $ADGCScomparisonResult | Format-Table -AutoSize >> $ExportDir/ADGResult.txt
        }
        if ($null -ne $script:ADCSV) {
            $ADGADcomparisonResult = Compare-Object $ADGData $($ADData | Where-Object {$_.OperatingSystem -eq "Mac OS X" -or $_.OperatingSystem -eq "macOS"}) -Property CName
            Write-Output "Addigy vs. AD" >> $ExportDir/ADGResult.txt
            $ADGADcomparisonResult | Format-Table -AutoSize >> $ExportDir/ADGResult.txt
        }
    }
}

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Agent Reconciliation"
$form.Size = '300,320'
$form.StartPosition = "CenterScreen"
$form.MinimumSize = $form.Size
$form.MaximizeBox = $False
$form.Topmost = $True
 
 
# Define controls
$button = New-Object System.Windows.Forms.Button
$button.Location = '5,5'
$button.Size = '75,23'
$button.Width = 120
$button.Text = "Generate Reports!"
 
$checkbox = New-Object Windows.Forms.Checkbox
$checkbox.Location = '140,8'
$checkbox.AutoSize = $True
$checkbox.Text = "Clear list after"
 
$label = New-Object Windows.Forms.Label
$label.Location = '5,40'
$label.AutoSize = $True
$label.Text = "Drop CSV files here:"
 
$listBox = New-Object Windows.Forms.ListBox
$listBox.Location = '5,60'
$listBox.Height = 200
$listBox.Width = 260
$listBox.Anchor = ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top)
$listBox.IntegralHeight = $False
$listBox.AllowDrop = $True
 
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"
 
 
# Add controls to form
$form.SuspendLayout()
$form.Controls.Add($button)
$form.Controls.Add($checkbox)
$form.Controls.Add($label)
$form.Controls.Add($listBox)
$form.Controls.Add($statusBar)
$form.ResumeLayout()
 
 
# Write event handlers
$button_Click = {
    foreach ($item in $listBox.Items)
    {
        $i = Get-Item -LiteralPath $item
        if($i -is [System.IO.DirectoryInfo])
        {
            write-host ("Specify files only please.")
        }
        else
        {
            if ($i.Name -eq "ADComputers.csv") {
                $script:ADCSV = $i.FullName
            }
            if ($i.Name -eq "Threatlocker.csv") {
                $script:TLCSV = $i.FullName
            }
            if ($i.Name -like "*Computers Page*") {
                $script:TLCSV = $i.FullName
                echo $i.Name + " for Threatlocker" ###testing###
            }
            if ($i.Name -eq "Automate.csv") {
                $script:CWACSV = $i.FullName
            }
            if ($i.Name -like "*cwa*") {
                $script:CWACSV = $i.FullName
                echo $i.Name + " for automate" ###testing###
            }
            if ($i.Name -eq "Crowdstrike.csv") {
                $script:CSCSV = $i.FullName
            }
            if ($i.Name -like "*hosts*") {
                $script:CSCSV = $i.FullName
                echo $i.Name + " for crowdstrike" ###testing###
            }
            if ($i.Name -eq "Addigy.csv") {
                $script:ADGCSV = $i.FullName
            }
            if ($i.Name -like "*Devices*") {
                $script:ADGCSV = $i.FullName
                echo $i.Name + " for addigy" ###testing###
            }
        }
    }
    Export-Report
    if($checkbox.Checked -eq $True)
    {
        $listBox.Items.Clear()
        $ADCSV = $null
        $TLCSV = $null
        $CWACSV = $null
        $CSCSV = $null
        $ADGCSV = $null
    }
 
    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}
 
$listBox_DragOver = [System.Windows.Forms.DragEventHandler]{
    if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) # $_ = [System.Windows.Forms.DragEventArgs]
    {
        $_.Effect = 'Copy'
    }
    else
    {
        $_.Effect = 'None'
    }
}
   
$listBox_DragDrop = [System.Windows.Forms.DragEventHandler]{
    foreach ($filename in $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)) # $_ = [System.Windows.Forms.DragEventArgs]
    {
        $listBox.Items.Add($filename)
    }
    $statusBar.Text = ("List contains $($listBox.Items.Count) items")
}
 
$form_FormClosed = {
    try
    {
        $listBox.remove_Click($button_Click)
        $listBox.remove_DragOver($listBox_DragOver)
        $listBox.remove_DragDrop($listBox_DragDrop)
        $listBox.remove_DragDrop($listBox_DragDrop)
        $form.remove_FormClosed($Form_Cleanup_FormClosed)
    }
    catch [Exception]
    { }
}
 
 
# Wire up events
$button.Add_Click($button_Click)
$listBox.Add_DragOver($listBox_DragOver)
$listBox.Add_DragDrop($listBox_DragDrop)
$form.Add_FormClosed($form_FormClosed)
 
 
# Show form
[void] $form.ShowDialog()
