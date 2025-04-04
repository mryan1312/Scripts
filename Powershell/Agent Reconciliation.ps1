### Sample showing a PowerShell GUI with drag-and-drop ###
 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
 
 
### Create form ###
 
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell GUI"
$form.Size = '260,320'
$form.StartPosition = "CenterScreen"
$form.MinimumSize = $form.Size
$form.MaximizeBox = $False
$form.Topmost = $True
 
 
### Define controls ###
 
$button = New-Object System.Windows.Forms.Button
$button.Location = '5,5'
$button.Size = '75,23'
$button.Width = 120
$button.Text = "Print list to console"
 
$checkbox = New-Object Windows.Forms.Checkbox
$checkbox.Location = '140,8'
$checkbox.AutoSize = $True
$checkbox.Text = "Clear afterwards"
 
$label = New-Object Windows.Forms.Label
$label.Location = '5,40'
$label.AutoSize = $True
$label.Text = "Drop files or folders here:"
 
$listBox = New-Object Windows.Forms.ListBox
$listBox.Location = '5,60'
$listBox.Height = 200
$listBox.Width = 240
$listBox.Anchor = ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top)
$listBox.IntegralHeight = $False
$listBox.AllowDrop = $True
 
$statusBar = New-Object System.Windows.Forms.StatusBar
$statusBar.Text = "Ready"
 
 
### Add controls to form ###
 
$form.SuspendLayout()
$form.Controls.Add($button)
$form.Controls.Add($checkbox)
$form.Controls.Add($label)
$form.Controls.Add($listBox)
$form.Controls.Add($statusBar)
$form.ResumeLayout()
 
 
### Write event handlers ###
 
