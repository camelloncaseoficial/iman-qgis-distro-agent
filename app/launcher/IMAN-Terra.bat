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
set "QGIS_VERSION=3.44.13"
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

REM -- RAIZ DE 64 BITS, RESOLVIDA EXPLICITAMENTE (D-IMAN-028/DB-20) ------------
REM
REM NAO use %ProgramFiles% para achar o QGIS. Num processo de 32 BITS o WOW64
REM aponta %ProgramFiles% para "C:\Program Files (x86)" - o MESMO valor de
REM %ProgramFiles(x86)% - e o QGIS de 64 bits nao esta la. Medido nesta bancada
REM em 2026-09-03, com o launcher INSTALADO e IMAN_TERRA_DETECT_ONLY=1:
REM
REM   pai 64-bit (System32\cmd.exe)  -> QGIS_EXE=C:\Program Files\QGIS 3.44.13\...
REM   pai 32-bit (SysWOW64\cmd.exe)  -> "O QGIS nao foi encontrado", exit 1
REM
REM O MESMO comando, a MESMA maquina, o MESMO QGIS instalado. O que muda e a
REM visao das variaveis de ambiente herdada do processo pai.
REM
REM POR QUE ISSO APARECEU AGORA (DB-20): o Setup.exe do Inno e um binario de
REM 32 BITS ("Setup version: Inno Setup version 7.1.0 (32-bit)" no log do
REM proprio build) e a entrada [Run] usa shellexec. O checkbox final "Abrir o
REM %PRODUCT_NAME% agora" nasce FILHO desse processo e herda a visao
REM redirecionada; o atalho do Menu Iniciar nasce do Explorer, que e de 64 bits,
REM e por isso funcionava. O sintoma era indistinguivel de "o QGIS nao esta
REM instalado".
REM
REM POR QUE O CONSERTO E AQUI, E NAO NA CHAMADA: forcar um filho de 64 bits no
REM [Run] resolveria so ESTE chamador. O launcher e o ponto de entrada do
REM produto; qualquer pai de 32 bits - atalho de terceiro, agendador, outro
REM instalador - reproduziria o defeito.
REM
REM %ProgramW6432% e definida NOS DOIS mundos (32 e 64 bits) e sempre aponta
REM para a raiz de 64 bits. Ela so nao existe no Windows de 32 bits - e la
REM %ProgramFiles% E a raiz certa, que e exatamente o fallback abaixo.
set "PF64=%ProgramW6432%"
if not defined PF64 set "PF64=%ProgramFiles%"
set "PF86=%ProgramFiles(x86)%"

set "QGIS_EXE="

REM (1) Override explicito do operador - sempre ganha.
if defined QGIS_BIN if exist "%QGIS_BIN%" set "QGIS_EXE=%QGIS_BIN%"

REM (2) O QGIS que ESTE produto instalou e no qual ele foi testado.
if not defined QGIS_EXE call :find_qgis "%PF64%\QGIS %QGIS_VERSION%\bin\qgis-ltr-bin.exe"
if not defined QGIS_EXE call :find_qgis "%PF64%\QGIS %QGIS_VERSION%\bin\qgis-bin.exe"

REM (3) Mesma minor (ex.: outro patch 3.44.x): degrada pouco e e melhor que
REM     cair numa serie diferente, onde QSS e dashboard podem quebrar calados.
if not defined QGIS_EXE call :find_in_root "%PF64%" "qgis-ltr-bin.exe" "%QGIS_MINOR%"
if not defined QGIS_EXE call :find_in_root "%PF64%" "qgis-bin.exe" "%QGIS_MINOR%"

REM (4) OSGeo4W tem caminho fixo: teste direto.
if not defined QGIS_EXE call :find_qgis "C:\OSGeo4W\bin\qgis-ltr-bin.exe"
if not defined QGIS_EXE call :find_qgis "C:\OSGeo4W\bin\qgis-bin.exe"

REM (5) ULTIMO RECURSO: qualquer "QGIS *". A ordem aqui e alfabetica e NAO
REM     e ordem de versao - so se chega neste ponto quando nada acima existe,
REM     e entao abrir algo e melhor que nao abrir nada.
if not defined QGIS_EXE call :find_in_root "%PF64%" "qgis-ltr-bin.exe" ""
if not defined QGIS_EXE call :find_in_root "%PF64%" "qgis-bin.exe" ""
REM %PF86% CONTINUA como ultimo recurso (nao remover): um QGIS de 32 bits alheio
REM ainda e melhor que nenhum QGIS.
if not defined QGIS_EXE call :find_in_root "%PF86%" "qgis-ltr-bin.exe" ""
if not defined QGIS_EXE call :find_in_root "%PF86%" "qgis-bin.exe" ""

REM A MENSAGEM E DIAGNOSTICO, NAO CHUTE (D-IMAN-028/DB-20).
REM A versao anterior AFIRMAVA uma causa - "o QGIS foi removido, reinstale o
REM %PRODUCT_NAME%" - sem mostrar o que tinha olhado. Sob o defeito do DB-20 o
REM QGIS ESTAVA instalado: a causa afirmada era falsa e a acao recomendada
REM (reinstalar) nao podia funcionar, e o diagnostico foi para o lado errado.
REM Agora a tela LISTA AS RAIZES efetivamente sondadas e a versao procurada -
REM quem le ve na hora se as duas raizes vieram IGUAIS, que e a assinatura da
REM visao WOW64.
REM
REM !PF64! e !PF86! usam expansao ATRASADA de proposito: os valores contem
REM parenteses ("C:\Program Files (x86)") e, com %VAR% dentro de um bloco
REM ( ... ), o ')' do valor fecharia o bloco na hora de PARSEAR.
if not defined QGIS_EXE (
  echo.
  echo   [%PRODUCT_NAME%] O QGIS nao foi encontrado nesta maquina.
  echo.
  echo   Procurei o QGIS %QGIS_VERSION% ^(e qualquer %QGIS_MINOR%.x^) nestas raizes:
  echo.
  echo     [64 bits] !PF64!
  echo     [32 bits] !PF86!
  echo     [OSGeo4W] C:\OSGeo4W
  echo.
  echo   Se as duas primeiras aparecem IGUAIS acima, este processo esta vendo o
  echo   sistema como 32 bits e nao enxerga "C:\Program Files". Transcreva esta
  echo   tela: e ela que identifica o problema.
  echo.
  echo   Se voce ja tem um QGIS noutro lugar, aponte o executavel com a variavel
  echo   QGIS_BIN. Exemplo:
  echo     set "QGIS_BIN=C:\Program Files\QGIS %QGIS_VERSION%\bin\qgis-ltr-bin.exe"
  echo.
  echo   O %PRODUCT_NAME% ^(powered by QGIS^) instala o QGIS %QGIS_VERSION% junto
  echo   com ele. Se o QGIS foi mesmo removido depois, reinstalar o
  echo   %PRODUCT_NAME% recoloca-o.
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
