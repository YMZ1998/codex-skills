# Superpowers

来源：[obra/superpowers](https://github.com/obra/superpowers)

Superpowers 是一套软件开发工作流插件，包含需求梳理、实现计划、测试驱动开发、系统化调试、代码审查、Git worktree 和任务收尾等技能。推荐通过 Codex 插件市场安装。

## Codex App 安装

1. 打开 Codex App 左侧边栏的 **Plugins**。
2. 在 **Coding** 分类中找到 **Superpowers**。
3. 点击插件旁边的 `+`，按照界面提示完成安装。
4. 安装完成后重新启动当前 Codex 会话。

## Codex CLI 安装

```powershell
codex plugin add superpowers@openai-curated-remote
```

也可以在 Codex CLI 中输入 `/plugins`，搜索 `superpowers`，选择 **Install Plugin**。

## 验证

```powershell
codex plugin list | Select-String -Pattern 'superpowers'
```

状态显示 `installed, enabled` 表示插件已启用。新建 Codex 任务并提出开发请求时，插件会自动选择相关工作流，例如：

- `brainstorming`
- `writing-plans`
- `test-driven-development`
- `systematic-debugging`
- `verification-before-completion`

## 更新

通过 Codex App 的 **Plugins** 页面管理更新。更新后如当前会话仍使用旧版本，请重启 Codex。
