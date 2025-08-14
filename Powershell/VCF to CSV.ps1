# Define input and output file paths
$vcfFile = "contacts.vcf"
$csvFile = "contacts.csv"

# Initialize an array to store contact data
$contacts = @()

# Read the .vcf file line by line
$vcfContent = Get-Content -Path $vcfFile

foreach ($line in $vcfContent) {
    if ($line -match "^BEGIN:VCARD") {
        # Start a new contact
        $currentContact = [Ordered]@{
        "First Name" = ""
        "Middle Name" = ""
        "Last Name" = ""
        "Title" = ""
        "Suffix" = ""
        "Web Page" = ""
        "Birthday" = ""
        "Anniversary" = ""
        "Notes" = ""
        'E-mail Address' = ""
        'E-mail 2 Address' = ""
        'E-mail 3 Address' = ""
        "Primary Phone" = ""
        "Home Phone" = ""
        "Home Phone 2" = ""
        "Mobile Phone" = ""
        "Pager" = ""
        "Home Fax" = ""
        "Home Address" = ""
        "Home Street" = ""
        "Home Street 2" = ""
        "Home Street 3" = ""
        "Home Address PO Box" = ""
        "Home City" = ""
        "Home State" = ""
        "Home Postal Code" = ""
        "Home Country" = ""
        "Spouse" = ""
        "Children" = ""
        "Manager's Name" = ""
        "Assistant's Name" = ""
        "Referred By" = ""
        "Company Main Phone" = ""
        "Business Phone" = ""
        "Business Phone 2" = ""
        "Business Fax" = ""
        "Assistant's Phone" = ""
        "Company" = ""
        "Job Title" = ""
        "Department" = ""
        "Business Address" = ""
        "Business Street" = ""
        "Business Street 2" = ""
        "Business Street 3" = ""
        "Business Address PO Box" = ""
        "Business City" = ""
        "Business State" = ""
        "Business Postal Code" = ""
        "Business Country" = ""
        "Other Phone" = ""
        "Other Fax" = ""
        "Other Address" = ""
        "Other Street" = ""
        "Other Street 2" = ""
        "Other Street 3" = ""
        "Other Address PO Box" = ""
        "Other City" = ""
        "Other State" = ""
        "Other Postal Code" = ""
        "Other Country" = ""
        "Callback" = ""
        "Car Phone" = ""
        "ISDN" = ""
        "Radio Phone" = ""
        "TTY/TDD Phone" = ""
        "Telex" = ""
        "Categories" = "myContacts"
        }
    }
    if ($line -match "(FN):(.*)") {
        # Extract fields (e.g., Full Name, Telephone, Email)
        $currentContact["First Name"] = $matches[2]
    }
    if ($line -match "(EMAIL.*):(.*@.*)") {
        $currentContact['E-mail Address'] = $matches[2]
    }
    if ($line -match "(TEL);.*(\+?\d*\(?\d{3}\)? ?-?\d{3} ?-?\d{4})") {
        $currentContact["Primary Phone"] = $matches[2]
    }
    if ($line -match "ORG:(.*)") {
        $currentContact["Company"] = $matches[1]
    }
    if ($line -match "TITLE:(.*)") {
        $currentContact["Job Title"] = $matches[1]
    }
        if ($line -match "^END:VCARD") {
        # Add the completed contact to the array
        $contacts += New-Object PSObject -Property $currentContact
    }
}

# Export the contacts to a CSV file
$contacts | Export-csv -NoTypeInformation -Encoding UTF8 -Path $csvFile

Write-Host "Conversion complete! CSV saved to $csvFile"
