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
REM  - RECONCILIA o perfil ISOLADO com o template desta versao, antes de o QGIS
REM    ler o perfil (DB-26, fatia #030). Ate a #029 o perfil era semeado no
REM    primeiro uso e nunca mais reconciliado: quem ja tinha perfil nao recebia
REM    tema, plugin, splash nem chave nenhuma de uma versao nova.
REM    Nunca toca o perfil do usuario fora do nosso (BL-3).
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
set "DECLARACAO=%APP_HOME%\profile-template\PERFIL-DO-PRODUTO.json"
set "SYNC=%APP_HOME%\launcher\Sync-Perfil.ps1"
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
set "WPOWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

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

REM ===========================================================================
REM  RECONCILIACAO DO PERFIL (DB-26, fatia #030)
REM
REM  O QUE ESTAVA AQUI ATE A #029, e por que saiu:
REM
REM      if not exist "%%PROFILE_DIR%%\QGIS\QGIS3.ini" ( xcopy ... )
REM
REM  Duas linhas que semeavam o perfil no PRIMEIRO uso e nunca mais o
REM  reconciliavam. Tema, plugin de marca, splash e chaves do QGIS3.ini: quem ja
REM  tinha perfil nao recebia NADA de uma versao nova. O aceite nunca pegou isso
REM  porque ele reconstroi o perfil do zero a cada rodada - sempre exercitava o
REM  template novo. A distancia entre "o teste passa" e "o usuario ve" era
REM  exatamente aquela linha.
REM
REM  O QUE ENTROU: Sync-Perfil.ps1, que SEMEIA E RECONCILIA na mesma rotina.
REM  Ela roda AQUI, antes de o QGIS ler o perfil - no --code do iman_startup.py
REM  seria tarde, porque o QGIS ja teria importado o codigo velho do iman_brand.
REM  A fronteira do que e do produto e do que e do usuario mora em
REM  profile-template\PERFIL-DO-PRODUTO.json, e so la.
REM
REM  O splashpath tambem passou para la. Ele era reescrito a CADA execucao, e
REM  isso sozinho fazia toda segunda abertura escrever no perfil - com ele aqui,
REM  "a segunda abertura nao escreve nada" seria impossivel de cumprir.
REM
REM  POR QUE EM POWERSHELL, e chamado por caminho ABSOLUTO: reconciliar exige
REM  SHA-256 por arquivo e edicao cirurgica de .ini preservando bytes; em cmd
REM  puro isso vira um emaranhado que ninguem audita. O caminho absoluto segue a
REM  mesma regra do %WFIND%/%WCERTUTIL% acima - launcher que depende do PATH do
REM  usuario e launcher que quebra na maquina de quem tem ferramentas instaladas.
REM ===========================================================================
if not exist "%WPOWERSHELL%" (
  set "RECON_DETALHE=o Windows PowerShell nao foi encontrado em %WPOWERSHELL%"
  goto :reconciliacao_falhou
)
if not exist "%SYNC%" (
  set "RECON_DETALHE=falta %SYNC% - a instalacao do %PRODUCT_NAME% esta incompleta"
  goto :reconciliacao_falhou
)

set "RECON_OUT=%TEMP%\iman-terra-reconciliacao.txt"
"%WPOWERSHELL%" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SYNC%" ^
  -Template "%TEMPLATE%" ^
  -Declaracao "%DECLARACAO%" ^
  -Perfil "%PROFILE_DIR%" ^
  -QgisRoot "%QGIS_ROOT%" > "%RECON_OUT%" 2>&1
set "RECON_RC=%ERRORLEVEL%"

REM -- Modo diagnostico da guarda ---------------------------------------------
REM Com IMAN_TERRA_RECONCILE_ONLY=1 o launcher confere a arvore, RECONCILIA o
REM perfil, imprime o relato cru e sai SEM abrir o QGIS. Mesma razao do
REM IMAN_TERRA_CHECK_ONLY: o teste da reconciliacao precisa exercitar ESTA
REM rotina. Teste que reimplementa a reconciliacao valida a copia (C.1).
REM Ver tools\test-reconciliacao-perfil.ps1.
if "%IMAN_TERRA_RECONCILE_ONLY%"=="1" (
  type "%RECON_OUT%"
  endlocal
  exit /b %RECON_RC%
)

if "%RECON_RC%"=="2" goto :produto_ja_aberto
if not "%RECON_RC%"=="0" goto :reconciliacao_falhou

REM Silencio quando nao havia o que fazer; uma linha quando houve.
"%WFIND%" /c "RECONCILIACAO=NADA_A_FAZER" "%RECON_OUT%" >nul
if errorlevel 1 (
  echo   [%PRODUCT_NAME%] Perfil atualizado para esta versao.
)

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
REM PISO, nao igualdade. A arvore NAO e somente-leitura em uso: medido em
REM 2026-09-07, na segunda abertura do produto instalado, apps\Python312 tinha
REM 20.111 arquivos contra os 19.666 do manifesto - 445 .pyc que o proprio
REM Python grava em __pycache__ ao importar, mais um is-*.tmp que o Inno deixou
REM para tras na instalacao. Nenhum dos dois e truncamento.
REM
REM Com igualdade exata, o produto ABRIA UMA VEZ e se recusava a abrir na
REM segunda - o pior falso positivo possivel. A guarda existe para pegar copia
REM TRUNCADA, e truncar sempre diminui a contagem; crescer nunca e truncar.
REM Adulteracao de conteudo continua coberta pelo SHA-256 dos arquivos
REM criticos, que e comparacao exata.
if !N! LSS %ESPERADO% (
  set /a FALHAS+=1
  set "DETALHE=!DETALHE! [%REL%: !N! arquivos, faltam ao menos %ESPERADO%]"
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
REM  :reconciliacao_falhou   (DB-26 / R6, C.3 fail-loud)
REM
REM  POR QUE RECUSA ABRIR, e nao "avisa e abre assim mesmo".
REM
REM  Abrir sem reconciliar pode ser abrir em EPSG:4674. Um perfil semeado antes
REM  de 4dfeb93 (2026-07-12) tem esse CRS padrao cravado, e o QGIS nao reclama
REM  de CRS "errado" - ele so desenha. O defeito nao aparece como erro: aparece
REM  como MEDICAO NOVA NO CRS ERRADO num memorial descritivo. E a mesma classe
REM  de falha silenciosa da arvore truncada, e a resposta do produto e a mesma.
REM
REM  E a reconciliacao que morreu no meio NAO atualiza a base: o perfil nunca
REM  passa por atualizado, e a proxima abertura refaz o plano inteiro.
:reconciliacao_falhou
echo.
echo   ============================================================
echo    %PRODUCT_NAME% NAO PODE ABRIR
echo   ============================================================
echo.
echo    Nao foi possivel atualizar o seu perfil para esta versao.
echo.
if defined RECON_DETALHE (
  echo    O que foi encontrado:
  echo      %RECON_DETALHE%
) else (
  echo    Relato da reconciliacao:
  if exist "%RECON_OUT%" type "%RECON_OUT%"
)
echo.
echo    Por que o produto nao abre assim, em vez de so avisar:
echo    abrir com o perfil desatualizado pode ser abrir com o CRS
echo    padrao ANTIGO. O QGIS nao reclama disso - ele so desenha, e
echo    a medicao sai errada sem aviso nenhum.
echo.
echo    O seu perfil NAO foi dado por atualizado: a proxima abertura
echo    tenta de novo, do zero.
echo.
echo    O que fazer: feche o %PRODUCT_NAME%, abra de novo. Se
echo    continuar, reinstale o %PRODUCT_NAME%.
echo    Perfil: %PROFILE_DIR%
echo.
pause
endlocal
exit /b 1

REM ===========================================================================
REM  :produto_ja_aberto   (DB-26 / R7)
REM
REM  Ha o que aplicar E ja existe uma janela deste produto aberta. Reconciliar
REM  agora seria pior que nao reconciliar: o QGIS REESCREVE o QGIS3.ini ao sair,
REM  e a instancia que ja esta rodando apagaria as chaves recem-aplicadas -
REM  ficaria uma base dizendo "aplicado" sobre um .ini que voltou atras. E o
REM  plugin de marca velho continua carregado na memoria dela de qualquer jeito.
REM
REM  Quando NAO ha o que aplicar, a segunda janela abre normalmente: o produto
REM  nao atrapalha quem so quer duas janelas.
:produto_ja_aberto
echo.
echo   ============================================================
echo    %PRODUCT_NAME% - feche a janela que ja esta aberta
echo   ============================================================
echo.
echo    Esta versao tem uma atualizacao de perfil para aplicar, e o
echo    %PRODUCT_NAME% ja esta aberto.
echo.
echo    Aplicar agora nao funcionaria: ao fechar, a janela que ja
echo    esta aberta regravaria a configuracao antiga por cima - e o
echo    perfil ficaria marcado como atualizado sem estar.
echo.
echo    O que fazer: feche o %PRODUCT_NAME% e abra de novo. A
echo    atualizacao e aplicada na abertura seguinte.
echo.
pause
endlocal
exit /b 2

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
