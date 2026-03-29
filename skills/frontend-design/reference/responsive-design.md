# Responsive Design Reference

## Breakpoints

```css
/* Mobile-first approach */
--bp-sm:  640px;   /* Large phones */
--bp-md:  768px;   /* Tablets */
--bp-lg:  1024px;  /* Laptops */
--bp-xl:  1280px;  /* Desktops */
--bp-2xl: 1536px;  /* Large screens */
```

Always test at: **375px** (iPhone SE), **768px** (iPad), **1024px** (laptop), **1440px** (desktop).

## Mobile-First CSS

Write base styles for mobile, then layer on complexity:

```css
/* Mobile base */
.grid { display: flex; flex-direction: column; gap: 1rem; }

/* Tablet+ */
@media (min-width: 768px) {
  .grid { flex-direction: row; }
}

/* Desktop+ */
@media (min-width: 1024px) {
  .grid { display: grid; grid-template-columns: repeat(3, 1fr); }
}
```

## Container Queries (Modern Approach)

Component-level responsiveness — better than media queries:

```css
.card-container {
  container-type: inline-size;
  container-name: card;
}

@container card (min-width: 400px) {
  .card { display: grid; grid-template-columns: auto 1fr; }
}

@container card (min-width: 600px) {
  .card { grid-template-columns: 200px 1fr auto; }
}
```

## Fluid Design

Use `clamp()` to avoid breakpoint jumps:

```css
/* Fluid typography */
font-size: clamp(1rem, 0.9rem + 0.5vw, 1.25rem);

/* Fluid spacing */
padding: clamp(1rem, 3vw, 4rem);

/* Fluid max-width */
max-width: clamp(20rem, 80vw, 70rem);
```

## Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Hide critical features on mobile | Adapt the interface — different layout, not less function |
| Use `display: none` on sections | Reorganize content priority |
| Fixed-width elements | Use `min()`, `max()`, `clamp()`, or percentage-based |
| Horizontal scrolling content | Stack vertically or use carousel on mobile |
| Tiny text on mobile (<14px) | Minimum 16px body text on mobile |
| Desktop sidebars on mobile | Convert to bottom nav, hamburger, or tabs |

## Navigation Patterns by Viewport

| Viewport | Pattern |
|----------|---------|
| Mobile (<768px) | Bottom tab bar (≤5 items) or hamburger menu |
| Tablet (768-1024px) | Collapsible sidebar or top nav |
| Desktop (>1024px) | Full sidebar or persistent top nav |

## Images

```html
<!-- Responsive images with art direction -->
<picture>
  <source srcset="hero-desktop.webp" media="(min-width: 1024px)">
  <source srcset="hero-tablet.webp" media="(min-width: 768px)">
  <img src="hero-mobile.webp" alt="Description" loading="lazy">
</picture>

<!-- Density-aware -->
<img srcset="photo-1x.webp 1x, photo-2x.webp 2x"
     src="photo-1x.webp" alt="Description">
```

## Preventing Layout Shift

- Always set `width` and `height` or `aspect-ratio` on images
- Reserve space for async content (skeleton screens)
- Use `min-height` on containers that will receive dynamic content
- Avoid inserting content above existing content
