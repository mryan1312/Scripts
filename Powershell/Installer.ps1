# Run the installer script with installers from the SMH app server in the same folder. I would like to have it
# retrieve the installers from the app server, but there are permission issues with that I cannot work around yet

# Check the folder for installers and run them
if (Test-Path -path "C:\Adobe installer") {
    & "C:\installer" /switches
}
if (Test-Path -path "C:\Chrome installer") {
    & "C:\installer" /switches
}
if (Test-Path -path "C:\Office.zip") {
    Expand-Archive C:\Office.zip -DestinationPath C:\
    & setup.exe /download configuration-Office365Business-x64.xml
    & setup.exe /configure configuration-Office365Business-x64.xml
}
if (Test-Path -path "C:\revit installer") {
    & "C:\installer" /switches
}
if (Test-Path -path "C:\autocad installer") {
   & "C:\installer" /switches
}

# Set Power Settings
powercfg /change standby-timeout-ac 20
powercfg /change standby-timeout-dc 10
powercfg /change monitor-timeout-ac 10
powercfg /change monitor-timeout-dc 5