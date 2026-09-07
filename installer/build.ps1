<#
=============================================================================
 IMAN Terra - build reprodutivel do instalador (Inno Setup)

 Compila installer\iman-terra.iss e emite installer\dist\BUILD_INFO.txt
 amarrando  artefato <-> commit <-> versao <-> SHA-256.

 POR QUE ESTE SCRIPT EXISTE
 --------------------------
 O BL-7 ("verdade na VM limpa") so vale se o .exe testado for rastreavel ate um
 commit. Um build feito de uma arvore suja ou da branch errada produz um
 Frankenstein indistinguivel de um build legitimo. Este script torna esse erro
 IMPOSSIVEL, nao improvavel: ele RECUSA compilar nessas condicoes.

 USO
 ---
   .\installer\build.ps1                                   # exige branch develop
   .\installer\build.ps1 -ExpectedBranch feat/xxx          # build NAO-CANONICO
   .\installer\build.ps1 -IsccPath "C:\...\ISCC.exe"       # ISCC explicito

 CODIGOS DE SAIDA
 ----------------
   0  sucesso
   2  ambiente (fora de repo git, git ausente, ISCC nao encontrado, .iss ausente)
   3  guarda de integridade (arvore suja / branch errada / versao divergente)
   4  falha do compilador Inno Setup
   5  payload do QGIS (ausente, download falhou ou SHA-256 nao confere)
   6  guarda DB-18 (o launcher nao passa no teste de deteccao do QGIS)

 REQUISITOS: PowerShell 5.1, git no PATH, Inno Setup 7 ou 6 (D-IMAN-030).
 (Este script roda na BANCADA do dev, nao na VM limpa. Os helpers que vao para a
 VM estao em tools\bl7\ e nao dependem de git/Python.)

 ASCII-only de proposito: o PowerShell 5.1 le arquivo .ps1 sem BOM como ANSI, e
 acentos em UTF-8 sem BOM viram lixo.
=============================================================================
#>
[CmdletBinding()]
param(
    # Branch exigida para compilar. O default 'develop' e a branch canonica de
    # integracao; qualquer outra gera um artefato marcado como NAO-CANONICO.
    [string]$ExpectedBranch = 'develop',

    # Caminho explicito do ISCC.exe (opcional; por padrao e localizado sozinho).
    [string]$IsccPath,

    # Onde procurar o MSI do QGIS ja baixado, antes de tentar a rede. Util em
    # bancada sem internet e para nao rebaixar 541 MB a cada build.
    # Tambem lido de %IMAN_QGIS_PAYLOAD_CACHE%.
    [string]$PayloadCache = $env:IMAN_QGIS_PAYLOAD_CACHE,

    # Nao tentar baixar: se o payload nao estiver em cache/estagiado, falhar.
    [switch]$SemRede
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

# --- infra de mensagens ------------------------------------------------------

function Write-Step([string]$Text) { Write-Host "==> $Text" -ForegroundColor Cyan }
function Write-Ok  ([string]$Text) { Write-Host "    OK  $Text" -ForegroundColor Green }

function Fail([int]$Code, [string]$Title, [string[]]$Detail) {
    Write-Host ""
    Write-Host "  BUILD RECUSADO: $Title" -ForegroundColor Red
    Write-Host ""
    foreach ($line in $Detail) { Write-Host "    $line" -ForegroundColor Yellow }
    Write-Host ""
    exit $Code
}

# Roda um executavel nativo e devolve as linhas de stdout. stderr vai para o
# vazio de proposito: o git emite avisos de CRLF que nao sao erro e poluiriam a
# leitura das guardas.
function Invoke-Native([string]$Exe, [string[]]$Arguments) {
    $out = & $Exe @Arguments 2>$null
    return @{ ExitCode = $LASTEXITCODE; Lines = @($out) }
}

# --- localizacao do repo -----------------------------------------------------

$InstallerDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot     = Split-Path -Parent $InstallerDir
$IssPath      = Join-Path $InstallerDir 'iman-terra.iss'
$DistDir      = Join-Path $InstallerDir 'dist'
$BuildInfo    = Join-Path $DistDir 'BUILD_INFO.txt'

Write-Host ""
Write-Host "  IMAN Terra - build do instalador" -ForegroundColor White
Write-Host "  repo: $RepoRoot"
Write-Host ""

if (-not (Test-Path -LiteralPath $IssPath)) {
    Fail 2 "script do Inno Setup nao encontrado" @(
        "Esperado em: $IssPath",
        "Rode este script de dentro do repositorio da distro."
    )
}

# --- guarda 1: e um repositorio git? ----------------------------------------

Write-Step "Verificando o repositorio"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fail 2 "git nao encontrado no PATH" @(
        "O build carimba o commit no BUILD_INFO.txt; sem git nao ha rastreabilidade."
    )
}

