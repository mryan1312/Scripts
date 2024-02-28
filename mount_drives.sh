#!/bin/bash
plistfile="/Library/LaunchAgents/map_drives.plist"
sudo touch $plistfile
#writing the plist
echo "<?xml version="1.0" encoding="UTF-8"?>" | sudo tee -a $plistfile
echo "<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">" | sudo tee -a $plistfile
echo "<plist version="1.0">" | sudo tee -a $plistfile
echo "<dict>" | sudo tee -a $plistfile
echo "    <key>Label</key>" | sudo tee -a $plistfile
echo "    <string>com.user.loginscript</string>" | sudo tee -a $plistfile
echo "    <key>ProgramArguments</key>" | sudo tee -a $plistfile
echo "    <array>" | sudo tee -a $plistfile
echo "        <string>/bin/sh</string>" | sudo tee -a $plistfile
echo "        <string>/Users/Shared/map_drives.sh</string>" | sudo tee -a $plistfile
echo "    </array>" | sudo tee -a $plistfile
echo "    <key>RunAtLoad</key>" | sudo tee -a $plistfile
echo "    <true/>" | sudo tee -a $plistfile
echo "    <key>KeepAlive</key>" | sudo tee -a $plistfile
echo "    <dict>" | sudo tee -a $plistfile
echo "        <key>SuccessfulExit</key>" | sudo tee -a $plistfile
echo "        <false/>" | sudo tee -a $plistfile
echo "    </dict>" | sudo tee -a $plistfile
echo "</dict>" | sudo tee -a $plistfile
echo "</plist>" | sudo tee -a $plistfile
#Writing the script to shared folder
scriptfile=/Users/Shared/map_drives.sh
sudo touch $scriptfile
sudo chmod +x $scriptfile
sudo chmod 777 $scriptfile
echo '#!/bin/bash' | sudo tee -a $scriptfile
echo "# Get the current user's username and set desktop directory" | sudo tee -a $scriptfile
echo 'user=$(whoami)' | sudo tee -a $scriptfile
echo 'directory="$HOME/Desktop/"' | sudo tee -a $scriptfile
echo "# Check AD group membership" | sudo tee -a $scriptfile
echo 'groupMembership="$(id -Gn $user)"' | sudo tee -a $scriptfile
echo "# Check for specific group memberships and mount shares accordingly" | sudo tee -a $scriptfile
echo 'rm $directory"Build Scans.command"' | sudo tee -a $scriptfile
echo 'rm $directory"Sales Scans.command"' | sudo tee -a $scriptfile
echo 'rm $directory"Purchasing Scans.command"' | sudo tee -a $scriptfile
echo 'rm $directory"Marketing Scans.command"' | sudo tee -a $scriptfile
echo 'rm $directory"Leadership Scans.command"' | sudo tee -a $scriptfile
echo 'rm $directory"IT Scans.command"' | sudo tee -a $scriptfile
echo 'rm $directory"HR Scans.command"' | sudo tee -a $scriptfile
echo 'rm $directory"Architecture Scans.command"' | sudo tee -a $scriptfile
echo 'rm $directory"Accounting Scans.command"' | sudo tee -a $scriptfile
echo 'if [[ $groupMembership == *"SMH_MO-JAS_Build_Access"* ]]; then' | sudo tee -a $scriptfile
echo '    touch $directory"Build Scans.command"' | tee -a $scriptfile
echo '    chmod +x $directory"Build Scans.command"' | tee -a $scriptfile
echo '    echo '#!/bin/bash' | tee -a "$directory"Build Scans.command"' | tee -a $scriptfile
echo '    echo "open \"smb://192.168.0.6/MO-JAS-Other Scans/\"" | -a $directory"Build Scans.command"' | sudo tee -a $scriptfile
echo "fi" | sudo tee -a $scriptfile
echo 'if [[ $groupMembership == *"SMH_MO-JAS_Sales_Access"* ]]; then' | sudo tee -a $scriptfile
echo '    touch $directory"Sales Scans.command"' | sudo tee -a $scriptfile
echo '    chmod +x $directory"Sales Scans.command"' | sudo tee -a $scriptfile
echo '    echo '#!/bin/bash' | tee -a $directory"Sales Scans.command"' | sudo tee -a $scriptfile
echo '    echo "open \"smb://192.168.0.6/MO-JAS-Sales Scans/\"" | tee -a $directory"Sales Scans.command"' | sudo tee -a $scriptfile
echo "fi" | sudo tee -a $scriptfile
echo 'if [[ $groupMembership == *"PurchasingTeam_Access"* ]]; then' | sudo tee -a $scriptfile
echo '    touch $directory"Purchasing Scans.command"' | sudo tee -a $scriptfile
echo '    chmod +x $directory"Purchasing Scans.command"' | sudo tee -a $scriptfile
echo '    echo '#!/bin/bash' | tee -a $directory"Purchasing Scans.command"' | sudo tee -a $scriptfile
echo '    echo "open \"smb://192.168.0.6/Purchasing Scans/\"" | tee -a $directory"Purchasing Scans.command"' | sudo tee -a $scriptfile
echo "fi" | sudo tee -a $scriptfile
echo 'if [[ $groupMembership == *"MarketingTeam_Access"* ]]; then' | sudo tee -a $scriptfile
echo '    touch $directory"Marketing Scans.command"' | sudo tee -a $scriptfile
echo '    chmod +x $directory"Marketing Scans.command"' | sudo tee -a $scriptfile
echo '    echo '#!/bin/bash' | tee -a $directory"Marketing Scans.command"' | sudo tee -a $scriptfile
echo '    echo "open \"smb://192.168.0.6/Marketing Scans/\"" | tee -a $directory"Marketing Scans.command"' | sudo tee -a $scriptfile
echo "fi" | sudo tee -a $scriptfile
echo 'if [[ $groupMembership == *"LeadershipTeam_Access"* ]]; then' | sudo tee -a $scriptfile
echo '    touch $directory"Leadership Scans.command"' | sudo tee -a $scriptfile
echo '    chmod +x $directory"Leadership Scans.command"' | sudo tee -a $scriptfile
echo '    echo '#!/bin/bash' | tee -a $directory"Leadership Scans.command"' | sudo tee -a $scriptfile
echo '    echo "open \"smb://192.168.0.6/Leadership Scans/\"" | tee -a $directory"Leadership Scans.command"' | sudo tee -a $scriptfile
echo "fi" | sudo tee -a $scriptfile
echo 'if [[ $groupMembership == *"ITTeam_Access"* ]]; then' | sudo tee -a $scriptfile
echo '    touch $directory"IT Scans.command"' | sudo tee -a $scriptfile
echo '    chmod +x $directory"IT Scans.command"' | sudo tee -a $scriptfile
echo '    echo '#!/bin/bash' | tee -a $directory"IT Scans.command"' | sudo tee -a $scriptfile
echo '    echo "open \"smb://192.168.0.6/IT Scans/\"" | tee -a $directory"IT Scans.command"' | sudo tee -a $scriptfile
echo "fi" | sudo tee -a $scriptfile
echo 'if [[ $groupMembership == *"HRTeam_Access"* ]]; then' | sudo tee -a $scriptfile
echo '    touch $directory"HR Scans.command"' | sudo tee -a $scriptfile
echo '    chmod +x $directory"HR Scans.command"' | sudo tee -a $scriptfile
echo '    echo '#!/bin/bash' | tee -a $directory"HR Scans.command"' | sudo tee -a $scriptfile
echo '    echo "open \"smb://192.168.0.6/HR Scans/\"" | tee -a $directory"HR Scans.command"' | sudo tee -a $scriptfile
echo "fi" | sudo tee -a $scriptfile
echo 'if [[ $groupMembership == *"ArchitectureTeam_Access"* ]]; then' | sudo tee -a $scriptfile
echo '    touch $directory"Architecture Scans.command"' | sudo tee -a $scriptfile
echo '    chmod +x $directory"Architecture Scans.command"' | sudo tee -a $scriptfile
echo '    echo '#!/bin/bash' | tee -a $directory"Architecture Scans.command"' | sudo tee -a $scriptfile
echo '    echo "open \"smb://192.168.0.6/Architecture Scans/\"" | tee -a $directory"Architecture Scans.command"' | sudo tee -a $scriptfile
echo "fi" | sudo tee -a $scriptfile
echo 'if [[ $groupMembership == *"AccountingTeam_Access"* ]]; then' | sudo tee -a $scriptfile
echo '    touch $directory"Accounting Scans.command"' | sudo tee -a $scriptfile
echo '    chmod +x $directory"Accounting Scans.command"' | sudo tee -a $scriptfile
echo '    echo '#!/bin/bash' | tee -a $directory"Accounting Scans.command"' | sudo tee -a $scriptfile
echo '    echo "open \"smb://192.168.0.6/Accounting Scans/\"" | tee -a $directory"Accounting Scans.command"' | sudo tee -a $scriptfile
echo "fi" | sudo tee -a $scriptfile

sudo chown root $plistfile
sudo launchctl load $plistfile
