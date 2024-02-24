# This script checks current SSID for domain joined computers and if on the wrong network, 
# deletes the current wlan profile and sets up the correct wlan network profile

# Initialize Variables
$CurrentSSID = Netsh WLAN show interfaces | findstr /r "^....SSID"
$TargetSSID = "    SSID                   : SMH_SECURE"

# Check if domain joined, set up wifi if on the wrong network.
if ((gwmi win32_computersystem).partofdomain -eq $true) {
    if ($CurrentSSID -eq $TargetSSID) {
        exit
    }
    else {
        Netsh WLAN delete profile "SMH_Mobile"
        Netsh WLAN add profile filename=".\Secure.XML"
        Netsh WLAN connect name="SMH_SECURE"
    }
}