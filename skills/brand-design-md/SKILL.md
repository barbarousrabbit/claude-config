---
name: brand-design-md
description: "Use when the user wants a page, component, or UI that looks like a specific real brand or product — e.g. 'make it look like Stripe', 'Notion-style landing page', 'design like Linear', '做个像 Vercel 的页面', '苹果风格', or asks for a named brand's design system, colors, or typography. Provides 73 production-grade brand DESIGN.md files (Apple, Notion, Stripe, Linear, Figma, Vercel, Airbnb, Tesla, Ferrari, Claude, and more) with exact color tokens, type scales, and design analysis to scaffold on-brand UI. Pair with frontend-design for build quality."
---

# Brand Design MD Collection (73 brands)

73 real-world brand design systems, each captured as a `DESIGN.md` with exact
color tokens, type scale, spacing, and a written design analysis. Drop one into a
build and generate UI that matches that brand's visual language — instead of
generic AI defaults.

**Source:** VoltAgent/awesome-design-md (71K★), cloned locally.
**Data path:** `~/.claude/references/awesome-design-md/design-md/<brand>/DESIGN.md`

## When to Use

- User names a brand/product and wants that look: "make it like Stripe", "Notion-style", "像 Linear 一样", "苹果风格的页面"
- User wants a real, coherent design system instead of picking abstract styles
- User asks for a brand's exact colors / fonts / spacing

**When NOT to use:** abstract style exploration with no target brand → use `ui-ux-pro-max`. General UI build with no brand reference → use `frontend-design`.

## Workflow

1. **Match the brand** to one in the list below (fuzzy ok: "the verge" → `theverge`).
2. **Read** `~/.claude/references/awesome-design-md/design-md/<brand>/DESIGN.md` — it has a YAML block of color tokens + type + a prose analysis.
3. **Apply** those exact tokens (colors, fonts, spacing, radii) when building. Substitute Google Fonts if the brand font is proprietary.
4. **Build** with `frontend-design` (or `interface-design` for dashboards) for production quality.
5. If the brand is **not** in the list, tell the user, then either pick the closest sibling (e.g. another fintech for an unlisted bank) or fall back to `ui-ux-pro-max`.

## Available Brands (73)

**AI / dev tools:** `claude` `cohere` `mistral.ai` `minimax` `x.ai` `together.ai` `elevenlabs` `nvidia` `ollama` `cursor` `replicate` `runwayml` `opencode.ai` `warp` `voltagent`

**SaaS / productivity:** `notion` `linear.app` `figma` `framer` `vercel` `supabase` `sanity` `posthog` `raycast` `webflow` `zapier` `miro` `intercom` `mintlify` `resend` `slack` `airtable` `cal` `composio` `superhuman` `lovable` `clay` `hashicorp` `clickhouse` `mongodb` `expo` `sentry`

**Fintech / crypto:** `stripe` `coinbase` `binance` `kraken` `mastercard` `revolut` `wise`

**Big tech / consumer:** `apple` `meta` `ibm` `hp` `dell-1996` `spacex` `tesla` `nike` `uber` `shopify` `spotify` `pinterest` `playstation` `starbucks` `theverge` `wired` `vodafone`

**Automotive:** `bmw` `bmw-m` `bugatti` `ferrari` `lamborghini` `renault`

## DESIGN.md Structure (what you'll read)

```yaml
---
name: <Brand>-design-analysis
description: <prose summary of the brand's voice and layout>
colors:
  primary: "#5645d4"
  on-primary: "#ffffff"
  ...exact hex tokens...
# followed by type scale, spacing, and component notes
---
```

Use the `colors:` tokens verbatim — they are sampled from the real site, not guessed.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Inventing brand colors from memory | Read the DESIGN.md — use its exact hex tokens |
| Using the proprietary brand font directly | Substitute the closest Google Font (DESIGN.md notes the substitute) |
| Skipping the build-quality pass | After applying tokens, run `frontend-design` to avoid AI-slop layout |
| Brand not in list, forcing a wrong match | Say so; pick closest sibling or fall back to `ui-ux-pro-max` |

## Updating the Collection

```bash
cd ~/.claude/references/awesome-design-md && git pull
```
Re-pull to get new brands added upstream. If a brand is missing, it can also be generated from the live site into a new DESIGN.md.

## Related Skills

`frontend-design` (build quality) · `ui-ux-pro-max` (abstract style library) · `interface-design` (dashboards) · `tailwind-theme-builder` (turn tokens into Tailwind theme) · `color-palette` (WCAG check the tokens)
