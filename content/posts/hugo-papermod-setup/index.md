---
title: "Hugo + PaperMod 博客搭建完整指南：从零到上线"
date: 2026-05-03
draft: false
tags: ["Hugo", "PaperMod", "博客搭建", "教程"]
description: "从零开始搭建 Hugo + PaperMod 博客，部署到 GitHub Pages 并绑定自定义域名的完整流程。"
ShowToc: true
TocOpen: false
---

我用 Hugo + PaperMod 主题搭了这个博客，部署到 GitHub Pages 并绑定了自己的域名，评论接的是 Giscus。下面是从环境搭建到部署上线的完整步骤。

## 选型理由

**Hugo**：下载即用，不用先装 Node、Ruby 这些环境；构建速度极快（几百篇文章秒级出结果）；配置简单，不懂前端也没问题。对比 Hexo / Jekyll 等其他流行框架，是最省心最少折腾的静态站方案。

**PaperMod**：选这个主题没什么特别理由，简洁，目录 / 搜索 / 归档 / tags / 阅读时间这些都开箱即用，对我够用。想要更视觉化或双栏布局的时候可以看看 NexT、Stack、NexT.Gemini 这些主题。

**Giscus（评论）**：PaperMod 本身不带评论，得自己接一套。Giscus 把评论存进 GitHub Discussions——**零后端、零数据库、零维护**，数据全在自己仓库下，比 Waline / Disqus 这类要单独跑服务的方案省心。代价是读者得登 GitHub 才能留言；以后真要匿名评论或更精细的控制，再迁去自建的 Waline / Twikoo 也不迟。

## 0. 环境准备

### 必装

```bash
# Hugo（必须 extended 版本，PaperMod 需要）
brew install hugo
```

### 可选

```bash
# Typora（写作编辑器，付费 ~$15）
brew install --cask typora
```

### 验证

```bash
hugo version          # 应显示 extended 字样
```

## 1. 创建 Hugo 站点

```bash
# 进入你打算存放博客的目录，下文以 ~/myblog 为例
cd ~
hugo new site myblog
cd myblog
git init
```

## 2. 安装 PaperMod 主题

⚠️ **必须用 git submodule，不要直接 clone 后删 .git**，否则 GitHub Actions 拉不到主题。

```bash
git submodule add --depth=1 https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
```

## 3. 配置 hugo.toml

把默认生成的 `hugo.toml` 替换成下面这份，按需改成你自己的信息：