Push-Location $RepoRoot
try {
    $inside = Invoke-Native 'git' @('rev-parse', '--is-inside-work-tree')
    if ($inside.ExitCode -ne 0) {
        Fail 2 "diretorio nao e um repositorio git" @("Raiz avaliada: $RepoRoot")
    }

    # --- guarda 2: branch correta -------------------------------------------

    $branchResult = Invoke-Native 'git' @('rev-parse', '--abbrev-ref', 'HEAD')
    $Branch = ($branchResult.Lines | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($Branch)) {
        Fail 2 "nao foi possivel determinar a branch atual" @()
    }
    $Branch = $Branch.Trim()

    if ($Branch -ne $ExpectedBranch) {
        Fail 3 "branch errada" @(
            "Branch atual   : $Branch",
            "Branch exigida : $ExpectedBranch",
            "",
            "Compilar da branch errada produz um artefato que NAO corresponde ao que",
            "sera integrado - e a evidencia do BL-7 vira ficcao.",
            "",
            "Saidas possiveis:",
            "  git checkout $ExpectedBranch     (build canonico)",
            "  .\installer\build.ps1 -ExpectedBranch $Branch",
            "                                   (build deliberado e NAO-CANONICO;",
            "                                    o BUILD_INFO.txt registra isso)"
        )
    }

    # --- guarda 3: arvore limpa ---------------------------------------------
    #
    # BUILD_INFO.txt e a UNICA excecao: ele e a saida deste proprio script e e
    # versionado. Sem esta excecao, o build 2 sempre falharia por causa do build
    # 1 - a guarda se auto-sabotaria.

    # --untracked-files=all e obrigatorio: sem ele o git COLAPSA um diretorio
    # nao-rastreado numa unica linha ("installer/dist/"), a excecao abaixo nunca
    # casa com o caminho do arquivo, e o primeiro build passaria a bloquear o
    # segundo para sempre.
    $statusResult = Invoke-Native 'git' @('status', '--porcelain', '--untracked-files=all')
    if ($statusResult.ExitCode -ne 0) {
        Fail 2 "git status falhou" @()
    }

    $dirty = @()
    foreach ($line in $statusResult.Lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        # Formato porcelain v1: XY<espaco>caminho  (caminho pode vir entre aspas)
        $path = $line.Substring(2).Trim().Trim('"')
        # Renomeio vem como "origem -> destino"; interessa o destino.
        if ($path -match '\s->\s(.+)$') { $path = $Matches[1].Trim().Trim('"') }
        if ($path -eq 'installer/dist/BUILD_INFO.txt') { continue }
        $dirty += $line
    }

    if ($dirty.Count -gt 0) {
        $shown = $dirty | Select-Object -First 20
        $extra = @()
        if ($dirty.Count -gt 20) { $extra = @("... e mais $($dirty.Count - 20) arquivo(s).") }
        # Parenteses obrigatorios: numa chamada de comando o '+' viraria mais um
        # argumento literal em vez de concatenar os arrays.
        Fail 3 "arvore de trabalho suja" (
            @("Ha $($dirty.Count) alteracao(oes) nao commitada(s):", "") +
            $shown + $extra +
            @(
                "",
                "Um instalador compilado de arvore suja nao corresponde a NENHUM commit:",
                "nao ha como saber depois o que exatamente foi testado na VM.",
                "",
                "Commite, descarte ou guarde (git stash -u) antes de compilar."
            )
        )
    }

    Write-Ok "branch '$Branch', arvore limpa"

    # --- metadados do commit -------------------------------------------------

    $CommitFull  = (Invoke-Native 'git' @('rev-parse', 'HEAD')).Lines           | Select-Object -First 1
    $CommitShort = (Invoke-Native 'git' @('rev-parse', '--short', 'HEAD')).Lines | Select-Object -First 1
    $CommitDate  = (Invoke-Native 'git' @('log', '-1', '--format=%cI')).Lines    | Select-Object -First 1
}
finally {
    Pop-Location
}

# --- versao e baseline: fonte unica e o proprio .iss -------------------------

Write-Step "Lendo a fonte unica de versao (iman-terra.iss)"

$issText = Get-Content -LiteralPath $IssPath -Raw

