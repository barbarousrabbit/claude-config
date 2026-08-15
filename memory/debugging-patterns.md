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

## Windows: hook/CLI stdin must be read as UTF-8 bytes for char-level analysis
A hook (e.g. a UserPromptSubmit hook) that reads its JSON payload from stdin and then inspects characters in Python — counting CJK to detect language, etc. — silently fails on Windows if it uses text-mode stdin.
- **Symptom**: Chinese input is misclassified (e.g. a `[reply-language]` detector reports "English" for a Chinese message; a `grep` for 作业/考试 never matches). Char counts come back 0 even though the text clearly contains those chars.
- **Root cause**: Python text-mode `sys.stdin` / `json.load(sys.stdin)` decodes with the OS locale codec (cp1252/gbk on Windows), NOT UTF-8. Non-ASCII bytes get mojibake'd, so any codepoint/range check returns 0.
- **Why a bash pipeline survives but Python char-ops don't**: `python -c "print(d['prompt'])" | grep …` works because the mis-decode is reversed when stdout re-encodes with the same wrong codec — a byte round-trip that bash byte-matches. The moment you do `ord(ch)` or a regex char-class INSIDE Python, the mis-decode is fatal.
- **Fix 1 — read bytes, decode UTF-8 explicitly**:
```python
raw = sys.stdin.buffer.read().decode('utf-8', 'replace')
prompt = json.loads(raw).get('prompt', '') or ''
```
- **Fix 2 — never embed CJK literals or `\uXXXX` escapes inside a `python -c "…"` string passed through bash**; argv/file encoding can corrupt them on a different machine. Use codepoint math with ASCII hex bounds:
```python
han = sum(1 for ch in prompt if 0x4e00 <= ord(ch) <= 0x9fff)   # CJK Unified
lat = sum(1 for ch in prompt if ('A' <= ch <= 'Z') or ('a' <= ch <= 'z'))
```
Used in `scripts/hook-user-prompt.sh` Layer 0 (reply-language anti-drift detection). A 2-hour debugging session compressed to: "read stdin as UTF-8 bytes."

## PowerShell: a helper function named `Git` shadows the real git command
A wrapper function that pins repo/flags for every call — a natural pattern for sync scripts — dies instantly if you name it after the command it wraps.
- **Symptom**: `The script failed due to call depth overflow. CategoryInfo: InvalidOperation (0:Int32) [], ParentContainsErrorRecordException, FullyQualifiedErrorId: CallDepthOverflow`. Nothing runs; no git output at all.
- **Root cause**: PowerShell resolves command names **case-insensitively**, and functions outrank external executables in the command-precedence order. So inside `function Git { & git -C $Root @Args }`, the `git` call resolves back to `Git` itself and recurses until the call-depth limit.
```powershell
function Git { & git -C $RepoRoot @Args }   # infinite recursion
```
- **Fix — two independent guards, use both**: name the helper with a verb-noun that cannot collide, and call the executable by its full name so function lookup can't match it.
```powershell
function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    & git.exe -C $RepoRoot -c core.quotepath=false @Args
}
```
- `git.exe` is the load-bearing half: it makes the recursion impossible even if someone later renames the function back. The rename is what stops a future `git status` typed inside the script from silently recursing.
- **Same trap** for any wrapper named after its tool: `Docker`, `Npm`, `Gh`, `Python`. Applies to aliases too — `Set-Alias git Invoke-Git` then calling `git` inside `Invoke-Git` recurses identically.
- Bonus, same family of scripts: native git prints UTF-8, but PowerShell 5.1 decodes native output with the ANSI codepage, so CJK filenames come back mangled. Set `[Console]::OutputEncoding = [Text.Encoding]::UTF8` at the top and pass `-c core.quotepath=false`.