$button_Click = {
    write-host "Listbox contains:" -ForegroundColor Yellow
 
	foreach ($item in $listBox.Items)
    {
        $i = Get-Item -LiteralPath $item
        if($i -is [System.IO.DirectoryInfo])
        {
            write-host ("`t" + $i.Name + " [Directory]")
        }
        else
        {
            write-host ("`t" + $i.Name + " [" + [math]::round($i.Length/1MB, 2) + " MB]")
        }
	}
 
    if($checkbox.Checked -eq $True)
    {
        $listBox.Items.Clear()
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
 
 
### Wire up events ###
 
$button.Add_Click($button_Click)
$listBox.Add_DragOver($listBox_DragOver)
$listBox.Add_DragDrop($listBox_DragDrop)
$form.Add_FormClosed($form_FormClosed)
 
 
#### Show form ###
 
[void] $form.ShowDialog()


////
# Specify the paths to your CSV files
$ADCSV = "ADComputers.csv"
$TLCSV = "Threatlocker.csv"
$CWACSV = "Automate.csv"
$CSCSV = "Crowdstrike.csv"
$ADGCSV = "Addigy.csv"
# Read the CSV files and format data objects
$ADData = Import-Csv $ADCSV | ForEach-Object {
    $_.Name = $_.Name.ToLower()
    $_
}
$ADData| Add-Member -MemberType AliasProperty -Name CName -Value "Name" -Force
$TLData = Import-Csv $TLCSV | ForEach-Object {
    $_."Host Name" = $_."Host Name".ToLower()
    $_
}
$TLData | Add-Member -MemberType AliasProperty -Name CName -Value "Host Name" -Force
$CWAData = Import-Csv $CWACSV | ForEach-Object {
    $_."Computer Name" = $_."Computer Name".ToLower()
    $_
}
$CWAData| Add-Member -MemberType AliasProperty -Name CName -Value "Computer Name" -Force
$CSData = Import-Csv $CSCSV | ForEach-Object {
    $_."Hostname" = $_."Hostname".ToLower()
    $SplitName = $_."Hostname".split(".")
    $_."Hostname" = $SplitName[0]
    $_
}
$CSDAta| Add-Member -MemberType AliasProperty -Name CName -Value "Hostname" -Force
$ADGData = Import-Csv $ADGCSV | ForEach-Object {
    $_."Device Name" = $_."Device Name".ToLower()
    $_
}
$ADGData| Add-Member -MemberType AliasProperty -Name CName -Value "Device Name" -Force

# Compare the data AD VS Others
$ADTLcomparisonResult = Compare-Object $ADData $TLData -Property CName
$ADCWAcomparisonResult = Compare-Object $($ADData | Where-Object {$_."OperatingSystem" -like "Windows *"}) $CWAData -Property CName
$ADCScomparisonResult = Compare-Object $ADData $CSData -Property CName
$ADADGcomparisonResult = Compare-Object $($ADData | Where-Object {$_.OperatingSystem -eq "Mac OS X"-or $_.OperatingSystem -eq "macOS"}) $ADGData -Property CName

# Display the differences AD VS Others
Write-Output "Below are the comparison Results. The side indicator points to /n hosts that are in one platform and not the other."
Write-Output "AD vs. Threatlocker" >> ./ADResult.txt
$ADTLcomparisonResult | Format-Table -AutoSize >> ./ADResult.txt
Write-Output "AD vs. Automate" >> ./ADResult.txt
$ADCWAcomparisonResult | Format-Table -AutoSize >> ./ADResult.txt
Write-Output "AD vs. Crowdstrike" >> ./ADResult.txt
$ADCScomparisonResult | Format-Table -AutoSize >> ./ADResult.txt
Write-Output "AD vs. Addigy" >> ./ADResult.txt
$ADADGcomparisonResult | Format-Table -AutoSize >> ./ADResult.txt

# Compare the data CWA VS Others
$CWATLcomparisonResult = Compare-Object $CWAData $($TLData | Where-Object {$_."Operating System" -like "Windows *"}) -Property CName
$CWAADcomparisonResult = Compare-Object $CWAData $($ADData | Where-Object {$_.OperatingSystem -like "Windows *"}) -Property CName
$CWACScomparisonResult = Compare-Object $CWAData $($CSData | Where-Object {$_.Platform -eq "Windows"}) -Property CName
   
# Display the differences CWA VS Others
Write-Output "Below are the comparison Results. The side indicator points to /n hosts that are in one platform and not the other."
Write-Output "CWA vs. Threatlocker" >> ./CWAResult.txt
$CWATLcomparisonResult | Format-Table -AutoSize >> ./CWAResult.txt
Write-Output "CWA vs. AD" >> ./CWAResult.txt
$CWAADcomparisonResult | Format-Table -AutoSize >> ./CWAResult.txt
Write-Output "CWA vs. Crowdstrike" >> ./CWAResult.txt
$CWACScomparisonResult | Format-Table -AutoSize >> ./CWAResult.txt

# Compare the data ADG VS Others
$ADGTLcomparisonResult = Compare-Object $ADGData $($TLData | Where-Object {$_.Group -eq "MAC"}) -Property CName
$ADGCScomparisonResult = Compare-Object $ADGData $($CSData | Where-Object {$_.Platform -eq "Mac"}) -Property CName
$ADGADcomparisonResult = Compare-Object $ADGData $($ADData | Where-Object {$_.OperatingSystem -eq "Mac OS X" -or $_.OperatingSystem -eq "macOS"}) -Property CName

# Display the differences AD VS Others
Write-Output "Below are the comparison Results. The side indicator points to /n hosts that are in one platform and not the other."
Write-Output "ADG vs. Threatlocker" >> ./ADGResult.txt
$ADGTLcomparisonResult | Format-Table -AutoSize >> ./ADGResult.txt
Write-Output "ADG vs. Crowdstrike" >> ./ADGResult.txt
$ADGCScomparisonResult | Format-Table -AutoSize >> ./ADGResult.txt
Write-Output "ADG vs. AD" >> ./ADGResult.txt
$ADGADcomparisonResult | Format-Table -AutoSize >> ./ADGResult.txt

////

# Import the Active Directory module
Import-Module ActiveDirectory
# Get the list of AD computers
## Need to filter out disabled OU if there are any
$computers = Get-ADComputer -Filter * -Property Name, OperatingSystem, LastLogonDate
# Select the properties you want to export
$computers | Select-Object Name, OperatingSystem, LastLogonDate | Export-Csv -Path "C:\ADComputers.csv" -NoTypeInformation
Write-Output "Export completed. The list of AD computers has been saved to C:\ADComputers.csv"
