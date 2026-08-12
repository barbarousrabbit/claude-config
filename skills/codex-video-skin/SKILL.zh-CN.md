# Codex Dream Skin — 视频壁纸（Windows）

English (authoritative): [SKILL.md](./SKILL.md)

> 这是 `SKILL.md` 的中文对照版，供阅读理解。Claude 实际加载的是 `SKILL.md`，
> 两边不一致时以英文版为准。

上游 Codex Dream Skin 在 **Windows 上只支持静态图片**，视频层只存在于 macOS 分支。
本技能应用该视频层的本地移植，并驱动整个换视频的流程。

## 适用范围与前置条件

- **仅限 Windows。** macOS 用户请直接用上游的 macOS 视频构建。
- Dream Skin 装在 `%LOCALAPPDATA%\Programs\CodexDreamSkin`。
- 已在 **Dream Skin v1.5.12** + **OpenAI.Codex 26.803.10989.0** 上验证。
- 需要 PATH 上有 `ffmpeg`（winget `Gyan.FFmpeg`）用于剪辑和转码。
- 自带的 Node 在 `payload\runtime\node\node.exe`——用它，不要依赖系统 Node。

全文用到的路径：

| 用途 | 路径 |
|---|---|
| 运行时 payload | `%LOCALAPPDATA%\Programs\CodexDreamSkin\payload` |
| 当前主题 | `%LOCALAPPDATA%\CodexDreamSkin\active-theme` |
| 视频文件（必须是这个文件名） | `<active-theme>\background-video.mp4` |
| 注入日志 | `%LOCALAPPDATA%\CodexDreamSkin\injector.log` |

## 硬约束（不能跳）

视频会被 base64 编码进注入脚本，再经 CDP `Runtime.evaluate` 送到渲染进程。
base64 让字节数膨胀约 33%，所以**源文件大小才是上限，不是画质**。

- 目标 **≤ 8 秒**、**1920×1080**、**30 fps**、**H.264 封装在 .mp4**。
- 磁盘上争取 **2–4 MB**。2.18 MB 的片段 → 约 3 MB payload，可用。
- 4K/60 的多分钟源片直接用是不可行的——必须先剪再降分辨率。
- 文件名**必须**是 `background-video.mp4`，加载器就认这个名字。
- 挑片段要符合构图规则：左侧（`x = 0–52%`）安静、低信息，主体压右。
  太空、夜景、室内镜头最稳。

## 流程

### 1. 剪辑与转码

```powershell
ffmpeg -y -ss <START> -t 8 -i "<SOURCE>" `
  -vf "scale=1920:1080:flags=lanczos,fps=30" `
  -c:v libx264 -profile:v high -pix_fmt yuv420p -crf 26 -preset slow `
  -an -movflags +faststart "<OUT>\background-video.mp4"
```

结果超过约 4 MB 就把 `-crf` 提到 28–30。`-an` 是故意的：音轨在这里没用，只占字节。
VP9/WebM 源在快速定位时可能打印 `Invalid data found when processing input`，
只要输出文件正常生成就无害。

挑片段前先出一张缩略图墙：

```powershell
ffmpeg -y -i "<SOURCE>" -vf "fps=1/41,scale=420:-1,tile=3x2" -frames:v 1 sheet.png
```

### 2. 确认补丁已应用

跑 `scripts/apply-patch.ps1`。它是幂等且自校验的——会检查 `renderer-inject.js`
是否已经接受 `videoDataUrl` 参数，只在缺失时才打补丁。

### 3. 放置视频

把片段复制到 `<active-theme>\background-video.mp4`。

### 4. 重启并注入

```powershell
$S = "$env:LOCALAPPDATA\Programs\CodexDreamSkin\payload\scripts"
Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
  Where-Object { $_.CommandLine -like "*CodexDreamSkin*" } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Get-CimInstance Win32_Process -Filter "Name='ChatGPT.exe' OR Name='Codex.exe'" |
  Where-Object { $_.ExecutablePath -like "*WindowsApps*" } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Start-Sleep 3
