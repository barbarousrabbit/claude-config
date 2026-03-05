---
name: taro-miniprogram-ui
description: |
  WeChat mini-program UI design skill for Taro 4 + NutUI React Taro projects.
  Enforces visual quality, layout constraints, and mobile e-commerce design patterns.
  Use this skill whenever creating or modifying mini-program page styles, component
  layouts, NutUI theme customization, product cards, checkout flows, or any SCSS
  styling in Taro projects. Trigger when: .scss files in Taro project, "小程序样式",
  "页面布局", "UI优化", "NutUI主题", product card design, or e-commerce page layout.
---

# Taro 小程序 UI 设计规范

> 本 skill 专注于**视觉设计和样式约束**，代码模式请配合 `taro-miniprogram` skill 使用。

---

## 1. 设计令牌系统（MANDATORY）

### 1.1 颜色使用规则

> ⚠️ **零冷色规则**（必须执行）：SCSS 中**严禁**直接使用冷色值。
> 如果用户提供了冷色（如 `#333`, `#999`, `#f5f5f5`, `rgba(0,0,0,...)`），
> 必须主动替换为设计令牌中的暖色值，并在回答中说明原因。

**禁止 → 替代映射：**

| 禁止使用 | 替代为 | 原因 |
|----------|--------|------|
| `#333333` / `#333` | `$color-text` | 冷灰文字 → 暖灰棕 |
| `#666666` / `#666` | `$color-text-secondary` | |
| `#999999` / `#999` | `$color-text-light` | |
| `#cccccc` / `#ccc` | `$color-text-placeholder` | |
| `#f5f5f5` / `#f0f0f0` | `$color-bg` | 冷灰背景 → 暖调 |
| `#ffffff` 作为页面背景 | `$color-bg` | 页面底色应有暖色调 |
| `#ffffff` 作为卡片背景 | `$color-bg-card` | 卡片用微暖白 |
| `rgba(0, 0, 0, α)` 阴影 | `rgba(80, 50, 30, α)` | 冷黑阴影 → 暖棕 |
| `#1677ff` / 任何蓝色 | `$color-primary` | 平台蓝 → 品牌色 |
| 硬编码 hex 色值 | 对应 `$变量` | 维护一致性 |

### 1.2 SCSS 引入规范

每个 SCSS 文件顶部**必须**引入设计令牌：

```scss
@use '../../styles/variables.scss' as *;
@use '../../styles/mixins.scss' as *;
```

**严禁**在页面 SCSS 中硬编码色值。所有颜色、间距、圆角、阴影必须引用 `$变量`。

### 1.3 文字层级

| 级别 | 变量 | 尺寸 | 场景 |
|------|------|------|------|
| 超大标题 | `$font-size-hero` | 48rpx | 价格大字、Banner 数字 |
| 大标题 | `$font-size-xxl` | 40rpx | 页面主标题 |
| 标题 | `$font-size-xl` | 36rpx | 卡片标题、区块标题 |
| 中标题 | `$font-size-lg` | 32rpx | 列表项主文、商品名 |
| 正文 | `$font-size-base` | 28rpx | 默认正文 |
| 辅助文 | `$font-size-sm` | 24rpx | 标签、说明文字 |
| 极小 | `$font-size-xs` | 20rpx | 角标、极小标注 |

**规则：** 同一视图内文字层级不超过 3 级；价格必须是视觉焦点（最大/最醒目）。

---

## 2. 安全区域与布局约束

### 2.1 胶囊按钮避让（MANDATORY）

> ⚠️ **致命规则**：屏幕右上角 **88rpx × 64rpx** 区域为微信胶囊按钮占位，
> 此区域**严禁放置任何可交互元素**（按钮、输入框、链接）。

自定义导航栏高度计算：

```tsx
const { top, height } = Taro.getMenuButtonBoundingClientRect()
const statusBarHeight = Taro.getSystemInfoSync().statusBarHeight || 0
const navBarHeight = (top - statusBarHeight) * 2 + height  // 导航栏内容区高度
const totalNavHeight = statusBarHeight + navBarHeight       // 总导航栏高度
```

导航栏内只在**左侧**放置返回按钮和标题，右侧留空给胶囊。

### 2.2 底部安全区

