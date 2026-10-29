@echo off
if not exist "%~dp0desktop-pet\build\WarmJadePrototype-v0.15.1.exe" (
  echo Please run build-prototype.ps1 first. See HANDOFF.md for setup.
  pause
  exit /b 1
)
start "" "%~dp0desktop-pet\build\WarmJadePrototype-v0.15.1.exe"
