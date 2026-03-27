#Requires -RunAsAdministrator
<#
    TinyWall Installer
    Replicates the Wix MSI installer behavior.
    Must be run from the directory containing TinyWall.exe.
#>

$ErrorActionPreference = 'Stop'

$ProductName = 'TinyWall'
$Manufacturer = 'Karoly Pados'
$Description = 'A non-intrusive firewall solution.'
$ProductURL = 'http://tinywall.pados.hu'
$InstallDir = Join-Path $env:ProgramFiles $ProductName
$AppDataDir = Join-Path $env:ProgramData $ProductName
$StartMenuDir = Join-Path ([Environment]::GetFolderPath('CommonPrograms')) $ProductName
$SourceDir = $PSScriptRoot

# Verify TinyWall.exe exists in script directory
$SourceExe = Join-Path $SourceDir 'TinyWall.exe'
if (-not (Test-Path $SourceExe)) {
    Write-Error "TinyWall.exe not found in $SourceDir. Place this script next to TinyWall.exe."
    exit 1
}

# Check Windows version (build 19044+)
$BuildNumber = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber
if ($BuildNumber -lt 19044) {
    Write-Error "This application requires Windows 10 version 21H2 (build 19044) or newer."
    exit 1
}

Write-Host "Installing $ProductName..." -ForegroundColor Cyan

# 1. Stop any existing TinyWall service and processes
#    Handles upgrades from both x64 (Program Files) and x86 (Program Files (x86)) installs
$isUpgrade = $false
$existingExe = Join-Path $InstallDir 'TinyWall.exe'
$oldx86Dir = Join-Path ${env:ProgramFiles(x86)} $ProductName
$oldx86Exe = Join-Path $oldx86Dir 'TinyWall.exe'

if ((Test-Path $existingExe) -or (Test-Path $oldx86Exe)) {
    $isUpgrade = $true
}

$svc = Get-Service -Name 'TinyWall' -ErrorAction SilentlyContinue
if ($svc -or $isUpgrade) {
    Write-Host "  Stopping existing TinyWall service and controller..."

    # Stop the service gracefully
    if ($svc -and $svc.Status -ne 'Stopped') {
        Stop-Service -Name 'TinyWall' -Force -ErrorAction SilentlyContinue
        try {
            $svc.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(10))
        } catch {
            Write-Host "  Service did not stop gracefully, forcing..."
        }
    }

    # Kill ALL TinyWall processes from any location (service, controller, old x86 install)
    Get-Process | Where-Object {
        $_.ProcessName -like "*TinyWall*" -or
        ($_.Path -and $_.Path -like "*TinyWall*")
    } | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3

    # Unregister the old service so /install can re-register it with the new binary path
    sc.exe stop TinyWall 2>$null | Out-Null
    sc.exe delete TinyWall 2>$null | Out-Null

    # Wait and verify the service is gone
    $retries = 0
    while ((Get-Service -Name 'TinyWall' -ErrorAction SilentlyContinue) -and $retries -lt 10) {
        Start-Sleep -Seconds 1
        $retries++
    }
    if (Get-Service -Name 'TinyWall' -ErrorAction SilentlyContinue) {
        Write-Error "Failed to remove existing TinyWall service. Please reboot and try again."
        exit 1
    }
}

# 2. Create install directory and copy all build output
Write-Host "  Copying files to $InstallDir..."
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Copy everything from the source directory (exe, DLLs, localization folders, docs, etc.)
Get-ChildItem -Path $SourceDir | ForEach-Object {
    if ($_.PSIsContainer) {
        Copy-Item -Path $_.FullName -Destination (Join-Path $InstallDir $_.Name) -Recurse -Force
    } else {
        Copy-Item -Path $_.FullName -Destination $InstallDir -Force
    }
}

# 3. Create ProgramData directory (preserve existing config on upgrades)
Write-Host "  Creating application data directory..."
if (-not (Test-Path $AppDataDir)) {
    New-Item -ItemType Directory -Path $AppDataDir -Force | Out-Null
}

# 4. Set registry keys
Write-Host "  Writing registry keys..."
$regPath = 'HKLM:\Software\TinyWall'
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
Set-ItemProperty -Path $regPath -Name 'InstallDir' -Value "$InstallDir\"

