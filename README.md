# Codex Skills 安装指南

本文档整理了以下 Codex 技能与工具在 Windows PowerShell 下的安装方法：

- `frontend-skill`
- Agent Skills for Context Engineering（17 个技能）
- Superpowers
- CodeGraph CLI 与 Codex MCP 集成

## 前置条件

- 已安装 Codex，并且 `~/.codex/skills/.system/skill-installer` 存在。
- 可以访问 GitHub。
- 使用 Windows PowerShell 或 PowerShell 7。
- 安装完成后，重新启动 Codex，使新技能或 MCP 配置生效。

以下命令优先使用 Codex Desktop 自带的 Python。如果你的运行时版本或目录不同，请先找到实际的 `python.exe` 并修改 `$python`。

```powershell
$python = Get-ChildItem `
  -Path "$env:USERPROFILE\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" `
  -ErrorAction Stop |
  Select-Object -ExpandProperty FullName

$installer = "$env:USERPROFILE\.codex\skills\.system\skill-installer\scripts\install-skill-from-github.py"
```

## 安装 frontend-skill

来源：[wzx2002/codex-frontend-skill](https://github.com/wzx2002/codex-frontend-skill)

```powershell
& $python $installer `
  --repo wzx2002/codex-frontend-skill `
  --path . `
  --name frontend-skill
```

默认安装目录：

```text
~/.codex/skills/frontend-skill
```

验证：

```powershell
Test-Path "$env:USERPROFILE\.codex\skills\frontend-skill\SKILL.md"
```

该技能的内部名称是 `frontend-production-shadcn`，主要用于 React、TypeScript、Tailwind CSS 和 shadcn/ui 前端任务。

## 安装 Context Engineering 技能包

来源：[muratcankoylan/Agent-Skills-for-Context-Engineering](https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering)

下面的命令一次安装完整的 17 个技能：

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

验证所有技能的 `SKILL.md`：

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

## 安装 Superpowers

来源：[obra/superpowers](https://github.com/obra/superpowers)

Superpowers 是一套完整的软件开发工作流插件，包含需求梳理、实现计划、测试驱动开发、系统化调试、代码审查、Git worktree 和任务收尾等技能。Codex 官方插件市场已经提供该插件，因此推荐通过市场安装，不需要手动克隆仓库或复制其中的技能目录。

### Codex App

1. 打开 Codex App 左侧边栏的 **Plugins**。
2. 在 **Coding** 分类中找到 **Superpowers**。
3. 点击 Superpowers 旁边的 `+`，按照界面提示完成安装。
4. 安装完成后，重新启动当前 Codex 会话。

### Codex CLI

在 Codex CLI 中打开插件搜索界面：

```text
/plugins
```

搜索：

```text
superpowers
```

选择 **Install Plugin** 完成安装，然后启动一个新的 Codex 会话。

### 验证

新建一个 Codex 任务并提出需要开发功能的请求。安装正常时，Superpowers 会自动选择相关工作流技能，例如：

- `brainstorming`
- `writing-plans`
- `test-driven-development`
- `systematic-debugging`
- `verification-before-completion`

通常不需要手动指定技能名称；插件会根据任务自动触发相应流程。

### 更新

Superpowers 的更新方式由 Codex 插件市场管理。出现新版本时，在 **Plugins** 页面中执行更新；如果当前会话仍使用旧版本，请重启 Codex。

> 官方仓库可能还包含其他编码工具的安装方法。本文仅记录 Codex App 和 Codex CLI 的推荐安装流程。

## 安装 CodeGraph

来源：[colbymchenry/codegraph](https://github.com/colbymchenry/codegraph)

CodeGraph 不是只复制一个 `SKILL.md` 就能工作的普通技能。它需要安装 CLI，并把 MCP 服务接入 Codex。

### 1. 安装 CLI

建议先查看[官方安装脚本](https://github.com/colbymchenry/codegraph/blob/main/install.ps1)，确认内容后执行：

```powershell
Invoke-RestMethod `
  -Uri "https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1" |
  Invoke-Expression
```

安装程序会修改用户级 `PATH`。关闭并重新打开终端，然后验证：

```powershell
codegraph --version
```

### 2. 接入 Codex

```powershell
codegraph install --target codex --location global --yes
```

该命令会更新 Codex 的全局 MCP 配置和 CodeGraph 使用指令。完成后重新启动 Codex。

### 3. 为项目建立索引

进入需要分析的代码仓库：

```powershell
Set-Location "C:\path\to\your-project"
codegraph init
```

索引保存在项目根目录的 `.codegraph` 中。检查状态：

```powershell
codegraph status
```

打开本地可视化界面：

```powershell
codegraph ui
```

## 重复安装与更新

Codex Skill 安装器遇到同名目标目录时会停止，不会自动覆盖。更新技能前，应先备份现有目录，再安装新版本。例如：

```powershell
$skillPath = "$env:USERPROFILE\.codex\skills\frontend-skill"
$backupPath = "$skillPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

if (Test-Path $skillPath) {
  Move-Item -LiteralPath $skillPath -Destination $backupPath
}
```

CodeGraph 使用自己的升级命令：

```powershell
codegraph upgrade --check
codegraph upgrade
```

## 安全提示

- 安装第三方 Skill 前，应检查其 `SKILL.md`、脚本和引用文件。
- 不要安装来源不明或要求读取密钥、上传代码的技能。
- 通过网络下载并直接执行脚本前，应先查看脚本内容。
- CodeGraph 官方说明其索引和分析在本地完成；遥测可按项目文档关闭。
