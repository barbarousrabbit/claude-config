/**
 * useOrderWebSocket.ts
 *
 * 订单通知 WebSocket Hook（Taro 4 + 微信小程序）
 *
 * ⚠️  协议安全说明：
 *   微信小程序生产环境强制要求 wss://（TLS 加密），不允许 ws://（明文）。
 *   原始 URL ws://api.daigou.example.com/ws/orders 已自动升级为
 *   wss://api.daigou.example.com/ws/orders。
 *   本地开发若需使用 ws://，请在微信开发者工具 → 详情 → 本地设置中
 *   勾选"不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书"。
 *
 * 功能：
 *   - 连接到订单通知 WebSocket 服务
 *   - 收到消息时调用 onMessage 回调
 *   - 连接断开后自动重连（指数退避，初始 1 秒，最长 30 秒）
 *   - 心跳保活（每 30 秒发送 ping，过滤 pong 响应）
 *   - 组件卸载时自动断开并清理所有定时器
 */

import { useEffect, useRef, useCallback } from 'react'
import Taro from '@tarojs/taro'

/** 订单通知消息类型 */
export interface OrderNotificationMessage {
  /** 消息类型，如 'order.created' | 'order.paid' | 'order.shipped' 等 */
  type: string
  /** 关联订单 ID */
  orderId?: string
  /** 消息携带的业务数据 */
  payload?: Record<string, unknown>
  /** 服务端时间戳（毫秒） */
  timestamp?: number
}

/** 心跳消息结构 */
interface PingMessage {
  type: 'ping'
  timestamp: number
}

/** Hook 配置项 */
export interface UseOrderWebSocketOptions {
  /**
   * 是否自动连接。
   * 默认 true，设为 false 可延迟连接（例如等待登录完成后再手动调用 reconnect）。
   */
  autoConnect?: boolean
  /**
   * 心跳间隔（毫秒），默认 30000（30 秒）。
   */
  heartbeatInterval?: number
  /**
   * 重连初始延迟（毫秒），默认 1000（1 秒）。
   */
  initialReconnectDelay?: number
  /**
   * 重连最大延迟（毫秒），默认 30000（30 秒）。
   */
  maxReconnectDelay?: number
  /**
   * 订阅的认证 Token（可选），连接建立后发送 auth 消息完成鉴权。
   */
  authToken?: string
}

/** Hook 返回值 */
export interface UseOrderWebSocketReturn {
  /**
   * 当前底层 SocketTask 引用（通常无需直接使用）。
   */
  socketRef: React.MutableRefObject<Taro.SocketTask | null>
  /**
   * 手动触发立即重连（例如从后台切回前台时主动刷新连接）。
   */
  reconnect: () => void
  /**
   * 手动发送消息到服务端。
   */
  send: (data: Record<string, unknown>) => void
}

/**
 * 订单通知 WebSocket URL（已升级为 wss://，生产环境合规）
 *
 * 原始需求为 ws://api.daigou.example.com/ws/orders，
 * 按微信小程序安全规范强制升级为 wss://。
 */
export const ORDER_WS_URL = 'wss://api.daigou.example.com/ws/orders'

/**
 * 订单通知 WebSocket Hook
 *
 * @param onMessage - 收到业务消息时的回调（pong 心跳响应已过滤，不会触发此回调）
 * @param options   - 可选配置项
 *
 * @example
 * ```tsx
 * import { useOrderWebSocket } from '@/hooks/useOrderWebSocket'
 *
 * export default function OrderListPage() {
 *   const handleMessage = useCallback((msg: OrderNotificationMessage) => {
 *     console.info('[订单通知] 收到消息', msg)
 *     if (msg.type === 'order.paid') {
 *       Taro.showToast({ title: '订单已支付', icon: 'success' })
 *       refreshOrderList()
 *     }
 *   }, [])
 *
 *   const { reconnect } = useOrderWebSocket(handleMessage, {
 *     authToken: useAuthStore((s) => s.token) ?? undefined,
 *   })
 *
 *   // 从后台切回前台时主动重连，避免连接因小程序休眠而断开
 *   useDidShow(() => { reconnect() })
 *
 *   return <View>...</View>
 * }
 * ```
 */
