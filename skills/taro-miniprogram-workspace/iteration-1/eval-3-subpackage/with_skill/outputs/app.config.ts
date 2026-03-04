export default defineAppConfig({
  // 主包：仅保留 Tab Bar 页面（首页 / 购物车 / 个人中心）
  // 这三个页面是用户打开小程序必然加载的，放入主包是正确的。
  // 其余所有页面按使用场景拆入分包，确保主包 < 2MB。
  pages: [
    'pages/home/index',
    'pages/cart/index',
    'pages/profile/index',
  ],

  // ── 分包规划 ──────────────────────────────────────────────
  // packageProduct  商品浏览链路（从首页进入，高频但非启动必须）
  // packageOrder    订单管理链路（从购物车/个人中心进入）
  // packageRefund   售后链路（从订单详情进入，低频）
  // packageService  服务与设置（客服聊天、收货地址、设置）
  subPackages: [
    {
      // 商品分包：搜索 + 商品详情
      // 从首页跳入，高频，建议在首页预加载
      root: 'packageProduct',
      pages: [
        'search/index',         // 搜索页
        'product-detail/index', // 商品详情
      ],
    },
    {
      // 订单分包：订单列表 + 订单详情 + 结算
      // 从购物车 / 个人中心跳入
      root: 'packageOrder',
      pages: [
        'order-list/index',   // 订单列表
        'order-detail/index', // 订单详情
        'checkout/index',     // 结算页
      ],
    },
    {
      // 售后分包：申请退款 + 退款详情 + 退货物流
      // 从订单详情跳入，属于低频售后链路
      root: 'packageRefund',
      pages: [
        'refund-apply/index',    // 申请退款
        'refund-detail/index',   // 退款详情
        'return-logistics/index', // 退货物流
      ],
    },
    {
      // 服务分包：客服聊天 + 收货地址 + 设置
      // 客服聊天包含 WebSocket，体积较大，单独拆出避免影响其他分包
      root: 'packageService',
      pages: [
        'customer-service/index', // 客服聊天（WebSocket，体积较重）
        'address-list/index',     // 地址列表
        'address-edit/index',     // 地址编辑
        'settings/index',         // 设置
      ],
    },
  ],

  // ── 预加载规则 ─────────────────────────────────────────────
  // 预加载在页面展示时触发，利用空闲带宽提前下载分包，减少跳转等待。
  // 策略：在最可能的「上游页面」上预加载「下游分包」。
  preloadRule: {
    // 首页：用户极大概率会点击搜索或商品，预加载商品分包
    'pages/home/index': {
      network: 'all',      // wifi + 4G 均预加载（商品分包是核心体验）
      packages: ['packageProduct'],
    },
    // 购物车：用户即将结算，预加载订单分包
    'pages/cart/index': {
      network: 'all',
      packages: ['packageOrder'],
    },
    // 个人中心：用户查看历史订单概率高，预加载订单分包；
    //          同时预加载服务分包（地址/设置入口在此页面）
    'pages/profile/index': {
      network: 'wifi',     // 两个分包同时预加载，仅在 wifi 下进行，避免消耗流量
      packages: ['packageOrder', 'packageService'],
    },
    // 订单详情：用户有可能发起售后，预加载售后分包
    'packageOrder/order-detail/index': {
      network: 'wifi',
      packages: ['packageRefund'],
    },
  },

  // ── 全局窗口配置 ───────────────────────────────────────────
  window: {
    backgroundTextStyle: 'light',
    navigationBarBackgroundColor: '#ffffff',
    navigationBarTitleText: '代购',
    navigationBarTextStyle: 'black',
    navigationStyle: 'custom', // 自定义导航栏，避开胶囊按钮区域
  },

  // ── Tab Bar ────────────────────────────────────────────────
  tabBar: {
    color: '#999999',
    selectedColor: '#FF6B35',
    backgroundColor: '#ffffff',
    borderStyle: 'black',
    list: [
      {
        pagePath: 'pages/home/index',
        text: '首页',
        iconPath: 'assets/tabbar/home.png',
        selectedIconPath: 'assets/tabbar/home-active.png',
      },
      {
        pagePath: 'pages/cart/index',
        text: '购物车',
        iconPath: 'assets/tabbar/cart.png',
        selectedIconPath: 'assets/tabbar/cart-active.png',
      },
      {
        pagePath: 'pages/profile/index',
        text: '我的',
        iconPath: 'assets/tabbar/profile.png',
        selectedIconPath: 'assets/tabbar/profile-active.png',
      },
    ],
  },
})
