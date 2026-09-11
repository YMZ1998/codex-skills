# Codex Skills 安装指南

本仓库整理 Codex 技能、插件及配套工具在 Windows PowerShell 下的安装与使用方法。

## 前置条件

- 已安装 Codex，并且 `~/.codex/skills/.system/skill-installer` 存在。
- 可以访问 GitHub。
- 使用 Windows PowerShell 或 PowerShell 7。
- 安装完成后重启 Codex，使新技能、插件或 MCP 配置生效。

安装普通 Skill 时，以下文档默认使用 Codex Desktop 自带的 Python：

```powershell
$python = Get-ChildItem `
  -Path "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" `
  -ErrorAction Stop |
  Select-Object -ExpandProperty FullName

$installer = "$env:USERPROFILE\.codex\skills\.system\skill-installer\scripts\install-skill-from-github.py"
```

如果运行时目录不同，请先找到实际的 `python.exe` 并修改 `$python`。

## 文档目录

- [frontend-skill](docs/frontend-skill.md)：React、TypeScript、Tailwind CSS 和 shadcn/ui 前端实现技能。
- [Context Engineering](docs/context-engineering.md)：完整安装 17 个上下文工程技能。
- [Superpowers](docs/superpowers.md)：软件开发工作流插件。
- [Product Design](docs/product-design.md)：产品探索、设计审查与交互原型插件。
- [CodeGraph](docs/codegraph.md)：代码图谱 CLI、Codex MCP 集成与项目索引。
- [git-commit](docs/git-commit.md)：按暂存状态选择范围并生成中文本地提交。
- [维护与安全](docs/maintenance.md)：技能更新、重复安装处理和安全建议。
