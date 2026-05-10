# ============================================
# Hugo 博客管理 Makefile
# 使用 make help 查看所有命令
# ============================================

.PHONY: help new edit rm preview preview-prod publish deploy deploy-fast \
        list drafts stats optimize build clean update-theme \
        install-hooks check update-hooks scan-secrets

# 默认显示帮助
.DEFAULT_GOAL := help

# 颜色
YELLOW := \033[1;33m
GREEN  := \033[1;32m
CYAN   := \033[1;36m
RED    := \033[1;31m
RESET  := \033[0m

# 路径和工具
POSTS_DIR := content/posts
# 打开文章用的命令；默认调系统默认应用，
# 想换可以在调用时覆盖：OPEN="code" make edit slug=xxx
OPEN      ?= open

# ============================================
# 帮助
# ============================================
help: ## 显示所有命令
	@echo "$(CYAN)Hugo 博客管理命令$(RESET)"
	@echo ""
	@echo "$(YELLOW)写作$(RESET)"
	@echo "  make new slug=xxx       新建文章并打开编辑器"
	@echo "  make edit slug=xxx      打开已有文章编辑"
	@echo "  make rm slug=xxx        删除文章（含图片，二次确认）"
	@echo "  make preview            本地预览（含草稿）"
	@echo "  make preview-prod       本地预览（不含草稿）"
	@echo ""
	@echo "$(YELLOW)发布$(RESET)"
	@echo "  make publish slug=xxx   把指定文章转为正式发布"
	@echo "  make deploy             严谨发布（带检查）"
	@echo "  make deploy m=\"说明\"    自定义 commit message"
	@echo "  make deploy-fast        快速发布（跳过检查）"
	@echo ""
	@echo "$(YELLOW)查看$(RESET)"
	@echo "  make list               列出所有文章"
	@echo "  make drafts             列出未发布草稿"
	@echo "  make stats              博客统计"
	@echo ""
	@echo "$(YELLOW)维护$(RESET)"
	@echo "  make optimize           批量压缩图片"
	@echo "  make build              本地构建（检查错误）"
	@echo "  make clean              清除构建缓存"
	@echo "  make update-theme       更新 PaperMod 主题"
	@echo ""
	@echo "$(YELLOW)pre-commit$(RESET)"
	@echo "  make install-hooks      安装 pre-commit hooks"
	@echo "  make check              手动运行所有检查"
	@echo "  make update-hooks       更新 pre-commit 插件"
	@echo "  make scan-secrets       重新扫描密钥基线"

# ============================================
# 写作类
# ============================================
new: ## 新建文章
ifndef slug
	@echo "$(RED)错误：请指定 slug$(RESET)"
	@echo "用法: make new slug=my-post-name"
	@exit 1
endif
	@if [ -d "$(POSTS_DIR)/$(slug)" ]; then \
		echo "$(RED)错误：文章 $(slug) 已存在$(RESET)"; \
		exit 1; \
	fi
	@hugo new content "$(POSTS_DIR)/$(slug)/index.md"
	@echo "$(GREEN)✅ 已创建 $(POSTS_DIR)/$(slug)/index.md$(RESET)"
	@$(OPEN) "$(POSTS_DIR)/$(slug)/index.md"

edit: ## 打开已有文章
ifndef slug
	@echo "$(RED)错误：请指定 slug$(RESET)"
	@echo "用法: make edit slug=my-post-name"
	@exit 1
endif
	@if [ ! -f "$(POSTS_DIR)/$(slug)/index.md" ]; then \
		echo "$(RED)错误：文章 $(slug) 不存在$(RESET)"; \
		exit 1; \
	fi
	@$(OPEN) "$(POSTS_DIR)/$(slug)/index.md"

rm: ## 删除文章（含整个 Page Bundle）
ifndef slug
	@echo "$(RED)错误：请指定 slug$(RESET)"
	@echo "用法: make rm slug=my-post-name"
	@exit 1
endif
	@if [ ! -d "$(POSTS_DIR)/$(slug)" ]; then \
		echo "$(RED)错误：文章 $(slug) 不存在$(RESET)"; \
		exit 1; \
	fi
	@printf "$(YELLOW)确认删除 $(POSTS_DIR)/$(slug)/ ？(y/N) $(RESET)"; \
	read CONFIRM; \
	if [ "$$CONFIRM" = "y" ] || [ "$$CONFIRM" = "Y" ]; then \
		rm -rf "$(POSTS_DIR)/$(slug)"; \
		echo "$(GREEN)✅ 已删除 $(slug)$(RESET)"; \
	else \
		echo "$(YELLOW)已取消$(RESET)"; \
	fi

preview: ## 本地预览（含草稿）
	@echo "$(CYAN)启动本地服务（含草稿）...$(RESET)"
	@hugo server -D --disableFastRender

preview-prod: ## 本地预览（生产模式）
	@echo "$(CYAN)启动本地服务（生产模式）...$(RESET)"
	@hugo server --environment production

# ============================================
# 发布类
# ============================================
publish: ## 把文章转为正式发布
ifndef slug
	@echo "$(RED)错误：请指定 slug$(RESET)"
	@echo "用法: make publish slug=my-post-name"
	@exit 1
endif
	@if [ ! -f "$(POSTS_DIR)/$(slug)/index.md" ]; then \
		echo "$(RED)错误：文章 $(slug) 不存在$(RESET)"; \
		exit 1; \
	fi
	@sed -i '' 's/^draft: true/draft: false/' "$(POSTS_DIR)/$(slug)/index.md"
	@echo "$(GREEN)✅ $(slug) 已转为正式发布$(RESET)"

deploy: ## 严谨发布（带检查）
	@echo "$(CYAN)→ 第 1/4 步：检查 Hugo 构建...$(RESET)"
	@hugo --gc --minify --quiet || (echo "$(RED)❌ 构建失败，请修复后重试$(RESET)" && exit 1)
	@echo "$(GREEN)   ✓ 构建通过$(RESET)"

	@echo "$(CYAN)→ 第 2/4 步：检查未提交改动...$(RESET)"
	@if [ -z "$$(git status --porcelain)" ]; then \
		echo "$(YELLOW)⚠️  没有需要提交的改动$(RESET)"; \
		exit 0; \
	fi
	@echo "$(GREEN)   ✓ 有改动$(RESET)"

	@echo "$(CYAN)→ 第 3/4 步：检查近期改过的草稿...$(RESET)"
	@RECENT_DRAFTS=$$(git status --porcelain | awk '{print $$2}' | grep "$(POSTS_DIR)" | xargs grep -l "^draft: true" 2>/dev/null || true); \
	if [ -n "$$RECENT_DRAFTS" ]; then \
		echo "$(YELLOW)⚠️  以下文章被改动但仍是草稿：$(RESET)"; \
		echo "$$RECENT_DRAFTS" | sed 's/^/    /'; \
		printf "$(YELLOW)是否继续发布？(y/N) $(RESET)"; \
		read CONFIRM; \
		if [ "$$CONFIRM" != "y" ] && [ "$$CONFIRM" != "Y" ]; then \
			echo "$(RED)已取消$(RESET)"; \
			exit 1; \
		fi; \
	else \
		echo "$(GREEN)   ✓ 没有未转正的草稿$(RESET)"; \
	fi

	@echo "$(CYAN)→ 第 4/4 步：提交并推送...$(RESET)"
	@git add .
	@if [ -n "$(m)" ]; then \
		git commit -m "$(m)"; \
	else \
		MSG=$$(make -s _gen-commit-msg); \
		git commit -m "$$MSG"; \
	fi
	@git push
	@echo "$(GREEN)✅ 部署完成，等 1-2 分钟博客自动更新$(RESET)"

deploy-fast: ## 快速发布（跳过检查）
	@echo "$(YELLOW)⚡ 快速发布模式$(RESET)"
	@git add .
	@if [ -n "$(m)" ]; then \
		git commit --no-verify -m "$(m)"; \
	else \
		MSG=$$(make -s _gen-commit-msg); \
		git commit --no-verify -m "$$MSG"; \
	fi
	@git push
	@echo "$(GREEN)✅ 已推送$(RESET)"

# 内部命令：根据 git diff 自动生成 commit message
_gen-commit-msg:
	@NEW_POSTS=$$(git diff --cached --name-only --diff-filter=A | grep "$(POSTS_DIR).*/index.md" | sed 's|$(POSTS_DIR)/||;s|/index.md||' | head -3); \
	MOD_POSTS=$$(git diff --cached --name-only --diff-filter=M | grep "$(POSTS_DIR).*/index.md" | sed 's|$(POSTS_DIR)/||;s|/index.md||' | head -3); \
	HAS_CONFIG=$$(git diff --cached --name-only | grep -E "(hugo\.toml|\.github/|Makefile|archetypes/|\.pre-commit)" | head -1); \
	if [ -n "$$NEW_POSTS" ]; then \
		echo "post: $$(echo $$NEW_POSTS | tr '\n' ',' | sed 's/,$$//')"; \
	elif [ -n "$$MOD_POSTS" ]; then \
		echo "update: $$(echo $$MOD_POSTS | tr '\n' ',' | sed 's/,$$//')"; \
	elif [ -n "$$HAS_CONFIG" ]; then \
		echo "chore: update config"; \
	else \
		echo "chore: $$(date +%Y-%m-%d)"; \
	fi

# ============================================
# 查看类
# ============================================
list: ## 列出所有文章
	@echo "$(CYAN)所有文章：$(RESET)"
	@ls -1 $(POSTS_DIR) 2>/dev/null | sed 's/^/  /' || echo "  （无）"

drafts: ## 列出未发布草稿
	@echo "$(CYAN)未发布草稿：$(RESET)"
	@DRAFTS=$$(grep -rl "^draft: true" $(POSTS_DIR) 2>/dev/null); \
	if [ -z "$$DRAFTS" ]; then \
		echo "  （无）"; \
	else \
		echo "$$DRAFTS" | sed 's|$(POSTS_DIR)/||;s|/index.md||;s/^/  /'; \
	fi

stats: ## 博客统计
	@echo "$(CYAN)📊 博客统计$(RESET)"
	@TOTAL=$$(find $(POSTS_DIR) -name "index.md" 2>/dev/null | wc -l | tr -d ' '); \
	DRAFT=$$(grep -rl "^draft: true" $(POSTS_DIR) 2>/dev/null | wc -l | tr -d ' '); \
	PUBLISHED=$$((TOTAL - DRAFT)); \
	WORDS=$$(find $(POSTS_DIR) -name "index.md" -exec cat {} \; 2>/dev/null | wc -c | tr -d ' '); \
	WEEK_AGO=$$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "7 days ago" +%Y-%m-%d); \
	RECENT=$$(find $(POSTS_DIR) -name "index.md" -newermt "$$WEEK_AGO" 2>/dev/null | wc -l | tr -d ' '); \
	echo "  总文章数:    $$TOTAL"; \
	echo "  已发布:      $$PUBLISHED"; \
	echo "  草稿:        $$DRAFT"; \
	echo "  总字符数:    $$WORDS"; \
	echo "  近 7 天新增: $$RECENT"

# ============================================
# 维护类
# ============================================
optimize: ## 压缩所有图片
	@if ! command -v pngquant >/dev/null 2>&1; then \
		echo "$(RED)未安装 pngquant，请先：brew install pngquant$(RESET)"; \
		exit 1; \
	fi
	@echo "$(CYAN)正在压缩 PNG 图片...$(RESET)"
	@find $(POSTS_DIR) -name "*.png" -type f | while read img; do \
		BEFORE=$$(stat -f%z "$$img" 2>/dev/null || stat -c%s "$$img"); \
		pngquant --quality=65-80 --ext .png --force --skip-if-larger "$$img" 2>/dev/null || true; \
		AFTER=$$(stat -f%z "$$img" 2>/dev/null || stat -c%s "$$img"); \
		if [ "$$BEFORE" != "$$AFTER" ]; then \
			echo "  ✓ $$img ($$BEFORE → $$AFTER bytes)"; \
		fi; \
	done
	@echo "$(GREEN)✅ 完成$(RESET)"

build: ## 本地构建（检查错误用）
	@echo "$(CYAN)开始构建...$(RESET)"
	@hugo --gc --minify
	@echo "$(GREEN)✅ 构建成功，输出在 ./public$(RESET)"

clean: ## 清除构建缓存
	@rm -rf public/ resources/ .hugo_build.lock
	@echo "$(GREEN)✅ 已清除构建缓存$(RESET)"

update-theme: ## 更新 PaperMod 主题
	@echo "$(CYAN)更新 PaperMod 主题...$(RESET)"
	@cd themes/PaperMod && git pull origin master
	@git add themes/PaperMod
	@git commit -m "chore: update PaperMod theme" || echo "$(YELLOW)主题已是最新版$(RESET)"
	@echo "$(GREEN)✅ 主题更新完成$(RESET)"

# ============================================
# pre-commit 类
# ============================================
install-hooks: ## 安装 pre-commit hooks
	@if ! command -v pre-commit >/dev/null 2>&1; then \
		echo "$(RED)未安装 pre-commit, 请先: brew install pre-commit$(RESET)"; \
		exit 1; \
	fi
	@if [ ! -f .secrets.baseline ]; then \
		echo "$(YELLOW)生成密钥检测基线...$(RESET)"; \
		detect-secrets scan > .secrets.baseline; \
	fi
	@pre-commit install
	@echo "$(GREEN)✅ pre-commit hooks 已安装$(RESET)"

check: ## 手动运行所有检查
	@pre-commit run --all-files

update-hooks: ## 更新 pre-commit 插件
	@pre-commit autoupdate
	@echo "$(GREEN)✅ hooks 已更新$(RESET)"

scan-secrets: ## 重新扫描密钥基线
	@detect-secrets scan --baseline .secrets.baseline
	@echo "$(GREEN)✅ 基线已更新$(RESET)"
	@echo "$(YELLOW)如需审计: detect-secrets audit .secrets.baseline$(RESET)"
