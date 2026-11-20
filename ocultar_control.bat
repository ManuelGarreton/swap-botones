@echo off
:: Vuelve a ocultar el control real (por ejemplo, si lo cambiaste de puerto USB)
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
call "%~dp0scripts\buscar_python.bat"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ocultar_control.ps1" -Python "%PY%"
pause
