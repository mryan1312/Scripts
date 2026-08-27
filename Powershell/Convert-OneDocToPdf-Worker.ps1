# Convert-OneDocToPdf-Worker.ps1
param(
    [Parameter(Mandatory=$true)][string]$DocPath,
    [Parameter(Mandatory=$true)][string]$PdfPath
)

$wdExportFormatPDF = 17
$wdFormatPDF       = 17
$wdAlertsNone      = 0
$msoAutomationSecurityForceDisable = 3

$word = $null
$doc  = $null

try {
    if (-not (Test-Path $DocPath)) { throw "Doc not found: $DocPath" }

    $outDir = Split-Path -Parent $PdfPath
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = $wdAlertsNone
    $word.ScreenUpdating = $false

    # Minimize “helpfulness”
    $word.Options.UpdateLinksAtOpen = $false
    $word.Options.SaveNormalPrompt  = $false
    $word.Options.BackgroundSave    = $false

    # Disable macros (very common cause of hangs)
    $word.AutomationSecurity = $msoAutomationSecurityForceDisable

    # Open read-only, don’t add to recent
    $doc = $word.Documents.Open($DocPath, $false, $true, $false)

    # Force layout before export (reduces export hangs)
    $doc.Repaginate()

    # Try export path, fallback to SaveAs2
    try {
        $doc.ExportAsFixedFormat($PdfPath, $wdExportFormatPDF)
    }
    catch {
        $doc.SaveAs2($PdfPath, $wdFormatPDF)
    }

    if (-not (Test-Path $PdfPath)) {
        throw "No PDF produced (Word claimed it did the thing, but reality disagreed)."
    }

    exit 0
}
catch {
    # Write something minimal; parent reads exit code anyway.
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 2
}
finally {
    try {
        if ($doc) { $doc.Close(0) | Out-Null }
    } catch {}

    try {
        if ($word) { $word.Quit() | Out-Null }
    } catch {}

    # COM cleanup
    try {
        if ($doc)  { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc)  | Out-Null }
        if ($word) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null }
    } catch {}

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
