$InstallDir = "$HOME\rathole"
$Binary = "$InstallDir\rathole.exe"
$Config = "$InstallDir\config.toml"

# -------------------------
# Ensure administrator
# -------------------------
function Ensure-Admin {

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

        Write-Host "Requesting administrator privileges..."

        Start-Process powershell `
            -Verb runAs `
            -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""

        exit
    }
}

# -------------------------
# Defender exclusion
# -------------------------
function Add-DefenderExclusion {

    try {

        if (!(Test-Path $InstallDir)) {
            New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
        }

        Write-Host "Adding Windows Defender exclusion..."
        Add-MpPreference -ExclusionPath $InstallDir

    } catch {

        Write-Host "Warning: Could not add Defender exclusion."
    }
}

# -------------------------
# Install Rathole
# -------------------------
function Install-Rathole {

    if (!(Test-Path $Binary)) {

        Write-Host "Installing Rathole..."

        $zip = "$InstallDir\rathole.zip"
        $extract = "$InstallDir\extract"

        if (Test-Path $extract) {
            Remove-Item $extract -Recurse -Force
        }

        New-Item -ItemType Directory -Force -Path $extract | Out-Null

        $url = "https://github.com/rapiz1/rathole/releases/latest/download/rathole-x86_64-pc-windows-msvc.zip"

        Write-Host "Downloading..."
        Invoke-WebRequest $url -OutFile $zip

        Write-Host "Extracting..."
        tar -xf $zip -C $extract

        Move-Item "$extract\rathole.exe" $Binary -Force

        Remove-Item $zip -Force
        Remove-Item $extract -Recurse -Force

        Write-Host "Rathole installed."
    }
}

# -------------------------
# Create start script
# -------------------------
function Create-StartScript {

$start = @"
cd `"$InstallDir`"

# ensure ANSI colors
`$env:TERM = "xterm"

.\rathole.exe config.toml

pause
"@

    $start | Out-File "$InstallDir\start.ps1" -Encoding ascii
}

# -------------------------
# Desktop shortcut
# -------------------------
function Create-DesktopShortcut {

    $Desktop = [Environment]::GetFolderPath("Desktop")
    $ShortcutPath = "$Desktop\Start Rathole.lnk"

    $wt = Get-Command wt.exe -ErrorAction SilentlyContinue

    $WScript = New-Object -ComObject WScript.Shell
    $Shortcut = $WScript.CreateShortcut($ShortcutPath)

    if ($wt) {

        # Use Windows Terminal for proper colors
        $Shortcut.TargetPath = "wt.exe"
        $Shortcut.Arguments = "powershell -NoExit -ExecutionPolicy Bypass -File `"$InstallDir\start.ps1`""

    } else {

        # Fallback to normal PowerShell
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-NoExit -ExecutionPolicy Bypass -File `"$InstallDir\start.ps1`""

    }

    $Shortcut.WorkingDirectory = $InstallDir
    $Shortcut.Save()

    Write-Host "Desktop shortcut created."
}

# -------------------------
# Server setup
# -------------------------
function Server-Setup {

    $token = -join ((48..57 + 97..102) | Get-Random -Count 32 | % {[char]$_})

$configContent = @"
[server]
bind_addr = "0.0.0.0:2333"

[server.services.mc]
type = "tcp"
bind_addr = "0.0.0.0:25565"
token = "$token"

[server.services.mc-voice]
type = "udp"
bind_addr = "0.0.0.0:24454"
token = "$token"
"@

    $configContent | Out-File $Config -Encoding ascii

    Create-StartScript
    Create-DesktopShortcut

    Write-Host ""
    Write-Host "Server setup complete."
    Write-Host ""
    Write-Host "Auth token:"
    Write-Host $token
}

# -------------------------
# Client setup
# -------------------------
function Client-Setup {

    $server = Read-Host "Server IP"
    $token = Read-Host "Auth Token"

$configContent = @"
[client]
remote_addr = "$server`:2333"

[client.services.mc]
type = "tcp"
local_addr = "127.0.0.1:25565"
token = "$token"

[client.services.mc-voice]
type = "udp"
local_addr = "127.0.0.1:24454"
token = "$token"
"@

    $configContent | Out-File $Config -Encoding ascii

    Create-StartScript
    Create-DesktopShortcut

    Write-Host ""
    Write-Host "Client setup complete."
}

# -------------------------
# Main
# -------------------------
Ensure-Admin
Add-DefenderExclusion

Write-Host ""
Write-Host "Rathole Interactive Installer"
Write-Host ""
Write-Host "1) Server"
Write-Host "2) Client"
Write-Host ""

$mode = Read-Host "Select mode"

Install-Rathole

switch ($mode) {
    "1" { Server-Setup }
    "2" { Client-Setup }
    default { Write-Host "Invalid option" }
}