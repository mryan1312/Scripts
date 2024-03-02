# Loading windows forms assembly
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Function Show-UserCreate {
    function Get-Phrase {
        $LetComp = @('Alpha','Beta','Gamma','Delta','Epsilon','Zeta','Eta','Theta','Iota','Kappa','Lambda','Mu','Nu','Xi','Omicron','Pi','Rho','Sigma','Tau','Upsilon','Phi','Chi','Psi','Omega')
        $AdjComp = @('Alert','Fuzzy','Spicy','Prickly','Calm','Bored','Clever','Bad','Drab','Dull','Dizzy','Busy','Brave','Jolly','Nice','Witty','Tame','Zany','Rich','Super','Shy','Proud','Itchy')
        $AniComp = @('Chicken','Quokka','Kangaroo','Bear','Cow','Cheetah','Lion','Panda','Owl','Snake','Eagle','Elephant','Newt','Shark','Spider','Squid','Crab','Scorpion','Barnacle','Penguin','Toad')
        $Prefix = $AdjComp | Get-Random
        $Middle = $LetComp | Get-Random
        $Suffix = $AniComp | Get-Random
        $TrailNum = Get-Random -Minimum 100 -Maximum 999
        $Phrase = $Prefix+"-"+$Middle+"-"+$Suffix+"#"+$TrailNum.ToString()
        $UsernameBox.Text = $FirstNameBox.Text[0].ToString().ToLower() + $LastNameBox.Text.ToLower()
        return $Phrase
    }

    function Clear-Form {
        $FirstNameBox.Text = ""
        $UsernameBox.Text = ""
        $EmailBox.Text = ""
        $PhoneBox.Text = ""
        $TitleBox.Text = ""
        $CompanyBox.Text = ""
        $LastNameBox.Text = ""
        $PasswordBox.Text = ""
        $OfficeBox.Text = ""
        $DepartmentBox.Text = ""
        $ManagerBox.Text = ""
    }

    function Format-Email($AddressFormat) {
        if ($AddressFormat -eq "FL") {
            if ($EDomainBox.Text -eq "") {
                $EmailBox.Text = $FirstNameBox.Text.ToLower() + "." + $LastNameBox.Text.ToLower() + "@" + $LDomainBox.Text.ToLower()
            }
            else {
                $EmailBox.Text = $FirstNameBox.Text.ToLower() + "." + $LastNameBox.Text.ToLower() + "@" + $EDomainBox.Text.ToLower()
            }
        }
        if ($AddressFormat -eq "IL") {
            if ($EDomainBox.Text -eq "") {
                $EmailBox.Text = $FirstNameBox.Text[0].ToString().ToLower() + $LastNameBox.Text.ToLower() + "@" + $LDomainBox.Text.ToLower()
            }
            else {
                $EmailBox.Text = $FirstNameBox.Text[0].ToString().ToLower() + $LastNameBox.Text.ToLower() + "@" + $EDomainBox.Text.ToLower()
            }
        }
    }

    function Set-User($FirstName, $LastName, $Username, $Password) {
        #$UserCheck = Get-ADUser -identity $Username
        Start-Transcript
        Write-Host "Creating user for "$FirstName  $LastName 
        Write-Host "as" $Username $Password
        # Proceed to run AD Creation
        Stop-Transcript
        #if ($UserCheck -eq "") {

        #}
        #else {
            # popup message "User already exists"
        #}
    }

    # Creating main form
    $UserCreateForm = New-Object System.Windows.Forms.Form
    $UserCreateForm.clientSize = '500,400'
    $UserCreateForm.text = "User Creation Tool"
    $UserCreateForm.BackColor = "#ffffff"
    $UserCreateForm.FormBorderStyle = 'FixedDialog'

    # Left-Hand Labels
    $FirstNameLabel = New-Object System.Windows.Forms.Label
    $FirstNameLabel.Text = "First Name"
    $FirstNameLabel.Location = New-Object System.Drawing.Point (10,6)
    $UsernameLabel = New-Object System.Windows.Forms.Label
    $UsernameLabel.Text = "Username"
    $UsernameLabel.Location = New-Object System.Drawing.Point (10,46)
    $LDomainLabel = New-Object System.Windows.Forms.Label
    $LDomainLabel.Text = "Logon Domain"
    $LDomainLabel.Location = New-Object System.Drawing.Point (10,86)
    $EmailLabel = New-Object System.Windows.Forms.Label
    $EmailLabel.Text = "Email"
    $EmailLabel.Location = New-Object System.Drawing.Point (10,126)
    $PhoneLabel = New-Object System.Windows.Forms.Label
    $PhoneLabel.Text = "Phone"
    $PhoneLabel.Location = New-Object System.Drawing.Point (10,206)
    $TitleLabel = New-Object System.Windows.Forms.Label
    $TitleLabel.Text = "Title"
    $TitleLabel.Location = New-Object System.Drawing.Point (10,246)
    $CompanyLabel = New-Object System.Windows.Forms.Label
    $CompanyLabel.Text = "Company"
    $CompanyLabel.Location = New-Object System.Drawing.Point (10,286)

    # Left-Hand Boxes
    $FirstNameBox = New-Object System.Windows.Forms.TextBox
    $FirstNameBox.Size = '180,300'
    $FirstNameBox.Font = 'Microsoft Sans Serif,10'
    $FirstNameBox.Location = New-Object System.Drawing.Point (10,20)
    $UsernameBox = New-Object System.Windows.Forms.TextBox
    $UsernameBox.Size = '180,300'
    $UsernameBox.Font = 'Microsoft Sans Serif,10'
    $UsernameBox.Location = New-Object System.Drawing.Point (10,60)
    $LDomainBox = New-Object System.Windows.Forms.TextBox
    $LDomainBox.Size = '180,300'
    $LDomainBox.Font = 'Microsoft Sans Serif,10'
    $LDomainBox.Location = New-Object System.Drawing.Point (10,100)
    $EmailBox = New-Object System.Windows.Forms.TextBox
    $EmailBox.Size = '250,300'
    $EmailBox.Font = 'Microsoft Sans Serif,10'
    $EmailBox.Location = New-Object System.Drawing.Point (10,140)
    $PhoneBox = New-Object System.Windows.Forms.TextBox
    $PhoneBox.Size = '180,300'
    $PhoneBox.Font = 'Microsoft Sans Serif,10'
    $PhoneBox.Location = New-Object System.Drawing.Point (10,220)
    $TitleBox = New-Object System.Windows.Forms.TextBox
    $TitleBox.Size = '180,300'
    $TitleBox.Font = 'Microsoft Sans Serif,10'
    $TitleBox.Location = New-Object System.Drawing.Point (10,260)
    $CompanyBox = New-Object System.Windows.Forms.TextBox
    $CompanyBox.Size = '180,300'
    $CompanyBox.Font = 'Microsoft Sans Serif,10'
    $CompanyBox.Location = New-Object System.Drawing.Point (10,300)

    #Right-Hand Labels
    $LastNameLabel = New-Object System.Windows.Forms.Label
    $LastNameLabel.Text = "Last Name"
    $LastNameLabel.Location = New-Object System.Drawing.Point (200,6)
    $PasswordLabel = New-Object System.Windows.Forms.Label
    $PasswordLabel.Text = "Password"
    $PasswordLabel.Location = New-Object System.Drawing.Point (200,46)
    $EDomainLabel = New-Object System.Windows.Forms.Label
    $EDomainLabel.Text = "Email Domain"
    $EDomainLabel.Location = New-Object System.Drawing.Point (200,86)
    $OfficeLabel = New-Object System.Windows.Forms.Label
    $OfficeLabel.Text = "Office"
    $OfficeLabel.Location = New-Object System.Drawing.Point (200,206)
    $DepartmentLabel = New-Object System.Windows.Forms.Label
    $DepartmentLabel.Text = "Department"
    $DepartmentLabel.Location = New-Object System.Drawing.Point (200,246)
    $ManagerLabel = New-Object System.Windows.Forms.Label
    $ManagerLabel.Text = "Manager"
    $ManagerLabel.Location = New-Object System.Drawing.Point (200,286)

    #Right-Hand Boxes
    $LastNameBox = New-Object System.Windows.Forms.TextBox
    $LastNameBox.Size = '180,300'
    $LastNameBox.Font = 'Microsoft Sans Serif,10'
    $LastNameBox.Location = New-Object System.Drawing.Point (200,20)
    $PasswordBox = New-Object System.Windows.Forms.TextBox
    $PasswordBox.Size = '180,300'
    $PasswordBox.Font = 'Microsoft Sans Serif,10'
    $PasswordBox.Location = New-Object System.Drawing.Point (200,60)
    $EDomainBox = New-Object System.Windows.Forms.TextBox
    $EDomainBox.Size = '180,300'
    $EDomainBox.Font = 'Microsoft Sans Serif,10'
    $EDomainBox.Location = New-Object System.Drawing.Point (200,100)
    $OfficeBox = New-Object System.Windows.Forms.TextBox
    $OfficeBox.Size = '180,300'
    $OfficeBox.Font = 'Microsoft Sans Serif,10'
    $OfficeBox.Location = New-Object System.Drawing.Point (200,220)
    $DepartmentBox = New-Object System.Windows.Forms.TextBox
    $DepartmentBox.Size = '180,300'
    $DepartmentBox.Font = 'Microsoft Sans Serif,10'
    $DepartmentBox.Location = New-Object System.Drawing.Point (200,260)
    $ManagerBox = New-Object System.Windows.Forms.TextBox
    $ManagerBox.Size = '180,300'
    $ManagerBox.Font = 'Microsoft Sans Serif,10'
    $ManagerBox.Location = New-Object System.Drawing.Point (200,300)

    # Buttons
    $GenerateButton = New-Object System.Windows.Forms.Button
    $GenerateButton.Text = "Generate"
    $GenerateButton.Location = New-Object System.Drawing.Point (400,60)
    $ILButton = New-Object System.Windows.Forms.Button
    $ILButton.Text = "FLast"
    $ILButton.Location = New-Object System.Drawing.Point (300,140)
    $FLButton = New-Object System.Windows.Forms.Button
    $FLButton.Text = "First.Last"
    $FLButton.Location = New-Object System.Drawing.Point (400,140)
    $ExecuteButton = New-Object System.Windows.Forms.Button
    $ExecuteButton.Text = "Execute"
    $ExecuteButton.Location = New-Object System.Drawing.Point (300,360)
    $SaveButton = New-Object System.Windows.Forms.Button
    $SaveButton.Text = "Save"
    $SaveButton.Location = New-Object System.Drawing.Point (400,360)
    $ClearButton = New-Object System.Windows.Forms.Button
    $ClearButton.Text = "Clear"
    $ClearButton.Location = New-Object System.Drawing.Point (10,360)
    
    # Adding elements to the form
    $UserCreateForm.Controls.Add($GenerateButton)
    $UserCreateForm.Controls.Add($PasswordBox)
    $UserCreateForm.Controls.Add($PasswordLabel)
    $UserCreateForm.Controls.Add($UsernameBox)
    $UserCreateForm.Controls.Add($UsernameLabel)
    $UserCreateForm.Controls.Add($ExecuteButton)
    $UserCreateForm.Controls.Add($SaveButton)
    $UserCreateForm.Controls.Add($FirstNameBox)
    $UserCreateForm.Controls.Add($FirstNameLabel)
    $UserCreateForm.Controls.Add($LastNameBox)
    $UserCreateForm.Controls.Add($LastNameLabel)
    $UserCreateForm.Controls.Add($EmailBox)
    $UserCreateForm.Controls.Add($EmailLabel)
    $UserCreateForm.Controls.Add($PhoneBox)
    $UserCreateForm.Controls.Add($PhoneLabel)
    $UserCreateForm.Controls.Add($OfficeBox)
    $UserCreateForm.Controls.Add($OfficeLabel)
    $UserCreateForm.Controls.Add($TitleBox)
    $UserCreateForm.Controls.Add($TitleLabel)
    $UserCreateForm.Controls.Add($DepartmentBox)
    $UserCreateForm.Controls.Add($DepartmentLabel)
    $UserCreateForm.Controls.Add($CompanyBox)
    $UserCreateForm.Controls.Add($CompanyLabel)
    $UserCreateForm.Controls.Add($ManagerBox)
    $UserCreateForm.Controls.Add($ManagerLabel)
    $UserCreateForm.Controls.Add($ClearButton)
    $UserCreateForm.Controls.Add($ILButton)
    $UserCreateForm.Controls.Add($FLButton)
    $UserCreateForm.Controls.Add($LDomainBox)
    $UserCreateForm.Controls.Add($LDomainLabel)
    $UserCreateForm.Controls.Add($EDomainBox)
    $UserCreateForm.Controls.Add($EDomainLabel)
    $GenerateButton.Add_Click({$PasswordBox.Text = Get-Phrase})
    $ILButton.Add_Click({Format-Email("IL")})
    $FLButton.Add_Click({Format-Email("FL")})
    $ClearButton.Add_Click({Clear-Form})
    $ExecuteButton.Add_Click({Set-User($FirstNameBox.Text, $LastNameBox.Text, $UsernameBox.Text, $PasswordBox.Text)})

    # Display Form
    [void]$UserCreateForm.ShowDialog()
}

Show-UserCreate