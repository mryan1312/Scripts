#!/bin/bash

## Set up Secure Network ##
INTERFACE="en0"
NETCHANGE=0

# Retrieve WIFI connection info and isolate SSID #
SSID=$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | grep -E ' SSID:[a-z,A-Z,0-9 ]*' | sed 's/^[ ]*SSID\:[ ]//')

# Check current SSID against expected values #
if [ "$SSID" == "net1" ]; then
    NETCHANGE=1
fi
if [ "$SSID" == "net2" ]; then
    NETCHANGE=1
fi
if [ "$SSID" == "net_secure" ]; then
    NETCHANGE=2
fi

# Taking action only if on mobile or guest networks #
if [ $NETCHANGE = 1 ]; then
    echo "Setting up Secure Network"
    networksetup -setairportnetwork $INTERFACE net_secure "password"
    echo "Removing other Networks"
    networksetup -removepreferredwirelessnetwork $INTERFACE net1
    networksetup -removepreferredwirelessnetwork $INTERFACE net2
    sleep 60
fi
if [ $NETCHANGE = 2 ]; then
    echo "Device already on Secure Network."
fi
if [ $NETCHANGE = 0 ]; then
    echo "Device on non-standard network, possibly not on location. No Action taken"
fi

## Set up Displaylink Driver ##
curl -O https://www.synaptics.com/sites/default/files/exe_files/2023-10/DisplayLink%20Manager%20Graphics%20Connectivity1.10-EXE.pkg
sudo installer -package DisplayLink%20Manager%20Graphics%20Connectivity1.10-EXE.pkg -target /

## Printer Setup ##
# Test if drivers exist and install if not
TESTFILE1=/Library/Printers/PPDs/Contents/Resources/CNPZBMF6100ZB.ppd.gz
if test -f "$TESTFILE1"; then
    echo "MF_Printer_Installer.pkg already installed"
else
    curl -O https://gdlp01.c-wss.com/gds/7/0100012017/02/mac-mf-v101111-00.dmg
    hdiutil attach mac-mf-v101111-00.dmg
    sudo installer -package /Volumes/mac-mf-v101111-00/MF_Printer_Installer.pkg -target /
    hdiutil detach /Volumes/mac-mf-v101111-00
    rm mac-mf-v101111-00.dmg
fi
TESTFILE2=/Library/Printers/PPDs/Contents/Resources/CNPZUIPRC170ZU.ppd.gz
if test -f "$TESTFILE2"; then
    echo "UFRII_LT_LIPS_LX_Installer.pkg already installed"
else
    curl -O https://gdlp01.c-wss.com/gds/5/0100011755/07/mac-UFRII-LIPSLX-v101916-00.dmg
    hdiutil attach mac-UFRII-LIPSLX-v101916-00.dmg
    sudo installer -package /Volumes/mac-UFRII-LIPSLX-v101916-00/UFRII_LT_LIPS_LX_Installer.pkg -target /
    hdiutil detach /Volumes/mac-UFRII-LIPSLX-v101916-00
    rm mac-UFRII-LIPSLX-v101916-00.dmg
fi

# Cleanup Old Printer Instances
lpadmin -x _PRN_1
lpadmin -x _PRN_2
lpadmin -x _PRN_3
lpadmin -x _PRN_4
lpadmin -x _PRN_5
lpadmin -x _PRN_6
lpadmin -x _PRN_7
lpadmin -x _PRN_8

# Create New Printers. Canons use LPD and their own PPD, all other use IPP and generic airprint PPD.
lpadmin -p _PRN_1 -D "_PRN_1806_MO-JAS_HP" -E -v ipp://192.168.1.50 -P /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/Resources/AirPrint.ppd
lpadmin -p _PRN_2 -D "_PRN_1810_MO-JAS_MFP" -E -v ipp://192.168.1.53 -P /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/Resources/AirPrint.ppd
lpadmin -p _PRN_3 -D "_PRN_AR_MHC_640_HP" -E -v ipp://192.168.7.19 -P /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/Resources/AirPrint.ppd
lpadmin -p _PRN_4 -D "_PRN_HO_Antillon_Pkwy_HP" -E -v ipp://172.16.100.62/ -P /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/Resources/AirPrint.ppd
lpadmin -p _PRN_5 -D "_PRN_HO_Mitchell_Way_Epson" -E -v ipp://192.168.0.50 -P /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/Resources/AirPrint.ppd
lpadmin -p _PRN_6 -D "_PRN_HO_Schuber_Pl_HP" -E -v ipp://192.168.0.52 -P /System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/PrintCore.framework/Versions/A/Resources/AirPrint.ppd
lpadmin -p _PRN_7 -L "_PRN_AR_MHC_600_Canon" -E -v lpd://172.16.102.20 -P /Library/Printers/PPDs/Contents/Resources/CNPZBD1500ZB.ppd.gz
lpadmin -p _PRN_8 -L "_PRN_HO_Mitchell_Way_Canon" -E -v lpd://192.168.0.104 -P /Library/Printers/PPDs/Contents/Resources/CNPZBMF6100ZB.ppd.gz