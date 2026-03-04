export default defineAppConfig({
  // =========================================================
  // 主包：仅保留 TabBar 页面（首页、分类、购物车、个人中心）
  // 目标主包体积 < 2MB
  // =========================================================
  pages: [
    'pages/index/index',      // 首页（TabBar）
    'pages/category/index',   // 分类（TabBar）
    'pages/cart/index',       // 购物车（TabBar）
    'pages/profile/index',    // 个人中心（TabBar）
  ],

  // =========================================================
  // 分包配置
  // =========================================================
  subPackages: [
    // --------------------------------------------------
    // 商品分包：与商品浏览直接相关的页面
    // 进入路径：首页 → 商品详情 / 搜索
    // --------------------------------------------------
    {
      root: 'packageProduct',
      name: 'product',
      pages: [
        'pages/detail/index',   // 商品详情
        'pages/search/index',   // 搜索
        'pages/shop/index',     // 店铺主页
      ],
    },

    // --------------------------------------------------
    // 订单分包：下单、支付、订单查看核心链路
    // 进入路径：购物车 → 结算 → 订单列表 → 订单详情
    // --------------------------------------------------
    {
      root: 'packageOrder',
      name: 'order',
      pages: [
        'pages/checkout/index',   // 结算（下单）
        'pages/list/index',       // 订单列表
        'pages/detail/index',     // 订单详情
        'pages/proxy-pay/index',  // 代付（转账确认）
      ],
    },

    // --------------------------------------------------
    // 售后分包：退款/退货/客服，低频但独立的场景
    // 进入路径：订单详情 → 申请退款 → 退款详情 / 退货物流 / 客服聊天
    // --------------------------------------------------
    {
      root: 'packageAftersale',
      name: 'aftersale',
      pages: [
        'pages/refund-apply/index',    // 申请退款
        'pages/refund-detail/index',   // 退款详情
        'pages/return-shipping/index', // 退货物流
        'pages/chat/index',            // 客服聊天
        'pages/message-list/index',    // 消息列表
      ],
    },

    // --------------------------------------------------
    // 设置分包：地址、证件、账号设置等低频功能
    // 进入路径：个人中心 → 各设置项
    // --------------------------------------------------
    {
      root: 'packageSettings',
      name: 'settings',
      pages: [
        'pages/address-list/index',  // 地址列表
        'pages/address-edit/index',  // 地址编辑（新增/修改）
        'pages/idcard-list/index',   // 证件列表
        'pages/idcard-edit/index',   // 证件编辑
        'pages/settings/index',      // 设置
        'pages/agreement/index',     // 用户协议
        'pages/privacy/index',       // 隐私政策
        'pages/about/index',         // 关于我们
      ],
    },
  ],

  // =========================================================
  // 分包预下载策略
  // 原则：预加载用户"高概率下一步"访问的分包，但不在主包启动时
  // 全量预加载（避免浪费流量）。
  //
  // 预加载时机说明：
  //   - network: 'all'  → Wi-Fi + 移动网络均可预加载
  //   - network: 'wifi' → 仅 Wi-Fi 预加载（节省流量）
  // =========================================================
  preloadRule: {
    // 首页加载完成后 → 预加载「商品分包」
    // 理由：用户浏览首页后大概率点击商品详情或搜索
    'pages/index/index': {
      network: 'all',
      packages: ['product'],
    },

    // 购物车加载完成后 → 预加载「订单分包」
    // 理由：购物车下一步高概率是结算/下单
    'pages/cart/index': {
      network: 'all',
      packages: ['order'],
    },

    // 个人中心加载完成后 → 预加载「设置分包」
    // 理由：个人中心入口聚集了设置相关的所有功能
    'pages/profile/index': {
      network: 'wifi',
      packages: ['settings'],
    },

    // 订单详情页加载后 → 预加载「售后分包」
    // 理由：查看订单详情后可能发起退款/联系客服
    'packageOrder/pages/detail/index': {
      network: 'wifi',
      packages: ['aftersale'],
    },
  },

  // =========================================================
  // 全局窗口配置
  // =========================================================
  window: {
    backgroundTextStyle: 'light',
    navigationBarBackgroundColor: '#ffffff',
    navigationBarTitleText: '',
    navigationBarTextStyle: 'black',
    navigationStyle: 'custom',
  },

  // =========================================================
  // TabBar 配置（仅 TabBar 页面可放主包）
  // =========================================================
  tabBar: {
    color: '#999999',
    selectedColor: '#FF6B35',
    backgroundColor: '#ffffff',
    borderStyle: 'black',
    list: [
      {
        pagePath: 'pages/index/index',
        text: '首页',
        iconPath: 'assets/tab/home.png',
        selectedIconPath: 'assets/tab/home-active.png',
      },
      {
        pagePath: 'pages/category/index',
        text: '分类',
        iconPath: 'assets/tab/category.png',
        selectedIconPath: 'assets/tab/category-active.png',
      },
      {
        pagePath: 'pages/cart/index',
        text: '购物车',
        iconPath: 'assets/tab/cart.png',
        selectedIconPath: 'assets/tab/cart-active.png',
      },
      {
        pagePath: 'pages/profile/index',
        text: '我的',
        iconPath: 'assets/tab/profile.png',
        selectedIconPath: 'assets/tab/profile-active.png',
      },
    ],
  },
})