function Get-IssDefine([string]$Text, [string]$Name) {
    $rx = [regex]("(?m)^\s*#define\s+" + [regex]::Escape($Name) + "\s+`"([^`"]+)`"")
    $m = $rx.Match($Text)
    if (-not $m.Success) { return $null }
    return $m.Groups[1].Value
}

$ProductVersion = Get-IssDefine $issText 'ProductVersion'
$QgisBaseline   = Get-IssDefine $issText 'QgisBaselineVersion'

if (-not $ProductVersion) {
    Fail 2 "#define ProductVersion nao encontrado no .iss" @("Arquivo: $IssPath")
}
if (-not $QgisBaseline) {
    Fail 2 "#define QgisBaselineVersion nao encontrado no .iss" @("Arquivo: $IssPath")
}

$baseNameMatch = [regex]::Match($issText, '(?m)^\s*OutputBaseFilename=(.+?)\s*$')
if (-not $baseNameMatch.Success) {
    Fail 2 "OutputBaseFilename nao encontrado no .iss" @("Arquivo: $IssPath")
}
$OutputBaseName = $baseNameMatch.Groups[1].Value.Replace('{#ProductVersion}', $ProductVersion)
$ArtifactName   = "$OutputBaseName.exe"
$ArtifactPath   = Join-Path $DistDir $ArtifactName

Write-Ok "ProductVersion $ProductVersion / QGIS embarcado $QgisBaseline"

# --- guarda 4: o launcher espelha a mesma versao de QGIS? --------------------
#
# D-IMAN-028/DB-14: o launcher precisa preferir o caminho EXATO do payload
# ("C:\Program Files\QGIS <versao>"). Ele guarda essa versao numa constante
# propria, porque um .bat nao le o .iss. Se as duas divergirem, o launcher para
# de reconhecer o proprio payload e cai no fallback por curinga - que foi
# EXATAMENTE o defeito medido na fatia #010 (abria a versao errada). O erro
# seria silencioso: tudo instala, tudo abre, so que o QGIS errado.
# Esta guarda existe para tornar essa divergencia impossivel, nao improvavel.

Write-Step "Conferindo a versao do QGIS no launcher"

$LauncherPath = Join-Path $RepoRoot 'app\launcher\IMAN-Terra.bat'
if (-not (Test-Path -LiteralPath $LauncherPath)) {
    Fail 2 "launcher nao encontrado" @("Esperado em: $LauncherPath")
}
$launcherText = Get-Content -LiteralPath $LauncherPath -Raw
$lm = [regex]::Match($launcherText, '(?m)^\s*set\s+"QGIS_VERSION=([^"]+)"')
if (-not $lm.Success) {
    Fail 3 "QGIS_VERSION nao encontrada no launcher" @(
        "Arquivo: $LauncherPath",
        "Esperada uma linha:  set `"QGIS_VERSION=<versao>`"",
        "Ela espelha o #define QgisBaselineVersion do .iss (D-IMAN-028/DB-14)."
    )
}
$LauncherQgis = $lm.Groups[1].Value.Trim()
if ($LauncherQgis -ne $QgisBaseline) {
    Fail 3 "versao do QGIS divergente entre o .iss e o launcher" @(
        "installer\iman-terra.iss  #define QgisBaselineVersion : $QgisBaseline",
        "app\launcher\IMAN-Terra.bat  set QGIS_VERSION         : $LauncherQgis",
        "",
        "O instalador embarcaria uma versao e o launcher procuraria outra.",
        "O produto ABRIRIA um QGIS diferente do que foi testado - em silencio.",
        "",
        "Corrija os dois para o mesmo valor e recompile."
    )
}
Write-Ok "launcher e .iss concordam em QGIS $QgisBaseline"

# ---------------------------------------------------------------------------
# GUARDA DE VERSAO DO PRODUTO (D9, fatia #018)
#
# O sponsor instalou o 0.3.0 e o produto disse na cara dele que era 0.1.0: o
# .iss dizia uma coisa e o brand.py/metadata.txt diziam outra. A fonte unica e
# o #define ProductVersion do .iss, que este script ja leu. As outras duas
# DERIVAM dela - e derivar so vale se divergir doer.
#
# Conserto que depende de alguem lembrar nao e conserto: divergencia aqui e
# Fail 3, no mesmo espirito da guarda de QGIS_VERSION acima.
# ---------------------------------------------------------------------------
Write-Step "conferindo a versao do produto nas tres fontes (D9)"

$BrandPath = Join-Path $RepoRoot 'app\profile-template\iman-distro\python\plugins\iman_brand\brand.py'
$MetaPath  = Join-Path $RepoRoot 'app\profile-template\iman-distro\python\plugins\iman_brand\metadata.txt'

foreach ($p in @($BrandPath, $MetaPath)) {
    if (-not (Test-Path -LiteralPath $p)) {
        Fail 2 "arquivo de versao do produto nao encontrado" @("Esperado em: $p")
    }
}

$bm = [regex]::Match((Get-Content -LiteralPath $BrandPath -Raw),
                     '(?m)^\s*VERSION\s*=\s*"([^"]+)"')
if (-not $bm.Success) {
    Fail 3 "VERSION nao encontrada em brand.py" @(
        "Arquivo: $BrandPath",
        "Esperada uma linha:  VERSION = `"<versao>`"",
        "Ela espelha o #define ProductVersion do .iss (D-IMAN-033/D9)."
    )
}
$BrandVersion = $bm.Groups[1].Value.Trim()

$mm = [regex]::Match((Get-Content -LiteralPath $MetaPath -Raw),
                     '(?m)^\s*version\s*=\s*(.+?)\s*$')
if (-not $mm.Success) {
    Fail 3 "version nao encontrada em metadata.txt" @(
        "Arquivo: $MetaPath",
        "Esperada uma linha:  version=<versao>"
    )
}
$MetaVersion = $mm.Groups[1].Value.Trim()

if (($BrandVersion -ne $ProductVersion) -or ($MetaVersion -ne $ProductVersion)) {
    Fail 3 "versao do produto divergente entre as tres fontes" @(
        "installer\iman-terra.iss   #define ProductVersion : $ProductVersion   (FONTE UNICA)",
        "...\iman_brand\brand.py      VERSION                : $BrandVersion",
        "...\iman_brand\metadata.txt  version                : $MetaVersion",
        "",
        "O instalador entregaria uma versao e o produto exibiria outra - na",
        "home, no Sobre e no banner. Foi o defeito D9 do 0.3.0: instalado",
        "0.3.0, exibido 0.1.0.",
        "",
        "A fonte unica e o .iss. Corrija brand.py e metadata.txt para $ProductVersion."
    )
}
Write-Ok "versao do produto $ProductVersion concorda nas tres fontes"

# --- guarda 5: o launcher PASSA no teste de deteccao? -----------------------
#
# D-IMAN-028/DB-18: a guarda 4 confere a versao ESCRITA no launcher; esta roda
# o launcher DE VERDADE contra raizes sinteticas e confere QUAL QGIS ele
# escolhe. As duas protegem o mesmo invariante ("o produto abre o QGIS que
# embarcamos"), e a diferenca importa: o .bat so se comporta como corrigido se
# chegar ao disco com CRLF. O MESMO arquivo com finais de linha LF cai de
# 5 de 5 para 1 de 5 casos (medido em 2026-08-31, quando o teste tinha 5
# casos; hoje tem 6 - o placar quem da e o teste) e volta a abrir a versao
# errada - sem um ruido. O .gitattributes da raiz impede o LF no checkout;
# esta guarda e a rede que prova, a cada build, que ele impediu.
#
# Bloqueante de proposito, nao aviso: um aviso e exatamente o que deixaria a
# reversao silenciosa entrar nos 544 MB. Roda ANTES de estagiar o payload para
# falhar barato, sem baixar 541 MB.

Write-Step "Rodando o teste de deteccao do QGIS pelo launcher"

$DetectTest = Join-Path $RepoRoot 'tools\test-launcher-detection.ps1'
if (-not (Test-Path -LiteralPath $DetectTest)) {
    Fail 2 "teste de deteccao do launcher nao encontrado" @(
        "Esperado em: $DetectTest",
        "Ele e a guarda do D-IMAN-028/DB-18; sem ele o build nao tem como saber",
        "se o launcher ainda abre o QGIS que o instalador embarca."
    )
}

# Processo filho de proposito: o teste termina com 'exit 0/1' e o codigo dele e
# a evidencia. Rodar em processo separado garante o codigo intacto e mantem a
# saida (o placar caso a caso) visivel no log do build.
$PsExe = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path -LiteralPath $PsExe)) { $PsExe = 'powershell.exe' }

