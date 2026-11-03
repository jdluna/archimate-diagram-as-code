@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-jarchi.ps1" %*
exit /b %ERRORLEVEL%
