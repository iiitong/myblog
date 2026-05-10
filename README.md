# 我的博客

基于 **Hugo + PaperMod** 的个人博客

## 技术栈

- **静态站点生成器**：Hugo (extended)
- **主题**：[PaperMod](https://github.com/adityatelange/hugo-PaperMod)
- **托管**：GitHub Pages
- **CI/CD**：GitHub Actions
- **写作**：Typora + Markdown
- **任务管理**：Makefile
- **代码检查**：pre-commit 框架

## 写作 SOP

```bash
make new slug=my-post     # 新建并打开编辑器
# ... 写 ...
make deploy               # 走全套检查并发布
```

完整命令清单 `make help`。流程详解、踩坑和 convention 整理在博客文章 [Hugo + PaperMod 博客的日常写作流程](https://blog.itong.me/posts/hugo-papermod-writing-flow/) 里。


### 草稿管理

```bash
make drafts                # 列出所有未发布草稿
make publish slug=xxx      # 转正式发布（draft: true → false）
```

### 删除文章

```bash
make rm slug=xxx           # 二次确认后删整个 Page Bundle（含图片）
make deploy m="chore: 删除 xxx"
```

## 项目结构

```
myblog/
├── archetypes/             # 文章模板
│   └── default.md
├── content/
│   ├── about.md            # 关于页
│   └── posts/              # 文章（每篇一个 Page Bundle）
│       └── my-post/
│           ├── index.md
│           └── screenshot.png
├── static/                 # 全局静态资源
│   └── CNAME               # 自定义域名
├── themes/
│   └── PaperMod/           # 主题（git submodule）
├── .github/
│   └── workflows/
│       └── hugo.yml        # 自动部署 workflow
├── .pre-commit-config.yaml # pre-commit 配置
├── .secrets.baseline       # 密钥检测基线
├── hugo.toml               # Hugo 主配置
├── Makefile                # 任务命令
└── README.md
```

## 维护

```bash
make help              # 列出所有命令
make stats             # 博客统计
make update-theme      # 更新主题
make update-hooks      # 更新 pre-commit 插件
```