& $PsExe -NoProfile -ExecutionPolicy Bypass -File $DetectTest -VersaoPayload $QgisBaseline
$DetectExit = $LASTEXITCODE

if ($DetectExit -ne 0) {
    Fail 6 "o launcher NAO passa no teste de deteccao do QGIS" @(
        "Teste    : tools\test-launcher-detection.ps1   (exit $DetectExit)",
        "Launcher : $LauncherPath",
        "Placar   : o esperado e TODOS; veja os casos [FAIL] logo acima.",
        "",
        "D-IMAN-028/DB-18. CAUSA MAIS PROVAVEL: o .bat chegou ao disco com",
        "finais de linha LF em vez de CRLF. Sob LF este launcher cai para",
        "1 de 5 casos (medicao de 2026-08-31) e reabre o DB-14 - em silencio.",
        "",
        "Confira com uma linha (tem de imprimir True):",
        "  (Get-Content -Raw app\launcher\IMAN-Terra.bat).Contains([char]13)",
        "",
        "Se der False, este clone nao aplicou o .gitattributes da raiz",
        "(*.bat text eol=crlf) - ele esta ausente nesta ref ou foi ignorado.",
        "Traga a ref que o contem e restaure o CRLF apagando e re-extraindo:",
        "  Remove-Item app\launcher\IMAN-Terra.bat",
        "  git checkout -- app\launcher\IMAN-Terra.bat",
        "",
        "Se der True, o defeito NAO e de finais de linha: leia os casos [FAIL]."
    )
}

Write-Ok "launcher passa no teste de deteccao (placar completo acima)"

# --- payload do QGIS: estagiar e CONFERIR o SHA-256 -------------------------
#
# D-IMAN-028/DB-5: o MSI (~541 MB) nao entra no git. O build o estagia em
# installer\payload\ e confere o hash ANTES de compilar. Sem a conferencia, um
# download truncado viraria um instalador que falha so na maquina do usuario.

Write-Step "Estagiando o payload do QGIS $QgisBaseline"

# Hash oficial por versao. Um payload cuja versao nao esteja aqui e RECUSADO:
# "nao conheco o hash" nunca pode virar "entao pode passar".
# 3.44.9  conferido em 2026-07-31 contra o MSI baixado de download.qgis.org e
#         contra o pacote em cache da instalacao da bancada (mesmo ProductCode).
# 3.44.13 conferido em 2026-09-01 contra o arquivo de checksum OFICIAL
#         https://download.qgis.org/downloads/QGIS-OSGeo4W-3.44.13-1.sha256sum
#         (procedencia do proprio projeto QGIS, nao do arquivo baixado aqui) e
#         batendo com o MSI em disco. Baseline desde a fatia #013.
# Versoes antigas ficam: a tabela e um registro de procedencia, nao a escolha.
# Quem escolhe a versao embarcada e o #define QgisBaselineVersion do .iss.
$PayloadHashes = @{
    '3.44.9'  = '711D6DF99F450522A1E22755FCBFED65D5190C1E4C241793BC2F80FF1A2C24BA'
    '3.44.13' = '42E2F1A6047A827454BC991F8E8CAA069961B9CB4B877E1F5568A43D98844EB4'
}

