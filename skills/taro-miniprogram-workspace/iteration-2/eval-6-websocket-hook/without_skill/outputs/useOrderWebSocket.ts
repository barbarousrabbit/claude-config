/**
 * useOrderWebSocket.ts
 *
 * Taro 4 微信小程序 —— 订单通知 WebSocket Hook
 *
 * 功能：
 *  - 连接到订单通知服务（wss://api.daigou.example.com/ws/orders）
 *  - 收到消息时触发 onMessage 回调
 *  - 连接断开后指数退避自动重连（上限 30 秒）
 *  - 组件卸载时自动断开并清理所有定时器
 *
 * 使用示例：
 *  const { status, disconnect, reconnect } = useOrderWebSocket({
 *    onMessage: (msg) => console.log('新订单消息', msg),
 *    onError: (err) => console.error('WebSocket 错误', err),
 *  });
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import Taro from '@tarojs/taro';

// ---------------------------------------------------------------------------
// 常量
// ---------------------------------------------------------------------------

/** WebSocket 服务端地址（微信小程序要求使用 wss，本地开发可放行 ws） */
const WS_URL = 'wss://api.daigou.example.com/ws/orders';

/** 首次重连等待时间（毫秒） */
const INITIAL_RETRY_DELAY_MS = 1_000;

/** 指数退避最大等待时间（毫秒） */
const MAX_RETRY_DELAY_MS = 30_000;

/** 指数退避乘数 */
const BACKOFF_MULTIPLIER = 2;

// ---------------------------------------------------------------------------
// 类型定义
// ---------------------------------------------------------------------------

/** WebSocket 连接状态 */
export type WebSocketStatus =
  | 'connecting'   // 正在建立连接
  | 'connected'    // 已连接
  | 'disconnected' // 已断开（等待重连或手动断开）
  | 'closed';      // 已彻底关闭（手动断开，不再重连）

/** Hook 入参 */
export interface UseOrderWebSocketOptions {
  /**
   * 收到服务端消息时的回调。
   * data 已尝试 JSON.parse，若解析失败则原样传入字符串。
   */
  onMessage?: (data: unknown) => void;

  /**
   * 发生错误时的回调（网络错误、服务端主动关闭等）。
   */
  onError?: (error: { errMsg: string }) => void;

  /**
   * 连接成功建立时的回调。
   */
  onOpen?: () => void;

  /**
   * 连接关闭时的回调（无论主动/被动）。
   * @param code    关闭码
   * @param reason  关闭原因
   */
  onClose?: (code: number, reason: string) => void;

  /**
   * 是否在组件挂载时立即建立连接，默认 true。
   */
  autoConnect?: boolean;

  /**
   * 自定义 WebSocket URL，覆盖默认值（用于测试/多环境）。
   */
  url?: string;

  /**
   * 自定义 Header（如鉴权 Token）。
   */
  header?: Record<string, string>;

  /**
   * 自定义子协议列表。
   */
  protocols?: string[];
}

/** Hook 返回值 */
export interface UseOrderWebSocketReturn {
  /** 当前连接状态 */
  status: WebSocketStatus;
  /** 主动断开并停止重连 */
  disconnect: () => void;
  /** 手动触发重连（会重置退避计时器） */
  reconnect: () => void;
  /**
   * 向服务端发送消息。
   * @returns true 表示发送成功，false 表示当前未连接
   */
  sendMessage: (data: string | object) => boolean;
  /** 当前已重连次数 */
  retryCount: number;
}

// ---------------------------------------------------------------------------
// Hook 实现
// ---------------------------------------------------------------------------

