# Spatial Design Reference

## Spacing Scale

Use a consistent base unit (4px or 8px) with deliberate multipliers:

```css
--space-1:  0.25rem;  /* 4px  — icon gaps */
--space-2:  0.5rem;   /* 8px  — tight groups */
--space-3:  0.75rem;  /* 12px — inline elements */
--space-4:  1rem;     /* 16px — component padding */
--space-5:  1.25rem;  /* 20px */
--space-6:  1.5rem;   /* 24px — card padding */
--space-8:  2rem;     /* 32px — section gaps */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px — major sections */
--space-16: 4rem;     /* 64px */
--space-20: 5rem;     /* 80px — page sections */
--space-24: 6rem;     /* 96px */
--space-32: 8rem;     /* 128px — hero spacing */
```

## Visual Rhythm

Create rhythm through **varied** spacing — not the same padding everywhere:

- **Tight groupings** (space-2 to space-4) for related items
- **Medium gaps** (space-6 to space-8) between components
- **Generous separations** (space-12 to space-20) between sections
- **Dramatic gaps** (space-24 to space-32) for hero/CTA areas

The contrast between tight and loose creates rhythm. Without it, layouts feel monotonous.

## Fluid Spacing

Use `clamp()` for spacing that adapts to viewport:

```css
--section-gap: clamp(2rem, 4vw, 6rem);
--page-padding: clamp(1rem, 3vw, 4rem);
--card-padding: clamp(1rem, 2vw, 2rem);
```

## Grid Systems

### CSS Grid Patterns
```css
/* Auto-fit responsive grid (no media queries) */
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(300px, 100%), 1fr));
  gap: var(--space-6);
}

/* Asymmetric layout */
.layout {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: var(--space-8);
}
```

### Container Queries
```css
@container (min-width: 400px) {
  .card { grid-template-columns: auto 1fr; }
}
```

## Layout Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Same padding everywhere | Vary spacing to create rhythm |
| Everything centered | Left-align text, use asymmetric layouts |
| Cards inside cards | Flatten hierarchy, use spacing |
| Identical card grids (icon + heading + text ×6) | Vary card layouts, use different compositions |
| Hero metric layout (big number + small label) | Design metrics for their specific context |
| Fixed-width containers at all breakpoints | Use fluid widths with max-width caps |

## Breaking the Grid

Intentionally break grid alignment for emphasis:
- Full-bleed images or sections
- Overlapping elements with negative margins
- Pull-quotes that extend into margins
- Hero elements that span multiple columns
