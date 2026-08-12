<#
.SYNOPSIS
  Apply (or revert) the Windows video-wallpaper patch for Codex Dream Skin.

.DESCRIPTION
  Upstream Dream Skin ships image-only wallpapers on Windows. This installs a
  ported video layer plus a sidebar-transparency toggle. Idempotent and
  self-verifying: it detects whether the patch is already present and always
  runs the injector's own payload self-check afterwards.

  Re-run after every Dream Skin update -- Setup.exe replaces payload\ wholesale.

.PARAMETER Revert
  Restore the pristine upstream files instead of patching.

.PARAMETER Force
  Re-copy patched files even if the patch is already detected.
#>
[CmdletBinding()]
param(
    [switch]$Revert,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$SkillRoot = Split-Path -Parent $PSScriptRoot
$Payload   = Join-Path $env:LOCALAPPDATA 'Programs\CodexDreamSkin\payload'
$ThemeDir  = Join-Path $env:LOCALAPPDATA 'CodexDreamSkin\active-theme'

$Files = @(
    @{ Rel = 'assets\renderer-inject.js'; Src = 'renderer-inject.js' },
    @{ Rel = 'assets\dream-skin.css';     Src = 'dream-skin.css' },
    @{ Rel = 'scripts\injector.mjs';      Src = 'injector.mjs' }
)

if (-not (Test-Path $Payload)) {
    throw "Dream Skin payload not found at $Payload. Install Codex Dream Skin first."
}

$rendererPath = Join-Path $Payload 'assets\renderer-inject.js'
$isPatched = (Select-String -Path $rendererPath -Pattern 'videoDataUrl' -Quiet -ErrorAction SilentlyContinue) -eq $true
Write-Host "Current state: $(if ($isPatched) { 'PATCHED' } else { 'stock' })"

$sourceDir = Join-Path $SkillRoot $(if ($Revert) { 'assets\original' } else { 'assets\patched' })
if (-not (Test-Path $sourceDir)) { throw "Source files missing: $sourceDir" }

if ($Revert) {
    Write-Host 'Reverting to stock files...'
} elseif ($isPatched -and -not $Force) {
    Write-Host 'Patch already applied; nothing to do. Use -Force to re-copy.'
    exit 0
} else {
    Write-Host 'Applying video patch...'
}

# One-time safety net: keep whatever was there before this script first ran.
$backupDir = Join-Path $env:LOCALAPPDATA 'CodexDreamSkin\patch-backup'
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    foreach ($f in $Files) {
        $src = Join-Path $Payload $f.Rel
        if (Test-Path $src) { Copy-Item $src (Join-Path $backupDir $f.Src) -Force }
    }
    Write-Host "  pre-patch backup -> $backupDir"
}

foreach ($f in $Files) {
    $src = Join-Path $sourceDir $f.Src
    $dst = Join-Path $Payload $f.Rel
    if (-not (Test-Path $src)) { throw "Missing source file: $src" }
    Copy-Item $src $dst -Force
    Write-Host ("  {0,-26} <- {1:N0} bytes" -f $f.Rel, (Get-Item $dst).Length)
}

# The injector validates placeholder substitution and parses the assembled
# script, so this catches a broken patch before Codex ever loads it.
$node = Join-Path $Payload 'runtime\node\node.exe'
$inj  = Join-Path $Payload 'scripts\injector.mjs'
if ((Test-Path $node) -and (Test-Path $ThemeDir)) {
    Write-Host 'Running payload self-check...'
    $out = & $node $inj --check-payload --theme-dir $ThemeDir 2>&1
    $text = ($out | Out-String)
    if ($text -match '"pass"\s*:\s*true') {
        Write-Host '  self-check PASS'
    } else {
        Write-Warning "  self-check did not report pass:`n$text"
        exit 1
    }
} else {
    Write-Warning '  skipped self-check (node or active-theme missing)'
}

Write-Host ''
Write-Host 'Done. Restart Dream Skin to load the change:'
Write-Host '  powershell -NoProfile -ExecutionPolicy RemoteSigned -File "' -NoNewline
Write-Host (Join-Path $Payload 'scripts\start-dream-skin.ps1') -NoNewline
Write-Host '"'
