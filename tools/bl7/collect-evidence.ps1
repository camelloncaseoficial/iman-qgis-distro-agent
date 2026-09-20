<#
=============================================================================
 BL-7 - coleta do ambiente da VM + esqueleto do RESULT.md

 Le do proprio Windows os dados que o RESULT.md exige (e que ninguem lembra de
 anotar direito na hora): versao do Windows, resolucao, escala DPI, se a sessao
 e de administrador, onde o IMAN Terra foi instalado e se o perfil isolado
 existe. Grava um RESULT-esqueleto.md pronto para preencher.

 PROCEDENCIA (fatia #036, A3). Desde o DB-24 o produto carrega a identidade do
 build em {app}\BUILD_ID.txt, e desde a via A1 ele carrega o QGIS dentro de
 {app}\qgis. Este script passou a ler os dois. Sem isso, o RESULT.md e um
 relatorio sobre binario anonimo: "versao 0.3.0" e string identica em todo
 artefato 0.3.0 ja compilado, canonico ou nao.

 RODE DEPOIS de instalar e abrir o IMAN Terra ao menos uma vez.

 EXEMPLO
   .\collect-evidence.ps1

 REQUISITOS: Windows PowerShell 5.1. Sem Python, sem git, sem modulos de
 terceiros, sem privilegio de administrador. ASCII-only de proposito.
=============================================================================
#>
[CmdletBinding()]
param(
    [string]$OutDir = (Join-Path $env:USERPROFILE 'Desktop\bl7-evidence'),
    [string]$PerfilIsolado = (Join-Path $env:APPDATA 'InstitutoIMAN\IMAN Terra\profiles\iman-distro'),
    # Raiz do produto instalado. E de la que saem a procedencia e o QGIS embarcado.
    [string]$Produto = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra')
)

$ErrorActionPreference = 'Stop'

function Get-Safe([scriptblock]$Block, $Fallback = 'nao detectado') {
    try {
        $v = & $Block
        if ($null -eq $v -or "$v" -eq '') { return $Fallback }
        return $v
    } catch {
        return $Fallback
    }
}

Write-Host ""
Write-Host "  BL-7 - coleta de ambiente" -ForegroundColor White
Write-Host ""

# --- Windows -----------------------------------------------------------------

$os = Get-Safe { Get-CimInstance Win32_OperatingSystem } $null
$winCaption = 'nao detectado'
$winVersao  = 'nao detectado'
$winArch    = 'nao detectado'
if ($os) {
    $winCaption = $os.Caption
    $winVersao  = "$($os.Version) (build $($os.BuildNumber))"
    $winArch    = $os.OSArchitecture
}
$winIdioma = Get-Safe { (Get-Culture).Name }

# --- privilegio --------------------------------------------------------------
# O criterio de adocao (TI municipal) e instalar SEM elevar, e desde a via A1
# (fatia #019) o produto cumpre isso: PrivilegesRequired=lowest, nada em
# Program Files, nada em HKLM. Se ESTA sessao for de administrador, o passo 4
# do checklist ("zero prompts de UAC") deixa de testar o que existe para testar.
$ehAdmin = Get-Safe {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
} $null

# --- video: resolucao e escala ----------------------------------------------

$resolucao = 'nao detectado'
$video = Get-Safe {
    Get-CimInstance Win32_VideoController |
        Where-Object { $_.CurrentHorizontalResolution } |
        Select-Object -First 1
} $null
if ($video) {
    $resolucao = "$($video.CurrentHorizontalResolution)x$($video.CurrentVerticalResolution)"
} else {
    # Fallback: WinForms faz parte do .NET Framework do Windows (nao e modulo
    # de terceiros), mas so responde em sessao interativa.
    $resolucao = Get-Safe {
        Add-Type -AssemblyName System.Windows.Forms
        $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        "$($b.Width)x$($b.Height)"
    }
}

# Escala: 96 dpi = 100%, 120 = 125%, 144 = 150%.
$dpi = Get-Safe {
    (Get-ItemProperty 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name AppliedDPI -ErrorAction Stop).AppliedDPI
} $null
$escala = 'nao detectado'
if ($dpi) { $escala = "{0}% ({1} dpi)" -f ([math]::Round($dpi / 96 * 100)), $dpi }

# --- PROCEDENCIA do produto instalado (DB-24 / fatia #033) -------------------
# {app}\BUILD_ID.txt e gravado pelo build.ps1 ANTES de compilar e viaja dentro
# do produto. E o unico lugar onde o produto INSTALADO sabe dizer de que build
# ele e. O SHA-256 do .exe nao esta la de proposito: ele so existe depois de
# compilar, e o arquivo entra NA compilacao. Ele vive no BUILD_INFO.txt.
$buildIdArq = Join-Path $Produto 'BUILD_ID.txt'
$buildId = [ordered]@{}
if (Test-Path -LiteralPath $buildIdArq) {
    foreach ($l in (Get-Content -LiteralPath $buildIdArq)) {
        if ($l -match '^\s*#') { continue }
        # [a-z0-9_] e nao [a-z_]: 'payload_sha256' tem digitos no nome, e com a
        # classe sem digitos ele nunca casava - saia 'nao detectado' num arquivo
        # que o trazia. Medido em 2026-09-20.
        if ($l -match '^([a-z0-9_]+)=(.*)$') { $buildId[$Matches[1]] = $Matches[2] }
    }
}
function BId([string]$Nome, $Fallback = 'nao detectado') {
    if ($buildId.Contains($Nome) -and "$($buildId[$Nome])" -ne '') { return $buildId[$Nome] }
    return $Fallback
}
# O commit curto tem de ser prefixo do completo. Se nao for, alguem editou o
# arquivo a mao - e o arquivo diz, na primeira linha, para nao fazer isso.
$commitCoerente = 'nao detectado'
if ($buildId.Contains('commit') -and $buildId.Contains('commit_curto')) {
    $commitCoerente = ([string]$buildId['commit']).StartsWith([string]$buildId['commit_curto'])
}

# --- QGIS EMBARCADO no produto (via A1, fatia #019) --------------------------
# O QGIS NAO e instalado ao lado: ele vive em {app}\qgis. A contagem de
# arquivos e comparada com o TOTAL do manifesto como PISO, nao como igualdade -
# o Python do proprio produto grava bytecode em __pycache__ ao importar, e
# crescer nunca e truncar.
$arvoreQgis = Join-Path $Produto 'qgis'
$manifestoArq = Join-Path $Produto 'qgis-manifest.txt'
$qgisEmbarcadoVersao = 'nao detectado'
$manifestoTotal = 0
$arvoreArquivos = 0
$arvoreExiste = Test-Path -LiteralPath $arvoreQgis
if (Test-Path -LiteralPath $manifestoArq) {
    foreach ($l in (Get-Content -LiteralPath $manifestoArq)) {
        if ($l -match '^VERSAO\|(.+)$') { $qgisEmbarcadoVersao = $Matches[1].Trim() }
        if ($l -match '^TOTAL\|(\d+)\|') { $manifestoTotal = [int]$Matches[1] }
    }
}
if ($arvoreExiste) {
    $arvoreArquivos = @(Get-ChildItem -LiteralPath $arvoreQgis -Recurse -File -Force -ErrorAction SilentlyContinue).Count
}
$arvoreNoPiso = ($manifestoTotal -gt 0 -and $arvoreArquivos -ge $manifestoTotal)

# --- QGIS DE SISTEMA (se houver) ---------------------------------------------
# Depois da via A1 isto deixou de ser requisito e passou a ser CONTEXTO: o
# produto nao procura QGIS na maquina. Na rodada M2 do checklist, um QGIS de
# sistema TEM de estar aqui, e o passo 19 prova que o produto nao o usa.

# ATENCAO: o qgis-ltr-bin.exe NAO tem resource de versao (ProductVersion e
# FileVersion vem VAZIOS - verificado no 3.44.9). Por isso a versao sai do NOME
# DA PASTA, que e como o instalador oficial do QGIS a registra. A chave de
# desinstalacao serve de confirmacao.
$qgisInstalacoes = @()

function New-QgisInfo([string]$Pasta, [string]$Exe, [string]$VersaoPasta) {
    return [PSCustomObject]@{
        Pasta  = $Pasta
        Exe    = $Exe
        Versao = $VersaoPasta
        LTR    = (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $Exe) 'qgis-ltr-bin.exe'))
    }
}

