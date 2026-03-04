/**
 * BindPhone 手机号授权绑定组件
 *
 * 用途：引导用户通过微信授权获取手机号，后端解密后绑定到账户。
 * 安全：不传明文手机号，仅传 encryptedData + iv（由后端服务端解密）。
 * 样式：使用 NutUI React Taro Button 组件。
 * 状态：授权成功后通过 Zustand useAuthStore 更新 user 信息，并跳转首页。
 */

import { useState } from 'react'
import { View, Text } from '@tarojs/components'
import Taro from '@tarojs/taro'
import { Button } from '@nutui/nutui-react-taro'
import type { User } from '@daigou/shared'
import { ErrorCode } from '@daigou/shared'
import { request } from '../../services/request'
import { useAuthStore } from '../../stores/useAuthStore'

// ─── 类型定义 ─────────────────────────────────────────────────────────────────

/** 微信 getPhoneNumber 事件回调的 detail 结构 */
interface GetPhoneNumberEventDetail {
  /** 加密手机号数据（微信加密，后端解密） */
  encryptedData: string
  /** 加密算法初始向量 */
  iv: string
  /** 微信云托管环境下的手机号（仅新版 API 有效，与 encryptedData 互斥） */
  code?: string
  /** 错误信息（用户拒绝授权时存在） */
  errMsg: string
}

/** 后端 bind-phone 接口返回的业务数据 */
interface BindPhoneResponse {
  user: User
}

// ─── 组件 ─────────────────────────────────────────────────────────────────────

interface BindPhoneProps {
  /**
   * 授权成功后的自定义回调，优先于默认跳转首页行为。
   * 若不传，则默认 switchTab 跳转到 /pages/index/index。
   */
  onSuccess?: (user: User) => void
  /** 授权失败/用户拒绝后的回调（可选） */
  onFail?: (reason: string) => void
  /** 按钮文案，默认「授权手机号」 */
  buttonText?: string
  /** 按钮类型，默认 primary */
  buttonType?: 'primary' | 'default' | 'info' | 'warning' | 'danger'
}

/**
 * 手机号授权绑定组件
 *
 * 使用方式：
 * ```tsx
 * <BindPhone
 *   buttonText="绑定手机号"
 *   onSuccess={(user) => console.log('绑定成功', user)}
 * />
 * ```
 *
 * 安全说明：
 * - 组件不直接处理或存储明文手机号
 * - 仅将微信加密的 encryptedData + iv 发送给后端
 * - 后端使用 session_key 解密，脱敏后更新用户记录并返回
 */
export default function BindPhone({
  onSuccess,
  onFail,
  buttonText = '授权手机号',
  buttonType = 'primary',
}: BindPhoneProps) {
  const [loading, setLoading] = useState(false)
  const { token, setUser } = useAuthStore()

  /**
   * 调用后端绑定接口。
   * 仅传递微信加密凭证，绝不传明文手机号。
   */
  const callBindPhoneApi = async (
    encryptedData: string,
    iv: string,
    code?: string,
  ): Promise<void> => {
    // 构建请求体：优先使用新版 code 方式，降级使用 encryptedData + iv
    const payload: Record<string, unknown> = code
      ? { code }
      : { encryptedData, iv }

    const res = await request<BindPhoneResponse>({
      url: '/api/auth/bind-phone',
      method: 'POST',
      data: payload,
      // 此接口需要登录态（携带 Bearer Token）
      skipAuth: false,
    })

    if (res.code !== ErrorCode.SUCCESS) {
      throw new Error(res.message || '绑定手机号失败，请稍后重试')
    }

    // 更新本地 Zustand 用户状态（含脱敏手机号）
    const updatedUser = res.data.user
    setUser(updatedUser)

    if (onSuccess) {
      onSuccess(updatedUser)
    } else {
      // 默认跳转首页 Tab
      Taro.switchTab({ url: '/pages/index/index' })
    }
  }

  /**
   * 微信 getPhoneNumber 授权回调。
   * 微信基础库 >= 2.21.2 后，encryptedData 方案依然兼容；
   * 新版小程序建议后端使用 code 换取手机号（更安全）。
   */
  const handleGetPhoneNumber = async (event: {
    detail: GetPhoneNumberEventDetail
  }) => {
    const { detail } = event

    // 用户拒绝授权，errMsg 会包含 'fail'
    if (!detail.encryptedData && !detail.code) {
      const reason = detail.errMsg || '用户取消了手机号授权'
      Taro.showToast({ title: '需要手机号才能继续使用', icon: 'none', duration: 2000 })
      onFail?.(reason)
      return
    }

    if (!token) {
      // 未登录状态下不应出现此组件，做防御性校验
      Taro.showToast({ title: '请先完成微信登录', icon: 'none', duration: 2000 })
      onFail?.('未登录')
      return
    }

    setLoading(true)
    try {
      await callBindPhoneApi(detail.encryptedData, detail.iv, detail.code)
      Taro.showToast({ title: '手机号绑定成功', icon: 'success', duration: 1500 })
    } catch (err) {
      const message = err instanceof Error ? err.message : '绑定失败，请重试'
      Taro.showToast({ title: message, icon: 'none', duration: 2000 })
      onFail?.(message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <View className="bind-phone">
      {/*
       * NutUI Button 通过 openType="getPhoneNumber" 触发微信授权弹窗。
       * 注意：
       *   1. open-type 按钮必须是用户直接点击触发，不能通过程序模拟点击
       *   2. onGetPhoneNumber 仅在用户确认授权后由微信框架调用
       *   3. 按钮样式不能完全隐藏（opacity:0 覆盖方案在此项目中不使用）
       */}
      <Button
        type={buttonType}
        openType="getPhoneNumber"
        onGetPhoneNumber={handleGetPhoneNumber}
        loading={loading}
        disabled={loading}
        block
      >
        {loading ? '绑定中...' : buttonText}
      </Button>

      <View className="bind-phone__tip">
        <Text className="bind-phone__tip-text">
          我们仅获取您的手机号用于账号绑定，不会泄露给第三方
        </Text>
      </View>
    </View>
  )
}
