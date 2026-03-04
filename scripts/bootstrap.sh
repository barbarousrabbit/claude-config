#!/bin/bash
# =============================================================
# Claude Config Bootstrap — 新设备一次性初始化脚本
# 用法: bash ~/.claude/scripts/bootstrap.sh
# =============================================================
set -e

CLAUDE_DIR="$HOME/.claude"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "    $1"; }

echo ""
echo "============================================"
echo "   Claude Config — New Device Bootstrap"
echo "============================================"
echo ""

# ── 0. 探测设备环境 ──────────────────────────────────────────
echo "→ 探测设备环境..."
bash "$CLAUDE_DIR/scripts/detect-env.sh"
source "$CLAUDE_DIR/local-env.sh" 2>/dev/null || true
ok "环境探测完成 (Python=${CLAUDE_PYTHON}, OS=${CLAUDE_OS})"

# ── 1. Git 分支跟踪 ──────────────────────────────────────────
echo "→ 配置 git 跟踪..."
cd "$CLAUDE_DIR"
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null 2>&1; then
    git branch --set-upstream-to=origin/main master 2>/dev/null || \
    git branch --set-upstream-to=origin/main main 2>/dev/null || true
fi
ok "Git 跟踪已配置"

# ── 2. Python 依赖 ────────────────────────────────────────────
echo "→ 安装 Python skill 依赖..."
if [ -n "$CLAUDE_PIP" ] && command -v "$CLAUDE_PIP" &>/dev/null; then
    "$CLAUDE_PIP" install -q -r "$CLAUDE_DIR/skills/requirements.txt" 2>/dev/null && ok "Python 依赖安装完成" || warn "部分 Python 依赖安装失败，可手动运行: ${CLAUDE_PIP} install -r ~/.claude/skills/requirements.txt"
else
    warn "未找到 pip，跳过 Python 依赖安装"
fi

# ── 3. Node / npx 检测 ───────────────────────────────────────
echo "→ 检测 Node.js..."
if command -v node &>/dev/null; then
    ok "Node.js $(node --version) 已安装"
else
    warn "未找到 Node.js — 部分 skill 需要 npx，建议安装 https://nodejs.org"
fi

# ── 4. GitHub CLI 检测 ────────────────────────────────────────
echo "→ 检测 GitHub CLI..."
if command -v gh &>/dev/null; then
    if gh auth status &>/dev/null 2>&1; then
        ok "gh CLI 已认证"
    else
        warn "gh CLI 已安装但未登录，请运行: gh auth login"
    fi
else
    warn "未找到 gh CLI — 建议安装 https://cli.github.com"
fi

# ── 5. MCP 配置 ───────────────────────────────────────────────
echo "→ 检测 MCP 配置..."
MCP_TARGET="$HOME/.claude/.mcp.json"
MCP_EXAMPLE="$CLAUDE_DIR/.mcp.json.example"

if [ -f "$MCP_TARGET" ]; then
    ok "MCP 配置已存在: $MCP_TARGET"
else
    if [ -f "$MCP_EXAMPLE" ]; then
        cp "$MCP_EXAMPLE" "$MCP_TARGET"
        warn "已从模板创建 MCP 配置: $MCP_TARGET"
        info "请编辑该文件，填入你的 API Token："
        info "  GitHub Token: https://github.com/settings/tokens"
    else
        warn "未找到 MCP 模板文件"
    fi
fi

# ── 6. 检测 uv (推荐 Python 包管理) ──────────────────────────
if ! command -v uv &>/dev/null; then
    warn "未找到 uv (更快的 pip 替代)，可选安装: pip install uv"
fi

# ── 完成 ──────────────────────────────────────────────────────
echo ""
echo "============================================"
ok "Bootstrap 完成！"
echo ""
echo "下一步（如有未完成项）："
echo "  1. 编辑 ~/.claude/.mcp.json 填入 API Token"
echo "  2. 运行 gh auth login 登录 GitHub CLI"
echo "  3. 重启 Claude Code 使配置生效"
echo "============================================"
echo ""
