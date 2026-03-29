# UX Writing Reference

## Core Principle

Every word must earn its place. If removing a word doesn't change the meaning, remove it.

## Button Labels

| Bad | Good | Why |
|-----|------|-----|
| Submit | Save Changes | Specific about what happens |
| Click Here | View Report | Describes the destination |
| OK | Confirm Delete | States the action clearly |
| Cancel | Discard Changes | Tells user what they'll lose |

## Error Messages

### Formula: What happened + How to fix it

| Bad | Good |
|-----|------|
| "Error" | "Couldn't save — check your internet connection and try again" |
| "Invalid input" | "Email must include @ and a domain (e.g., name@example.com)" |
| "403 Forbidden" | "You don't have permission to view this page. Contact your admin." |
| "Something went wrong" | "We couldn't load your data. Refresh the page or try again in a minute." |

Never blame the user. Never show raw error codes to end users.

## Empty States

### Formula: What this is + Why it's empty + How to fill it

```
No projects yet

Create your first project to start tracking tasks
and collaborating with your team.

[+ Create Project]
```

NOT: "No data to display"

## Confirmation Dialogs

### Formula: Consequence + Specific action

```
Delete "Q4 Report"?

This will permanently remove the file and all 3 comments.
This can't be undone.

[Cancel]  [Delete File]
```

NOT: "Are you sure?"

## Loading States

| Duration | Show |
|----------|------|
| < 300ms | Nothing (avoid flash) |
| 300ms – 2s | Spinner or skeleton |
| 2s – 10s | Progress indicator with message |
| > 10s | Progress bar + time estimate + cancel option |

## Success Messages

- Brief and specific: "Project created" not "Operation completed successfully"
- Auto-dismiss after 3-5 seconds
- Include next action when relevant: "Saved. [View changes]"

## Microcopy Rules

1. **Sentence case** — not Title Case (except proper nouns)
2. **No periods** on single-sentence labels, tooltips, placeholders
3. **Active voice** — "Save changes" not "Changes will be saved"
4. **Present tense** — "File uploads" not "File will be uploaded"
5. **No jargon** — "Sign in" not "Authenticate"
6. **Consistent terminology** — pick one term and use it everywhere (don't mix "delete/remove/trash")

## Tooltip Guidelines

- Only add when label isn't self-explanatory
- Max 1-2 short sentences
- Don't repeat information already visible
- Show on hover after 300ms delay, dismiss on mouse leave
- Position: prefer top, fall back to bottom/left/right if clipped

## Placeholder Text

- Use as **hints**, not labels: "Search by name or email..."
- Never use as the only label (disappears on input)
- Use lighter color than real text input
- Keep short — truncation in small inputs

## Numbers & Data

- Use locale-appropriate formatting: 1,000 not 1000
- Abbreviate large numbers: 1.2K, 3.5M
- Show units: "5 min ago" not "5m"
- Relative time for recent (<24h), absolute for older
