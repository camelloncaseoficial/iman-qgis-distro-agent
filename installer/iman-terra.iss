; ============================================================================
;  IMAN Terra - instalador Inno Setup (Opcao 1, no-fork; powered by QGIS)
;
;  Instalador BUNDLADO (D-IMAN-028, via A2a): o pacote EMBARCA o instalador
;  oficial do QGIS (MSI) e o encadeia, instalando offline. Uma unica instalacao
;  entrega os dois softwares. NAO e fork: o binario oficial nao e modificado
;  (D-IMAN-028/DB-1); ele apenas e redistribuido sem alteracao.
;
;  Isto INVERTE a premissa anterior ("instalador LEVE, exige o QGIS ja
;  instalado"): a maquina SEM QGIS passa a ser o caminho feliz principal.
;
;  Ordem deliberada (DB-15): o QGIS entra ANTES da camada de marca, e falha do
;  QGIS ABORTA a instalacao inteira, deixando a maquina como estava.
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
#define QgisBaselineVersion "3.44.9"
#define Publisher "Instituto IMAN"
#define PublisherDir "InstitutoIMAN"

; --- payload do QGIS --------------------------------------------------------
; DB-5: o MSI (~541 MB) NAO entra no git. O build.ps1 o estagia em
; installer\payload\ em tempo de build, conferindo o SHA-256 antes de compilar.
#define QgisPayloadFile "QGIS-OSGeo4W-" + QgisBaselineVersion + "-1.msi"
#define QgisPayloadPath "payload\" + QgisPayloadFile

; Guarda de compilacao: sem o payload o .exe sairia "bundlado" mas vazio - e o
; defeito so apareceria na VM. Falhar aqui e barato; falhar la, nao.
#if !FileExists(AddBackslash(SourcePath) + QgisPayloadPath)
  #error Payload do QGIS ausente em installer\payload\. Rode installer\build.ps1 (ele baixa/estagia e confere o SHA-256) em vez de chamar o ISCC na mao.
#endif

[Setup]
; AppId fixo (nao reutilizar noutro produto). Uninstall usa este GUID.
AppId={{7B3A9E42-1C6D-4E9F-9A21-6F2E5A1D8B34}
AppName={#ProductName}
AppVersion={#ProductVersion}
AppVerName={#ProductName} {#ProductVersion}
AppPublisher={#Publisher}
VersionInfoDescription={#ProductName} - powered by QGIS (QGIS LTR {#QgisBaselineVersion} embarcado)
DefaultDirName={autopf}\{#ProductName}
DisableProgramGroupPage=yes
DisableDirPage=no
; D-IMAN-028/DB-7: o MSI do QGIS e ALLUSERS=1 (per-machine) e, sob /qn, o
; msiexec NAO exibe UAC - ou ja esta elevado, ou falha com 1625. Logo a
; elevacao tem de vir do NOSSO setup, UMA unica vez, e ser herdada pelo
; msiexec. Por isso 'admin' e por isso o override por dialogo SAI: deixar o
; usuario escolher "instalar so pra mim" produziria um setup sem elevacao que
; falharia no meio, ao encadear o QGIS.
; CONSEQUENCIA ACEITA: a premissa "usuario NAO administrador" cai (DB-7).
PrivilegesRequired=admin
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
Compression=lzma2
; SolidCompression=no e DELIBERADO, nao descuido (era 'yes' ate a fatia #011).
; O payload e um MSI ja comprimido: recomprimi-lo em bloco solido rendeu 1,8%
; (534,44 MB x 544,13 MB) e custou 8x no build (90,9 s x 11,1 s) - medido na
; fatia #010/S7. Pior: com bloco solido, o ExtractTemporaryFile() do payload
; obriga a descomprimir sequencialmente na MAQUINA DO USUARIO, penalizando
; justamente a maquina fraca de prefeitura. Trocamos 10 MB de download por
; instalacao mais rapida no alvo.
SolidCompression=no
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar um atalho na Area de Trabalho"; GroupDescription: "Atalhos adicionais:"; Flags: unchecked

[Files]
; --- payload do QGIS ------------------------------------------------------
; 'dontcopy': o MSI NAO e um arquivo instalado - e insumo do PrepareToInstall,
; extraido sob demanda por ExtractTemporaryFile(). Fica em {tmp} e o Inno o
; remove ao final. 'nocompression': ver a nota de SolidCompression acima.
Source: "{#QgisPayloadPath}"; Flags: dontcopy nocompression

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

; NOTA: nao ha secao [UninstallDelete] para %APPDATA%\{#PublisherDir}\{#ProductName}.
; Isso e PROPOSITAL (BL-3): o perfil isolado do usuario e seus dados NAO sao
; apagados no uninstall. Removem-se apenas os arquivos instalados em {app}.
;
; NOTA 2 (D-IMAN-028/DB-11, decisao ABERTA): desinstalar o IMAN Terra NAO
; remove o QGIS. Nao ha, de proposito, nenhuma chamada de msiexec /x aqui.
; Remover o QGIS quebraria o trabalho GIS de quem passou a usa-lo para outra
; coisa. Enquanto o arquiteto/sponsor nao arbitrarem, a opcao nao-destrutiva
; e a unica aceitavel.

[Code]
{ ==========================================================================
  Encadeamento do instalador oficial do QGIS (D-IMAN-028 / via A2a).

  POR QUE PrepareToInstall E NAO [Run]:
  o [Run] do Inno so executa DEPOIS que os arquivos ja foram copiados, e
  IGNORA o exit code por padrao. Os dois pontos violam o DB-15 ("QGIS
  primeiro; falha aborta"). PrepareToInstall roda ANTES de qualquer arquivo
  ser instalado e, ao devolver string nao-vazia, ABORTA a instalacao exibindo
  a mensagem - deixando a maquina exatamente como estava.
  ========================================================================== }

const
  { ProductCode EXATO do payload embarcado. ATENCAO: e especifico da VERSAO -
    trocar QgisBaselineVersion OBRIGA a trocar este GUID junto, senao o "pulo"
    do M2a nunca casa e o instalador reconfigura o QGIS a cada execucao.
    Medido em 2026-07-31 no MSI oficial QGIS-OSGeo4W-3.44.9-1.msi. }
  QgisProductCode = '{8397FA4A-7089-1014-9008-9EE76A62B1BC}';
  ChaveArp = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\';

{ O QGIS ja instalado E EXATAMENTE o do payload?

  D-IMAN-028/DB-16 - ARMADILHA DE 32 BITS, medida em 2026-07-31: a chave ARP do
  QGIS existe SO na view de 64 bits do registro (Registry64 encontra;
  Registry32 nao). Um processo de 32 bits e redirecionado para WOW6432Node e
  enxerga False.
  Usamos HKLM64 EXPLICITAMENTE em vez de depender de
  ArchitecturesInstallIn64BitMode: uma funcao nao deve ficar correta por causa
  de uma diretiva noutra secao, que alguem pode mexer sem ligar os pontos. Se
  isso falhar, o Check devolve "precisa instalar" SEMPRE, e o instalador
  reconfigura o QGIS do usuario silenciosamente - parecendo funcionar. }
function QgisDoPayloadInstalado(): Boolean;
begin
  Result := RegKeyExists(HKLM64, ChaveArp + QgisProductCode);
end;

{ Traduz o codigo do msiexec para uma frase que o tecnico na frente da maquina
  consiga usar. Codigos NAO MEDIDOS na fatia #010 sao tratados como falha -
  desconhecido nunca e sucesso. }
function ExplicaCodigoMsi(Codigo: Integer): String;
begin
  case Codigo of
    1602: Result := 'A instalacao do QGIS foi cancelada.';
    1603: Result := 'Erro fatal durante a instalacao do QGIS.';
    1618: Result := 'Ha outra instalacao do Windows em andamento. Conclua-a (ou reinicie o computador) e tente de novo.';
    1619: Result := 'O pacote do QGIS embarcado nao pode ser aberto (arquivo corrompido ou incompleto).';
    { 1625 NAO significa "ja instalado" - e elevacao negada. Confundir os dois
      faria o instalador seguir sem QGIS achando que estava tudo certo. }
    1625: Result := 'O Windows recusou a instalacao do QGIS por falta de permissao de administrador.';
    1638: Result := 'Ja existe outra versao deste mesmo pacote do QGIS instalada.';
  else
    Result := 'A instalacao do QGIS terminou com um erro inesperado.';
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Codigo: Integer;
  CaminhoMsi, CaminhoLog, Parametros: String;
begin
  Result := '';

  { M2a - "pular" e trabalho NOSSO, nunca do MSI. Medido na fatia #010: o MSI
    oficial nao tem Upgrade table nem FindRelatedProducts; ele NUNCA procura
    outra versao. Se chamado com o mesmo ProductCode ja instalado, ele entra em
    RECONFIGURACAO do produto existente em vez de nao fazer nada. }
  if QgisDoPayloadInstalado() then
  begin
    Log('QGIS {#QgisBaselineVersion} (' + QgisProductCode + ') ja instalado: PULANDO o encadeamento.');
    Exit;
  end;

  { D-IMAN-028/DB-13 - COEXISTENCIA: nao ha nenhuma verificacao aqui de "existe
    outro QGIS?" de proposito. Outra versao (3.44.12, 3.34, 3.40) fica onde
    esta, intacta: o MSI oficial instala lado a lado, em diretorio proprio e
    com ProductCode proprio. Atualizar ou remover a instalacao de terceiro seria
    acao destrutiva e NAO foi arbitrada. Quem resolve a ambiguidade de "qual
    QGIS abrir" e o launcher (DB-14), nao o instalador. }

  Log('Encadeando o instalador oficial do QGIS {#QgisBaselineVersion}...');
  ExtractTemporaryFile('{#QgisPayloadFile}');

  CaminhoMsi := ExpandConstant('{tmp}\{#QgisPayloadFile}');
  CaminhoLog := ExpandConstant('{tmp}\qgis-install.log');
  Parametros := '/i "' + CaminhoMsi + '" /qn /norestart /L*v "' + CaminhoLog + '"';

  if not Exec('msiexec.exe', Parametros, '', SW_HIDE, ewWaitUntilTerminated, Codigo) then
  begin
    Result := 'Nao foi possivel iniciar o instalador do QGIS (msiexec).' + #13#10 +
              'A instalacao do {#ProductName} foi cancelada e nada foi alterado nesta maquina.';
    Exit;
  end;

  { Sucesso e SO 0 e 3010. Todos os demais codigos do caminho de instalacao
    seguem NAO MEDIDOS (fatia #010/S2) - por isso "else" e falha, nunca
    tolerancia. }
  case Codigo of
    0: Log('QGIS instalado com sucesso (codigo 0).');
    3010: begin
      Log('QGIS instalado; exige reinicio (codigo 3010).');
      NeedsRestart := True;
    end;
  else
    { begin/end obrigatorio: o ramo 'else' do case aceita UMA instrucao so. }
    begin
      Log('FALHA ao instalar o QGIS: codigo ' + IntToStr(Codigo));
      Result := ExplicaCodigoMsi(Codigo) + #13#10 + #13#10 +
                'Codigo do Windows Installer: ' + IntToStr(Codigo) + #13#10 +
                'Log detalhado: ' + CaminhoLog + #13#10 + #13#10 +
                'A instalacao do {#ProductName} foi cancelada e nada foi alterado nesta maquina.';
    end;
  end;
end;
