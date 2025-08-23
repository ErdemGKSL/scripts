# Requires: PowerShell 5+
# - Prompts for remote IP/host and token
# - Creates %APPDATA%\.rathole
# - Adds Microsoft Defender exclusion for the entire folder
# - Downloads ZIP into the excluded folder and extracts rathole.exe there
# - Writes client.toml
# - Creates/updates a Windows service to run: .\rathole.exe .\client.toml
# - Starts or restarts the service

param()

# Self-elevate if not running as Administrator (needed for Defender exclusion
# and creating a service)
$currUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currUser)
if (-not $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
  )) {
  Write-Host "Elevation required. Prompting for Administrator..."
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "powershell.exe"
  $psi.Arguments =
    "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  $psi.Verb = "runas"
  try {
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.WaitForExit()
    exit $p.ExitCode
  } catch {
    Write-Error "Elevation canceled or failed."
    exit 1
  }
}

# Prompt user inputs
$remote = Read-Host "Enter remote IP or hostname (e.g., 203.0.113.10)"
if ([string]::IsNullOrWhiteSpace($remote)) {
  Write-Error "Remote IP/host is required."
  exit 1
}
$token = Read-Host "Enter default token"
if ([string]::IsNullOrWhiteSpace($token)) {
  Write-Error "Token is required."
  exit 1
}

# Paths and constants
$Url =
  "https://github.com/rathole-org/rathole/releases/download/v0.5.0/" +
  "rathole-x86_64-pc-windows-msvc.zip"
$AppDir = Join-Path $env:APPDATA ".rathole"
$ZipPath = Join-Path $AppDir "rathole-client.zip"   # Download inside excluded folder
$ExePath = Join-Path $AppDir "rathole.exe"
$TomlPath = Join-Path $AppDir "client.toml"
$RunnerPath = Join-Path $AppDir "run-rathole.ps1"
$ServiceName = "rathole-client"
$ServiceDisplay = "Rathole Client"
$PowerShellExe =
  "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

# Ensure TLS 1.2 for download
[Net.ServicePointManager]::SecurityProtocol =
  [Net.SecurityProtocolType]::Tls12

# Create app directory first (needed for Defender exclusion)
New-Item -Path $AppDir -ItemType Directory -Force | Out-Null

# Add Microsoft Defender exclusion for the folder (recursively bypass)
function Add-DefenderExclusion {
  param([string]$Path)
  $mpPref = Get-Command Add-MpPreference -ErrorAction SilentlyContinue
  if (-not $mpPref) {
    Write-Warning "Defender cmdlets not available. Skipping exclusion."
    return
  }
  try {
    $current = (Get-MpPreference).ExclusionPath
    if ($current -and ($current -contains $Path)) {
      Write-Host "Defender exclusion already present for: $Path"
    } else {
      Write-Host "Adding Microsoft Defender exclusion for: $Path"
      Add-MpPreference -ExclusionPath $Path
    }
  } catch {
    Write-Warning ("Failed to add Defender exclusion. Tamper Protection or " +
      "policy may block this. Add it manually if needed. Error: {0}" -f
      $_.Exception.Message)
  }
}

Add-DefenderExclusion -Path $AppDir

# Download zip into excluded folder
Write-Host "Downloading rathole.exe ZIP to $ZipPath ..."
try {
  Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
} catch {
  Write-Error "Failed to download: $($_.Exception.Message)"
  exit 1
}

# Extract the ZIP (contains rathole.exe) into excluded folder
Write-Host "Extracting to $AppDir ..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
try {
  if (Test-Path $ExePath) { Remove-Item $ExePath -Force }
  # Extract to temp subdir inside excluded folder to ensure overwrite
  $tmpDir = Join-Path $AppDir ("_tmp_" + [Guid]::NewGuid())
  New-Item $tmpDir -ItemType Directory | Out-Null
  [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $tmpDir)
  Copy-Item (Join-Path $tmpDir "rathole.exe") $ExePath -Force
  Remove-Item $tmpDir -Recurse -Force
} finally {
  Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $ExePath)) {
  Write-Error "rathole.exe not found after extraction."
  exit 1
}

# Unblock the executable (remove MOTW)
try { Unblock-File -Path $ExePath -ErrorAction SilentlyContinue } catch {}

# Create client.toml with provided values
@"
[client]
remote_addr = "$remote:2333"
default_token = "$token"

[client.services.mc]
local_addr = "127.0.0.1:25565"
"@ | Set-Content -Path $TomlPath -Encoding ASCII

# Create runner script to ensure working directory and exact command form
@"
# Auto-generated launcher for Rathole client
Set-Location -Path '$AppDir'
# Run exactly: .\rathole.exe .\client.toml
& '.\rathole.exe' '.\client.toml'
"@ | Set-Content -Path $RunnerPath -Encoding UTF8

# Create or update service pointing to the runner script
$binArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$RunnerPath`""
$binPath = "`"$PowerShellExe`" $binArgs"

$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($null -eq $existing) {
  Write-Host "Creating Windows service '$ServiceName' ..."
  New-Service `
    -Name $ServiceName `
    -BinaryPathName $binPath `
    -DisplayName $ServiceDisplay `
    -Description "Rathole client tunnel" `
    -StartupType Automatic | Out-Null
} else {
  Write-Host "Service '$ServiceName' already exists. Updating path..."
  sc.exe config $ServiceName binPath= $binPath | Out-Null
}

# Start or restart service
$svc = Get-Service -Name $ServiceName -ErrorAction Stop
if ($svc.Status -eq 'Running') {
  Write-Host "Restarting service..."
  Restart-Service -Name $ServiceName -Force
} else {
  Write-Host "Starting service..."
  Start-Service -Name $ServiceName
}

Write-Host "Done."
Write-Host "Folder: $AppDir"
Write-Host "Config: $TomlPath"
Write-Host "Service: $ServiceName (Automatic)"
Write-Host "Defender exclusion applied to: $AppDir"
Write-Host "Verify with: `(Get-MpPreference).ExclusionPath`"
