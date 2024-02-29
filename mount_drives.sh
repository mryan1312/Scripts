#!/bin/bash
plistfile="/Library/LaunchAgents/map_drives.plist"
sudo touch $plistfile
sudo chown root $plistfile

#writing the plist
cat > $plistfile << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.loginscript</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>/Users/Shared/map_drives.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
</dict>
</plist>
EOF

#Writing the script to shared folder
scriptfile=/Users/Shared/map_drives.sh
sudo touch $scriptfile
sudo chmod +x $scriptfile
sudo chmod 777 $scriptfile
sudo cat > $scriptfile << 'EOF'
#!/bin/bash
# Get the current user's username and set desktop directory
user=$(whoami)
directory="$HOME/Desktop/"
# Check AD group membership
groupMembership="$(id -Gn $user)"
# Check for specific group memberships and mount shares accordingly
rm $directory"Build Scans.command"
rm $directory"Sales Scans.command"
rm $directory"Purchasing Scans.command"
rm $directory"Marketing Scans.command"
rm $directory"Leadership Scans.command"
rm $directory"IT Scans.command"
rm $directory"HR Scans.command"
rm $directory"Architecture Scans.command"
rm $directory"Accounting Scans.command"
if [[ $groupMembership == *"SMH_MO-JAS_Build_Access"* ]]; then
    touch $directory"Build Scans.command"
    chmod +x $directory"Build Scans.command"
    echo '#!/bin/bash' | tee -a "$directory"Build Scans.command"
    echo "open \"smb://192.168.0.6/MO-JAS-Other Scans/\"" | -a $directory"Build Scans.command"
fi
if [[ $groupMembership == *"SMH_MO-JAS_Sales_Access"* ]]; then
    touch $directory"Sales Scans.command"
    chmod +x $directory"Sales Scans.command"
    echo '#!/bin/bash' | tee -a $directory"Sales Scans.command"
    echo "open \"smb://192.168.0.6/MO-JAS-Sales Scans/\"" | tee -a $directory"Sales Scans.command"
fi
if [[ $groupMembership == *"PurchasingTeam_Access"* ]]; then
    touch $directory"Purchasing Scans.command"
    chmod +x $directory"Purchasing Scans.command"
    echo '#!/bin/bash' | tee -a $directory"Purchasing Scans.command"
    echo "open \"smb://192.168.0.6/Purchasing Scans/\"" | tee -a $directory"Purchasing Scans.command"
fi
if [[ $groupMembership == *"MarketingTeam_Access"* ]]; then
    touch $directory"Marketing Scans.command"
    chmod +x $directory"Marketing Scans.command"
    echo '#!/bin/bash' | tee -a $directory"Marketing Scans.command"
    echo "open \"smb://192.168.0.6/Marketing Scans/\"" | tee -a $directory"Marketing Scans.command"
fi
if [[ $groupMembership == *"LeadershipTeam_Access"* ]]; then
    touch $directory"Leadership Scans.command"
    chmod +x $directory"Leadership Scans.command"
    echo '#!/bin/bash' | tee -a $directory"Leadership Scans.command"
    echo "open \"smb://192.168.0.6/Leadership Scans/\"" | tee -a $directory"Leadership Scans.command"
fi
if [[ $groupMembership == *"ITTeam_Access"* ]]; then
    touch $directory"IT Scans.command"
    chmod +x $directory"IT Scans.command"
    echo '#!/bin/bash' | tee -a $directory"IT Scans.command"
    echo "open \"smb://192.168.0.6/IT Scans/\"" | tee -a $directory"IT Scans.command"
fi
if [[ $groupMembership == *"HRTeam_Access"* ]]; then
    touch $directory"HR Scans.command"
    chmod +x $directory"HR Scans.command"
    echo '#!/bin/bash' | tee -a $directory"HR Scans.command"
    echo "open \"smb://192.168.0.6/HR Scans/\"" | tee -a $directory"HR Scans.command"
fi
if [[ $groupMembership == *"ArchitectureTeam_Access"* ]]; then
    touch $directory"Architecture Scans.command"
    chmod +x $directory"Architecture Scans.command"
    echo '#!/bin/bash' | tee -a $directory"Architecture Scans.command"
    echo "open \"smb://192.168.0.6/Architecture Scans/\"" | tee -a $directory"Architecture Scans.command"
fi
if [[ $groupMembership == *"AccountingTeam_Access"* ]]; then
    touch $directory"Accounting Scans.command"
    chmod +x $directory"Accounting Scans.command"
    echo '#!/bin/bash' | tee -a $directory"Accounting Scans.command"
    echo "open \"smb://192.168.0.6/Accounting Scans/\"" | tee -a $directory"Accounting Scans.command"
fi
EOF

# Load the plist using launchctl
sudo launchctl load $plistfile
