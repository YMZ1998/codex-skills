<#
.SYNOPSIS
Verify a generated .docx through Word COM without risking DLP re-encryption
of the delivered original.

.DESCRIPTION
Opening a plain .docx in Word (or a preview panel) can cause the DLP client to
re-encrypt it in place. This script copies the file into a unique %TEMP% folder,
opens the copy read-only, reports statistics, then discards the copy.

.PARAMETER Path
The .docx to verify. Never modified.

.PARAMETER UpdateFields
Update TOC / PAGE / NUMPAGES fields across all story ranges and repaginate
before reporting. Required for trustworthy page counts and TOC page numbers.

.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File verify_docx.ps1 `
  -Path "D:\文档\交付物.docx" -UpdateFields
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Path,
    [switch] $UpdateFields
)

$ErrorActionPreference = "Stop"

$src = (Resolve-Path -LiteralPath $Path).Path
$work = Join-Path $env:TEMP ("wb_verify_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Path $work -Force | Out-Null
$copy = Join-Path $work (Split-Path $src -Leaf)
Copy-Item -LiteralPath $src -Destination $copy -Force

$word = $null
$createdNew = $false
try {
    $word = [Runtime.InteropServices.Marshal]::GetActiveObject("Word.Application")
} catch {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $createdNew = $true
}
try { $word.DisplayAlerts = 0 } catch { }

$doc = $null
try {
    $doc = $word.Documents.Open($copy, $false, $true, $false)

    if ($UpdateFields) {
        try { $doc.Fields.Update() | Out-Null } catch { }
        # Headers/footers live in separate story ranges; Fields.Update() alone
        # does not refresh them.
        foreach ($story in $doc.StoryRanges) {
            try { $story.Fields.Update() | Out-Null } catch { }
        }
        $doc.Repaginate()
    }

    $pages = $doc.ComputeStatistics(2)          # wdStatisticPages = 2
    $tables = $doc.Tables.Count
    $tocCount = @($doc.TablesOfContents).Count
    $footerText = ""
    try {
        # wdHeaderFooterPrimary = 1
        $footerText = $doc.Sections.Item(1).Footers.Item(1).Range.Text
    } catch { }
    $footerText = ($footerText -replace "[\r\n\a\x07]", " ").Trim()

    Write-Host ("OPEN_OK copy={0}" -f $copy)
    Write-Host ("  pages={0} tables={1} TOC={2}" -f $pages, $tables, $tocCount)
    Write-Host ("  footer='{0}'" -f $footerText)
    Write-Host "  original left untouched: $src"
} finally {
    if ($doc -ne $null) {
        try { $doc.Close(0) } catch { }
        try {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($doc)
        } catch { }
    }
    if ($createdNew -and $word -ne $null) {
        try { $word.Quit(0) } catch { }
    }
    if ($word -ne $null) {
        try {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($word)
        } catch { }
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    # Cleanup is scoped to the unique temp folder created above.
    if (Test-Path -LiteralPath $work) {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}