$raizes = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
foreach ($raiz in $raizes) {
    $dirs = Get-Safe { Get-ChildItem -LiteralPath $raiz -Filter 'QGIS *' -Directory -ErrorAction SilentlyContinue } @()
    foreach ($d in $dirs) {
        $exe = Join-Path $d.FullName 'bin\qgis-ltr-bin.exe'
        if (-not (Test-Path -LiteralPath $exe)) { $exe = Join-Path $d.FullName 'bin\qgis-bin.exe' }
        if (-not (Test-Path -LiteralPath $exe)) { continue }
        # "QGIS 3.44.9" -> "3.44.9"
        $ver = $d.Name -replace '^QGIS\s*', ''
        if (-not $ver) { $ver = $d.Name }
        $qgisInstalacoes += (New-QgisInfo $d.FullName $exe $ver)
    }
}

foreach ($exe in @('C:\OSGeo4W\bin\qgis-ltr-bin.exe', 'C:\OSGeo4W\bin\qgis-bin.exe')) {
    if (Test-Path -LiteralPath $exe) {
        $qgisInstalacoes += (New-QgisInfo 'C:\OSGeo4W' $exe 'OSGeo4W (versao na pasta apps\qgis-ltr)')
        break
    }
}

# Confirmacao independente pela chave de desinstalacao do QGIS oficial.
$qgisRegistro = @()
foreach ($padrao in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
    $achados = Get-Safe {
        Get-ItemProperty -Path $padrao -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like 'QGIS*' }
    } @()
    foreach ($a in $achados) { $qgisRegistro += "$($a.DisplayName)" }
}
$qgisRegistro = @($qgisRegistro | Sort-Object -Unique)