# Add/Remove Programs entry
$uninstallRegPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$ProductName"
if (-not (Test-Path $uninstallRegPath)) {
    New-Item -Path $uninstallRegPath -Force | Out-Null
}
$installedExe = Join-Path $InstallDir 'TinyWall.exe'
$version = (Get-Item $installedExe).VersionInfo.ProductVersion
Set-ItemProperty -Path $uninstallRegPath -Name 'DisplayName' -Value $ProductName
Set-ItemProperty -Path $uninstallRegPath -Name 'DisplayVersion' -Value $version
Set-ItemProperty -Path $uninstallRegPath -Name 'Publisher' -Value $Manufacturer
Set-ItemProperty -Path $uninstallRegPath -Name 'DisplayIcon' -Value $installedExe
Set-ItemProperty -Path $uninstallRegPath -Name 'UninstallString' -Value "powershell.exe -File `"$(Join-Path $InstallDir 'uninstall.ps1')`""
Set-ItemProperty -Path $uninstallRegPath -Name 'InstallLocation' -Value "$InstallDir\"
Set-ItemProperty -Path $uninstallRegPath -Name 'URLInfoAbout' -Value $ProductURL
Set-ItemProperty -Path $uninstallRegPath -Name 'Comments' -Value $Description
Set-ItemProperty -Path $uninstallRegPath -Name 'NoRepair' -Value 1 -Type DWord

# Remove old x86 MSI uninstall entry if present
$oldMsiEntries = Get-ChildItem 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue |
    Where-Object { (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DisplayName -eq $ProductName -and $_.PSChildName -ne $ProductName }
foreach ($entry in $oldMsiEntries) {
    Remove-Item -Path $entry.PSPath -Recurse -Force -ErrorAction SilentlyContinue
}

# 5. Create Start Menu shortcuts
Write-Host "  Creating Start Menu shortcuts..."
if (-not (Test-Path $StartMenuDir)) {
    New-Item -ItemType Directory -Path $StartMenuDir -Force | Out-Null
}

$WshShell = New-Object -ComObject WScript.Shell

$shortcut = $WshShell.CreateShortcut((Join-Path $StartMenuDir 'TinyWall Controller.lnk'))
$shortcut.TargetPath = $installedExe
$shortcut.WorkingDirectory = $InstallDir
$shortcut.Description = $Description
$shortcut.IconLocation = "$installedExe,0"
$shortcut.Save()

$shortcut = $WshShell.CreateShortcut((Join-Path $StartMenuDir 'TinyWall Dev Helper.lnk'))
$shortcut.TargetPath = $installedExe
$shortcut.Arguments = '/develtool'
$shortcut.WorkingDirectory = $InstallDir
$shortcut.Description = 'TinyWall Developer Helper'
$shortcut.IconLocation = "$installedExe,0"
$shortcut.Save()

$faqPath = Join-Path $InstallDir 'doc\faq.html'
if (Test-Path $faqPath) {
    $shortcut = $WshShell.CreateShortcut((Join-Path $StartMenuDir 'FAQ.lnk'))
    $shortcut.TargetPath = $faqPath
    $shortcut.Save()
}

$whatsNewPath = Join-Path $InstallDir 'doc\whatsnew.html'
if (Test-Path $whatsNewPath) {
    $shortcut = $WshShell.CreateShortcut((Join-Path $StartMenuDir "What's new.lnk"))
    $shortcut.TargetPath = $whatsNewPath
    $shortcut.Save()
}

$urlShortcut = $WshShell.CreateShortcut((Join-Path $StartMenuDir 'Website.url'))
$urlShortcut.TargetPath = $ProductURL
$urlShortcut.Save()

# 6. Run TinyWall /install (registers service, creates scheduled task, starts service)
Write-Host "  Registering service and creating scheduled task..."
$process = Start-Process -FilePath $installedExe -ArgumentList '/install' -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) {
    Write-Warning "TinyWall /install exited with code $($process.ExitCode)"
}

# 7. Launch the controller (matches Wix installer behavior)
Write-Host "  Starting TinyWall controller..."
if ($isUpgrade) {
    Start-Process -FilePath $installedExe
} else {
    Start-Process -FilePath $installedExe -ArgumentList '/autowhitelist'
}

Write-Host ""
Write-Host "$ProductName $version installed successfully!" -ForegroundColor Green
Write-Host "The default configuration blocks most programs. Use the 'Whitelist by...' options from the tray menu to allow applications."
