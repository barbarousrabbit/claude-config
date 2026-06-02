---
name: frontend-patterns
description: Use when implementing React/Next.js patterns — hooks, Zustand, React Query, data fetching, composition, Server Components, Server Actions, React 19 APIs.
user-invocable: true
origin: ECC
---

# Frontend Development Patterns

Modern frontend patterns for React 19, Next.js, and performant user interfaces.

## When to Activate

- Building React components (composition, props, rendering)
- Using React 19 APIs (use, useActionState, useOptimistic, useFormStatus, Server Components, Server Actions)
- Managing state (useState, useReducer, Zustand, Context)
- Implementing data fetching (TanStack Query, server components, use() hook)
- Optimizing performance (React Compiler, virtualization, code splitting)
- Working with forms (useActionState, validation, Zod schemas)
- Handling client-side routing and navigation
- Building accessible, responsive UI patterns

## React 19 New Hooks

### use() — Read Resources in Render

`use()` reads promises and context directly during render. Unlike other hooks, it can be called inside conditionals and loops.

```typescript
import { use, Suspense } from 'react'

// ✅ Read a promise during render (replaces many useEffect data-fetching patterns)
function MarketDetails({ marketPromise }: { marketPromise: Promise<Market> }) {
  const market = use(marketPromise)

  return (
    <div>
      <h2>{market.name}</h2>
      <p>{market.description}</p>
    </div>
  )
}

// Usage — lift the promise above the Suspense boundary
function MarketPage({ id }: { id: string }) {
  const marketPromise = fetchMarket(id) // starts fetching immediately
  return (
    <Suspense fallback={<MarketSkeleton />}>
      <MarketDetails marketPromise={marketPromise} />
    </Suspense>
  )
}

// ✅ Read context conditionally (impossible with useContext)
function ThemeIcon({ showIcon }: { showIcon: boolean }) {
  if (!showIcon) return null
  const theme = use(ThemeContext) // legal — use() works inside conditionals
  return <Icon name={theme === 'dark' ? 'moon' : 'sun'} />
}
```

### useActionState — Form Actions with State

Replaces the old `useFormState` from `react-dom`. Manages form submission state including pending status.

```typescript
import { useActionState } from 'react'

interface FormState {
  error: string | null
  success: boolean
}

async function createMarketAction(
  prevState: FormState,
  formData: FormData
): Promise<FormState> {
  const name = formData.get('name') as string
  if (!name.trim()) {
    return { error: 'Name is required', success: false }
  }

  try {
    await createMarket({ name, description: formData.get('description') as string })
    return { error: null, success: true }
  } catch (e) {
    return { error: (e as Error).message, success: false }
  }
}

export function CreateMarketForm() {
  const [state, formAction, isPending] = useActionState(createMarketAction, {
    error: null,
    success: false,
  })

  return (
    <form action={formAction}>
      <input name="name" placeholder="Market name" disabled={isPending} />
      <textarea name="description" placeholder="Description" disabled={isPending} />

      {state.error && <p className="error">{state.error}</p>}
      {state.success && <p className="success">Market created!</p>}

      <SubmitButton />
    </form>
  )
}
```

### useFormStatus — Pending State in Nested Components

Must be called from a component rendered inside a `<form>`. Gives the pending state of the parent form.

```typescript
import { useFormStatus } from 'react-dom'

function SubmitButton() {
  const { pending } = useFormStatus()

  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  )
}

// ✅ Use inside any form — it reads the nearest parent <form>'s status
// ❌ Does NOT work if called in the same component that renders the <form>
```

### useOptimistic — Instant UI Updates

Show an optimistic value while an async action is in progress, then revert on failure.

