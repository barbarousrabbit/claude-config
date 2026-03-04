import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import Taro from '@tarojs/taro'

// 微信小程序环境没有 localStorage / sessionStorage。
// 必须使用 Taro 封装的同步存储 API 作为 zustand persist 的 storage 适配器。
const taroStorage = {
  getItem: (key: string): string | null => {
    return Taro.getStorageSync(key) ?? null
  },
  setItem: (key: string, value: string): void => {
    Taro.setStorageSync(key, value)
  },
  removeItem: (key: string): void => {
    Taro.removeStorageSync(key)
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
      storage: createJSONStorage(() => taroStorage),
    }
  )
)
