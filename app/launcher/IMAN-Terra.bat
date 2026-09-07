@echo off
REM ===========================================================================
REM  IMAN Terra - launcher Windows (Opcao 1, no-fork; powered by QGIS)
REM
REM  VIA A1 (D-IMAN-028 emenda 2026-09-06; executavel provado pelo spike #016):
REM  o QGIS NAO e mais procurado na maquina - ele vive DENTRO do produto, em
REM  <APP_HOME>\qgis. Nao ha deteccao, nao ha ambiguidade de "qual QGIS abrir",
REM  nao ha dependencia de registro, ARP ou PATH.
REM
REM  - Confere o MANIFESTO DE INTEGRIDADE da arvore ANTES de subir (ver abaixo).
REM  - Cria o perfil ISOLADO no primeiro run (nunca toca o perfil do usuario - BL-3).
REM  - Abre o QGIS com o perfil iman-distro + startup.
REM  Marca (nome/perfil): fonte unica em docs/design-system.md e brand.py (BL-4).
REM  ASCII-only de proposito (compatibilidade de codepage do cmd.exe).
REM ===========================================================================
setlocal EnableExtensions EnableDelayedExpansion

REM -- Constantes de marca (espelham a fonte unica; ver design-system.md) -------
set "PRODUCT_NAME=IMAN Terra"
set "PROFILE_NAME=iman-distro"
set "PUBLISHER_DIR=InstitutoIMAN"

REM -- Versao do QGIS EMBARCADO (D-IMAN-028/DB-12) -----------------------------
REM ESPELHA o #define QgisBaselineVersion de installer\iman-terra.iss, que e a
REM fonte unica, e o campo VERSAO do manifesto. installer\build.ps1 RECUSA
REM compilar se os tres divergirem.
set "QGIS_VERSION=3.44.13"

REM -- Layout: este .bat vive em <APP_HOME>\launcher\ --------------------------
set "APP_HOME=%~dp0.."
pushd "%APP_HOME%" >nul
set "APP_HOME=%CD%"
popd >nul

set "TEMPLATE=%APP_HOME%\profile-template\%PROFILE_NAME%"
set "STARTUP=%APP_HOME%\startup\iman_startup.py"
set "DEMO=%APP_HOME%\demo\welcome.qgz"

REM -- A ARVORE PRIVADA DO QGIS -----------------------------------------------
REM Um caminho, fixo, dentro do produto. Nada de procurar.
REM Utilitarios do Windows chamados por CAMINHO ABSOLUTO, nunca pelo PATH.
REM MEDIDO em 2026-09-07: numa maquina com o Git para Windows no PATH, o `find`
REM resolvia para o find(1) do MSYS, que nao entende /c /v e sai com erro - a
REM contagem vinha vazia e a guarda de integridade acusava arvore corrompida
REM numa arvore intacta. Um launcher que depende do PATH do usuario e um
REM launcher que quebra na maquina de quem tem ferramentas instaladas.
set "WFIND=%SystemRoot%\System32\find.exe"
set "WCERTUTIL=%SystemRoot%\System32\certutil.exe"

set "QGIS_ROOT=%APP_HOME%\qgis"
set "QGIS_BAT=%QGIS_ROOT%\bin\qgis-ltr.bat"
set "MANIFESTO=%APP_HOME%\qgis-manifest.txt"

REM -- Perfil ISOLADO em %APPDATA%\InstitutoIMAN\IMAN Terra -------------------
REM IMPORTANTE: o QGIS ACRESCENTA "profiles\" ao valor de --profiles-path, logo
REM ele le de <PROFILES_ROOT>\profiles\<perfil>. Passamos a RAIZ e copiamos o
REM template para <PROFILES_ROOT>\profiles\<perfil>.
set "PROFILES_ROOT=%APPDATA%\%PUBLISHER_DIR%\%PRODUCT_NAME%"
set "PROFILE_DIR=%PROFILES_ROOT%\profiles\%PROFILE_NAME%"

REM Exposto ao plugin para localizar o demo/docs (open_demo).
set "IMAN_TERRA_HOME=%APP_HOME%"

REM ===========================================================================
REM  GUARDA DE INTEGRIDADE (C.3 fail-loud)
REM
REM  POR QUE ISTO EXISTE, e por que ele RECUSA abrir em vez de avisar:
REM  o spike #016 mediu que a arvore do QGIS NAO se autodiagnostica. Com
REM  share\proj ausente, o QGIS responde
REM
REM      CRS validos? SAD69=True SIRGAS=True UTM=True
REM
REM  e devolve deslocamento de datum de 0,00 m onde o correto sao ~57 m. Nao ha
REM  excecao, nao ha valor absurdo, isValid() diz True. Uma copia truncada nao
REM  aparece como erro - aparece como COORDENADA ERRADA num memorial descritivo.
REM  Num produto de REURB e o defeito mais caro que existe.
REM
REM  Por isso: manifesto divergente => o produto NAO ABRE. Abrir degradado
REM  seria entregar o defeito silencioso de novo, so que com o nosso nome.
REM ===========================================================================
call :verifica_integridade
if errorlevel 1 goto :integridade_falhou

REM -- Modo diagnostico: so confere a arvore e sai -----------------------------
REM Com IMAN_TERRA_CHECK_ONLY=1 o launcher confere o manifesto, imprime o
REM resultado e sai SEM copiar perfil, escrever customizacao ou abrir o QGIS.
REM POR QUE ISSO EXISTE: o teste do manifesto precisa exercitar ESTA rotina. Um
REM teste que reimplementa a verificacao passa a validar a copia, nao o produto.
REM Ver tools\test-launcher-manifest.ps1.
if "%IMAN_TERRA_CHECK_ONLY%"=="1" (
  echo INTEGRIDADE=OK
  echo QGIS_ROOT=%QGIS_ROOT%
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

REM -- Abre o QGIS PRIVADO com o perfil IMAN isolado ---------------------------
REM Chamamos o bin\qgis-ltr.bat DA PROPRIA ARVORE, e nao o .exe direto: e ele
REM que monta o ambiente (OSGEO4W_ROOT, PROJ_DATA, GDAL_DATA, PYTHONHOME,
REM QT_PLUGIN_PATH...) chamando o o4w_env.bat, que deriva a raiz de %~dp0 e
REM ZERA o PATH herdado. Medido no #016: nenhuma dessas variaveis carrega
REM caminho gravado em tempo de instalacao, e por isso a arvore roda relocada.
REM Chamar o .exe direto subiria sem PROJ nem GDAL configurados.
REM
REM SEM --project: abrir mostra a HOME de boas-vindas no miolo (fatia #006). O
REM projeto demo fica acessivel pela acao "Abrir projeto demo" do plugin de marca.
call "%QGIS_BAT%" ^
  --profiles-path "%PROFILES_ROOT%" ^
  --profile "%PROFILE_NAME%" ^
  --code "%STARTUP%" ^
  --noversioncheck

endlocal
exit /b 0


REM ===========================================================================
REM  :verifica_integridade
REM  Le o manifesto gerado no build e confere, NA MAQUINA DO USUARIO:
REM    DIR |<rel>|<n>          contagem RECURSIVA de arquivos (nao so "existe")
REM    FILE|<rel>|<sha>|<tam>  tamanho + SHA-256 RECALCULADO aqui (E.5)
REM  Devolve errorlevel 1 e preenche FALHAS/DETALHE se algo divergir.
REM ===========================================================================
:verifica_integridade
set "FALHAS=0"
set "DETALHE="

if not exist "%QGIS_ROOT%\bin\qgis-ltr-bin.exe" (
  set "FALHAS=1"
  set "DETALHE=o executavel do QGIS nao esta em %QGIS_ROOT%\bin\qgis-ltr-bin.exe"
  exit /b 1
)
if not exist "%QGIS_BAT%" (
  set "FALHAS=1"
  set "DETALHE=falta %QGIS_BAT% - a arvore esta incompleta"
  exit /b 1
)
if not exist "%MANIFESTO%" (
  set "FALHAS=1"
  set "DETALHE=o manifesto de integridade nao foi encontrado em %MANIFESTO%"
  exit /b 1
)

REM --- ANTES de contar: o caminho comporta a arvore? -------------------------
REM O `dir /s` PULA EM SILENCIO o que passa do limite classico de 260
REM caracteres. Num caminho de instalacao longo a contagem viria mais baixa e a
REM guarda acusaria "copia truncada" numa arvore intacta. Medido em 2026-09-07:
REM com a raiz a 126 caracteres, apps\Python312 contou 19.664 em vez de 19.666.
REM Entao o comprimento e conferido PRIMEIRO, e o diagnostico e outro.
for /f "usebackq eol=# tokens=1,2 delims=|" %%A in ("%MANIFESTO%") do (
  if /i "%%A"=="MAXREL" set "MAXREL=%%B"
)
if defined MAXREL (
  call :strlen QGIS_ROOT LEN_ROOT
  set /a PIOR=!LEN_ROOT!+1+!MAXREL!
  if !PIOR! GTR 259 (
    set "CAMINHO_LONGO=1"
    exit /b 1
  )
)

for /f "usebackq eol=# tokens=1,2,3,4 delims=|" %%A in ("%MANIFESTO%") do (
  if /i "%%A"=="VERSAO" (
    if not "%%B"=="%QGIS_VERSION%" (
      set /a FALHAS+=1
      set "DETALHE=!DETALHE! [versao do manifesto ^(%%B^) difere da do launcher ^(%QGIS_VERSION%^)]"
    )
  )
  if /i "%%A"=="DIR"  call :confere_dir  "%%B" "%%C"
  if /i "%%A"=="FILE" call :confere_file "%%B" "%%C" "%%D"
)

if !FALHAS! GTR 0 exit /b 1
exit /b 0

REM --- DIR: presenca + contagem recursiva ------------------------------------
:confere_dir
set "REL=%~1"
set "ESPERADO=%~2"
if not exist "%QGIS_ROOT%\%REL%\" (
  set /a FALHAS+=1
  set "DETALHE=!DETALHE! [ausente: %REL%]"
  exit /b 0
)
set "N=0"
for /f %%N in ('dir /a-d /b /s "%QGIS_ROOT%\%REL%" 2^>nul ^| "%WFIND%" /c /v ""') do set "N=%%N"
if not "!N!"=="%ESPERADO%" (
  set /a FALHAS+=1
  set "DETALHE=!DETALHE! [%REL%: !N! arquivos, esperados %ESPERADO%]"
)
exit /b 0

REM --- FILE: presenca + tamanho + SHA-256 recalculado ------------------------
REM E.5: o hash e CALCULADO aqui, na maquina do usuario. Comparar um valor
REM transcrito do build contra ele mesmo nao provaria nada.
:confere_file
set "REL=%~1"
set "SHA_ESPERADO=%~2"
set "TAM_ESPERADO=%~3"
if not exist "%QGIS_ROOT%\%REL%" (
  set /a FALHAS+=1
  set "DETALHE=!DETALHE! [ausente: %REL%]"
  exit /b 0
)
for %%F in ("%QGIS_ROOT%\%REL%") do set "TAM=%%~zF"
if not "!TAM!"=="%TAM_ESPERADO%" (
  set /a FALHAS+=1
  set "DETALHE=!DETALHE! [%REL%: !TAM! bytes, esperados %TAM_ESPERADO%]"
  exit /b 0
)
set "SHA_OBTIDO="
REM %WCERTUTIL% SEM aspas de proposito: quando a linha de comando de um for /f
REM COMECA com aspa, o cmd aplica a regra especial de remocao de aspas e o
REM comando sai deformado - medido em 2026-09-07, os dois SHA-256 vinham
REM vazios e a guarda acusava arvore alterada numa arvore intacta. O caminho
REM nao tem espaco (%%SystemRoot%% e C:\Windows em toda instalacao do Windows),
REM entao dispensar as aspas aqui e seguro; o %%WFIND%% fica quotado porque
REM esta no MEIO do pipe, onde a regra nao se aplica.
for /f "skip=1 tokens=* delims=" %%H in ('%WCERTUTIL% -hashfile "%QGIS_ROOT%\%REL%" SHA256 2^>nul') do (
  if not defined SHA_OBTIDO set "SHA_OBTIDO=%%H"
)
set "SHA_OBTIDO=!SHA_OBTIDO: =!"
if /i not "!SHA_OBTIDO!"=="%SHA_ESPERADO%" (
  set /a FALHAS+=1
  set "DETALHE=!DETALHE! [%REL%: SHA-256 diferente do gerado no build]"
)
exit /b 0


REM --- comprimento de string em cmd puro -------------------------------------
REM %~1 = nome da variavel de entrada ; %~2 = nome da variavel de saida.
:strlen
setlocal EnableDelayedExpansion
set "s=!%~1!#"
set "n=0"
for %%P in (2048 1024 512 256 128 64 32 16 8 4 2 1) do (
  if "!s:~%%P!" NEQ "" ( set /a n+=%%P & set "s=!s:~%%P!" )
)
endlocal & set "%~2=%n%"
exit /b 0


REM ===========================================================================
:integridade_falhou
if defined CAMINHO_LONGO goto :caminho_longo
echo.
echo   ============================================================
echo    %PRODUCT_NAME% NAO PODE ABRIR
echo   ============================================================
echo.
echo    A copia do QGIS que acompanha o %PRODUCT_NAME% esta
echo    INCOMPLETA ou ALTERADA.
echo.
echo    O que foi encontrado:
echo      !DETALHE!
echo.
echo    Por que o produto nao abre assim, em vez de so avisar:
echo    uma copia truncada do QGIS NAO da erro - ela devolve
echo    COORDENADA ERRADA, em silencio. Abrir agora colocaria isso
echo    num memorial descritivo.
echo.
echo    O que fazer: reinstalar o %PRODUCT_NAME%.
echo    Arvore conferida: %QGIS_ROOT%
echo    Manifesto       : %MANIFESTO%
echo.
pause
endlocal
exit /b 1

REM ===========================================================================
:caminho_longo
echo.
echo   ============================================================
echo    %PRODUCT_NAME% NAO PODE ABRIR - caminho longo demais
echo   ============================================================
echo.
echo    O %PRODUCT_NAME% foi instalado num caminho fundo demais para
echo    o limite de 260 caracteres do Windows.
echo.
echo      raiz do QGIS      : %QGIS_ROOT%
echo      comprimento       : !LEN_ROOT! caracteres
echo      maior caminho     : !MAXREL! caracteres dentro da arvore
echo      pior caso         : !PIOR! (o limite classico e 259)
echo.
echo    Isto NAO significa que a copia esta corrompida - significa que
echo    parte da arvore nao pode nem ser LIDA daqui. Abrir assim faria
echo    o QGIS subir sem componentes, em silencio.
echo.
echo    O que fazer: reinstalar o %PRODUCT_NAME% num caminho mais curto.
echo.
pause
endlocal
exit /b 1
