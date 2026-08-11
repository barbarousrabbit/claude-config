---
name: dark-mode-no-brown
description: GLOBAL UI rule — dark mode must never use brown/khaki-leaning ("poop") colors; neutral charcoal is the safe zone
metadata:
  type: feedback
---

Dark-mode palettes must never read as brown. The user's words (2026-08-11,
power-monitor dashboard): "暗色永远不用贴近屎一样的颜色，这是UI的全局规定，
而不是项目规定" — explicitly a GLOBAL rule for all projects, not a
project preference.

**Why:** a "warm dark" theme drifts into poop-brown territory through
mid-lightness warm neutrals, not through the near-black base. The danger
zone is L 30–75% + hue ~25–50° (HSL) + visible saturation — text ramps
and raised surfaces live exactly there. The near-black background can
look fine while the ink scale reads as khaki.

**How to apply:**
- Dark neutrals may keep a warm tint only while it is invisible as brown:
  OKLCH chroma ≤ ~0.01, or in sRGB keep the R−B spread ≤ ~8 (of 255) per
  color. Example fix: ink-3 #a89b8c (R−B=28, khaki) → #a19e99 (R−B=8,
  neutral warm).
- The banned-pattern table in
  `frontend-design/reference/color-and-contrast.md` owns this rule for
  UI work; the pre-delivery checklist in `references/ui-design-protocol.md`
  references it.
- Blue-slate OLED dark (#131820-family) is ALSO banned (separate rule,
  same user, same day) — the safe zone between the two is neutral
  charcoal. Accent/data colors (saturated orange, green) are exempt;
  the rule targets surfaces and neutral ramps.
- Related earlier lesson: ask which aspect is ugly before banning a whole
  category — this time the user named the aspect (brown-leaning hue)
  themselves.
