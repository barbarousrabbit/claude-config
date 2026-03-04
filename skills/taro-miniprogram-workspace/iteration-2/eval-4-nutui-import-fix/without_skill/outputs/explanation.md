# Root Cause: Wrong NutUI Package Import

## Problem

The original code imports `Toast` from `@nutui/nutui-react`:

```tsx
import { Button, Toast } from '@nutui/nutui-react'
```

This is the **web version** of NutUI, which internally relies on browser DOM APIs (e.g., `document.createElement`, `ReactDOM.render`/`createPortal`). These APIs do not exist in the WeChat mini-program runtime, so calling `Toast.show(...)` silently fails — no error is thrown, nothing is displayed.

## Fix

Import from `@nutui/nutui-react-taro` instead:

```tsx
import { Button, Toast } from '@nutui/nutui-react-taro'
```

`@nutui/nutui-react-taro` is the Taro-adapted build of NutUI. It uses Taro's native component primitives (`View`, `Text`, etc.) and Taro APIs under the hood, making it fully compatible with the mini-program environment.

## Rule of Thumb

| Environment | Correct package |
|---|---|
| Web (React) | `@nutui/nutui-react` |
| Taro mini-program | `@nutui/nutui-react-taro` |

Never mix the two — importing the web package inside a Taro mini-program will cause all NutUI components that rely on DOM (Toast, Dialog, Popup, etc.) to silently do nothing or crash at runtime.