```typescript
import { useOptimistic } from 'react'

interface Comment {
  id: string
  text: string
  sending?: boolean
}

export function CommentThread({
  comments,
  addComment,
}: {
  comments: Comment[]
  addComment: (text: string) => Promise<void>
}) {
  const [optimisticComments, addOptimistic] = useOptimistic(
    comments,
    (current: Comment[], newText: string) => [
      ...current,
      { id: `temp-${Date.now()}`, text: newText, sending: true },
    ]
  )

  async function handleSubmit(formData: FormData) {
    const text = formData.get('text') as string
    addOptimistic(text)
    await addComment(text)
  }

  return (
    <div>
      {optimisticComments.map(comment => (
        <div key={comment.id} style={{ opacity: comment.sending ? 0.6 : 1 }}>
          {comment.text}
        </div>
      ))}
      <form action={handleSubmit}>
        <input name="text" placeholder="Add a comment..." />
        <SubmitButton />
      </form>
    </div>
  )
}
```

## Server Components & Server Actions (React 19 + Next.js)

### Server Components — Default in App Router

Server Components run on the server, have zero client JS bundle cost, and can directly access databases, file systems, and secrets.

```typescript
// app/markets/page.tsx — Server Component by default (no 'use client')
import { db } from '@/lib/db'

export default async function MarketsPage() {
  const markets = await db.market.findMany({
    orderBy: { createdAt: 'desc' },
  })

  return (
    <div>
      <h1>Markets</h1>
      {/* Client component receives serializable props */}
      <MarketFilters />
      <MarketList markets={markets} />
    </div>
  )
}
```

**When to add `'use client'`**: Only when the component uses browser APIs, event handlers, useState, useEffect, useRef with DOM, or other client-only hooks. Keep client boundaries as low in the tree as possible.

```typescript
'use client'
// components/market-filters.tsx — needs useState for interactive filtering
import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'

export function MarketFilters() {
  const [search, setSearch] = useState('')
  const [isPending, startTransition] = useTransition()
  const router = useRouter()

  function handleSearch(value: string) {
    setSearch(value)
    startTransition(() => {
      router.push(`/markets?q=${encodeURIComponent(value)}`)
    })
  }

  return (
    <input
      value={search}
      onChange={e => handleSearch(e.target.value)}
      placeholder="Search markets..."
      className={isPending ? 'opacity-50' : ''}
    />
  )
}
```

### Server Actions — Mutations Without API Routes

```typescript
// app/actions/market.ts
'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { z } from 'zod'

const CreateMarketSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().min(1),
  endDate: z.string().datetime(),
})

export async function createMarket(formData: FormData) {
  const parsed = CreateMarketSchema.safeParse({
    name: formData.get('name'),
    description: formData.get('description'),
    endDate: formData.get('endDate'),
  })

  if (!parsed.success) {
    return { error: parsed.error.flatten().fieldErrors }
  }

  await db.market.create({ data: parsed.data })
  revalidatePath('/markets')
  redirect('/markets')
}

// Can also be called directly (not only from forms)
export async function deleteMarket(id: string) {
  await db.market.delete({ where: { id } })
  revalidatePath('/markets')
}
```

## Component Patterns

### Composition Over Inheritance

```typescript
// ✅ GOOD: Component composition
interface CardProps {
  children: React.ReactNode
  variant?: 'default' | 'outlined'
}

export function Card({ children, variant = 'default' }: CardProps) {
  return <div className={`card card-${variant}`}>{children}</div>
}

export function CardHeader({ children }: { children: React.ReactNode }) {
  return <div className="card-header">{children}</div>
}

export function CardBody({ children }: { children: React.ReactNode }) {
  return <div className="card-body">{children}</div>
}

// Usage
<Card>
  <CardHeader>Title</CardHeader>
  <CardBody>Content</CardBody>
</Card>
```

### Compound Components

