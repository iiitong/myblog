---
title: "Hugo + PaperMod 博客的日常写作流程"
date: 2026-05-07
draft: true
tags: ["Hugo", "PaperMod", "博客", "工作流"]
description: "环境搭好之后博客真正的日常：怎么新建、怎么写、怎么处理草稿和图片、怎么部署，以及一路上踩过的几个坑。"
ShowToc: true
TocOpen: false
---

[Hugo + PaperMod 博客搭建完整指南]({{< ref "hugo-papermod-setup" >}}) 之后，博客本身已经能跑了，但真正的日常是写作流程本身——怎么新建、怎么处理图片和草稿、怎么部署。这篇记下我自己跑顺了的一套节奏，以及一路上踩过的几个小坑和形成的几个习惯。

## 三步走的节奏

```bash
make new slug=my-post     # 1. 新建并自动打开编辑器
# ... 写 ...
make deploy               # 2. 走全套检查发布
                          # 3. 等 GitHub Actions 部署完
```

90% 的写作就这样。下面把每一步展开。

## 新建文章：用 Page Bundle，别用单文件

`make new slug=xxx` 创建：

```
content/posts/xxx/
└── index.md
```

也就是 Hugo 所谓的 **Page Bundle**——文章和它的图片放在同一个文件夹，截图直接落在 `index.md` 边上，引用时只写文件名。

PaperMod 也支持单文件形式（`content/posts/xxx.md`），但混用是个糟糕的主意：

- 截图放哪儿？图床？还是 `static/images/`？
- 删文章时图片要单独清理
- 文章一旦想加图，又要重构成 Page Bundle

立一条"全部用 Page Bundle"的规则，省掉所有未来纠结。

**slug 命名 convention**：英文小写 + 连字符。`nginx-reverse-proxy` ✅，`Nginx_反代` ❌。这个会出现在 URL 里，要长期可读。

## Frontmatter

`archetypes/default.md` 里我用的模板：

```yaml
---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
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

写作时按需调整：

- **`draft: true`**：写作期间保持 true，避免半成品被 push 上线
- **`tags`**：用列表语法 `["nginx", "性能"]`，PaperMod 会自动汇总到 `/tags/`
- **`description`**：可选，作 SEO meta 用。空着 PaperMod 会用文章前几行
- **`ShowToc`**：短文（< 300 字）可关，长文留 true 看着舒服

## 写正文：Typora + 截图工作流

我用 Typora 写。截图工作流：

```
Cmd + Ctrl + Shift + 4    # 截屏到剪贴板（macOS）
Cmd + V                   # Typora 里粘贴
```

Typora 自动把图片保存到 `index.md` 同目录，并在文档里插入相对路径。**前提**是在 Typora Preferences → Image 把 Custom Folder 设成 `.`（一个点），不然图片会落到默认目录。

引用图片时只写文件名：

```markdown
✅ ![](nginx-502.png)
❌ ![](./nginx-502.png)            # macOS 能跑，Linux 部署 404
❌ ![](/posts/xxx/nginx-502.png)   # 绝对路径，搬家就死
```

文件名大小写也要小心——`Screenshot.png` 引用成 `screenshot.png`，在 macOS 默认文件系统能跑（大小写不敏感），到 GitHub Actions 的 Linux 环境就 404。

控制图片大小用 HTML：

```markdown
<img src="nginx-502.png" alt="错误截图" width="600">
```

或 PaperMod 自带的 figure shortcode（带 caption）：

```markdown
{{< figure src="nginx-502.png" alt="Nginx 502" caption="图 1：报错截图" >}}
```

## 草稿管理：让"写一半"成为常态

文章写到一半很正常。两条暂存路径：

### 路径 A：commit 草稿（保持 `draft: true`）

```bash
git add .
git commit -m "wip: 续写中"
git push
```

云端有备份，换设备能继续。代价是 pre-commit 全套检查会跑——半成品如果 Hugo 构建过不了，得 `git commit --no-verify` 跳过。

### 路径 B：git stash

```bash
git stash push -m "wip: 半截内容"
# 之后恢复
git stash pop
```

短期暂存（几小时到一两天）用这个最干净，不污染 git 历史。

### 防遗忘

```bash
make drafts
```

列出所有 `draft: true` 的文章。隔几天跑一下，避免"写完了忘发"。

## 发布前：两个动作

### 1. 压图

```bash
make optimize
```

把 `content/posts/` 下所有 PNG 走 pngquant，质量 65-80（视觉无损），体积砍掉 50-70%。我习惯发布前固定跑一遍，零成本。单张截图建议 < 500KB，超过 2MB 会被 pre-commit 直接拦下来。

### 2. 转正

```bash
make publish slug=my-post
```

把指定文章的 `draft: true` 改成 `false`。在编辑器里手动改也一样。

## 部署：`make deploy` 的四道闸门

```bash
make deploy
```

依次跑：

1. **Hugo 构建** — 构建不过直接拒绝
2. **是否有改动** — 没改动直接退出，不创建空 commit
3. **改过的草稿** — 列出修改过但仍是 `draft: true` 的文章，问"确定发吗？"防误推
4. **commit + push** — message 自动按 git diff 类型生成（`post:` / `update:` / `chore:`）

要自定义 message：

```bash
make deploy m="post: 详细记录 nginx 反代配置陷阱"
```

应急绕过所有检查：

```bash
make deploy-fast m="紧急修复"
```

push 完 1-2 分钟，GitHub Actions 跑完，博客就更新了。

## 几条形成习惯的 convention

**用 tag 分类，不要用文件夹**。一篇文章挂多个标签，PaperMod 自动生成 `/tags/<tag>/` 页面，远比强行塞进单一目录灵活。

**提交频率：一篇 1-2 次 commit 足够**。不要为了"history 干净"频繁 amend——这是博客不是 PR review，没人看 commit log。

**修改已发布文章直接改、直接 push**，不需要标注"v2"什么的。博客是活的文档，git 历史里都有版本。

**删文章用 `make rm slug=xxx`**，二次确认后整个 Page Bundle（含图片）一起删干净，再 `make deploy`。

**pre-commit 第一次 commit 失败是正常的**：它会自动修一些格式问题（行尾空格、文末换行）然后阻止 commit。看到提示后 `git add` 重新 commit 即可。

## 收尾

跑通这套之后，日常写作的真实摩擦就剩"想不出来写什么"和"写不出来"了——这才是博客该有的难题。
