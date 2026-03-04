/**
 * BindPhone 组件 —— 用户手机号授权绑定
 *
 * 安全说明：
 *   - 绝不传明文手机号；仅将微信加密凭证（code + encryptedData + iv）发给后端
 *   - 后端持 AppSecret 解密，再写入数据库
 *   - 前端只存 JWT Token，不存 openid 或手机号原文
 */

import { View, Text } from '@tarojs/components'
import Taro from '@tarojs/taro'
import { useState, useCallback } from 'react'
import { Button, Toast } from '@nutui/nutui-react-taro'
import { useAuthStore } from '@/stores/auth.store'
import styles from './BindPhone.module.scss'

// ─────────────────────────────────────────────────────────────────────────────
// 类型定义
// ─────────────────────────────────────────────────────────────────────────────

interface PhoneNumberEventDetail {
  /** 微信一次性凭证，用于后端换取用户标识（getPhoneNumber 场景） */
  code: string
  /** 已废弃的加密数据字段，仍保留以兼容旧版基础库 */
  encryptedData?: string
  /** 已废弃的 iv 字段，仍保留以兼容旧版基础库 */
  iv?: string
  /** 微信错误信息（授权失败时） */
  errMsg: string
}

interface BindPhoneResponse {
  token: string
  userId: string
}

// ─────────────────────────────────────────────────────────────────────────────
// 工具：请求后端绑定手机号接口
// ─────────────────────────────────────────────────────────────────────────────

/**
 * 调用后端 /api/auth/bind-phone 接口
 *
 * 安全要点：
 *  1. 仅传加密凭证（code / encryptedData / iv），不传明文手机号
 *  2. 请求头携带当前 token（如已登录），供后端关联账号
 *  3. 接口须在后端做速率限制（Rate Limiting），防爆破
 */
async function bindPhoneRequest(
  params: {
    code: string
    encryptedData?: string
    iv?: string
  },
  token: string | null,
): Promise<BindPhoneResponse> {
  const BASE_URL = process.env.TARO_APP_API_BASE_URL ?? ''

  const res = await Taro.request<BindPhoneResponse>({
    url: `${BASE_URL}/api/auth/bind-phone`,
    method: 'POST',
    header: {
      'Content-Type': 'application/json',
      // 若已有 token，携带以便后端将手机号绑定到现有账号
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    data: params,
  })

  if (res.statusCode !== 200 && res.statusCode !== 201) {
    const msg: string =
      (res.data as any)?.message ?? `请求失败（${res.statusCode}）`
    throw new Error(msg)
  }

  if (!res.data?.token) {
    throw new Error('服务器返回数据异常，缺少 token')
  }

  return res.data
}

// ─────────────────────────────────────────────────────────────────────────────
// 主组件
// ─────────────────────────────────────────────────────────────────────────────

export default function BindPhone() {
  const [loading, setLoading] = useState(false)
  const { token, setToken } = useAuthStore()

  /**
   * 处理微信手机号授权回调
   *
   * 注意：
   *  - 微信基础库 2.21.2 起推荐用 code 模式（一次性凭证）；
   *    旧版 encryptedData + iv 模式仍作为兼容 fallback 保留
   *  - 若用户拒绝授权（errMsg 不含 'ok'），直接提示并返回
   */
  const handleGetPhoneNumber = useCallback(
    async (e: { detail: PhoneNumberEventDetail }) => {
      const { code, encryptedData, iv, errMsg } = e.detail

      // 1. 检查用户是否拒绝授权
      if (!errMsg.includes('ok')) {
        Toast.show({ content: '您已取消授权，无法绑定手机号', icon: 'fail' })
        return
      }

      // 2. 基础库版本校验：code 模式（推荐）或 encryptedData 模式（兼容）
      if (!code && !encryptedData) {
        Toast.show({ content: '获取授权信息失败，请重试', icon: 'fail' })
        return
      }

      setLoading(true)

      try {
        // 3. 调用后端解密接口，只传加密凭证，不传明文手机号
        const result = await bindPhoneRequest({ code, encryptedData, iv }, token)

        // 4. 将后端返回的 JWT Token 存入 Zustand（持久化到微信 Storage）
        setToken(result.token)

        Toast.show({ content: '手机号绑定成功', icon: 'success' })

        // 5. 延迟 800ms 让 Toast 展示后再跳转，避免闪烁
        setTimeout(() => {
          Taro.switchTab({ url: '/pages/index/index' })
        }, 800)
      } catch (err: unknown) {
        const message =
          err instanceof Error ? err.message : '绑定失败，请稍后重试'
        Toast.show({ content: message, icon: 'fail' })
        console.error('[BindPhone] 手机号绑定失败', { err })
      } finally {
        setLoading(false)
      }
    },
    [token, setToken],
  )

  return (
    <View className={styles.container}>
      {/* 顶部图标区域 */}
      <View className={styles.iconWrap}>
        <Text className={styles.icon}>📱</Text>
      </View>

      {/* 标题与说明 */}
      <Text className={styles.title}>绑定手机号</Text>
      <Text className={styles.subtitle}>
        为保障账号安全，需要绑定您的手机号。{'\n'}
        我们仅用于登录验证，不会泄露或用于营销。
      </Text>

      {/* 授权按钮 —— 使用 NutUI Button + 微信 getPhoneNumber open-type */}
      <Button
        className={styles.authBtn}
        type="primary"
        size="large"
        loading={loading}
        disabled={loading}
        openType="getPhoneNumber"
        onGetPhoneNumber={handleGetPhoneNumber as any}
      >
        {loading ? '绑定中...' : '一键授权绑定'}
      </Button>

      {/* 跳过按钮（弱化样式） */}
      <Button
        className={styles.skipBtn}
        type="default"
        size="large"
        disabled={loading}
        onClick={() => Taro.switchTab({ url: '/pages/index/index' })}
      >
        暂不绑定
      </Button>

      {/* 隐私声明 */}
      <Text className={styles.privacy}>
        授权即表示您同意我们的
        <Text
          className={styles.link}
          onClick={() =>
            Taro.navigateTo({ url: '/pages/privacy/index' })
          }
        >
          《隐私政策》
        </Text>
      </Text>
    </View>
  )
}
