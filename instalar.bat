@echo off
setlocal
:: --- Permisos de administrador ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
cd /d "%~dp0"
echo ==================================================
echo  swap-botones: instalador
echo  Deja el control ENCHUFADO durante la instalacion
echo ==================================================

:: --- 1. Python ---
call "%~dp0scripts\buscar_python.bat"
if not defined PY (
  echo ERROR: no encontre Python 3. Instalalo desde https://www.python.org
  echo        marcando "Add python.exe to PATH" y vuelve a ejecutar.
  pause & exit /b 1
)
echo [1/5] Python: %PY%

set "VIGEM_URL=https://github.com/nefarius/ViGEmBus/releases/download/v1.22.0/ViGEmBus_1.22.0_x64_x86_arm64.exe"
set "HIDHIDE_URL=https://github.com/nefarius/HidHide/releases/download/v1.5.230.0/HidHide_1.5.230_x64.exe"

:: --- 2. ViGEmBus ---
echo [2/5] Descargando e instalando ViGEmBus...
powershell -NoProfile -Command "Invoke-WebRequest -UseBasicParsing '%VIGEM_URL%' -OutFile \"$env:TEMP\ViGEmBus_setup.exe\""
start /wait "" "%TEMP%\ViGEmBus_setup.exe"

:: --- 3. HidHide ---
echo [3/5] Descargando e instalando HidHide (si pide reiniciar, elige "mas tarde")...
powershell -NoProfile -Command "Invoke-WebRequest -UseBasicParsing '%HIDHIDE_URL%' -OutFile \"$env:TEMP\HidHide_setup.exe\""
start /wait "" "%TEMP%\HidHide_setup.exe"

:: --- 4. vgamepad ---
echo [4/5] Instalando vgamepad...
"%PY%" -m pip install --upgrade vgamepad
if %errorlevel% neq 0 ( echo ERROR instalando vgamepad & pause & exit /b 1 )

:: --- 5. Ocultar control real ---
echo [5/5] Configurando HidHide...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ocultar_control.ps1" -Python "%PY%"

echo.
echo ==================================================
echo  Listo. REINICIA el PC. Luego abre iniciar.bat.
echo ==================================================
pause