```typescript
interface TabsContextValue {
  activeTab: string
  setActiveTab: (tab: string) => void
}

const TabsContext = createContext<TabsContextValue | undefined>(undefined)

export function Tabs({ children, defaultTab }: {
  children: React.ReactNode
  defaultTab: string
}) {
  const [activeTab, setActiveTab] = useState(defaultTab)

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      {children}
    </TabsContext.Provider>
  )
}

export function TabList({ children }: { children: React.ReactNode }) {
  return <div className="tab-list">{children}</div>
}

export function Tab({ id, children }: { id: string, children: React.ReactNode }) {
  const context = useContext(TabsContext)
  if (!context) throw new Error('Tab must be used within Tabs')

  return (
    <button
      className={context.activeTab === id ? 'active' : ''}
      onClick={() => context.setActiveTab(id)}
    >
      {children}
    </button>
  )
}

// Usage
<Tabs defaultTab="overview">
  <TabList>
    <Tab id="overview">Overview</Tab>
    <Tab id="details">Details</Tab>
  </TabList>
</Tabs>
```

## Custom Hooks Patterns

### State Management Hook

```typescript
export function useToggle(initialValue = false): [boolean, () => void] {
  const [value, setValue] = useState(initialValue)
  const toggle = useCallback(() => setValue(v => !v), [])
  return [value, toggle]
}

// Usage
const [isOpen, toggleOpen] = useToggle()
```

### Debounce Hook

```typescript
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => clearTimeout(handler)
  }, [value, delay])

  return debouncedValue
}

// Usage
const [searchQuery, setSearchQuery] = useState('')
const debouncedQuery = useDebounce(searchQuery, 500)

useEffect(() => {
  if (debouncedQuery) {
    performSearch(debouncedQuery)
  }
}, [debouncedQuery])
```

## Data Fetching with TanStack Query v5

Prefer TanStack Query (React Query) over hand-rolled useQuery hooks for production apps. It handles caching, deduplication, background refetching, pagination, and error retry out of the box.

### Setup

```typescript
// providers.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000, // 1 minute
            retry: 2,
          },
        },
      })
  )

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}
```

### Queries

```typescript
import { useQuery, useSuspenseQuery } from '@tanstack/react-query'

// ✅ Standard query
function useMarkets(category?: string) {
  return useQuery({
    queryKey: ['markets', { category }],
    queryFn: async () => {
      const params = category ? `?category=${category}` : ''
      const res = await fetch(`/api/markets${params}`)
      if (!res.ok) throw new Error('Failed to fetch markets')
      return res.json() as Promise<Market[]>
    },
    staleTime: 5 * 60 * 1000, // 5 minutes
  })
}

// ✅ Suspense query — use with <Suspense> boundary, data is always defined
function useMarketSuspense(id: string) {
  return useSuspenseQuery({
    queryKey: ['market', id],
    queryFn: () => fetchMarket(id),
  })
}

// ✅ Dependent query — only runs when userId is available
function useUserMarkets(userId: string | undefined) {
  return useQuery({
    queryKey: ['markets', 'user', userId],
    queryFn: () => fetchUserMarkets(userId!),
    enabled: !!userId,
  })
}
```

### Mutations

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query'

function useCreateMarket() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async (data: CreateMarketInput) => {
      const res = await fetch('/api/markets', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      })
      if (!res.ok) throw new Error('Failed to create market')
      return res.json() as Promise<Market>
    },
    onSuccess: () => {
      // Invalidate and refetch the markets list
      queryClient.invalidateQueries({ queryKey: ['markets'] })
    },
  })
}

// Usage
function CreateMarketButton() {
  const { mutate, isPending, error } = useCreateMarket()

  return (
    <button onClick={() => mutate({ name: 'New Market' })} disabled={isPending}>
      {isPending ? 'Creating...' : 'Create Market'}
    </button>
  )
}
```

### Optimistic Updates with TanStack Query

```typescript
function useToggleLike(marketId: string) {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: () => toggleLikeAPI(marketId),
    onMutate: async () => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['market', marketId] })

      // Snapshot previous value
      const previous = queryClient.getQueryData<Market>(['market', marketId])

      // Optimistically update
      queryClient.setQueryData<Market>(['market', marketId], old =>
        old ? { ...old, liked: !old.liked, likes: old.liked ? old.likes - 1 : old.likes + 1 } : old
      )

      return { previous }
    },
    onError: (_err, _vars, context) => {
      // Rollback on error
      if (context?.previous) {
        queryClient.setQueryData(['market', marketId], context.previous)
      }
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['market', marketId] })
    },
  })
}
```

## State Management with Zustand

Zustand is the recommended lightweight state manager for client-side state that does not belong in server state (React Query) or URL state.

### Basic Store

```typescript
import { create } from 'zustand'