```toml
baseURL = 'https://blog.example.com/'   # 最终域名，末尾必须带斜杠
languageCode = "zh-cn"                  # 语言代码
defaultContentLanguage = "zh"           # 默认内容语言
title = '你的博客名'                     # 站点标题（浏览器标签 / 首页大标题）
theme = 'PaperMod'                      # 主题名，对应 themes/<name>/

enableRobotsTXT = true                  # 自动生成 /robots.txt（SEO）
buildDrafts = false                     # 不构建 draft: true 的文章
buildFuture = false                     # 不构建未来日期的文章

# URL 结构：渲染成 /2026/05/my-post/
[permalinks]
posts = "/:year/:month/:slug/"

# 搜索功能需要 JSON 输出（PaperMod 的 /search/ 页面用）
[outputs]
home = ["HTML", "RSS", "JSON"]

[params]
env = "production"                      # 生产环境（启用一些性能优化）
title = "你的博客名"                     # 用于 SEO 的 title
description = "博客描述"                 # meta description（搜索结果摘要）
author = "你的名字"                      # 作者名，出现在文章 meta 行
defaultTheme = "auto"                   # 主题模式：auto / dark / light
ShowReadingTime = true                  # 显示阅读时间
ShowShareButtons = false                # 分享按钮（不需要可关）
ShowCodeCopyButtons = true              # 代码块"复制"按钮
ShowToc = true                          # 文章目录
TocOpen = false                         # 目录默认折叠
ShowBreadCrumbs = true                  # 面包屑（首页 > Posts > 文章名）
ShowPostNavLinks = true                 # 文章底部上下篇导航
ShowWordCount = true                    # 字数统计
disableScrollToTop = false              # 显示"回到顶部"按钮
disableSpecial1stPost = true            # 列表第一篇不放大，统一卡片样式
comments = true                         # 启用评论（需配 layouts/partials/comments.html，见第 14 节）

# 搜索引擎参数（fuse.js）
[params.fuseOpts]
isCaseSensitive = false
shouldSort = true
location = 0
distance = 1000
threshold = 0.3
minMatchCharLength = 1
keys = ["title", "permalink", "summary", "content"]

[params.profileMode]
enabled = false                         # 不启用首页 profile 卡片模式

# 顶部菜单（按 weight 升序排列）
[[menu.main]]
identifier = "posts"
name = "文章"
url = "/posts/"
weight = 10

[[menu.main]]
identifier = "tags"
name = "标签"
url = "/tags/"
weight = 20

[[menu.main]]
identifier = "archives"
name = "归档"
url = "/archives/"
weight = 30

[[menu.main]]
identifier = "search"
name = "搜索"
url = "/search/"
weight = 40

[[menu.main]]
identifier = "about"                    # 可选：建了 content/about.md 再启用这一项
name = "关于"
url = "/about/"
weight = 50

# 代码高亮
[markup]
[markup.highlight]
noClasses = false                       # 用 CSS 类（配合 PaperMod 高亮 CSS）
codeFences = true                       # 启用 ``` 围栏代码块
guessSyntax = true                      # 不带语言标记时自动猜
lineNos = false                         # 不显示行号
style = "monokai"                       # 高亮配色（其它见 https://xyproto.github.io/splash/docs/）
[markup.goldmark.renderer]
unsafe = true                           # 允许 Markdown 里写 HTML（图片 width / shortcode 都需要）
```

需要按需修改的字段：

- `baseURL`：你的最终域名（带末尾斜杠）
- `title`：博客名
- `params.author`：作者名
- `params.description`：博客描述

## 4. 安装文章模板

`archetypes/default.md` 是 `hugo new content posts/xxx/index.md` 生成新文章时的 frontmatter 模板——每次新建都会把这段自动塞到文件顶部。

替换默认的 `archetypes/default.md` 为：

```markdown
---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: false
tags: []
description: ""
ShowToc: true
TocOpen: false
cover:
  image: ""
  alt: ""
  caption: ""
---
```

各字段含义：

- **`title`**：文章标题。`{{ replace .Name "-" " " | title }}` 是 Hugo 模板语法——把 slug 的连字符替换成空格、首字母大写。例：新建 `nginx-tips/index.md` → 标题自动填成 `Nginx Tips`，写作时再改成想要的中文标题即可
- **`date`**：发布日期。`{{ .Date }}` 自动取当前时刻
- **`draft: true`**：草稿状态。默认 true 防止误推，写完手动改成 `false` 才会被构建到站点
- **`tags: []`**：标签数组，写法 `["nginx", "网络"]`。PaperMod 会自动汇总到 `/tags/<标签>/` 页面
- **`description: ""`**：SEO meta description，搜索结果摘要用。空着 PaperMod 会自动取文章前几行
- **`ShowToc: true` / `TocOpen: false`**：是否显示目录、目录默认是否展开。短文（<300 字）可以把 ShowToc 关掉
- **`cover`**：封面图（可选）。`image` 填 Page Bundle 里的图片名（如 `cover.png`），列表页和文章顶部会展示

`{{ ... }}` 是 Hugo 模板语法，**只在 `hugo new` 那一刻被求值**——生成出的新文章里它们已经是具体值，不会保留 `{{ }}`。

## 5. 创建必要页面

PaperMod 的归档和搜索需要手动建页面。

`content/archives.md`：

```markdown
---
title: "归档"
layout: "archives"
url: "/archives/"
summary: archives
---
```

`content/search.md`：

```markdown
---
title: "搜索"
layout: "search"
url: "/search/"
summary: search
placeholder: "输入关键词..."
---
```

## 6. 写第一篇测试文章

```bash
hugo new content posts/hello-world/index.md
```

编辑生成的 `content/posts/hello-world/index.md`，把 `draft` 改成 `false` 并写点内容即可。

## 7. 本地预览

```bash
hugo server -D
```

打开 http://localhost:1313 看效果，`Ctrl+C` 停止。

## 8. 配置 GitHub Actions

在项目根目录创建 `.github/workflows/hugo.yml`：

```yaml
name: Deploy Hugo site to Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

