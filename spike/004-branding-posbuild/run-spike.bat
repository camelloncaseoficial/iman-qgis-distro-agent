@echo off
REM ===========================================================================
REM  SPIKE #004 - composition root (caminho REAL). Uso:
REM     run-spike.bat runtime   -> sondas I(runtime)/III/IV via --code
REM     run-spike.bat ii        -> splash nativo via customizacao do perfil
REM  Perfil ISOLADO do spike em %APPDATA%\InstitutoIMAN\IMAN Terra Spike4\
REM  (nunca toca o perfil do usuario nem o de producao - BL-3). Foreground.
REM ===========================================================================
setlocal EnableExtensions EnableDelayedExpansion

set "SONDA=%~1"
if "%SONDA%"=="" set "SONDA=runtime"

set "SPIKE_DIR=%~dp0"
if "%SPIKE_DIR:~-1%"=="\" set "SPIKE_DIR=%SPIKE_DIR:~0,-1%"

set "APP_HOME=%SPIKE_DIR%\..\..\app"
pushd "%APP_HOME%" >nul 2>&1
if not errorlevel 1 ( set "APP_HOME=!CD!" & popd >nul )
set "IMAN_TERRA_HOME=%APP_HOME%"

set "PROFILE_NAME=iman-spike4"
set "PROFILES_ROOT=%APPDATA%\InstitutoIMAN\IMAN Terra Spike4"
set "PROFILE_DIR=%PROFILES_ROOT%\profiles\%PROFILE_NAME%"
set "INI=%PROFILE_DIR%\QGIS\QGIS3.ini"

set "QGIS_EXE="
if defined QGIS_BIN if exist "%QGIS_BIN%" set "QGIS_EXE=%QGIS_BIN%"
if not defined QGIS_EXE if exist "C:\OSGeo4W\bin\qgis-ltr-bin.exe" set "QGIS_EXE=C:\OSGeo4W\bin\qgis-ltr-bin.exe"
if not defined QGIS_EXE if exist "C:\OSGeo4W\bin\qgis-bin.exe" set "QGIS_EXE=C:\OSGeo4W\bin\qgis-bin.exe"
if not defined QGIS_EXE (
  echo   [spike] QGIS LTR nao encontrado. & pause & exit /b 1
)

if exist "%PROFILE_DIR%" rmdir /S /Q "%PROFILE_DIR%"
mkdir "%PROFILE_DIR%\QGIS" 2>nul

(
  echo [locale]
  echo userLocale=pt_BR
  echo overrideFlag=true
  echo [app]
  echo projections\defaultProjectCrs=EPSG:31984
  echo projections\newProjectCrsBehavior=usePresetCrs
  echo [qgis]
  echo showTips=false
) > "%INI%"

set "CODE="
if /I "%SONDA%"=="runtime" set "CODE=%SPIKE_DIR%\sonda_runtime.py"
if /I "%SONDA%"=="ii" call :setup_ii

echo   [spike] Sonda %SONDA% - perfil: %PROFILE_DIR%
if defined CODE (
  "%QGIS_EXE%" --profiles-path "%PROFILES_ROOT%" --profile "%PROFILE_NAME%" --code "%CODE%" --noversioncheck
) else (
  "%QGIS_EXE%" --profiles-path "%PROFILES_ROOT%" --profile "%PROFILE_NAME%" --noversioncheck
)
echo   [spike] Sonda %SONDA% encerrada. Evidencia: %SPIKE_DIR%\evidence

endlocal
exit /b 0

:setup_ii
REM Splash nativo via customizacao: habilita + aponta splashpath ao splash IMAN.
(
  echo [UI]
  echo Customization\enabled=true
) >> "%INI%"
(
  echo [Customization]
  echo splashpath=%SPIKE_DIR%/custom_splash/
) > "%PROFILE_DIR%\QGIS\QGISCUSTOMIZATION3.ini"
REM sem --code: queremos o boot puro para ver o splash nativo
exit /b 0
