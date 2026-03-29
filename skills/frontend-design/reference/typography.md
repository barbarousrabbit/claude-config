# Typography Reference

## Banned Fonts (NEVER use these)

| Font | Why Banned |
|------|-----------|
| Inter | Overused in AI-generated UIs; signals "no design decision was made" |
| Roboto | Default Android/Material; screams template |
| Arial | System default; zero personality |
| Open Sans | Corporate default; forgettable |
| system-ui | Lazy fallback; no intentional choice |
| Helvetica Neue | Safe default on Mac; feels generic |

## Recommended Alternatives by Tone

### Clean & Professional (replace Inter/Roboto)
- **DM Sans** — Geometric but warmer than Inter, optical sizing
- **Plus Jakarta Sans** — Modern geometric, excellent weight range
- **Outfit** — Clean geometric with personality
- **Satoshi** — Premium feel, great for SaaS
- **General Sans** — Versatile, slightly humanist

### Elegant & Premium
- **Playfair Display** (heading) + **Source Serif 4** (body)
- **Cormorant Garamond** (heading) + **Lora** (body)
- **Fraunces** (heading) — Variable optical size, unique personality

### Technical & Developer
- **Space Grotesk** (heading) + **DM Sans** (body)
- **JetBrains Mono** (code only, never as body)
- **IBM Plex Sans** + **IBM Plex Mono** — Cohesive system

### Warm & Friendly
- **Nunito** — Rounded terminals, approachable
- **Quicksand** — Rounded geometric, playful
- **Lexend** — Designed for readability

### Editorial & Magazine
- **Libre Baskerville** + **Source Sans 3**
- **Newsreader** — Designed specifically for reading
- **Bitter** — Slab serif with character

### Bold & Expressive
- **Space Grotesk** — Unique character shapes
- **Clash Display** — High impact display font
- **Cabinet Grotesk** — Strong personality

## Type Scale

Use a modular scale with fluid sizing via `clamp()`:

```css
--text-xs:   clamp(0.75rem, 0.7rem + 0.25vw, 0.875rem);
--text-sm:   clamp(0.875rem, 0.8rem + 0.35vw, 1rem);
--text-base: clamp(1rem, 0.9rem + 0.5vw, 1.125rem);
--text-lg:   clamp(1.125rem, 1rem + 0.6vw, 1.25rem);
--text-xl:   clamp(1.25rem, 1.1rem + 0.75vw, 1.5rem);
--text-2xl:  clamp(1.5rem, 1.2rem + 1.5vw, 2rem);
--text-3xl:  clamp(1.875rem, 1.5rem + 1.875vw, 2.5rem);
--text-4xl:  clamp(2.25rem, 1.75rem + 2.5vw, 3.5rem);
```

## Font Loading Strategy

Always use `font-display: swap` to prevent FOIT:

```css
@font-face {
  font-family: 'DM Sans';
  font-display: swap;
  /* Use variable font for smaller payload */
  src: url('/fonts/DMSans-Variable.woff2') format('woff2');
}
```

Or via Google Fonts with `&display=swap` parameter.

## Line Height Rules

| Context | Line Height |
|---------|------------|
| Display/Hero headings (>2rem) | 1.1 – 1.2 |
| Section headings (1.5-2rem) | 1.2 – 1.3 |
| Body text | 1.5 – 1.75 |
| UI labels/buttons | 1 – 1.2 |
| Code blocks | 1.5 – 1.6 |

## Letter Spacing

| Context | Tracking |
|---------|---------|
| Large headings | -0.02em to -0.04em (tighter) |
| Small caps / labels | 0.05em to 0.1em (wider) |
| Body text | 0 (default) |
| Buttons | 0.01em to 0.02em |

## Line Length

Optimal: **45–75 characters** per line for body text. Use `max-width: 65ch` on text containers.