所有固定底部栏（操作栏、TabBar 上方浮层）必须包含：

```scss
padding-bottom: env(safe-area-inset-bottom);
```

底部操作栏标准写法：

```scss
.bottom-bar {
  @include bottom-bar(100px);
  // 已内置：fixed + safe-area-inset-bottom + shadow-top
}
```

### 2.3 页面底部留白

页面滚动内容底部必须留出足够空间，避免被固定底栏遮挡：

```scss
.page-container {
  padding-bottom: calc($tab-bar-height + env(safe-area-inset-bottom) + 20px);
}
```

若页面有自定义底部操作栏（非 TabBar），则：

```scss
padding-bottom: calc(100px + env(safe-area-inset-bottom) + 20px);
```

---

## 3. 卡片与容器规范

### 3.1 标准卡片

```scss
.card {
  @include card-base;
  // 等价于：background-color: $color-bg-card; border-radius: $radius-base; box-shadow: $shadow-card;
}
```

### 3.2 可按压卡片

所有可点击的卡片必须有按压反馈：

```scss
.card-tap {
  @include card-base;
  @include card-pressable;
  // 按压时 scale(0.98) + 阴影减弱
}
```

### 3.3 内容区块

白色内容区块使用 `section-block`：

```scss
.info-section {
  @include section-block;
  // card-base + padding + margin-bottom
}
```

### 3.4 区块标题

带左侧装饰线的区块标题：

```scss
.section-title {
  @include section-title-accent;
  // 左侧 4px 品牌色竖线 + 轻微渐变底色
}
```

### 3.5 圆角层级

| 层级 | 变量 | 尺寸 | 场景 |
|------|------|------|------|
| 大容器 | `$radius-xl` / `$radius-2xl` | 20-24rpx | 页面级卡片、弹窗 |
| 标准卡片 | `$radius-lg` | 16rpx | 商品卡、信息卡 |
| 普通容器 | `$radius-base` | 12rpx | section-block |
| 小元素 | `$radius-sm` / `$radius-xs` | 8-6rpx | 标签、头像 |
| 胶囊按钮 | `$radius-round` | 999rpx | 按钮、搜索框 |

**规则：** 父容器圆角 ≥ 子容器圆角，避免视觉冲突。

---

## 4. 商品卡片设计（电商核心）

### 4.1 双列网格商品卡

标准电商商品卡结构（图片叠加样式）：

```
[卡片] — border-radius: $radius-lg, overflow: hidden, shadow-card
  [图片容器] — relative, height: 340rpx
    [商品图] — aspectFill, 覆满容器
    [暗角遮罩] — absolute bottom, gradient-img-overlay
      [标签] — 毛玻璃半透明背景
      [价格行] — 白色价格 + 白色销量，浮于暗角之上
  [信息区] — white background, padding
    [标题] — 2行截断, $color-text
```

**关键约束：**
- 图片容器固定 **340rpx** 高度，`overflow: hidden`
- 暗角遮罩：`$gradient-img-overlay`（从 40% 开始渐变至 65% 不透明度）
- 价格浮于图片之上时用**白色**，带文字阴影 `0 1px 4px rgba(0,0,0,0.3)`
- 标签用毛玻璃效果：`$glass-bg` + `$glass-border` + `backdrop-filter: blur(8px)`
- 双列间距：`$spacing-sm`（12rpx）

### 4.2 价格显示规范

```scss
.price {
  @include price-text($font-size-lg);
  // 红色 + 粗体 + 紧凑字间距
}
```

**价格排版规则：**
- 货币符号 `¥` 用 `$font-size-sm`，数字用 `$font-size-lg` 或更大
- 划线原价用 `$color-text-light` + `text-decoration: line-through` + `$font-size-sm`
- 价格是卡片中**视觉权重最高**的元素

### 4.3 商品标签

```scss
.tag {
  display: inline-flex;
  align-items: center;
  padding: 2rpx $spacing-xs;
  border-radius: $radius-xs;
  font-size: $font-size-xs;

  // 品牌标签（橙色系）
  &--brand {
    background: rgba(240, 112, 64, 0.10);
    color: $color-primary;
  }

  // 物流标签（绿色系）
  &--shipping {
    background: rgba(82, 196, 26, 0.10);
    color: $color-success;
  }

  // 毛玻璃标签（用于图片之上）
  &--glass {
    background: $glass-bg;
    border: 1rpx solid $glass-border;
    backdrop-filter: blur(8px);
    color: $color-primary;
  }
}
```

