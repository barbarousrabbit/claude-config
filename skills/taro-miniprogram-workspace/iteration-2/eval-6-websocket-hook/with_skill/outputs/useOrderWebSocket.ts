/**
 * useOrderWebSocket.ts
 *
 * 订单通知 WebSocket Hook（Taro 4 + React 18 + TypeScript）
 *
 * 功能：
 *   - 连接到订单通知服务 ws://api.daigou.example.com/ws/orders
 *   - 收到消息时调用外部回调
 *   - 连接断开后自动重连（指数退避，最长 30 秒）
 *   - 组件卸载时自动断开连接并清理定时器
 *   - 心跳保活（每 30 秒发送 ping，过滤 pong 响应）
 */

import { useEffect, useRef, useCallback } from 'react'
import Taro from '@tarojs/taro'

// ────────────────────────────────────────────────────────────────────────────
// 类型定义
// ────────────────────────────────────────────────────────────────────────────

/** 订单通知消息类型枚举 */
export enum OrderNotifyType {
  /** 买手已接单 */
  ORDER_ACCEPTED = 'ORDER_ACCEPTED',
  /** 买手已付款 */
  ORDER_PAID = 'ORDER_PAID',
  /** 商品已发货 */
  ORDER_SHIPPED = 'ORDER_SHIPPED',
  /** 订单已完成 */
  ORDER_COMPLETED = 'ORDER_COMPLETED',
  /** 退款申请已提交 */
  REFUND_REQUESTED = 'REFUND_REQUESTED',
  /** 退款已到账 */
  REFUND_COMPLETED = 'REFUND_COMPLETED',
  /** 保证金状态变更 */
  DEPOSIT_STATUS_CHANGED = 'DEPOSIT_STATUS_CHANGED',
  /** 系统通知（非订单业务） */
  SYSTEM = 'SYSTEM',
}

/** WebSocket 服务端推送的订单通知消息结构 */
export interface OrderNotifyMessage {
  /** 消息类型 */
  type: OrderNotifyType
  /** 关联订单 ID */
  orderId?: string
  /** 通知标题（用于展示） */
  title: string
  /** 通知正文 */
  body: string
  /** 额外业务数据（因消息类型而异） */
  payload?: Record<string, unknown>
  /** 服务端消息时间戳（ISO 8601） */
  timestamp: string
}

/** 心跳消息结构（不暴露给外部） */
interface HeartbeatMessage {
  type: 'ping' | 'pong'
}

/** Hook 配置项 */
export interface UseOrderWebSocketOptions {
  /**
   * 是否在 Hook 挂载时立即建立连接，默认 true。
   * 设为 false 可手动调用返回的 connect 方法。
   */
  autoConnect?: boolean
  /**
   * 初始重连间隔（毫秒），默认 1000ms。
   * 每次重连失败后翻倍，上限 MAX_RECONNECT_DELAY。
   */
  initialReconnectDelay?: number
  /**
   * 心跳间隔（毫秒），默认 30000ms（30 秒）。
   * 设为 0 可禁用心跳。
   */
  heartbeatInterval?: number
}

/** Hook 返回值 */
export interface UseOrderWebSocketReturn {
  /** 手动触发连接（autoConnect=false 时使用，或手动重连） */
  connect: () => void
  /** 手动断开连接（不会触发自动重连） */
  disconnect: () => void
  /** 当前连接状态 */
  isConnected: boolean
  /** 底层 SocketTask 引用（高级用途） */
  socketRef: React.MutableRefObject<Taro.SocketTask | null>
}

// ────────────────────────────────────────────────────────────────────────────
// 常量
// ────────────────────────────────────────────────────────────────────────────

/** 订单通知服务 WebSocket 地址 */
const ORDER_WS_URL = 'ws://api.daigou.example.com/ws/orders'

/** 最大重连间隔（毫秒） */
const MAX_RECONNECT_DELAY = 30_000

/** 默认心跳间隔（毫秒） */
const DEFAULT_HEARTBEAT_INTERVAL = 30_000

/** 默认初始重连间隔（毫秒） */
const DEFAULT_INITIAL_RECONNECT_DELAY = 1_000

// ────────────────────────────────────────────────────────────────────────────
// Hook 实现
// ────────────────────────────────────────────────────────────────────────────

