# UI Design Protocol — Detailed Steps (Reference)

Extracted from CLAUDE.md to keep the always-loaded rules file lean. The trigger condition and CEO-Mode relationship stay in CLAUDE.md; this file holds the detailed 3-step chain + pre-delivery checklist. Load this when a task produces new pages/components or changes 3+ visual properties.

### Step 1: Design System (`ui-ux-pro-max`) — BEFORE writing any UI code
```bash
python3 ~/.claude/skills/ui-ux-pro-max/scripts/search.py "<product> <industry> <keywords>" --design-system -p "Project"
```
- Generates: style direction, color palette, font pairing, effects, anti-patterns
- **CRITICAL**: If the script outputs a banned font (Inter, Roboto, Open Sans, Arial, system-ui), **override it immediately** — pick from `frontend-design/reference/typography.md`
- If the script fails or user is in a hurry, at minimum manually decide: palette (3-5 colors with hex), font pair, and overall tone (e.g. "warm minimal", "dark editorial")
- NEVER skip this step — a page without a design system is a page that looks like AI slop

### Step 2: Build (`frontend-design` / `interface-design`) — with the design system in hand
- Apply the chosen palette, fonts, and style from Step 1
- **Read the reference files** in `frontend-design/reference/` for detailed guidance:
  - `typography.md` — banned fonts list + recommended alternatives by tone
  - `color-and-contrast.md` — OKLCH system, tinted neutrals, banned color patterns
  - `spatial-design.md` — spacing scale, visual rhythm, grid systems
  - `motion-design.md` — timing, easing functions, performance rules
  - `interaction-design.md` — states, focus indicators, form patterns
  - `responsive-design.md` — breakpoints, container queries, fluid design
  - `ux-writing.md` — button labels, error messages, empty states
- Follow all DON'T rules in `frontend-design` (no Inter/Roboto, no pure black/white, no emoji icons, no card-in-card, no center-everything)
- Use `interface-design` for dashboards/admin panels, `frontend-design` for everything else

### Step 3: Self-Review (`critique`) — BEFORE delivering to user
- Review the output against `frontend-design` anti-patterns (The AI Slop Test)
- Check: color contrast ≥ 4.5:1, no layout shift on hover, consistent spacing rhythm, responsive at 375/768/1024px
- **Verify against Step 1**: Does the final output actually use the design system from Step 1? Or did defaults creep in?
- If anything fails, fix it before showing to user
- For thorough review, also invoke `web-design-guidelines`

### Quick Checklist (verify before delivery)
- [ ] Design system generated (not random defaults)
- [ ] No banned fonts (Inter, Roboto, Open Sans, system-ui)
- [ ] No AI palette (cyan-on-dark, purple-blue gradient, neon, Tailwind #2563EB)
- [ ] Tinted neutrals (no pure gray/black/white)
- [ ] No identical card grids or center-everything layout
- [ ] No emoji icons — use Lucide/Heroicons SVGs
- [ ] Text contrast ≥ 4.5:1, hover no layout shift, `cursor-pointer` on clickables
- [ ] Consistent spacing scale, ease-out-quart/quint/expo animations
- [ ] Interactive states (focus, active, disabled) styled
- [ ] Responsive at 375/768/1024/1440px, mobile-first
- [ ] Microcopy clear and actionable
