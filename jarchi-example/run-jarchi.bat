@echo off
setlocal EnableExtensions
REM Generate the Archi model with the compiled jArchi bundles.
REM Uses the Windows portable zip and the per-user dropins folder.
REM Nothing is written to Program Files.
REM
REM From Git Bash:
REM   cmd //c run-jarchi.bat
REM   cmd //c "run-jarchi.bat model/claims.json out/claims-handling.archimate"

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "BUILD=%ROOT%\.build"
set "DIST=%ROOT%\dist"
set "ARCHI_HOME=%BUILD%\Archi-Win64"
set "DROPINS=%APPDATA%\Archi\dropins"
set "SCRIPTS=%USERPROFILE%\Documents\Archi\scripts"
set "SCRIPT=%ROOT%\scripts\create-from-json.ajs"
set "JSON=%~1"
set "OUT=%~2"
if "%JSON%"=="" set "JSON=%ROOT%\model\claims.json"
if "%OUT%"=="" set "OUT=%ROOT%\out\claims-handling.archimate"

dir /b "%DIST%\com.archimatetool.script*.jar" >nul 2>&1
if errorlevel 1 (
  echo jArchi bundles are not in %DIST%. Run build-jarchi.bat first. 1>&2
  exit /b 1
)
where.exe curl.exe >nul 2>&1
if errorlevel 1 (
  echo curl.exe is required. It ships with Windows 10 and later. 1>&2
  exit /b 1
)
where.exe tar.exe >nul 2>&1
if errorlevel 1 (
  echo tar.exe is required. It ships with Windows 10 and later. 1>&2
  exit /b 1
)

if not exist "%ARCHI_HOME%\Archi.exe" (
  echo Downloading Archi 5.10 Windows portable zip into .build
  if not exist "%BUILD%" mkdir "%BUILD%"
  curl.exe -fL --retry 3 -o "%BUILD%\Archi-Win64-5.10.0.zip" "https://github.com/archimatetool/archi.io/releases/download/5.10/Archi-Win64-5.10.0.zip"
  if errorlevel 1 exit /b 1
  if exist "%ARCHI_HOME%" rmdir /s /q "%ARCHI_HOME%"
  mkdir "%ARCHI_HOME%"
  tar.exe -xf "%BUILD%\Archi-Win64-5.10.0.zip" -C "%ARCHI_HOME%"
  if errorlevel 1 exit /b 1
)
if not exist "%ARCHI_HOME%\Archi.exe" (
  for /d %%D in ("%ARCHI_HOME%\*") do (
    if exist "%%D\Archi.exe" set "ARCHI_HOME=%%D"
  )
)
if not exist "%ARCHI_HOME%\Archi.exe" (
  echo Could not find Archi.exe in %ARCHI_HOME% 1>&2
  exit /b 1
)

if not exist "%DROPINS%" mkdir "%DROPINS%"
del /q "%DROPINS%\com.archimatetool.script*.jar" 2>nul
copy /y "%DIST%\com.archimatetool.script*.jar" "%DROPINS%\" >nul
if errorlevel 1 (
  echo Could not copy jArchi jars to %DROPINS% 1>&2
  exit /b 1
)

REM GraalJS CommonJS refuses to start unless this folder exists.
if not exist "%SCRIPTS%" mkdir "%SCRIPTS%"
cd /d "%ROOT%"
for %%D in ("%OUT%") do if not exist "%%~dpD" mkdir "%%~dpD"

"%ARCHI_HOME%\Archi.exe" -clean -application com.archimatetool.commandline.app -consoleLog -nosplash --abortOnException --script.runScript "%SCRIPT%" --json "%JSON%" --saveModel "%OUT%" --createEmptyModel
if errorlevel 1 (
  echo Archi exited with an error. 1>&2
  exit /b 1
)
if not exist "%OUT%" (
  echo Archi exited without writing %OUT% 1>&2
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\check-model.ps1" -Path "%OUT%"
exit /b %ERRORLEVEL%
