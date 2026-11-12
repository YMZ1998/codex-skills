# Environment Reference - Enterprise Transparent Encryption (TSD/DLP)

## What the container is

Files protected by the enterprise DLP client begin with the ASCII bytes `%TSD-Header-###%` instead of a real Office header:

| Real format | Magic bytes |
|---|---|
| Word 97-2003 / Excel 97-2003 (OLE) | `D0 CF 11 E0 A1 B1 1A E1` |
| OOXML `.docx` / `.xlsx` / `.pptx` (ZIP) | `50 4B 03 04` (`PK\x03\x04`) |
| DLP-encrypted container | `25 54 53 44 2D 48 65 61` (`%TSD-Hea`) |

Observed encrypted headers:

```
%TSD-Header-###%
```

The extension is meaningless here: a `.doc` with this header is neither OLE nor a Word binary, and a `.docx` with this header is not a ZIP. Tools that parse the bytes (`editor_sdk`, `python-docx`, `openpyxl`, `antiword`, LibreOffice) all fail or produce garbage.

## Why Word works

The DLP client installs a transparent-decryption layer that grants on-the-fly plaintext only to authorized processes at read time. Microsoft Word, running as the logged-in user, is such a process. Therefore:

- `Document.Content.Text` returns the actual document text.
- `Document.Tables`, `Sections`, `Fields`, `TablesOfContents` are all fully usable.
- The same DLP layer re-wraps **every file Word writes**. `SaveAs2`, `Save`, and even saving a newly created blank document all produce `%TSD-` output.

This is an authorization-based read path, not a decryption algorithm. It works only on the machine with the DLP client, under the logged-in user's session. Do not attempt to reverse the container format.

### Verify the asymmetry (one-time sanity check)

```powershell
# 1. python-docx writes a genuine ZIP
python -c "from docx import Document; d=Document(); d.add_paragraph('probe'); d.save('_py_probe.docx')"
python -c "print(open('_py_probe.docx','rb').read(8))"
# -> b'PK\x03\x04\x14\x00\x00\x00'

# 2. Word writing the same thing is re-encrypted
powershell -Command "$w=New-Object -ComObject Word.Application; $w.Visible=$false; $d=$w.Documents.Add(); $d.SaveAs2((Resolve-Path '_probe.docx'),16); $d.Close(0); $w.Quit(0)"
python -c "print(open('_probe.docx','rb').read(8))"
# -> b'%TSD-Hea'
```

Conclusion: Word is a reader; `python-docx` is the writer.

## Full Word COM extraction snippet

Use this when the bundled script needs adapting. Windows PowerShell 5.1 syntax; avoid `&&`, `?.` and `??`.

```powershell
$ErrorActionPreference = 'Stop'
$src = 'D:\文档\模板.doc'
$out = "$env:TEMP\wb_docx\template.txt"

# Reuse the running, DLP-authorized Word instance. Fall back to a hidden one,
# and only quit the instance this code created.
$word = $null; $createdNew = $false
try   { $word = [Runtime.InteropServices.Marshal]::GetActiveObject('Word.Application') }
catch { $word = New-Object -ComObject Word.Application; $word.Visible = $false; $createdNew = $true }
$word.DisplayAlerts = 0

$doc = $null
try {
    # Open(FileName, ConfirmConversions, ReadOnly, AddToRecentFiles)
    $doc = $word.Documents.Open($src, $false, $true, $false)
    $text = $doc.Content.Text
    [System.IO.File]::WriteAllText(
        $out, $text, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "chars=$($text.Length) tables=$($doc.Tables.Count)"
} finally {
    if ($doc)  { $doc.Close(0) }
    if ($createdNew) { $word.Quit(0) }
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($word)
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
}
```

Notes:

- `Content.Text` flattens tables: cells end with `\r\a` (CR + BEL). To preserve structure, iterate `table.Range.Cells` and group by `RowIndex` — this is safe for merged cells, unlike `table.Rows`.
- Prefer `GetActiveObject` over `New-Object`: a freshly launched Word process may not yet hold DLP authorization.
- Never `Quit()` a borrowed instance; that closes the user's open documents.
- Write text with `.NET File.WriteAllText`, not `Out-File` / `Set-Content` (PowerShell 5.1 defaults to UTF-16LE and adds a BOM).

## Updating fields (TOC, PAGE, NUMPAGES)

Directory and page-number fields are only correct after a full update across all story ranges:

```powershell
$d.Fields.Update() | Out-Null
foreach ($s in $d.StoryRanges) { try { $s.Fields.Update() | Out-Null } catch {} }
$d.Repaginate()
$pages = $d.ComputeStatistics(2)   # wdStatisticPages
```

Without the `StoryRanges` loop, headers/footers keep stale values (e.g. "第 1 页，共 2 页" on a 61-page document) and TOC entries show wrong page numbers.

## Generating the deliverable with python-docx

Install if needed:

```powershell
python -m pip install python-docx --quiet
python -c "import docx; print(docx.__version__)"   # verified 1.2.0
```

Structure content generation as a **re-runnable generator script + a separate data module**, e.g. `build_plan.py` + `plan_data.py`. Keep the generated `.docx` disposable. Verified output characteristics:

```
SIZE: 70512
HEAD: 50 4b 03 04 -> PLAIN DOCX
OPEN_OK pages=61 tables=95 TOC=1
FOOTER_TEXT=第 1 页，共 61 页
```

Useful OOXML details when reproducing a corporate template:

- Standard OOXML field for a page number: `w:fldSimple`/`w:instrText` with `PAGE` and `NUMPAGES`; enable `<w:updateFields w:val="true"/>` in `settings.xml` so Word refreshes on open.
- TOC field: `TOC \o "1-3" \h \z \u`.
- Table styling via XML: `w:tblBorders`, `w:tblCellMar`, `w:shd`, `w:tblHeader` (repeat header row), and `WD_ROW_HEIGHT_RULE.AT_LEAST`.
- To keep dozens of tables consistent, register each table with its `(header, label_cols, center_cols)` metadata when it is created, then apply one `standardize_all()` pass before `doc.save()`. Retro-fitting styles afterwards is unreliable because the delivered file may already be re-encrypted.

## The re-encryption trap after delivery

A plain `.docx` that is opened in Word, WPS, `editor_sdk`, or a preview panel can be re-encrypted in place back to `%TSD-`. Symptoms:

- `python-docx` raises `PackageNotFoundError: Package not found at '...'`.
- The file header reads `25 54 53 44 ...` instead of `50 4B 03 04`.
- The file size changes to a round DLP block size (e.g. 106496).

Recovery: do **not** try to repair or decrypt. Re-run the generator script to overwrite the deliverable from the data module, then check the header again. This is why the generator must always be kept and be idempotent.

## Machine prerequisites checklist

- Windows with the DLP client installed and the user logged in / authorized.
- Microsoft Word installed (COM automation available). A running Word instance is preferred.
- Windows PowerShell 5.1 (for `Marshal.GetActiveObject`).
- Python 3 with `python-docx`.
- Not available in this environment: `soffice`, `libreoffice`, `antiword`, `wvText`, `pandoc`, `pywin32` (COM is done from PowerShell instead).
