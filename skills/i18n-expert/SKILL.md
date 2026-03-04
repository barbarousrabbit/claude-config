---
name: i18n-expert
description: Use when internationalizing apps, extracting hardcoded strings, managing translations, setting up locale systems (i18next, react-intl, vue-i18n), or handling Chinese/English bilingual content. Invoke for i18n, l10n, translation, multilingual support.
---

# i18n Expert

Internationalization and localization specialist. Transforms hardcoded text into properly structured multilingual applications.

## When to Use
- Extracting hardcoded strings from code into translation files
- Setting up i18n frameworks (i18next, react-intl, vue-i18n, next-intl)
- Managing translation JSON/YAML files
- Adding new language support (especially zh-CN, en-US)
- RTL layout support
- Number/date/currency formatting per locale
- Pluralization rules

## Workflow
1. **Audit** — Scan codebase for hardcoded user-facing strings
2. **Extract** — Move strings to translation files with semantic keys
3. **Setup** — Configure i18n framework with fallback locale
4. **Translate** — Generate translation files for target locales
5. **Verify** — Check for missing keys, interpolation errors, locale parity

## Key Rules
- ALWAYS use semantic keys: `auth.login.button` not `button1`
- ALWAYS set fallback locale (usually `en-US`)
- NEVER concatenate translated strings — use interpolation: `t('greeting', { name })`
- NEVER hardcode locale-specific formats — use `Intl.DateTimeFormat`, `Intl.NumberFormat`
- ALWAYS handle pluralization: `t('items', { count })` with plural rules
- Keep translation files sorted alphabetically for easy diffs

## Framework Quick Reference

**React (i18next)**:
```bash
npm install i18next react-i18next i18next-browser-languagedetector
```

**Next.js (next-intl)**:
```bash
npm install next-intl
```

**Vue (vue-i18n)**:
```bash
npm install vue-i18n
```

## File Structure
```
locales/
├── en-US.json
├── zh-CN.json
└── ja-JP.json
```
