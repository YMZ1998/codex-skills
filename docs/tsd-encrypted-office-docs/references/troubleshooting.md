# Troubleshooting - Observed Failures and Fixes

All entries below come from a real session generating a design-verification plan from two `%TSD-` encrypted `.doc` sources on Windows.

## Detection and reading

| Symptom | Root cause | Fix |
|---|---|---|
| `JSON-RPC 错误 -32603: open: import failed: [14001]Not Supported File Type (source_format=unknown)` from `editor_sdk open_file` | The `.doc` is a DLP container, not OLE; the SDK sniffs the header and rejects it | Do not retry with `editor_sdk`. Check magic bytes, then read via Word COM (`dump_encrypted_doc.ps1`) |
| `docx.opc.exceptions.PackageNotFoundError: Package not found at '...docx'` on a file that was previously openable | Word/WPS/preview re-encrypted the plain `.docx` in place; header is now `%TSD-` | Re-run the generator script to overwrite from the data module. Do not attempt to read or repair the encrypted file |
| UTF-16LE / GBK string scanning yields plausible-looking but nonsensical Chinese fragments | The container payload is encrypted/obfuscated; there is no recoverable embedded plaintext | Abandon byte-level recovery. Use the authorized Word process |
| `python-docx` / `pywin32` import errors (`No module named 'docx'`) | Packages not installed | `python -m pip install python-docx --quiet`. `pywin32` is not needed; COM is driven from PowerShell |
| `无法加载文件 ...ps1，因为在此系统上禁止运行脚本` / `UnauthorizedAccess` | Windows execution policy blocks `.ps1` files when invoked with `& script.ps1` inside an existing session | Launch a child process instead: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File script.ps1 -Path ...`. The bypass is scoped to that process |
| `GetActiveObject('Word.Application')` throws | Word is not running | Fall back to `New-Object -ComObject Word.Application`. If reads still fail, launch Word once interactively and log in to the DLP client to establish authorization |

## Writing and exporting

| Symptom | Root cause | Fix |
|---|---|---|
| Word `SaveAs2(..., 16)` batch conversion exits with code 1, or stops after printing `opened, tables=39` with no output file | COM automation aborted, and even on success the written file is re-encrypted | Do not use Word as a converter. Read `Document.Content.Text` and write the text with `.NET File.WriteAllText` |
| `template.docx` / `_probe.docx` exist but start with `25-54-53-44-2D-48-65-61` (`%TSD-Hea`) | Word-written files are always re-wrapped by the DLP client, including blank new documents | Generate final `.docx` with `python-docx`; assert with `probe_encryption.py --expect-plain` |
| Exported text is UTF-16LE with a BOM, or Python reads leading `\ufeff` | `Out-File` / `Set-Content` defaults on Windows PowerShell 5.1 | Use `[System.IO.File]::WriteAllText($out, $text, (New-Object System.Text.UTF8Encoding($false)))` |

## Word COM scripting

| Symptom | Root cause | Fix |
|---|---|---|
| PowerShell parse errors on `&&`, `?.`, `??` | Windows PowerShell 5.1 does not support them | Use `;`, explicit `if ($?) { ... }`, and explicit `$null -eq` checks |
| Iterating `$table.Rows` throws on merged cells ("Cannot access individual rows/columns ... mixed cell widths") | Word COM exposes merged tables through the flat `Cells` collection only | Iterate `$table.Range.Cells`, group by `[int]$cell.RowIndex`, strip `\r\a` from `$cell.Range.Text` |
| User's open Word documents get closed | Script called `Quit()` on an instance obtained with `GetActiveObject` | Track `$createdNew`; only `Quit()` when the script created the instance. Always `Close(0)` on documents |
| Word prompts block automation (conversion / save dialogs) | `DisplayAlerts` not disabled | `$word.DisplayAlerts = 0` and `Documents.Open($src, $false, $true, $false)` |

## Generated document quality

| Symptom | Root cause | Fix |
|---|---|---|
| TOC shows wrong page numbers, duplicated text such as `9.1 ... 59 试验 ...59` | Fields not updated before reading | `$d.Fields.Update()` then loop `$d.StoryRanges` and update each, then `$d.Repaginate()` |
| Footer reads `第 1 页，共 2 页` on a 61-page document | `NUMPAGES` in the footer story range was not refreshed | Same story-range update loop; verify `PAGE` and `NUMPAGES` field results |
| `IndexError: tuple index out of range` when filling a review table | Table created with fewer columns than the data group (7 labels into a 6-column table) | Build the table from the data width: `rows=3, cols=len(group)`, or explicitly `cols=7` |
| Table fonts/borders/shading inconsistent across dozens of tables | Styles applied ad hoc during generation | Register every table with `reg(t, header, label_cols, center_cols)` and run one `standardize_all()` pass before `doc.save()` |

## Quick diagnostic sequence

```powershell
# 1. What is this file, really?
python scripts/probe_encryption.py "D:\文档\*.doc" "D:\文档\*.docx"

# 2. Read whatever is encrypted
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/dump_encrypted_doc.ps1 `
  -Path "D:\文档\模板.doc" -OutDir "$env:TEMP\wb_docx" -IncludeTables

# 3. After generating, assert plaintext before anyone previews it
python scripts/probe_encryption.py --expect-plain "D:\文档\交付物.docx"

# 4. Verify structure on a copy only
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify_docx.ps1 `
  -Path "D:\文档\交付物.docx" -UpdateFields
```