# --- IMAN Terra instalado ----------------------------------------------------
# Instalacao sem elevar cai em HKCU; com elevacao, em HKLM. Procura nos dois.

$chavesUninstall = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$instalacao = $null
foreach ($padrao in $chavesUninstall) {
    $achado = Get-Safe {
        Get-ItemProperty -Path $padrao -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like 'IMAN Terra*' } |
            Select-Object -First 1
    } $null
    if ($achado) { $instalacao = $achado; break }
}

$imanNome    = 'NAO INSTALADO'
$imanVersao  = '-'
$imanPasta   = '-'
$imanEscopo  = '-'
if ($instalacao) {
    $imanNome   = $instalacao.DisplayName
    $imanVersao = Get-Safe { $instalacao.DisplayVersion } '-'
    $imanPasta  = Get-Safe { $instalacao.InstallLocation } '-'
    $imanEscopo = 'por usuario (HKCU, sem elevacao)'
    if ($instalacao.PSPath -like '*HKEY_LOCAL_MACHINE*') { $imanEscopo = 'por maquina (HKLM, elevado)' }
}

# --- perfis ------------------------------------------------------------------

$perfilUsuarioRaiz = Join-Path $env:APPDATA 'QGIS\QGIS3\profiles'
$perfilUsuarioExiste = Test-Path -LiteralPath $perfilUsuarioRaiz
$isoladoExiste = Test-Path -LiteralPath $PerfilIsolado
$isoladoArquivos = 0
if ($isoladoExiste) {
    $isoladoArquivos = @(Get-ChildItem -LiteralPath $PerfilIsolado -Recurse -File -Force -ErrorAction SilentlyContinue).Count
}

# Base do merge de 3 vias (DB-26). Sem ela, o perfil nunca passou por uma
# reconciliacao que terminou, e a proxima abertura refaz o plano inteiro.
$baseArq = Join-Path $PerfilIsolado '.iman-terra\base.json'
$baseExiste = Test-Path -LiteralPath $baseArq
$baseDigest = '-'
if ($baseExiste) {
    $baseDigest = Get-Safe {
        (Get-Content -LiteralPath $baseArq -Raw -Encoding UTF8 | ConvertFrom-Json).template_digest
    } 'ILEGIVEL'
}

# --- console -----------------------------------------------------------------

