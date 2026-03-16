---
name: taro-miniprogram
description: Use when building WeChat mini-programs with Taro 4 — components, WeChat APIs, rpx layout, NutUI, 小程序.
---

# Taro 4 + WeChat 小程序 开发指南

## 核心原则

Taro 4 是 React 18 的超集，但运行在小程序环境，有几条关键差异：
- 没有 DOM/BOM，用 `Taro.*` API 代替 `window.*` / `document.*`
- 用 `View/Text/Image/ScrollView` 等 Taro 原生组件代替 `div/span/img`
- 样式单位用 `rpx`（750rpx = 屏幕宽度），不用 `px`（除非全局字体）
- 生命周期用 `useDidShow` / `useDidHide` 代替 `window.onFocus`

---

## 1. 组件规范

### 标准函数式组件模板

```tsx
import { View, Text, Image } from '@tarojs/components'
import { useLoad, useDidShow } from '@tarojs/taro'
import Taro from '@tarojs/taro'
import styles from './index.module.scss'

interface Props {
  title: string
}

export default function MyPage({ title }: Props) {
  useLoad(() => {
    // 页面首次加载，等价于 componentDidMount
  })

  useDidShow(() => {
    // 每次页面展示（含从后台返回），适合刷新数据
  })

  return (
    <View className={styles.container}>
      <Text className={styles.title}>{title}</Text>
    </View>
  )
}
```

### NutUI React Taro 使用规范

```tsx
import { Button, Cell, Toast } from '@nutui/nutui-react-taro'

// ✅ 正确：从 @nutui/nutui-react-taro 导入
// ❌ 错误：从 @nutui/nutui-react 导入（Web 版，小程序不兼容）

// 弹出提示
Toast.show({ content: '操作成功', icon: 'success' })

// Cell 列表
<Cell title="订单号" description="DG20260223001" />
```

### 常用 Taro 组件对照

| Web | Taro 组件 | 说明 |
|-----|---------|------|
| `div` | `View` | 块级容器 |
| `span/p` | `Text` | 文本，必须套 Text 才能选中复制 |
| `img` | `Image` | 图片，mode 属性控制裁切 |
| `ul/li` | `View` + `ScrollView` | 列表 |
| `input` | `Input` | 单行输入 |
| `textarea` | `Textarea` | 多行输入 |

---

## 2. 胶囊按钮避让（MANDATORY）

**右上角区域严禁放交互元素**，必须动态计算安全区：

```tsx
// hooks/useNavHeight.ts
import Taro from '@tarojs/taro'
import { useState, useEffect } from 'react'

export function useNavHeight() {
  const [navHeight, setNavHeight] = useState(88) // 默认值兜底

  useEffect(() => {
    const sysInfo = Taro.getSystemInfoSync()
    const capsule = Taro.getMenuButtonBoundingClientRect()
    // 导航栏高度 = 胶囊底部 + (胶囊顶部 - 状态栏高度)
    const height = capsule.bottom + (capsule.top - sysInfo.statusBarHeight)
    setNavHeight(height + sysInfo.statusBarHeight)
  }, [])

  return navHeight
}

// 在自定义导航栏中使用
const navHeight = useNavHeight()
<View style={{ height: `${navHeight}px` }} />
```

**app.config.ts 中配置：**
```ts
window: {
  navigationStyle: 'custom', // 启用自定义导航
}
```

---

## 3. 样式规范（rpx + CSS Module）

```scss
// index.module.scss
.container {
  padding: 24rpx;          // rpx 响应式
  background: #fff;
}

.title {
  font-size: 32rpx;        // 小程序中 32rpx ≈ 16px（750 基准屏）
  font-weight: 600;
  color: #1a1a1a;
}

.btn {
  width: 686rpx;           // 屏宽 750rpx 两边各 32rpx 留白
  height: 88rpx;
  border-radius: 44rpx;
}
```

**常用换算：** 1rpx = 0.5px（iPhone 6/7/8 基准），设计稿通常以 375px = 750rpx 为基准。

---

## 4. 分包加载配置

主包必须 < 2MB，分包各 < 2MB：

```ts
// app.config.ts
export default {
  pages: ['pages/index/index', 'pages/cart/index'],  // 主包
  subPackages: [
    {
      root: 'packageOrder',
      pages: ['order-list/index', 'order-detail/index'],
    },
    {
      root: 'packageProduct',
      pages: ['product-detail/index', 'search/index'],
    },
  ],
  preloadRule: {
    'pages/index/index': {
      network: 'all',
      packages: ['packageProduct'],  // 首页预加载商品分包
    },
  },
}
```

**检查包大小：** `pnpm --filter <app> build:weapp` 后查看 `dist/` 目录各包大小。

---

## 5. WeChat API 速查

详细用法见 `references/wechat-apis.md`，常用速查：

```ts
import Taro from '@tarojs/taro'

// 登录获取 code
const { code } = await Taro.login()

// JSAPI 支付
await Taro.requestPayment({ timeStamp, nonceStr, package: pkg, signType: 'RSA', paySign })

// 选择收货地址
const addr = await Taro.chooseAddress()

// 获取系统信息
const sysInfo = Taro.getSystemInfoSync()

// 胶囊按钮位置
const capsule = Taro.getMenuButtonBoundingClientRect()

// 跳转（tabBar 页用 switchTab，普通页用 navigateTo）
Taro.navigateTo({ url: '/packageOrder/order-detail/index?id=xxx' })

// 下拉刷新（需在 page config 中开启 enablePullDownRefresh: true）
Taro.stopPullDownRefresh()

// 分享（useShareAppMessage Hook）
useShareAppMessage(() => ({
  title: '帮我付款',
  path: `/packageOrder/proxy-pay/index?token=${token}`,
}))
```

