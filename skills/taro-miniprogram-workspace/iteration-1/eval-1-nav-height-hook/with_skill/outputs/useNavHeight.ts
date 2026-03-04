/**
 * useNavHeight - 自定义导航栏高度计算 Hook
 *
 * 解决问题：
 * 1. 自定义导航栏内容与右上角胶囊按钮重叠
 * 2. iOS 与 Android 导航栏高度不一致
 * 3. 刘海屏 / 挖孔屏的安全区顶部内边距差异
 *
 * 计算公式（来自微信官方推荐做法）：
 *   状态栏高度 = systemInfo.statusBarHeight
 *   胶囊按钮信息 = Taro.getMenuButtonBoundingClientRect()
 *   导航内容区高度 = capsule.height + (capsule.top - statusBarHeight) * 2
 *   导航栏总高度 = 状态栏高度 + 导航内容区高度
 */

import Taro from '@tarojs/taro'
import { useState, useEffect } from 'react'

/** Hook 返回值类型 */
export interface NavHeightResult {
  /** 导航栏总高度（含状态栏），单位 px，直接设置为自定义导航栏容器的高度 */
  navHeight: number
  /** 状态栏高度（即顶部安全区高度），单位 px */
  statusBarHeight: number
  /** 导航内容区高度（胶囊按钮所在行的高度），单位 px */
  navContentHeight: number
  /**
   * 内容区顶部内边距，单位 px
   * 使用方式：页面主体内容的 paddingTop 设置为此值，确保不被导航栏遮挡
   */
  contentPaddingTop: number
}

/**
 * 默认兜底值
 * - iOS 默认状态栏 44px，导航内容区 44px，总高 88px
 * - 若 API 调用失败，使用这些值确保基本可用
 */
const DEFAULT_STATUS_BAR_HEIGHT = 44
const DEFAULT_NAV_CONTENT_HEIGHT = 44

/**
 * 计算导航栏高度信息
 * 封装为纯函数便于测试和复用
 */
function calcNavHeight(): NavHeightResult {
  let statusBarHeight = DEFAULT_STATUS_BAR_HEIGHT
  let navContentHeight = DEFAULT_NAV_CONTENT_HEIGHT

  try {
    // 第一步：获取系统信息（状态栏高度因机型和 iOS/Android 差异较大）
    const sysInfo = Taro.getSystemInfoSync()
    statusBarHeight = sysInfo.statusBarHeight ?? DEFAULT_STATUS_BAR_HEIGHT

    // 第二步：获取胶囊按钮的位置和尺寸
    // getMenuButtonBoundingClientRect 在真机上始终可用，模拟器可能返回 0
    const capsule = Taro.getMenuButtonBoundingClientRect()

    if (capsule && capsule.top > 0 && capsule.height > 0) {
      /**
       * 核心公式：
       *   胶囊按钮距状态栏底部的间距 = capsule.top - statusBarHeight
       *   导航内容区高度 = 胶囊高度 + 上下各一份间距（对称）
       *                  = capsule.height + (capsule.top - statusBarHeight) * 2
       *
       * 这样计算可以保证胶囊按钮垂直居中于导航内容区，
       * 同时右侧内容不会超过胶囊左边缘（需配合 paddingRight 处理）
       */
      const capsuleMarginTop = capsule.top - statusBarHeight
      navContentHeight = capsule.height + capsuleMarginTop * 2
    } else {
      /**
       * 兜底：模拟器或 API 异常时，Android 默认导航内容区 48px，iOS 默认 44px
       * platform 字段标识平台：'android' / 'ios' / 'devtools'
       */
      const platform = (sysInfo.platform ?? '').toLowerCase()
      navContentHeight = platform === 'android' ? 48 : DEFAULT_NAV_CONTENT_HEIGHT
    }
  } catch (error) {
    // API 调用失败（极少见），使用全部默认值，打印警告供调试
    console.warn('[useNavHeight] 获取导航栏高度失败，使用默认值', error)
  }

  const navHeight = statusBarHeight + navContentHeight

  return {
    navHeight,
    statusBarHeight,
    navContentHeight,
    contentPaddingTop: navHeight,
  }
}

/**
 * useNavHeight Hook
 *
 * @example
 * ```tsx
 * // 自定义导航栏组件
 * function CustomNavBar({ title }: { title: string }) {
 *   const { navHeight, statusBarHeight, navContentHeight } = useNavHeight()
 *
 *   return (
 *     <View style={{ height: `${navHeight}px`, background: '#fff' }}>
 *       {// 状态栏占位，高度等于系统状态栏}
 *       <View style={{ height: `${statusBarHeight}px` }} />
 *       {// 导航内容区：标题居中，右侧留出胶囊宽度（约 87px）避免重叠}
 *       <View
 *         style={{
 *           height: `${navContentHeight}px`,
 *           display: 'flex',
 *           alignItems: 'center',
 *           paddingRight: '95px',  // 胶囊宽度 87px + 额外间距 8px
 *         }}
 *       >
 *         <Text>{title}</Text>
 *       </View>
 *     </View>
 *   )
 * }
 *
 * // 页面主体内容区域
 * function MyPage() {
 *   const { contentPaddingTop } = useNavHeight()
 *
 *   return (
 *     <View style={{ paddingTop: `${contentPaddingTop}px` }}>
 *       {// 页面内容不会被导航栏遮挡}
 *     </View>
 *   )
 * }
 * ```
 */
export function useNavHeight(): NavHeightResult {
  // 初始值在 useState 中直接计算，避免第一帧出现高度为 0 的闪烁
  // getSystemInfoSync 和 getMenuButtonBoundingClientRect 均为同步 API，可在渲染前调用
  const [result, setResult] = useState<NavHeightResult>(() => calcNavHeight())

  useEffect(() => {
    /**
     * 在 useEffect 中再次计算并更新，原因：
     * 1. 部分 Android 机型在 SSR/hydration 阶段系统信息可能尚未完全初始化
     * 2. 横竖屏切换时需要重新计算（小程序中较少见，保留扩展点）
     */
    const latest = calcNavHeight()

    // 仅在值发生变化时更新，避免不必要的重渲染
    setResult((prev) => {
      if (
        prev.navHeight === latest.navHeight &&
        prev.statusBarHeight === latest.statusBarHeight &&
        prev.navContentHeight === latest.navContentHeight
      ) {
        return prev
      }
      return latest
    })
  }, [])

  return result
}

export default useNavHeight
