# 微信 API 完整参考

## 登录与授权

### wx.login（获取 code）
```ts
const { code } = await Taro.login()
// 将 code 发给后端，后端换取 openid/session_key
```

### 手机号授权（推荐方式）
```tsx
// 前端：使用 Button open-type，不要用已废弃的 getUserProfile
<Button
  openType="getPhoneNumber"
  onGetPhoneNumber={(e) => {
    // e.detail.encryptedData + iv 发给后端解密
    if (!e.detail.errMsg?.includes('ok')) return
    api.bindPhone({
      encryptedData: e.detail.encryptedData,
      iv: e.detail.iv,
      code: loginCode, // 同步获取的 code
    })
  }}
>
  授权手机号
</Button>
```

### wx.getUserProfile（已废弃，不要使用）
微信从 2022.10.25 起停止支持 `wx.getUserProfile`，用户信息在登录后由后端从 access_token 获取，或在前端通过 `open-data` 组件展示。

---

## 支付

### wx.requestPayment（JSAPI 支付）
```ts
// 参数来自后端 JSAPI 下单接口返回
const payParams = await api.createPayment(orderId)

await Taro.requestPayment({
  timeStamp: payParams.timeStamp,
  nonceStr: payParams.nonceStr,
  package: payParams.package,       // "prepay_id=xxx"
  signType: 'RSA',
  paySign: payParams.paySign,
})

// 支付成功后跳转到结果页（不要依赖这里做业务逻辑，以后端回调为准）
Taro.redirectTo({ url: '/pages/pay-result/index' })
```

**注意：** `requestPayment` 成功仅代表用户确认支付，实际支付结果以后端 notify 回调为准。

---

## 地理与地址

### wx.chooseAddress（选择收货地址）
```ts
try {
  const addr = await Taro.chooseAddress()
  // addr.userName, addr.telNumber, addr.provinceName, addr.cityName
  // addr.countyName, addr.detailInfo, addr.postalCode
} catch (e) {
  // 用户取消或未授权，正常处理
}
```

### wx.getLocation（获取位置，需在 app.json 配置权限）
```ts
// app.config.ts 中需配置：
// permission: { 'scope.userLocation': { desc: '用于展示附近买手' } }
const { latitude, longitude } = await Taro.getLocation({ type: 'gcj02' })
```

---

## 媒体

### wx.chooseMedia（选择图片/视频）
```ts
const res = await Taro.chooseMedia({
  count: 9,
  mediaType: ['image'],
  sizeType: ['compressed'],
  sourceType: ['album', 'camera'],
})
// res.tempFiles[].tempFilePath — 临时路径，用于上传 OSS
```

### wx.previewImage（预览图片）
```ts
Taro.previewImage({
  current: imageUrl,           // 当前显示图片
  urls: [imageUrl1, imageUrl2], // 所有图片列表
})
```

---

## 分享

### useShareAppMessage
```ts
import { useShareAppMessage } from '@tarojs/taro'

useShareAppMessage(() => ({
  title: '帮我付款',
  path: `/packageOrder/proxy-pay/index?token=${proxyToken}`,
  imageUrl: 'https://oss.example.com/share-cover.jpg', // 自定义分享封面
}))
```

### useShareTimeline（分享到朋友圈）
```ts
import { useShareTimeline } from '@tarojs/taro'

useShareTimeline(() => ({
  title: '代购好物',
  query: `merchantId=${merchantId}`,
}))
```

---

## 缓存与存储

```ts
// 同步（推荐小数据）
Taro.setStorageSync('token', value)
const token = Taro.getStorageSync('token')
Taro.removeStorageSync('token')

// 异步（推荐大数据）
await Taro.setStorage({ key: 'cart', data: cartItems })
const { data } = await Taro.getStorage({ key: 'cart' })
```

---

## 系统信息

```ts
const sysInfo = Taro.getSystemInfoSync()
// sysInfo.statusBarHeight  — 状态栏高度（px）
// sysInfo.safeArea         — 安全区域（bottom 值用于底部安全区）
// sysInfo.screenWidth      — 屏幕宽度（px）
// sysInfo.pixelRatio       — 设备像素比

const capsule = Taro.getMenuButtonBoundingClientRect()
// capsule.top/bottom/left/right/width/height（px）
```

---

## 导航

```ts
// 普通页面跳转（可返回）
Taro.navigateTo({ url: '/packageOrder/order-detail/index?id=xxx' })

// 替换当前页（不可返回）
Taro.redirectTo({ url: '/pages/pay-result/index' })

// 返回
Taro.navigateBack({ delta: 1 })

// TabBar 页面跳转（必须用 switchTab）
Taro.switchTab({ url: '/pages/index/index' })

// 传递复杂参数（URL 参数只能传字符串，复杂对象用 EventChannel 或 Storage）
Taro.navigateTo({
  url: '/packageOrder/confirm/index',
  events: { acceptData: (data) => console.log(data) },
  success: (res) => {
    res.eventChannel.emit('sendData', { items: cartItems })
  },
})
```

---

## 下拉刷新与上拉加载

```ts
// page.config.ts 中配置
export default { enablePullDownRefresh: true }

// 页面中
import { usePullDownRefresh, useReachBottom } from '@tarojs/taro'

usePullDownRefresh(async () => {
  await fetchData()
  Taro.stopPullDownRefresh()
})

useReachBottom(() => {
  loadMore()
})
```

---

## 内容安全（UGC 必须接入）

```ts
// 文字内容检测（同步，用于评论/消息发送前校验）
// 注意：这是微信云函数中的用法，后端直接调用微信 API
// 前端只需把内容传给后端校验接口

// 图片/音频异步检测（后端发起）
// POST https://api.weixin.qq.com/wxa/img_sec_check
// 结果通过消息推送回来，前端无需处理
```
