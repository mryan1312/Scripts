# This script will build a list of interfaces and mitigate against IPv6 RA/DHCP vulnerabilities.
# For Questions / Comments: madams@kalmersolutions.com

# Check if CIM cmdlets are available, fallback to netsh if not
try { 
    get-netipinterface -ErrorVariable ErrCheck -ErrorAction 'silentlycontinue' > $null
    # There were a few workstations giving invalid class for this, causing it to fail. Catching that.
    if ($ErrCheck -like "*Invalid*") {
        $CIMPresent = $false
    }
    Else {
        $CIMPresent = $true
    }
    
}
catch {
    $CIMPresent = $false
}
# Getting a list of interfaces and building an array for that. Pulling substrings directly from the output to build.
if ($CIMPresent -eq $false) {
    $interfaceList = New-Object System.Collections.Generic.List[Object]
    $cmdResult = $(netsh interface ipv6 show interface)
    $counter = 3
    $arrayLength = $($cmdResult.Length - 1)
    While ($counter -lt $arrayLength) {
        $interfaceList.Add($cmdResult[$counter].substring(43))
        $counter++
    }
    $wmiInterfaces = Get-WmiObject -Class Win32_NetworkAdapter | Select-Object -ExpandProperty Name
    foreach ($interface in $wmiInterfaces) {
        $interfaceList.Add($interface)
    }
}
else {
    # If CIM is present, it is much easier to get a PSObject of Interfaces
    $interfaceList = Get-NetIPInterface | Select-Object -ExpandProperty InterfaceAlias
}
# Iterate through each interface and check the settings. Defaulting to using netsh, however if CIM is present also passing those for good measure.
foreach ($interface in $interfaceList) {
    $getSettings = $(netsh interface ipv6 show interface "$interface")
    if ($getSettings[18] -like "*enabled*") {
        Write-Host "Disabling Router Discovery on $interface."
        $(netsh interface ipv6 set interface "$interface" routerdiscovery=disabled)
        if ($CIMPresent -eq $true) {
            Set-NetIPInterface -InterfaceAlias "$interface" -RouterDiscovery Disabled -PolicyStore ActiveStore
            Set-NetIPInterface -InterfaceAlias "$interface" -RouterDiscovery Disabled -PolicyStore PersistentStore
        }
    }
    else {
        Write-Host "Router Discovery already disabled on $interface."
    }
    if ($getSettings[19] -like "*enabled*") {
        Write-Host "Disabling Managed Address Config on $interface."
        $(netsh interface ipv6 set interface "$interface" managedaddress=disabled)
        $(netsh interface ipv6 set interface "$interface" otherstateful=disabled)
        if ($CIMPresent -eq $true) {
            Set-NetIPInterface -InterfaceAlias "$interface" -ManagedAddressConfiguration Disabled -PolicyStore ActiveStore
            Set-NetIPInterface -InterfaceAlias "$interface" -ManagedAddressConfiguration Disabled -PolicyStore PersistentStore
            Set-NetIPInterface -InterfaceAlias "$interface" -OtherStatefulConfiguration Disabled -PolicyStore ActiveStore
            Set-NetIPInterface -InterfaceAlias "$interface" -OtherStatefulConfiguration Disabled -PolicyStore PersistentStore
        }
    }
    else {
        Write-Host "Managed Address Config already disabled on $interface."
    }
    if ($CIMPresent -eq $true) {
        if ($(Get-NetIPInterface -AddressFamily IPv6 -InterfaceAlias "$interface" | Select-Object -ExpandProperty Dhcp) -eq "Enabled") {
            Write-Host "Disabling DHCP on $interface."
            Set-NetIPInterface -InterfaceAlias "$interface" -AddressFamily IPv6 -Dhcp Disabled -PolicyStore ActiveStore
            Set-NetIPInterface -InterfaceAlias "$interface" -AddressFamily Ipv6 -Dhcp Disabled -PolicyStore PersistentStore
        }
    }
    else {
        Write-Host "DHCP already disabled on $interface."
    }
}

# Verification is handled by Automate, passing the check script again to verify and set extra data fields to remove from the affected group if necessary.