Write-Host "  Windows        : $winCaption"
Write-Host "  Versao         : $winVersao  ($winArch, $winIdioma)"
Write-Host "  Sessao admin   : $ehAdmin"
Write-Host "  Resolucao      : $resolucao"
Write-Host "  Escala         : $escala"
Write-Host "  PowerShell     : $($PSVersionTable.PSVersion)"
Write-Host ""
Write-Host "  PROCEDENCIA (de que build e este produto instalado)" -ForegroundColor White
if ($buildId.Count -eq 0) {
    Write-Host "  BUILD_ID.txt   : AUSENTE em $Produto" -ForegroundColor Yellow
    Write-Host "                   Sem ele a rodada nao sabe dizer o que testou." -ForegroundColor Yellow
} else {
    Write-Host "  Produto        : $(BId 'produto')  $(BId 'versao')"
    Write-Host "  Commit         : $(BId 'commit')"
    Write-Host "  Commit (curto) : $(BId 'commit_curto')    prefixo coerente: $commitCoerente"
    Write-Host "  Branch         : $(BId 'branch')"
    $canon = BId 'build_canonico'
    if ("$canon" -eq 'sim') {
        Write-Host "  Build canonico : $canon" -ForegroundColor Green
    } else {
        Write-Host "  Build canonico : $canon  (rodada vale como ensaio, nao como evidencia de release)" -ForegroundColor Yellow
    }
    Write-Host "  Compilado em   : $(BId 'compilado_em')"
}
Write-Host ""
Write-Host "  QGIS EMBARCADO (via A1 - ele vive DENTRO do produto)" -ForegroundColor White
Write-Host "  Versao         : $qgisEmbarcadoVersao   (manifesto)   BUILD_ID diz: $(BId 'qgis_embarcado')"
Write-Host "  Arvore         : $arvoreQgis"
if ($arvoreExiste) {
    $marcaPiso = 'ABAIXO DO PISO'
    if ($arvoreNoPiso) { $marcaPiso = 'ok (piso, nao igualdade)' }
    Write-Host "  Arquivos       : $arvoreArquivos  contra TOTAL $manifestoTotal do manifesto  -  $marcaPiso"
} else {
    Write-Host "  Arvore         : AUSENTE" -ForegroundColor Yellow
}
Write-Host "  Payload SHA256 : $(BId 'payload_sha256')"
Write-Host ""
Write-Host "  QGIS DE SISTEMA (contexto; o produto nao usa nenhum)" -ForegroundColor White
if ($qgisInstalacoes.Count -eq 0) {
    Write-Host "  QGIS           : NENHUM (esperado nas rodadas M1, M3 e M4)"
} else {
    foreach ($q in $qgisInstalacoes) {
        $marca = 'nao-LTR'
        if ($q.LTR) { $marca = 'LTR' }
        Write-Host "  QGIS           : $($q.Versao)  [$marca]  -  $($q.Pasta)"
    }
}
foreach ($r in $qgisRegistro) { Write-Host "  QGIS (registro): $r" -ForegroundColor DarkGray }
Write-Host ""
if ($instalacao) {
    Write-Host "  IMAN Terra     : $imanNome $imanVersao"
} else {
    Write-Host "  IMAN Terra     : NAO INSTALADO" -ForegroundColor Yellow
}
Write-Host "  Instalado em   : $imanPasta"
Write-Host "  Escopo         : $imanEscopo"
Write-Host "  Perfil isolado : $(if ($isoladoExiste) { "SIM ($isoladoArquivos arquivos)" } else { 'NAO' })"
Write-Host "  Base do 3-way  : $(if ($baseExiste) { "SIM  template_digest=$baseDigest" } else { 'AUSENTE (.iman-terra\base.json)' })"
Write-Host ""

# --- esqueleto do RESULT.md --------------------------------------------------

if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}
$OutFile = Join-Path $OutDir 'RESULT-esqueleto.md'

$linhasQgis = @()
if ($qgisInstalacoes.Count -eq 0) {
    $linhasQgis += '- nenhum QGIS de sistema nesta maquina'
} else {
    foreach ($q in $qgisInstalacoes) {
        $marca = 'nao-LTR'
        if ($q.LTR) { $marca = 'LTR' }
        $linhasQgis += "- ``$($q.Versao)`` ($marca) em ``$($q.Pasta)``"
    }
}
foreach ($r in $qgisRegistro) { $linhasQgis += "- confirmado no registro: ``$r``" }
$linhasQgis += ''
$linhasQgis += '> A versao vem do NOME DA PASTA: o `qgis-ltr-bin.exe` nao carrega resource de'
$linhasQgis += '> versao (ProductVersion/FileVersion vazios). Confirme em Ajuda > Sobre.'

