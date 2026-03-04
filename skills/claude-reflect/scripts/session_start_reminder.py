#!/usr/bin/env python3
"""
SessionStart hook: 快速健康检查，提示缺失配置。
轻量级 — 必须在 1 秒内完成，不阻塞 Claude 启动。
"""
import sys
import os
import importlib.util

CLAUDE_DIR = os.path.expanduser("~/.claude")
issues = []

# 检查关键 Python 包
REQUIRED_PACKAGES = ["PIL", "pandas", "matplotlib"]
for pkg in REQUIRED_PACKAGES:
    if importlib.util.find_spec(pkg) is None:
        issues.append(f"Python 包缺失: {pkg}")

# 检查 MCP 配置
mcp_path = os.path.join(CLAUDE_DIR, ".mcp.json")
if not os.path.exists(mcp_path):
    issues.append("MCP 未配置 (.mcp.json 不存在)")

# 检查 gh CLI 认证（只检查可执行文件存在，不运行 auth status 避免慢）
import shutil
if not shutil.which("gh"):
    issues.append("gh CLI 未安装")

if issues:
    print("\n⚠️  Claude Config — 健康检查发现问题：", file=sys.stderr)
    for issue in issues:
        print(f"  • {issue}", file=sys.stderr)
    print("  → 运行 bash ~/.claude/scripts/bootstrap.sh 自动修复\n", file=sys.stderr)

sys.exit(0)
