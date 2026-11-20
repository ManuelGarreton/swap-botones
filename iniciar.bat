@echo off
cd /d "%~dp0"
call "%~dp0scripts\buscar_python.bat"
if not defined PY ( echo No encontre Python. & pause & exit /b 1 )
"%PY%" swap_botones.py
pause