$md = @()
$md += '<!-- Gerado por tools/bl7/collect-evidence.ps1. Cole estes dados no'
$md += '     docs/verify/bl7-clean-vm/RESULT.md e preencha o resto na mao. -->'
$md += ''
$md += '## Ambiente da VM'
$md += ''
$md += '| Campo | Valor |'
$md += '|---|---|'
$md += "| Windows | $winCaption |"
$md += "| Versao/build | $winVersao |"
$md += "| Arquitetura / idioma | $winArch / $winIdioma |"
$md += "| Sessao de administrador | $ehAdmin |"
$md += "| Resolucao | $resolucao |"
$md += "| Escala de exibicao | $escala |"
$md += "| PowerShell | $($PSVersionTable.PSVersion) |"
$md += "| Coletado em | $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')) |"
$md += ''
$md += '### Procedencia do produto INSTALADO (DB-24)'
$md += ''
$md += '| Campo | Valor |'
$md += '|---|---|'
$md += "| Arquivo de origem | ``$buildIdArq`` |"
$md += "| Produto | $(BId 'produto') |"
$md += "| Versao | $(BId 'versao') |"
$md += "| Commit | ``$(BId 'commit')`` |"
$md += "| Commit (curto) | ``$(BId 'commit_curto')`` |"
$md += "| Commit curto e prefixo do completo | $commitCoerente |"
$md += "| Branch | $(BId 'branch') |"
$md += "| **Build canonico** | **$(BId 'build_canonico')** |"
$md += "| Data do commit | $(BId 'data_do_commit') |"
$md += "| Compilado em | $(BId 'compilado_em') |"
$md += ''
$md += '> Confronte o `commit_curto` e o `build_canonico` com o `installer/canonico/VIGENTE.txt`'
$md += '> da `develop`. `build_canonico=nao` significa build de branch: legitimo para ensaiar,'
$md += '> **invalido como evidencia de release**, e o veredito final tem de dizer isso.'
$md += ''
$md += '### QGIS EMBARCADO (via A1 - vive dentro do produto)'
$md += ''
$md += '| Campo | Valor |'
$md += '|---|---|'
$md += "| Versao (manifesto) | $qgisEmbarcadoVersao |"
$md += "| Versao (BUILD_ID) | $(BId 'qgis_embarcado') |"
$md += "| Arvore | ``$arvoreQgis`` |"
$md += "| Arquivos na arvore | $arvoreArquivos |"
$md += "| TOTAL do manifesto | $manifestoTotal |"
$md += "| Contagem no piso (>= TOTAL) | $arvoreNoPiso |"
$md += "| Payload SHA-256 de origem | ``$(BId 'payload_sha256')`` |"
$md += ''
$md += '> A contagem e PISO, nao igualdade: o Python do proprio produto grava bytecode em'
$md += '> `__pycache__` ao importar. Truncar sempre DIMINUI a contagem; crescer nunca e truncar.'
$md += ''
$md += '### QGIS de sistema presente (contexto, nao requisito)'
$md += ''
$md += $linhasQgis
$md += ''
$md += '### IMAN Terra instalado'
$md += ''
$md += '| Campo | Valor |'
$md += '|---|---|'
$md += "| Produto (ARP) | $imanNome |"
$md += "| Versao (ARP) | $imanVersao |"
$md += "| Pasta de instalacao | $imanPasta |"
$md += "| Escopo | $imanEscopo |"
$md += "| Perfil do usuario existe | $perfilUsuarioExiste ($perfilUsuarioRaiz) |"
$md += "| Perfil isolado existe | $isoladoExiste ($isoladoArquivos arquivos) |"
$md += "| Perfil isolado | $PerfilIsolado |"
$md += "| Base do 3-way (base.json) | $baseExiste |"
$md += "| template_digest | ``$baseDigest`` |"
$md += ''
$md += '> Escopo esperado desde a fatia #019: **por usuario (HKCU, sem elevacao)**. Escopo'
$md += '> `por maquina (HKLM, elevado)` significa que `PrivilegesRequired` voltou a `admin`,'
$md += '> e isso arrasta `{app}` para area de sistema - e achado, nao detalhe.'
$md += ''
$md += '### A preencher na mao'
$md += ''
$md += '- SHA-256 do .exe baixado (`Get-FileHash .\<arquivo>.exe -Algorithm SHA256`)'
$md += '- SHA-256 e tamanho conforme o BUILD_INFO.txt, e se batem'
$md += '- Texto LITERAL exibido pelo SmartScreen'
$md += '- Quantos prompts de UAC apareceram (esperado: 0)'
$md += '- Tabela PASS/FAIL por BL-1..BL-7'
$md += ''

Set-Content -LiteralPath $OutFile -Value $md -Encoding UTF8

Write-Host "  Esqueleto do RESULT: $OutFile" -ForegroundColor Green
Write-Host ""
