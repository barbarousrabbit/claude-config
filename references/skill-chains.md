# Skill Chaining Patterns (Reference)

When a task spans multiple phases, chain skills in order. Only load what the current step needs.

## Workflow Chains

### New Feature (full lifecycle)
`brainstorming` → `EnterPlanMode` → `tdd` → implement → `code-reviewer`

### Bug Fix
`diagnosing-bugs` → fix → `code-reviewer`

### Release
`conventional-commits` → `changelog-generator`

## Frontend Chains

### Web UI Page
`ui-ux-pro-max` → `frontend-design` → `critique`

### Dashboard / Admin Panel
`ui-ux-pro-max` → `interface-design` → `critique`

### Tailwind Project Setup
`tailwind-theme-builder` → `shadcn-ui`

### React/Next.js App
`ui-ux-pro-max` → `frontend-design` + `frontend-patterns` → `critique`

### React Native / Expo
`vercel-react-native-skills` + `ui-ux-pro-max` → build → test

## Backend Chains

### API Development
`typescript-pro` (or `python-pro`) → `api-test-suite-builder` → `/security-review`

## Prompt Engineering
`prompt-architect` (sole prompt skill; covers templates and advanced patterns via its references)
