@echo off
:: Deja en PY la ruta real de python.exe (evita el acceso directo de la Microsoft Store)
set "PY="
for /f "delims=" %%P in ('py -3 -c "import sys;print(sys.executable)" 2^>nul') do set "PY=%%P"
if defined PY exit /b 0
for /f "delims=" %%P in ('python -c "import sys;print(sys.executable)" 2^>nul') do set "PY=%%P"
exit /b 0
