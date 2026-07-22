<#
=============================================================================
 BL-7 / BL-3 - assercao do invariante "perfil do usuario intacto"

 Compara o perfil QGIS do usuario com o snapshot tirado ANTES da instalacao e
 verifica que o IMAN Terra criou o SEU perfil, isolado, noutro lugar.

 Duas assercoes independentes:
   [BL-3a] O perfil do USUARIO esta BYTE-IDENTICO ao snapshot anterior.
           Qualquer arquivo adicionado, removido ou alterado = FAIL.
   [BL-3b] O perfil ISOLADO do IMAN Terra foi criado em
           %APPDATA%\InstitutoIMAN\IMAN Terra\profiles\iman-distro.

 FAIL em BL-3a BLOQUEIA o release (regra de corte do RESULT.md).

 EXEMPLO
   .\snapshot-user-profile.ps1 -Rotulo antes     # antes de instalar
   ... instalar, abrir, usar e FECHAR o IMAN Terra ...
   .\assert-bl3.ps1 -Baseline "$env:USERPROFILE\Desktop\bl7-evidence\perfil-usuario-antes.json"

 IMPORTANTE: feche o QGIS antes de rodar, senao arquivos travados viram ruido.

 SAIDA: 0 = PASS (as duas assercoes), 1 = FAIL, 2 = erro de uso.

 REQUISITOS: Windows PowerShell 5.1. Sem Python, sem git, sem modulos de
 terceiros, sem privilegio de administrador. ASCII-only de proposito.
=============================================================================
#>
[CmdletBinding()]
param(
    # JSON gerado por snapshot-user-profile.ps1 ANTES da instalacao.
    [Parameter(Mandatory = $true)]
    [string]$Baseline,

    # Raiz a re-inspecionar. Por padrao usa a mesma raiz gravada no baseline.
    [string]$Path,

    # Perfil isolado que o IMAN Terra deve ter criado.
    [string]$PerfilIsolado = (Join-Path $env:APPDATA 'InstitutoIMAN\IMAN Terra\profiles\iman-distro'),

    [string]$OutDir = (Join-Path $env:USERPROFILE 'Desktop\bl7-evidence')
)

$ErrorActionPreference = 'Stop'

function Write-Result([string]$Tag, [bool]$Ok, [string]$Text) {
    if ($Ok) {
        Write-Host ("  [{0}] PASS  {1}" -f $Tag, $Text) -ForegroundColor Green
    } else {
        Write-Host ("  [{0}] FAIL  {1}" -f $Tag, $Text) -ForegroundColor Red
    }
}

if (-not (Test-Path -LiteralPath $Baseline)) {
    Write-Host ""
    Write-Host "  ERRO: baseline nao encontrado: $Baseline" -ForegroundColor Red
    Write-Host "  Rode snapshot-user-profile.ps1 -Rotulo antes ANTES de instalar." -ForegroundColor Yellow
    Write-Host ""
    exit 2
}

$base = Get-Content -LiteralPath $Baseline -Raw | ConvertFrom-Json

if (-not $Path) { $Path = $base.Raiz }

