#!/bin/bash
# video-analyzer 一键安装脚本
set -e

SKILL_NAME="video-analyzer"
REPO_URL="https://github.com/Torricelli0/video-analyzer.git"
TMP_DIR=$(mktemp -d)

echo "=== video-analyzer 安装 ==="

# 克隆到临时目录
git clone --depth 1 "$REPO_URL" "$TMP_DIR/repo" 2>/dev/null

INSTALLED=0

# Codex
if [ -d "$HOME/.codex/skills" ]; then
  rm -rf "$HOME/.codex/skills/$SKILL_NAME"
  cp -R "$TMP_DIR/repo/$SKILL_NAME" "$HOME/.codex/skills/$SKILL_NAME"
  echo "✅ Codex: ~/.codex/skills/$SKILL_NAME"
  INSTALLED=1
fi

# Claude Code（通过 .agents 共享池）
if [ -d "$HOME/.agents/skills" ]; then
  rm -rf "$HOME/.agents/skills/$SKILL_NAME"
  cp -R "$TMP_DIR/repo/$SKILL_NAME" "$HOME/.agents/skills/$SKILL_NAME"
  echo "✅ Claude 共享池: ~/.agents/skills/$SKILL_NAME"
  INSTALLED=1
  if [ -d "$HOME/.claude/skills" ]; then
    ln -sfn "../../.agents/skills/$SKILL_NAME" "$HOME/.claude/skills/$SKILL_NAME" 2>/dev/null || true
    echo "✅ Claude Code 链接: ~/.claude/skills/$SKILL_NAME"
  fi
fi

# DSH（无 skill 机制，装到参考目录供 AI 读取）
if [ -d "$HOME/.dsh" ]; then
  mkdir -p "$HOME/.dsh/skills"
  rm -rf "$HOME/.dsh/skills/$SKILL_NAME"
  cp -R "$TMP_DIR/repo/$SKILL_NAME" "$HOME/.dsh/skills/$SKILL_NAME"
  echo "✅ DSH: ~/.dsh/skills/$SKILL_NAME（DSH 无原生加载，需让 AI 读取 SKILL.md）"
  INSTALLED=1
fi

# 依赖检查
echo ""
echo "=== 依赖检查 ==="
for t in yt-dlp ffmpeg; do
  if command -v "$t" >/dev/null 2>&1; then
    echo "✅ $t 已安装"
  else
    echo "❌ $t 未安装，请运行: brew install yt-dlp ffmpeg"
  fi
done

rm -rf "$TMP_DIR"
echo ""
if [ "$INSTALLED" -eq 1 ]; then
  echo "🎉 安装完成"
else
  echo "⚠️ 未检测到任何 agent 目录，请手动复制 $SKILL_NAME 到对应 skills 目录"
fi
