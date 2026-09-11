# Agent Skills for Context Engineering

来源：[muratcankoylan/Agent-Skills-for-Context-Engineering](https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering)

该技能包包含 17 个上下文工程技能。

## 安装

先完成 [README](../README.md) 中的 PowerShell 环境变量配置，然后运行：

```powershell
& $python $installer `
  --repo muratcankoylan/Agent-Skills-for-Context-Engineering `
  --path `
    skills/advanced-evaluation `
    skills/bdi-mental-states `
    skills/context-compression `
    skills/context-degradation `
    skills/context-fundamentals `
    skills/context-optimization `
    skills/evaluation `
    skills/filesystem-context `
    skills/harness-engineering `
    skills/hosted-agents `
    skills/latent-briefing `
    skills/long-horizon-prompting `
    skills/memory-systems `
    skills/multi-agent-patterns `
    skills/project-development `
    skills/self-improvement-loops `
    skills/tool-design
```

## 验证

```powershell
$contextSkills = @(
  'advanced-evaluation',
  'bdi-mental-states',
  'context-compression',
  'context-degradation',
  'context-fundamentals',
  'context-optimization',
  'evaluation',
  'filesystem-context',
  'harness-engineering',
  'hosted-agents',
  'latent-briefing',
  'long-horizon-prompting',
  'memory-systems',
  'multi-agent-patterns',
  'project-development',
  'self-improvement-loops',
  'tool-design'
)

$contextSkills | ForEach-Object {
  [PSCustomObject]@{
    Skill = $_
    Installed = Test-Path "$env:USERPROFILE\.codex\skills\$_\SKILL.md"
  }
}
```

所有 `Installed` 值均为 `True` 时，技能包安装完整。重启 Codex 后使用这些技能。
