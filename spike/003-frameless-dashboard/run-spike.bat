@echo off
REM ===========================================================================
REM  SPIKE #003 - composition root (caminho REAL: launcher -> perfil isolado ->
REM  startup/plugin num QGIS LTR de verdade). Uso:  run-spike.bat a^|b^|c
REM
REM  - Detecta o QGIS LTR instalado (mesma logica do launcher de producao).
REM  - Constroi um perfil ISOLADO do SPIKE em
REM      %APPDATA%\InstitutoIMAN\IMAN Terra Spike\profiles\iman-spike
REM    (publisher-dir PROPRIO -> NUNCA toca o perfil do usuario nem o de producao).
REM  - Abre o QGIS com a sonda pedida, em FOREGROUND. Cada sonda auto-coleta a
REM    evidencia em evidence\ e fecha sozinha (harness deterministico/repetivel).
REM  ASCII-only de proposito (codepage do cmd.exe).
REM ===========================================================================
setlocal EnableExtensions EnableDelayedExpansion

set "SONDA=%~1"
if "%SONDA%"=="" set "SONDA=c"

set "SPIKE_DIR=%~dp0"
if "%SPIKE_DIR:~-1%"=="\" set "SPIKE_DIR=%SPIKE_DIR:~0,-1%"

REM -- app/ de producao (reaproveita assets/demo reais) -----------------------
set "APP_HOME=%SPIKE_DIR%\..\..\app"
pushd "%APP_HOME%" >nul 2>&1
if not errorlevel 1 (
  set "APP_HOME=!CD!"
  popd >nul
)
set "IMAN_TERRA_HOME=%APP_HOME%"

REM -- Perfil ISOLADO do spike (publisher-dir proprio) ------------------------
set "PROFILE_NAME=iman-spike"
set "PROFILES_ROOT=%APPDATA%\InstitutoIMAN\IMAN Terra Spike"
set "PROFILE_DIR=%PROFILES_ROOT%\profiles\%PROFILE_NAME%"
set "INI=%PROFILE_DIR%\QGIS\QGIS3.ini"

REM -- Deteccao do QGIS LTR ---------------------------------------------------
set "QGIS_EXE="
if defined QGIS_BIN if exist "%QGIS_BIN%" set "QGIS_EXE=%QGIS_BIN%"
if not defined QGIS_EXE if exist "C:\OSGeo4W\bin\qgis-ltr-bin.exe" set "QGIS_EXE=C:\OSGeo4W\bin\qgis-ltr-bin.exe"
if not defined QGIS_EXE if exist "C:\OSGeo4W\bin\qgis-bin.exe" set "QGIS_EXE=C:\OSGeo4W\bin\qgis-bin.exe"
if not defined QGIS_EXE for /f "delims=" %%F in ('dir /b /s "%ProgramFiles%\QGIS *\bin\qgis-ltr-bin.exe" 2^>nul') do if not defined QGIS_EXE set "QGIS_EXE=%%F"
if not defined QGIS_EXE (
  echo   [spike] QGIS LTR nao encontrado. Instale o QGIS LTR e rode novamente.
  pause
  exit /b 1
)
echo   [spike] QGIS: %QGIS_EXE%

REM -- (re)cria o perfil isolado do spike do zero ------------------------------
if exist "%PROFILE_DIR%" rmdir /S /Q "%PROFILE_DIR%"
mkdir "%PROFILE_DIR%\QGIS" 2>nul

REM CRS default SIRGAS 2000 / UTM 24S (Ceara) - NUNCA EPSG:4326; locale pt-BR
(
  echo [locale]
  echo userLocale=pt_BR
  echo overrideFlag=true
  echo [app]
  echo projections\defaultProjectCrs=EPSG:31984
  echo projections\newProjectCrsBehavior=usePresetCrs
  echo projections\layerDefaultCrs=EPSG:31984
  echo [qgis]
  echo showTips=false
) > "%INI%"

REM -- Seleciona a sonda ------------------------------------------------------
set "CODE=%SPIKE_DIR%\sonda_a_frameless.py"
if /I "%SONDA%"=="b" set "CODE=%SPIKE_DIR%\sonda_b_central.py"
if /I "%SONDA%"=="c" call :setup_sonda_c

echo   [spike] Sonda %SONDA% - perfil isolado: %PROFILE_DIR%
echo   [spike] SPIKE_DIR=%SPIKE_DIR%
"%QGIS_EXE%" --profiles-path "%PROFILES_ROOT%" --profile "%PROFILE_NAME%" --code "%CODE%" --noversioncheck
echo   [spike] Sonda %SONDA% encerrada. Evidencia em: %SPIKE_DIR%\evidence

endlocal
exit /b 0

:setup_sonda_c
REM Instala o plugin de home (dashboard-as-dock) no perfil isolado e habilita.
mkdir "%PROFILE_DIR%\python\plugins" 2>nul
xcopy /E /I /Y /Q "%SPIKE_DIR%\sonda_c_dock" "%PROFILE_DIR%\python\plugins\iman_home" >nul
(
  echo [PythonPlugins]
  echo iman_home=true
) >> "%INI%"
set "CODE=%SPIKE_DIR%\sonda_c_probe.py"
exit /b 0
