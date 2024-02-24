$appList = Import-Csv "S:\Matt Adams\Powershell Scripts\Testing\SoftwareSources.csv" | Group-Object -AsHashTable -Property ID
Write-Host $appList