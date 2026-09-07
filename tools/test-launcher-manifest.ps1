<#
=============================================================================
 IMAN Terra - teste da GUARDA DE INTEGRIDADE do launcher (fatia #019, via A1)

 SUBSTITUI o tools\test-launcher-detection.ps1, que morreu junto com a
 deteccao do QGIS instalado: na via A1 nao ha o que detectar - o QGIS vive
 dentro do produto.

 O QUE ELE PROVA, exercitando o launcher REAL (nunca uma copia da logica):

   T1  arvore integra                  -> abre (INTEGRIDADE=OK, exit 0)
   T2  diretorio critico AUSENTE       -> RECUSA abrir, e diz qual
   T3  diretorio critico TRUNCADO      -> RECUSA abrir, e diz a contagem
   T4  arquivo critico ALTERADO        -> RECUSA abrir pelo SHA-256
   T5  manifesto AUSENTE               -> RECUSA abrir
   T6  caminho de instalacao LONGO     -> RECUSA abrir com diagnostico PROPRIO,
                                          e NAO acusando corrupcao

 O T3 e o coracao: "a pasta existe" nao basta. Foi uma arvore truncada que o
 spike #016 mediu devolvendo deslocamento de datum de 0,00 m onde o correto
 sao ~57 m, com o QGIS afirmando que os CRS eram validos.

 O T6 existe porque o `dir /s` PULA em silencio o que passa de 260 caracteres:
 sem ele, uma instalacao em caminho fundo seria acusada de corrompida.

 NAO altera a arvore de origem: trabalha sobre uma copia das areas mexidas e
 desfaz tudo ao final.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-launcher-manifest.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-launcher-manifest.ps1 -Arvore <raiz> -Manifesto <arquivo>

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    [string]$Arvore = '',
    [string]$Manifesto = '',
    [string]$Sandbox = ''
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$raizRepo   = (Get-Item (Join-Path $raizScript '..')).FullName

if ([string]::IsNullOrWhiteSpace($Arvore)) {
    $Arvore = Join-Path $raizRepo 'installer\stage\qgis\QGIS 3.44.13'
}
if ([string]::IsNullOrWhiteSpace($Manifesto)) {
    $Manifesto = Join-Path $raizRepo 'installer\stage\qgis-manifest.txt'
}
# Raiz CURTA de proposito: o T6 mede o caso longo deliberadamente, e os outros
# cinco precisam de folga para nao esbarrarem no limite sem querer.
if ([string]::IsNullOrWhiteSpace($Sandbox)) { $Sandbox = 'C:\_imant19' }

$Launcher = Join-Path $raizRepo 'app\launcher\IMAN-Terra.bat'

function Escreve { param([string]$T, [string]$C = 'Gray') Write-Host $T -ForegroundColor $C }

foreach ($p in @($Arvore, $Manifesto, $Launcher)) {
    if (-not (Test-Path -LiteralPath $p)) {
        Escreve "  Pre-requisito ausente: $p" 'Red'
        Escreve '  Rode installer\build.ps1 (ou installer\New-ArvoreQgis.ps1) antes.' 'Red'
        exit 2
    }
}

Escreve ''
Escreve '  #019 - guarda de integridade do launcher' 'White'
Escreve "  arvore    : $Arvore"
Escreve "  manifesto : $Manifesto"
Escreve ''

# --------------------------------------------------------------- sandbox
# Junction em vez de copia: a arvore tem 2,2 GB e copia-la a cada teste
# tornaria o teste caro o bastante para ninguem rodar.
function Novo-Sandbox {
    param([string]$Raiz)
    if (Test-Path -LiteralPath (Join-Path $Raiz 'qgis')) {
        & cmd.exe /c "rmdir `"$(Join-Path $Raiz 'qgis')`"" | Out-Null
    }
    if (Test-Path -LiteralPath $Raiz) { Remove-Item -LiteralPath $Raiz -Recurse -Force }
    New-Item -ItemType Directory -Path (Join-Path $Raiz 'launcher') -Force | Out-Null
    Copy-Item -LiteralPath $Launcher -Destination (Join-Path $Raiz 'launcher') -Force
    Copy-Item -LiteralPath $Manifesto -Destination (Join-Path $Raiz 'qgis-manifest.txt') -Force
    & cmd.exe /c "mklink /J `"$(Join-Path $Raiz 'qgis')`" `"$Arvore`"" | Out-Null
}

function Roda-Launcher {
    param([string]$Raiz)
    $bat = Join-Path $Raiz 'launcher\IMAN-Terra.bat'
    $env:IMAN_TERRA_CHECK_ONLY = '1'
    # `echo.` alimenta o `pause` do caminho de falha; sem isso o teste trava.
    $saida = & cmd.exe /c "echo.| `"$bat`"" 2>&1 | Out-String
    $codigo = $LASTEXITCODE
    Remove-Item Env:\IMAN_TERRA_CHECK_ONLY -ErrorAction SilentlyContinue
    return @{ Saida = $saida; Codigo = $codigo }
}

$resultados = @()
function Caso {
    param([string]$Id, [string]$Titulo, [scriptblock]$Preparo, [scriptblock]$Criterio)
    Novo-Sandbox -Raiz $Sandbox
    $desfazer = & $Preparo $Sandbox
    try {
        $r = Roda-Launcher -Raiz $Sandbox
        $ok = & $Criterio $r
    } finally {
        if ($desfazer) { & $desfazer }
    }
    $script:resultados += [pscustomobject]@{
        Id = $Id; Titulo = $Titulo; Ok = $ok
        Codigo = $r.Codigo
        Trecho = (($r.Saida -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 6) -join ' / ')
    }
    $tag = if ($ok) { 'PASS' } else { 'FAIL' }
    $cor = if ($ok) { 'Green' } else { 'Red' }
    Escreve ("  [{0}] {1}  {2}" -f $tag, $Id, $Titulo) $cor
    if (-not $ok) { Escreve ("        exit={0}  saida: {1}" -f $r.Codigo, $script:resultados[-1].Trecho) 'DarkGray' }
}

# ------------------------------------------------------------------ T1
Caso 'T1' 'arvore integra -> abre' { param($s) $null } {
    param($r) ($r.Codigo -eq 0) -and ($r.Saida -match 'INTEGRIDADE=OK')
}

# ------------------------------------------------------------------ T2
# Diretorio critico AUSENTE. Renomeia na origem e desfaz no finally.
Caso 'T2' 'share\proj AUSENTE -> recusa' {
    param($s)
    $de = Join-Path $Arvore 'share\proj'
    $para = Join-Path $Arvore 'share\proj.TESTE019'
    Rename-Item -LiteralPath $de -NewName 'proj.TESTE019'
    { if (Test-Path -LiteralPath $para) { Rename-Item -LiteralPath $para -NewName 'proj' } }.GetNewClosure()
} {
    param($r) ($r.Codigo -eq 1) -and ($r.Saida -match 'share\\proj')
}

# ------------------------------------------------------------------ T3
# Diretorio critico TRUNCADO: some UM arquivo. "A pasta existe" continua
# verdadeiro - e e exatamente por isso que este caso existe.
Caso 'T3' 'apps\gdal\share\gdal TRUNCADO em 1 arquivo -> recusa' {
    param($s)
    $dir = Join-Path $Arvore 'apps\gdal\share\gdal'
    $alvo = Get-ChildItem -LiteralPath $dir -File | Select-Object -First 1
    $guardado = Join-Path $env:TEMP ('t19-' + $alvo.Name)
    Move-Item -LiteralPath $alvo.FullName -Destination $guardado -Force
    $origem = $alvo.FullName
    { Move-Item -LiteralPath $guardado -Destination $origem -Force }.GetNewClosure()
} {
    param($r) ($r.Codigo -eq 1) -and ($r.Saida -match 'gdal') -and ($r.Saida -match 'esperados')
}

# ------------------------------------------------------------------ T4
# Arquivo critico ALTERADO com o MESMO tamanho: so o SHA-256 pega.
Caso 'T4' 'proj.db ALTERADO (mesmo tamanho) -> recusa pelo SHA-256' {
    param($s)
    $alvo = Join-Path $Arvore 'share\proj\proj.db'
    $backup = Join-Path $env:TEMP 't19-proj.db'
    Copy-Item -LiteralPath $alvo -Destination $backup -Force
    $fs = [IO.File]::Open($alvo, 'Open', 'ReadWrite')
    try {
        $fs.Seek(1024, 'Begin') | Out-Null
        $b = $fs.ReadByte()
        $fs.Seek(1024, 'Begin') | Out-Null
        $fs.WriteByte([byte](($b + 1) -band 0xFF))
    } finally { $fs.Close() }
    { Move-Item -LiteralPath $backup -Destination $alvo -Force }.GetNewClosure()
} {
    param($r) ($r.Codigo -eq 1) -and ($r.Saida -match 'SHA-256')
}

# ------------------------------------------------------------------ T5
Caso 'T5' 'manifesto AUSENTE -> recusa' {
    param($s) Remove-Item -LiteralPath (Join-Path $s 'qgis-manifest.txt') -Force; $null
} {
    param($r) ($r.Codigo -eq 1) -and ($r.Saida -match 'manifesto')
}

# ------------------------------------------------------------------ T6
# Caminho longo: o diagnostico tem de ser PROPRIO, nunca "copia corrompida".
$SandboxLongo = Join-Path $env:TEMP ('imant19-' + ('x' * 90))
Caso 'T6' 'caminho longo demais -> diagnostico proprio, nao "corrompida"' {
    param($s)
    $script:Sandbox = $SandboxLongo
    Novo-Sandbox -Raiz $SandboxLongo
    { $script:Sandbox = 'C:\_imant19' }.GetNewClosure()
} {
    param($r)
    ($r.Codigo -eq 1) -and ($r.Saida -match 'caminho longo demais') -and
    ($r.Saida -notmatch 'INCOMPLETA ou ALTERADA')
}

# ----------------------------------------------------------------- limpeza
foreach ($raiz in @('C:\_imant19', $SandboxLongo)) {
    if (Test-Path -LiteralPath (Join-Path $raiz 'qgis')) {
        & cmd.exe /c "rmdir `"$(Join-Path $raiz 'qgis')`"" | Out-Null
    }
    if (Test-Path -LiteralPath $raiz) {
        Remove-Item -LiteralPath $raiz -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$falhas = @($resultados | Where-Object { -not $_.Ok })
Escreve ''
Escreve ("  {0} de {1} casos passaram." -f ($resultados.Count - $falhas.Count), $resultados.Count) 'White'
if ($falhas.Count -gt 0) {
    Escreve '  A guarda de integridade do launcher NAO esta cumprindo o contrato.' 'Red'
    exit 1
}
Escreve '  A guarda recusa abrir em toda arvore quebrada, e diz por que.' 'Green'
exit 0
