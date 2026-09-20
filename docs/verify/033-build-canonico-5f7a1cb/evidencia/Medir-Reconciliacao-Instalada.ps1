<#
=============================================================================
 #033 - ENTREGA 5: a reconciliacao rodando NO PRODUTO INSTALADO.

 O QUE MUDA EM RELACAO A tools\test-reconciliacao-perfil.ps1 (#030): aquela
 guarda monta um APP_HOME sintetico (launcher copiado, template do repo,
 arvore por junction) porque precisa rodar sem instalacao. Esta aqui NAO monta
 nada: ela chama o launcher que o instalador colocou em
 %LOCALAPPDATA%\Programs\IMAN Terra\launcher\IMAN-Terra.bat, com o template e
 a arvore que o instalador entregou. E a primeira vez que o caminho do
 INSTALADOR exercita o DB-26 (C.1 - produto real, nao copia).

 ONDE ELA ESCREVE (BL-3 / Passo 0): o perfil de cada estado vive em
 %APPDATA% REDIRECIONADO para dentro do sandbox, so durante a execucao do
 launcher. O perfil REAL do sponsor em %APPDATA%\InstitutoIMAN nao e tocado -
 e isso e MEDIDO, com MD5 por arquivo antes e depois.

 E.1: antes de cada rodada confere-se que o perfil semeado DE FATO difere do
 template instalado naquilo que a rodada assere.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Medir-Reconciliacao-Instalada.ps1

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    [string]$Produto = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),
    [string]$Sandbox = 'C:\_imant33',
    [string]$Perfil  = 'iman-distro',
    [string]$VelhoDe = 'ba58d14',
    [string]$Json    = ''
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$raizRepo   = (Get-Item (Join-Path $raizScript '..\..\..\..')).FullName

function Escreve { param([string]$T, [string]$C = 'Gray') Write-Host $T -ForegroundColor $C }
function Sha { param([string]$P) (Get-FileHash -LiteralPath $P -Algorithm SHA256).Hash.ToUpperInvariant() }

# --------------------------------------------------------- guarda de destino
$Sandbox = [IO.Path]::GetFullPath($Sandbox)
$proibidos = @($env:APPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)},
               (Join-Path $env:LOCALAPPDATA 'Programs'), $raizRepo)
foreach ($p in $proibidos) {
    if ($p -and $Sandbox.ToLower().StartsWith($p.ToLower())) {
        throw "Sandbox '$Sandbox' cai em area protegida '$p'. Abortado (BL-3 / Passo 0)."
    }
}

