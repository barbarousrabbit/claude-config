## 实现思路

核心方案是通过 `Taro.getMenuButtonBoundingClientRect()` 获取胶囊按钮的精确位置，再结合 `Taro.getSystemInfoSync()` 的 `statusBarHeight`，用公式 `navBarHeight = 胶囊高度 + (胶囊顶部 - 状态栏高度) × 2` 计算出在各机型上都能让内容垂直居中且不与胶囊重叠的导航栏内容区高度。

Hook 在 `useState` 初始化时同步执行计算（而非 `useEffect`），保证首帧渲染就有正确高度，避免导航栏高度从 0 跳变的闪烁问题；同时对胶囊数据做合法性校验，当数据异常或非微信环境时自动降级到 iOS/Android 各自的平台默认值，确保全机型兼容。

除高度外，还额外暴露 `menuButtonLeft`（胶囊左边界）和 `menuButtonRight`（胶囊右侧到屏幕边缘距离）字段，方便调用方直接约束自定义导航栏右侧按钮的布局区域，彻底解决与胶囊按钮重叠的问题。
