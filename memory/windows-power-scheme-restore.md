# Windows: restore a DELETED built-in power plan (High Performance) without `restoredefaultschemes`

Measured 2026-08-17 on DESKTOP-XUYU (Windows 10 19045, AMD Ryzen desktop, S3 sleep, no Modern
Standby, PS 5.1) while switching the machine to 高性能 + 60-min sleep. Generic Windows behaviour.

## Symptom → cause
- `powercfg /list` showed 卓越性能 / 平衡 / AMD Ryzen Balanced / GamePP but no 高性能 or 节能.
- `powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c` → "参数无效";
  `powercfg /duplicatescheme 8c5e7fda-…` → "指定的电源方案、子组或设置不存在".
  The well-known "restore High Performance with duplicatescheme" trick only works when the plan is
  merely *hidden* (Modern Standby / S0 machines); it needs the source key to still exist.
- `powercfg /list` enumerates subkeys of
  `HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes`. Someone (optimizer / GamePP /
  manual `powercfg /delete`) had removed the 8c5e7fda (HP) and a1841308 (Power saver) keys.
  There is NO `…\Power\User\Default\PowerSchemes` template hive on this build.

## Why recreating just the key is enough (stock result, not a copy)
Scheme keys are sparse — Balanced had only FriendlyName/Description + 3 subkeys. Every unset
setting falls back to
`…\Power\PowerSettings\<subgroup>\<setting>\DefaultPowerSchemeValues\<schemeGUID>` (AC/DCSettingIndex),
and those survive deletion (141 settings still carried HP defaults). So a key containing only
- `FriendlyName = @C:\WINDOWS\system32\powrprof.dll,-13,High performance`
- `Description  = @C:\WINDOWS\system32\powrprof.dll,-12,Favors performance, but may use more energy.`
lists as localized 高性能 with min CPU 100 % / display 15 min / sleep never — the factory plan.
powrprof.dll string pairs (name/description): -11/-10 Power saver, -13/-12 High performance,
-15/-14 Balanced, -19/-18 Ultimate Performance (resolve with `shlwapi!SHLoadIndirectString`).

## Only SYSTEM can write there — even elevated PowerShell fails
`PowerSchemes` ACL: SYSTEM FullControl; Administrators and Users ReadKey (+ GENERIC_READ inherit).
An elevated `New-Item` still throws "不允许所请求的注册表访问权" — Windows itself writes via the
power service. Working recipe (one UAC prompt):
```powershell
# inside a Start-Process powershell -Verb RunAs script:
$a = New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$sysScript`""
$p = New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName ClaudeRestoreHighPerf -Action $a -Principal $p -Force | Out-Null
Start-ScheduledTask ClaudeRestoreHighPerf   # $sysScript does New-Item + New-ItemProperty, logs whoami
# poll for the log, then:
Unregister-ScheduledTask ClaudeRestoreHighPerf -Confirm:$false
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c   # these go through the power service — no ACL issue
powercfg -change standby-timeout-ac 60; powercfg -change standby-timeout-dc 60
```
Verify: `powercfg /q SCHEME_CURRENT SUB_SLEEP STANDBYIDLE` → 0x00000e10 (3600 s) both AC/DC.
Rejected alternative: `powercfg -restoredefaultschemes` rebuilds the whole key set (custom plans
AMD Ryzen Balanced / GamePP / duplicated Ultimate at risk, Balanced overrides reset).

## Gotchas hit on the way
- The Claude harness blocked one PowerShell call that contained `Remove-Item …` and, later in a
  here-string, `powercfg /list` ("Remove-Item on system path '/list' is blocked") — nothing ran.
  Use `powercfg -l` and keep any delete in its own call.
- `Start-Process -Verb RunAs` returns immediately; the elevated script must log to a file and the
  caller polls ≤ 100 s (UAC auto-dismisses at ~120 s, tool timeout 120 s default).
- Diagnosis tip: `ActiveOverlayAcPowerScheme = ded574b5-…` (Max Performance Overlay) under
  `PowerSchemes` means Balanced + power-slider "最佳性能" — the user *felt* they were on 卓越性能 while
  the active plan was actually 平衡. Overlays only apply to Balanced; irrelevant once HP is active.
- Machine state after 2026-08-17: HP recreated + active, sleep 60 min; 节能 (a1841308) still
  missing (out of scope, same recipe restores it with strings -11/-10).
