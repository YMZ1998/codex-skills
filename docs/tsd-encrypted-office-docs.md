# tsd-encrypted-office-docs

来源：2026-11-11 由 WorkBuddy 会话整理，用于读取企业透明加密（DLP）Office 文档。完整技能文件备份在同目录的 [`tsd-encrypted-office-docs/`](tsd-encrypted-office-docs/)。

该技能处理文件头为 `%TSD-Header-###%` 的加密容器。这类 `.doc/.docx` 既不是 OLE 也不是 ZIP，`python-docx`、编辑器 SDK 和转换工具都无法直接打开；只有本机已授权的 Word 进程能透明读到明文。技能的做法是：Word 只作只读解密器 → 导出 UTF-8 明文文本 → 用 `python-docx` 写出明文 `.docx` → 只在临时副本上验证。

## 适用环境（重要）

- 仅限**原生 Windows**，且已登录企业 DLP 客户端、Microsoft Word 已安装并正在运行。
- 需要 Windows PowerShell 5.1 与 `python-docx`（`python -m pip install python-docx`）。
- **不适用于** Codex 云端、macOS、Linux、WSL2、容器或 CI。
- Windows 原生 Codex 的沙箱可能拦截跨进程 COM 自动化。若 Word COM 失败，在已授权的交互会话中人工执行导出脚本，再从明文文本继续。不要尝试绕过公司 DLP 或沙箱策略。

## 安装

本仓库其他文档使用 `~/.codex/skills/`；当前 Codex 官方规范的用户级目录是 `~/.agents/skills/`。按本机实际版本选择 `$dst`：

```powershell
$src = Join-Path (Get-Location) "docs\tsd-encrypted-office-docs"
# 新版 Codex（Agent Skills 标准）
$dst = Join-Path $env:USERPROFILE ".agents\skills\tsd-encrypted-office-docs"
# 旧版 Codex 请改用：
# $dst = Join-Path $env:USERPROFILE ".codex\skills\tsd-encrypted-office-docs"

if (Test-Path $dst) {
  Write-Warning "目标已存在，请先备份或改名：$dst"
} else {
  New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
  Copy-Item -Path $src -Destination $dst -Recurse
  Write-Host "已安装到 $dst"
}
```

安装后重启 Codex，用 `$tsd-encrypted-office-docs` 显式调用，或由 description 隐式匹配。

## 验证

```powershell
Test-Path (Join-Path $dst "SKILL.md")
python .\docs\tsd-encrypted-office-docs\scripts\probe_encryption.py "D:\文档\*.doc"
```

探测脚本输出 `tsd-encrypted` 表示识别到加密容器；对生成的交付物用 `--expect-plain` 断言其为标准 `PK` OOXML。

三个 `.ps1` 脚本必须用 `-ExecutionPolicy Bypass` 启动子进程，直接 `& script.ps1` 会被系统执行策略拒绝：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File `
  .\docs\tsd-encrypted-office-docs\scripts\dump_encrypted_doc.ps1 `
  -Path "D:\文档\模板.doc" -OutDir "$env:TEMP\wb_docx" -IncludeTables
```

## 文件清单

| 文件 | 作用 |
|---|---|
| `SKILL.md` | 触发条件、工作流、硬规则、Codex 安装说明 |
| `scripts/probe_encryption.py` | 魔数分类与明文 OOXML 断言 |
| `scripts/dump_encrypted_doc.ps1` | Word COM 只读解密 → UTF-8 文本（可选表格导出） |
| `scripts/verify_docx.ps1` | 复制到 `%TEMP%` 后在副本上验证页数/表数/目录/页脚 |
| `references/environment.md` | 原理、完整 COM 与 python-docx 片段 |
| `references/troubleshooting.md` | 错误 → 原因 → 修复对照表 |
| `agents/openai.yaml` | Codex 显示名与调用策略 |

## 实测结果（2026-11-11）

解密规格书得到 8,684 字符 / 10 张表；交付文档验证为 61 页 / 95 张表 / TOC=1 / 页脚「第 1 页，共 61 页」，且验证后原件仍为明文。规范校验通过：无未知 frontmatter 字段，description 524 字符、compatibility 284 字符。

## 其他副本

- WorkBuddy 原版：`C:\Users\LiJin\.workbuddy-ai\skills\tsd-encrypted-office-docs\`
- Codex 适配版原件：`D:\文档\codex-compatible\tsd-encrypted-office-docs\`
- 分发包：`D:\文档\tsd-encrypted-office-docs-codex.zip`、`D:\文档\tsd-encrypted-office-docs.zip`
