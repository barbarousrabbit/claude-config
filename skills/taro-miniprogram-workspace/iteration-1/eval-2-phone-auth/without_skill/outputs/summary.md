## 方案说明

组件通过 NutUI React Taro 的 `Button` 组件配合 `openType="getPhoneNumber"` 触发微信原生授权弹窗，在 `onGetPhoneNumber` 回调中拿到微信加密凭证（`encryptedData` + `iv`，或新版 `code`），再调用后端 `/api/auth/bind-phone` 接口由服务端解密并绑定，全程不传明文手机号，符合微信平台安全要求。

授权成功后，组件通过 `useAuthStore.setUser()` 将后端返回的脱敏用户信息（`phone` 字段已脱敏，如 `138****8888`）同步到 Zustand 全局状态，并持久化至 `Taro.setStorageSync`，然后 `Taro.switchTab` 跳转首页；组件也暴露了 `onSuccess`/`onFail` 回调供父组件自定义后续流程。

网络请求复用项目现有 `request()` 封装（含 HMAC-SHA256 签名、Bearer Token 注入、自动 Token 刷新），未引入任何额外依赖，同时对未登录、用户拒绝、网络错误三种异常场景做了防御处理并给出友好 Toast 提示。
