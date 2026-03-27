@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell.exe -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
powershell.exe -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
pause
