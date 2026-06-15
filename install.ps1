# Comprobot installer for Windows (PowerShell).
#
# Usage:
#   irm https://badluma.github.io/Comprobot-Website/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$DashboardRepo = 'badluma/Comprobot-Dashboard'

function Info($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "warning: $m" -ForegroundColor Yellow }

# Data dir must match appdirs.user_data_dir("Comprobot") on Windows:
#   %LOCALAPPDATA%\Comprobot\Comprobot
$DataDir = Join-Path $env:LOCALAPPDATA 'Comprobot\Comprobot'

# Make freshly installed tools usable in this same session.
function Ensure-Path {
    $bin = Join-Path $env:USERPROFILE '.local\bin'
    $bun = Join-Path $env:USERPROFILE '.bun\bin'
    $env:Path = "$bin;$bun;$env:Path"
}

# --- 1. uv: isolated Python + the bot CLI ------------------------------------
if (Get-Command uv -ErrorAction SilentlyContinue) {
    Info 'uv already installed'
} else {
    Info 'Installing uv (Python toolchain manager)'
    Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
}
Ensure-Path

# --- 2. bun: dashboard runtime -----------------------------------------------
if (Get-Command bun -ErrorAction SilentlyContinue) {
    Info 'bun already installed'
} else {
    Info 'Installing bun (dashboard runtime)'
    Invoke-RestMethod https://bun.sh/install.ps1 | Invoke-Expression
}
Ensure-Path

# --- 3. the bot --------------------------------------------------------------
Info 'Installing Comprobot'
uv tool install --force comprobot
Ensure-Path

# --- 4. resolve the dashboard version ----------------------------------------
$Ver = (& comprobot --dashboard-version) 2>$null
if (-not $Ver) {
    try {
        $Ver = (Invoke-RestMethod "https://api.github.com/repos/$DashboardRepo/releases/latest").tag_name
    } catch { $Ver = $null }
}

# --- 5. download + unpack the dashboard --------------------------------------
if ($Ver) {
    Info "Installing dashboard $Ver"
    $Url = "https://github.com/$DashboardRepo/archive/refs/tags/$Ver.zip"
} else {
    Warn 'No dashboard release found — using latest main'
    $Url = "https://github.com/$DashboardRepo/archive/refs/heads/main.zip"
}

$Tmp = Join-Path $env:TEMP ("comprobot-dash-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp -Force | Out-Null
$Zip = Join-Path $Tmp 'dashboard.zip'
Invoke-WebRequest -Uri $Url -OutFile $Zip
Expand-Archive -Path $Zip -DestinationPath $Tmp -Force

New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
$Dest = Join-Path $DataDir 'dashboard'
if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
# the archive extracts to a single top-level dir (repo-tag\)
$Extracted = Get-ChildItem -Path $Tmp -Directory | Select-Object -First 1
Move-Item $Extracted.FullName $Dest
Remove-Item $Tmp -Recurse -Force

# --- 6. onboarding (interactive) + start -------------------------------------
Info 'Launching onboarding…'
comprobot onboard
