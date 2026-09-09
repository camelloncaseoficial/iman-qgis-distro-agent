<#
=============================================================================
 #021 - CICLO DE REINSTALACAO (DB-22)

 Mede, num destino REAL, o que o briefing #021 pediu que fosse medido - e nao
 relatado:

   1. destino VIRGEM      -> instalar          : exit, contagem, INTEGRIDADE
   2. abrir e reabrir                          : quanto a arvore CRESCE em uso
   3. instalar SOBRE a instalacao existente    : exit 0, contagem == manifesto
   4. arvore DELIBERADAMENTE corrompida        : o ciclo se recupera sozinho
   5. abrir e reabrir de novo
   6. desinstalar                              : quantas SOBRAS, e de que tipo

 POR QUE ESTE SCRIPT EXISTE, e nao um roteiro no laudo: o DB-22 nasceu de um
 ciclo feito a mao, cujo diagnostico veio contaminado por um launcher
 sobrevivente da instalacao anterior. Um ciclo que se re-roda e um ciclo que
 se pode conferir.

 P0.8 - A CONTAGEM E CONTRA O MANIFESTO, NUNCA CONTRA PADRAO DE NOME. O
 numero de referencia sai da linha TOTAL| do proprio qgis-manifest.txt que
 acompanha o artefato; nada aqui presume 37.337.

 O QUE ELE NAO FAZ: nao eleva (o produto e per-user), nao toca
 %APPDATA%\InstitutoIMAN (o perfil do usuario - BL-3), nao toca instalacao
 nenhuma de QGIS de terceiro. So mexe no destino do proprio produto.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-reinstalacao.ps1 `
       -Instalador .\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Instalador,

    # Raiz do produto. O default e o mesmo do .iss: {localappdata}\Programs\<produto>.
    [string]$Produto = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),

    # Onde o relatorio JSON e gravado.
    [string]$Saida = '',

    # Quantos arquivos de sujeira injetar no passo 4.
    [int]$ArquivosDeSujeira = 25,

    # Segundos de espera por cada abertura do produto.
    [int]$EsperaAbrir = 45
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$raizRepo   = (Get-Item (Join-Path $raizScript '..')).FullName
if ([string]::IsNullOrWhiteSpace($Saida)) {
    $Saida = Join-Path $raizRepo 'docs\verify\021-reinstalar-sem-laco\evidencia\reinstalacao.json'
}

function Escreve { param([string]$T, [string]$C = 'Gray') Write-Host $T -ForegroundColor $C }
function Titulo  { param([string]$T) Write-Host ''; Write-Host "  $T" -ForegroundColor White }

$Instalador = (Get-Item -LiteralPath $Instalador).FullName
$Produto    = [IO.Path]::GetFullPath($Produto)
$ArvoreQgis = Join-Path $Produto 'qgis'
$Manifesto  = Join-Path $Produto 'qgis-manifest.txt'
$Launcher   = Join-Path $Produto 'launcher\IMAN-Terra.bat'

# GUARDA (BL-3): este script APAGA o destino para chegar ao estado virgem. Se
# alguem apontar -Produto para area protegida ou para o perfil do usuario, o
# estrago seria real. Recusar e mais barato que consertar.
foreach ($proibido in @($env:ProgramFiles, ${env:ProgramFiles(x86)},
                        (Join-Path $env:APPDATA 'QGIS'),
                        (Join-Path $env:APPDATA 'InstitutoIMAN'))) {
    if ($proibido -and $Produto.ToLower().StartsWith($proibido.ToLower())) {
        throw "Destino '$Produto' cai em area protegida '$proibido'. Abortado (BL-3)."
    }
}

# ---------------------------------------------------------------- utilitarios
function Conta-Arvore {
    if (-not (Test-Path -LiteralPath $ArvoreQgis)) { return 0 }
    return @(Get-ChildItem -LiteralPath $ArvoreQgis -Recurse -File -Force -ErrorAction SilentlyContinue).Count
}

function Total-Do-Manifesto {
    # P0.8: o numero de referencia vem do manifesto do artefato, nao de constante.
    if (-not (Test-Path -LiteralPath $Manifesto)) { return $null }
    $m = Select-String -LiteralPath $Manifesto -Pattern '^TOTAL\|(\d+)\|' | Select-Object -First 1
    if (-not $m) { return $null }
    return [int]$m.Matches[0].Groups[1].Value
}

function Integridade {
    <# Roda a GUARDA DO PROPRIO PRODUTO, em modo diagnostico. Reimplementar a
       verificacao aqui validaria a copia, nao o produto. #>
    if (-not (Test-Path -LiteralPath $Launcher)) { return @{ ok = $false; saida = '<launcher ausente>' } }
    $cmd = Join-Path $env:SystemRoot 'System32\cmd.exe'
    $antes = $env:IMAN_TERRA_CHECK_ONLY
    $env:IMAN_TERRA_CHECK_ONLY = '1'
    try {
        # `< NUL` de proposito: no caminho de RECUSA o launcher termina em
        # `pause`, e sem stdin fechado esta funcao ficaria pendurada esperando
        # uma tecla que ninguem vai apertar. O caso de falha tem de devolver
        # numero, nao travar a medicao.
        $out = & $cmd '/c' "`"$Launcher`" < NUL" 2>&1 | Out-String
        $code = $LASTEXITCODE
    } finally {
        $env:IMAN_TERRA_CHECK_ONLY = $antes
    }
    return @{
        ok    = ($code -eq 0 -and $out -match 'INTEGRIDADE=OK')
        exit  = $code
        saida = ($out.Trim() -replace '\s+', ' ')
    }
}

