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
    $out  = robocopy "$Path" "$env:TEMP\__rc_size_dummy__" /L /E /BYTES /NFL /NDL /NJH /XJ /R:0 /W:0 2>$null
    $line = $out | Select-String '^\s+Bytes :' | Select-Object -First 1
    if ($line) { return [math]::Round([double](($line.ToString() -split '\s+')[3]) / 1GB, 2) }
    return 0
}
```

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