defaults:
  run:
    shell: bash

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      HUGO_VERSION: 0.160.1
    steps:
      - name: Install Hugo CLI
        run: |
          wget -O ${{ runner.temp }}/hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb \
          && sudo dpkg -i ${{ runner.temp }}/hugo.deb
      - name: Install Dart Sass
        run: sudo snap install dart-sass
      - name: Checkout
        uses: actions/checkout@v5
        with:
          submodules: recursive
          fetch-depth: 0
      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v5
      - name: Install Node.js dependencies
        run: "[[ -f package-lock.json || -f npm-shrinkwrap.json ]] && npm ci || true"
      - name: Build with Hugo
        env:
          HUGO_CACHEDIR: ${{ runner.temp }}/hugo_cache
          HUGO_ENVIRONMENT: production
          TZ: Asia/Shanghai
        run: |
          hugo \
            --gc \
            --minify \
            --baseURL "${{ steps.pages.outputs.base_url }}/"
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v4
        with:
          path: ./public

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

`HUGO_VERSION` 改成和你本地 `hugo version` 一致的版本号。

## 9. 配置 .gitignore

```
public/
resources/
.hugo_build.lock
.DS_Store
```

## 10. 推送到 GitHub

### 在 GitHub 上新建仓库

- 仓库名随意（比如 `myblog`）
- **必须 public**（免费 Pages 限制）
- 不要勾选 "Initialize this repository"

### 本地推送

```bash
git add .
git commit -m "init: hugo + papermod"
git remote add origin https://github.com/<your-username>/myblog.git
git push -u origin main
```

## 11. 启用 GitHub Pages

1. 仓库 → **Settings → Pages**
2. **Source** 选 `GitHub Actions`（不是 Deploy from a branch）
3. 保存

回到 **Actions** 标签页，等 workflow 跑完，绿勾出现就部署完了。

此时可访问 `https://<your-username>.github.io/myblog/` 验证。

## 12. 绑定自定义域名

### 12.1 DNS 解析

到你的 DNS 服务商（域名注册商或 Cloudflare、阿里云等）添加一条 CNAME 记录：

| 字段 | 填什么 |
|------|--------|
| Record type | `CNAME` |
| Subdomain（主机记录） | `blog` |
| Maps to（值） | `<your-username>.github.io` |

> Cloudflare 用户特别注意：**代理状态先关掉（灰云朵）**，等 HTTPS 完全生效后再考虑开。

### 12.2 项目里加 CNAME 文件

创建 `static/CNAME`，内容只有一行：

```
blog.example.com
```

⚠️ **必须是 `static/CNAME`，不是项目根目录的 CNAME**。Hugo 会把 `static/` 里的内容原样复制到输出。

### 12.3 Hugo 配置更新

修改 `hugo.toml` 的 `baseURL`：

```toml
baseURL = "https://blog.example.com/"
```

### 12.4 GitHub Pages 设置

仓库 → **Settings → Pages**：

- **Custom domain** 填 `blog.example.com` → Save
- 等 DNS check 通过（绿色对勾，几分钟到几小时）
- 勾选 **Enforce HTTPS**（GitHub 用 Let's Encrypt 自动签证书）