if (-not $PayloadHashes.ContainsKey($QgisBaseline)) {
    Fail 5 "SHA-256 oficial desconhecido para o QGIS $QgisBaseline" @(
        "Versoes com hash conhecido: " + (($PayloadHashes.Keys | Sort-Object) -join ', '),
        "",
        "Trocar a versao embarcada e decisao de PRODUTO, nao do build. Para adotar",
        "uma nova versao: baixe o MSI oficial, confira a procedencia, registre o",
        "SHA-256 em `$PayloadHashes e ATUALIZE JUNTO:",
        "  - #define QgisBaselineVersion  (installer\iman-terra.iss)",
        "  - QgisProductCode             (bloco [Code] do .iss - e por VERSAO)",
        "  - set QGIS_VERSION            (app\launcher\IMAN-Terra.bat)"
    )
}

$PayloadExpected = $PayloadHashes[$QgisBaseline]
$PayloadName     = "QGIS-OSGeo4W-$QgisBaseline-1.msi"
$PayloadDir      = Join-Path $InstallerDir 'payload'
$PayloadPath     = Join-Path $PayloadDir $PayloadName
$PayloadUrl      = "https://download.qgis.org/downloads/$PayloadName"

if (-not (Test-Path -LiteralPath $PayloadDir)) {
    New-Item -ItemType Directory -Path $PayloadDir -Force | Out-Null
}

function Test-PayloadHash([string]$Path, [string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    return ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -eq $Expected)
}

if (Test-PayloadHash $PayloadPath $PayloadExpected) {
    Write-Ok "payload ja estagiado e conferido"
} else {
    # Um arquivo estagiado com hash errado e pior que nenhum: seria a origem de
    # um instalador silenciosamente quebrado. Remove e refaz.
    if (Test-Path -LiteralPath $PayloadPath) {
        Write-Host "    payload estagiado com SHA-256 divergente - descartando" -ForegroundColor Yellow
        Remove-Item -LiteralPath $PayloadPath -Force
    }

    $origem = $null
    if ($PayloadCache) {
        $cand = if (Test-Path -LiteralPath $PayloadCache -PathType Container) {
            Join-Path $PayloadCache $PayloadName
        } else { $PayloadCache }
        if (Test-PayloadHash $cand $PayloadExpected) { $origem = $cand }
        elseif (Test-Path -LiteralPath $cand) {
            Write-Host "    cache encontrado mas com SHA-256 divergente: $cand" -ForegroundColor Yellow
        }
    }

    if ($origem) {
        Write-Host "    copiando do cache: $origem"
        Copy-Item -LiteralPath $origem -Destination $PayloadPath -Force
    } elseif ($SemRede) {
        Fail 5 "payload do QGIS ausente e -SemRede foi pedido" @(
            "Esperado: $PayloadPath",
            "Cache consultado: " + $(if ($PayloadCache) { $PayloadCache } else { '<nenhum>' }),
            "",
            "Baixe manualmente de:  $PayloadUrl",
            "e coloque em:          $PayloadDir"
        )
    } else {
        Write-Host "    baixando $PayloadUrl"
        Write-Host "    (~541 MB; use -PayloadCache <pasta> para reaproveitar entre builds)"
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $wc = New-Object Net.WebClient
            try { $wc.DownloadFile($PayloadUrl, $PayloadPath) } finally { $wc.Dispose() }
        } catch {
            Fail 5 "falha ao baixar o payload do QGIS" @(
                "URL: $PayloadUrl",
                "Erro: " + $_.Exception.Message,
                "",
                "Baixe manualmente e rode de novo com:",
                "  .\installer\build.ps1 -PayloadCache '<pasta com o .msi>'"
            )
        }
    }

    if (-not (Test-PayloadHash $PayloadPath $PayloadExpected)) {
        $obtido = if (Test-Path -LiteralPath $PayloadPath) {
            (Get-FileHash -LiteralPath $PayloadPath -Algorithm SHA256).Hash
        } else { '<arquivo ausente>' }
        Fail 5 "SHA-256 do payload NAO confere" @(
            "Arquivo  : $PayloadPath",
            "Esperado : $PayloadExpected",
            "Obtido   : $obtido",
            "",
            "Download truncado, arquivo trocado ou versao diferente do declarado.",
            "Compilar assim produziria um instalador que so falha na maquina do usuario."
        )
    }
    Write-Ok "payload estagiado e SHA-256 conferido"
}

$PayloadItem = Get-Item -LiteralPath $PayloadPath
$PayloadSha  = (Get-FileHash -LiteralPath $PayloadPath -Algorithm SHA256).Hash
Write-Ok ("$PayloadName ({0} MB)" -f [math]::Round($PayloadItem.Length / 1MB, 2))

