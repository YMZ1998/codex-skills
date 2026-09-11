# frontend-skill

来源：[wzx2002/codex-frontend-skill](https://github.com/wzx2002/codex-frontend-skill)

该技能的内部名称是 `frontend-production-shadcn`，主要用于 React、TypeScript、Tailwind CSS 和 shadcn/ui 前端任务。

## 安装

先完成 [README](../README.md) 中的 PowerShell 环境变量配置，然后运行：

```powershell
& $python $installer `
  --repo wzx2002/codex-frontend-skill `
  --path . `
  --name frontend-skill
```

默认安装目录为 `~/.codex/skills/frontend-skill`。

## 验证

```powershell
Test-Path "$env:USERPROFILE\.codex\skills\frontend-skill\SKILL.md"
```

输出 `True` 表示安装文件存在。重启 Codex 后使用该技能。
