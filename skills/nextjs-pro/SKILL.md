---
name: nextjs-pro
description: Use when building Next.js apps — App Router, Server/Client Components, SSR/SSG, middleware, server actions, or Vercel AI SDK.
user-invocable: true
---

# Next.js Pro

Expert Next.js developer specializing in App Router, React Server Components, and modern full-stack patterns.

## When to Use
- Building or modifying Next.js applications
- App Router setup, routing, layouts, loading/error states
- Server Components vs Client Components decisions
- Data fetching (server actions, route handlers, RSC)
- Middleware, authentication, cookies
- Vercel AI SDK integration
- Performance optimization (ISR, streaming, Suspense)

## Key Principles
1. **Server Components by default** — only add `'use client'` when you need interactivity, hooks, or browser APIs
2. **App Router over Pages Router** — use `app/` directory structure
3. **Server Actions for mutations** — use `'use server'` functions instead of API routes for form handling
4. **Streaming with Suspense** — wrap async components in `<Suspense>` for progressive rendering
5. **Route Groups `(group)`** — organize without affecting URL structure
6. **Parallel Routes `@slot`** — render multiple pages in same layout simultaneously
7. **Intercepting Routes `(..)photo`** — modal patterns without full navigation

## Anti-Patterns to Avoid
- NEVER use `useEffect` for data fetching in Server Components
- NEVER import server-only code in Client Components
- NEVER use `router.push` for server-side redirects — use `redirect()` from `next/navigation`
- NEVER put `'use client'` at layout level — push it down to leaf components
- NEVER use `searchParams` without wrapping in `<Suspense>`

## Reference Files
See companion files in this directory for detailed patterns:
- `nextjs-app-router-fundamentals.md` — Core App Router concepts
- `nextjs-server-client-components.md` — Server vs Client component guide
- `nextjs-advanced-routing.md` — Parallel/intercepting routes
- `nextjs-dynamic-routes-params.md` — Dynamic segments, generateStaticParams
- `nextjs-anti-patterns.md` — Common mistakes to avoid
- `nextjs-client-cookie-pattern.md` — Cookie handling patterns
- `nextjs-server-navigation.md` — Server-side navigation
- `nextjs-use-search-params-suspense.md` — useSearchParams with Suspense
- `nextjs-pathname-id-fetch.md` — Pathname-based data fetching
- `vercel-ai-sdk.md` — AI SDK integration patterns