function Mata-Qgis {
    Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

function Instala {
    param([string]$Rotulo)
    Mata-Qgis
    $t0 = Get-Date
    $p = Start-Process -FilePath $Instalador -Wait -PassThru -ArgumentList @(
        '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/NOICONS')
    $dt = ((Get-Date) - $t0).TotalSeconds
    $n = Conta-Arvore
    $manifesto = Total-Do-Manifesto
    $integ = Integridade
    $r = [ordered]@{
        passo               = $Rotulo
        exit                = $p.ExitCode
        segundos            = [math]::Round($dt, 1)
        arquivos_na_arvore  = $n
        total_do_manifesto  = $manifesto
        diferenca           = $(if ($manifesto) { $n - $manifesto } else { $null })
        integridade_ok      = $integ.ok
        integridade_exit    = $integ.exit
        integridade_saida   = $integ.saida
    }
    Escreve ("    exit {0} | {1} s | arvore {2} | manifesto {3} | dif {4} | INTEGRIDADE {5}" -f
             $r.exit, $r.segundos, $r.arquivos_na_arvore, $r.total_do_manifesto, $r.diferenca,
             $(if ($r.integridade_ok) { 'OK' } else { 'FALHOU' })) `
             $(if ($r.exit -eq 0 -and $r.integridade_ok) { 'Green' } else { 'Red' })
    return $r
}

function Abre-E-Fecha {
    param([string]$Rotulo)
    Mata-Qgis
    Start-Process -FilePath $Launcher -WorkingDirectory (Split-Path -Parent $Launcher) -WindowStyle Hidden | Out-Null
    $p = $null
    for ($i = 0; $i -lt ($EsperaAbrir * 2); $i++) {
        Start-Sleep -Milliseconds 500
        $p = Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($p) { break }
    }
    $subiu = [bool]$p
    $titulo = ''
    if ($subiu) {
        # Espera a janela principal existir: e o que prova que o produto ABRIU,
        # e nao so que um processo nasceu e morreu.
        for ($i = 0; $i -lt 60; $i++) {
            Start-Sleep -Seconds 1
            $p.Refresh()
            if ($p.HasExited) { break }
            if ($p.MainWindowTitle) { $titulo = $p.MainWindowTitle; break }
        }
    }
    Mata-Qgis
    $n = Conta-Arvore
    $r = [ordered]@{
        passo              = $Rotulo
        subiu              = $subiu
        titulo_da_janela   = $titulo
        arquivos_na_arvore = $n
    }
    Escreve ("    subiu {0} | titulo '{1}' | arvore {2}" -f $subiu, $titulo, $n) `
             $(if ($subiu -and $titulo) { 'Green' } else { 'Red' })
    return $r
}

function Desinstala {
    Mata-Qgis
    $unins = Join-Path $Produto 'unins000.exe'
    if (-not (Test-Path -LiteralPath $unins)) { throw "unins000.exe nao encontrado em $Produto" }
    $t0 = Get-Date
    # O desinstalador do Inno se copia para o TEMP e o processo original sai
    # antes do fim. Esperar so o -Wait daria um tempo mentiroso: a espera de
    # verdade e o diretorio do produto parar de existir (ou o unins sumir).
    $p = Start-Process -FilePath $unins -Wait -PassThru -ArgumentList @(
        '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART')
    for ($i = 0; $i -lt 300; $i++) {
        if (-not (Test-Path -LiteralPath $unins)) { break }
        Start-Sleep -Seconds 1
    }
    Start-Sleep -Seconds 3
    $dt = ((Get-Date) - $t0).TotalSeconds

    $sobras = @()
    if (Test-Path -LiteralPath $Produto) {
        $sobras = @(Get-ChildItem -LiteralPath $Produto -Recurse -File -Force -ErrorAction SilentlyContinue)
    }
    $porExt = @{}
    foreach ($f in $sobras) {
        $e = $f.Extension.ToLower(); if (-not $e) { $e = '<sem extensao>' }
        if ($porExt.ContainsKey($e)) { $porExt[$e]++ } else { $porExt[$e] = 1 }
    }
    $bytes = 0; foreach ($f in $sobras) { $bytes += $f.Length }
    $r = [ordered]@{
        passo             = 'desinstalar'
        exit              = $p.ExitCode
        segundos          = [math]::Round($dt, 1)
        raiz_ainda_existe = (Test-Path -LiteralPath $Produto)
        sobras_arquivos   = $sobras.Count
        sobras_bytes      = $bytes
        sobras_por_extensao = $porExt
        amostra           = @($sobras | Select-Object -First 6 |
                              ForEach-Object { $_.FullName.Substring($Produto.Length).TrimStart('\') })
    }
    Escreve ("    exit {0} | {1} s | sobras {2} arquivos / {3:N2} MB | por extensao: {4}" -f
             $r.exit, $r.segundos, $r.sobras_arquivos, ($bytes / 1MB),
             (($porExt.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' ')) 'Cyan'
    return $r
}

# ================================================================== o ciclo
Write-Host ''
Write-Host '  #021 - ciclo de reinstalacao (DB-22)' -ForegroundColor White
Write-Host "  instalador: $Instalador"
Write-Host "  destino   : $Produto"

$doc = [ordered]@{
    quando     = (Get-Date).ToUniversalTime().ToString('o')
    instalador = $Instalador
    instalador_sha256 = (Get-FileHash -LiteralPath $Instalador -Algorithm SHA256).Hash
    instalador_bytes  = (Get-Item -LiteralPath $Instalador).Length
    destino    = $Produto
    passos     = @()
}

# ------------------------------------------------------------- 0. destino virgem
Titulo '0. destino VIRGEM'
Mata-Qgis
$unins = Join-Path $Produto 'unins000.exe'
if (Test-Path -LiteralPath $unins) {
    Escreve '    ha instalacao anterior - desinstalando antes de comecar' 'Yellow'
    $doc.passos += (Desinstala)
}
if (Test-Path -LiteralPath $Produto) {
    Remove-Item -LiteralPath $Produto -Recurse -Force -ErrorAction SilentlyContinue
}
$virgem = -not (Test-Path -LiteralPath $Produto)
Escreve ("    destino virgem: {0}" -f $virgem) $(if ($virgem) { 'Green' } else { 'Red' })
if (-not $virgem) { throw "Nao foi possivel deixar '$Produto' virgem." }
$doc.passos += ([ordered]@{ passo = 'destino virgem'; virgem = $virgem })

# ---------------------------------------------------- 1. instalar (ciclo limpo)
Titulo '1. instalar em destino virgem  (o caminho que JA funcionava - nao pode regredir)'
$doc.passos += (Instala 'instalar em destino virgem')

# -------------------------------------------------------- 2. abrir e reabrir
Titulo '2. abrir e reabrir  (a arvore CRESCE em uso: .pyc de runtime)'
$doc.passos += (Abre-E-Fecha 'abrir (1a vez)')
$doc.passos += (Abre-E-Fecha 'reabrir (2a vez)')

# -------------------------------------- 3. instalar SOBRE instalacao existente
Titulo '3. instalar SOBRE a instalacao existente  (o DB-22)'
$doc.passos += (Instala 'instalar sobre instalacao existente')

# --------------------------------------------- 4. arvore deliberadamente suja
Titulo '4. arvore DELIBERADAMENTE corrompida -> instalar  (o ciclo se recupera sozinho?)'
$sujos = @()
$alvo = Join-Path $ArvoreQgis 'apps\Python312'
if (-not (Test-Path -LiteralPath $alvo)) { $alvo = $ArvoreQgis }
for ($i = 1; $i -le $ArquivosDeSujeira; $i++) {
    $f = Join-Path $alvo ("iman-sujeira-{0:D3}.tmp" -f $i)
    Set-Content -LiteralPath $f -Value "sujeira deliberada do #021 - passo 4" -Encoding Ascii
    $sujos += $f
}
$nSujo = Conta-Arvore
Escreve ("    injetados {0} arquivos -> arvore com {1}" -f $sujos.Count, $nSujo) 'Yellow'
$doc.passos += ([ordered]@{
    passo = 'corromper a arvore'
    arquivos_injetados = $sujos.Count
    arquivos_na_arvore = $nSujo
    onde = $alvo.Substring($ArvoreQgis.Length).TrimStart('\')
})
$doc.passos += (Instala 'instalar sobre arvore corrompida')
$sobreviventes = @($sujos | Where-Object { Test-Path -LiteralPath $_ })
Escreve ("    arquivos de sujeira sobreviventes: {0}" -f $sobreviventes.Count) `
         $(if ($sobreviventes.Count -eq 0) { 'Green' } else { 'Red' })
$doc.passos += ([ordered]@{
    passo = 'sujeira apos reinstalar'
    sobreviventes = $sobreviventes.Count
})

# ------------------------------ 5. abrir e reabrir (para medir o CICLO LIMPO)
Titulo '5. abrir e reabrir  (para o numero de sobras ser o do CICLO LIMPO)'
$doc.passos += (Abre-E-Fecha 'abrir (ciclo limpo, 1a vez)')
$doc.passos += (Abre-E-Fecha 'reabrir (ciclo limpo, 2a vez)')

# ------------------------------------------------------------ 6. desinstalar
Titulo '6. desinstalar  (quantas sobras o ciclo LIMPO deixa)'
$doc.passos += (Desinstala)

# ------------------------------------------------------------------ relatorio
$dirSaida = Split-Path -Parent $Saida
if (-not (Test-Path -LiteralPath $dirSaida)) { New-Item -ItemType Directory -Path $dirSaida -Force | Out-Null }
$doc | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Saida -Encoding UTF8
Write-Host ''
Escreve "  relatorio: $Saida" 'Green'
Write-Host ''
