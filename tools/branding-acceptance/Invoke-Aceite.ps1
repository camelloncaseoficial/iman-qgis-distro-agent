<#
=============================================================================
 #017 - orquestrador do TESTE DE ACEITE da camada de marca

 Sobe o PRODUTO REAL (QGIS instalado + perfil iman-distro montado do
 profile-template + iman_startup.py de verdade) e roda um script de sonda
 dentro dele via --code.

 V.4 - PERFIL NOVO: o perfil e reconstruido do zero a cada rodada. Um perfil
 reaproveitado carrega estado da rodada anterior (docks movidos, projeto
 recente, .ini editado) e faz o aceite medir a bancada em vez do build.

 BL-3 - o perfil vive em %LOCALAPPDATA%\InstitutoIMAN\_aceite017\. NUNCA em
 %APPDATA%\QGIS, NUNCA em C:\Program Files\QGIS*. O script RECUSA rodar se o
 destino cair numa dessas areas.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1 -Sonda discover.py

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    # Script .py rodado dentro do QGIS via --code.
    [string]$Sonda = 'acceptance_probe.py',

    # Raiz do QGIS a usar. Default: o standalone instalado nesta bancada.
    [string]$Qgis = '',

    # Onde o perfil novo e a saida da rodada vivem.
    [string]$Base = (Join-Path $env:LOCALAPPDATA 'InstitutoIMAN\_aceite017'),

    [string]$Perfil = 'iman-distro',

    # Segundos de espera pelo arquivo de saida da sonda.
    [int]$Espera = 180,

    # Nao mata o QGIS ao final (para inspecao manual).
    [switch]$Manter,

    # SEGUNDA EXECUCAO (D7): reaproveita o perfil da rodada anterior em vez de
    # reconstrui-lo. E o unico jeito de medir "a home some depois do 1o uso" -
    # na 1a execucao o defeito nao existe. Fora deste caso, V.4 manda perfil novo.
    [switch]$ReusarPerfil,

    # 'primeira' (suite completa) ou 'segunda' (so o pouso, no perfil ja usado).
    [ValidateSet('primeira','segunda')]
    [string]$Fase = 'primeira'
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$raizRepo   = (Get-Item (Join-Path $raizScript '..\..')).FullName

function Escreve { param([string]$T, [string]$C = 'Gray') Write-Host $T -ForegroundColor $C }

Escreve ''
Escreve '  #017 - teste de aceite da camada de marca' 'White'
Escreve ''

# --------------------------------------------------------------- 1. o QGIS
if ([string]::IsNullOrEmpty($Qgis)) {
    $cand = Get-ChildItem 'C:\Program Files' -Directory -Filter 'QGIS *' -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending | Select-Object -First 1
    if (-not $cand) { throw 'Nenhum QGIS encontrado em C:\Program Files. Passe -Qgis <raiz>.' }
    $Qgis = $cand.FullName
}
$exe = Join-Path $Qgis 'bin\qgis-ltr-bin.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw "qgis-ltr-bin.exe nao encontrado em $Qgis" }
Escreve "  QGIS    : $Qgis"

# --------------------------------------------------- 2. guarda BL-3 do destino
$Base = [IO.Path]::GetFullPath($Base)
foreach ($proibido in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, (Join-Path $env:APPDATA 'QGIS'))) {
    if ($proibido -and $Base.ToLower().StartsWith($proibido.ToLower())) {
        throw "Destino '$Base' cai em area protegida '$proibido'. Abortado (BL-3)."
    }
}

# ------------------------------------------------------ 3. PERFIL NOVO (V.4)
$perfilRaiz = Join-Path $Base 'perfil'
$perfilDir  = Join-Path $perfilRaiz ("profiles\{0}" -f $Perfil)
$template   = Join-Path $raizRepo ("app\profile-template\{0}" -f $Perfil)
if (-not (Test-Path -LiteralPath $template)) { throw "profile-template nao encontrado: $template" }

