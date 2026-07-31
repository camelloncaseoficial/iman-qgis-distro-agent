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

REM -- Versao do QGIS EMBARCADA pelo instalador (D-IMAN-028/DB-12) -------------
REM ESPELHA o #define QgisBaselineVersion de installer\iman-terra.iss, que e a
REM fonte unica. Trocar la SEM trocar aqui faria o launcher parar de reconhecer
REM o proprio payload e cair no fallback por curinga - exatamente o defeito que
REM o DB-14 corrige. Por isso installer\build.ps1 RECUSA compilar se os dois
REM valores divergirem: a checagem existe para tornar esse erro impossivel.
set "QGIS_VERSION=3.44.9"
for /f "tokens=1,2 delims=." %%a in ("%QGIS_VERSION%") do set "QGIS_MINOR=%%a.%%b"

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

REM -- Deteccao do executavel do QGIS -----------------------------------------
REM
REM ORDEM DELIBERADA (D-IMAN-028/DB-14). O instalador agora EMBARCA o QGIS, e o
REM MSI oficial COEXISTE com outras versoes em vez de atualiza-las (DB-13) - ele
REM nao tem Upgrade table nem FindRelatedProducts, medido na fatia #010. Logo
REM "varios QGIS na mesma maquina" deixa de ser hipotese e vira o caso comum.
REM
REM O DEFEITO CORRIGIDO AQUI: a busca por curinga aceitava o PRIMEIRO que o
REM `for /d` enumerasse, e a enumeracao e ALFABETICA POR TEXTO. Medido:
REM   com 3.34.15 + 3.40.3 + 3.44.9 + 3.44.12 -> escolhia "QGIS 3.34.15" (a mais ANTIGA)
REM   com apenas   3.44.9 + 3.44.12           -> escolhia "QGIS 3.44.12" ('1' < '9')
REM Ou seja: instalavamos 541 MB de QGIS testado e abriamos OUTRO, nao testado.
REM
REM Agora o caminho EXATO do payload vence, e o curinga e so ultimo recurso.
set "QGIS_EXE="

REM (1) Override explicito do operador - sempre ganha.
if defined QGIS_BIN if exist "%QGIS_BIN%" set "QGIS_EXE=%QGIS_BIN%"

REM (2) O QGIS que ESTE produto instalou e no qual ele foi testado.
if not defined QGIS_EXE call :find_qgis "%ProgramFiles%\QGIS %QGIS_VERSION%\bin\qgis-ltr-bin.exe"
if not defined QGIS_EXE call :find_qgis "%ProgramFiles%\QGIS %QGIS_VERSION%\bin\qgis-bin.exe"

REM (3) Mesma minor (ex.: outro patch 3.44.x): degrada pouco e e melhor que
REM     cair numa serie diferente, onde QSS e dashboard podem quebrar calados.
if not defined QGIS_EXE call :find_in_root "%ProgramFiles%" "qgis-ltr-bin.exe" "%QGIS_MINOR%"
if not defined QGIS_EXE call :find_in_root "%ProgramFiles%" "qgis-bin.exe" "%QGIS_MINOR%"

REM (4) OSGeo4W tem caminho fixo: teste direto.
if not defined QGIS_EXE call :find_qgis "C:\OSGeo4W\bin\qgis-ltr-bin.exe"
if not defined QGIS_EXE call :find_qgis "C:\OSGeo4W\bin\qgis-bin.exe"

REM (5) ULTIMO RECURSO: qualquer "QGIS *". A ordem aqui e alfabetica e NAO
REM     e ordem de versao - so se chega neste ponto quando nada acima existe,
REM     e entao abrir algo e melhor que nao abrir nada.
if not defined QGIS_EXE call :find_in_root "%ProgramFiles%" "qgis-ltr-bin.exe" ""
if not defined QGIS_EXE call :find_in_root "%ProgramFiles%" "qgis-bin.exe" ""
if not defined QGIS_EXE call :find_in_root "%ProgramFiles(x86)%" "qgis-ltr-bin.exe" ""
if not defined QGIS_EXE call :find_in_root "%ProgramFiles(x86)%" "qgis-bin.exe" ""

REM Com o instalador bundlado (D-IMAN-028), chegar aqui NAO e mais o caso normal
REM de "o usuario nao instalou o QGIS": o instalador do %PRODUCT_NAME% instala o
REM QGIS %QGIS_VERSION% junto e ABORTA se isso falhar. Se ainda assim nao ha QGIS,
REM o mais provavel e que alguem o desinstalou depois. A mensagem mudou de
REM "instale o QGIS" para "reinstale o %PRODUCT_NAME%", que e a acao certa agora.
if not defined QGIS_EXE (
  echo.
  echo   [%PRODUCT_NAME%] O QGIS nao foi encontrado nesta maquina.
  echo.
  echo   O %PRODUCT_NAME% ^(powered by QGIS^) instala o QGIS %QGIS_VERSION% junto
  echo   com ele. Nao encontrar o QGIS agora indica que ele foi removido depois
  echo   da instalacao.
  echo.
  echo   O que fazer: reinstale o %PRODUCT_NAME% - ele reinstala o QGIS.
  echo   Se voce ja tem um QGIS noutro lugar, aponte-o com a variavel QGIS_BIN.
  echo.
  pause
  exit /b 1
)

REM -- Modo diagnostico: so RESOLVE o QGIS e sai -------------------------------
REM Com IMAN_TERRA_DETECT_ONLY=1 o launcher imprime o executavel escolhido e sai
REM SEM copiar perfil, escrever customizacao ou abrir o QGIS.
REM POR QUE ISSO EXISTE: o teste do DB-14 precisa exercitar ESTA rotina. Um teste
REM que reimplementa a logica de deteccao passa a validar a copia, nao o produto -
REM e foi assim que o defeito do `for /d` sobreviveu ate a fatia #010.
REM Ver tools\test-launcher-detection.ps1.
if "%IMAN_TERRA_DETECT_ONLY%"=="1" (
  echo QGIS_EXE=%QGIS_EXE%
  endlocal
  exit /b 0
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

REM Procura <raiz>\QGIS <prefixo>*\bin\<exe>.
REM   %~1 = raiz (ex.: C:\Program Files)
REM   %~2 = nome do executavel
REM   %~3 = prefixo de versao a exigir (ex.: "3.44"); vazio = qualquer versao
REM
REM POR QUE FOR /D E NAO DIR /S: o `dir /s` procura um NOME DE ARQUIVO recursivamente
REM e NAO expande curinga em componente de DIRETORIO. Ou seja,
REM   dir /b /s "C:\Program Files\QGIS *\bin\qgis-ltr-bin.exe"
REM retorna VAZIO mesmo com o QGIS instalado. Era o que esta rotina fazia, e por isso
REM o launcher nao achava instalacao standalone nenhuma. O `for /d` resolve o curinga
REM no nome do diretorio, que e onde a versao mora ("QGIS 3.44.9").
REM
REM ATENCAO (DB-14): a ordem do `for /d` e alfabetica POR TEXTO, nao por versao -
REM "QGIS 3.44.12" vem ANTES de "QGIS 3.44.9" porque '1' < '9'. Esta rotina
REM continua aceitando o primeiro; quem garante a versao certa e a ORDEM DAS
REM CHAMADAS la em cima (caminho exato primeiro), nao esta funcao.
:find_in_root
if "%~1"=="" exit /b 0
for /d %%D in ("%~1\QGIS %~3*") do (
  if not defined QGIS_EXE if exist "%%~fD\bin\%~2" set "QGIS_EXE=%%~fD\bin\%~2"
)
exit /b 0
