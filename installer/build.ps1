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
   3  guarda de integridade (arvore suja / branch errada)
   4  falha do compilador Inno Setup

 REQUISITOS: PowerShell 5.1, git no PATH, Inno Setup 6.
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
    [string]$IsccPath
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

Write-Ok "ProductVersion $ProductVersion / baseline QGIS LTR $QgisBaseline"

# --- localizacao do ISCC -----------------------------------------------------

Write-Step "Localizando o compilador do Inno Setup"

function Find-Iscc([string]$Explicit) {
    if ($Explicit) {
        if (Test-Path -LiteralPath $Explicit) { return (Resolve-Path -LiteralPath $Explicit).Path }
        return $null
    }
    if ($env:ISCC -and (Test-Path -LiteralPath $env:ISCC)) { return $env:ISCC }

    # Ordem deliberada: winget instala em LOCALAPPDATA\Programs (a memoria da
    # fatia 1 presumiu Program Files e errou - por isso a busca e explicita).
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }

    # Ultimo recurso: chave de desinstalacao do proprio Inno Setup.
    $keys = @(
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Inno Setup 6_is1'
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

    $cmd = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

$Iscc = Find-Iscc $IsccPath
if (-not $Iscc) {
    Fail 2 "ISCC.exe (Inno Setup 6) nao encontrado" @(
        "Instale com:  winget install --id JRSoftware.InnoSetup -e",
        "Ou informe o caminho:  .\installer\build.ps1 -IsccPath 'C:\...\ISCC.exe'"
    )
}
Write-Ok $Iscc

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
    "QGIS LTR baseline     : $QgisBaseline   (versao suportada declarada)",
    "QGIS na bancada       : $qgisOnBench",
    "Compilador            : $Iscc",
    "Data/hora do build    : $buildStamp",
    "",
    "-----------------------------------------------------------------------",
    "SOBRE REPRODUTIBILIDADE",
    "O par (ProductVersion, Commit) e reproduzivel: recompilar o MESMO commit",
    "limpo produz sempre os mesmos valores. O SHA-256 NAO e - o Inno Setup",
    "embute data/hora no cabecalho do executavel, entao cada compilacao gera um",
    "hash diferente. Por isso o SHA-256 identifica ESTA COPIA do artefato: e ele",
    "que a VM confere apos o download, para provar que testou este arquivo.",
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
Write-Host ""

exit 0
