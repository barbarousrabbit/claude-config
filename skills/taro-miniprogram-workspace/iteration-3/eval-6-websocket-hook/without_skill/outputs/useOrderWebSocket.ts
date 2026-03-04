/**
 * useOrderWebSocket.ts
 *
 * Taro 4 微信小程序 WebSocket Hook
 * 连接订单通知服务，支持消息回调、自动重连（指数退避）、组件卸载自动断开。
 *
 * 使用方式：
 *   const { connected, lastMessage, disconnect } = useOrderWebSocket((msg) => {
 *     console.log('收到订单通知', msg);
 *   });
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import Taro from '@tarojs/taro';

// ─────────────────────────────────────────────────────────────────────────────
// 常量
// ─────────────────────────────────────────────────────────────────────────────

/** 订单通知 WebSocket 服务地址（微信小程序要求 wss，示例保留原始配置） */
const WS_URL = 'wss://api.daigou.example.com/ws/orders';

/** 初始重连等待时间（毫秒） */
const RECONNECT_BASE_DELAY_MS = 1_000;

/** 最大重连等待时间（毫秒） */
const RECONNECT_MAX_DELAY_MS = 30_000;

/** 指数退避倍率 */
const RECONNECT_MULTIPLIER = 2;

// ─────────────────────────────────────────────────────────────────────────────
// 类型定义
// ─────────────────────────────────────────────────────────────────────────────

/** 连接状态枚举 */
export type WebSocketStatus = 'connecting' | 'open' | 'closed' | 'error';

/** 收到的原始消息（字符串或 ArrayBuffer） */
export type WebSocketMessage = string | ArrayBuffer;

/**
 * 消息回调类型
 * @param message 服务端推送的原始消息内容
 */
export type OnMessageCallback = (message: WebSocketMessage) => void;

/** Hook 配置选项 */
export interface UseOrderWebSocketOptions {
  /** 覆盖默认的 WebSocket 服务地址 */
  url?: string;
  /** 是否在 Hook 初始化时立即建立连接，默认 true */
  connectOnMount?: boolean;
  /**
   * 鉴权 Token，将通过请求头 `Authorization: Bearer <token>` 传递。
   * 微信小程序 connectSocket 的 header 仅在握手阶段有效。
   */
  authToken?: string;
}

/** Hook 返回值 */
export interface UseOrderWebSocketReturn {
  /** 当前连接状态 */
  status: WebSocketStatus;
  /** 是否已建立连接 */
  connected: boolean;
  /** 最近一次收到的消息，未收到时为 null */
  lastMessage: WebSocketMessage | null;
  /** 当前已重连次数 */
  retryCount: number;
  /** 主动断开连接（断开后不再自动重连） */
  disconnect: () => void;
  /** 主动发送消息，连接未建立时静默失败并返回 false */
  send: (data: string | ArrayBuffer) => boolean;
}

// ─────────────────────────────────────────────────────────────────────────────
// 工具函数
// ─────────────────────────────────────────────────────────────────────────────

/**
 * 计算指数退避延迟时间
 * delay = min(base * multiplier^retryCount, maxDelay)
 */
function calcBackoffDelay(retryCount: number): number {
  const delay = RECONNECT_BASE_DELAY_MS * Math.pow(RECONNECT_MULTIPLIER, retryCount);
  return Math.min(delay, RECONNECT_MAX_DELAY_MS);
}

// ─────────────────────────────────────────────────────────────────────────────
// Hook 实现
// ─────────────────────────────────────────────────────────────────────────────

/**
 * useOrderWebSocket
 *
 * @param onMessage 收到消息时触发的回调（可在每次渲染传入新函数，内部用 ref 稳定引用）
 * @param options   可选配置
 */
