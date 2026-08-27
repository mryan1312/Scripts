# Convert-DocxToPdf-Batch.ps1
# Runs one DOCX conversion per separate PowerShell process with timeout + cleanup.

$folderPath       = "C:\temp\Test"
$outputFolderPath = "C:\temp\Out"
$timeoutSeconds   = 60   # per document
$workerPath       = Join-Path $PSScriptRoot "Convert-OneDocToPdf-Worker.ps1"

if (-not (Test-Path $folderPath)) { throw "Input folder not found: $folderPath" }
if (-not (Test-Path $outputFolderPath)) { New-Item -ItemType Directory -Path $outputFolderPath | Out-Null }
if (-not (Test-Path $workerPath)) { throw "Worker script not found: $workerPath" }

$files = Get-ChildItem -Path $folderPath -Filter *.docx -File
if (-not $files) {
    Write-Host "No .docx files found in $folderPath"
    exit 0
}

function Kill-WordProcesses {
    # Brutal by design. This is why we isolate per-doc.
    Get-Process WINWORD -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

Write-Host "Converting $($files.Count) file(s) with $timeoutSeconds s timeout each..."
foreach ($file in $files) {
    $pdfName    = [System.IO.Path]::ChangeExtension($file.Name, ".pdf")
    $outputPath = Join-Path $outputFolderPath $pdfName

    Write-Host "`n=== $($file.Name) ==="
    Write-Host "-> $outputPath"

    # Start a separate PowerShell process to do ONE conversion.
    $args = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$workerPath`"",
        "-DocPath", "`"$($file.FullName)`"",
        "-PdfPath", "`"$outputPath`""
    )

    $p = Start-Process -FilePath "powershell.exe" -ArgumentList $args -PassThru -WindowStyle Hidden

    if ($p.WaitForExit($timeoutSeconds * 1000)) {
        if ($p.ExitCode -eq 0 -and (Test-Path $outputPath)) {
            Write-Host "OK"
        } else {
            Write-Warning "FAILED (exit code $($p.ExitCode))."
        }
    }
    else {
        Write-Warning "TIMEOUT after $timeoutSeconds seconds. Killing worker + WINWORD."
        try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {}
        Kill-WordProcesses
    }
}

Write-Host "`nDone. If any files failed, Word probably hates them specifically."
