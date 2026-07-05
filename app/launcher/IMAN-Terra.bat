@echo off
REM ===========================================================================
REM  IMAN Terra - launcher Windows (Opcao 1, no-fork; powered by QGIS)
REM  - Detecta o QGIS LTR instalado (OSGeo4W ou standalone).
REM  - Cria o perfil ISOLADO no primeiro run (nunca toca o perfil do usuario - BL-3).
REM  - Abre o QGIS com o perfil iman-distro + startup + projeto demo.
REM  Marca (nome/perfil): fonte unica em docs/design-system.md e brand.py (BL-4).
REM  ASCII-only de proposito (compatibilidade de codepage do cmd.exe).
REM ===========================================================================
setlocal EnableExtensions EnableDelayedExpansion

REM -- Constantes de marca (espelham a fonte unica; ver design-system.md) -------
set "PRODUCT_NAME=IMAN Terra"
set "PROFILE_NAME=iman-distro"
set "PUBLISHER_DIR=InstitutoIMAN"

REM -- Layout: este .bat vive em <APP_HOME>\launcher\ --------------------------
set "APP_HOME=%~dp0.."
pushd "%APP_HOME%" >nul
set "APP_HOME=%CD%"
popd >nul

set "TEMPLATE=%APP_HOME%\profile-template\%PROFILE_NAME%"
set "STARTUP=%APP_HOME%\startup\iman_startup.py"
set "DEMO=%APP_HOME%\demo\welcome.qgz"

REM -- Perfil ISOLADO em %APPDATA%\InstitutoIMAN\IMAN Terra\profiles -----------
set "PROFILES_PATH=%APPDATA%\%PUBLISHER_DIR%\%PRODUCT_NAME%\profiles"

REM Exposto ao plugin para localizar o demo/docs (open_demo).
set "IMAN_TERRA_HOME=%APP_HOME%"

REM -- Deteccao do executavel do QGIS LTR --------------------------------------
set "QGIS_EXE="
if defined QGIS_BIN if exist "%QGIS_BIN%" set "QGIS_EXE=%QGIS_BIN%"

if not defined QGIS_EXE call :find_qgis "C:\OSGeo4W\bin\qgis-ltr-bin.exe"
if not defined QGIS_EXE call :find_qgis "C:\OSGeo4W\bin\qgis-bin.exe"
if not defined QGIS_EXE call :find_first "%ProgramFiles%\QGIS *\bin\qgis-ltr-bin.exe"
if not defined QGIS_EXE call :find_first "%ProgramFiles%\QGIS *\bin\qgis-bin.exe"
if not defined QGIS_EXE call :find_first "%ProgramFiles(x86)%\QGIS *\bin\qgis-ltr-bin.exe"

if not defined QGIS_EXE (
  echo.
  echo   [%PRODUCT_NAME%] QGIS LTR nao foi encontrado nesta maquina.
  echo.
  echo   O %PRODUCT_NAME% e uma camada de marca sobre o QGIS LTR oficial
  echo   ^(powered by QGIS^) e precisa do QGIS LTR instalado.
  echo   Instale o QGIS LTR ^(https://qgis.org/download^) e rode novamente.
  echo.
  pause
  exit /b 1
)

REM -- Primeiro run: copia o template para o perfil isolado --------------------
if not exist "%PROFILES_PATH%\%PROFILE_NAME%\QGIS\QGIS3.ini" (
  echo   [%PRODUCT_NAME%] Preparando o perfil isolado ^(primeiro uso^)...
  if not exist "%PROFILES_PATH%" mkdir "%PROFILES_PATH%"
  xcopy /E /I /Y /Q "%TEMPLATE%" "%PROFILES_PATH%\%PROFILE_NAME%" >nul
)

REM -- Abre o QGIS com o perfil IMAN isolado -----------------------------------
start "" "%QGIS_EXE%" ^
  --profiles-path "%PROFILES_PATH%" ^
  --profile "%PROFILE_NAME%" ^
  --code "%STARTUP%" ^
  --project "%DEMO%" ^
  --noversioncheck

endlocal
exit /b 0

:find_qgis
if exist "%~1" set "QGIS_EXE=%~1"
exit /b 0

:find_first
for /f "delims=" %%F in ('dir /b /s "%~1" 2^>nul') do (
  if not defined QGIS_EXE set "QGIS_EXE=%%F"
)
exit /b 0
