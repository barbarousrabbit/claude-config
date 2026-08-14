---
name: dream-skin-theme
description: Build, modify or verify a Codex Dream Skin theme in this repository - changing colours, the title bar, the sidebar, the wallpaper or a skin toggle, or diagnosing a skin that looks wrong, will not start, or fails package validation. Use whenever the work touches themes/, tools/ or video-patch/. 触发词：改皮肤、换壁纸、主题不生效、校验失败、注入不上。
---

# Working on a Dream Skin theme

This skill routes. It deliberately does not restate what the repository documents,
because two copies of a rule drift and the copy people read is the one that is wrong.
本 skill 只做路由。它刻意不复述仓库已有的内容——同一条规则存两份必然漂移，
而人们读到的往往正是错的那份。

## Read before editing / 动手前先读

Always, in this order:
每次都按这个顺序：

1. `AGENTS.md` — the rules both agents follow. Non-negotiable.
   两个 agent 共同遵守的规则，没有商量余地。
2. `docs/skin-ui-map.md` — which file and selector owns each Codex UI area, and the full
   wallpaper pipeline. Answers "where do I change this?"
   哪块 UI 归哪个文件和选择器管，以及完整的壁纸链路。回答「这个要去哪改」。
3. `docs/skin-troubleshooting.md` — 21 recorded faults with root cause, fix and regression
   check. Answers "has this already bitten someone?" **Search it before debugging anything.**
   21 条故障记录，含根因、修法和回归检查。回答「这个坑别人踩过没」。**开始调试前先搜它。**
4. `themes/<theme>/NOTES.md` — decisions true for that one skin only: its palette, its skin
   toggle, its wash approach. Never generalise these to another theme.
   只对那一套皮肤成立的决策：调色板、皮肤切换、洗淡方案。绝不要把它们套到别的主题上。

The split matters: a lesson that applies to every skin belongs in `docs/`, a lesson that
applies to one belongs in that theme's `NOTES.md`. Reading the wrong tier is how one
theme's measured numbers get copied into another where they were never measured.
这个分层很重要：适用于所有皮肤的经验放 `docs/`，只适用于一套的放该主题的 `NOTES.md`。
读错层级，就是一套主题的实测数值被抄进另一套从未测过的主题的起因。

## The loop / 工作循环

```powershell
.\themes\<theme>\start.ps1          # apply; re-run after every CSS edit
.\tools\validate-theme.ps1          # official package validator, both themes
node .\tools\cdp-verify.mjs         # live probe + screenshot into tmp/
python .\tools\contrast.py themes\<theme>\theme.json
```

Saving CSS does not mean the running Codex loaded it. Re-run `start.ps1`.
存了 CSS 不等于运行中的 Codex 已经载入。重跑 `start.ps1`。

## Two CSS levels, and why a theme needs both

- `theme.css` is Safe CSS and ships in the three-file package. The validator is strict:
  registered `[data-ds-part]` parts only, no comments, no quotes, no pseudo-elements,
  no named fonts. A rule for an unregistered part is dead code **and fails the whole
  stylesheet** — `brand` is the one that keeps getting reintroduced.
- `runtime.css` is trusted local CSS and carries everything Safe CSS forbids: native
  selectors, pseudo-elements, the injected skin toggle, the wordmark.

`tools/start-theme.ps1` treats `runtime.css` as a hard precondition and throws before it
touches anything. A theme published as the package alone **cannot start on another
machine** — verify by cloning the repo elsewhere and running its `start.ps1`.
只发布包的主题**在别的机器上根本起不来**——把仓库克隆到别处跑一次 `start.ps1` 才算验过。

## Rules that get broken most often / 最常被破坏的规则

- **No screenshot in a theme folder.** Captures go to `tmp/<theme>/`. A theme directory
  holds one skin and nothing else.
  截图一律进 `tmp/<主题>/`，主题目录只装一套皮肤。
- **Rebuild the zip** after any of the three package files changes: `New-DreamThemeZip`
  from `tools/_theme-paths.ps1`. A stale zip is what actually gets applied.
  三个包文件任一变动都要重建 zip；真正被应用的是那个 zip。
- **Validation needs a staging copy**, never the theme folder — the folder always carries
  `assets/`, and the validator rejects any subdirectory. `validate-theme.ps1` handles it.
  校验必须对暂存副本跑，主题目录永远带 `assets/`，校验器拒绝任何子目录。
- **Renaming a package id** silently disables the theme-id-gated rules in
  `video-patch/patched/dream-skin.css`. Grep that file for the old id.
  改包 id 会静默让 `video-patch/patched/dream-skin.css` 里的 id 门控规则失效，记得 grep 旧 id。
- Every document ships a `.zh-CN.md` translation. Run `python scripts\check-translations.py`
  after touching any of them.

## Before saying it works / 说「好了」之前

Claiming a visual result without a live capture is the failure this repository has
repeated most. Read the screenshot back; do not infer the skin from the fact that a
command exited 0.
没有实机截图就宣称视觉效果，是这个仓库重复次数最多的失败。要把截图读回来看，
不要因为命令返回 0 就推断皮肤生效了。

When something new is learned in the process, file it — see the `dream-skin-experience`
skill for which file it belongs in.
过程中学到新东西就记下来——归到哪个文件见 `dream-skin-experience` skill。