# O ProductCode que o .iss usa para decidir "pular ou instalar" (M2a) e por
# VERSAO. Ele vai para o BUILD_INFO porque, sem ele, a evidencia da VM nao
# permite reconstruir POR QUE o instalador pulou (ou nao pulou) o QGIS.
$pcMatch = [regex]::Match($issText, "(?m)^\s*QgisProductCode\s*=\s*'([^']+)'")
if (-not $pcMatch.Success) {
    Fail 2 "QgisProductCode nao encontrado no bloco [Code] do .iss" @(
        "Arquivo: $IssPath",
        "Esperada uma linha:  QgisProductCode = '{GUID}';",
        "Ela e especifica da VERSAO embarcada (D-IMAN-028/DB-16)."
    )
}
$QgisProductCode = $pcMatch.Groups[1].Value

# --- localizacao do ISCC -----------------------------------------------------

Write-Step "Localizando o compilador do Inno Setup"

# D-IMAN-030: majores do Inno Setup aceitas, EM ORDEM DE PRECEDENCIA.
# A ordem e ARBITRADA (o 7 vence o 6), nao acidental: as duas majores convivem
# lado a lado na mesma maquina, e deixar vencer "a que estiver primeiro no array
# de caminhos" faria o compilador do release depender de ONDE cada uma foi
# instalada - um build reprodutivel nao pode depender disso.
$IsccMajoresAceitas = @(7, 6)