export function useOrderWebSocket(
  onMessage: (message: OrderNotificationMessage) => void,
  options: UseOrderWebSocketOptions = {},
): UseOrderWebSocketReturn {
  const {
    autoConnect = true,
    heartbeatInterval = 30_000,
    initialReconnectDelay = 1_000,
    maxReconnectDelay = 30_000,
    authToken,
  } = options

  // 当前 SocketTask 实例
  const socketRef = useRef<Taro.SocketTask | null>(null)
  // 心跳定时器
  const heartbeatTimerRef = useRef<ReturnType<typeof setInterval> | null>(null)
  // 重连定时器
  const reconnectTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  // 当前重连退避延迟（毫秒）
  const reconnectDelayRef = useRef<number>(initialReconnectDelay)
  // 组件是否已卸载标志，防止卸载后继续重连
  const isUnmountedRef = useRef<boolean>(false)
  // 是否正在连接中（防止并发创建多个 SocketTask）
  const isConnectingRef = useRef<boolean>(false)

  // 使用 ref 持有最新的 onMessage，避免 connect 因回调变化频繁重建
  const onMessageRef = useRef(onMessage)
  useEffect(() => {
    onMessageRef.current = onMessage
  }, [onMessage])

  /** 清理心跳定时器 */
  const clearHeartbeat = useCallback(() => {
    if (heartbeatTimerRef.current !== null) {
      clearInterval(heartbeatTimerRef.current)
      heartbeatTimerRef.current = null
    }
  }, [])

  /** 清理重连定时器 */
  const clearReconnectTimer = useCallback(() => {
    if (reconnectTimerRef.current !== null) {
      clearTimeout(reconnectTimerRef.current)
      reconnectTimerRef.current = null
    }
  }, [])

  /** 安全关闭当前连接（不触发重连） */
  const closeSocket = useCallback(() => {
    clearHeartbeat()
    if (socketRef.current) {
      try {
        socketRef.current.close({})
      } catch {
        // 连接可能已经关闭，忽略异常
      }
      socketRef.current = null
    }
    isConnectingRef.current = false
  }, [clearHeartbeat])

  /** 启动心跳保活 */
  const startHeartbeat = useCallback(
    (socket: Taro.SocketTask) => {
      clearHeartbeat()
      heartbeatTimerRef.current = setInterval(() => {
        if (isUnmountedRef.current) return
        const ping: PingMessage = { type: 'ping', timestamp: Date.now() }
        socket.send({
          data: JSON.stringify(ping),
          fail: () => {
            // 发送失败说明连接已异常，清理并等待 onClose 触发重连
            console.warn('[OrderWS] 心跳发送失败，连接可能已断开')
          },
        })
      }, heartbeatInterval)
    },
    [clearHeartbeat, heartbeatInterval],
  )

  /** 建立 WebSocket 连接（核心逻辑） */
  const connect = useCallback(() => {
    if (isUnmountedRef.current) return
    if (isConnectingRef.current) return

    isConnectingRef.current = true
    console.info('[OrderWS] 正在连接...', ORDER_WS_URL)

    const socket = Taro.connectSocket({
      url: ORDER_WS_URL,
      fail: (err) => {
        console.error('[OrderWS] 连接创建失败', err)
        isConnectingRef.current = false
        scheduleReconnect()
      },
    })

    socketRef.current = socket

    socket.onOpen(() => {
      if (isUnmountedRef.current) {
        socket.close({})
        return
      }
      console.info('[OrderWS] 连接已建立')
      isConnectingRef.current = false
      // 连接成功后重置退避延迟
      reconnectDelayRef.current = initialReconnectDelay

      // 若配置了 authToken，发送鉴权消息
      if (authToken) {
        socket.send({
          data: JSON.stringify({ type: 'auth', token: authToken }),
          fail: () => console.warn('[OrderWS] 鉴权消息发送失败'),
        })
      }

      startHeartbeat(socket)
    })

    socket.onMessage(({ data }) => {
      if (isUnmountedRef.current) return
      try {
        const msg = JSON.parse(data as string) as OrderNotificationMessage & { type: string }
        // 过滤心跳 pong 响应，不传递给业务回调
        if (msg.type === 'pong') return
        onMessageRef.current(msg)
      } catch (err) {
        console.error('[OrderWS] 消息解析失败', err, data)
      }
    })

    socket.onError((err) => {
      console.error('[OrderWS] 连接发生错误', err)
      // onError 后通常会紧跟 onClose，重连在 onClose 中处理
    })

    socket.onClose(({ code, reason }) => {
      clearHeartbeat()
      isConnectingRef.current = false
      console.warn(`[OrderWS] 连接已关闭，code=${code} reason=${reason}`)
      scheduleReconnect()
    })
  }, [authToken, clearHeartbeat, initialReconnectDelay, startHeartbeat]) // eslint-disable-line react-hooks/exhaustive-deps

  /**
   * 安排指数退避重连
   * 延迟策略：每次失败后 delay * 2，上限 maxReconnectDelay（默认 30 秒）
   */
  const scheduleReconnect = useCallback(() => {
    if (isUnmountedRef.current) return
    clearReconnectTimer()

    const delay = reconnectDelayRef.current
    console.info(`[OrderWS] 将在 ${delay}ms 后重连...`)

    reconnectTimerRef.current = setTimeout(() => {
      if (isUnmountedRef.current) return
      // 更新下次退避延迟（指数增长，上限 maxReconnectDelay）
      reconnectDelayRef.current = Math.min(reconnectDelayRef.current * 2, maxReconnectDelay)
      connect()
    }, delay)
  }, [clearReconnectTimer, connect, maxReconnectDelay])

  /**
   * 手动触发立即重连（用于 useDidShow 等生命周期场景）
   * 会先关闭当前连接，清理重连定时器，再重置延迟后立即连接。
   */
  const reconnect = useCallback(() => {
    if (isUnmountedRef.current) return
    console.info('[OrderWS] 手动触发重连')
    clearReconnectTimer()
    closeSocket()
    reconnectDelayRef.current = initialReconnectDelay
    connect()
  }, [clearReconnectTimer, closeSocket, connect, initialReconnectDelay])

  /**
   * 手动发送消息（业务层使用）
   */
  const send = useCallback((data: Record<string, unknown>) => {
    if (!socketRef.current) {
      console.warn('[OrderWS] 连接未建立，无法发送消息')
      return
    }
    socketRef.current.send({
      data: JSON.stringify(data),
      fail: (err) => console.error('[OrderWS] 消息发送失败', err),
    })
  }, [])

  // 挂载时建立连接，卸载时断开并清理所有资源
  useEffect(() => {
    isUnmountedRef.current = false

    if (autoConnect) {
      connect()
    }

    return () => {
      // 标记已卸载，阻止后续所有重连和回调
      isUnmountedRef.current = true
      clearReconnectTimer()
      closeSocket()
      console.info('[OrderWS] 组件卸载，连接已清理')
    }
  }, []) // 仅在挂载/卸载时执行，connect 通过 ref 访问最新状态，无需列为依赖

  return { socketRef, reconnect, send }
}

export default useOrderWebSocket