interface MarketStore {
  selectedMarketId: string | null
  filters: { category: string; sortBy: 'newest' | 'popular' }
  selectMarket: (id: string | null) => void
  setFilter: <K extends keyof MarketStore['filters']>(
    key: K,
    value: MarketStore['filters'][K]
  ) => void
  resetFilters: () => void
}

const DEFAULT_FILTERS = { category: 'all', sortBy: 'newest' as const }

export const useMarketStore = create<MarketStore>((set) => ({
  selectedMarketId: null,
  filters: { ...DEFAULT_FILTERS },
  selectMarket: (id) => set({ selectedMarketId: id }),
  setFilter: (key, value) =>
    set((state) => ({
      filters: { ...state.filters, [key]: value },
    })),
  resetFilters: () => set({ filters: { ...DEFAULT_FILTERS } }),
}))
```

### Selectors — Prevent Unnecessary Re-renders

```typescript
// ✅ Select only what you need — component re-renders only when this slice changes
function MarketSidebar() {
  const selectedId = useMarketStore((s) => s.selectedMarketId)
  const selectMarket = useMarketStore((s) => s.selectMarket)

  return <Sidebar selectedId={selectedId} onSelect={selectMarket} />
}

// ✅ Derived selector with shallow equality (for objects/arrays)
import { useShallow } from 'zustand/react/shallow'

function FilterBar() {
  const filters = useMarketStore(useShallow((s) => s.filters))
  const setFilter = useMarketStore((s) => s.setFilter)

  return <Filters values={filters} onChange={setFilter} />
}
```

### Zustand with Persist Middleware

```typescript
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface SettingsStore {
  theme: 'light' | 'dark' | 'system'
  sidebarOpen: boolean
  setTheme: (theme: SettingsStore['theme']) => void
  toggleSidebar: () => void
}

export const useSettingsStore = create<SettingsStore>()(
  persist(
    (set) => ({
      theme: 'system',
      sidebarOpen: true,
      setTheme: (theme) => set({ theme }),
      toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
    }),
    {
      name: 'app-settings', // localStorage key
    }
  )
)
```

## Performance Optimization

### React Compiler (React Forget)

React Compiler (available in React 19) auto-memoizes components and hooks at build time. When enabled, **manual `useMemo`, `useCallback`, and `React.memo` are largely unnecessary** — the compiler infers optimal memoization.

```typescript
// ✅ With React Compiler enabled — write plain code, compiler handles memoization
function MarketList({ markets, sortBy }: { markets: Market[]; sortBy: string }) {
  // No need for useMemo — compiler detects this depends only on `markets` and `sortBy`
  const sorted = markets.toSorted((a, b) =>
    sortBy === 'volume' ? b.volume - a.volume : a.name.localeCompare(b.name)
  )

  // No need for useCallback — compiler memoizes automatically
  const handleClick = (id: string) => {
    console.log('Selected', id)
  }

  return sorted.map(m => (
    <MarketCard key={m.id} market={m} onClick={() => handleClick(m.id)} />
  ))
}

// ❌ STILL use useMemo/useCallback when React Compiler is NOT enabled in the project
// Check: look for 'babel-plugin-react-compiler' or 'react-compiler' in build config
```

**When you still need manual memoization** (even with Compiler):
- Very expensive computations (>10ms) that benefit from explicit dependency tracking
- Third-party libraries that expect stable references
- `useRef`-based patterns the compiler cannot analyze

### Code Splitting & Lazy Loading

```typescript
import { lazy, Suspense } from 'react'

// ✅ Lazy load heavy components
const HeavyChart = lazy(() => import('./HeavyChart'))
const ThreeJsBackground = lazy(() => import('./ThreeJsBackground'))

