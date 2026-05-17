---
title: "把 iTerm2 + Oh My Zsh 换成 Ghostty + 裸 zsh"
date: 2026-05-11
draft: false
tags: ["Ghostty", "zsh", "终端", "工具链"]
description: "从一个 Claude Code 渲染 bug 开始，顺手做了两次小迁移：终端换 Ghostty、shell 配置离开 Oh My Zsh 回到裸 zsh + 几个插件。"
ShowToc: true
TocOpen: false
---

## 起因：iTerm2 渲染 Claude Code 有问题

最近在 iTerm2 里跑 Claude Code 时遇到了渲染异常——CC 高频刷新输出时整个屏幕会一直不停地快速滚动，看一会儿眼都能闪瞎。之前在 [LINUX DO 社区](https://linux.do/t/topic/1294221) 也看到过类似的问题，基本可以确定是终端这边的问题。

再加上现在用的 omz 也有挺多用不上的插件，我决定这次干脆重新整理一遍终端和 shell 相关的工具链，换一个终端，也调整一下 zsh。

## 换 Ghostty

### 选它的理由

- **GPU 渲染**：滚动、刷新、`tail -f` 大日志这类场景肉眼可见地顺
- **速度本身就快**：冷启动、首次绘制、字体渲染都比 iTerm2 干脆
- **配置文件化**：一份纯文本，比 iTerm2 更方便修改

在 Ghostty 里按 `cmd+,` 就能用系统默认编辑器直接打开 config 文件，不用手抄它实际的路径（如果好奇的话，在 `~/Library/Application Support/com.mitchellh.ghostty/`）。改完保存，再用 `cmd+shift+,` reload 一下就生效，不需要重启 Ghostty。

### 用下来发现的小好处

Ghostty 的分屏体验和 iTerm2 差不多，但多了一个很好用的功能——**把当前分屏单独最大化**，比临时调整窗口比例要方便很多。

`toggle_split_zoom` 这个动作是 Ghostty 内置的，但默认没绑键，我手动绑了 `cmd+shift+f`。

```
cmd+shift+f    # toggle split zoom（当前分屏全屏 / 还原）
cmd+shift+e    # equalize splits（各分屏均分空间）
```

日常分屏在跑多个 Claude Code 的时候，临时想专心看其中一个时按一下放大、看完再按一下还原，十分方便。

我自己还顺手定制的几个键：

```
keybind = cmd+d=new_split:right         # 向右开分屏
keybind = cmd+shift+d=new_split:down    # 向下开分屏
# vim 风格分屏导航
keybind = cmd+shift+h=goto_split:left
keybind = cmd+shift+j=goto_split:bottom
keybind = cmd+shift+k=goto_split:top
keybind = cmd+shift+l=goto_split:right
keybind = cmd+shift+comma=reload_config  # 改完配置立刻生效
```

### Quake 风格的 Quick Terminal

之前在 Linux 上用过 guake，可以从屏幕顶部呼出一个下拉的常驻终端，临时跑个命令、查个东西特别顺手。用 iTerm2 的时候我也会单独配置一个类似的 Profile。Ghostty 内置了同样形态的 Quick Terminal，我把它绑在了 `ctrl+\``：

```
quick-terminal-position           = top      # 从顶部下拉
quick-terminal-screen             = mouse    # 出现在鼠标所在的显示器
quick-terminal-autohide           = true     # 失焦自动隐藏
quick-terminal-animation-duration = 0.15
keybind = global:ctrl+grave_accent=toggle_quick_terminal
```

`global:` 前缀让这个键在系统任何位置都生效，不需要 Ghostty 在前台。多显示器场景下 `quick-terminal-screen = mouse` 会跟着鼠标所在屏幕弹出。

**美中不足**：Quick Terminal 本质上是一个常驻的 shell 进程，快捷键只控制它显示/隐藏，并不是每次都启动新 shell。所以昨天在 `~/projects/foo` 里 cd 进去之后，今天再唤起还会停在那儿。不过也不是不能接受，如果真的需要一个全新的 shell，就运行 `exit` 退出重开一下就 OK 了。

### 其他几个值得提的配置

```
font-family = Maple Mono NF CN          # 中英文混排友好的等宽字体
theme = Catppuccin Mocha                # 现成的暗色主题
background-opacity = 0.98               # 轻微透明，不影响阅读
shell-integration = detect              # 自动检测 shell 集成
copy-on-select = true                   # 选中即复制（这个特别顺手）
```

## 顺手把 omz 也换了

### 为什么离开 Oh My Zsh

我用了 omz 好几年。它最初的吸引力是"开箱即用一堆主题和插件"，但实际上：

- 默认会加载一大堆我从来用不上的插件（git、laravel、osx……一大串）
- 启动慢，每次开 terminal 的时候都要等
- 真正在用的功能其实就那几个：补全、历史建议、目录跳转、prompt

也就是说我用 omz 这个**框架**只是为了它附带的几个**工具**。那就把工具直接装上就好，不需要框架本身。

### 留下的六个插件

去掉 omz 之后，`.zshrc` 里实际只挂了这几样：

| 工具 | 解决什么 |
|------|---------|
| **compinit** | zsh 自带的补全系统，命令、参数、文件路径都靠它 |
| **zsh-autosuggestions** | 根据历史命令给灰色提示，按一下右方向键就可以触发补全 |
| **zsh-syntax-highlighting** | 边敲边高亮命令是否存在、路径是否有效 |
| **Zoxide** | 智能 `cd`——`z proj` 直接跳到最近用过的 `~/projects/something` |
| **Starship** | 跨 shell 的 prompt，配置简单、显示 git/语言版本之类 |
| **fzf** | 模糊查找。`Ctrl+R` 搜历史、`Ctrl+T` 找文件 |

对应到 `.zshrc` 里：

```bash
# 补全系统
autoload -Uz compinit
compinit

# Homebrew 安装的两个 zsh 插件
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Zoxide / Starship / fzf
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
source <(fzf --zsh)
```

六个工具按 `brew install` 装就行：

```bash
brew install zsh-autosuggestions zsh-syntax-highlighting zoxide starship fzf
```

`compinit` 是 zsh 自带的，不用单独装。

### 启动时间

```
$ time zsh -i -c exit
zsh -i -c exit  0.12s user 0.11s system 83% cpu 0.274 total
```

0.27 秒，新窗口/分屏开起来基本无感。之前的 omz 配置已经被我清掉了，没留对比数字，但体感上明显快了不少。

## EOF

用了一段时间，我个人感觉跟之前 iTerm2 + omz 没什么明显区别，Claude Code 渲染的问题解决了，shell 启动也变快了。而且因为可以把当前分屏放大成全屏，多开 Claude Code 的时候反而更方便了。
