# 维护与安全

## 重复安装与更新

Codex Skill 安装器遇到同名目标目录时会停止，不会自动覆盖。更新技能前，应先备份现有目录，再安装新版本：

```powershell
$skillPath = "$env:USERPROFILE\.codex\skills\frontend-skill"
$backupPath = "$skillPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

if (Test-Path $skillPath) {
  Move-Item -LiteralPath $skillPath -Destination $backupPath
}
```

插件由 Codex 插件市场管理。CodeGraph 的升级方式见 [CodeGraph 文档](codegraph.md#更新)。

## 安全建议

- 安装第三方 Skill 前，检查其 `SKILL.md`、脚本和引用文件。
- 不要安装来源不明或要求读取密钥、上传代码的技能。
- 通过网络下载并直接执行脚本前，先查看脚本内容。
- CodeGraph 的遥测可按项目文档关闭。

## 安装后检查

普通 Skill：

```powershell
Get-ChildItem "$env:USERPROFILE\.codex\skills" -Directory | ForEach-Object {
  [PSCustomObject]@{
    Skill = $_.Name
    HasSkillFile = Test-Path (Join-Path $_.FullName 'SKILL.md')
  }
}
```

插件：

```powershell
codex plugin list
```

安装或更新后重启 Codex，使技能、插件和 MCP 配置在新会话中生效。
