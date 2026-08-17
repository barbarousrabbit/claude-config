# Windows: a shortcut-launched PowerShell "button" that shows no console and restores a tray-hidden window

Measured 2026-08-17 (Windows 11 26100, Windows Terminal 1.24 as default terminal, PS 5.1)
while fixing the Codex-Skins desktop launcher. Both facts are generic Windows/.NET behaviour.

## `powershell -WindowStyle Hidden` alone STILL flashes a window under Windows Terminal
The console is created — and handed to Terminal — before PowerShell parses its own arguments,
so the flag can only hide a window that has already been shown.

| .lnk WindowStyle | args                  | result (50 ms poller on visible console/terminal windows) |
|---|---|---|
| 1 (normal)       | none                  | Terminal window visible at ~650 ms |
| 1 (normal)       | `-WindowStyle Hidden` | Terminal window STILL visible at ~430 ms, then hides |
| 7 (minimised)    | `-WindowStyle Hidden` | legacy conhost born minimised at ~130 ms (no Terminal handoff), then hidden — nothing opens on screen |

Rule: set the **shortcut** to minimised (`$lnk.WindowStyle = 7`) AND pass `-WindowStyle Hidden`.
A hidden console cannot show errors: report failure with `user32!MessageBoxW`
(`MB_TOPMOST 0x40000 | MB_SETFOREGROUND 0x10000`), never `Read-Host` (blocks forever unseen).
Zero-flash needs a GUI-subsystem exe (compiled launcher) — extra unsigned exe, AV-heuristic risk.

## `Process.MainWindowHandle` is 0 for a window hidden to the tray
.NET defines it as the first *visible* unowned top-level window. `SW_HIDE` (close-to-tray) makes it 0
for every process of the app, so a "wait for MainWindowHandle" poll can only time out; a
*minimised* window still has WS_VISIBLE and works. Enumerate instead:
`EnumWindows` → pid in set, `GetWindow(h, GW_OWNER)==0`, class match (Chromium/Electron:
`Chrome_WidgetWin_1`), skip `WS_EX_TOOLWINDOW` (0x80), prefer `WS_EX_APPWINDOW` (0x40000).
Then `ShowWindow(h, SW_SHOW=5)` for hidden (keeps maximised state; SW_RESTORE would un-maximise),
`SW_RESTORE=9` for minimised, then `SetForegroundWindow` with `WScript.Shell.AppActivate(pid)` fallback.
Electron gotcha: the app window may be titled after the package display name (Codex's is "ChatGPT"),
and a topmost transparent overlay of the same class may carry the "obvious" title — match on
styles, not titles. Foregrounding is refused unless the caller was started by the foreground
process (a real double-click qualifies; a test harness does not).

Full write-up with numbers: Codex-Skins repo `docs/skin-troubleshooting.md` faults #28 and #29.

## Probing a local port from PowerShell: never use `Invoke-WebRequest` as the probe
Against a loopback port nobody listens on, `Invoke-WebRequest -TimeoutSec N` does NOT fail fast on
this machine — it runs the whole timeout (measured 2,131 ms with `-TimeoutSec 2`), so a
"try HTTP, relaunch on failure" branch pays N seconds before deciding, and a boot-wait poll
`sleep 500ms; Invoke-WebRequest` becomes a ~2.5 s poll. `TcpClient.BeginConnect` + `AsyncWaitHandle.WaitOne(250)`
answers in ~5 ms when the port is open and gives up in 250 ms when it is not; ask HTTP only after
the socket says open. Codex cold relaunch went 10.5 s -> 5.9 s from this plus replacing a fixed
`Start-Sleep 2` after `Stop-Process` with an exit poll (processes gone in 150-210 ms).