### Same family: a PowerShell parameter named `$Args` swallows `-A`
The wrapper above has a second trap in its parameter, not its name:
```powershell
function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)   # bad
    & git.exe @Args
}
Invoke-Git add -A
# Invoke-Git : Missing an argument for parameter 'Args'.
```
- **Root cause**: PowerShell binds parameters by **prefix**, so `-A` matches the parameter `-Args` and is consumed as a parameter name; the next token becomes its value, or binding fails outright. Any argument that prefix-matches the parameter name is stolen before `ValueFromRemainingArguments` ever sees it. (`$Args` also shadows the automatic `$args`.)
- **Fix**: never name a catch-all parameter after something a passthrough argument could prefix-match — `$GitArgs`, `$Rest`, `$Passthru`. Verify with the actual flag: `Invoke-Git add -A` must reach git.
- **Related**: passing a long multi-line string as a native-command argument (`git commit -m $msg`) is fragile on 5.1 — quoting and the ANSI codepage both apply. Write it to a UTF-8 file and use the tool's file flag (`git commit -F <file>`); git reads the bytes and no shell quoting happens.

## Windows: `Get-ChildItem` silently skips Hidden files — cleanup scripts under-report as "done"
Any sweep that enumerates files to delete/count/validate must pass `-Force`, or hidden items are invisible and the script reports success over an incomplete job.
- **Symptom**: a cleanup reports "0 remaining", but `ls -la` in Git Bash (or `dir /a`) still lists the files. The two tools disagree because only PowerShell applies the hidden filter by default.
- **Root cause**: `Get-ChildItem` omits Hidden/System entries unless `-Force` is given. `-Filter`/`-File`/`-Recurse` do not re-include them. BitTorrent clients, installers, and sync tools routinely set Hidden on sidecar files (`.torrent`, `.nfo`, state files).
- **Cost when missed**: a "delete all `.torrent` library-wide" pass reported complete; two batches later 57 hidden ones were still there, because the per-folder cleanup used `Get-ChildItem -File -Filter *.torrent` with no `-Force`.
- **Fix — enumerate with `-Force`, and clear the attribute before deleting** (`Remove-Item -Force` handles ReadOnly, not always Hidden+System combos):
```powershell
Get-ChildItem -LiteralPath $dir -Recurse -File -Force -Filter *.torrent |
  ForEach-Object { $_.Attributes = [IO.FileAttributes]::Normal; Remove-Item -LiteralPath $_.FullName -Force }
```
- **Verify by invariant, not by the script's own count**: measure something the operation must not change (e.g. video-file count before/after a `.torrent` purge) and assert it held. A self-reported "N deleted" cannot detect what it never saw.
- **Cross-check cheaply**: `Get-ChildItem -Force | Measure-Object` vs the same without `-Force`; any gap is hidden items.

## Windows: NTFS junctions store an ABSOLUTE path and do not survive a parent rename
A junction created inside a tree keeps pointing at the old absolute path after any ancestor directory is renamed or moved — it does not resolve relatively.
- **Symptom**: the junction directory still exists and looks fine in Explorer, but enumerating it yields nothing. Scripts that only check `Test-Path <junction>` report **valid** (the reparse point exists) — the breakage is one level deeper.
- **Detection**: a broken junction is a directory that exists but enumerates empty; compare `(Get-Item $j).Target` against the real path.
```powershell
$broken = @(Get-ChildItem $dir -Directory |
  Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force -EA SilentlyContinue).Count -eq 0 })
```
- **Audit blind spot that hides this for months**: link-validation passes usually glob `*.lnk`. Junctions are directories, so `-Filter *.lnk` never sees them and the audit prints all-green. Any audit that validates shortcuts must enumerate `-Directory` too.
- **Removing one is dangerous**: `Remove-Item -Recurse` on a junction deletes the *target's* contents. Detach the reparse point only: `[IO.Directory]::Delete($path, $false)` or `cmd /c rmdir "$path"` (no `/s`). Verify the target's files still exist afterward.
- **Rule**: any script that rewrites hardcoded root paths after a rename (e.g. `sed` over a `_tools/` directory) must also **rebuild every junction** — text substitution fixes scripts, not reparse points already on disk.
