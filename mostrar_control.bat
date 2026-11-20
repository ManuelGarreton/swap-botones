@echo off
:: Desactiva el ocultamiento: el control real vuelve a verse normal (sin swap)
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
"C:\Program Files\Nefarius Software Solutions\HidHide\x64\HidHideCLI.exe" --cloak-off
echo Ocultamiento desactivado. Desenchufa y vuelve a enchufar el control.
echo Para volver a usar swap-botones ejecuta ocultar_control.bat
pause
