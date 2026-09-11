# Product Design

来源：[OpenAI Product Design plugin](https://github.com/openai/role-specific-plugins/tree/main/plugins/product-design)

Product Design 用于把产品想法、网页 URL、截图和现有设计转换成可评审、可迭代的交互原型。

## Codex App 安装

1. 打开 Codex App 左侧边栏的 **Plugins**。
2. 搜索 **Product Design**，或在 **Creativity** 分类中找到它。
3. 点击插件旁边的 `+`，按照界面提示完成安装。
4. 安装完成后启动新的 Codex 任务。

## Codex CLI 安装与验证

```powershell
codex plugin add product-design@openai-curated-remote
codex plugin list | Select-String -Pattern 'product-design'
```

## 初次设置

```text
@Product Design Help me get started
```

可保存的上下文包括产品 URL、Figma 文件、截图、参考图片、代码仓库路径、Storybook、设计令牌、设计系统和品牌素材。

## 常用工作流

```text
@Product Design Turn this product idea into three visual directions
@Product Design Build a clickable prototype for this product idea
@Product Design Clone this URL into an editable prototype: https://example.com
@Product Design Turn this selected mockup into a responsive prototype
@Product Design Audit this onboarding flow and identify the highest-impact UX and accessibility issues
@Product Design Research the biggest UX problems users are reporting for this product
```

## 可选集成

- Browser、Chrome 或 Playwright：捕获和检查网页，完成复刻、审查与原型 QA。
- Figma 或 Canva：引入已有设计上下文。
- Image generation：探索视觉方向并生成原型素材。
- Sites、Vercel 或其他托管工具：发布可运行的原型。

## 与 frontend-skill 的分工

- Product Design 负责产品探索、视觉方向、UX 审查和交互原型。
- `frontend-production-shadcn` 负责在 React、TypeScript、Tailwind CSS 和 shadcn/ui 项目中实现生产级界面。
- 推荐先用 Product Design 比较并确认方向，再用 frontend-skill 实现正式代码。