$bat        = Join-Path $Produto 'launcher\IMAN-Terra.bat'
$templateIn = Join-Path $Produto ('profile-template\' + $Perfil)
foreach ($p in @($bat, $templateIn, (Join-Path $Produto 'qgis-manifest.txt'))) {
    if (-not (Test-Path -LiteralPath $p)) { throw "nao parece uma instalacao do produto: falta $p" }
}

Escreve ''
Escreve '  #033 entrega 5 - reconciliacao NO PRODUTO INSTALADO' 'White'
Escreve ("  produto  : {0}" -f $Produto)
Escreve ("  launcher : {0}" -f $bat)
Escreve ("  template : {0}  (o que o INSTALADOR entregou)" -f $templateIn)
Escreve ("  sandbox  : {0}  (%APPDATA% redirecionado)" -f $Sandbox)
Escreve ''

# BUILD_ID do produto que esta sendo exercitado
$buildId = @{}
foreach ($l in (Get-Content -LiteralPath (Join-Path $Produto 'BUILD_ID.txt'))) {
    if ($l -match '^([a-z_]+)=(.*)$') { $buildId[$Matches[1]] = $Matches[2] }
}
Escreve ("  BUILD_ID : versao={0} commit={1} canonico={2}" -f $buildId['versao'], $buildId['commit_curto'], $buildId['build_canonico'])
Escreve ''

# ------------------------------------------------- hashes do template instalado
$hashTemplate = @{}
foreach ($f in (Get-ChildItem -LiteralPath $templateIn -Recurse -File -Force)) {
    $rel = $f.FullName.Substring($templateIn.Length + 1) -replace '\\', '/'
    if ($rel -match '(^|/)__pycache__/' -or $rel -like '*.pyc' -or $rel -like '*.gitkeep') { continue }
    $hashTemplate[$rel] = Sha $f.FullName
}
Escreve ("  template instalado: {0} arquivos" -f $hashTemplate.Count)

# ------------------------------------------------------------- BL-3, antes
$RaizesIntocaveis = @((Join-Path $env:APPDATA 'QGIS'), (Join-Path $env:APPDATA 'InstitutoIMAN'))
function SnapshotIntocavel {
    $h = [ordered]@{}
    foreach ($raiz in $RaizesIntocaveis) {
        if (-not (Test-Path -LiteralPath $raiz)) { continue }
        foreach ($f in (Get-ChildItem -LiteralPath $raiz -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            try { $h[$f.FullName] = (Get-FileHash -LiteralPath $f.FullName -Algorithm MD5).Hash } catch { }
        }
    }
    return $h
}
$antesIntocavel = SnapshotIntocavel
foreach ($raiz in $RaizesIntocaveis) {
    $n = @($antesIntocavel.Keys | Where-Object { $_.ToLower().StartsWith($raiz.ToLower()) }).Count
    Escreve ("  BL-3: {0} - {1} arquivo(s), MD5 tirado antes" -f $raiz, $n)
}
Escreve ''

# ------------------------------------------------------------------ utilidades
function PerfilDe { param([string]$Raiz) Join-Path $Raiz ('appdata\InstitutoIMAN\IMAN Terra\profiles\' + $Perfil) }

# Roda O LAUNCHER INSTALADO, com %APPDATA% redirecionado e RECONCILE_ONLY.
function RodaLauncher {
    param([string]$Raiz, [int]$Limite = 300)
    $log = Join-Path $Raiz '_launcher.out'
    $envolucro = Join-Path $Raiz '_roda.cmd'
    Set-Content -LiteralPath $envolucro -Encoding ASCII -Value @(
        '@echo off',
        ('set "APPDATA=' + (Join-Path $Raiz 'appdata') + '"'),
        'set "IMAN_TERRA_RECONCILE_ONLY=1"',
        'set "PYTHONDONTWRITEBYTECODE=1"',
        ('echo.| "' + $bat + '" > "' + $log + '" 2>&1'),
        'exit /b %ERRORLEVEL%')
    $t0 = Get-Date
    $proc = Start-Process -FilePath $envolucro -PassThru -WindowStyle Hidden
    $fim = (Get-Date).AddSeconds($Limite)
    while (-not $proc.HasExited -and (Get-Date) -lt $fim) { Start-Sleep -Milliseconds 200 }
    if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue; $codigo = 999 }
    else { $codigo = $proc.ExitCode }
    $saida = ''
    if (Test-Path -LiteralPath $log) {
        try { $saida = [System.IO.File]::ReadAllText($log, [System.Text.Encoding]::GetEncoding([Console]::OutputEncoding.CodePage)) }
        catch { $saida = (Get-Content -LiteralPath $log -Raw -ErrorAction SilentlyContinue) }
    }
    return @{ Saida = [string]$saida; Codigo = $codigo; Ms = [int]((Get-Date) - $t0).TotalMilliseconds }
}

function Campo {
    param([string]$Saida, [string]$Nome)
    $m = [regex]::Match($Saida, ('(?m)^' + [regex]::Escape($Nome) + '=(.*)$'))
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return ''
}

function ContaRaios {
    param([string]$Qss, [int]$Px)
    if (-not (Test-Path -LiteralPath $Qss)) { return -1 }
    return @([regex]::Matches((Get-Content -LiteralPath $Qss -Raw), ('[a-z-]*radius:\s*' + $Px + 'px'))).Count
}

# Materializa app/profile-template/<perfil> de um commit real, por COPIA CRUA.
function TemplateDoCommit {
    param([string]$Commit, [string]$Destino)
    if (Test-Path -LiteralPath $Destino) { Remove-Item -LiteralPath $Destino -Recurse -Force }
    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
    $tar = Join-Path ([IO.Path]::GetTempPath()) ("iman033-" + [guid]::NewGuid().ToString('N') + ".tar")
    Push-Location $raizRepo
    try {
        & git archive --format=tar -o $tar $Commit ("app/profile-template/{0}" -f $Perfil)
        if ($LASTEXITCODE -ne 0) { throw "git archive $Commit falhou" }
    } finally { Pop-Location }
    try {
        & tar -xf $tar -C $Destino
        if ($LASTEXITCODE -ne 0) { throw "tar -xf falhou" }
    } finally { Remove-Item -LiteralPath $tar -Force -ErrorAction SilentlyContinue }
    return (Join-Path $Destino ('app\profile-template\' + $Perfil))
}

$resultados = New-Object System.Collections.ArrayList
function Registra {
    param([string]$Id, [string]$Titulo, [string]$Veredito, [string[]]$Provas, [string]$Cru = '')
    [void]$resultados.Add([pscustomobject]@{ Id = $Id; Titulo = $Titulo; Veredito = $Veredito; Provas = @($Provas); Cru = $Cru })
    $cor = switch ($Veredito) { 'PASS' { 'Green' } 'FAIL' { 'Red' } 'ABORTADO' { 'Magenta' } default { 'DarkYellow' } }
    Escreve ("  [{0}] {1} - {2}" -f $Veredito, $Id, $Titulo) $cor
    foreach ($p in $Provas) { Escreve ("        {0}" -f $p) 'DarkGray' }
}

function ConfereContraTemplate {
    param([string]$PerfilDir)
    $div = @()
    foreach ($rel in $hashTemplate.Keys) {
        $alvo = Join-Path $PerfilDir ($rel -replace '/', '\')
        if (-not (Test-Path -LiteralPath $alvo)) { $div += "$rel (ausente)" }
        elseif ((Sha $alvo) -ne $hashTemplate[$rel]) { $div += "$rel (hash)" }
    }
    return , @($div)
}

if (Test-Path -LiteralPath $Sandbox) { Remove-Item -LiteralPath $Sandbox -Recurse -Force }
New-Item -ItemType Directory -Path $Sandbox -Force | Out-Null

# ==========================================================================
#  (a) PERFIL AUSENTE - o primeiro uso de quem acabou de instalar
# ==========================================================================
$raizA = Join-Path $Sandbox 'a-perfil-ausente'
New-Item -ItemType Directory -Path $raizA -Force | Out-Null
$perfilA = PerfilDe $raizA
$existiaAntes = Test-Path -LiteralPath $perfilA
$rA = RodaLauncher $raizA
$divA = ConfereContraTemplate $perfilA
$baseA = Join-Path $perfilA '.iman-terra\base.json'
$temBaseA = Test-Path -LiteralPath $baseA
$provasA = @(
    ("exit={0}  RECONCILIACAO={1}  {2}" -f $rA.Codigo, (Campo $rA.Saida 'RECONCILIACAO'), (Campo $rA.Saida 'PLANO')),
    ("perfil existia antes da abertura: {0}" -f $existiaAntes),
    ("{0} de {1} arquivos do template INSTALADO com SHA-256 identico no perfil" -f ($hashTemplate.Count - $divA.Count), $hashTemplate.Count),
    ("base registrada em .iman-terra\base.json: {0}" -f $temBaseA)
)
if ($divA.Count -gt 0) { $provasA += ("divergentes: " + ($divA -join ', ')) }
$digestA = ''
if ($temBaseA) {
    $b = Get-Content -LiteralPath $baseA -Raw -Encoding UTF8 | ConvertFrom-Json
    $digestA = [string]$b.template_digest
    $provasA += ("  template_digest={0}  chaves={1}" -f $digestA, @($b.chaves.PSObject.Properties).Count)
}
$okA = ($rA.Codigo -eq 0) -and (-not $existiaAntes) -and ($divA.Count -eq 0) -and $temBaseA -and
       ((Campo $rA.Saida 'RECONCILIACAO') -eq 'SEMEADO')
Registra '5a' 'perfil ausente -> nasce semeado, com a base registrada' $(if ($okA) { 'PASS' } else { 'FAIL' }) $provasA $rA.Saida

# ==========================================================================
#  (b) PERFIL VELHO, vindo do git por COPIA CRUA (ba58d14, anterior ao #022)
# ==========================================================================
$raizB = Join-Path $Sandbox 'b-perfil-velho'
New-Item -ItemType Directory -Path $raizB -Force | Out-Null
$perfilB = PerfilDe $raizB
$velho = TemplateDoCommit $VelhoDe (Join-Path $raizB '_t-velho')
New-Item -ItemType Directory -Path $perfilB -Force | Out-Null
Copy-Item -Path (Join-Path $velho '*') -Destination $perfilB -Recurse -Force

$qss    = Join-Path $perfilB 'themes\IMAN Terra\style.qss'
$plugin = Join-Path $perfilB 'python\plugins\iman_brand\iman_brand.py'
$raios58A = (ContaRaios $qss 5) + (ContaRaios $qss 6) + (ContaRaios $qss 7) + (ContaRaios $qss 8)
$raios2A  = (ContaRaios $qss 2)
$menu6x12 = @(Select-String -LiteralPath $qss -Pattern 'QMenuBar::item \{[^}]*padding:\s*6px 12px').Count
$sufixoA  = @(Select-String -LiteralPath $plugin -Pattern '_RE_SUFIXO_DO_QGIS').Count
$divAntes = ConfereContraTemplate $perfilB

# E.1 - o perfil semeado TEM de diferir naquilo que a rodada assere
$ruins = @()
if ($raios58A -ne 14)      { $ruins += "raios de 5 a 8 px no perfil semeado ($raios58A, esperado 14)" }
if ($raios2A  -ne 0)       { $ruins += "raios de 2 px ja presentes ($raios2A, esperado 0)" }
if ($menu6x12 -ne 1)       { $ruins += "QMenuBar::item 6px 12px ausente" }
if ($sufixoA  -ne 0)       { $ruins += "_RE_SUFIXO_DO_QGIS ja presente ($sufixoA, esperado 0)" }
if ($divAntes.Count -eq 0) { $ruins += "o perfil semeado ja sai identico ao template instalado" }

if ($ruins.Count -gt 0) {
    Registra '5b' ("perfil de {0} -> reconciliacao aplica" -f $VelhoDe) 'ABORTADO' @(
        ("E.1: o baseline nao difere do esperado em: " + ($ruins -join '; ') + " - a rodada nao provaria nada"))
} else {
    $rB = RodaLauncher $raizB
    $raios2B  = (ContaRaios $qss 2)
    $raios58B = (ContaRaios $qss 5) + (ContaRaios $qss 6) + (ContaRaios $qss 7) + (ContaRaios $qss 8)
    $menu3x4  = @(Select-String -LiteralPath $qss -Pattern 'QMenuBar::item \{[^}]*padding:\s*3px 4px').Count
    $sufixoB  = @(Select-String -LiteralPath $plugin -Pattern '_RE_SUFIXO_DO_QGIS').Count
    $divB     = ConfereContraTemplate $perfilB
    $baseB    = Join-Path $perfilB '.iman-terra\base.json'
    $temBaseB = Test-Path -LiteralPath $baseB
    $digestB  = ''
    if ($temBaseB) { $digestB = [string]((Get-Content -LiteralPath $baseB -Raw -Encoding UTF8 | ConvertFrom-Json).template_digest) }
    $okB = ($rB.Codigo -eq 0) -and ($divB.Count -eq 0) -and ($raios2B -eq 20) -and ($raios58B -eq 0) -and
           ($menu3x4 -eq 1) -and ($sufixoB -eq 3) -and $temBaseB -and
           ((Campo $rB.Saida 'RECONCILIACAO') -eq 'APLICADA')
    $provasB = @(
        ("exit={0}  RECONCILIACAO={1}  {2}" -f $rB.Codigo, (Campo $rB.Saida 'RECONCILIACAO'), (Campo $rB.Saida 'PLANO')),
        ("raios: 5-8px {0} -> {1}   2px {2} -> {3}  (o template instalado tem 20)" -f $raios58A, $raios58B, $raios2A, $raios2B),
        ("QMenuBar::item: 6px 12px -> 3px 4px? {0}" -f ($menu3x4 -eq 1)),
        ("_RE_SUFIXO_DO_QGIS em iman_brand.py: {0} -> {1}  (o template instalado tem 3)" -f $sufixoA, $sufixoB),
        ("arquivos do produto com SHA-256 do template INSTALADO: {0} de {1} (antes: {2} de {1})" -f
            ($hashTemplate.Count - $divB.Count), $hashTemplate.Count, ($hashTemplate.Count - $divAntes.Count)),
        ("base registrada: {0}  template_digest={1}" -f $temBaseB, $digestB)
    )
    if ($divB.Count -gt 0) { $provasB += ("divergentes: " + ($divB -join ', ')) }
    if ($digestA -and $digestB -and ($digestA -ne $digestB)) { $provasB += ("ATENCAO: digest de (a) e (b) diferem") }
    Registra '5b' ("perfil de {0} (copia crua) -> tema e plugin desta versao chegam" -f $VelhoDe) $(if ($okB) { 'PASS' } else { 'FAIL' }) $provasB $rB.Saida
}

# ==========================================================================
#  BL-3, depois
# ==========================================================================
$depoisIntocavel = SnapshotIntocavel
$mexidos = @()
foreach ($k in $antesIntocavel.Keys) {
    if (-not $depoisIntocavel.Contains($k)) { $mexidos += "- $k" }
    elseif ($depoisIntocavel[$k] -ne $antesIntocavel[$k]) { $mexidos += "~ $k" }
}
foreach ($k in $depoisIntocavel.Keys) { if (-not $antesIntocavel.Contains($k)) { $mexidos += "+ $k" } }
$okBl3 = ($mexidos.Count -eq 0)
$provasBl3 = @(("{0} arquivo(s) sob %APPDATA%\QGIS e %APPDATA%\InstitutoIMAN, MD5 antes x depois: {1} diferenca(s)" -f $antesIntocavel.Count, $mexidos.Count))
if ($mexidos.Count -gt 0) { $provasBl3 += ($mexidos | Select-Object -First 20) }
Registra 'BL-3' 'o perfil REAL do sponsor nao foi tocado' $(if ($okBl3) { 'PASS' } else { 'FAIL' }) $provasBl3

# ==========================================================================
#  placar
# ==========================================================================
$n = @($resultados | Where-Object { $_.Veredito -eq 'PASS' }).Count
$N = $resultados.Count
Escreve ''
Escreve ("  PLACAR: {0} de {1}" -f $n, $N) $(if ($n -eq $N) { 'Green' } else { 'Red' })
Escreve ''
foreach ($r in $resultados) {
    if ($r.Cru) {
        Escreve ("--- saida crua: {0} ---" -f $r.Id) 'DarkCyan'
        Write-Host $r.Cru
    }
}

if ($Json) {
    [pscustomobject]@{
        quando   = (Get-Date).ToString('o')
        produto  = $Produto
        build_id = $buildId
        sandbox  = $Sandbox
        placar   = ("{0} de {1}" -f $n, $N)
        estados  = $resultados
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Json -Encoding UTF8
    Escreve ("  json: {0}" -f $Json)
}

exit $(if ($n -eq $N) { 0 } else { 1 })
