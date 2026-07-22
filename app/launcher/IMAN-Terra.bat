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

REM -- Perfil ISOLADO em %APPDATA%\InstitutoIMAN\IMAN Terra -------------------
REM IMPORTANTE: o QGIS ACRESCENTA "profiles\" ao valor de --profiles-path, logo
REM ele le de <PROFILES_ROOT>\profiles\<perfil>. Passamos a RAIZ e copiamos o
REM template para <PROFILES_ROOT>\profiles\<perfil>.
set "PROFILES_ROOT=%APPDATA%\%PUBLISHER_DIR%\%PRODUCT_NAME%"
set "PROFILE_DIR=%PROFILES_ROOT%\profiles\%PROFILE_NAME%"

REM Exposto ao plugin para localizar o demo/docs (open_demo).
set "IMAN_TERRA_HOME=%APP_HOME%"

REM -- Deteccao do executavel do QGIS LTR --------------------------------------
set "QGIS_EXE="
if defined QGIS_BIN if exist "%QGIS_BIN%" set "QGIS_EXE=%QGIS_BIN%"

REM OSGeo4W tem caminho fixo: teste direto.
if not defined QGIS_EXE call :find_qgis "C:\OSGeo4W\bin\qgis-ltr-bin.exe"
if not defined QGIS_EXE call :find_qgis "C:\OSGeo4W\bin\qgis-bin.exe"
REM Standalone: a pasta tem a VERSAO no nome ("QGIS 3.44.9"), entao o curinga
REM precisa ser resolvido pelo FOR /D. LTR primeiro, depois a release comum.
if not defined QGIS_EXE call :find_in_root "%ProgramFiles%" "qgis-ltr-bin.exe"
if not defined QGIS_EXE call :find_in_root "%ProgramFiles%" "qgis-bin.exe"
if not defined QGIS_EXE call :find_in_root "%ProgramFiles(x86)%" "qgis-ltr-bin.exe"
if not defined QGIS_EXE call :find_in_root "%ProgramFiles(x86)%" "qgis-bin.exe"

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
if not exist "%PROFILE_DIR%\QGIS\QGIS3.ini" (
  echo   [%PRODUCT_NAME%] Preparando o perfil isolado ^(primeiro uso^)...
  if not exist "%PROFILE_DIR%" mkdir "%PROFILE_DIR%"
  xcopy /E /I /Y /Q "%TEMPLATE%" "%PROFILE_DIR%" >nul
)

REM -- Splash NATIVO de marca (mecanismo no-fork do spike #004) ----------------
REM O QGIS mostra QgsCustomization::splashPath()+"splash.png" no boot. Apontamos
REM o splashpath (ABSOLUTO, por-instalacao) para a pasta QGIS\ do perfil, que
REM contem o splash.png re-derivado. Reescrito a cada run (idempotente) para
REM sobreviver a uma eventual reescrita da customizacao pelo QGIS. So o splash -
REM nenhuma regra de widget (nao mexe na UI). BL-3: tudo no perfil isolado.
set "SPLASH_DIR=%PROFILE_DIR:\=/%/QGIS/"
> "%PROFILE_DIR%\QGIS\QGISCUSTOMIZATION3.ini" echo [Customization]
>> "%PROFILE_DIR%\QGIS\QGISCUSTOMIZATION3.ini" echo splashpath=%SPLASH_DIR%

REM -- Abre o QGIS com o perfil IMAN isolado -----------------------------------
REM SEM --project: abrir mostra a HOME de boas-vindas no miolo (fatia #006). O
REM projeto demo fica acessivel pela acao "Abrir projeto demo" do plugin de marca.
start "" "%QGIS_EXE%" ^
  --profiles-path "%PROFILES_ROOT%" ^
  --profile "%PROFILE_NAME%" ^
  --code "%STARTUP%" ^
  --noversioncheck

endlocal
exit /b 0

:find_qgis
if exist "%~1" set "QGIS_EXE=%~1"
exit /b 0

REM Procura <raiz>\QGIS <versao>\bin\<exe>.
REM   %~1 = raiz (ex.: C:\Program Files)   %~2 = nome do executavel
REM
REM POR QUE FOR /D E NAO DIR /S: o `dir /s` procura um NOME DE ARQUIVO recursivamente
REM e NAO expande curinga em componente de DIRETORIO. Ou seja,
REM   dir /b /s "C:\Program Files\QGIS *\bin\qgis-ltr-bin.exe"
REM retorna VAZIO mesmo com o QGIS instalado. Era o que esta rotina fazia, e por isso
REM o launcher nao achava instalacao standalone nenhuma. O `for /d` resolve o curinga
REM no nome do diretorio, que e onde a versao mora ("QGIS 3.44.9").
:find_in_root
if "%~1"=="" exit /b 0
for /d %%D in ("%~1\QGIS *") do (
  if not defined QGIS_EXE if exist "%%~fD\bin\%~2" set "QGIS_EXE=%%~fD\bin\%~2"
)
exit /b 0
