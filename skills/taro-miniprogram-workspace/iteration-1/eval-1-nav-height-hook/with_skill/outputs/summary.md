# useNavHeight Hook - 实现思路

## 方法概述

基于技能文档第 2 节（胶囊按钮避让）的核心公式，结合跨机型兼容性要求，实现了一个返回完整导航栏高度信息的 Hook。核心计算公式为：导航内容区高度 = 胶囊按钮高度 + (胶囊顶部距状态栏底部的间距) × 2，确保胶囊垂直居中于导航内容区，解决了 iPhone 和 Android 因胶囊位置不同导致的布局差异。

## 关键设计决策

Hook 在 `useState` 初始化阶段即同步调用 `getSystemInfoSync()` 和 `getMenuButtonBoundingClientRect()`（两者均为同步 API），避免了第一帧高度为 0 的闪烁；同时提供多层兜底策略——API 调用失败时按平台（Android 48px / iOS 44px）选取默认导航内容区高度，模拟器环境胶囊数据异常时也能正常降级。

## 返回值设计

Hook 返回 `{ navHeight, statusBarHeight, navContentHeight, contentPaddingTop }` 四个字段，覆盖自定义导航栏组件（设置容器高度 + 状态栏占位 + 内容区高度）和页面主体内容区（设置 paddingTop 避免被导航栏遮挡）两种使用场景。
