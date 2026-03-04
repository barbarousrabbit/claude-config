# 根本原因分析：Zustand persist 在 Taro 小程序中 token 丢失

## 问题根本原因

原始代码使用了 `localStorage` 作为 Zustand `persist` 中间件的 storage 后端：

```ts
storage: createJSONStorage(() => localStorage),
```

**`localStorage` 在微信小程序运行环境中不存在。**

微信小程序运行在一个独立的 JavaScript 运行时（V8 引擎 + 小程序框架），它没有 DOM，也没有 Web 平台的 BOM 对象，因此以下全局对象均不存在：

- `window`
- `document`
- `localStorage`
- `sessionStorage`
- `navigator`（部分属性缺失）

当 `zustand/middleware` 的 `persist` 尝试调用 `localStorage.getItem(key)` 时，由于 `localStorage` 是 `undefined`，调用会直接抛出异常或静默失败。结果是：

- 写入时（`setToken`）：数据无法持久化到任何存储介质，仅保留在内存中
- 读取时（小程序重启后）：内存状态已清空，`persist` 尝试从 storage 恢复，但因 `localStorage` 不可用，恢复失败，`token` 回到初始值 `null`

## 正确做法

Taro 提供了一套封装微信原生存储 API 的同步接口，必须用它替换 `localStorage`：

| Web API | Taro 等效 API |
|---|---|
| `localStorage.getItem(key)` | `Taro.getStorageSync(key)` |
| `localStorage.setItem(key, val)` | `Taro.setStorageSync(key, val)` |
| `localStorage.removeItem(key)` | `Taro.removeStorageSync(key)` |

正确的 storage 适配器：

```ts
import Taro from '@tarojs/taro'

const taroStorage = {
  getItem: (key: string): string | null => {
    return Taro.getStorageSync(key) ?? null
  },
  setItem: (key: string, value: string): void => {
    Taro.setStorageSync(key, value)
  },
  removeItem: (key: string): void => {
    Taro.removeStorageSync(key)
  },
}
```

然后将其传入 `createJSONStorage`：

```ts
storage: createJSONStorage(() => taroStorage),
```

## 修复前后对比

### 修复前（错误）

```ts
storage: createJSONStorage(() => localStorage),
// localStorage 在小程序运行时不存在，读写均失败
// token 每次重启小程序都变回 null
```

### 修复后（正确）

```ts
storage: createJSONStorage(() => taroStorage),
// taroStorage 使用 Taro.getStorageSync / setStorageSync / removeStorageSync
// 数据持久化到微信本地存储，重启小程序后 token 可正确恢复
```

## 注意事项

1. `Taro.getStorageSync` 在 key 不存在时返回空字符串 `''` 而不是 `null`，适配器中需加 `?? null` 保证返回值类型与 zustand persist 的期望一致。
2. Taro 存储 API 有同步（`Sync`）和异步（回调/Promise）两种形式。`persist` 中间件的 storage 接口要求同步或返回 Promise，使用同步版本（`getStorageSync` / `setStorageSync` / `removeStorageSync`）最为简洁可靠。
3. 微信小程序本地存储上限为 **10MB**，存储大量数据时需注意。
