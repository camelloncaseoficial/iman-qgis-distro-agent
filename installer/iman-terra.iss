; ============================================================================
;  IMAN Terra - instalador Inno Setup (Opcao 1, no-fork; powered by QGIS)
;  Instalador LEVE: instala a camada de marca (launcher + perfil + plugin +
;  startup + demo + notices). Exige o QGIS LTR ja instalado (o launcher orienta
;  se ausente). NAO instala/altera/remove o QGIS. Perfil do usuario intacto (BL-3).
;  Marca: fonte unica em docs/design-system.md e brand.py (BL-4).
;  ASCII-only de proposito (encoding seguro do compilador Inno).
; ============================================================================

#define ProductName "IMAN Terra"
#define ProductVersion "0.1.0"
#define Publisher "Instituto IMAN"
#define PublisherDir "InstitutoIMAN"

[Setup]
; AppId fixo (nao reutilizar noutro produto). Uninstall usa este GUID.
AppId={{7B3A9E42-1C6D-4E9F-9A21-6F2E5A1D8B34}
AppName={#ProductName}
AppVersion={#ProductVersion}
AppVerName={#ProductName} {#ProductVersion}
AppPublisher={#Publisher}
VersionInfoDescription={#ProductName} - powered by QGIS
DefaultDirName={autopf}\{#ProductName}
DisableProgramGroupPage=yes
DisableDirPage=no
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
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
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar um atalho na Area de Trabalho"; GroupDescription: "Atalhos adicionais:"; Flags: unchecked

[Files]
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
