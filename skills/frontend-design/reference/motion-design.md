# Motion Design Reference

## Timing Guidelines

| Type | Duration | Use For |
|------|----------|---------|
| Micro-interaction | 100–200ms | Button press, toggle, checkbox |
| State change | 200–300ms | Hover effects, tab switch, accordion |
| Enter/exit | 250–400ms | Modal, dropdown, tooltip appear/dismiss |
| Page transition | 300–500ms | Route change, view switch |
| Stagger delay | 50–100ms | Between items in a list animation |

## Easing Functions

### USE these (natural deceleration):
```css
--ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1);
--ease-out-quint: cubic-bezier(0.22, 1, 0.36, 1);
--ease-out-expo:  cubic-bezier(0.16, 1, 0.3, 1);
--ease-in-out:    cubic-bezier(0.65, 0, 0.35, 1);
```

### NEVER use these:
- `bounce` — Dated, tacky, unprofessional
- `elastic` — Cartoon-like, inappropriate for most UIs
- `linear` — Mechanical, unnatural (except for infinite loaders)
- `ease` (CSS default) — Too generic, lacks character

## Performance Rules

**Only animate these properties** (GPU-composited, no layout recalc):
- `transform` (translate, scale, rotate)
- `opacity`
- `filter` (blur, brightness)
- `clip-path`

**NEVER animate** (triggers layout/paint):
- `width`, `height`
- `padding`, `margin`
- `top`, `left`, `right`, `bottom`
- `border-width`
- `font-size`

### Height Animation Workaround
```css
/* Use grid-template-rows instead of height */
.collapsible {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows 300ms var(--ease-out-quart);
}
.collapsible.open {
  grid-template-rows: 1fr;
}
.collapsible > div {
  overflow: hidden;
}
```

## Staggered Entrance Pattern

```css
.list-item {
  opacity: 0;
  transform: translateY(12px);
  animation: fadeInUp 400ms var(--ease-out-quart) forwards;
}

/* Stagger each item by 50-100ms */
.list-item:nth-child(1) { animation-delay: 0ms; }
.list-item:nth-child(2) { animation-delay: 60ms; }
.list-item:nth-child(3) { animation-delay: 120ms; }

@keyframes fadeInUp {
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

## Reduced Motion

Always respect user preference:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

## Scroll-Triggered Animations

Use Intersection Observer for performant scroll animations. Avoid scroll event listeners.

```js
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.1 }
);
```