export function useOrderWebSocket(
  options: UseOrderWebSocketOptions = {}
): UseOrderWebSocketReturn {
  const {
    onMessage,
    onError,
    onOpen,
    onClose,
    autoConnect = true,
    url = WS_URL,
    header,
    protocols,
  } = options;

  // ---- 状态 ----
  const [status, setStatus] = useState<WebSocketStatus>(
    autoConnect ? 'connecting' : 'closed'
  );
  const [retryCount, setRetryCount] = useState(0);

  // ---- Refs（不触发重渲染的内部状态） ----

  /** 当前 Taro SocketTask 实例 */
  const socketRef = useRef<Taro.SocketTask | null>(null);

  /** 当前退避延迟时间（毫秒） */
  const retryDelayRef = useRef(INITIAL_RETRY_DELAY_MS);

  /** 重连定时器句柄 */
  const retryTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  /** 标记组件是否已卸载，防止卸载后的异步回调触发状态更新 */
  const unmountedRef = useRef(false);

  /** 标记用户是否主动断开（主动断开后不再重连） */
  const manualCloseRef = useRef(false);

  // 用 Ref 保存回调函数，避免闭包陈旧问题
  const onMessageRef = useRef(onMessage);
  const onErrorRef = useRef(onError);
  const onOpenRef = useRef(onOpen);
  const onCloseRef = useRef(onClose);

  useEffect(() => { onMessageRef.current = onMessage; }, [onMessage]);
  useEffect(() => { onErrorRef.current = onError; }, [onError]);
  useEffect(() => { onOpenRef.current = onOpen; }, [onOpen]);
  useEffect(() => { onCloseRef.current = onClose; }, [onClose]);

  // ---- 清理重连定时器 ----
  const clearRetryTimer = useCallback(() => {
    if (retryTimerRef.current !== null) {
      clearTimeout(retryTimerRef.current);
      retryTimerRef.current = null;
    }
  }, []);

  // ---- 关闭当前 Socket（不触发重连逻辑） ----
  const closeSocket = useCallback(() => {
    const task = socketRef.current;
    if (task) {
      // 移除监听器，防止关闭后触发重连逻辑
      task.onClose(() => {});
      task.onError(() => {});
      try {
        task.close({ code: 1000, reason: '组件主动关闭' });
      } catch {
        // 某些情况下 task 已经关闭，忽略异常
      }
      socketRef.current = null;
    }
  }, []);

  // ---- 建立 WebSocket 连接 ----
  const connect = useCallback(() => {
    if (unmountedRef.current) return;

    // 若已有连接，先关闭旧连接
    closeSocket();

    if (!unmountedRef.current) {
      setStatus('connecting');
    }

    Taro.connectSocket({
      url,
      header: {
        'Content-Type': 'application/json',
        ...header,
      },
      protocols,
      success: (task: Taro.SocketTask) => {
        if (unmountedRef.current) {
          // 组件已卸载，立即关闭
          try { task.close({ code: 1000, reason: '组件已卸载' }); } catch { /* noop */ }
          return;
        }

        socketRef.current = task;

        // 连接成功
        task.onOpen(() => {
          if (unmountedRef.current) return;
          console.info('[OrderWS] 连接成功:', url);
          setStatus('connected');
          // 重置退避参数
          retryDelayRef.current = INITIAL_RETRY_DELAY_MS;
          setRetryCount(0);
          onOpenRef.current?.();
        });

        // 收到消息
        task.onMessage((res: Taro.SocketTask.OnMessageCallbackResult) => {
          if (unmountedRef.current) return;
          let parsed: unknown = res.data;
          if (typeof res.data === 'string') {
            try {
              parsed = JSON.parse(res.data);
            } catch {
              // 非 JSON 格式，原样传递
              parsed = res.data;
            }
          }
          onMessageRef.current?.(parsed);
        });

        // 连接关闭（网络中断、服务端主动关闭等）
        task.onClose((res: Taro.SocketTask.OnCloseCallbackResult) => {
          if (unmountedRef.current) return;

          const code = res.code ?? 1006;
          const reason = res.reason ?? '未知原因';
          console.warn(`[OrderWS] 连接关闭 code=${code} reason=${reason}`);

          onCloseRef.current?.(code, reason);

          // 用户主动断开则不重连
          if (manualCloseRef.current) {
            setStatus('closed');
            return;
          }

          setStatus('disconnected');
          scheduleReconnect();
        });

        // 连接错误
        task.onError((err: { errMsg: string }) => {
          if (unmountedRef.current) return;
          console.error('[OrderWS] 连接错误:', err.errMsg);
          onErrorRef.current?.(err);
          // onError 后通常会触发 onClose，重连逻辑在 onClose 中处理
        });
      },
      fail: (err: { errMsg: string }) => {
        if (unmountedRef.current) return;
        console.error('[OrderWS] connectSocket 失败:', err.errMsg);
        onErrorRef.current?.(err);

        if (!manualCloseRef.current) {
          setStatus('disconnected');
          scheduleReconnect();
        }
      },
    });
  }, [url, header, protocols, closeSocket]); // eslint-disable-line react-hooks/exhaustive-deps
  // scheduleReconnect 在下方定义，避免循环依赖，通过 ref 调用

  // ---- 指数退避重连调度 ----
  const scheduleReconnectRef = useRef<() => void>(() => {});

  const scheduleReconnect = useCallback(() => {
    if (unmountedRef.current || manualCloseRef.current) return;

    clearRetryTimer();

    const delay = retryDelayRef.current;
    console.info(`[OrderWS] ${delay / 1000}s 后尝试重连...`);

    retryTimerRef.current = setTimeout(() => {
      if (unmountedRef.current || manualCloseRef.current) return;
      setRetryCount((prev) => prev + 1);
      // 更新下次退避延迟（上限 MAX_RETRY_DELAY_MS）
      retryDelayRef.current = Math.min(
        retryDelayRef.current * BACKOFF_MULTIPLIER,
        MAX_RETRY_DELAY_MS
      );
      connect();
    }, delay);
  }, [clearRetryTimer, connect]);

  // 保持 ref 同步，供 connect 回调调用
  useEffect(() => {
    scheduleReconnectRef.current = scheduleReconnect;
  }, [scheduleReconnect]);

  // ---- 手动断开 ----
  const disconnect = useCallback(() => {
    console.info('[OrderWS] 手动断开连接');
    manualCloseRef.current = true;
    clearRetryTimer();
    closeSocket();
    if (!unmountedRef.current) {
      setStatus('closed');
    }
  }, [clearRetryTimer, closeSocket]);

  // ---- 手动重连 ----
  const reconnect = useCallback(() => {
    console.info('[OrderWS] 手动触发重连');
    manualCloseRef.current = false;
    retryDelayRef.current = INITIAL_RETRY_DELAY_MS;
    clearRetryTimer();
    connect();
  }, [clearRetryTimer, connect]);

  // ---- 发送消息 ----
  const sendMessage = useCallback((data: string | object): boolean => {
    if (!socketRef.current) {
      console.warn('[OrderWS] 发送失败：WebSocket 未连接');
      return false;
    }
    try {
      const payload = typeof data === 'string' ? data : JSON.stringify(data);
      socketRef.current.send({
        data: payload,
        fail: (err: { errMsg: string }) => {
          console.error('[OrderWS] 消息发送失败:', err.errMsg);
        },
      });
      return true;
    } catch (e) {
      console.error('[OrderWS] 消息序列化失败:', e);
      return false;
    }
  }, []);

  // ---- 生命周期：挂载时建立连接 ----
  useEffect(() => {
    unmountedRef.current = false;
    manualCloseRef.current = false;

    if (autoConnect) {
      connect();
    }

    // 组件卸载时清理
    return () => {
      unmountedRef.current = true;
      clearRetryTimer();
      closeSocket();
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps
  // 仅在挂载/卸载时执行一次，依赖项变更由调用方通过 reconnect() 处理

  return {
    status,
    disconnect,
    reconnect,
    sendMessage,
    retryCount,
  };
}
