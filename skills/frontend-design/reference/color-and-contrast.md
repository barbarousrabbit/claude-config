# Color & Contrast Reference

## Banned Color Patterns (AI Slop)

| Pattern | Why Banned |
|---------|-----------|
| Cyan on dark background | Default AI aesthetic from 2024; signals zero design effort |
| Purple-to-blue gradient | Most common AI gradient; immediately recognizable |
| Neon accents on dark | "Cool" without design decisions |
| Gradient text on metrics | Decorative, not meaningful |
| Tailwind default blue (#2563EB) as primary | Too generic; signals no palette was designed |
| Pure black (#000) backgrounds | Harsh; never occurs in nature |
| Pure white (#fff) surfaces | Flat; always tint slightly |

## OKLCH Color System

Use `oklch()` for perceptually uniform colors. Equal steps in lightness *look* equal:

```css
/* Generate a harmonious palette from a single hue */
--brand-50:  oklch(97% 0.02 250);
--brand-100: oklch(93% 0.04 250);
--brand-200: oklch(87% 0.08 250);
--brand-300: oklch(78% 0.12 250);
--brand-400: oklch(68% 0.16 250);
--brand-500: oklch(58% 0.18 250);  /* Primary */
--brand-600: oklch(48% 0.16 250);
--brand-700: oklch(40% 0.14 250);
--brand-800: oklch(32% 0.10 250);
--brand-900: oklch(24% 0.08 250);
```

## Tinted Neutrals

NEVER use pure gray. Always add a subtle color tint:

```css
/* Warm neutrals (for warm brands) */
--neutral-50:  oklch(97% 0.005 60);
--neutral-100: oklch(93% 0.008 60);
--neutral-200: oklch(87% 0.010 60);
--neutral-700: oklch(40% 0.010 60);
--neutral-900: oklch(20% 0.010 60);

/* Cool neutrals (for cool brands) */
--neutral-50:  oklch(97% 0.005 250);
--neutral-100: oklch(93% 0.008 250);
--neutral-900: oklch(20% 0.008 250);
```

## Contrast Requirements (WCAG 2.1)

| Level | Text Size | Minimum Ratio |
|-------|-----------|--------------|
| AA | Normal text (<18px) | 4.5:1 |
| AA | Large text (≥18px bold or ≥24px) | 3:1 |
| AA | UI components & graphical objects | 3:1 |
| AAA | Normal text | 7:1 |
| AAA | Large text | 4.5:1 |

## Color Palette Strategies

### 60-30-10 Rule
- **60%** — Dominant (backgrounds, surfaces)
- **30%** — Secondary (cards, sections, supporting elements)
- **10%** — Accent (CTAs, highlights, active states)

### Semantic Colors
```css
--success: oklch(65% 0.20 145);  /* Green family */
--warning: oklch(75% 0.18 85);   /* Amber family */
--error:   oklch(60% 0.22 25);   /* Red family */
--info:    oklch(65% 0.15 250);  /* Blue family */
```

## Gray on Color — NEVER

Never put gray text on colored backgrounds. It looks washed out. Instead:
- Use a darker shade of the background color
- Or use `color-mix(in oklch, var(--bg-color) 30%, black)`
- Or use semi-transparent dark: `oklch(20% 0 0 / 0.7)`

## Modern CSS Functions

```css
/* Color mixing */
background: color-mix(in oklch, var(--primary) 20%, white);

/* Light/dark mode toggle */
color: light-dark(var(--text-light), var(--text-dark));

/* Relative color syntax */
--hover: oklch(from var(--primary) calc(l - 0.1) c h);
```

## Dark Mode Adjustments

- Reduce saturation slightly for semantic colors (success, error, warning)
- Higher elevation = slightly lighter background (opposite of light mode)
- Use borders more, shadows less (shadows invisible on dark)
- Ensure text contrast is still ≥ 4.5:1
