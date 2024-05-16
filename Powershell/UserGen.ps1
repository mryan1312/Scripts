# TODO Change Company to drop-down selection to to email domain, Add direct report entry, get rid of logon domain and hardcode it as it is always the same,
# May need to update OU structer when moving new users, export/save function is broken currently,  

# Loading windows forms assembly
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Function Show-UserCreate {
    function Get-Phrase {
        # Generates a psuedo-random password that should be somewhat easy to remember.
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
        $LogonDomainBox.Text = ""
        $EmailDomainBox.Text = ""
        $LastNameBox.Text = ""
        $PasswordBox.Text = ""
        $OfficeBox.Text = ""
        $DepartmentBox.Text = ""
        $ManagerBox.Text = ""
        $GroupIndicatorLabel.Text = ""
        $Script:GroupMembership = @{}
    }

    function Format-Email($AddressFormat) {
        # Formats the email address according to the chosen style and populates the box
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

    function Get-Groups {
        # Create a window to allow selecting all groups for the user, return them to a hashtable for further processing
        $LocalGroups = @()
        $DistroGroups = @()
        $UnifiedLinks = @()

        $GroupSelectForm = New-Object System.Windows.Forms.Form
        $GroupSelectForm.clientSize = '420,180'
        $GroupSelectForm.text = "Select Applicable Groups"
        $GroupSelectForm.BackColor = "#ffffff"
        $GroupSelectForm.FormBorderStyle = 'FixedDialog'

        $LocalGroupsLabel = New-Object System.Windows.Forms.Label
        $LocalGroupsLabel.Text = "Local AD"
        $LocalGroupsLabel.Location = New-Object System.Drawing.Point (10,10)
        $LocalGroupsBox = New-Object System.Windows.Forms.Listbox
        $LocalGroupsBox.Location = New-Object System.Drawing.Point (10,40)
        $LocalGroupsBox.SelectionMode = 'Multiextended'
        $DistroGroupsLabel = New-Object System.Windows.Forms.Label
        $DistroGroupsLabel.Text = "Distro Groups"
        $DistroGroupsLabel.Location = New-Object System.Drawing.Point (150,10)
        $DistroGroupsBox = New-Object System.Windows.Forms.Listbox
        $DistroGroupsBox.Location = New-Object System.Drawing.Point (150,40)
        $DistroGroupsBox.SelectionMode = 'Multiextended'
        $UnifiedLinksLabel = New-Object System.Windows.Forms.Label
        $UnifiedLinksLabel.Text = "Unified Links"
        $UnifiedLinksLabel.Location = New-Object System.Drawing.Point (290,10)
        $UnifiedLinksBox = New-Object System.Windows.Forms.Listbox
        $UnifiedLinksBox.Location = New-Object System.Drawing.Point (290,40)
        $UnifiedLinksBox.SelectionMode = 'Multiextended'
        $SelectButton = New-Object System.Windows.Forms.Button
        $SelectButton.Text = "Select"
        $SelectButton.Location = New-Object System.Drawing.Point (170,150)

        # Local AD Group Items
        $LocalGroupsBox.Items.Add("_GreenTree_QB_Access")
        $LocalGroupsBox.Items.Add("_Secure_Wireless_Computers")
        $LocalGroupsBox.Items.Add("_SSLVPNUsers")
        $LocalGroupsBox.Items.Add("AccountingTeam_Access")
        $LocalGroupsBox.Items.Add("ArchitectureTeam_Access")
        $LocalGroupsBox.Items.Add("DesignTeam_Access")
        $LocalGroupsBox.Items.Add("HRTeam_Access")
        $LocalGroupsBox.Items.Add("IT_AllowedToCreateGroups_Access")
        $LocalGroupsBox.Items.Add("IT_ServerMaintenance_Access")
        $LocalGroupsBox.Items.Add("IT_SharePointAdministrators_Access")
        $LocalGroupsBox.Items.Add("ITTeam_Access")
        $LocalGroupsBox.Items.Add("LDG_Employees_Access")
        $LocalGroupsBox.Items.Add("LDG_Finance_Access")
        $LocalGroupsBox.Items.Add("LDG_GM_Access")
        $LocalGroupsBox.Items.Add("LDG_Managers_Access")
        $LocalGroupsBox.Items.Add("LDG_ProjectManagers_Access")
        $LocalGroupsBox.Items.Add("LDGTeam_Access")
        $LocalGroupsBox.Items.Add("LeadershipTeam_Access")
        $LocalGroupsBox.Items.Add("LEADTeam_Access")
        $LocalGroupsBox.Items.Add("Marketing_NewHomeAdvisor_Access")
        $LocalGroupsBox.Items.Add("MarketingTeam_Access")
        $LocalGroupsBox.Items.Add("PayrollTeam_Access")
        $LocalGroupsBox.Items.Add("ProductionTeam_Access")
        $LocalGroupsBox.Items.Add("PurchasingTeam_Access")
        $LocalGroupsBox.Items.Add("SMH_AR-BEN_Build_Access")
        $LocalGroupsBox.Items.Add("SMH_AR-BEN_Coordinator_Access")
        $LocalGroupsBox.Items.Add("SMH_AR-BEN_Experience_Access")
        $LocalGroupsBox.Items.Add("SMH_AR-BEN_GM_Access")
        $LocalGroupsBox.Items.Add("SMH_AR-BEN_Ministry_Access")
        $LocalGroupsBox.Items.Add("SMH_AR-BEN_Sales_Access")
        $LocalGroupsBox.Items.Add("SMH_AR-BEN_Service_Access")
        $LocalGroupsBox.Items.Add("SMH_Employees_Access")
        $LocalGroupsBox.Items.Add("SMH_Featherston_Build_Access")
        $LocalGroupsBox.Items.Add("SMH_Finance_Access")
        $LocalGroupsBox.Items.Add("SMH_Gifting_Access")
        $LocalGroupsBox.Items.Add("SMH_HO_Coordinator_Access")
        $LocalGroupsBox.Items.Add("SMH_HO_Intern_Access")
        $LocalGroupsBox.Items.Add("SMH_LocalAdmin_Workstations_Access")
        $LocalGroupsBox.Items.Add("SMH_Managers_Access")
        $LocalGroupsBox.Items.Add("SMH_MO-JAS_Build_Access")
        $LocalGroupsBox.Items.Add("SMH_MO-JAS_Coordinator_Access")
        $LocalGroupsBox.Items.Add("SMH_MO-JAS_Experience_Access")
        $LocalGroupsBox.Items.Add("SMH_MO-JAS_GM_Access")
        $LocalGroupsBox.Items.Add("SMH_MO-JAS_Ministry_Access")
        $LocalGroupsBox.Items.Add("SMH_MO-JAS_Sales_Access")
        $LocalGroupsBox.Items.Add("SMH_MO-JAS_Service_Access")
        $LocalGroupsBox.Items.Add("SMH_Neighborhoods_Access")
        $LocalGroupsBox.Items.Add("SMH_OK-TUL_Build_Access")
        $LocalGroupsBox.Items.Add("SMH_OK-TUL_Coordinator_Access")
        $LocalGroupsBox.Items.Add("SMH_OK-TUL_Experience_Access")
        $LocalGroupsBox.Items.Add("SMH_OK-TUL_GM_Access")
        $LocalGroupsBox.Items.Add("SMH_OK-TUL_Ministry_Access")
        $LocalGroupsBox.Items.Add("SMH_OK-TUL_Sales_Access")
        $LocalGroupsBox.Items.Add("SMH_OK-TUL_Service_Access")
        $LocalGroupsBox.Items.Add("SMH_ServiceManagers_Access")
        $LocalGroupsBox.Items.Add("SystemsTeam_Access")

        # Distro Group Items
        $DistroGroupsBox.Items.Add("LDG AR-BEN Ministry")
        $DistroGroupsBox.Items.Add("LDG HO Ministry")
        $DistroGroupsBox.Items.Add("LDG Managers")
        $DistroGroupsBox.Items.Add("LDG MO-JAS Ministry")
        $DistroGroupsBox.Items.Add("Leads and Information")
        $DistroGroupsBox.Items.Add("Shared Services")
        $DistroGroupsBox.Items.Add("SMH AR-BEN Closing")
        $DistroGroupsBox.Items.Add("SMH AR-BEN Construction Managers")
        $DistroGroupsBox.Items.Add("SMH AR-BEN Contract Signed")
        $DistroGroupsBox.Items.Add("SMH AR-BEN Listings")
        $DistroGroupsBox.Items.Add("SMH AR-BEN Ministry")
        $DistroGroupsBox.Items.Add("SMH AR-BEN Region")
        $DistroGroupsBox.Items.Add("SMH AR-BEN Sales")
        $DistroGroupsBox.Items.Add("SMH AR-BEN Service")
        $DistroGroupsBox.Items.Add("SMH AR-BEN Settlements")
        $DistroGroupsBox.Items.Add("SMH AR-BEN Unsold")
        $DistroGroupsBox.Items.Add("SMH Build Region 002")
        $DistroGroupsBox.Items.Add("SMH Build Region 004")
        $DistroGroupsBox.Items.Add("SMH Drivers")
        $DistroGroupsBox.Items.Add("SMH Featherston Build")
        $DistroGroupsBox.Items.Add("SMH HO Ministry")
        $DistroGroupsBox.Items.Add("SMH Managers")
        $DistroGroupsBox.Items.Add("SMH MO-JAS Build")
        $DistroGroupsBox.Items.Add("SMH MO-JAS Construction Managers")
        $DistroGroupsBox.Items.Add("SMH MO-JAS Contract Signed")
        $DistroGroupsBox.Items.Add("SMH MO-JAS Ministry")
        $DistroGroupsBox.Items.Add("SMH MO-JAS Region")
        $DistroGroupsBox.Items.Add("SMH MO-JAS Sales")
        $DistroGroupsBox.Items.Add("SMH MO-JAS Service")
        $DistroGroupsBox.Items.Add("SMH MO-JAS Settlements")
        $DistroGroupsBox.Items.Add("SMH MO-JAS Unsold")
        $DistroGroupsBox.Items.Add("SMH OK-TUL Build")
        $DistroGroupsBox.Items.Add("SMH OK-TUL Closing")
        $DistroGroupsBox.Items.Add("SMH OK-TUL Construction Managers")
        $DistroGroupsBox.Items.Add("SMH OK-TUL Contract Signed")
        $DistroGroupsBox.Items.Add("SMH OK-TUL Listings")
        $DistroGroupsBox.Items.Add("SMH OK-TUL Ministry")
        $DistroGroupsBox.Items.Add("SMH OK-TUL Region")
        $DistroGroupsBox.Items.Add("SMH OK-TUL Sales")
        $DistroGroupsBox.Items.Add("SMH OK-TUL Service")
        $DistroGroupsBox.Items.Add("SMH OK-TUL Settlements")
        $DistroGroupsBox.Items.Add("SMH OK-TUL Unsold")


        # Unified Link Items
        $UnifiedLinksBox.Items.Add("Letsignit_Deploy")
        $UnifiedLinksBox.Items.Add("Unified3")
        $UnifiedLinksBox.Items.Add("Accounting Team")
        $UnifiedLinksBox.Items.Add("BOD Team")
        $UnifiedLinksBox.Items.Add("Daily plan")
        $UnifiedLinksBox.Items.Add("Design Team")
        $UnifiedLinksBox.Items.Add("Facilities Team")
        $UnifiedLinksBox.Items.Add("Fleet Team")
        $UnifiedLinksBox.Items.Add("Home Office")
        $UnifiedLinksBox.Items.Add("HR Team")
        $UnifiedLinksBox.Items.Add("IT Team")
        $UnifiedLinksBox.Items.Add("LDG Team")
        $UnifiedLinksBox.Items.Add("LEAD Team")
        $UnifiedLinksBox.Items.Add("Leadership Team")
        $UnifiedLinksBox.Items.Add("Managers Site Access")
        $UnifiedLinksBox.Items.Add("Marketing Team")
        $UnifiedLinksBox.Items.Add("Ministry Team")
        $UnifiedLinksBox.Items.Add("Payroll Team")
        $UnifiedLinksBox.Items.Add("Production Team")
        $UnifiedLinksBox.Items.Add("Purchasing Team")
        $UnifiedLinksBox.Items.Add("Safety Team")
        $UnifiedLinksBox.Items.Add("SMH AR-BEN Team")
        $UnifiedLinksBox.Items.Add("SMH Featherston Team")
        $UnifiedLinksBox.Items.Add("SMH MO-JAS Build/Service/Detail")
        $UnifiedLinksBox.Items.Add("SMH MO-JAS Closing")
        $UnifiedLinksBox.Items.Add("SMH MO-JAS Team")
        $UnifiedLinksBox.Items.Add("SMH OK-TUL Team")
        $UnifiedLinksBox.Items.Add("SSPR")
        $UnifiedLinksBox.Items.Add("Systems Team")

        
        $GroupSelectForm.Controls.Add($LocalGroupsBox)
        $GroupSelectForm.Controls.Add($DistroGroupsBox)
        $GroupSelectForm.Controls.Add($UnifiedLinksBox)
        $GroupSelectForm.Controls.Add($SelectButton)
        $GroupSelectForm.Controls.Add($LocalGroupsLabel)
        $GroupSelectForm.Controls.Add($DistroGroupsLabel)
        $GroupSelectForm.Controls.Add($UnifiedLinksLabel)

        # Set select button output, send return value as Hash table of lists based on listbox selections
        $SelectButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $FormResult = $GroupSelectForm.ShowDialog()
        if ($FormResult -eq [System.Windows.Forms.DialogResult]::OK) {
            $GroupIndicatorLabel.Text = "Group Memberships Set!"
            return @{"LocalGroups"=@($LocalGroupsBox.SelectedItems); "DistroGroups"=@($DistroGroupsBox.SelectedItems); "UnifiedLinks"=@($UnifiedLinksBox.SelectedItems)}
        }
        
    }

    function Set-User {
        # Check if username already exists in AD
        $UserCheck = Get-ADUser -identity $($UsernameBox.Text)
        # Proceed to run AD Creation if return value is empty
        if ( $null -eq $UserCheck) {
            # Get Manager DN
            $ManagerDN = Get-ADUser -Filter { displayName -like "$($ManagerBox.Text)" } | Select-Object -ExpandProperty DistinguishedName
            # Create User
            $secpasswd = ConvertTo-SecureString -String $($PasswordBox.Text) -AsPlainText -Force
            $FullName = $($FirstNameBox.Text)+" "+$($LastNameBox.Text)
            New-ADUser -Name $FullName -DisplayName $FullName -SamAccountName $($UsernameBox.Text) -GivenName $($FirstNameBox.Text) -Surname $($LastNameBox.Text)  -AccountPassword($secpasswd) -Enabled $true -Company $($CompanyBox.Text) -Office $($OfficeBox.Text) -Department $($DepartmentBox.Text) -EmailAddress $($EmailBox.Text)  -Title $($TitleBox.Text) -manager $ManagerDN -OfficePhone $($PhoneBox.Text)  -UserPrincipalName $($EmailBox.Text)
            
            $UserID = Get-ADUser $($UsernameBox.Text)
            Set-ADUser $userid -add @{proxyAddresses ="smtp:$($EmailBox.Text)"}
            
            #OU Move based on company name
            $UserDN = Get-ADUser -Filter { displayName -like $FullName } | Select-Object -ExpandProperty DistinguishedName
            if ( $Company -eq "Schuber Mitchell Homes" ) {
                Move-ADObject -Identity $UserDN -TargetPath "OU=Employees,OU=Joplin,DC=schubermitchell,DC=com"
            }
            if ( $Company -eq "Land Development Group" ) {
                Move-ADObject -Identity $UserDN -TargetPath "OU=Employees,OU=Land Group LLC,DC=schubermitchell,DC=com"
            }
            # Iterate through each item in list from the hashtable and add group membership
            foreach ($GroupName in $GroupMembership["LocalGroups"]) {
                Add-ADGroupMember -Identity $GroupName -Members $UserId
            }



            # Verify user exists and send confirmation of successful operation
            $UserCompleteCheck = Get-ADUser -identity $($UsernameBox.Text)
            if ( $null -ne $UserCompleteCheck ) {
                [System.Windows.Forms.MessageBox]::Show('User was successfully added to domain.','Success')
                # Sync changes to Cloud            
                $SyncResult = Start-ADSyncSyncCycle -PolicyType Initial
                echo $SynchResult
                Start-Sleep -Seconds 15
            }
        }
        else {
            # Username already exists in AD, need to check if user exists or username is not unique.
            [System.Windows.Forms.MessageBox]::Show('Username already exists in AD. No action taken.','WARNING')
        }
                # Connect to AzureAD and add groups
        Connect-AzureAD 
        Connect-ExchangeOnline 
        $AzureUserEmail = $($EmailBox.Text)
        $AzureUserID = (Get-AzureADuser -objectid $azureuseremail ).objectid

        # Iterate through each item in list from the hashtable and add group membership
        foreach ($DistroName in $GroupMembership["DistroGroups"]) {
            Add-DistributionGroupMember -Identity $DistroName -Member $AzureUserID
        }
        foreach ($UnifiedName in $GroupMembership["UnifiedLinks"]) {
            if ($UnifiedName -eq "Letsignit_Deploy") {
                Add-AzureADGroupMember -ObjectID "748b7d01-86aa-4d5c-8097-cf278e6c683e" -RefObjectID $azureuserid
            }
            else {
                Add-UnifiedGroupLinks -Identity $UnifiedName -LinkType "Members" -Links $AzureUserEmail
            }
        }

        # MFA
        Install-module Microsoft.Graph.Identity.Signins
        Install-Module Microsoft.Graph.Beta -AllowClobber
        Connect-MgGraph -Scopes "User.Read.all","UserAuthenticationMethod.Read.All","UserAuthenticationMethod.ReadWrite.All"
        New-MgUserAuthenticationPhoneMethod -UserId $azureuserid -phoneType "mobile" -phoneNumber ('+1'+$($PhoneBox.Text))
    }

    function Export-User {
        echo "
        # Check if username already exists in AD
        $UserCheck = Get-ADUser -identity $($UsernameBox.Text)
        # Proceed to run AD Creation if return value is empty
        if ( $null -eq $UserCheck) {
            # Get Manager DN
            $ManagerDN = Get-ADUser -Filter { displayName -like $($ManagerBox.Text) } | Select-Object -ExpandProperty DistinguishedName
            # Create User
            $secpasswd = ConvertTo-SecureString -String $($PasswordBox.Text) -AsPlainText -Force
            $FullName = $($FirstNameBox.Text)+" "+$($LastNameBox.Text)
            New-ADUser -Name $FullName -DisplayName $FullName -SamAccountName $($UsernameBox.Text) -GivenName $($FirstNameBox.Text) -Surname $($LastNameBox.Text)  -AccountPassword($secpasswd) -Enabled $true -Company $($CompanyBox.Text) -Office $($OfficeBox.Text) -Department $($DepartmentBox.Text) -EmailAddress $($EmailBox.Text)  -Title $($TitleBox.Text) -manager $ManagerDN -OfficePhone $($PhoneBox.Text)  -UserPrincipalName $($EmailBox.Text)
            
            $UserID = Get-ADUser $($UsernameBox.Text)
            
            #OU Move based on company name
            $UserDN = Get-ADUser -Filter { displayName -like $FullName } | Select-Object -ExpandProperty DistinguishedName
            if ( $Company -eq "Schuber Mitchell Homes" ) {
                Move-ADObject -Identity $UserDN -TargetPath "OU=Employees,OU=Joplin,DC=schubermitchell,DC=com"
            }
            if ( $Company -eq "Land Development Group" ) {
                Move-ADObject -Identity $UserDN -TargetPath "OU=Employees,OU=Land Group LLC,DC=schubermitchell,DC=com"
            }
            # Iterate through each item in list from the hashtable and add group membership
            foreach ($GroupName in $GroupMembership["LocalGroups"]) {
                Add-ADGroupMember -Identity $GroupName -Members $UserId
            }



            # Sync changes to Cloud            
            Start-ADSyncSyncCycle -PolicyType Initial

            # Verify user exists and send confirmation of successful operation
            $UserCompleteCheck = Get-ADUser -identity $($UsernameBox.Text)
            if ( $null -ne $UserCompleteCheck ) {
                [System.Windows.Forms.MessageBox]::Show('User was successfully added to domain.','Success')
            }
        }
        else {
            # Username already exists in AD, need to check if user exists or username is not unique.
            [System.Windows.Forms.MessageBox]::Show('Username already exists in AD. No action taken.','WARNING')
        }
                # Connect to AzureAD and add groups
        Connect-AzureAD 
        Connect-ExchangeOnline 
        $AzureUserEmail = $($EmailBox.Text)
        $AzureUserID = (Get-AzureADuser -objectid $azureuseremail ).objectid

        # Iterate through each item in list from the hashtable and add group membership
        foreach ($DistroName in $GroupMembership["DistroGroups"]) {
            Add-DistributionGroupMember -Identity $DistroName -Member $AzureUserID
        }
        foreach ($UnifiedName in $GroupMembership["UnifiedLinks"]) {
            if ($UnifiedName -eq "Letsignit_Deploy") {
                Add-AzureADGroupMember -ObjectID "748b7d01-86aa-4d5c-8097-cf278e6c683e" -RefObjectID $azureuserid
            }
            else {
                Add-UnifiedGroupLinks -Identity $UnifiedName -LinkType "Members" -Links $AzureUserEmail
            }
        }

        # MFA
        Install-module Microsoft.Graph.Identity.Signins
        Install-Module Microsoft.Graph.Beta -AllowClobber
        Connect-MgGraph -Scopes "User.Read.all","UserAuthenticationMethod.Read.All","UserAuthenticationMethod.ReadWrite.All"
        New-MgUserAuthenticationPhoneMethod -UserId $azureuserid -phoneType "mobile" -phoneNumber ('+1'+$($PhoneBox.Text))
        " | Out-File -FilePath C:\usergen.txt
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
    $GroupIndicatorLabel = New-Object System.Windows.Forms.Label
    $GroupIndicatorLabel.Location = New-Object System.Drawing.Point (10,326)

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

    # Right-Hand Labels
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

    # Right-Hand Boxes
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
    $GroupsButton = New-Object System.Windows.Forms.Button
    $GroupsButton.Text = "Groups"
    $GroupsButton.Location = New-Object System.Drawing.Point (400,220)
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
    $UserCreateForm.Controls.Add($GroupsButton)
    $UserCreateForm.Controls.Add($LDomainBox)
    $UserCreateForm.Controls.Add($LDomainLabel)
    $UserCreateForm.Controls.Add($EDomainBox)
    $UserCreateForm.Controls.Add($EDomainLabel)
    $UserCreateForm.Controls.Add($GroupIndicatorLabel)
    $GenerateButton.Add_Click({$PasswordBox.Text = Get-Phrase})
    $ILButton.Add_Click({Format-Email("IL")})
    $FLButton.Add_Click({Format-Email("FL")})
    $GroupsButton.Add_Click({$Script:GroupMembership = Get-Groups})
    $ClearButton.Add_Click({Clear-Form})
    $ExecuteButton.Add_Click({Set-User})
    $SaveButton.Add_Click({Export-User})

    # Display Form
    [void]$UserCreateForm.ShowDialog()
}

Show-UserCreate