#Requires -RunAsAdministrator
<#
    TinyWall Uninstaller
    Replicates the Wix MSI uninstaller behavior.
#>

$ErrorActionPreference = 'Stop'

$ProductName = 'TinyWall'
$InstallDir = Join-Path $env:ProgramFiles $ProductName
$AppDataDir = Join-Path $env:ProgramData $ProductName
$StartMenuDir = Join-Path ([Environment]::GetFolderPath('CommonPrograms')) $ProductName
$InstalledExe = Join-Path $InstallDir 'TinyWall.exe'

if (-not (Test-Path $InstalledExe)) {
    Write-Error "$ProductName is not installed at $InstallDir."
    exit 1
}

Write-Host "Uninstalling $ProductName..." -ForegroundColor Cyan

# 1. Run TinyWall /uninstall (shows confirmation dialog, stops service, removes WFP filters,
#    deletes scheduled task, restores hosts file, unregisters service)
Write-Host "  Stopping service and cleaning up..."
$process = Start-Process -FilePath $InstalledExe -ArgumentList '/uninstall' -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) {
    if ($process.ExitCode -eq -1) {
        Write-Host "Uninstall cancelled by user." -ForegroundColor Yellow
        exit 0
    }
    Write-Warning "TinyWall /uninstall exited with code $($process.ExitCode)"
}

# 2. Remove Start Menu shortcuts
Write-Host "  Removing Start Menu shortcuts..."
if (Test-Path $StartMenuDir) {
    Remove-Item -Path $StartMenuDir -Recurse -Force
}

# 3. Remove registry keys
Write-Host "  Removing registry keys..."
$regPath = 'HKLM:\Software\TinyWall'
if (Test-Path $regPath) {
    Remove-Item -Path $regPath -Recurse -Force
}

$uninstallRegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProductName"
if (Test-Path $uninstallRegPath) {
    Remove-Item -Path $uninstallRegPath -Recurse -Force
}

# Clean up per-user registry key if present
$userRegPath = "HKCU:\Software\$ProductName"
if (Test-Path $userRegPath) {
    Remove-Item -Path $userRegPath -Recurse -Force
}

# 4. Remove application data
Write-Host "  Removing application data..."
if (Test-Path $AppDataDir) {
    Remove-Item -Path $AppDataDir -Recurse -Force
}

# 5. Remove install directory
#    Use cmd /c to avoid issues with PowerShell deleting the directory it's running from
Write-Host "  Removing program files..."
if (Test-Path $InstallDir) {
    cmd /c "rmdir /s /q `"$InstallDir`""
}

Write-Host ""
Write-Host "$ProductName has been uninstalled." -ForegroundColor Green