export function Dashboard() {
  return (
    <div>
      <Suspense fallback={<ChartSkeleton />}>
        <HeavyChart data={data} />
      </Suspense>

      <Suspense fallback={null}>
        <ThreeJsBackground />
      </Suspense>
    </div>
  )
}
```

### Virtualization for Long Lists

```typescript
import { useVirtualizer } from '@tanstack/react-virtual'

export function VirtualMarketList({ markets }: { markets: Market[] }) {
  const parentRef = useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: markets.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 100,  // Estimated row height
    overscan: 5  // Extra items to render
  })

  return (
    <div ref={parentRef} style={{ height: '600px', overflow: 'auto' }}>
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          position: 'relative'
        }}
      >
        {virtualizer.getVirtualItems().map(virtualRow => (
          <div
            key={virtualRow.index}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualRow.size}px`,
              transform: `translateY(${virtualRow.start}px)`
            }}
          >
            <MarketCard market={markets[virtualRow.index]} />
          </div>
        ))}
      </div>
    </div>
  )
}
```

## Context + Reducer Pattern

```typescript
interface State {
  markets: Market[]
  selectedMarket: Market | null
  loading: boolean
}

type Action =
  | { type: 'SET_MARKETS'; payload: Market[] }
  | { type: 'SELECT_MARKET'; payload: Market }
  | { type: 'SET_LOADING'; payload: boolean }

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'SET_MARKETS':
      return { ...state, markets: action.payload }
    case 'SELECT_MARKET':
      return { ...state, selectedMarket: action.payload }
    case 'SET_LOADING':
      return { ...state, loading: action.payload }
    default:
      return state
  }
}

const MarketContext = createContext<{
  state: State
  dispatch: Dispatch<Action>
} | undefined>(undefined)

export function MarketProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(reducer, {
    markets: [],
    selectedMarket: null,
    loading: false
  })

  return (
    <MarketContext.Provider value={{ state, dispatch }}>
      {children}
    </MarketContext.Provider>
  )
}

export function useMarkets() {
  const context = useContext(MarketContext)
  if (!context) throw new Error('useMarkets must be used within MarketProvider')
  return context
}
```

## Form Handling with useActionState

For new forms, prefer `useActionState` + `useFormStatus` (shown in React 19 section above) over manual `useState` + `onSubmit`. For complex multi-step forms or forms needing field-level validation as you type, combine with a form library (React Hook Form, Conform).

### Controlled Form (Legacy Pattern — Still Valid)

```typescript
interface FormData {
  name: string
  description: string
  endDate: string
}

interface FormErrors {
  name?: string
  description?: string
  endDate?: string
}

export function CreateMarketForm() {
  const [formData, setFormData] = useState<FormData>({
    name: '',
    description: '',
    endDate: ''
  })

  const [errors, setErrors] = useState<FormErrors>({})

  const validate = (): boolean => {
    const newErrors: FormErrors = {}

    if (!formData.name.trim()) {
      newErrors.name = 'Name is required'
    } else if (formData.name.length > 200) {
      newErrors.name = 'Name must be under 200 characters'
    }

    if (!formData.description.trim()) {
      newErrors.description = 'Description is required'
    }

    if (!formData.endDate) {
      newErrors.endDate = 'End date is required'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!validate()) return

    try {
      await createMarket(formData)
    } catch (error) {
      // Error handling
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={formData.name}
        onChange={e => setFormData(prev => ({ ...prev, name: e.target.value }))}
        placeholder="Market name"
      />
      {errors.name && <span className="error">{errors.name}</span>}
      {/* Other fields */}
      <button type="submit">Create Market</button>
    </form>
  )
}
```

## Error Boundary Pattern

ErrorBoundary must be a class component — React 19 still has no functional equivalent. Use `react-error-boundary` package for a pre-built version with reset and fallback render props.

```typescript
interface ErrorBoundaryState {
  hasError: boolean
  error: Error | null
}

export class ErrorBoundary extends React.Component<
  { children: React.ReactNode; fallback?: React.ReactNode },
  ErrorBoundaryState
> {
  state: ErrorBoundaryState = {
    hasError: false,
    error: null
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error boundary caught:', error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) return this.props.fallback

      return (
        <div className="error-fallback">
          <h2>Something went wrong</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={() => this.setState({ hasError: false, error: null })}>
            Try again
          </button>
        </div>
      )
    }

    return this.props.children
  }
}

// Usage
<ErrorBoundary fallback={<ErrorPage />}>
  <App />
</ErrorBoundary>
```

## Animation Patterns

### Motion (formerly Framer Motion)

The library was renamed: import from `motion/react` (not `framer-motion`).

```typescript
import { motion, AnimatePresence } from 'motion/react'

// ✅ List animations
export function AnimatedMarketList({ markets }: { markets: Market[] }) {
  return (
    <AnimatePresence>
      {markets.map(market => (
        <motion.div
          key={market.id}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.3 }}
        >
          <MarketCard market={market} />
        </motion.div>
      ))}
    </AnimatePresence>
  )
}

// ✅ Modal animations
export function Modal({ isOpen, onClose, children }: ModalProps) {
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="modal-overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />
          <motion.div
            className="modal-content"
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
          >
            {children}
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
```

## Accessibility Patterns

### Keyboard Navigation

```typescript
export function Dropdown({ options, onSelect }: DropdownProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [activeIndex, setActiveIndex] = useState(0)

  const handleKeyDown = (e: React.KeyboardEvent) => {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault()
        setActiveIndex(i => Math.min(i + 1, options.length - 1))
        break
      case 'ArrowUp':
        e.preventDefault()
        setActiveIndex(i => Math.max(i - 1, 0))
        break
      case 'Enter':
        e.preventDefault()
        onSelect(options[activeIndex])
        setIsOpen(false)
        break
      case 'Escape':
        setIsOpen(false)
        break
    }
  }

  return (
    <div
      role="combobox"
      aria-expanded={isOpen}
      aria-haspopup="listbox"
      onKeyDown={handleKeyDown}
    >
      {/* Dropdown implementation */}
    </div>
  )
}
```

### Focus Management

```typescript
export function Modal({ isOpen, onClose, children }: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null)
  const previousFocusRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (isOpen) {
      previousFocusRef.current = document.activeElement as HTMLElement
      modalRef.current?.focus()
    } else {
      previousFocusRef.current?.focus()
    }
  }, [isOpen])

  return isOpen ? (
    <div
      ref={modalRef}
      role="dialog"
      aria-modal="true"
      tabIndex={-1}
      onKeyDown={e => e.key === 'Escape' && onClose()}
    >
      {children}
    </div>
  ) : null
}
```

## Quick Reference: What Changed in React 19

| Before (React 18) | After (React 19) | Notes |
|---|---|---|
| `useEffect` + `useState` for data fetching | `use(promise)` + `<Suspense>` | `use()` can be called conditionally |
| `useFormState` from `react-dom` | `useActionState` from `react` | Returns `[state, action, isPending]` |
| No built-in optimistic UI | `useOptimistic` | Works with form actions and transitions |
| No pending status in child components | `useFormStatus` from `react-dom` | Must be inside a `<form>` child component |
| Manual `useMemo` / `useCallback` everywhere | React Compiler auto-memoizes | Opt-in via build plugin; manual still works |
| `framer-motion` package | `motion/react` package | Same API, just renamed |
| Hand-rolled `useQuery` hook | TanStack Query v5 | Handles cache, retry, dedup, background refetch |
| `forwardRef` wrapper | `ref` is a regular prop | No more `forwardRef` needed in React 19 |
| Context.Provider | `<Context>` directly | `<MyContext value={...}>` works as provider |

**Remember**: Modern frontend patterns enable maintainable, performant user interfaces. Prefer server-side data fetching (Server Components, Server Actions) for Next.js apps. Use TanStack Query for client-side async state. Use Zustand for client-side UI state. Let React Compiler handle memoization when available.
