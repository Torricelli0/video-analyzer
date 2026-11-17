# video-analyzer

一个 Agent Skill：把网页视频链接变成带时间点和证据来源的讲义。

用 `yt-dlp` 取媒体、`FFmpeg` 抽帧、视觉模型读图。B站等平台字幕接口常只返回弹幕，因此主打"抽帧读硬字幕"路线。

## 安装

### 方式一：一行脚本（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/Torricelli0/video-analyzer/main/install.sh | bash
```

脚本会自动检测 Codex / Claude / DSH，把 skill 装到对应目录。

### 方式二：手动

```bash
git clone https://github.com/Torricelli0/video-analyzer.git
mkdir -p ~/.codex/skills
ln -s "$PWD/video-analyzer" ~/.codex/skills/video-analyzer
```

## 依赖

```bash
brew install yt-dlp ffmpeg    # macOS
```

模型需要有视觉能力（能读图片）。纯文本模型需额外配 OCR/ASR。

## 用法

安装后，对 Agent 说：

```
帮我分析这个视频：https://www.bilibili.com/video/BVxxxx
```

Agent 会自动：检查工具 → 取元信息 → 查字幕 → 下载 → 抽帧 → 读图 → 输出讲义。

## 文件

- `SKILL.md` — skill 主体
- `install.sh` — 一键安装脚本

## License

MIT
