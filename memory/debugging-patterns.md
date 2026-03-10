# Debugging Patterns

## Native Crash Bisection with File Markers
When debugging crashes/hangs in compiled code where debuggers can't attach:
1. Write markers to a file using `open("debug.txt", "a") + flush()` at suspect locations
2. Run process for N seconds, kill it, read the file
3. Last marker = crash/hang point
4. Add more markers between last-written and next-expected to narrow down
5. Repeat until exact call identified

## Win32 Message Queue Inspection via ctypes
When SDL2/pygame event functions hang, bypass them with direct Win32 API:
```python
import ctypes, ctypes.wintypes
user32 = ctypes.windll.user32
msg = ctypes.wintypes.MSG()
# Peek without removing (PM_NOREMOVE = 0)
while user32.PeekMessageW(ctypes.byref(msg), 0, 0, 0, 0):
    print(f"hwnd={msg.hWnd} msg=0x{msg.message:04X}")
    # Remove (PM_REMOVE = 1)
    user32.PeekMessageW(ctypes.byref(msg), 0, 0, 0, 1)
    user32.DispatchMessageW(ctypes.byref(msg))
```
Filter specific message ranges: `PeekMessageW(byref(msg), 0, wMsgFilterMin, wMsgFilterMax, 1)`

## Windows Known DLLs
These DLLs CANNOT be overridden by placing a copy in the application directory:
- opengl32.dll, kernel32.dll, user32.dll, gdi32.dll, ntdll.dll, etc.
- Full list in registry: `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\KnownDLLs`
- ANGLE DLLs (libEGL.dll, libGLESv2.dll) CAN be overridden locally

## SDL2 + AMD RDNA 4 Issues
- SDL2 2.0.20 has compatibility issues with AMD RDNA 4 (RX 9070 series)
- OpenGL path: heap corruption (0xC0000374)
- ANGLE/D3D11 path: WM_USER (0x0400) deadlock in DispatchMessage
- Fix: drain WM_USER range (0x0400-0x7FFF) before SDL_PumpEvents using PeekMessageW with PM_REMOVE

## Ren'Py Specific
- `.rpyc` compiled files override `.rpy` source — delete `.rpyc` after editing `.rpy`
- `librenpython.dll` contains statically linked SDL2 — cannot update SDL2 separately
- Renderer preference stored in persistent data — may need to reset programmatically
- `renpy.style.rebuild()` is compiled Cython — can corrupt heap on certain GPU/driver combos
