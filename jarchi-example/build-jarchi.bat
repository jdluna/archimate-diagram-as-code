@echo off
setlocal EnableExtensions
REM Compile jArchi 1.12.0 from source against Archi 5.10.0.
REM Writes only under this folder. No administrator rights and no Program Files install.
REM
REM From Git Bash:
REM   cmd //c build-jarchi.bat

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "BUILD=%ROOT%\.build"
set "ARCHI=%BUILD%\archi"
set "JARCHI=%BUILD%\archi-scripting-plugin"
set "DIST=%ROOT%\dist"
set "ARCHI_TAG=release_5.10.0"
set "JARCHI_TAG=v1.12.0"
set "ARCHI_VERSION=5.10.0-SNAPSHOT"
set "JARCHI_VERSION=1.12.0-SNAPSHOT"

where.exe git >nul 2>&1
if errorlevel 1 (
  echo Git for Windows is required and must be on PATH. A per-user Git install is enough. 1>&2
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

call :ensure_java
if errorlevel 1 exit /b 1
call :ensure_maven
if errorlevel 1 exit /b 1

if not exist "%BUILD%" mkdir "%BUILD%"
if not exist "%ARCHI%\.git" (
  git clone --depth 1 --branch "%ARCHI_TAG%" https://github.com/archimatetool/archi.git "%ARCHI%"
  if errorlevel 1 exit /b 1
)
if not exist "%JARCHI%\.git" (
  git clone --depth 1 --branch "%JARCHI_TAG%" https://github.com/archimatetool/archi-scripting-plugin.git "%JARCHI%"
  if errorlevel 1 exit /b 1
)

git -C "%ARCHI%" fetch --depth 1 origin tag "%ARCHI_TAG%"
if errorlevel 1 exit /b 1
git -C "%ARCHI%" checkout --detach "%ARCHI_TAG%"
if errorlevel 1 exit /b 1
git -C "%JARCHI%" fetch --depth 1 origin tag "%JARCHI_TAG%"
if errorlevel 1 exit /b 1
git -C "%JARCHI%" checkout --detach "%JARCHI_TAG%"
if errorlevel 1 exit /b 1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\patch-reactor.ps1" -PomPath "%ARCHI%\pom.xml" -Jarchi "%JARCHI%" -ArchiVersion "%ARCHI_VERSION%" -JarchiVersion "%JARCHI_VERSION%"
if errorlevel 1 exit /b 1

echo Compiling with %JAVA_HOME%
cd /d "%ARCHI%"
call "%MVN%" -B -Drevision=%ARCHI_VERSION% clean package -DskipTests "-P!tests"
if errorlevel 1 exit /b 1

if not exist "%DIST%" mkdir "%DIST%"
del /q "%DIST%\*.jar" 2>nul
call :copy_bundle com.archimatetool.script
if errorlevel 1 exit /b 1
call :copy_bundle com.archimatetool.script.commandline
if errorlevel 1 exit /b 1
call :copy_bundle com.archimatetool.script.nashorn
if errorlevel 1 exit /b 1

echo jArchi bundles are in %DIST%
exit /b 0

:copy_bundle
set "COPIED="
for %%J in ("%JARCHI%\%~1\target\*.jar") do (
  echo %%~nxJ | findstr /i "sources javadoc" >nul
  if errorlevel 1 if not defined COPIED (
    copy /y "%%J" "%DIST%\" >nul
    echo Installed %%~nxJ
    set "COPIED=1"
  )
)
if not defined COPIED (
  echo No bundle jar produced for %~1 1>&2
  exit /b 1
)
exit /b 0

:ensure_java
set "JAVA_OK="
if defined JAVA_HOME if exist "%JAVA_HOME%\bin\java.exe" (
  "%JAVA_HOME%\bin\java.exe" -version >"%TEMP%\jarchi-java-version.txt" 2>&1
  findstr /C:"version ""21" "%TEMP%\jarchi-java-version.txt" >nul
  if not errorlevel 1 set "JAVA_OK=1"
)
if defined JAVA_OK goto :java_ready

if exist "%LOCALAPPDATA%\Programs\Eclipse Adoptium" (
  for /d %%D in ("%LOCALAPPDATA%\Programs\Eclipse Adoptium\jdk-21*") do (
    if not defined JAVA_OK if exist "%%D\bin\java.exe" (
      set "JAVA_HOME=%%D"
      set "JAVA_OK=1"
    )
  )
)
if defined JAVA_OK goto :java_ready

set "JAVA_HOME=%BUILD%\jdk-21.0.7+6"
if not exist "%JAVA_HOME%\bin\java.exe" (
  echo Downloading Temurin JDK 21 into .build. This stays in the project folder.
  if not exist "%BUILD%" mkdir "%BUILD%"
  curl.exe -fL --retry 3 -o "%BUILD%\OpenJDK21U-jdk_x64_windows_hotspot_21.0.7_6.zip" "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.7%%2B6/OpenJDK21U-jdk_x64_windows_hotspot_21.0.7_6.zip"
  if errorlevel 1 exit /b 1
  tar.exe -xf "%BUILD%\OpenJDK21U-jdk_x64_windows_hotspot_21.0.7_6.zip" -C "%BUILD%"
  if errorlevel 1 exit /b 1
)
if not exist "%JAVA_HOME%\bin\java.exe" (
  echo JDK 21 was not found after unpacking the Temurin zip. 1>&2
  exit /b 1
)

:java_ready
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo Using JDK %JAVA_HOME%
exit /b 0

:ensure_maven
set "MVN="
where.exe mvn >nul 2>&1
if errorlevel 1 goto :download_maven
powershell.exe -NoProfile -Command "try { $v = (mvn -version | Select-String -Pattern 'Apache Maven (\d+\.\d+\.\d+)').Matches[0].Groups[1].Value; if ([version]$v -ge [version]'3.9.9') { exit 0 } else { exit 1 } } catch { exit 1 }"
if errorlevel 1 goto :download_maven
set "MVN=mvn"
exit /b 0

:download_maven
set "MVN=%BUILD%\apache-maven-3.9.11\bin\mvn.cmd"
if exist "%MVN%" exit /b 0
echo Downloading Maven 3.9.11 into .build. Archi 5.10 needs Maven 3.9.9 or newer.
if not exist "%BUILD%" mkdir "%BUILD%"
curl.exe -fL --retry 3 -o "%BUILD%\apache-maven-3.9.11-bin.zip" "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.11/apache-maven-3.9.11-bin.zip"
if errorlevel 1 exit /b 1
tar.exe -xf "%BUILD%\apache-maven-3.9.11-bin.zip" -C "%BUILD%"
if errorlevel 1 exit /b 1
if not exist "%MVN%" (
  echo Maven 3.9.11 was not found after unpacking. 1>&2
  exit /b 1
)
exit /b 0
