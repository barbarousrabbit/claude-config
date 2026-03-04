import { create } from 'zustand'
import { persist, createJSONStorage, StateStorage } from 'zustand/middleware'
import Taro from '@tarojs/taro'

/**
 * 微信小程序同步存储适配器
 *
 * 原因：微信小程序运行环境中不存在浏览器的 localStorage / sessionStorage API，
 * 直接使用 createJSONStorage(() => localStorage) 会导致 localStorage 为 undefined，
 * 每次读取都返回 null，从而使持久化完全失效。
 *
 * 此适配器将 Zustand persist 中间件所需的 Web Storage 接口
 * (getItem / setItem / removeItem) 映射到微信小程序的同步存储 API：
 * - wx.getStorageSync  / Taro.getStorageSync
 * - wx.setStorageSync  / Taro.setStorageSync
 * - wx.removeStorageSync / Taro.removeStorageSync
 */
const taroStorage: StateStorage = {
  getItem(key: string): string | null {
    try {
      const value = Taro.getStorageSync(key)
      // getStorageSync 在 key 不存在时返回空字符串 ''，需统一转为 null
      return value !== '' && value !== undefined && value !== null
        ? (value as string)
        : null
    } catch (e) {
      console.error(`[AuthStore] 读取存储失败 key=${key}`, e)
      return null
    }
  },

  setItem(key: string, value: string): void {
    try {
      Taro.setStorageSync(key, value)
    } catch (e) {
      console.error(`[AuthStore] 写入存储失败 key=${key}`, e)
    }
  },

  removeItem(key: string): void {
    try {
      Taro.removeStorageSync(key)
    } catch (e) {
      console.error(`[AuthStore] 删除存储失败 key=${key}`, e)
    }
  },
}

interface AuthState {
  token: string | null
  userId: string | null
  setToken: (token: string) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      userId: null,
      setToken: (token) => set({ token }),
      logout: () => set({ token: null, userId: null }),
    }),
    {
      name: 'auth-storage',
      // 使用适配了微信小程序同步存储 API 的自定义 storage，
      // 替换掉在小程序环境中不存在的 localStorage
      storage: createJSONStorage(() => taroStorage),
    }
  )
)
