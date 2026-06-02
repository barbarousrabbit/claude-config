---
name: nextjs-pro
description: Use when building Next.js apps — App Router, Server/Client Components, SSR/SSG, proxy (formerly middleware), server actions, 'use cache', or Vercel AI SDK. Covers Next.js 16 with Turbopack, React 19.2, and async request APIs.
user-invocable: true
---

# Next.js Pro (Next.js 16 / React 19.2)

Expert Next.js developer specializing in App Router, React Server Components, and modern full-stack patterns. Updated for **Next.js 16** (2026) with Turbopack as default bundler, `proxy.ts` replacing `middleware.ts`, `'use cache'` directive, `connection()` API, `forbidden()` API, and React 19.2 integration.

## Important: AGENTS.md Docs-Index

Vercel research (2026) shows that an AGENTS.md docs-index achieves **100% accuracy** on Next.js 16 API tasks, compared to **79% for skills**. For version-accurate Next.js guidance, prefer reading the project's AGENTS.md or `.next-docs` index if available. This skill provides patterns and anti-patterns; for exact API signatures, defer to the docs-index or official docs.

## When to Use
- Building or modifying Next.js 16+ applications
- App Router setup, routing, layouts, loading/error states
- Server Components vs Client Components decisions
- Data fetching (server actions, route handlers, RSC)
- Proxy configuration (formerly middleware), authentication, cookies
- `'use cache'` directive for explicit caching
- `connection()` API for opting into dynamic rendering
- `forbidden()` API for 403 authorization errors
- Vercel AI SDK integration
- Performance optimization (ISR, streaming, Suspense, Turbopack)

## Next.js 16 Breaking Changes (Critical)

### 1. `middleware.ts` renamed to `proxy.ts`
- The `middleware` export is deprecated; rename to `proxy`
- File: `middleware.ts` -> `proxy.ts` at project root
- Function: `export function middleware()` -> `export function proxy()`
- Config: `skipMiddlewareUrlNormalize` -> `skipProxyUrlNormalize`
- Runtime: `proxy.ts` runs on Node.js runtime only (not Edge)
- Edge runtime users: keep using `middleware.ts` with Edge runtime
- **No deprecation warning** — old `middleware.ts` silently stops working
- Codemod available: `npx @next/codemod@latest middleware-to-proxy .`

### 2. Synchronous Request APIs Fully Removed
- `cookies()`, `headers()`, `params`, `searchParams`, `draftMode()` — **must be awaited**
- Next.js 15 had backward-compatible sync access; Next.js 16 removes it entirely
- Synchronous access now throws runtime errors

### 3. Turbopack is the Default Bundler
- `next dev` and `next build` use Turbopack by default
- Webpack is still available via `--webpack` flag
- Most webpack plugins need Turbopack equivalents
- Custom webpack config in `next.config.js` requires `--webpack` flag

### 4. `'use cache'` Directive (Stable)
- Mark routes, components, or functions as cacheable
- Replaces implicit caching from Next.js 14
- Cannot use `cookies()`, `headers()`, or read params inside `'use cache'` functions
- Variants: `'use cache'`, `'use cache: private'`, `'use cache: remote'`

### 5. `connection()` API
- Import from `next/server`
- Opt a route into dynamic rendering without using `cookies()` or `headers()`
- Cleaner replacement for `export const dynamic = 'force-dynamic'`

### 6. `forbidden()` API
- Import from `next/navigation`
- Throws a 403 error, rendered by `forbidden.tsx` boundary
- Works like `notFound()` but for authorization errors
- Requires `experimental.authInterrupts` in `next.config.js`

### 7. React 19.2 Integration
- **View Transitions**: animate elements during navigation
- **useEffectEvent**: extract non-reactive logic from Effects
- **Activity**: render background UI while maintaining state
- **React Compiler**: built-in, stable — auto-memoizes components

## Key Principles
1. **Server Components by default** — only add `'use client'` when you need interactivity, hooks, or browser APIs
2. **App Router over Pages Router** — use `app/` directory structure
3. **Server Actions for mutations** — use `'use server'` functions instead of API routes for form handling
4. **Streaming with Suspense** — wrap async components in `<Suspense>` for progressive rendering
5. **Route Groups `(group)`** — organize without affecting URL structure
6. **Parallel Routes `@slot`** — render multiple pages in same layout simultaneously
7. **Intercepting Routes `(..)photo`** — modal patterns without full navigation
8. **All request APIs are async** — always `await` cookies(), headers(), params, searchParams
9. **Use `proxy.ts` not `middleware.ts`** — for request interception and routing logic
10. **Explicit caching with `'use cache'`** — no implicit caching; opt in explicitly

## Anti-Patterns to Avoid
- NEVER use `useEffect` for data fetching in Server Components
- NEVER import server-only code in Client Components
- NEVER use `router.push` for server-side redirects — use `redirect()` from `next/navigation`
- NEVER put `'use client'` at layout level — push it down to leaf components
- NEVER use `searchParams` without wrapping in `<Suspense>`
- NEVER access `cookies()`, `headers()`, `params`, or `searchParams` synchronously — always `await`
- NEVER create new `middleware.ts` files — use `proxy.ts` instead
- NEVER use `export const dynamic = 'force-dynamic'` — use `connection()` API
- NEVER use `cookies()`/`headers()` inside `'use cache'` functions

## Reference Files
See companion files in this directory for detailed patterns:
- `nextjs-app-router-fundamentals.md` — Core App Router concepts (Next.js 16)
- `nextjs-server-client-components.md` — Server vs Client component guide
- `nextjs-advanced-routing.md` — Parallel/intercepting routes, proxy.ts, forbidden()
- `nextjs-dynamic-routes-params.md` — Dynamic segments, generateStaticParams
- `nextjs-anti-patterns.md` — Common mistakes to avoid
- `nextjs-client-cookie-pattern.md` — Cookie handling patterns
- `nextjs-server-navigation.md` — Server-side navigation
- `nextjs-use-search-params-suspense.md` — useSearchParams with Suspense
- `nextjs-pathname-id-fetch.md` — Pathname-based data fetching
- `vercel-ai-sdk.md` — AI SDK integration patterns
