#!/bin/bash
#Load user folder directories into an array and iterate through each
array2=(/Users/*/)
for dir in "${array2[@]}"
do
    # reset variables for each iteration
    Build_Access=0
    Sales_Access=0
    Purchasing_Access=0
    Marketing_Access=0
    Leadership_Access=0
    Itteam_Access=0
    Hrteam_Access=0
    Architecture_Access=0
    Accounting_Access=0
    #stripping leading directories
    b=${dir:7}
    #stripping final backslash so c is just the username
    c=${b%/*}
    #querying username for group memberships and loading memberships into an array
    Groups="$(id -Gn $c)" 
    IFS=', ' read -r -a array <<< "$Groups"
    #iterate through each group and check if it is one of the specified groups, setting variable if true.
    for element in "${array[@]}"
    do
        if [[ "$element" =~ (SMH_MO-JAS_Build_Access)$ ]]; then
            Build_Access=1
            echo "$element"
        fi
        if [[ "$element" =~ (SMH_MO-JAS_Sales_Access)$ ]]; then
            Sales_Access=1
            echo "$element"
        fi
        if [[ "$element" =~ (PurchasingTeam_Access)$ ]]; then
            Purchasing_Access=1
            echo "$element"
        fi
        if [[ "$element" =~ (MarketingTeam_Access)$ ]]; then
            Marketing_Access=1
            echo "$element"
        fi
        if [[ "$element" =~ (LeadershipTeam_Access)$ ]]; then
            Leadership_Access=1
            echo "$element"
        fi
        if [[ "$element" =~ (ITTeam_Access)$ ]]; then
            Itteam_Access=1
            echo "$element"
        fi
        if [[ "$element" =~ (HRTeam_Access)$ ]]; then
            Hrteam_Access=1
            echo "$element"
        fi
        if [[ "$element" =~ (ArchitectureTeam_Access)$ ]]; then
            Architecture_Access=1
            echo "$element"
        fi
        if [[ "$element" =~ (AccountingTeam_Access)$ ]]; then
            Accounting_Access=1
            echo "$element"
        fi
    done
    #Cleaning up old shortcuts, in case there are group changes
    sudo rm $dir"Desktop/Build Scans.command"
    sudo rm $dir"Desktop/Sales Scans.command"
    sudo rm $dir"Desktop/Purchasing Scans.command"
    sudo rm $dir"Desktop/Marketing Scans.command"
    sudo rm $dir"Desktop/Leadership Scans.command"
    sudo rm $dir"Desktop/IT Scans.command"
    sudo rm $dir"Desktop/HR Scans.command"
    sudo rm $dir"Desktop/Architecture Scans.command"
    sudo rm $dir"Desktop/Accounting Scans.command"
    #Checking each variable, creating a shortcut to open that scan folder on the user desktop.
    if [ $Build_Access == 1 ]; then
        sudo touch $dir"Desktop/Build Scans.command"
        sudo chmod +x $dir"Desktop/Build Scans.command"
        echo '#!/bin/bash' | sudo tee -a $dir"Desktop/Build Scans.command"
        echo "open \"smb://192.168.0.6/MO-JAS-Other Scans/\"" | sudo tee -a $dir"Desktop/Build Scans.command"
        sudo chown $c $dir"Desktop/Build Scans.command"
        echo "Build Scan Shortcut Created for user: " $c
    fi
    if [ $Sales_Access == 1 ]; then
        sudo touch $dir"Desktop/Sales Scans.command"
        sudo chmod +x $dir"Desktop/Sales Scans.command"
        echo '#!/bin/bash' | sudo tee -a $dir"Desktop/Sales Scans.command"
        echo "open \"smb://192.168.0.6/MO-JAS-Sales Scans/\"" | sudo tee -a $dir"Desktop/Sales Scans.command"
        sudo chown $c $dir"Desktop/Sales Scans.command"
        echo "Sales Scan Shortcut Created for user: " $c
    fi
    if [ $Purchasing_Access == 1 ]; then
        sudo touch $dir"Desktop/Purchasing Scans.command"
        sudo chmod +x $dir"Desktop/Purchasing Scans.command"
        echo '#!/bin/bash' | sudo tee -a $dir"Desktop/Purchasing Scans.command"
        echo "open \"smb://192.168.0.6/Purchasing Scans/\"" | sudo tee -a $dir"Desktop/Purchasing Scans.command"
        sudo chown $c $dir"Desktop/Purchasing Scans.command"
        echo "Purchasing Scan Shortcut Created for user: " $c
    fi
    if [ $Marketing_Access == 1 ]; then
        sudo touch $dir"Desktop/Marketing Scans.command"
        sudo chmod +x $dir"Desktop/Marketing Scans.command"
        echo '#!/bin/bash' | sudo tee -a $dir"Desktop/Marketing Scans.command"
        echo "open \"smb://192.168.0.6/Marketing Scans/\"" | sudo tee -a $dir"Desktop/Marketing Scans.command"
        sudo chown $c $dir"Desktop/Marketing Scans.command"
        echo "Marketing Scan Shortcut Created for user: " $c
    fi
    if [ $Leadership_Access == 1 ]; then
        sudo touch $dir"Desktop/Leadership Scans.command"
        sudo chmod +x $dir"Desktop/Leadership Scans.command"
        echo '#!/bin/bash' | sudo tee -a $dir"Desktop/Leadership Scans.command"
        echo "open \"smb://192.168.0.6/Leadership Scans/\"" | sudo tee -a $dir"Desktop/Leadership Scans.command"
        sudo chown $c $dir"Desktop/Leadership Scans.command"
        echo "Leadership Scan Shortcut Created for user: " $c
    fi
    if [ $Itteam_Access == 1 ]; then
        sudo touch $dir"Desktop/IT Scans.command"
        sudo chmod +x $dir"Desktop/IT Scans.command"
        echo '#!/bin/bash' | sudo tee -a $dir"Desktop/IT Scans.command"
        echo "open \"smb://192.168.0.6/IT Scans/\"" | sudo tee -a $dir"Desktop/IT Scans.command"
        sudo chown $c $dir"Desktop/IT Scans.command"
        echo "IT Scan Shortcut Created for user: " $c
    fi
    if [ $Hrteam_Access == 1 ]; then
        sudo touch $dir"Desktop/HR Scans.command"
        sudo chmod +x $dir"Desktop/HR Scans.command"
        echo '#!/bin/bash' | sudo tee -a $dir"Desktop/HR Scans.command"
        echo "open \"smb://192.168.0.6/HR Scans/\"" | sudo tee -a $dir"Desktop/HR Scans.command"
        sudo chown $c $dir"Desktop/HR Scans.command"
        echo "HR Scan Shortcut Created for user: " $c
    fi
    if [ $Architecture_Access == 1 ]; then
        sudo touch $dir"Desktop/Architecture Scans.command"
        sudo chmod +x $dir"Desktop/Architecture Scans.command"
        echo '#!/bin/bash' | sudo tee -a $dir"Desktop/Architecture Scans.command"
        echo "open \"smb://192.168.0.6/Architecture Scans/\"" | sudo tee -a $dir"Desktop/Architecture Scans.command"
        sudo chown $c $dir"Desktop/Architecture Scans.command"
        echo "Architecture Scan Shortcut Created for user: " $c
    fi
    if [ $Accounting_Access == 1 ]; then
        sudo touch $dir"Desktop/Accounting Scans.command"
        sudo chmod +x $dir"Desktop/Accounting Scans.command"
        echo '#!/bin/bash' | sudo tee -a $dir"Desktop/Accounting Scans.command"
        echo "open \"smb://192.168.0.6/Accounting Scans/\"" | sudo tee -a $dir"Desktop/Accounting Scans.command"
        sudo chown $c $dir"Desktop/Accounting Scans.command"
        echo "Accounting Scan Shortcut Created for user: " $c
    fi
done
