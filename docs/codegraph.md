# CodeGraph

来源：[colbymchenry/codegraph](https://github.com/colbymchenry/codegraph)

CodeGraph 需要安装 CLI，并把 MCP 服务接入 Codex。

## 安装 CLI

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

## 接入 Codex

```powershell
codegraph install --target codex --location global --yes
```

完成后重启 Codex。

## 为项目建立索引

```powershell
Set-Location "C:\path\to\your-project"
codegraph init
codegraph status
```

索引保存在项目根目录的 `.codegraph` 中。打开本地可视化界面：

```powershell
codegraph ui
```

## 更新

```powershell
codegraph upgrade --check
codegraph upgrade
```
