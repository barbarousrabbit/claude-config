<#
.SYNOPSIS
  Cut a clip from a source video and install it as the Codex wallpaper.

.DESCRIPTION
  Handles the whole loop: transcode -> size check -> place -> restart -> verify.
  The clip is base64-encoded into the injected payload and shipped over CDP, so
  size is the binding constraint, not visual quality. Defaults target ~2-4 MB.

.PARAMETER Video
  Source video. Any format ffmpeg can decode (mp4, webm, mov, mkv...).

.PARAMETER Start
  Start timestamp in seconds. Pick a segment with a quiet left side.

.PARAMETER Duration
  Clip length in seconds. Keep at or below 8.

.PARAMETER Crf
  x264 quality. Higher = smaller file. Raise to 28-30 if the clip is too big.

.PARAMETER NoRestart
  Transcode and place the file but leave Codex alone.

.EXAMPLE
  .\set-video.ps1 -Video "D:\clips\city.mp4" -Start 41
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Video,
    [double]$Start = 0,
    [int]$Duration = 8,
    [int]$Crf = 26,
    [switch]$NoRestart
)

$ErrorActionPreference = 'Stop'
$MaxMB = 6

if (-not (Test-Path $Video)) { throw "Source video not found: $Video" }
if ($Duration -lt 1 -or $Duration -gt 20) { throw 'Duration must be between 1 and 20 seconds.' }

$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ffmpeg) {
    $guess = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe'
    $found = Get-ChildItem $guess -Recurse -Filter 'ffmpeg.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $ffmpeg = $found.FullName }
}
if (-not $ffmpeg) { throw 'ffmpeg not found. Install with: winget install Gyan.FFmpeg' }

$Payload  = Join-Path $env:LOCALAPPDATA 'Programs\CodexDreamSkin\payload'
$ThemeDir = Join-Path $env:LOCALAPPDATA 'CodexDreamSkin\active-theme'
if (-not (Test-Path $ThemeDir)) { throw "Active theme not found at $ThemeDir" }

$renderer = Join-Path $Payload 'assets\renderer-inject.js'
if (-not (Select-String -Path $renderer -Pattern 'videoDataUrl' -Quiet -ErrorAction SilentlyContinue)) {
    throw 'Video patch is not applied. Run apply-patch.ps1 first.'
}

$target = Join-Path $ThemeDir 'background-video.mp4'
$tmp    = Join-Path $env:TEMP ('dream-clip-' + [guid]::NewGuid().ToString('N') + '.mp4')

Write-Host "Transcoding ${Duration}s from ${Start}s (crf $Crf)..."
# -ss before -i is keyframe-accurate fast seek; -an drops useless audio bytes.
# loglevel is 'fatal' on purpose: fast-seeking VP9/WebM sources emits a wall of
# "Invalid data found when processing input" decode warnings that PowerShell 5.1
# renders as red NativeCommandError noise even on a clean exit. Real failures
# are caught by the output-file check below rather than by parsing stderr.
& $ffmpeg -hide_banner -loglevel fatal -y -ss $Start -t $Duration -i $Video `
    -vf 'scale=1920:1080:flags=lanczos,fps=30' `
    -c:v libx264 -profile:v high -pix_fmt yuv420p -crf $Crf -preset slow `
    -an -movflags +faststart $tmp

if (-not (Test-Path $tmp)) {
    throw "ffmpeg produced no output. Re-run the same ffmpeg command with -loglevel error to see why."
}

$mb = (Get-Item $tmp).Length / 1MB
Write-Host ("  clip: {0:N2} MB  (payload adds ~{1:N2} MB after base64)" -f $mb, ($mb * 1.37))
if ($mb -gt $MaxMB) {
    Remove-Item $tmp -Force
    throw ("Clip is {0:N2} MB, above the {1} MB ceiling. Re-run with a higher -Crf (e.g. {2}) or shorter -Duration." -f $mb, $MaxMB, ($Crf + 4))
}

Move-Item $tmp $target -Force
Write-Host "  installed -> $target"

if ($NoRestart) { Write-Host 'Skipping restart (-NoRestart).'; exit 0 }

Write-Host 'Restarting Dream Skin...'
Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
    Where-Object { $_.CommandLine -like '*CodexDreamSkin*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Get-CimInstance Win32_Process -Filter "Name='ChatGPT.exe' OR Name='Codex.exe'" |
    Where-Object { $_.ExecutablePath -like '*WindowsApps*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 3

Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'RemoteSigned',
    '-File', (Join-Path $Payload 'scripts\start-dream-skin.ps1')
)
Write-Host '  waiting for injection...'
Start-Sleep -Seconds 32

$log = Join-Path $env:LOCALAPPDATA 'CodexDreamSkin\injector.log'
if (Test-Path $log) { Write-Host ('  ' + (Get-Content $log -Tail 1)) }

$node  = Join-Path $Payload 'runtime\node\node.exe'
$probe = Join-Path $PSScriptRoot 'probe-video.mjs'
if ((Test-Path $node) -and (Test-Path $probe)) {
    Write-Host 'Verifying video layer...'
    & $node $probe
} else {
    Write-Warning 'probe-video.mjs unavailable; verify manually.'
}