export function useOrderWebSocket(
  onMessage: OnMessageCallback,
  options: UseOrderWebSocketOptions = {},
): UseOrderWebSocketReturn {
  const {
    url = WS_URL,
    connectOnMount = true,
    authToken,
  } = options;

  // ── 状态 ──────────────────────────────────────────────────────────────────
  const [status, setStatus] = useState<WebSocketStatus>('closed');
  const [lastMessage, setLastMessage] = useState<WebSocketMessage | null>(null);
  const [retryCount, setRetryCount] = useState(0);

  // ── Refs（避免 effect 闭包捕获过期值） ────────────────────────────────────
  /** 保持 onMessage 回调的最新引用，避免重新订阅 */
  const onMessageRef = useRef<OnMessageCallback>(onMessage);
  useEffect(() => {
    onMessageRef.current = onMessage;
  }, [onMessage]);

  /** 微信 SocketTask 实例 */
  const socketTaskRef = useRef<Taro.SocketTask | null>(null);

  /** 重连定时器 */
  const reconnectTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  /** 当前重连次数（ref 版本，供异步回调读写，不触发渲染） */
  const retryCountRef = useRef(0);

  /**
   * 是否已主动断开（true 时不再自动重连）
   * 用 ref 而非 state，确保在异步 close 回调中读取到最新值。
   */
  const manuallyDisconnectedRef = useRef(false);

  /** 组件是否已卸载，防止卸载后 setState */
  const unmountedRef = useRef(false);

  // ── 辅助：清除重连定时器 ──────────────────────────────────────────────────
  const clearReconnectTimer = useCallback(() => {
    if (reconnectTimerRef.current !== null) {
      clearTimeout(reconnectTimerRef.current);
      reconnectTimerRef.current = null;
    }
  }, []);

  // ── 核心：建立连接 ────────────────────────────────────────────────────────
  const connect = useCallback(() => {
    // 如果已有连接实例，先关闭（防止重复连接）
    if (socketTaskRef.current) {
      try {
        socketTaskRef.current.close({ code: 1000, reason: '重新连接' });
      } catch {
        // 忽略关闭时的错误
      }
      socketTaskRef.current = null;
    }

    if (!unmountedRef.current) {
      setStatus('connecting');
    }

    // 构建请求头
    const header: Record<string, string> = {};
    if (authToken) {
      header['Authorization'] = `Bearer ${authToken}`;
    }

    let task: Taro.SocketTask;
    try {
      task = Taro.connectSocket({
        url,
        header,
        // 微信小程序默认支持 text / binary，无需额外声明
        complete: () => { /* 连接发起完成（不代表成功） */ },
      });
    } catch (err) {
      console.error('[useOrderWebSocket] connectSocket 调用失败', err);
      if (!unmountedRef.current) {
        setStatus('error');
      }
      scheduleReconnect();
      return;
    }

    socketTaskRef.current = task;

    // ── 事件：连接成功 ────────────────────────────────────────────────────
    task.onOpen(() => {
      if (unmountedRef.current) return;
      console.info('[useOrderWebSocket] 连接已建立', url);
      // 连接成功后重置重连计数
      retryCountRef.current = 0;
      setRetryCount(0);
      setStatus('open');
    });

    // ── 事件：收到消息 ────────────────────────────────────────────────────
    task.onMessage((res) => {
      if (unmountedRef.current) return;
      const data = res.data as WebSocketMessage;
      setLastMessage(data);
      try {
        onMessageRef.current(data);
      } catch (err) {
        console.error('[useOrderWebSocket] onMessage 回调执行异常', err);
      }
    });

    // ── 事件：发生错误 ────────────────────────────────────────────────────
    task.onError((err) => {
      if (unmountedRef.current) return;
      console.error('[useOrderWebSocket] WebSocket 错误', err);
      setStatus('error');
      // 错误后由 onClose 触发重连，此处不重复调度
    });

    // ── 事件：连接关闭 ────────────────────────────────────────────────────
    task.onClose((res) => {
      if (unmountedRef.current) return;
      console.warn(
        `[useOrderWebSocket] 连接关闭，code=${res.code}，reason=${res.reason}`,
      );
      setStatus('closed');
      socketTaskRef.current = null;

      // 主动断开时不重连
      if (!manuallyDisconnectedRef.current) {
        scheduleReconnect();
      }
    });
  }, [url, authToken]); // eslint-disable-line react-hooks/exhaustive-deps
  // 注：scheduleReconnect 是在同一 useCallback 作用域内定义，通过 ref 引用

  // ── 核心：调度重连 ────────────────────────────────────────────────────────
  // 使用 ref 存储函数引用，避免 connect 的依赖数组循环
  const scheduleReconnectRef = useRef<() => void>(() => { /* 占位 */ });

  const scheduleReconnect = useCallback(() => {
    clearReconnectTimer();
    const delay = calcBackoffDelay(retryCountRef.current);
    const nextCount = retryCountRef.current + 1;
    retryCountRef.current = nextCount;

    console.info(
      `[useOrderWebSocket] 将在 ${delay}ms 后进行第 ${nextCount} 次重连`,
    );

    if (!unmountedRef.current) {
      setRetryCount(nextCount);
    }

    reconnectTimerRef.current = setTimeout(() => {
      if (!unmountedRef.current && !manuallyDisconnectedRef.current) {
        connect();
      }
    }, delay);
  }, [clearReconnectTimer, connect]);

  // 将最新的 scheduleReconnect 写入 ref，供 connect 内部调用
  useEffect(() => {
    scheduleReconnectRef.current = scheduleReconnect;
  }, [scheduleReconnect]);

  // ── 主动断开 ──────────────────────────────────────────────────────────────
  const disconnect = useCallback(() => {
    manuallyDisconnectedRef.current = true;
    clearReconnectTimer();
    if (socketTaskRef.current) {
      try {
        socketTaskRef.current.close({ code: 1000, reason: '主动断开' });
      } catch (err) {
        console.warn('[useOrderWebSocket] 主动关闭时出错', err);
      }
      socketTaskRef.current = null;
    }
    if (!unmountedRef.current) {
      setStatus('closed');
    }
    console.info('[useOrderWebSocket] 已主动断开，不再自动重连');
  }, [clearReconnectTimer]);

  // ── 主动发送消息 ──────────────────────────────────────────────────────────
  const send = useCallback((data: string | ArrayBuffer): boolean => {
    const task = socketTaskRef.current;
    if (!task) {
      console.warn('[useOrderWebSocket] 发送失败：连接未建立');
      return false;
    }
    try {
      task.send({ data });
      return true;
    } catch (err) {
      console.error('[useOrderWebSocket] 发送消息失败', err);
      return false;
    }
  }, []);

  // ── 生命周期：挂载时连接，卸载时断开 ─────────────────────────────────────
  useEffect(() => {
    unmountedRef.current = false;
    manuallyDisconnectedRef.current = false;

    if (connectOnMount) {
      connect();
    }

    return () => {
      // 组件卸载：标记卸载、清定时器、关闭连接
      unmountedRef.current = true;
      manuallyDisconnectedRef.current = true;
      clearReconnectTimer();
      if (socketTaskRef.current) {
        try {
          socketTaskRef.current.close({ code: 1000, reason: '组件卸载' });
        } catch {
          // 忽略卸载时的关闭错误
        }
        socketTaskRef.current = null;
      }
    };
    // connect 和 clearReconnectTimer 已通过 ref 稳定，connectOnMount 为初始值不变
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ─────────────────────────────────────────────────────────────────────────
  // 返回值
  // ─────────────────────────────────────────────────────────────────────────
  return {
    status,
    connected: status === 'open',
    lastMessage,
    retryCount,
    disconnect,
    send,
  };
}

export default useOrderWebSocket;
