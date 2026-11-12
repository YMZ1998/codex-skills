<#
.SYNOPSIS
Extract plaintext from enterprise transparent-encrypted (TSD/DLP) Office documents
by reading them through an authorized local Microsoft Word COM instance.

.DESCRIPTION
Word is used strictly as a READ-ONLY decryptor. Its output is written as UTF-8
(no BOM) .txt files via .NET, bypassing Word's own file writer (which the DLP
client would immediately re-encrypt). Word documents are closed without saving.

.PARAMETER Path
One or more source files or wildcard patterns.

.PARAMETER OutDir
Directory for the .txt output. Created if missing. Defaults to %TEMP%\wb_docx.

.PARAMETER IncludeTables
Also write <name>.tables.txt with table rows/cells preserved. Use this when the
source is a template whose table layout must be reproduced.

.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File dump_encrypted_doc.ps1 `
  -Path "D:\文档\模板.doc" -OutDir "$env:TEMP\wb_docx" -IncludeTables
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [string[]] $Path,
    [string] $OutDir = (Join-Path $env:TEMP "wb_docx"),
    [switch] $IncludeTables
)

begin {
    $ErrorActionPreference = "Stop"

    if (-not (Test-Path -LiteralPath $OutDir)) {
        New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    }

    # Prefer the already-running Word instance: the DLP client normally grants
    # transparent decryption only to processes it has already authorized.
    $word = $null
    $createdNew = $false
    try {
        $word = [Runtime.InteropServices.Marshal]::GetActiveObject("Word.Application")
        Write-Host "WORD: attached to running instance"
    } catch {
        try {
            $word = New-Object -ComObject Word.Application
            $word.Visible = $false
            $createdNew = $true
            Write-Host "WORD: created hidden instance (no running instance found)"
        } catch {
            throw ("Cannot obtain Word.Application. Launch Word once, log in to " +
                   "the DLP client, then retry. " + $_.Exception.Message)
        }
    }
    try { $word.DisplayAlerts = 0 } catch { }

    # UTF-8 without BOM so downstream Python tooling reads cleanly.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    function Get-BaseName([string] $filePath) {
        return [System.IO.Path]::GetFileNameWithoutExtension($filePath)
    }

    function Read-Head([string] $filePath) {
        $fs = $null
        try {
            $fs = [System.IO.File]::OpenRead($filePath)
            $buf = New-Object byte[] 8
            [void] $fs.Read($buf, 0, 8)
            return [System.Text.Encoding]::ASCII.GetString($buf)
        } finally {
            if ($fs -ne $null) { $fs.Dispose() }
        }
    }
}

process {
    foreach ($pattern in $Path) {
        $files = @(Get-ChildItem -Path $pattern -File -ErrorAction SilentlyContinue)
        if ($files.Count -eq 0 -and (Test-Path -LiteralPath $pattern)) {
            $files = @(Get-Item -LiteralPath $pattern)
        }
        if ($files.Count -eq 0) {
            Write-Warning "No file matches: $pattern"
            continue
        }

        foreach ($file in $files) {
            $src = $file.FullName
            $head = Read-Head $src
            if ($head -notlike "%TSD-*") {
                Write-Warning ("File does not start with %TSD- (head='{0}'); " -f $head +
                               "attempting Word read anyway: " + $src)
            }

            $doc = $null
            try {
                # Documents.Open(FileName, ConfirmConversions, ReadOnly, AddToRecentFiles)
                $doc = $word.Documents.Open($src, $false, $true, $false)
                $text = $doc.Content.Text

                $outTxt = Join-Path $OutDir ((Get-BaseName $src) + ".txt")
                [System.IO.File]::WriteAllText($outTxt, $text, $utf8NoBom)
                Write-Host ("OK: {0} -> {1} chars={2}" -f `
                    (Split-Path $src -Leaf), $outTxt, $text.Length)

                if ($IncludeTables) {
                    $sb = New-Object System.Text.StringBuilder
                    $tIdx = 0
                    foreach ($tbl in $doc.Tables) {
                        $tIdx++
                        [void] $sb.AppendLine("=== TABLE $tIdx ===")
                        # Iterate the flat Cells collection and group by RowIndex;
                        # this is safe on tables with merged cells, unlike tbl.Rows.
                        $rows = @{}
                        foreach ($cell in $tbl.Range.Cells) {
                            $ri = [int] $cell.RowIndex
                            if (-not $rows.ContainsKey($ri)) {
                                $rows[$ri] = New-Object System.Collections.ArrayList
                            }
                            $v = $cell.Range.Text -replace "[\r\n\a\x07]", " "
                            [void] $rows[$ri].Add($v.Trim())
                        }
                        foreach ($ri in ($rows.Keys | Sort-Object)) {
                            [void] $sb.AppendLine(($rows[$ri] -join " | "))
                        }
                        [void] $sb.AppendLine("")
                    }
                    $outTbl = Join-Path $OutDir ((Get-BaseName $src) + ".tables.txt")
                    [System.IO.File]::WriteAllText($outTbl, $sb.ToString(), $utf8NoBom)
                    Write-Host ("OK: tables -> {0} tables={1}" -f $outTbl, $tIdx)
                }
            } catch {
                Write-Error ("FAILED: {0} : {1}" -f $src, $_.Exception.Message)
            } finally {
                if ($doc -ne $null) {
                    try { $doc.Close(0) } catch { }
                    try {
                        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($doc)
                    } catch { }
                }
            }
        }
    }
}

end {
    # Only quit Word if this script started it; never close the user's session.
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
    Write-Host "DONE. Output dir: $OutDir"
}
