---
name: video-analyzer
description: 分析网页视频（B站/YouTube 等）。用 yt-dlp 下载、FFmpeg 抽帧、视觉模型读图，输出带时间点的讲义。用户提供视频链接并要求总结/分析/做讲义时使用。字幕优先，无字幕走抽帧路线。
metadata:
  author: "Torricelli0"
  version: "1.0.0"
  repository: "https://github.com/Torricelli0/video-analyzer"
---

# 视频分析（video-analyzer）

把视频链接变成带时间点和证据来源的讲义。

**核心原则**：先实际取得媒体内容，再让模型分析。永远不要仅凭标题/简介编造视频内容。

## 工具依赖

```bash
# macOS
brew install yt-dlp ffmpeg

# 验证
which yt-dlp ffmpeg
```

**必需**：
- `yt-dlp`：下载视频/音频/字幕
- `ffmpeg`：抽帧、转码、提取音频
- 模型的**视觉能力**（读图片）——纯文本模型无法读帧，需要先 OCR/ASR 转文字

**可选**：
- Whisper / 其他 ASR：把音频转文字
- OCR 工具：把画面文字转成文本（给纯文本模型用）

## 完整流程

### 第 1 步：检查工具

```bash
which yt-dlp ffmpeg || echo "缺少工具，先 brew install yt-dlp ffmpeg"
```

### 第 2 步：取元信息（不下载）

```bash
yt-dlp --dump-single-json --no-warnings --skip-download "<URL>"
```

拿到：标题、时长、UP主、简介、标签。简介里常有作者补充的关键信息（如开源链接）。

### 第 3 步：检查字幕

```bash
yt-dlp --list-subs "<URL>"
```

**判断**：
- 有讲解字幕（如 `zh-Hans`）→ 优先下载字幕，**字幕优先于抽帧**
- 只有 `danmaku`（弹幕）→ **不要把弹幕当讲稿**，走抽帧路线
- B站字幕接口经常只返回弹幕，这是正常现象

### 第 4 步：下载视频

```bash
# 480P + 最佳音频，足够读字幕和课件
yt-dlp -f "best[height<=480]+bestaudio/best" --no-warnings -o "video.%(ext)s" "<URL>"
```

**注意**：
- 1080P 通常需要会员 cookie，480P 对读文字足够
- 如需 cookie：`--cookies-from-browser chrome`
- 查看可用格式：`yt-dlp --list-formats "<URL>"`

### 第 5 步：抽帧

```bash
mkdir -p frames
# 每 20 秒一帧（短片 10 秒，长片 30 秒）
ffmpeg -i video.mp4 -vf "fps=1/20,scale=960:-1" -q:v 3 frames/frame_%03d.jpg -y
```

**抽帧间隔建议**：
- 视频 < 5 分钟：每 10 秒
- 5-20 分钟：每 20 秒
- > 20 分钟：每 30-60 秒，或先按章节定位再针对性抽

**帧文件名与时间对应**：`frame_001.jpg` ≈ 00:00:20，`frame_002.jpg` ≈ 00:00:40，以此类推（fps=1/20 时）。

### 第 6 步：读取画面

**有视觉能力**：逐张读取 frames/*.jpg，转录画面上的：
- 硬字幕（视频底部的对白字幕）
- 幻灯片/课件内容
- 界面截图里的文字

**无视觉能力**：
```bash
# 提取音频
ffmpeg -i video.mp4 -vn -acodec mp3 audio.mp3
# 用 Whisper 等 ASR 转文字
whisper audio.mp3 --model medium --output_format srt
# 或用 OCR 工具处理帧图片
```

### 第 7 步：组织输出

按视频自身的章节顺序组织讲义，每个知识点标注：
- **时间点**（来自哪一帧）
- **证据来源**（字幕原文 / 画面文字 / 推断）
- **无法确认的部分**明确说明

## 输出规范

### 必须包含

1. **视频信息**：标题、UP主、时长、BV号/URL
2. **分析方式说明**：用了字幕还是抽帧，字幕接口返回了什么
3. **按章节组织的内容**：跟随视频自身的章节结构
4. **金句/要点表**：原话摘录
5. **证据边界**：哪些是字幕/画面直接说的，哪些是推断，哪些没取到

### 严禁

- ❌ 只看标题和简介就编造全片内容
- ❌ 把弹幕当成讲解字幕
- ❌ 无法确认的内容写得像确定的
- ❌ 声称"看完了视频"但实际只看了几帧

## 证据格式（推荐）

传给模型或写入文件时用这个结构：

```json
{
  "video_title": "示例标题",
  "duration_seconds": 406,
  "evidence": [
    {
      "type": "subtitle",
      "start": 32.1,
      "end": 37.8,
      "text": "讲解原文"
    },
    {
      "type": "frame",
      "timestamp": 35.0,
      "path": "frames/000035.jpg",
      "visible_text": "幻灯片上的文字"
    }
  ]
}
```


## 输出格式：Markdown 或 HTML

默认输出 Markdown 讲义。如果用户想要**浏览器里可看、可搜索的页面**，生成 HTML。

### 生成 HTML 讲义

**第 1 步**：把分析结果写成 JSON：

```json
{
  "title": "视频标题",
  "date": "2026-11-17",
  "duration": "6:46",
  "platform": "B站",
  "summary": "一句话摘要",
  "method": "抽帧读硬字幕（字幕接口仅返回弹幕）",
  "source_url": "https://www.bilibili.com/video/BVxxxx",
  "sections": [
    {
      "heading": "一、章节标题",
      "timestamp": "00:20",
      "body": "<p>正文段落</p><ul><li>要点</li></ul>",
      "evidence": "画面硬字幕 / 幻灯片文字"
    }
  ]
}
```

**第 2 步**：渲染

```bash
python3 scripts/build-report.py content.json report.html
```

**第 3 步**：打开查看

```bash
open report.html          # macOS
xdg-open report.html      # Linux
```

### HTML 样式说明

`templates/report.html` 采用 **Terminal Aesthetic**（黑底 + 单一蓝 `#6799fe`）：

- 黑底 `#0a0a0a`，白字，极淡边框
- 时间戳用蓝色胶囊标签（`<span class="ts">00:20</span>`）
- 引用块左侧蓝色竖线
- 证据来源用虚线框单独标注
- 无外部依赖，单文件可直接分享

**为什么用这套风格**：与作者博客保持一致的视觉语言，便于统一归档和二次发布。

### Slack：如果要别的风格

模板是可替换的——复制 `templates/report.html` 改 CSS 即可。常见风格：
- **极简白**：`#fbfaf8` 背景 + 深灰字（适合打印）
- **杂志感**：大字号 + 衬线体（适合长文阅读）


## 常见平台注意事项

| 平台 | 字幕情况 | 备注 |
|---|---|---|
| **B站** | 字幕接口常只返回 danmaku（弹幕） | 1080P 需会员 cookie；480P 够读字 |
| **YouTube** | 通常有自动字幕 | `--write-auto-subs` 可下载 |
| **需要登录** | 用 `--cookies-from-browser chrome` | 遵守平台访问规则 |

## 边界说明

- 多模态模型 ≠ 能打开任意视频网站；它只处理传入的图片/音频
- 播放器能打开 ≠ 内容已被分析；要确认实际读到了字幕/帧
- Skill 只提供流程；下载/抽帧/转写靠工具执行
- MCP 只是连接协议，本身不含视频解析能力
- 不同视频结果不同：字幕、登录、平台限制、时长都会影响路径
