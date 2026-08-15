---
name: windows-disk-usage-scanning
description: Sizing directories on Windows — Get-ChildItem -Recurse times out on system trees; robocopy /L is ~100x faster and reparse-point safe
metadata:
  type: reference
---

To measure directory sizes on Windows, use `robocopy` in list-only mode, **never**
`Get-ChildItem -Recurse | Measure-Object -Sum`.

Measured on `C:\` (380 GB used, 2026-08-15): the `Get-ChildItem` approach over ~26
top-level directories **exceeded a 600 s timeout and had to be killed**. The
robocopy equivalent returned all of them in seconds.

```powershell
function Get-DirSizeGB {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    # /L list-only (no copy), /BYTES exact, /NFL /NDL /NJH suppress file+dir+header
    # noise, /XJ skips junctions (prevents double-count and infinite descent),
    # /R:0 /W:0 = never retry on locked files
    $out = robocopy "$Path" "$env:TEMP\__rc_size_dummy__" /L /E /BYTES /NFL /NDL /NJH /XJ /R:0 /W:0 2>$null
    foreach ($ln in $out) {
        if ($ln -match '(?:Bytes|字节)\s*[:：]\s*(\d+)') {
            return [math]::Round([double]$matches[1] / 1GB, 2)
        }
    }
    return 0
}
```

## The summary block is LOCALIZED — never parse it by column index

This burned a whole cycle on 2026-08-16. The obvious parse
(`Select-String '^\s+Bytes :'` then `-split '\s+'` and take `[3]`) works when
developing and silently returns 0 for every path in the user's own console:

```
CP 65001 (agent harness) ->  "   Bytes : 145301255 ..."   space before colon, field [3]
CP 936   (real zh-CN box) ->  "       字节: 145301255 ..."  NO space before colon, field [2]
```

Two independent breakages in one line: the label is translated **and** the column
index shifts. Match the label with a regex and take the first number after it.

**A size of 0 must never gate a destructive action.** The original code did
`if ($before -le 0) { return 0 }` before cleaning — so under CP 936 the cleanup
silently skipped everything while printing a clean-looking report. Pair the size
read with a separate emptiness check:

```powershell
$first = Get-ChildItem -LiteralPath $Path -Force -EA SilentlyContinue | Select-Object -First 1
if (-not $first) { return }        # genuinely empty
# non-empty but unmeasurable -> proceed anyway, do not skip
```

## CJK in a .ps1 requires a UTF-8 BOM

Same session, second bug: a probe script written as BOM-less UTF-8 had `字节`
in its regex. PowerShell 5.1 decodes a BOM-less file with the ANSI codepage, so
the literal became mojibake and the regex could never match — the fix looked
broken until the BOM went on. Always re-encode generated .ps1 files:

```powershell
$t = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)
[IO.File]::WriteAllText($p, $t, (New-Object System.Text.UTF8Encoding($true)))
```

## .bat files: CRLF is non-negotiable, and prefer pure ASCII

Third bug, found only when the user double-clicked the launcher (2026-08-16):
the Write tool emits **LF-only** line endings, and cmd.exe requires CRLF.
With bare LF, cmd executes byte-offset fragments of lines — the console fills
with `'maticall y.' 不是内部或外部命令` style garbage, one error per fragment.
The file parsed fine in every static check; only an actual `cmd /c` run showed it.

Rules for generated `.bat`:
- Always normalize to CRLF after writing:
  `$t = ($t -replace "`r`n","`n") -replace "`n","`r`n"` then write ASCII.
- Keep launchers **pure ASCII** and put every localized string in the `.ps1`.
  GBK (`GetEncoding(936)`) works for Chinese in `.bat`, but mixing `chcp` into a
  file mid-stream shifts cmd's byte offsets — simplest is no non-ASCII at all.
- Test with a real `cmd /c` run, stubbing slow payloads: force branch conditions
  (`if 1 neq 1 goto ...`), replace the payload line with `echo MARKER`, strip
  `pause`. Grep output for `不是内部或外部命令|is not recognized`.
  Caveat: `echo` does not reset errorlevel, so a stubbed run may show a stale
  exit-code message that the real payload would not.

**Verify generated scripts in a real elevated console, not in the harness.** The
harness runs CP 65001 with English tool output; the user's console does not. Every
one of these bugs was invisible until the script ran through
`Start-Process -Verb RunAs` and wrote its findings to a file.

## cleanmgr and Start-Process -Wait hangs (live-run lessons, 2026-08-16)

- `cleanmgr /sagerun:N` reliably **removed a 45 GB Windows.old in ~10 min, then
  idled forever** on the "Update Cleanup" handler (37 min, CPU delta 0 over 5 s).
  Killing cleanmgr at that point is safe — the deletion work was already done, and
  DISM `StartComponentCleanup` covers update cleanup anyway. Diagnose "working vs
  hung" by sampling `(Get-Process x).CPU` twice a few seconds apart, never by wall
  time alone.
- **PS 5.1 `Start-Process -Wait` waits on the process TREE and can wedge forever
  when the direct child is force-killed** while a grandchild (DismHost) briefly
  outlives it. The wait never returned even after every descendant was gone; the
  host had to be killed. Design cleanup scripts to be **idempotent** (each section
  begins with a Test-Path / emptiness check) so the recovery is simply "kill the
  host, rerun the whole script" — completed sections skip themselves.
- Monitoring a PowerShell transcript with `tail -F | grep`: DISM writes
  progress-bar control chars, grep flags the stream as **binary and silently stops
  emitting lines**. Use `grep -a`. Strip for display with
  `-replace '[\x00-\x08\x0B\x0C\x0E-\x1F]',''`.
- Elevated processes hide their CommandLine from a non-elevated `Win32_Process`
  query (null) — match them by ParentProcessId instead of command-line text.

Why it wins:
- **Reparse-point safe.** `/XJ` skips junctions. `C:\Users\All Users` is a junction
  to `ProgramData` and `Documents and Settings` points at `Users` — without `/XJ`
  these double-count or loop. `Get-ChildItem -Recurse` has no clean equivalent.
- **No object materialization.** robocopy streams a summary; Get-ChildItem builds a
  `FileInfo` object per file (hundreds of thousands under `C:\Windows`).
- **Access-denied is silent**, not a per-file error record.

Gotchas:
- robocopy's exit codes are bit flags where **0-7 mean success** — 1 = files copied,
  2 = extra files, 8+ = real failure. Any wrapper that treats non-zero as failure
  will false-alarm; PowerShell tool harnesses report these as "Exit code 1/9".
- Returns 0 (not an error) for paths the user cannot read. Without elevation
  `C:\Windows\Temp`, `Prefetch`, `WER`, and `DeliveryOptimization` all read as
  inaccessible — **check `IsInRole(Administrator)` before trusting a system scan**.
- The destination path is never written to, but pick one that does not exist.

Related: [[debugging-patterns]]
