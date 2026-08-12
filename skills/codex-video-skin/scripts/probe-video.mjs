// Query the live renderer over CDP to prove the video layer is real and playing.
const EXPR = `(() => {
  const v = document.getElementById("codex-dream-skin-video");
  const root = document.documentElement;
  const cs = v ? getComputedStyle(v) : null;
  const r = v ? v.getBoundingClientRect() : null;
  return JSON.stringify({
    videoExists: !!v,
    tag: v ? v.tagName : null,
    paused: v ? v.paused : null,
    currentTime: v ? Number(v.currentTime.toFixed(2)) : null,
    duration: v ? Number((v.duration || 0).toFixed(2)) : null,
    readyState: v ? v.readyState : null,
    intrinsic: v ? (v.videoWidth + "x" + v.videoHeight) : null,
    muted: v ? v.muted : null,
    loop: v ? v.loop : null,
    srcKind: v && v.currentSrc ? v.currentSrc.slice(0, 5) : null,
    mediaAttr: root.getAttribute("data-dream-media"),
    activeAttr: root.getAttribute("data-dream-video-active"),
    zIndex: cs ? cs.zIndex : null,
    position: cs ? cs.position : null,
    objectFit: cs ? cs.objectFit : null,
    pointerEvents: cs ? cs.pointerEvents : null,
    displayed: cs ? cs.display : null,
    rect: r ? { w: Math.round(r.width), h: Math.round(r.height) } : null,
    bodyBg: getComputedStyle(document.body).backgroundColor,
    artVar: root.style.getPropertyValue("--dream-skin-art").slice(0, 24),
    firstChildIsVideo: document.body.firstElementChild
      ? document.body.firstElementChild.id : null
  });
})()`;

function probe(target) {
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  return new Promise((resolve) => {
    const timer = setTimeout(() => { try { ws.close(); } catch {} resolve(null); }, 15000);
    ws.onopen = () => ws.send(JSON.stringify({
      id: 1, method: "Runtime.evaluate",
      params: { expression: EXPR, returnByValue: true, awaitPromise: false },
    }));
    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id !== 1) return;
      clearTimeout(timer);
      try { ws.close(); } catch {}
      resolve(msg.result?.result?.value ? JSON.parse(msg.result.result.value) : null);
    };
    ws.onerror = () => { clearTimeout(timer); resolve(null); };
  });
}

const list = await (await fetch("http://127.0.0.1:9335/json")).json();
const pages = list.filter((t) => t.type === "page" && t.webSocketDebuggerUrl);
for (const target of pages) {
  const info = await probe(target);
  console.log(`\n===== ${target.id} =====`);
  console.log(`url: ${target.url}`);
  console.log(info ? JSON.stringify(info, null, 2) : "(no response)");
}