# Mesma canonicalizacao do snapshot: o caminho relativo gravado no baseline so
# bate se a raiz for recortada com o mesmo comprimento nas duas pontas.
if (Test-Path -LiteralPath $Path) { $Path = (Get-Item -LiteralPath $Path).FullName }
$Path = $Path.TrimEnd('\')

Write-Host ""
Write-Host "  BL-3 - o perfil do usuario continua intacto?" -ForegroundColor White
Write-Host "  Baseline : $Baseline  ($($base.CapturadoEm))"
Write-Host "  Raiz     : $Path"
Write-Host ""

# --- re-snapshot (mesma regra do snapshot-user-profile.ps1) ------------------

$existeAgora = Test-Path -LiteralPath $Path
$agora = @{}

if ($existeAgora) {
    $itens = Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue
    foreach ($item in $itens) {
        $rel = $item.FullName.Substring($Path.Length).TrimStart('\')
        $hash = $null
        try {
            $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
        } catch {
            $hash = "ERRO_LEITURA: " + $_.Exception.Message
        }
        $agora[$rel] = $hash
    }
}

# --- comparacao --------------------------------------------------------------

$antes = @{}
foreach ($a in $base.Arquivos) { $antes[$a.Caminho] = $a.SHA256 }

$adicionados = @()
$removidos   = @()
$alterados   = @()

foreach ($k in $agora.Keys) {
    if (-not $antes.ContainsKey($k)) {
        $adicionados += $k
    } elseif ($antes[$k] -ne $agora[$k]) {
        $alterados += $k
    }
}
foreach ($k in $antes.Keys) {
    if (-not $agora.ContainsKey($k)) { $removidos += $k }
}

$adicionados = @($adicionados | Sort-Object)
$removidos   = @($removidos   | Sort-Object)
$alterados   = @($alterados   | Sort-Object)

$divergencias = $adicionados.Count + $removidos.Count + $alterados.Count

# A raiz existir antes e sumir depois (ou vice-versa) tambem e violacao.
$raizConsistente = ($existeAgora -eq $base.RaizExiste)

$bl3a = ($divergencias -eq 0) -and $raizConsistente

# --- perfil isolado ----------------------------------------------------------

$isoladoExiste = Test-Path -LiteralPath $PerfilIsolado
$isoladoArquivos = 0
if ($isoladoExiste) {
    $isoladoArquivos = @(Get-ChildItem -LiteralPath $PerfilIsolado -Recurse -File -Force -ErrorAction SilentlyContinue).Count
}
# Diretorio vazio nao conta: significaria copia do template falhando.
$bl3b = $isoladoExiste -and ($isoladoArquivos -gt 0)

# --- relatorio ---------------------------------------------------------------

Write-Host "  Arquivos no baseline : $($base.TotalArquivos)"
Write-Host "  Arquivos agora       : $($agora.Count)"
# Os dois totais podem COINCIDIR e ainda assim haver violacao: um arquivo apagado
# mais um adicionado mantem a contagem. Por isso o detalhe vem sempre junto - o
# total sozinho e numericamente verdadeiro e enganoso.
Write-Host ("  Detalhe              : {0} alterado(s), {1} adicionado(s), {2} removido(s)" -f `
            $alterados.Count, $adicionados.Count, $removidos.Count)
Write-Host ""

Write-Result 'BL-3a' $bl3a "perfil do usuario byte-identico ao baseline ($divergencias divergencia(s))"
Write-Result 'BL-3b' $bl3b "perfil isolado do IMAN Terra criado ($isoladoArquivos arquivo(s))"
Write-Host "         $PerfilIsolado" -ForegroundColor DarkGray

if (-not $raizConsistente) {
    Write-Host ""
    Write-Host "  A propria raiz mudou de estado:" -ForegroundColor Red
    Write-Host "    existia antes: $($base.RaizExiste)   existe agora: $existeAgora" -ForegroundColor Red
}

if ($divergencias -gt 0) {
    Write-Host ""
    Write-Host "  DIVERGENTES (o que a distro nao deveria ter tocado):" -ForegroundColor Red
    foreach ($k in $alterados)   { Write-Host "    ALTERADO  $k" -ForegroundColor Red }
    foreach ($k in $adicionados) { Write-Host "    ADICIONADO $k" -ForegroundColor Red }
    foreach ($k in $removidos)   { Write-Host "    REMOVIDO  $k" -ForegroundColor Red }
}

if (-not $bl3b) {
    Write-Host ""
    Write-Host "  O perfil isolado nao foi encontrado (ou esta vazio)." -ForegroundColor Red
    Write-Host "  Causas tipicas: o IMAN Terra nunca chegou a abrir, ou o launcher" -ForegroundColor Yellow
    Write-Host "  nao encontrou o QGIS. Confira o passo 5 do CHECKLIST." -ForegroundColor Yellow
}

# --- evidencia em arquivo ----------------------------------------------------

if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}
$OutFile = Join-Path $OutDir 'assert-bl3.json'

[PSCustomObject]@{
    Ferramenta        = 'assert-bl3.ps1'
    VerificadoEm      = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
    Baseline          = $Baseline
    Raiz              = $Path
    BL3a_PerfilUsuarioIntacto = $bl3a
    BL3b_PerfilIsoladoCriado  = $bl3b
    PerfilIsolado     = $PerfilIsolado
    PerfilIsoladoArquivos = $isoladoArquivos
    Alterados         = $alterados
    Adicionados       = $adicionados
    Removidos         = $removidos
} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutFile -Encoding UTF8

Write-Host ""
Write-Host "  Evidencia: $OutFile"

if ($bl3a -and $bl3b) {
    Write-Host ""
    Write-Host "  RESULTADO: PASS" -ForegroundColor Green
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "  RESULTADO: FAIL" -ForegroundColor Red
if (-not $bl3a) {
    Write-Host "  FAIL em BL-3a BLOQUEIA o release (dado do usuario)." -ForegroundColor Red
}
Write-Host ""
exit 1
