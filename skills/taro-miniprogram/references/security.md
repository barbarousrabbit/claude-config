# 小程序安全规范详细实现

## 1. 手机号安全授权流程

**绝不允许**前端直接传明文手机号。完整流程：

```
前端                    后端
  |                       |
  |── wx.login() ────────►|
  |◄── code ──────────────|
  |                       |
  | 点击"授权手机号"按钮     |
  | (open-type="getPhoneNumber")
  |                       |
  |── { encryptedData,    |
  |    iv, code } ───────►|
  |                       |── jscode2session(code) ──► 微信
  |                       |◄── session_key ──────────── 微信
  |                       |
  |                       |── AES-128-CBC 解密 encryptedData
  |                       |── 获得真实手机号
  |◄── { sessionToken } ──|
```

后端解密代码（Node.js）：
```ts
import { createDecipheriv } from 'crypto'

function decryptPhone(sessionKey: string, encryptedData: string, iv: string): string {
  const decipher = createDecipheriv(
    'aes-128-cbc',
    Buffer.from(sessionKey, 'base64'),
    Buffer.from(iv, 'base64'),
  )
  decipher.setAutoPadding(true)
  const decrypted = Buffer.concat([
    decipher.update(Buffer.from(encryptedData, 'base64')),
    decipher.final(),
  ])
  const data = JSON.parse(decrypted.toString('utf8'))
  return data.phoneNumber // 真实手机号
}
```

---

## 2. Session Token 设计

**绝不**将 openid 暴露给前端。使用自定义 Token：

```ts
// 后端登录接口返回
{
  "accessToken": "eyJ...",    // JWT，payload 中存 userId，不存 openid
  "refreshToken": "eyJ...",
  "expiresIn": 7200
}

// JWT payload 示例（正确）
{ "sub": "user_clx...", "role": "CUSTOMER", "iat": ..., "exp": ... }

// JWT payload 示例（错误！不要这样做）
{ "openid": "oXxx...", "role": "CUSTOMER" }  // ❌ openid 泄露
```

前端存储 Token（正确方式）：
```ts
// ✅ 存 Token，不存 openid
Taro.setStorageSync('accessToken', response.accessToken)
Taro.setStorageSync('refreshToken', response.refreshToken)

// 所有 API 请求带 Authorization 头
headers: { Authorization: `Bearer ${Taro.getStorageSync('accessToken')}` }
```

---

## 3. UGC 内容安全

### 文字检测（发送前拦截）
```ts
// 前端调用后端接口，后端再调微信 API（避免直接暴露 access_token）
async function checkText(content: string): Promise<boolean> {
  try {
    const res = await api.checkContent({ type: 'text', content })
    return res.safe // 后端返回是否安全
  } catch {
    return true // 接口异常时放行，避免影响用户体验
  }
}

// 消息发送前校验
const onSend = async () => {
  if (!(await checkText(inputValue))) {
    Taro.showToast({ title: '内容不合规，请修改', icon: 'none' })
    return
  }
  sendMessage(inputValue)
}
```

### 图片检测（上传后异步）
```ts
// 1. 前端上传图片到 OSS（直传，后端不接触原始文件）
// 2. 前端将 OSS URL 传给后端
// 3. 后端触发微信异步检测（mediaCheckAsync）
// 4. 微信通过消息推送回调，后端更新审核状态
// 5. 图片在审核通过前显示占位图

// 前端展示逻辑
<Image
  src={item.status === 'APPROVED' ? item.imageUrl : PLACEHOLDER_URL}
  mode="aspectFill"
/>
```

---

## 4. 支付安全

### 前端注意事项
```ts
// ✅ 正确：从后端获取支付参数，前端只负责唤起支付界面
const payParams = await api.createPayment(orderId)
await Taro.requestPayment(payParams)

// ❌ 错误：前端自己计算签名（私钥泄露风险）
// ❌ 错误：前端自行构造金额（被篡改风险）
```

### 支付结果处理
```ts
try {
  await Taro.requestPayment(payParams)
  // requestPayment resolve 表示用户操作完成，不代表支付成功
  // 轮询订单状态，等后端 notify 回调更新
  await pollOrderStatus(orderId)
} catch (e) {
  if (e.errMsg?.includes('cancel')) {
    // 用户主动取消，不是错误
  } else {
    Taro.showToast({ title: '支付失败', icon: 'error' })
  }
}
```

---

## 5. 防止接口越权

前端所有涉及用户数据的请求，只传自己的 Token：

```ts
// ✅ 正确：用 Token 隐含当前用户，后端从 Token 解析 userId
api.getMyOrders() // GET /api/orders/mine

// ❌ 错误：在请求参数里传 userId（可被篡改）
api.getOrders({ userId: 'other-user-id' }) // 潜在越权
```

---

## 6. 敏感数据展示脱敏

```ts
// 前端展示时进一步保护（后端已脱敏，前端不需要重复）
// 但如果后端返回了完整数据，前端展示前要脱敏：

function maskPhone(phone: string): string {
  return phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2')
}

function maskIdCard(idCard: string): string {
  return idCard.replace(/(\d{4})\d{10}(\w{4})/, '$1**********$2')
}
```

---

## 7. HTTPS / WSS 强制要求

```ts
// app.config.ts 或 HTTP 拦截器
const BASE_URL = 'https://api.example.com' // ✅ HTTPS
const WS_URL = 'wss://api.example.com/ws'  // ✅ WSS

// ❌ 绝不使用 http:// 或 ws:// 在生产环境
```

微信后台白名单配置路径：
`微信公众平台 → 开发 → 开发管理 → 服务器域名 → request合法域名/socket合法域名`