---

## 5. 页面布局模式

### 5.1 首页

```
[自定义导航栏] — 品牌名 / 搜索入口
[搜索栏] — $color-bg-warm 背景, $radius-round 圆角
[分类网格] — 4-5 列, 圆形图标 + 文字
  [图标容器] — 圆形, rgba($color-primary, 0.08) 背景
[内容区]
  [区块标题] — @include section-title-accent
  [商品网格] — 双列, flex-wrap, $spacing-sm gap
```

### 5.2 商品详情

```
[图片轮播] — 750rpx 宽, 750rpx 高 (1:1)
[价格区] — $gradient-price-bg 背景
  [现价] — $font-size-hero, $color-price
  [原价] — 划线, $color-text-light
  [销量/标签行]
[商品信息] — @include section-block × N
[底部操作栏]
  [收藏] [加入购物车 outline] [立即购买 gradient]
```

**底部操作栏按钮：**
- 主要操作（立即购买）：`@include gradient-btn`，占据更多宽度
- 次要操作（加入购物车）：outline 样式，`border: 2rpx solid $color-primary`
- 图标操作（收藏）：最左侧，固定宽度

### 5.3 个人中心

```
[头部渐变] — $gradient-profile, 至少 300rpx 高
  [头像 + 昵称] — 白色文字, 头像有白色边框
[浮动订单卡] — margin-top: -40rpx, z-index, $shadow-card
  [订单状态快捷入口] — 5 列 grid (待付款/待发货/已发货/已完成/售后)
[功能菜单] — @include card-base, 列表形式
```

**关键技巧：** 浮动卡片使用负 margin-top 叠在渐变头部上方，创造层次感。

### 5.4 购物车

```
[按卖家分组]
  [卖家头部] — $color-bg-warm 背景
  [商品列表]
    [全选 checkbox] + [商品图 160rpx] + [信息 + 价格 + 数量]
[底部结算栏] — fixed, $shadow-top
  [全选] [合计金额 $color-price] [结算按钮 @include gradient-btn]
```

### 5.5 订单列表

```
[Tab 栏] — 全部/待付款/待发货/已发货/已完成/售后
[订单卡片] — @include card-base
  [头部] — 订单号 + 状态标签(彩色)
  [商品行] — 图片 + 信息 + 价格
  [底部] — 合计 + 操作按钮(右对齐)
```

---

## 6. 交互与动效规范

### 6.1 触控目标

- 最小可点击区域：**88rpx × 88rpx**（微信设计规范）
- 按钮最小高度：**72rpx**
- 列表项最小高度：**88rpx**
- 相邻可点击元素间距 ≥ **16rpx**

### 6.2 按压反馈

所有可点击元素必须有反馈，按优先级：

1. **卡片按压**：`@include card-pressable`（scale + shadow 变化）
2. **按钮按压**：`filter: brightness(0.92)` 或 `opacity: 0.85`
3. **列表项按压**：`background-color: $color-bg` 变化

### 6.3 加载态

- **骨架屏**：使用 `@include skeleton-shimmer`，暖色调闪动
- **下拉刷新**：使用 NutUI 原生 PullRefresh
- **上拉加载**：底部 loading 指示器 + "没有更多了" 文案
- **空状态**：居中图标 + 描述文字 + 可选操作按钮

### 6.4 过渡动画

```scss
// 快速（按钮、hover）
transition: all $transition-fast;  // 0.15s ease-out

// 标准（展开、弹出）
transition: all $transition-base;  // 0.25s ease-out

// 慢速（页面级动画）
transition: all $transition-slow;  // 0.35s ease-out
```

---

## 7. NutUI 主题定制

### 7.1 主题文件

NutUI 主题通过 CSS 变量覆盖，在 `nutui-theme.scss` 中统一管理：

