# Interaction Design Reference

## Interactive States (REQUIRED for every clickable element)

| State | Visual Treatment |
|-------|-----------------|
| Default | Base styling |
| Hover | Subtle color shift, slight elevation, or background change |
| Focus | Visible focus ring (2px+ outline, offset, brand color) |
| Active/Pressed | Slight scale-down or color darken |
| Disabled | Reduced opacity (0.5), `cursor: not-allowed`, no hover effects |
| Loading | Spinner or skeleton, disable interaction |

## Focus Indicators

NEVER remove focus outlines without replacement:

```css
/* Custom focus ring */
:focus-visible {
  outline: 2px solid var(--brand-500);
  outline-offset: 2px;
  border-radius: inherit;
}

/* Remove default for mouse users only */
:focus:not(:focus-visible) {
  outline: none;
}
```

## Cursor Rules

| Element | Cursor |
|---------|--------|
| Buttons, links, clickable cards | `cursor: pointer` |
| Text inputs | `cursor: text` |
| Disabled elements | `cursor: not-allowed` |
| Draggable | `cursor: grab` / `cursor: grabbing` |
| Resize handles | `cursor: ew-resize` etc. |

## Form Patterns

### Validation Timing
- Validate on **blur** (not on every keystroke)
- Show errors **after first submit attempt**, then validate on change
- Clear errors as soon as input becomes valid

### Input Styling
```css
.input {
  /* Slightly inset — darker than surroundings */
  background: oklch(from var(--surface) calc(l - 0.03) c h);
  border: 1px solid oklch(from var(--border) l c h / 0.5);
  transition: border-color 150ms, box-shadow 150ms;
}
.input:focus {
  border-color: var(--brand-500);
  box-shadow: 0 0 0 3px oklch(from var(--brand-500) l c h / 0.15);
}
.input:invalid:not(:placeholder-shown) {
  border-color: var(--error);
}
```

### Labels
- Every input MUST have a visible `<label>` with `for` attribute
- Don't use placeholder as label substitute
- Required fields: use `*` after label text or "(required)" for accessibility

## Loading Patterns

### Skeleton Screens (preferred)
```css
.skeleton {
  background: linear-gradient(
    90deg,
    oklch(90% 0 0) 25%,
    oklch(95% 0 0) 50%,
    oklch(90% 0 0) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 4px;
}
@keyframes shimmer {
  to { background-position: -200% 0; }
}
```

### Button Loading
- Replace button text with spinner
- Keep button width constant (prevent layout shift)
- Disable click during loading

## Optimistic UI

Update the UI **immediately** on user action, sync with server in background:

1. User clicks "Like" → Heart fills instantly
2. API call fires in background
3. If fails → revert UI + show toast error

## Progressive Disclosure

- Start simple, reveal complexity through interaction
- Basic options first, advanced behind expandable sections
- Hover states that reveal secondary actions
- "Show more" / "Advanced options" patterns

## Empty States

Empty states should **teach the interface**, not just say "nothing here":
- Explain what will appear here
- Provide a clear CTA to get started
- Use illustration or icon for visual interest
- Never leave a blank white space

## Error States

- Use inline errors near the problem (not toasts for form errors)
- Say what went wrong AND how to fix it
- Use color + icon (not color alone) for accessibility
- Don't blame the user ("Invalid email" → "Please enter a valid email address")

## Touch Targets

- Minimum 44×44px on touch devices
- Add padding if the visual element is smaller
- Space touch targets at least 8px apart
