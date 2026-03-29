# Skill Chaining Patterns (Reference)

When a task spans multiple phases, chain skills in order. Only load what the current step needs.

## Workflow Chains

### New Feature (full lifecycle)
`brainstorming` → `writing-plans` → `test-driven-development` → `executing-plans` → `code-reviewer`

### Bug Fix
`systematic-debugging` → fix → `code-reviewer`

### Release
`conventional-commits` → `changelog-generator`

## Frontend Chains

### Web UI Page
`ui-ux-pro-max` → `frontend-design` → `critique` → `web-design-guidelines`

### Dashboard / Admin Panel
`ui-ux-pro-max` → `interface-design` → `critique`

### Tailwind Project Setup
`tailwind-theme-builder` → `shadcn-ui`

### React/Next.js App
`ui-ux-pro-max` → `frontend-design` + `senior-frontend` + `frontend-patterns` → `critique`

### React Native / Expo
`vercel-react-native-skills` + `ui-ux-pro-max` → build → test

### WeChat Mini-program
`taro-miniprogram` + `taro-miniprogram-ui` + `typescript-pro` → `test-master`

## Backend Chains

### API Development
`api-designer` → `typescript-pro` → `test-master` → `security-reviewer`

## Prompt Engineering
`prompt-architect` (primary) + `prompt-templates` (Anthropic format) + `prompt-engineering` (advanced patterns)