```scss
:root,
page {
  // 品牌色 — 所有 NutUI 组件的主色
  --nutui-brand-color: $color-primary;
  --nutui-brand-color-start: $color-primary-light;
  --nutui-brand-color-end: $color-primary-dark;
  --nutui-brand-link-color: $color-primary;

  // 按钮 — 渐变主按钮
  --nutui-button-primary-background-color: $gradient-primary-h;
  --nutui-button-primary-border-color: $color-primary;

  // 背景与文字
  --nutui-base-background-color: $color-bg;
  --nutui-text-color: $color-text;
  --nutui-sub-text-color: $color-text-secondary;

  // 边框
  --nutui-border-color: $color-border;
  --nutui-cell-divider-color: $color-divider;
}
```

### 7.2 NutUI 组件使用约束

> ⚠️ **导入路径规则**（必须执行）：NutUI 组件必须从 `@nutui/nutui-react-taro` 导入，
> **严禁**从 `@nutui/nutui-react`（Web 版）导入，两者 API 不同。

```tsx
// ✅ 正确
import { Button, Cell, Popup } from '@nutui/nutui-react-taro'

// ❌ 错误 — 这是 Web 版，小程序中会报错
import { Button, Cell, Popup } from '@nutui/nutui-react'
```

### 7.3 常用 NutUI 组件样式覆盖

当 CSS 变量不够用时，通过类名覆盖：

```scss
// 覆盖 NutUI 组件样式时，使用 :global 穿透 CSS Module
:global {
  .nut-button--primary {
    border-radius: $radius-round;
    box-shadow: $shadow-primary;
  }

  .nut-cell {
    background-color: $color-bg-card;
  }
}
```

---

## 8. 渐变使用规范

### 8.1 渐变层级

| 渐变 | 变量 | 场景 | 深度 |
|------|------|------|------|
| 按钮/标签 | `$gradient-primary-h` | 水平，两色柔和 | 浅 |
| 卡片/区块 | `$gradient-primary` | 135°，三色 | 中 |
| 页头/Banner | `$gradient-hero` | 150°，四色 | 深 |
| 个人中心头 | `$gradient-profile` | 150°，四色 | 深 |
| 价格背景 | `$gradient-price-bg` | 极轻暖底 | 极浅 |
| 暖底背景 | `$gradient-warm-bg` | 页面背景微变 | 极浅 |

**规则：**
- 渐变深度与元素面积成反比 — 面积越大（页头），渐变越深
- 按钮用水平渐变（从左到右），面板用对角渐变（135°/150°）
- 渐变最深色不超过 `$color-primary-darker`（`#b84820`），避免过深

### 8.2 图片叠加

商品图底部暗角遮罩：

```scss
.img-overlay {
  background: $gradient-img-overlay;
  // linear-gradient(180deg, transparent 40%, rgba(30, 15, 8, 0.65) 100%)
}
```

---

## 9. BEM 命名规范

所有页面 SCSS 使用 BEM 命名，页面名作为 Block：

```scss
// 页面: pages/index/index.scss
.page-home {
  &__search-bar { ... }
  &__categories { ... }
  &__product-grid { ... }
}

// 页面: packageProduct/pages/detail/index.scss
.page-product-detail {
  &__banner { ... }
  &__price-section { ... }
  &__info-card { ... }
  &__bottom-bar { ... }
}
```

**命名规则：**
- Block：`.page-{页面名}` 或 `.comp-{组件名}`
- Element：`__` 连接（双下划线）
- Modifier：`--` 连接（双横线）
- 避免超过 3 级嵌套

---

## 10. 审查清单

为每个页面/组件的 SCSS 检查以下项目：

- [ ] 顶部引入了 `variables.scss` 和 `mixins.scss`
- [ ] 零硬编码色值（全部使用 `$变量`）
- [ ] 零冷色（无 `#333`, `#999`, `#f5f5f5`, `rgba(0,0,0,...)`）
- [ ] 页面背景使用 `$color-bg`（非 `#fff`）
- [ ] 卡片使用 `@include card-base` 或等效 mixin
- [ ] 可点击元素有按压反馈（`card-pressable` / `brightness` / `opacity`）
- [ ] 触控目标 ≥ 88rpx × 88rpx
- [ ] 底部固定栏包含 `env(safe-area-inset-bottom)`
- [ ] 滚动内容底部留白足够（不被固定栏遮挡）
- [ ] 价格使用 `@include price-text` + `$color-price`
- [ ] 文字截断使用 `@include text-ellipsis`
- [ ] 加载态使用骨架屏（`@include skeleton-shimmer`）
- [ ] BEM 命名一致
- [ ] NutUI 从 `@nutui/nutui-react-taro` 导入（非 Web 版）
- [ ] 划线原价颜色 ≥ `#888b94`（确保对比度 ≥ 3.5:1，不要用 `#999`）