if ($ReusarPerfil) {
    if (-not (Test-Path -LiteralPath $perfilDir)) {
        throw "-ReusarPerfil pedido, mas nao existe perfil anterior em $perfilDir. Rode a 1a execucao primeiro."
    }
    $nArq = @(Get-ChildItem -LiteralPath $perfilDir -Recurse -File).Count
    Escreve "  perfil  : $perfilDir  ($nArq arquivos, REAPROVEITADO da rodada anterior)" 'Yellow'
} else {
    if (Test-Path -LiteralPath $perfilDir) {
        Remove-Item -LiteralPath $perfilDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $perfilDir -Force | Out-Null
    Copy-Item -Path (Join-Path $template '*') -Destination $perfilDir -Recurse -Force
    # __pycache__ do repo nao pode viajar para o perfil de teste
    Get-ChildItem -LiteralPath $perfilDir -Recurse -Directory -Filter '__pycache__' -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
    $nArq = @(Get-ChildItem -LiteralPath $perfilDir -Recurse -File).Count
    Escreve "  perfil  : $perfilDir  ($nArq arquivos, RECONSTRUIDO do zero)"
}
if ($nArq -le 0) { throw 'Perfil saiu vazio. Abortado.' }

# ----------------------------------------------------------- 4. saida limpa
$saida = Join-Path $Base 'saida'
if ((Test-Path -LiteralPath $saida) -and (-not $ReusarPerfil)) {
    Remove-Item -LiteralPath $saida -Recurse -Force
}
New-Item -ItemType Directory -Path $saida -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $saida 'shots') -Force | Out-Null

# ------------------------------------------------------------- 5. ambiente
$sondaPath = Join-Path $raizScript $Sonda
if (-not (Test-Path -LiteralPath $sondaPath)) { throw "Sonda nao encontrada: $sondaPath" }
$startup = Join-Path $raizRepo 'app\startup\iman_startup.py'
if (-not (Test-Path -LiteralPath $startup)) { throw "iman_startup.py nao encontrado: $startup" }

$env:SPIKE017_OUT      = $saida
$env:SPIKE017_STARTUP  = $startup
$env:SPIKE017_REPO     = $raizRepo
$env:IMAN_TERRA_HOME   = (Join-Path $raizRepo 'app')
$env:SPIKE017_FASE     = $Fase

Escreve "  sonda   : $sondaPath"
Escreve "  startup : $startup  (o de verdade)"
Escreve "  saida   : $saida"
Escreve "  fase    : $Fase"

# --------------------------------------------------------------- 6. executa
$argv = @('--profiles-path', $perfilRaiz, '--profile', $Perfil, '--noversioncheck',
          '--code', $sondaPath)
Escreve ''
Escreve "  > qgis-ltr-bin.exe --profiles-path <perfil> --profile $Perfil --noversioncheck --code <sonda>"
$p = Start-Process -FilePath $exe -ArgumentList $argv -PassThru
Escreve "  PID $($p.Id) - aguardando ate $Espera s pela saida da sonda..."

$alvos = @('descoberta.json', $(if ($Fase -eq 'segunda') { 'aceite-segunda.json' } else { 'aceite.json' }))
$achado = $null
for ($i = 0; $i -lt $Espera; $i++) {
    Start-Sleep -Seconds 1
    foreach ($a in $alvos) {
        $f = Join-Path $saida $a
        if (Test-Path -LiteralPath $f) { $achado = $f; break }
    }
    if ($achado) { break }
    if ($p.HasExited) { break }
}

$p.Refresh()
if ($achado) {
    Start-Sleep -Seconds 2   # deixa a sonda terminar de gravar screenshots
    Escreve ""
    Escreve ("  sonda concluiu em ~{0} s: {1}" -f $i, $achado) 'Green'
} else {
    Escreve ''
    if ($p.HasExited) {
        Escreve ("  O QGIS SAIU sozinho (exit {0}) sem a sonda gravar saida." -f $p.ExitCode) 'Red'
    } else {
        Escreve '  TIMEOUT: a sonda nao gravou saida.' 'Red'
    }
}

if (-not $Manter) {
    Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
} else {
    Escreve "  -Manter: o QGIS continua aberto (PID $($p.Id))." 'Yellow'
}

if (-not $achado) { exit 1 }
exit 0