---

## 6. WebSocket Hook（心跳 + 重连）

> ⚠️ **协议安全（必须执行）**：微信小程序生产环境**强制要求 `wss://`**，不允许 `ws://`（明文）。
> 若用户提供的 URL 是 `ws://`，必须主动将其改为 `wss://` 并在回答中说明原因。
> 本地开发若需 `ws://`，需在微信开发者工具中勾选"不校验域名"。

```tsx
// hooks/useWebSocket.ts
import { useEffect, useRef, useCallback } from 'react'
import Taro from '@tarojs/taro'

// ✅ 正确：wss://（加密，生产必须）
// ❌ 错误：ws://（明文，小程序上线后被拒绝）
export function useWebSocket(url: string, onMessage: (data: any) => void) {
  const socketRef = useRef<Taro.SocketTask | null>(null)
  const reconnectDelay = useRef(1000)
  const heartbeatTimer = useRef<ReturnType<typeof setInterval>>()
  const isUnmounted = useRef(false)

  const connect = useCallback(() => {
    if (isUnmounted.current) return

    const socket = Taro.connectSocket({ url, fail: () => scheduleReconnect() })
    socketRef.current = socket

    socket.onOpen(() => {
      reconnectDelay.current = 1000 // 重置退避延迟
      heartbeatTimer.current = setInterval(() => {
        socket.send({ data: JSON.stringify({ type: 'ping' }) })
      }, 30000)
    })

    socket.onMessage(({ data }) => {
      const msg = JSON.parse(data as string)
      if (msg.type !== 'pong') onMessage(msg)
    })

    socket.onClose(() => {
      clearInterval(heartbeatTimer.current)
      scheduleReconnect()
    })
  }, [url, onMessage])

  const scheduleReconnect = useCallback(() => {
    if (isUnmounted.current) return
    setTimeout(() => {
      reconnectDelay.current = Math.min(reconnectDelay.current * 2, 30000) // 指数退避上限 30s
      connect()
    }, reconnectDelay.current)
  }, [connect])

  useEffect(() => {
    connect()
    return () => {
      isUnmounted.current = true
      clearInterval(heartbeatTimer.current)
      socketRef.current?.close({})
    }
  }, [connect])

  return socketRef
}
```

---

## 7. Zustand 状态管理

Taro 中 Zustand 用法与 Web 完全一致，但有一个注意点：

```ts
// stores/auth.store.ts
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import Taro from '@tarojs/taro'

// 小程序持久化用 Taro.setStorageSync，不能用 localStorage
const taroStorage = {
  getItem: (key: string) => Taro.getStorageSync(key) ?? null,
  setItem: (key: string, value: string) => Taro.setStorageSync(key, value),
  removeItem: (key: string) => Taro.removeStorageSync(key),
}

interface AuthState {
  token: string | null
  userId: string | null
  setToken: (token: string) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      userId: null,
      setToken: (token) => set({ token }),
      logout: () => set({ token: null, userId: null }),
    }),
    { name: 'auth', storage: createJSONStorage(() => taroStorage) },
  ),
)
```

---

## 8. i18n 双语方案

```ts
// i18n/index.ts
import zhCN from './zh-CN.json'
import enUS from './en-US.json'
import Taro from '@tarojs/taro'

const messages = { 'zh-CN': zhCN, 'en-US': enUS }

export function t(key: string, params?: Record<string, string>): string {
  const lang = (Taro.getStorageSync('lang') as string) || 'zh-CN'
  const dict = messages[lang] ?? messages['zh-CN']
  let text = key.split('.').reduce((obj: any, k) => obj?.[k], dict) ?? key
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      text = text.replace(`{{${k}}}`, v)
    })
  }
  return text
}

// 用法：t('order.pay.success') → '支付成功'
```

---

## 9. 安全规范

详细规则见 `references/security.md`，核心要点：

- **手机号**：使用 `<Button open-type="getPhoneNumber">` + 后端解密，不直接传明文
- **openid**：后端自行调用微信接口换取，前端只持有自定义 Session Token
- **UGC 内容安全**：文字 → `wx.sec.msgSecCheck`；图片 → `wx.sec.mediaCheckAsync`（异步回调）
- **支付回调**：后端必须验签 + 二次比对金额，防止篡改

---

## 10. miniprogram-ci 发布

详细配置见 `references/cicd.md`，核心用法：

```bash
# 预览（生成二维码）
node deploy/miniprogram-ci.js preview --app customer-app

# 上传体验版
node deploy/miniprogram-ci.js upload --app customer-app --version 1.2.0 --desc "新增代付功能"
```

---

## 参考文档

- `references/wechat-apis.md` — 微信 API 完整用法（login/payment/share/media）
- `references/security.md` — 安全规范详细实现
- `references/cicd.md` — miniprogram-ci 配置与 GitHub Actions 集成