/**
 * 订单通知 WebSocket Hook
 *
 * @param onMessage - 收到订单通知消息时的回调（已过滤心跳响应）
 * @param options   - 可选配置项
 *
 * @example
 * ```tsx
 * import { useOrderWebSocket, OrderNotifyType } from '@/hooks/useOrderWebSocket'
 *
 * export default function OrderListPage() {
 *   useOrderWebSocket((msg) => {
 *     if (msg.type === OrderNotifyType.ORDER_SHIPPED) {
 *       Taro.showToast({ title: '您的订单已发货', icon: 'success' })
 *     }
 *   })
 *
 *   return <View>...</View>
 * }
 * ```
 */
export function useOrderWebSocket(
  onMessage: (message: OrderNotifyMessage) => void,
  options: UseOrderWebSocketOptions = {},
): UseOrderWebSocketReturn {
  const {
    autoConnect = true,
    initialReconnectDelay = DEFAULT_INITIAL_RECONNECT_DELAY,
    heartbeatInterval = DEFAULT_HEARTBEAT_INTERVAL,
  } = options

  // ── Refs（不触发重渲染）──────────────────────────────────────────────────
  const socketRef = useRef<Taro.SocketTask | null>(null)

  /** 当前重连等待时长（毫秒），连接成功后重置为初始值 */
  const reconnectDelayRef = useRef<number>(initialReconnectDelay)

  /** 心跳定时器 ID */
  const heartbeatTimerRef = useRef<ReturnType<typeof setInterval> | null>(null)

  /** 重连定时器 ID */
  const reconnectTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  /**
   * 组件是否已卸载标志。
   * 任何异步回调（onClose、scheduleReconnect）在执行前都必须检查此标志，
   * 避免在已卸载的组件上继续操作。
   */
  const isUnmountedRef = useRef<boolean>(false)

  /**
   * 是否是用户主动调用 disconnect() 触发的断开。
   * 主动断开不触发自动重连。
   */
  const isManualDisconnectRef = useRef<boolean>(false)

  /** 当前连接状态（用于返回给调用方） */
  const isConnectedRef = useRef<boolean>(false)

  // 使用稳定引用保存 onMessage，避免 connect 的 useCallback 因 onMessage 变化而重建
  const onMessageRef = useRef<(message: OrderNotifyMessage) => void>(onMessage)
  useEffect(() => {
    onMessageRef.current = onMessage
  }, [onMessage])

  // ── 清理心跳定时器 ──────────────────────────────────────────────────────
  const clearHeartbeat = useCallback(() => {
    if (heartbeatTimerRef.current !== null) {
      clearInterval(heartbeatTimerRef.current)
      heartbeatTimerRef.current = null
    }
  }, [])

  // ── 清理重连定时器 ──────────────────────────────────────────────────────
  const clearReconnectTimer = useCallback(() => {
    if (reconnectTimerRef.current !== null) {
      clearTimeout(reconnectTimerRef.current)
      reconnectTimerRef.current = null
    }
  }, [])

  // ── 安全关闭当前 Socket ─────────────────────────────────────────────────
  const closeSocket = useCallback(() => {
    clearHeartbeat()
    if (socketRef.current) {
      try {
        socketRef.current.close({})
      } catch (e) {
        // 忽略已关闭状态下重复 close 的错误
      }
      socketRef.current = null
    }
    isConnectedRef.current = false
  }, [clearHeartbeat])

  // ── 调度重连（指数退避） ────────────────────────────────────────────────
  const scheduleReconnect = useCallback(() => {
    // 组件已卸载 或 用户主动断开，均不重连
    if (isUnmountedRef.current || isManualDisconnectRef.current) return

    const delay = reconnectDelayRef.current
    console.info(
      `[OrderWS] 连接断开，${delay / 1000} 秒后自动重连（退避上限 ${MAX_RECONNECT_DELAY / 1000}s）`,
    )

    reconnectTimerRef.current = setTimeout(() => {
      if (isUnmountedRef.current || isManualDisconnectRef.current) return

      // 指数退避：当前延迟翻倍，不超过上限
      reconnectDelayRef.current = Math.min(
        reconnectDelayRef.current * 2,
        MAX_RECONNECT_DELAY,
      )

      // eslint-disable-next-line @typescript-eslint/no-use-before-define
      connect()
    }, delay)
  }, []) // connect 通过前向引用调用，避免循环依赖

  // ── 建立 WebSocket 连接 ─────────────────────────────────────────────────
  const connect = useCallback(() => {
    if (isUnmountedRef.current) return

    // 如有旧连接，先安全关闭
    closeSocket()

    console.info(`[OrderWS] 正在连接：${ORDER_WS_URL}`)

    const socket = Taro.connectSocket({
      url: ORDER_WS_URL,
      fail: (err) => {
        // connectSocket 本身失败（如 URL 格式错误），直接调度重连
        console.error('[OrderWS] connectSocket 调用失败：', err)
        scheduleReconnect()
      },
    })

    socketRef.current = socket

    // 连接建立成功
    socket.onOpen(() => {
      if (isUnmountedRef.current) {
        socket.close({})
        return
      }

      console.info('[OrderWS] 连接已建立')
      isConnectedRef.current = true

      // 重置指数退避延迟
      reconnectDelayRef.current = initialReconnectDelay

      // 启动心跳（若配置了心跳间隔）
      if (heartbeatInterval > 0) {
        clearHeartbeat()
        heartbeatTimerRef.current = setInterval(() => {
          if (!isConnectedRef.current || isUnmountedRef.current) return
          try {
            socket.send({
              data: JSON.stringify({ type: 'ping' } satisfies HeartbeatMessage),
              fail: () => {
                console.warn('[OrderWS] 心跳发送失败，可能已断连')
              },
            })
          } catch (e) {
            console.warn('[OrderWS] 心跳发送异常：', e)
          }
        }, heartbeatInterval)
      }
    })

    // 收到服务端消息
    socket.onMessage(({ data }) => {
      if (isUnmountedRef.current) return

      let parsed: OrderNotifyMessage | HeartbeatMessage

      try {
        parsed = JSON.parse(data as string)
      } catch (e) {
        console.warn('[OrderWS] 消息解析失败，原始数据：', data)
        return
      }

      // 过滤心跳响应（pong），不传递给业务回调
      if ((parsed as HeartbeatMessage).type === 'pong') return

      // 将订单通知消息传递给外部回调
      onMessageRef.current(parsed as OrderNotifyMessage)
    })

    // 连接出错
    socket.onError((err) => {
      console.error('[OrderWS] 连接发生错误：', err)
      // onError 后通常紧跟 onClose，重连在 onClose 中处理，此处仅记录日志
    })

    // 连接关闭
    socket.onClose(({ code, reason }) => {
      clearHeartbeat()
      isConnectedRef.current = false

      if (isUnmountedRef.current || isManualDisconnectRef.current) {
        console.info('[OrderWS] 连接已关闭（主动断开或组件卸载）')
        return
      }

      console.warn(`[OrderWS] 连接意外关闭，code=${code}，reason=${reason ?? '无'}，准备重连`)
      scheduleReconnect()
    })
  }, [closeSocket, clearHeartbeat, scheduleReconnect, initialReconnectDelay, heartbeatInterval])

  // 将 connect 挂到 scheduleReconnect 的前向引用（规避循环依赖）
  // scheduleReconnect 内部通过直接调用 connect 实现，
  // 由于 JS 函数作用域，connect 在 scheduleReconnect 调用时已定义。

  // ── 用户手动断开 ────────────────────────────────────────────────────────
  const disconnect = useCallback(() => {
    console.info('[OrderWS] 主动断开连接')
    isManualDisconnectRef.current = true
    clearReconnectTimer()
    closeSocket()
  }, [clearReconnectTimer, closeSocket])

  // ── 生命周期管理 ────────────────────────────────────────────────────────
  useEffect(() => {
    isUnmountedRef.current = false
    isManualDisconnectRef.current = false

    if (autoConnect) {
      connect()
    }

    // 组件卸载时清理所有资源
    return () => {
      isUnmountedRef.current = true
      clearReconnectTimer()
      closeSocket()
      console.info('[OrderWS] 组件卸载，WebSocket 资源已清理')
    }
  // 仅在挂载/卸载时执行，connect 已通过 useCallback 保持稳定
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return {
    connect,
    disconnect,
    isConnected: isConnectedRef.current,
    socketRef,
  }
}

export default useOrderWebSocket