### 12.5 推送生效

```bash
git add .
git commit -m "feat: bind custom domain"
git push
```

等 Actions 跑完，访问 `https://blog.example.com` 就能看到博客。

## 13. 配置 Typora（可选）

如果用 Typora 写作 + 截图粘贴，需要做一步配置才能让图片自动落到对应文章目录里。

打开 Typora → **Preferences → Image**：

| 选项 | 设置值 |
|------|--------|
| When Insert | **Copy image to custom folder** |
| Custom Folder | `.`（一个点） |
| ☑ Apply above rules to local images | 勾选 |
| ☑ Apply above rules to online images | 勾选 |
| Image Path | **Use relative path if possible** |

之后在 Typora 里粘贴截图会自动保存到 `index.md` 同级目录，符合 Page Bundle 结构。

## 14. 集成评论系统：Giscus（可选）

PaperMod 不带评论功能，需要单独集成。下面是 Giscus 的集成步骤。

### 步骤

**1. 仓库启用 Discussions**

GitHub 仓库 → **Settings → General → Features**，勾选 `Discussions`。

**2. 新建评论分类**

Discussions 页 → 左侧 Categories 旁边的铅笔图标 → New category：

- 名字：`Comments`
- **Discussion format 必须选 `Announcement`**——只允许仓库 owner 创建 thread（Giscus 会自动创建），普通用户只能在已有 thread 里评论，避免垃圾贴

**3. 用 giscus.app 生成配置**

去 https://giscus.app 填表，关键选项：

| 项 | 选 |
|---|---|
| Page ↔ Discussion Mapping | `pathname`（按 URL 路径映射，最稳定） |
| Discussion Category | `Comments` |
| Enable Reactions for the main post | ✅ |
| Emit discussion metadata | ❌ |
| Place the comment box above the comments | ❌ |
| Lazy loading | ✅ |
| Theme | `preferred_color_scheme`（跟随浅 / 深色模式） |

页面下方生成一段 `<script>` 标签。

**4. 创建 partial 文件**

把那段 script 整段贴到 `layouts/partials/comments.html`：

```html
<script src="https://giscus.app/client.js"
        data-repo="<owner>/<repo>"
        data-repo-id="..."
        data-category="Comments"
        data-category-id="..."
        data-mapping="pathname"
        data-strict="0"
        data-reactions-enabled="1"
        data-emit-metadata="0"
        data-input-position="bottom"
        data-theme="preferred_color_scheme"
        data-lang="zh-CN"
        data-loading="lazy"
        crossorigin="anonymous"
        async>
</script>
```

**5. `hugo.toml` 启用**

`[params]` 里加：

```toml
comments = true
```

PaperMod 的 `single.html` 里有 v }}{{- partial "comments.html" . }}` 这段逻辑，开关靠这个 flag。想关掉某篇文章评论，在该文章 frontmatter 加 `comments: false` 即可（frontmatter 优先级高于 site params）。

**6. 验证**

`hugo server -D`，打开任意一篇文章滚到底，应该看到 Giscus 评论区。**Giscus 会在第一次访问每篇文章时自动在 Discussions 里创建对应 thread**——不需要预先批量创建。

## 总结

最小可用形态需要：

- Hugo extended + PaperMod submodule
- 配好 `hugo.toml` 和 archetype 模板
- GitHub Actions workflow + GitHub Pages 启用
- 自定义域名：DNS 服务商加 CNAME + 项目里 `static/CNAME` + Settings 里填域名

加分项：

- Typora 配好图片自动落盘
- Giscus 评论（基于 GitHub Discussions，零后端）

<!--
装完这一套，写博客就回到它本来该有的样子----想写就写、写完推一下、其他都不用管。日常用起来形成的几个习惯、踩过的坑，我整理在另一篇 [Hugo + PaperMod 博客的日常写作流程](/posts/hugo-papermod-writing-flow/)。
-->
