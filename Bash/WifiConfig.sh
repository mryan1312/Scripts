#!/bin/bash

INTERFACE="en0"
SSID=$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | grep -E ' SSID:[a-z,A-Z,0-9 ]*' | sed 's/^[ ]*SSID\:[ ]//')
NETCHANGE=0

if [ "$SSID" == "net1" ]; then
    NETCHANGE=1
fi
if [ "$SSID" == "net2" ]; then
    NETCHANGE=1
fi
if [ "$SSID" == "net_secure" ]; then
    NETCHANGE=2
fi
if [ $NETCHANGE = 1 ]; then
    echo "Setting up Secure Network"
    networksetup -setairportnetwork $INTERFACE net_secure "password"
    echo "Removing other Networks"
    networksetup -removepreferredwirelessnetwork $INTERFACE net1
    networksetup -removepreferredwirelessnetwork $INTERFACE net2
fi
if [ $NETCHANGE = 2 ]; then
    echo "Device already on Secure Network."
fi
if [ $NETCHANGE = 0 ]; then
    echo "Device on non-standard network, possibly not on location. No Action taken"
fi