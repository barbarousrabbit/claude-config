---
name: codex-video-skin
description: "Use when setting a looping VIDEO background (animated wallpaper) for the Codex / ChatGPT desktop app on Windows via Codex Dream Skin, replacing a video wallpaper, re-applying the video patch after a Dream Skin update, or toggling sidebar transparency over video — '换视频背景', '动态壁纸', '视频皮肤', 'Codex 换视频', '侧栏透明'"
user-invocable: true
args:
  - name: video
    description: Path to the source video file to use as the wallpaper
    required: false
  - name: start
    description: Start timestamp in seconds to cut the 8s clip from (default 0)
    required: false
---

# Codex Dream Skin — Video Wallpaper (Windows)

Upstream Codex Dream Skin supports **still images only on Windows**; video exists
only in a macOS fork. This skill applies a local port of the video layer and
drives the whole change-the-video workflow.

## Scope and preconditions

- **Windows only.** macOS users should use the upstream macOS video build instead.
- Codex Dream Skin installed at `%LOCALAPPDATA%\Programs\CodexDreamSkin`.
- Verified against **Dream Skin v1.5.12** + **OpenAI.Codex 26.803.10989.0**.
- `ffmpeg` on PATH (winget `Gyan.FFmpeg`) for cutting and transcoding.
- Bundled Node lives at `payload\runtime\node\node.exe` — use it, do not require a system Node.

Paths used throughout:

| Purpose | Path |
|---|---|
| Runtime payload | `%LOCALAPPDATA%\Programs\CodexDreamSkin\payload` |
| Active theme | `%LOCALAPPDATA%\CodexDreamSkin\active-theme` |
| Video file (must be this exact name) | `<active-theme>\background-video.mp4` |
| Injector log | `%LOCALAPPDATA%\CodexDreamSkin\injector.log` |

## Hard constraints (do not skip)

The video is base64-encoded into the injected script and shipped to the renderer
over CDP `Runtime.evaluate`. Base64 inflates bytes by ~33%, so **source size is
the binding limit, not visual quality**.

- Target **≤ 8 seconds**, **1920×1080**, **30 fps**, **H.264 in .mp4**.
- Aim for **2–4 MB** on disk. A 2.18 MB clip → ~3 MB payload, which works.
- A 4K/60 multi-minute source is unusable directly — always cut and downscale.
- The file **must** be named `background-video.mp4`; the loader keys on that name.
- Pick a segment matching the composition rules: quiet low-information left side
  (`x = 0–52%`), subject weighted right. Space/night/interior shots work best.

## Workflow

### 1. Cut and transcode

```powershell
ffmpeg -y -ss <START> -t 8 -i "<SOURCE>" `
  -vf "scale=1920:1080:flags=lanczos,fps=30" `
  -c:v libx264 -profile:v high -pix_fmt yuv420p -crf 26 -preset slow `
  -an -movflags +faststart "<OUT>\background-video.mp4"
```

Raise `-crf` (28–30) if the result exceeds ~4 MB. `-an` is deliberate: audio is
useless here and only adds bytes. VP9/WebM sources may print `Invalid data found
when processing input` during fast seek — harmless if the output file is produced.

To choose a segment, render a contact sheet first:

```powershell
ffmpeg -y -i "<SOURCE>" -vf "fps=1/41,scale=420:-1,tile=3x2" -frames:v 1 sheet.png
```

### 2. Ensure the patch is applied

Run `scripts/apply-patch.ps1` (see below). It is idempotent and self-verifying —
it checks whether `renderer-inject.js` already accepts a `videoDataUrl` argument
and only patches if missing.

### 3. Place the video

Copy the clip to `<active-theme>\background-video.mp4`.

### 4. Restart and inject

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

Injection takes ~30 s. Confirm with `injector.log` showing `injected target <id>`.

### 5. Verify — never trust the log alone

```powershell
& "$env:LOCALAPPDATA\Programs\CodexDreamSkin\payload\runtime\node\node.exe" scripts/probe-video.mjs
```

Expect `paused: false`, `displayed: "block"`, `readyState: 4`, a rising
`currentTime`, and `activeAttr: "true"`. **`displayed: "none"` with everything
else healthy means the reduced-motion trap below.**

Note the app exposes **two** CDP page targets; the `?initialRoute=/avatar-overlay`
one is never skinned. Always probe the plain `app://-/index.html` target.

## Gotchas

**Reduced motion silently kills it.** Windows reports
`prefers-reduced-motion: reduce` whenever *Show animations in Windows* is off
(`HKCU\Control Panel\Desktop\WindowMetrics\MinAnimate = 0`). That setting targets
UI animation, not wallpaper. A `@media (prefers-reduced-motion: reduce)` rule
hiding the video makes it decode and play perfectly while staying invisible.
The shipped CSS deliberately omits such a rule.

**The body paints over the video.** The video sits at `z-index: -1`, but
`html[data-dream-skin="active"] body` sets an opaque `background`. The patch
clears it *only* once `data-dream-video-active="true"`, so a refused autoplay
falls back to the still image instead of a blank window.

**Video needs harder grading than a still.** A still is graded once for the UI;
footage swings from dark frames to blown highlights and drowns sidebar text. The
patch applies `filter: brightness(.38) saturate(.9)` to the whole layer.

**Updates wipe everything.** Running `CodexDreamSkin-Setup-*.exe` replaces
`payload\`. Re-run `apply-patch.ps1` afterwards. Switching themes replaces
`active-theme\`, dropping the video — re-copy it.

## Sidebar transparency toggle

The patch injects a pill button (top-right, idles at 46% opacity) that switches
the sidebar between two variants and remembers the choice in `localStorage`
(`codex-dream-skin-sidebar-mode`):

- **`translucent`** (default) — footage visible through the sidebar; text kept
  readable with a hard `text-shadow` rather than an opaque plate.
- **`opaque`** — sidebar fully hides the video; maximum legibility, no motion in
  peripheral vision.

Set it without clicking:

```js
localStorage.setItem("codex-dream-skin-sidebar-mode", "opaque");
document.documentElement.setAttribute("data-dream-sidebar", "opaque");
```

## Reverting

Restore the three pristine files from `assets/original/` into `payload\`, delete
`<active-theme>\background-video.mp4`, and restart. Or simply reinstall via
`CodexDreamSkin-Setup-*.exe`, which restores stock files (and drops the patch).

## What the patch changes

| File | Change |
|---|---|
| `assets/renderer-inject.js` | IIFE takes `videoDataUrl`; adds `ensureVideoLayer()` creating `<video id="codex-dream-skin-video">` as body's first child; adds `ensureSidebarToggle()`; `data-dream-media` / `data-dream-video-active` / `data-dream-sidebar` state; revokes object URLs on cleanup |
| `assets/dream-skin.css` | Video layer styling, background hand-off, brightness grading, two sidebar variants, toggle button |
| `scripts/injector.mjs` | Reads `background-video.mp4` → base64 data URL → `__DREAM_SKIN_VIDEO_JSON__`; video hash folded into the payload revision |

`injector.mjs --check-payload --theme-dir <active-theme>` validates placeholder
substitution and parses the assembled script. Run it after any edit; `"pass":true`
means the payload is well-formed.