function Find-Iscc([string]$Explicit) {
    if ($Explicit) {
        if (Test-Path -LiteralPath $Explicit) { return (Resolve-Path -LiteralPath $Explicit).Path }
        return $null
    }
    if ($env:ISCC -and (Test-Path -LiteralPath $env:ISCC)) { return $env:ISCC }

    # Ordem deliberada dos diretorios: winget instala em LOCALAPPDATA\Programs (a
    # memoria da fatia 1 presumiu Program Files e errou - por isso a busca e
    # explicita); o instalador oficial do 7 desta bancada caiu em Program Files.
    #
    # A MAJOR e o laco de FORA, de proposito: um Inno 7 em Program Files tem de
    # vencer um Inno 6 em LOCALAPPDATA, e nao o contrario.
    $bases = @(
        (Join-Path $env:LOCALAPPDATA 'Programs'),
        ${env:ProgramFiles(x86)},
        $env:ProgramFiles
    )

    foreach ($major in $IsccMajoresAceitas) {
        foreach ($b in $bases) {
            if (-not $b) { continue }
            $c = Join-Path $b "Inno Setup $major\ISCC.exe"
            if (Test-Path -LiteralPath $c) { return $c }
        }

        # Recurso seguinte: chave de desinstalacao do proprio Inno Setup.
        $keys = @(
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup ${major}_is1",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup ${major}_is1",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup ${major}_is1"
        )
        foreach ($k in $keys) {
            try {
                $loc = (Get-ItemProperty -Path $k -Name InstallLocation -ErrorAction Stop).InstallLocation
                if ($loc) {
                    $exe = Join-Path $loc 'ISCC.exe'
                    if (Test-Path -LiteralPath $exe) { return $exe }
                }
            } catch { }
        }
    }

    # Ultimo recurso: o PATH. Aqui a major nao e escolhida por nos - vem quem
    # estiver no PATH, e a validacao de versao logo abaixo decide se serve.
    $cmd = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

# A VERSAO do compilador, medida NO COMPILADOR QUE SERA USADO.
#
# D-IMAN-030. MEDIDO em 2026-09-01 nesta bancada (Inno Setup 7.1.0) porque as
# duas fontes obvias NAO servem:
#   (Get-Item ISCC.exe).VersionInfo -> FileVersion e ProductVersion sao
#                                      '0.0.0.0'. O binario do ISCC 7 nao
#                                      carrega version info util.
#   banner do ISCC sem argumentos   -> 'Inno Setup 7 Command-Line Compiler'.
#                                      So a MAJOR; nem o '.1.0'.
# O que serve e a linha que o proprio ISCC imprime ao compilar SEM /Q:
#   'Compiler engine version: Inno Setup 7.1.0'
# (o /Q da compilacao a suprime - por isso a sonda e uma chamada separada).
#
# A sonda manda compilar um .iss descartavel que aborta ainda no
# preprocessador: a linha sai antes do erro, e a chamada inteira custou ~60 ms
# na medicao.
function Get-IsccVersao([string]$Exe) {
    $probeIss = Join-Path $env:TEMP ("iman-iscc-probe-" + [Guid]::NewGuid().ToString('N') + ".iss")
    $probeOut = "$probeIss.out"
    # stderr num arquivo proprio: a sonda ABORTA de proposito, e o "Compile
    # aborted." dela no console de um build BEM-SUCEDIDO so assustaria quem le.
    $probeErr = "$probeIss.err"
    try {
        Set-Content -LiteralPath $probeIss -Value '#error iman-sonda-de-versao' -Encoding Ascii

        # Start-Process com TIMEOUT de proposito: -IsccPath e $env:ISCC apontam
        # para um executavel ARBITRARIO, e um build nunca pode ficar pendurado
        # nele esperando um processo que nao vai terminar.
        $p = Start-Process -FilePath $Exe -ArgumentList "`"$probeIss`"" `
                           -RedirectStandardOutput $probeOut `
                           -RedirectStandardError $probeErr -NoNewWindow -PassThru
        if (-not $p.WaitForExit(15000)) {
            try { $p.Kill() } catch { }
            return $null
        }
        if (-not (Test-Path -LiteralPath $probeOut)) { return $null }

        $texto = Get-Content -LiteralPath $probeOut -Raw
        if (-not $texto) { return $null }
        $m = [regex]::Match($texto, 'Compiler engine version:\s*Inno Setup\s+([0-9]+(?:\.[0-9]+)*)')
        if ($m.Success) { return $m.Groups[1].Value }
        return $null
    } catch {
        return $null
    } finally {
        Remove-Item -LiteralPath $probeIss -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $probeOut -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $probeErr -Force -ErrorAction SilentlyContinue
    }
}

$Iscc = Find-Iscc $IsccPath
if (-not $Iscc) {
    Fail 2 "ISCC.exe (Inno Setup 7 ou 6) nao encontrado" @(
        "Procurado: 'Inno Setup 7' e 'Inno Setup 6' em LOCALAPPDATA\Programs,",
        "Program Files e Program Files (x86); nas chaves 'Inno Setup <major>_is1'",
        "(HKCU, HKLM e WOW6432Node); e, por ultimo, no PATH.",
        "",
        "Instale com:  winget install --id JRSoftware.InnoSetup -e",
        "Ou informe o caminho:  .\installer\build.ps1 -IsccPath 'C:\...\ISCC.exe'"
    )
}

# FAIL-LOUD (D-IMAN-030): major desconhecida NAO segue com aviso. Compilar o
# release com um compilador que nunca foi validado contra este .iss e
# exatamente o risco que esta guarda existe para impedir - a falha apareceria
# so na VM, ou pior, na maquina do usuario.
$IsccVersao = Get-IsccVersao $Iscc
if (-not $IsccVersao) {
    Fail 2 "nao foi possivel determinar a versao do Inno Setup" @(
        "Executavel: $Iscc",
        "",
        "A sonda manda o ISCC compilar um .iss descartavel e le a linha:",
        "  'Compiler engine version: Inno Setup <versao>'",
        "Nao sair essa linha significa que este executavel nao se comporta como",
        "um ISCC - ou que e uma versao que nunca foi validada contra este .iss.",
        "",
        # Parenteses obrigatorios em torno da concatenacao: o ',' do array
        # tem precedencia MAIOR que o '+' em PowerShell, e sem eles o
        # "a", "b" + $x + "." vira um array de tres itens em vez de duas
        # linhas (medido nesta fatia - a mensagem saiu quebrada em 3).
        ("Versoes aceitas: Inno Setup major " + ($IsccMajoresAceitas -join ' ou ') + ".")
    )
}

$IsccMajor = [int](($IsccVersao -split '\.')[0])
if ($IsccMajoresAceitas -notcontains $IsccMajor) {
    Fail 2 "Inno Setup $IsccVersao nao e uma versao aceita" @(
        "Executavel: $Iscc",
        # Parenteses: ver a nota de precedencia ',' x '+' logo acima.
        ("Aceitas   : major " + ($IsccMajoresAceitas -join ' ou ') + "."),
        "",
        "O .iss deste produto so foi validado sob as majores acima. Seguir com um",
        "compilador nao reconhecido produziria um release que ninguem checou, e o",
        "defeito apareceria so na maquina do usuario. Por isso aqui e RECUSA, nao",
        "aviso.",
        "",
        "Adotar uma major nova e decisao de toolchain (foi assim com o 7, em",
        "D-IMAN-030): valide o .iss sob ela e so entao acrescente a major em",
        "`$IsccMajoresAceitas."
    )
}

Write-Ok "Inno Setup $IsccVersao  ($Iscc)"

# --- compilacao --------------------------------------------------------------

Write-Step "Compilando"

if (-not (Test-Path -LiteralPath $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir | Out-Null
}

# Idempotencia: remove o alvo antes de compilar para que uma falha nao deixe um
# artefato ANTIGO no lugar, passando por novo.
if (Test-Path -LiteralPath $ArtifactPath) {
    Remove-Item -LiteralPath $ArtifactPath -Force
}

& $Iscc "/Q" $IssPath
$isccExit = $LASTEXITCODE

if ($isccExit -ne 0 -or -not (Test-Path -LiteralPath $ArtifactPath)) {
    Fail 4 "o Inno Setup falhou (exit $isccExit)" @(
        "Artefato esperado: $ArtifactPath",
        "Rode sem /Q para ver o log completo:",
        "  & '$Iscc' '$IssPath'"
    )
}

$artifact = Get-Item -LiteralPath $ArtifactPath
$Sha256   = (Get-FileHash -LiteralPath $ArtifactPath -Algorithm SHA256).Hash

Write-Ok "$ArtifactName ($([math]::Round($artifact.Length / 1MB, 2)) MB)"

# --- QGIS presente na bancada (informativo) ----------------------------------

$qgisOnBench = 'nao detectado'
$qgisDir = Get-ChildItem -Path $env:ProgramFiles -Filter 'QGIS *' -Directory -ErrorAction SilentlyContinue |
           Sort-Object Name -Descending | Select-Object -First 1
if ($qgisDir) { $qgisOnBench = $qgisDir.FullName }

# --- BUILD_INFO.txt ----------------------------------------------------------

Write-Step "Gravando BUILD_INFO.txt"

$canonico = 'SIM'
$canonicoNota = ''
if ($Branch -ne 'develop') {
    $canonico = 'NAO'
    $canonicoNota = "  <<< artefato de branch de trabalho, nao de integracao"
}

$buildStamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')

$lines = @(
    "IMAN Terra - BUILD_INFO",
    "=======================================================================",
    "Este arquivo amarra o instalador ao commit que o gerou. Sem ele, um .exe",
    "numa VM e apenas um binario sem procedencia.",
    "",
    "Artefato              : $ArtifactName",
    "SHA-256               : $Sha256",
    "Tamanho (bytes)       : $($artifact.Length)",
    "",
    "ProductVersion        : $ProductVersion",
    "Commit                : $CommitFull",
    "Commit (curto)        : $CommitShort",
    "Data do commit        : $CommitDate",
    "Branch                : $Branch",
    "Build canonico        : $canonico$canonicoNota",
    "",
    "-----------------------------------------------------------------------",
    "QGIS EMBARCADO (D-IMAN-028 / via A2a)",
    "Este instalador NAO exige QGIS previamente instalado: ele instala o QGIS",
    "abaixo, offline, encadeando o MSI oficial nao modificado.",
    "",
    "QGIS embarcado        : $QgisBaseline",
    "Payload               : $PayloadName",
    "Payload SHA-256       : $PayloadSha",
    "Payload (bytes)       : $($PayloadItem.Length)",
    "ProductCode do QGIS   : $QgisProductCode",
    "Origem oficial        : $PayloadUrl",
    "-----------------------------------------------------------------------",
    "",
    "QGIS na bancada       : $qgisOnBench",
    "Compilador            : Inno Setup $IsccVersao",
    "Compilador (caminho)  : $Iscc",
    "Data/hora do build    : $buildStamp",
    "",
    "-----------------------------------------------------------------------",
    "SOBRE REPRODUTIBILIDADE",
    "O que este arquivo GARANTE e o par (ProductVersion, Commit): recompilar o",
    "MESMO commit limpo produz sempre os mesmos valores. E isso que amarra o",
    "artefato ao codigo.",
    "",
    "Sobre o SHA-256: ele NAO e funcao apenas do commit. Recompilar sem tocar em",
    "nada da o MESMO hash, mas o Inno Setup grava a DATA DE MODIFICACAO de cada",
    "arquivo empacotado, e o git NAO preserva mtime. Entao um clone novo, um",
    "checkout ou um rebase mudam o hash com o codigo IDENTICO - verificado nesta",
    "bancada: um rebase que so reescreveu a autoria, sem alterar um byte de app/,",
    "trocou o SHA-256 do instalador.",
    "",
    "CONSEQUENCIA PRATICA: nao use o SHA-256 para conferir 'e o mesmo codigo?'.",
    "Para isso serve o par (ProductVersion, Commit). O SHA-256 responde outra",
    "pergunta, tambem necessaria: 'o arquivo que chegou na VM e exatamente este",
    "que eu gerei?' - contra download truncado, trocado ou corrompido.",
    "",
    "COMO CONFERIR NA VM (PowerShell 5.1):",
    "  Get-FileHash .\$ArtifactName -Algorithm SHA256",
    "-----------------------------------------------------------------------"
)

Set-Content -LiteralPath $BuildInfo -Value $lines -Encoding UTF8

Write-Host ""
Write-Host "  BUILD OK" -ForegroundColor Green
Write-Host "  Artefato : $ArtifactPath"
Write-Host "  Versao   : $ProductVersion   Commit: $CommitShort   Branch: $Branch"
Write-Host "  SHA-256  : $Sha256" -ForegroundColor White
Write-Host "  Info     : $BuildInfo"
if ($canonico -eq 'NAO') {
    Write-Host ""
    Write-Host "  AVISO: build NAO-CANONICO (branch '$Branch', esperado 'develop')." -ForegroundColor Yellow
    Write-Host "         Serve para teste; o artefato de release sai de develop." -ForegroundColor Yellow
}

# Artefatos de versoes anteriores continuam em dist/ (o script so remove o alvo).
# Sao a origem classica do erro de levar o .exe ERRADO para a VM - o BUILD_INFO.txt
# descreve apenas o artefato acima.
$outros = @(Get-ChildItem -LiteralPath $DistDir -Filter '*.exe' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne $ArtifactName })
if ($outros.Count -gt 0) {
    Write-Host ""
    Write-Host "  ATENCAO: ha outro(s) instalador(es) antigo(s) em installer\dist\:" -ForegroundColor Yellow
    foreach ($o in $outros) {
        Write-Host ("         {0}   ({1:yyyy-MM-dd})" -f $o.Name, $o.LastWriteTime) -ForegroundColor Yellow
    }
    Write-Host "         O BUILD_INFO.txt descreve APENAS $ArtifactName." -ForegroundColor Yellow
    Write-Host "         Leve para a VM o arquivo cujo SHA-256 bate com o BUILD_INFO." -ForegroundColor Yellow
}
Write-Host ""

exit 0
