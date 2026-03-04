# Root Cause: Wrong NutUI Package Import

## Problem

The original code imported `Toast` (and `Button`) from `@nutui/nutui-react`:

```tsx
import { Button, Toast } from '@nutui/nutui-react'
```

## Why This Fails in Taro Mini-Programs

`@nutui/nutui-react` is the **Web version** of NutUI. It relies on the browser DOM and standard HTML elements, which do not exist in the WeChat mini-program runtime. When this package is used inside a Taro mini-program:

- The components render nothing visible because they attempt to create DOM nodes that the mini-program environment cannot handle.
- `Toast.show(...)` calls silently fail or produce no output because the underlying implementation depends on `document` / React DOM portals, neither of which is available.

## Fix

Replace the import with `@nutui/nutui-react-taro`, which is the mini-program-compatible build of NutUI:

```tsx
// Before (Web version - incompatible with Taro mini-program)
import { Button, Toast } from '@nutui/nutui-react'

// After (Taro version - correct for WeChat mini-program)
import { Button, Toast } from '@nutui/nutui-react-taro'
```

`@nutui/nutui-react-taro` uses Taro's native components (`View`, `Text`, etc.) internally instead of HTML elements, making it fully compatible with the mini-program runtime.

## Rule (from taro-miniprogram skill)

> Always import NutUI components from `@nutui/nutui-react-taro` in Taro projects.
> Never import from `@nutui/nutui-react` (the Web version is incompatible with mini-programs).
