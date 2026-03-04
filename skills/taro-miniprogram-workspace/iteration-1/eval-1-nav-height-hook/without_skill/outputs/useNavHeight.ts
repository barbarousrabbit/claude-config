/**
 * useNavHeight - 自定义导航栏高度计算 Hook
 *
 * 解决问题：
 * 1. iOS（如 iPhone 15 Pro）右侧胶囊按钮遮挡自定义导航栏按钮
 * 2. Android / iOS 导航栏高度不一致
 * 3. 刘海屏、动态岛设备的安全区适配
 *
 * 核心思路：
 * - 通过 Taro.getMenuButtonBoundingClientRect() 获取胶囊按钮的位置信息
 * - 通过 Taro.getSystemInfoSync() 获取状态栏高度（statusBarHeight）
 * - 导航栏内容区高度 = (胶囊底部 - 胶囊顶部) + (胶囊顶部 - 状态栏高度) * 2
 *   即：让内容区在胶囊按钮上下方向垂直居中
 * - 导航栏总高度 = 状态栏高度 + 导航栏内容区高度
 */

import { useEffect, useState } from 'react'
import Taro from '@tarojs/taro'

/** 导航栏尺寸信息 */
export interface NavHeightInfo {
  /** 状态栏高度（px），即顶部信号栏区域 */
  statusBarHeight: number
  /** 导航栏内容区高度（px），即放置标题/按钮的区域，不含状态栏 */
  navBarHeight: number
  /** 导航栏总高度（px）= statusBarHeight + navBarHeight */
  totalHeight: number
  /**
   * 胶囊按钮右侧到屏幕右边缘的距离（px）
   * 自定义导航栏右侧按钮需留出此宽度，避免与胶囊重叠
   */
  menuButtonRight: number
  /**
   * 胶囊按钮左侧到屏幕左边缘的距离（px）
   * 即右侧可用区域从 0 到 (屏幕宽度 - menuButtonRight - 胶囊宽度) 的宽度
   * 快捷字段：导航栏右侧内容区的可用右边界
   */
  menuButtonLeft: number
  /** 胶囊按钮的宽度（px） */
  menuButtonWidth: number
  /** 胶囊按钮的高度（px） */
  menuButtonHeight: number
  /** 屏幕宽度（px） */
  screenWidth: number
  /** 是否已成功获取胶囊按钮信息（false 时使用降级默认值） */
  menuButtonAvailable: boolean
}

/**
 * 不同平台的降级默认值
 * 当 getMenuButtonBoundingClientRect 不可用时使用
 */
const FALLBACK_DEFAULTS = {
  ios: {
    statusBarHeight: 44,  // iPhone X 及以后的标准状态栏高度
    navBarHeight: 44,     // iOS 标准导航栏内容高度
  },
  android: {
    statusBarHeight: 24,  // Android 标准状态栏高度
    navBarHeight: 48,     // Android Material Design 标准 AppBar 高度
  },
} as const

/**
 * 计算导航栏高度信息（非 Hook 版本，可在非组件环境调用）
 *
 * @returns NavHeightInfo 导航栏尺寸信息对象
 */
export function calcNavHeight(): NavHeightInfo {
  let systemInfo: Taro.getSystemInfoSync.Result
  let platform: 'ios' | 'android' = 'android'

  try {
    systemInfo = Taro.getSystemInfoSync()
    // Taro/微信小程序中 platform 值为 'ios' | 'android' | 'devtools' 等
    platform = systemInfo.platform?.toLowerCase().includes('ios') ? 'ios' : 'android'
  } catch {
    // 极端情况：getSystemInfoSync 失败，返回保守默认值
    return {
      statusBarHeight: 24,
      navBarHeight: 48,
      totalHeight: 72,
      menuButtonRight: 7,
      menuButtonLeft: 295,
      menuButtonWidth: 88,
      menuButtonHeight: 32,
      screenWidth: 390,
      menuButtonAvailable: false,
    }
  }

  const statusBarHeight = systemInfo.statusBarHeight ?? FALLBACK_DEFAULTS[platform].statusBarHeight
  const screenWidth = systemInfo.screenWidth ?? 390

  try {
    // 获取胶囊按钮位置（仅微信小程序支持）
    const menuButtonRect = Taro.getMenuButtonBoundingClientRect()

    // 校验胶囊数据合理性：top 必须大于 statusBarHeight，否则数据异常
    if (
      menuButtonRect &&
      menuButtonRect.top > 0 &&
      menuButtonRect.width > 0 &&
      menuButtonRect.height > 0 &&
      menuButtonRect.top >= statusBarHeight
    ) {
      /**
       * 计算导航栏内容区高度：
       * 微信胶囊按钮在垂直方向上应位于导航栏内容区的正中央
       * 胶囊顶部距状态栏底部的间距 = menuButtonRect.top - statusBarHeight
       * 内容区高度 = 胶囊高度 + 上下间距 * 2
       */
      const menuButtonTopMargin = menuButtonRect.top - statusBarHeight
      const navBarHeight = menuButtonRect.height + menuButtonTopMargin * 2

      return {
        statusBarHeight,
        navBarHeight,
        totalHeight: statusBarHeight + navBarHeight,
        menuButtonRight: screenWidth - menuButtonRect.right,
        menuButtonLeft: menuButtonRect.left,
        menuButtonWidth: menuButtonRect.width,
        menuButtonHeight: menuButtonRect.height,
        screenWidth,
        menuButtonAvailable: true,
      }
    }
  } catch {
    // getMenuButtonBoundingClientRect 不支持（如非微信环境），使用降级值
  }

  // 降级处理：使用平台默认值
  const fallback = FALLBACK_DEFAULTS[platform]
  const navBarHeight = fallback.navBarHeight

  return {
    statusBarHeight,
    navBarHeight,
    totalHeight: statusBarHeight + navBarHeight,
    // 降级时胶囊右间距使用微信标准值 7px
    menuButtonRight: 7,
    // 降级时胶囊左边界估算（屏幕宽度 - 右间距 - 标准胶囊宽度 87px）
    menuButtonLeft: screenWidth - 7 - 87,
    menuButtonWidth: 87,
    menuButtonHeight: 32,
    screenWidth,
    menuButtonAvailable: false,
  }
}

/**
 * useNavHeight - 自定义导航栏高度计算 Hook
 *
 * @example
 * ```tsx
 * import { useNavHeight } from '@/hooks/useNavHeight'
 *
 * export default function CustomNavBar() {
 *   const { statusBarHeight, navBarHeight, totalHeight, menuButtonLeft } = useNavHeight()
 *
 *   return (
 *     <View style={{ height: `${totalHeight}px`, paddingTop: `${statusBarHeight}px` }}>
 *       {// 内容区高度为 navBarHeight，右侧按钮不超过 menuButtonLeft}
 *       <View style={{ height: `${navBarHeight}px`, display: 'flex', alignItems: 'center' }}>
 *         <Text>页面标题</Text>
 *       </View>
 *     </View>
 *   )
 * }
 * ```
 *
 * @returns NavHeightInfo 导航栏尺寸信息，组件挂载后立即可用
 */
export function useNavHeight(): NavHeightInfo {
  // 在 useState 初始化时同步计算，避免首帧闪烁（高度为 0 再跳变）
  const [navHeightInfo] = useState<NavHeightInfo>(() => calcNavHeight())

  // 注意：导航栏高度在同一设备上不会变化（旋转屏幕除外），无需监听变化
  // 若需支持横竖屏切换，可在此添加 Taro.onWindowResize 监听

  return navHeightInfo
}

export default useNavHeight
