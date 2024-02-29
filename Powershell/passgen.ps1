# Loading windows forms assembly
Add-Type -AssemblyName system.Windows.Forms

# Creating main form and setting attributes
$PassGenForm = New-Object System.Windows.Forms.Form
$PassGenForm.clientSize = '400,150'
$PassGenForm.text = "Sane Password Generator"
$PassGenForm.BackColor = "#ffffff"
$PassGenForm.FormBorderStyle = 'FixedDialog'

# Creating form elements
$GenerateButton = New-Object System.Windows.Forms.Button
$GenerateButton.text = "Generate"
$GenerateButton.Location = New-Object System.Drawing.Point (300,100)
$OutputLabel = New-Object System.Windows.Forms.TextBox
$OutputLabel.Text = "AlphaGammaRoh420!"
$OutputLabel.Size = '358,240'
$OutputLabel.Font = 'Microsoft Sans Serif,24'
$OutputLabel.Location = New-Object System.Drawing.Point (20,20)
$OutputTooltip = New-Object System.Windows.Forms.ToolTip
$OutputTooltip.SetToolTip("Double click to copy!")

# Adding elements to the form
$PassGenForm.Controls.add($GenerateButton)
$PassGenForm.Controls.add($OutputLabel)
$OutputLabel.Controls.add($OutputTooltip)

# Display Form
[void]$PassGenForm.ShowDialog()
