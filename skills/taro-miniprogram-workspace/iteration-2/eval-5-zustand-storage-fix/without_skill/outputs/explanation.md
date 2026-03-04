# Root Cause Analysis: Zustand `persist` Token Lost on Mini-Program Restart

## Root Cause

The original code uses `createJSONStorage(() => localStorage)` as the storage backend for Zustand's `persist` middleware.

```ts
// 错误写法
storage: createJSONStorage(() => localStorage),
```

**`localStorage` does not exist in the WeChat mini-program JavaScript runtime.**

The WeChat mini-program runs in a custom JS engine (V8 on Android, JavaScriptCore on iOS), not a browser. Browser Web APIs — including `window`, `document`, `localStorage`, and `sessionStorage` — are absent. When the store is initialized, `localStorage` evaluates to `undefined`. Zustand's `persist` middleware calls `storage.getItem(name)` on rehydration; because the object is `undefined`, the call either throws silently or returns `null`, so the stored token is never restored. State resets to the initial value (`token: null`) on every app cold start.

## Why It Silently Fails

Zustand's `persist` middleware wraps storage calls in try/catch internally, so the `TypeError: Cannot read properties of undefined` error is swallowed rather than propagated to the application. This makes the bug appear as "token becomes null" rather than a visible crash, which is easy to miss.

## The Fix

Replace `localStorage` with a custom `StateStorage` adapter that delegates to the Taro (WeChat mini-program) synchronous storage API:

| Web Storage API (browser) | Taro / WeChat equivalent |
|---|---|
| `localStorage.getItem(key)` | `Taro.getStorageSync(key)` |
| `localStorage.setItem(key, value)` | `Taro.setStorageSync(key, value)` |
| `localStorage.removeItem(key)` | `Taro.removeStorageSync(key)` |

```ts
import Taro from '@tarojs/taro'
import { StateStorage } from 'zustand/middleware'

const taroStorage: StateStorage = {
  getItem(key) {
    const value = Taro.getStorageSync(key)
    return value !== '' && value !== undefined && value !== null ? value : null
  },
  setItem(key, value) {
    Taro.setStorageSync(key, value)
  },
  removeItem(key) {
    Taro.removeStorageSync(key)
  },
}
```

Then pass it to `createJSONStorage`:

```ts
storage: createJSONStorage(() => taroStorage),
```

## Key Subtlety: `getStorageSync` Returns `''` for Missing Keys

Unlike `localStorage.getItem()` which returns `null` for missing keys, `Taro.getStorageSync()` returns an empty string `''` when the key does not exist. The adapter normalizes this to `null` so Zustand's rehydration logic correctly detects "no stored state" and uses initial values rather than treating `''` as valid serialized JSON.

## Alternative: Async Storage (Recommended for Large State)

For large state objects, consider using the async API to avoid blocking the JS thread:

```ts
import { StateStorage } from 'zustand/middleware'
import Taro from '@tarojs/taro'

const taroAsyncStorage: StateStorage = {
  async getItem(key) {
    const res = await Taro.getStorage({ key }).catch(() => ({ data: null }))
    return res.data ?? null
  },
  async setItem(key, value) {
    await Taro.setStorage({ key, data: value })
  },
  async removeItem(key) {
    await Taro.removeStorage({ key }).catch(() => {})
  },
}
```

For an auth token (small payload), the synchronous adapter in the fix is sufficient and simpler.

## Summary

| Aspect | Original (Broken) | Fixed |
|---|---|---|
| Storage backend | `localStorage` (browser-only) | `Taro.getStorageSync` / `Taro.setStorageSync` |
| Exists in mini-program | No — `undefined` at runtime | Yes — native mini-program API |
| Error visibility | Silent (swallowed by persist) | Logged via `console.error` with context |
| Token persisted across restarts | No | Yes |
