# BindPhone 组件实现思路

The skill's security guidelines drove the core design: the component uses WeChat's `open-type="getPhoneNumber"` to receive an encrypted one-time `code` (plus `encryptedData`/`iv` as a compatibility fallback for older base libraries), and passes only these cryptographic tokens to the backend `/api/auth/bind-phone` endpoint — no plaintext phone number ever leaves the client.

State management follows the skill's Taro-specific Zustand pattern, using a `persist` store backed by `Taro.setStorageSync` (not `localStorage`) so the JWT token survives app restarts; the `useAuthStore` hook's `setToken` action is called immediately after a successful bind response before navigating to the home tab via `Taro.switchTab`.

UI is built entirely with NutUI React Taro's `Button` component (imported from `@nutui/nutui-react-taro`, not the Web variant) and `Toast` for feedback, all styled in `rpx` units via a CSS Module, with user-rejection and network-error paths handled gracefully before any async call is made.
