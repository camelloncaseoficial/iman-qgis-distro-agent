; ============================================================================
;  IMAN Terra - instalador Inno Setup (Opcao 1, no-fork; powered by QGIS)
;
;  VIA A1 (D-IMAN-028 emenda 2026-09-06; executavel provado pelo spike #016):
;  o QGIS NAO e mais instalado ao lado - ele VIVE DENTRO do produto, em
;  {app}\qgis. UM produto, UM instalador, SEM ELEVACAO.
;
;  O que isso resolve, na palavra do sponsor: "a sensacao de instalacao de um
;  produto que na metade aparece outro produto sendo instalado". Nao aparece
;  mais - nao ha msiexec encadeado, nao ha UI de terceiro no meio do wizard.
;
;  E o que SOME junto:
;    - o DB-19 (a janela que parecia travada por ~4 minutos): nao ha mais
;      espera bloqueante dentro do wizard;
;    - o DB-16 como CLASSE INTEIRA: nao existe mais o ramo "ja instalado:
;      PULANDO", que era o pior caminho de falha silenciosa do produto;
;    - a premissa violada do CHECKLIST 0.2: PrivilegesRequired volta a
;      'lowest' e o DB-7 se INVERTE.
;
;  NAO e fork: o binario oficial do QGIS nao e modificado (D-IMAN-028/DB-1);
;  ele e redistribuido sem alteracao, extraido do MSI oficial em tempo de build.
;  Perfil do usuario intacto (BL-3). Marca em fonte unica (BL-4).
;  ASCII-only de proposito (encoding seguro do compilador Inno).
; ============================================================================

#define ProductName "IMAN Terra"
; 0.1.0 JA FOI consumida pelo build de 05/07/2026 (fatia 1). Reusar a versao tornaria a
; evidencia do BL-7 ambigua: nao daria pra saber QUAL artefato foi testado na VM.
#define ProductVersion "0.3.0"
; Versao do QGIS LTR EMBARCADA no instalador (D-IMAN-028/DB-12). Antes isto
; significava "versao suportada declarada"; agora e o que o pacote INSTALA.
; Fonte unica com docs/distro-architecture.md. installer\build.ps1 le este
; define para estagiar o payload, conferir o SHA-256 e carimbar o BUILD_INFO.txt.
;
; 3.44.9 -> 3.44.13 em 2026-09-01 (decisao do sponsor na fatia #013): a 3.44.13
; passa a ser a baseline padrao. Trocar este numero OBRIGA a trocar junto, e o
; build recusa se algum ficar para tras:
;   - set QGIS_VERSION       (app\launcher\IMAN-Terra.bat)
;   - $PayloadHashes         (installer\build.ps1)
;   - VERSAO|<x>             (o manifesto, regerado por New-ArvoreQgis.ps1)
; O QgisProductCode SAIU nesta lista na fatia #019: com a via A1 nao ha mais
; ProductCode nenhum a casar - o QGIS nao e instalado, e extraido.
#define QgisBaselineVersion "3.44.13"
#define Publisher "Instituto IMAN"
#define PublisherDir "InstitutoIMAN"

; --- arvore privada do QGIS -------------------------------------------------
; DB-5: nem o MSI (~555 MB) nem a arvore extraida (~2,2 GB) entram no git. O
; build.ps1 estagia o payload e confere o SHA-256; installer\New-ArvoreQgis.ps1
; extrai a arvore com `msiexec /a` para installer\stage\ em tempo de build.
#define QgisTreeDir "stage\qgis\QGIS " + QgisBaselineVersion
#define QgisManifest "stage\qgis-manifest.txt"

; Guarda de compilacao: sem a arvore o .exe sairia "com o QGIS embarcado" mas
; vazio - e o defeito so apareceria na VM. Falhar aqui e barato; falhar la, nao.
#if !FileExists(AddBackslash(SourcePath) + QgisTreeDir + "\bin\qgis-ltr-bin.exe")
  #error Arvore do QGIS ausente em installer\stage\. Rode installer\build.ps1 (ele estagia o payload e extrai a arvore) em vez de chamar o ISCC na mao.
#endif
; O manifesto e o que o launcher confere na maquina do usuario ANTES de subir.
; Sem ele o produto se recusaria a abrir - melhor descobrir aqui.
#if !FileExists(AddBackslash(SourcePath) + QgisManifest)
  #error Manifesto de integridade ausente. Ele e gerado por installer\New-ArvoreQgis.ps1 junto com a arvore.
#endif

[Setup]
; AppId fixo (nao reutilizar noutro produto). Uninstall usa este GUID.
AppId={{7B3A9E42-1C6D-4E9F-9A21-6F2E5A1D8B34}
AppName={#ProductName}
AppVersion={#ProductVersion}
AppVerName={#ProductName} {#ProductVersion}
AppPublisher={#Publisher}
VersionInfoDescription={#ProductName} - powered by QGIS (QGIS LTR {#QgisBaselineVersion} embarcado)
; VIA A1 - o produto inteiro vive no perfil do usuario, sem elevacao.
; %LOCALAPPDATA%\Programs\IMAN Terra\  (o QGIS em ...\qgis\)
DefaultDirName={localappdata}\Programs\{#ProductName}
DisableProgramGroupPage=yes
DisableDirPage=no
; D-IMAN-028/DB-7 INVERTIDO (fatia #019). Antes 'admin' era obrigatorio porque
; o MSI encadeado do QGIS e ALLUSERS=1 e, sob /qn, o msiexec nao exibe UAC - ou
; ja esta elevado, ou falha com 1625. Sem msiexec encadeado essa amarra some:
; nada mais nesta instalacao pede elevacao, e o produto volta a caber na
; premissa "usuario NAO administrador" do CHECKLIST 0.2, que estava violada.
;
; CUIDADO AO MEXER: trocar isto para 'admin' de novo NAO e uma escolha de
; conforto - reabriria a premissa violada e mudaria o destino de {app} para
; area de sistema, quebrando o BL-3 que esta fatia acabou de reforcar.
PrivilegesRequired=lowest
OutputDir=dist
OutputBaseFilename=Instituto-IMAN-IMAN-Terra-Setup-{#ProductVersion}
SetupIconFile=..\app\assets\icon-iman-terra.ico
UninstallDisplayIcon={app}\assets\icon-iman-terra.ico
UninstallDisplayName={#ProductName}
LicenseFile=..\app\notices\LICENSE
WizardStyle=modern
; Imagens de marca do wizard (Inno 6 aceita PNG). Simbolo oficial folha+globo.
; O splash NATIVO de boot do QGIS continua sendo limite da Opcao 2 (fork) - aqui
; a arte oficial entra so na superficie que o no-fork alcanca (wizard do instalador).
WizardImageFile=..\app\assets\wizard-large.png
WizardSmallImageFile=..\app\assets\wizard-small.png
; D-IMAN-028/DB-21 - A CHAPA CINZA DO LOGO.
; O wizard-small.png era RGB SEM canal alfa, com o fundo #EBEEE8 cravado nos
; pixels; a pagina do wizard e clWindow (medido num build real desta bancada:
; #FFFFFF). Resultado: um retangulo cinza atras do logo, no canto superior
; direito de toda pagina interna. Nao era composicao do Inno - estava no
; arquivo.
; O conserto NAO e repintar o PNG com a cor da pagina: #FFFFFF nao e token da
; paleta (docs/design-system.md) e a cor da pagina vem do TEMA do Windows, nao
; de nos - repintar so troca a chapa de lugar no proximo tema. Com alfa real no
; PNG, esta diretiva manda o Inno RESPEITAR o canal alfa e o simbolo assenta
; sobre a cor que a pagina tiver.
; 'defined' (e nao 'premultiplied') porque o PIL grava alfa RETO, nao
; pre-multiplicado - ver app/assets/regenerate-brand-derivatives.py.
; Evidencia antes/depois: docs/verify/015-db21-wizard/.
WizardImageAlphaFormat=defined
Compression=lzma2
; SolidCompression=yes VOLTA na fatia #019, e a razao se inverteu junto com a
; via. Ate o #018 o payload era UM MSI ja comprimido: recomprimi-lo em bloco
; solido rendia 1,8% e custava 8x no build (fatia #010/S7). Agora o payload sao
; 37.337 arquivos CRUS - milhares de .py, .dll e dados que se parecem muito
; entre si. E exatamente o caso em que o bloco solido ganha.
; O tamanho final e o tempo de build estao medidos e relatados em
; docs/verify/019-a1-qgis-embarcado/ (STOP-AND-FLAG de tamanho).
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar um atalho na Area de Trabalho"; GroupDescription: "Atalhos adicionais:"; Flags: unchecked

[Files]
; --- a ARVORE PRIVADA do QGIS ---------------------------------------------
; Vira {app}\qgis\ - a raiz OSGeo4W do produto. E o que o launcher chama, e o
; que o manifesto descreve. Sem Excludes de proposito: a contagem de arquivos
; do manifesto tem de casar EXATAMENTE com o que foi instalado, senao a guarda
; de integridade acusaria corrupcao numa instalacao intacta.
Source: "{#QgisTreeDir}\*"; DestDir: "{app}\qgis"; Flags: recursesubdirs createallsubdirs ignoreversion
; O manifesto que o launcher confere na maquina do usuario (C.3 fail-loud).
; Fica FORA de {app}\qgis de proposito: dentro, ele mudaria a propria contagem.
Source: "{#QgisManifest}"; DestDir: "{app}"; DestName: "qgis-manifest.txt"; Flags: ignoreversion

; Camada de marca completa (app/*), preservando a arvore.
Source: "..\app\*"; DestDir: "{app}"; Excludes: "*.pyc,__pycache__,.gitkeep"; Flags: recursesubdirs createallsubdirs ignoreversion
; Copias na raiz para visibilidade dos creditos/licenca (BL-1).
Source: "..\app\notices\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\app\notices\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme

[Icons]
; Menu Iniciar (atalho para o launcher, com o icone de marca).
Name: "{autoprograms}\{#ProductName}"; Filename: "{app}\launcher\IMAN-Terra.bat"; WorkingDir: "{app}\launcher"; IconFilename: "{app}\assets\icon-iman-terra.ico"; Comment: "{#ProductName} - powered by QGIS"
; Area de Trabalho (opcional).
Name: "{autodesktop}\{#ProductName}"; Filename: "{app}\launcher\IMAN-Terra.bat"; WorkingDir: "{app}\launcher"; IconFilename: "{app}\assets\icon-iman-terra.ico"; Comment: "{#ProductName} - powered by QGIS"; Tasks: desktopicon
; Desinstalador no menu.
Name: "{autoprograms}\Desinstalar {#ProductName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\launcher\IMAN-Terra.bat"; Description: "Abrir o {#ProductName} agora"; Flags: postinstall shellexec skipifsilent nowait

[UninstallDelete]
; A ARVORE DO QGIS SAI INTEIRA, e nao so os arquivos que o Inno instalou.
;
; MEDIDO em 2026-09-07, num ciclo real de instalar -> abrir -> desinstalar
; nesta bancada: o uninstall deixou 817 arquivos / 14,69 MB para tras, TODOS
; .pyc. O Python grava bytecode em __pycache__ dentro da propria arvore ao
; importar, e o Inno so remove o que ele proprio instalou - esses .pyc nasceram
; depois, entao nao estavam na lista dele.
;
; Sem esta linha, cada instalar-usar-desinstalar deixaria um sedimento crescente
; no perfil do usuario. Com ela, {app}\qgis sai inteiro. E seguro apagar por
; caminho: esse diretorio e 100% nosso - foi criado por este instalador e nao ha
; nada do usuario la dentro (os dados dele vivem no perfil isolado, em
; %APPDATA%, que continua intocado).
Type: filesandordirs; Name: "{app}\qgis"

; NOTA: nao ha secao [UninstallDelete] para %APPDATA%\{#PublisherDir}\{#ProductName}.
; Isso e PROPOSITAL (BL-3): o perfil isolado do usuario e seus dados NAO sao
; apagados no uninstall. Removem-se apenas os arquivos instalados em {app}.
;
; NOTA 2 (fatia #019, via A1): o DB-11 ("desinstalar o IMAN Terra nao remove o
; QGIS") PERDEU OBJETO. Nao ha mais um QGIS de terceiro instalado por nos para
; decidir se removemos: o QGIS e nosso, vive em {app}\qgis, e sai junto com o
; resto - o Inno remove {app} inteiro por ter instalado tudo que esta la.
; Isso resolve os ~2,2 GB orfaos que a via A2 deixaria para tras, e mantem
; intacto o QGIS que o usuario porventura tenha instalado por conta propria:
; nunca encostamos nele, nem para instalar nem para remover.

[Code]

{ ==========================================================================
  Via A1: NAO HA MAIS ENCADEAMENTO.

  Ate a fatia #018 este bloco tinha ~170 linhas: PrepareToInstall chamava o
  msiexec com o MSI oficial do QGIS embarcado, traduzia exit codes, e detectava
  se o payload ja estava instalado. Tudo isso MORREU com a via A1, e nao por
  simplificacao - por remocao de superficie de falha:

    - QgisDoPayloadInstalado() / DB-16: era o ramo "ja instalado: PULANDO". Se
      a leitura da chave ARP falhasse (e ela SO existe na view de 64 bits - a
      armadilha medida em 2026-07-31), o instalador reconfigurava o QGIS do
      usuario em silencio, parecendo funcionar. Nao existe mais chave para ler.
    - ExplicaCodigoMsi() e os codigos 1602/1603/1618/1619/1625/1638: nao ha
      mais msiexec para devolver codigo.
    - O rotulo do DB-19 ("esta janela pode aparecer como Nao Respondendo"):
      nao ha mais espera bloqueante de 4 minutos dentro do wizard.

  O que substituiu tudo isso e mais forte: a arvore ja vem pronta dentro do
  pacote, e a GUARDA DE INTEGRIDADE do launcher confere o manifesto antes de
  subir o QGIS (ver app\launcher\IMAN-Terra.bat). O risco deixou de ser "o
  encadeamento falhou no meio" e passou a ser "a copia chegou truncada" - que e
  detectavel, e e detectado.
  ========================================================================== }