Start-Process powershell.exe -ArgumentList "-NoProfile","-ExecutionPolicy","RemoteSigned","-File","$S\start-dream-skin.ps1" -WindowStyle Hidden
```

注入约需 30 秒。`injector.log` 出现 `injected target <id>` 即确认。

### 5. 验证——绝不能只信日志

```powershell
& "$env:LOCALAPPDATA\Programs\CodexDreamSkin\payload\runtime\node\node.exe" scripts/probe-video.mjs
```

预期 `paused: false`、`displayed: "block"`、`readyState: 4`、`currentTime` 在涨、
`activeAttr: "true"`。**其它都健康但 `displayed: "none"`，就是下面那个减少动画的陷阱。**

注意应用暴露**两个** CDP page target，带 `?initialRoute=/avatar-overlay` 的那个
永远不会被换肤。永远探测普通的 `app://-/index.html`。

## 坑

**减少动画会静默杀掉它。** Windows 只要关掉「显示动画」
（`HKCU\Control Panel\Desktop\WindowMetrics\MinAnimate = 0`）就会报告
`prefers-reduced-motion: reduce`。那个设置针对的是 UI 动画而不是壁纸。
一条隐藏视频的 `@media (prefers-reduced-motion: reduce)` 规则，会让视频解码、播放
一切正常却完全不可见。随附的 CSS 故意不写这条规则。

**body 会盖住视频。** 视频在 `z-index: -1`，但
`html[data-dream-skin="active"] body` 设了不透明背景。补丁只在
`data-dream-video-active="true"` 之后才清掉它——这样自动播放被拒时会回落到静图，
而不是白屏。

**视频比静图需要更狠的分级。** 静图只为 UI 调一次色；视频帧在暗帧与过曝之间摆动，
会淹掉侧栏文字。补丁对整层施加 `filter: brightness(.38) saturate(.9)`。

**升级会清空一切。** 跑 `CodexDreamSkin-Setup-*.exe` 会替换 `payload\`，之后要重跑
`apply-patch.ps1`。切换主题会替换 `active-theme\`，视频随之丢失——需要重新复制。

## 侧栏透明切换

补丁注入了一个小药丸按钮（右上角，静置时 46% 不透明度），在两种侧栏形态间切换，
选择记在 `localStorage` 的 `codex-dream-skin-sidebar-mode`：

- **`translucent`**（默认）——画面透过侧栏可见，文字靠硬阴影而非不透明底板保持可读。
- **`opaque`**——侧栏完全挡住视频，可读性最高，余光里没有动态干扰。

不点按钮直接设置：

```js
localStorage.setItem("codex-dream-skin-sidebar-mode", "opaque");
document.documentElement.setAttribute("data-dream-sidebar", "opaque");
```

## 回滚

把 `assets/original/` 里三个原始文件还原进 `payload\`，删掉
`<active-theme>\background-video.mp4`，重启即可。或者直接重装
`CodexDreamSkin-Setup-*.exe`，它会恢复原厂文件（补丁一并消失）。

## 补丁改了什么

| 文件 | 改动 |
|---|---|
| `assets/renderer-inject.js` | IIFE 接受 `videoDataUrl`；新增 `ensureVideoLayer()`，把 `<video id="codex-dream-skin-video">` 插为 body 首个子元素；新增 `ensureSidebarToggle()`；维护 `data-dream-media` / `data-dream-video-active` / `data-dream-sidebar` 状态；清理时回收 object URL |
| `assets/dream-skin.css` | 视频层样式、背景交接、亮度分级、两套侧栏变体、切换按钮 |
| `scripts/injector.mjs` | 读取 `background-video.mp4` → base64 data URL → `__DREAM_SKIN_VIDEO_JSON__`；视频哈希并入 payload 修订号 |

`injector.mjs --check-payload --theme-dir <active-theme>` 校验占位符替换并解析组装后的脚本。
任何改动后都跑一次；`"pass":true` 表示 payload 结构良好。

## 上游仓库

补丁的唯一事实来源是 **Codex-Skins** 仓库的 `video-patch/`。
本技能目录里的副本是为了让技能自包含而存在的镜像，改动方向永远是仓库 → 技能。
已验证可用的视频片段与配套主题在该仓库的 `themes/freedom-gundam-video/`。