---

## 11. 组件标准尺寸（rpx 参考）

基于微信设计规范和主流电商小程序的实测值：

| 组件 | 高度 | 说明 |
|------|------|------|
| 自定义导航栏（内容区） | 88rpx | 不含状态栏 |
| 底部 TabBar | 98rpx | 标准微信 TabBar |
| 搜索栏 | 64-72rpx | 胶囊圆角 `$radius-round` |
| 列表项（单行） | 88-96rpx | 含 24rpx 上下内边距 |
| 列表项（双行） | 128-136rpx | 标题 + 副标题 |
| 底部操作栏 | 100rpx | 不含安全区 |
| 主按钮（全宽） | 88rpx | `$radius-round` 圆角 |
| 商品卡片图片区 | 340rpx | `overflow: hidden` |
| 商品图片宽高比 | 1:1 | 标准商品网格 |
| 页面水平内边距 | 24-32rpx | 标准页面 padding |
| 双列商品卡间距 | 16rpx | `$spacing-base` / 2 |

---

## 12. 对比度与可读性（WCAG AA）

> ⚠️ **对比度规则**（必须执行）：文字对比度必须满足 WCAG AA 标准。
> 发现不满足时必须主动调整色值并说明原因。

| 文字类型 | 最低对比度 | 项目中的安全色值 |
|----------|-----------|-----------------|
| 正文（< 32rpx） | 4.5:1 | `$color-text`（#3d2e28）→ 白底 12:1 |
| 次级文字 | 4.5:1 | `$color-text-secondary`（#7a6b64）→ 白底 4.8:1 |
| 辅助文字（≥ 32rpx） | 3:1 | `$color-text-light`（#a0948e）→ 白底 3.2:1 |
| 占位符（禁用态） | 不强制 | `$color-text-placeholder`（#c4b8b2）→ 1.9:1 |
| 价格红字 | 4.5:1 | `$color-price`（#f5222d）→ 白底 4.6:1 |
| 白字在暗角遮罩上 | 4.5:1 | 白色 → rgba(30,15,8,0.65) ≈ 7:1 |

**注意：** `$color-text-light` 仅用于 ≥ 32rpx 的大号辅助文字，小号文字必须用 `$color-text-secondary` 或更深。

---

## 13. 电商 UI 高频模式速查

### 价格区块

```scss
.price-block {
  background: $gradient-price-bg;  // 极轻暖底
  border-radius: $radius-base;
  padding: $spacing-sm $spacing-base;

  &__current {
    @include price-text($font-size-hero);  // ¥ 用 $font-size-sm
  }
  &__original {
    font-size: $font-size-sm;
    color: $color-text-light;  // ≥ 32rpx 场景
    text-decoration: line-through;
  }
  &__discount {
    display: inline-flex;
    background: rgba(245, 34, 45, 0.10);
    color: $color-price;
    font-size: $font-size-xs;
    padding: 2rpx $spacing-xs;
    border-radius: $radius-xs;
  }
}
```

### 订单状态步骤条

```scss
.order-steps {
  display: flex;
  justify-content: space-between;
  padding: $spacing-base;

  &__step {
    text-align: center;
    color: $color-text-placeholder;  // 未来步骤
    font-size: $font-size-xs;

    &--active {
      color: $color-primary;
      font-weight: 600;
    }
    &--done {
      color: $color-success;
    }
  }
}
```

### 空状态

```scss
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: $spacing-2xl $spacing-lg;

  &__icon {
    width: 200rpx;
    height: 200rpx;
    margin-bottom: $spacing-md;
  }
  &__title {
    font-size: $font-size-lg;
    color: $color-text;
    margin-bottom: $spacing-xs;
  }
  &__desc {
    font-size: $font-size-sm;
    color: $color-text-light;
    margin-bottom: $spacing-md;
  }
  &__action {
    @include gradient-btn;
    padding: $spacing-xs $spacing-lg;
    font-size: $font-size-base;
  }
}
