<#
=============================================================================
 IMAN Terra - guarda da RECONCILIACAO DO PERFIL (DB-26, fatia #030)

 O QUE ELA PROVA, exercitando o LAUNCHER REAL (C.1). O launcher e chamado com
 IMAN_TERRA_RECONCILE_ONLY=1: ele confere a arvore, RECONCILIA o perfil,
 imprime o relato cru e sai sem abrir o QGIS. Nada aqui reimplementa a
 reconciliacao - um teste que a reimplementasse validaria a copia, nao o
 produto. E o mesmo precedente do IMAN_TERRA_CHECK_ONLY (#019).

 PERFIL VELHO VEM DE TEMPLATE REAL DA HISTORIA DO GIT, nunca de edicao a mao:

   ba58d14  (2026-09-07, merge do PR #22, ANTERIOR a fatia #022)
            14 declaracoes de raio de 5 a 8 px, QMenuBar::item 6px 12px,
            iman_brand.py SEM _RE_SUFIXO_DO_QGIS.
   8cc4d5e^ (= f728e4f, 2026-07-05, ANTERIOR a 8cc4d5e de 07-07)
            carrega os DOIS obsoletos - QGIS/iman-theme.qss e
            .../resources/logo.png - e CRS padrao EPSG:4674.

 O perfil velho e semeado por COPIA CRUA, e nao passando o template antigo
 pela rotina nova. E assim que ele nasceu de verdade: o launcher daquela epoca
 fazia `xcopy /E /I /Y`. Alem disso, template antigo nao e "o template deste
 build" - o produto sempre reconcilia contra o template que ELE embarca.

 ONDE ELA ESCREVE (Passo 0 - a bancada e do sponsor, e esta em uso):
 nenhum teste toca o perfil real em %APPDATA%\InstitutoIMAN\IMAN Terra. Cada
 estado roda com %APPDATA% REDIRECIONADO para a sua pasta dentro do sandbox,
 so durante a execucao do launcher. O script RECUSA rodar se o sandbox cair em
 %APPDATA% real, em %ProgramFiles% ou em %LOCALAPPDATA%\Programs.

 ASSERCAO POR HASH E POR VALOR DE CHAVE LIDO DO .INI (C.2), nunca "o arquivo
 existe".

 E.1 - antes de cada rodada, confere-se que o perfil semeado DE FATO difere do
 template atual naquilo que a rodada assere. Se ja saisse igual, a rodada nao
 provaria nada: o estado vira ABORTADO e a suite sai com exit 2.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-reconciliacao-perfil.ps1
   ... -Estados 3,4,6,8
   ... -Ref 733e129        (adulteracao inversa: o launcher DAQUELE commit)
   ... -Json .\saida.json

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    # Launcher a por a prova. Vazio = o da arvore de trabalho.
    [string]$Launcher = '',

    # Adulteracao inversa: extrai app\launcher\ DESTE commit e poe a prova.
    # O template e a declaracao continuam sendo os da arvore de trabalho - a
    # pergunta e "o launcher daquele commit entrega este produto?".
    [string]$Ref = '',

    [string]$Arvore = '',
    [string]$Manifesto = '',
    # Raiz CURTA (o manifesto tem MAXREL=152 e o limite classico e 259) mas com
    # MAIS DE 8 CARACTERES no primeiro componente, de proposito: assim o
    # o4w_env.bat precisa de um alias 8.3 (C:\_IMANT~1) e a deteccao de
    # instancia viva do produto e exercitada na forma CURTA, que e a que
    # aparece de verdade. Com 'C:\_imant30' (8 caracteres, ja valido em 8.3) os
    # dois caminhos coincidiam e o ramo curto nunca era posto a prova.
    [string]$Sandbox = 'C:\_imant30-guarda',
    # Lista separada por virgula. NAO e [int[]]: chamado com -File, o
    # powershell.exe nao interpreta o valor - '-Estados 3,4' chegaria como a
    # STRING '3,4' (que vira @(34)), e '-Estados 3 4' amarraria o 4 no primeiro
    # parametro posicional. Recebendo texto, as duas formas funcionam.
    [string]$Estados = '',
    [string]$Json = '',

    # Estado 10 sobe um QGIS de verdade e pode levar ~1 min. -SemQgis o pula,
    # e o estado sai N/E (nomeado), nunca PASS.
    [switch]$SemQgis
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$raizRepo   = (Get-Item (Join-Path $raizScript '..')).FullName

if (-not $Arvore)    { $Arvore    = Join-Path $raizRepo 'installer\stage\qgis\QGIS 3.44.13' }
if (-not $Manifesto) { $Manifesto = Join-Path $raizRepo 'installer\stage\qgis-manifest.txt' }

$TemplateRepo = Join-Path $raizRepo 'app\profile-template\iman-distro'
$DeclaracaoRepo = Join-Path $raizRepo 'app\profile-template\PERFIL-DO-PRODUTO.json'
$PastaLauncherRepo = Join-Path $raizRepo 'app\launcher'

function Escreve { param([string]$T, [string]$C = 'Gray') Write-Host $T -ForegroundColor $C }

# Materializa um caminho do repo NUM COMMIT, via git archive.
# O .tar vai para DISCO antes de ser aberto: `git archive ... | tar -x` em
# PowerShell corrompe o fluxo (o pipe do PS carrega texto, nao bytes) e o tar
# responde "Unrecognized archive format". Medido nesta bancada em 2026-09-16.
function ExtraiDoGit {
    param([string]$Commit, [string]$Caminho, [string]$Destino)
    if (-not (Test-Path -LiteralPath $Destino)) { New-Item -ItemType Directory -Path $Destino -Force | Out-Null }
    $tar = Join-Path ([IO.Path]::GetTempPath()) ("iman030-" + [guid]::NewGuid().ToString('N') + ".tar")
    Push-Location $raizRepo
    try {
        & git archive --format=tar -o $tar $Commit $Caminho
        if ($LASTEXITCODE -ne 0) { throw "git archive $Commit $Caminho falhou" }
    } finally { Pop-Location }
    try {
        & tar -xf $tar -C $Destino
        if ($LASTEXITCODE -ne 0) { throw "tar -xf falhou para $Commit $Caminho" }
    } finally { Remove-Item -LiteralPath $tar -Force -ErrorAction SilentlyContinue }
}

# ==========================================================================
# GUARDA DE DESTINO (BL-3 / Passo 0). Esta e a primeira coisa que roda: um
# teste de reconciliacao de perfil que erra o destino RECONCILIA O PERFIL DO
# SPONSOR. Nao ha como desfazer isso depois.
# ==========================================================================
$Sandbox = [IO.Path]::GetFullPath($Sandbox)
$proibidos = @(
    $env:APPDATA,
    $env:ProgramFiles,
    ${env:ProgramFiles(x86)},
    (Join-Path $env:LOCALAPPDATA 'Programs'),
    (Join-Path $env:APPDATA 'QGIS'),
    $raizRepo
)
foreach ($p in $proibidos) {
    if ($p -and $Sandbox.ToLower().StartsWith($p.ToLower())) {
        throw "Sandbox '$Sandbox' cai em area protegida '$p'. Abortado (BL-3 / Passo 0)."
    }
}

foreach ($p in @($Arvore, $Manifesto, $TemplateRepo, $DeclaracaoRepo)) {
    if (-not (Test-Path -LiteralPath $p)) {
        Escreve "  Pre-requisito ausente: $p" 'Red'
        Escreve '  Rode installer\build.ps1 (ou installer\New-ArvoreQgis.ps1) antes.' 'Red'
        exit 2
    }
}

# --------------------------------------------------- o launcher sob teste
$pastaLauncher = $PastaLauncherRepo
$rotuloLauncher = 'arvore de trabalho'
if ($Ref) {
    $pastaLauncher = Join-Path $Sandbox ('_launcher-' + $Ref)
    if (Test-Path -LiteralPath $pastaLauncher) { Remove-Item -LiteralPath $pastaLauncher -Recurse -Force }
    New-Item -ItemType Directory -Path $pastaLauncher -Force | Out-Null
    ExtraiDoGit $Ref 'app/launcher' $pastaLauncher
    $pastaLauncher = Join-Path $pastaLauncher 'app\launcher'
    $rotuloLauncher = "launcher de $Ref"
}
if ($Launcher) { $pastaLauncher = Split-Path -Parent ([IO.Path]::GetFullPath($Launcher)) ; $rotuloLauncher = $Launcher }
$batLauncher = Join-Path $pastaLauncher 'IMAN-Terra.bat'
if (-not (Test-Path -LiteralPath $batLauncher)) { throw "Launcher nao encontrado: $batLauncher" }

Escreve ''
Escreve '  #030 - reconciliacao do perfil (DB-26)' 'White'
Escreve "  launcher : $batLauncher  ($rotuloLauncher)"
Escreve "  template : $TemplateRepo"
Escreve "  arvore   : $Arvore"
Escreve "  sandbox  : $Sandbox"
Escreve ''

# ==========================================================================
#  ferramentas
# ==========================================================================

function Sha { param([string]$P) (Get-FileHash -LiteralPath $P -Algorithm SHA256).Hash.ToUpperInvariant() }

function LimpaIgnorados {
    param([string]$Raiz)
    Get-ChildItem -LiteralPath $Raiz -Recurse -Directory -Filter '__pycache__' -Force -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
    Get-ChildItem -LiteralPath $Raiz -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq '.gitkeep' -or $_.Extension -eq '.pyc' } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
}

# Instantaneo do perfil INTEIRO: caminho relativo -> SHA-256. E a regua do R4
# ("byte a byte") e do R5 ("nao escreve nada").
function Instantaneo {
    param([string]$Raiz)
    $h = @{}
    if (-not (Test-Path -LiteralPath $Raiz)) { return $h }
    foreach ($f in (Get-ChildItem -LiteralPath $Raiz -Recurse -File -Force)) {
        $rel = $f.FullName.Substring($Raiz.Length + 1) -replace '\\', '/'
        $h[$rel] = @{ Sha = (Sha $f.FullName); Escrito = $f.LastWriteTimeUtc.Ticks }
    }
    return $h
}

function DiferencaInstantaneo {
    param([hashtable]$Antes, [hashtable]$Depois)
    $d = New-Object System.Collections.ArrayList
    foreach ($k in $Antes.Keys) {
        if (-not $Depois.ContainsKey($k)) { [void]$d.Add("- $k") }
        elseif ($Depois[$k].Sha -ne $Antes[$k].Sha) { [void]$d.Add("~ $k") }
        elseif ($Depois[$k].Escrito -ne $Antes[$k].Escrito) { [void]$d.Add("t $k (mtime)") }
    }
    foreach ($k in $Depois.Keys) { if (-not $Antes.ContainsKey($k)) { [void]$d.Add("+ $k") } }
    return , @($d)
}

# Leitor de .ini so para ASSERIR. Nao e a rotina do produto: o produto edita
# preservando bytes, este aqui so le valor de chave (C.2).
function ValorChave {
    param([string]$Arquivo, [string]$Chave)   # Chave = 'secao/nome'
    if (-not (Test-Path -LiteralPath $Arquivo)) { return $null }
    $sec = ''
    foreach ($linha in (Get-Content -LiteralPath $Arquivo -Encoding UTF8)) {
        if ($linha -match '^\s*\[(.+)\]\s*$') { $sec = $Matches[1].Trim(); continue }
        if ($linha -match '^\s*[;#]') { continue }
        if ($linha -match '^([^=\[\]]+?)=(.*)$') {
            if ("$sec/$($Matches[1].Trim())" -eq $Chave) { return $Matches[2] }
        }
    }
    return $null
}

function PoeChave {
    param([string]$Arquivo, [string]$Chave, [string]$Valor)
    $sec, $nome = $Chave -split '/', 2
    $linhas = New-Object System.Collections.ArrayList
    $secAtual = ''; $achou = $false; $fimDaSecao = -1
    foreach ($l in (Get-Content -LiteralPath $Arquivo -Encoding UTF8)) {
        [void]$linhas.Add($l)
        if ($l -match '^\s*\[(.+)\]\s*$') { $secAtual = $Matches[1].Trim(); if ($secAtual -eq $sec) { $fimDaSecao = $linhas.Count - 1 }; continue }
        if ($secAtual -eq $sec -and $l -match '^([^=\[\]]+?)=(.*)$' -and $Matches[1].Trim() -eq $nome) {
            $linhas[$linhas.Count - 1] = "$nome=$Valor"; $achou = $true
        }
        if ($secAtual -eq $sec) { $fimDaSecao = $linhas.Count - 1 }
    }
    if (-not $achou) {
        if ($fimDaSecao -ge 0) { $linhas.Insert($fimDaSecao + 1, "$nome=$Valor") }
        else { [void]$linhas.Add("[$sec]"); [void]$linhas.Add("$nome=$Valor") }
    }
    Set-Content -LiteralPath $Arquivo -Value @($linhas) -Encoding UTF8
}

# Materializa o template de um commit REAL da historia. E a fonte dos perfis
# velhos (E.1): nada e editado a mao.
function TemplateDoCommit {
    param([string]$Commit, [string]$Destino)
    if (Test-Path -LiteralPath $Destino) { Remove-Item -LiteralPath $Destino -Recurse -Force }
    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
    ExtraiDoGit $Commit 'app/profile-template/iman-distro' $Destino
    $t = Join-Path $Destino 'app\profile-template\iman-distro'
    LimpaIgnorados $t
    return $t
}

# Variante do template ATUAL, para os estados em que o produto precisa ter
# mudado DEPOIS da base. O HEAD e o template mais novo que existe, entao "o
# produto mudou" so se constroi para frente - e a variante e sintetica de
# proposito, com o mesmo conjunto de arquivos que a declaracao cobre.
#
# A PASTA TEM DE SE CHAMAR 'iman-distro': o launcher monta o caminho do
# template como <APP_HOME>\profile-template\%PROFILE_NAME%. Com outro nome ele
# nao acha o template e a reconciliacao falha - foi o que aconteceu na primeira
# rodada desta guarda, em 2026-09-16, e os estados 6, 8 e 11 sairam FALHOU.
function TemplateVariante {
    param([string]$Raiz, [string]$Nome)
    $dir = Join-Path $Raiz $Nome
    if (Test-Path -LiteralPath $dir) { Remove-Item -LiteralPath $dir -Recurse -Force }
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $t = Join-Path $dir 'iman-distro'
    Copy-Item -LiteralPath $TemplateRepo -Destination $t -Recurse -Force
    LimpaIgnorados $t
    return $t
}

# APP_HOME de mentira, com o conteudo de verdade: o launcher sob teste, o
# Sync-Perfil.ps1 do MESMO lugar de onde o launcher veio, a arvore do QGIS por
# JUNCTION (2,2 GB copiados por estado tornariam a guarda cara demais para
# alguem rodar) e o template que este "build" embarca.
function NovoAppHome {
    param([string]$Raiz, [string]$Template)
    $app = Join-Path $Raiz 'app'
    $qgis = Join-Path $app 'qgis'
    if (Test-Path -LiteralPath $qgis) { [System.IO.Directory]::Delete($qgis, $false) }
    if (Test-Path -LiteralPath $Raiz) { Remove-Item -LiteralPath $Raiz -Recurse -Force }
    New-Item -ItemType Directory -Path (Join-Path $app 'launcher') -Force | Out-Null
    Copy-Item -Path (Join-Path $pastaLauncher '*') -Destination (Join-Path $app 'launcher') -Recurse -Force
    Copy-Item -LiteralPath $Manifesto -Destination (Join-Path $app 'qgis-manifest.txt') -Force
    New-Item -ItemType Directory -Path (Join-Path $app 'profile-template') -Force | Out-Null
    Copy-Item -LiteralPath $Template -Destination (Join-Path $app 'profile-template') -Recurse -Force
    Copy-Item -LiteralPath $DeclaracaoRepo -Destination (Join-Path $app 'profile-template') -Force
    LimpaIgnorados (Join-Path $app 'profile-template')
    New-Item -ItemType Junction -Path $qgis -Target $Arvore | Out-Null
    return $app
}

function PerfilDe { param([string]$Raiz) Join-Path $Raiz 'appdata\InstitutoIMAN\IMAN Terra\profiles\iman-distro' }

# O o4w_env.bat deriva OSGEO4W_ROOT em forma 8.3 (%~fsi), entao o executavel do
# processo chega ENCURTADO: medido nesta bancada em 2026-09-16, um QGIS subido de
# C:\_imant30i\e01 aparece como C:\_IMANT~2\e01pp\qgisin\qgis-ltr-bin.exe.
# Comparar so a forma longa nao acha nada - e foi por isso que a primeira rodada
# vermelha travou: o cao de guarda procurava um caminho que nunca apareceria.
function FormaCurta { param([string]$Caminho)
    if (-not $Caminho) { return '' }
    try { return (New-Object -ComObject Scripting.FileSystemObject).GetFolder($Caminho).ShortPath }
    catch { return $Caminho }
}
function EhDoSandbox {
    param([string]$Exe, [string]$Raiz, [string]$RaizCurta)
    if (-not $Exe) { return $false }
    $e = $Exe.ToLower()
    if ($e.StartsWith($Raiz.ToLower())) { return $true }
    if ($RaizCurta -and $e.StartsWith($RaizCurta.ToLower())) { return $true }
    return $false
}

# Mata QGIS que tenha subido DESTE sandbox. So o deste: um qgis-ltr-bin de
# outra origem na bancada nao e nosso para matar.
function MataQgisDoSandbox {
    param([string]$Raiz, [int]$Segundos = 1)
    $curta = FormaCurta $Raiz
    $fim = (Get-Date).AddSeconds($Segundos)
    do {
        foreach ($proc in @(Get-CimInstance Win32_Process -Filter "Name='qgis-ltr-bin.exe'" -ErrorAction SilentlyContinue)) {
            if (EhDoSandbox ([string]$proc.ExecutablePath) $Raiz $curta) {
                Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
            }
        }
        Start-Sleep -Milliseconds 200
    } while ((Get-Date) -lt $fim)
}

# Roda O LAUNCHER DE VERDADE, com %APPDATA% redirecionado (Passo 0).
#
# NAO-BLOQUEANTE DE PROPOSITO, e a razao e a adulteracao inversa. O launcher
# de ANTES desta fatia nao conhece RECONCILE_ONLY: ele abre o QGIS de verdade,
# e o `call "%QGIS_BAT%"` dele SO RETORNA QUANDO O QGIS FECHA. Medido nesta
# bancada em 2026-09-16: com a chamada sincrona, a rodada vermelha travou no
# primeiro estado, esperando para sempre por uma janela que ninguem ia fechar -
# e o cao de guarda que derrubaria o QGIS so rodaria DEPOIS, isto e, nunca.
#
# Entao o launcher sobe destacado, e o QGIS deste sandbox e derrubado ENQUANTO
# ele roda. O que o launcher velho faz ao perfil (nada, quando o perfil ja
# existe) ja aconteceu nessa hora: a copia vinha ANTES do `call`.
function RodaLauncher {
    param([string]$App, [string]$Raiz, [int]$MataPor = 0, [int]$Limite = 180)
    $bat = Join-Path $App 'launcher\IMAN-Terra.bat'
    $log = Join-Path $Raiz '_launcher.out'
    $envolucro = Join-Path $Raiz '_roda.cmd'
    # `echo.` alimenta o `pause` dos caminhos de recusa; sem isso trava.
    Set-Content -LiteralPath $envolucro -Encoding ASCII -Value @(
        '@echo off',
        ('echo.| "' + $bat + '" > "' + $log + '" 2>&1'),
        'exit /b %ERRORLEVEL%')
    $appdataAntes = $env:APPDATA
    $env:APPDATA = Join-Path $Raiz 'appdata'
    $env:IMAN_TERRA_RECONCILE_ONLY = '1'
    # S.5: a arvore do QGIS entra por JUNCTION, entao tudo que o processo
    # escrever "dentro do sandbox" cai na arvore de origem, compartilhada, de
    # onde o proximo build empacota. O launcher de antes desta fatia abre o
    # QGIS de verdade, e o Python dele grava __pycache__ na arvore. Isto o
    # impede na fonte, em vez de limpar depois.
    $env:PYTHONDONTWRITEBYTECODE = '1'
    try {
        $proc = Start-Process -FilePath $envolucro -PassThru -WindowStyle Hidden
    } finally {
        $env:APPDATA = $appdataAntes
        Remove-Item Env:\IMAN_TERRA_RECONCILE_ONLY -ErrorAction SilentlyContinue
        Remove-Item Env:\PYTHONDONTWRITEBYTECODE -ErrorAction SilentlyContinue
    }
    $fim = (Get-Date).AddSeconds($Limite)
    while (-not $proc.HasExited -and (Get-Date) -lt $fim) {
        if ($MataPor -gt 0) { MataQgisDoSandbox $Raiz 0 }
        Start-Sleep -Milliseconds 200
    }
    if (-not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        $codigo = 999                      # nao e sucesso, e nao e silencio
    } else {
        $codigo = $proc.ExitCode
    }
    if ($MataPor -gt 0) { MataQgisDoSandbox $Raiz 1 }
    # O log foi escrito pelo cmd.exe, na CODEPAGE DO CONSOLE (850 nesta
    # bancada), nao na ANSI que o Get-Content assume. Lendo como ANSI, os
    # acentos da mensagem de erro do Windows saem trocados - e a saida crua
    # deste arquivo e evidencia de laudo, entao ela tem de sair como saiu.
    $saida = ''
    if (Test-Path -LiteralPath $log) {
        try {
            $saida = [System.IO.File]::ReadAllText($log, [System.Text.Encoding]::GetEncoding([Console]::OutputEncoding.CodePage))
        } catch {
            $saida = (Get-Content -LiteralPath $log -Raw -ErrorAction SilentlyContinue)
        }
    }
    if ($codigo -eq 999) { $saida += "`r`n[a guarda derrubou o launcher depois de $Limite s]" }
    return @{ Saida = [string]$saida; Codigo = $codigo }
}

# Uma linha que resume a rodada - com o DETALHE junto, senao um FALHOU sai sem
# dizer por que e o diagnostico vira adivinhacao.
function Resumo {
    param($R)
    $t = ("exit={0}  RECONCILIACAO={1}  {2}" -f $R.Codigo, (Campo $R.Saida 'RECONCILIACAO'), (Campo $R.Saida 'PLANO'))
    $d = Campo $R.Saida 'DETALHE'
    if ($d) { $t += ("  DETALHE: " + $d) }
    return $t
}

function Campo {
    param([string]$Saida, [string]$Nome)
    $m = [regex]::Match($Saida, ('(?m)^' + [regex]::Escape($Nome) + '=(.*)$'))
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return ''
}

# ==========================================================================
#  placar
# ==========================================================================
$resultados = New-Object System.Collections.ArrayList
$script:AbortouE1 = $false

function Registra {
    param([int]$Id, [string]$Titulo, [string]$Veredito, [string[]]$Provas, [string]$Cru = '')
    [void]$resultados.Add([pscustomobject]@{
        Id = $Id; Titulo = $Titulo; Veredito = $Veredito; Provas = @($Provas); Cru = $Cru })
    $cor = switch ($Veredito) { 'PASS' { 'Green' } 'FAIL' { 'Red' } 'ABORTADO' { 'Magenta' } default { 'DarkYellow' } }
    Escreve ("  [{0}] estado {1} - {2}" -f $Veredito, $Id, $Titulo) $cor
    foreach ($p in $Provas) { Escreve ("        {0}" -f $p) 'DarkGray' }
}

# E.1: o baseline TEM de diferir naquilo que a rodada assere.
function ExigeDiferenca {
    param([int]$Id, [string]$Titulo, [hashtable]$Checagens)
    $ruins = @()
    foreach ($k in $Checagens.Keys) { if (-not $Checagens[$k]) { $ruins += $k } }
    if ($ruins.Count -gt 0) {
        $script:AbortouE1 = $true
        Registra $Id $Titulo 'ABORTADO' @(("E.1: o perfil semeado JA sai igual ao esperado em: " + ($ruins -join '; ') +
                                           " - a rodada nao provaria nada"))
        return $false
    }
    return $true
}

$listaEstados = @($Estados -split '[,;\s]+' | Where-Object { $_ } | ForEach-Object { [int]$_ })
function Rodar { param([int]$Id) return ($listaEstados.Count -eq 0 -or $listaEstados -contains $Id) }

# Raios de 5 a 8 px x raios de 2 px: e o sinal visivel da fatia #022 no tema.
function ContaRaios {
    param([string]$Qss, [int]$Px)
    if (-not (Test-Path -LiteralPath $Qss)) { return -1 }
    return @([regex]::Matches((Get-Content -LiteralPath $Qss -Raw), ('[a-z-]*radius:\s*' + $Px + 'px'))).Count
}

$hashTemplate = @{}
foreach ($f in (Get-ChildItem -LiteralPath $TemplateRepo -Recurse -File -Force)) {
    $rel = $f.FullName.Substring($TemplateRepo.Length + 1) -replace '\\', '/'
    if ($rel -match '(^|/)__pycache__/' -or $rel -like '*.pyc' -or $rel -like '*.gitkeep') { continue }
    $hashTemplate[$rel] = Sha $f.FullName
}

# ==========================================================================
#  R8 (BL-3): %APPDATA%\QGIS intacto, MD5 por arquivo, antes e depois.
# ==========================================================================
#
#  Duas raizes, e a segunda nao e luxo:
#    %APPDATA%\QGIS                        - o perfil do QGIS do usuario (BL-3).
#                                            NESTA bancada ele esta VAZIO (nao ha
#                                            QGIS de sistema desde a via A1), entao
#                                            sozinho ele provaria pouco.
#    %APPDATA%\InstitutoIMAN\IMAN Terra    - o perfil REAL do sponsor, que ESTA em
#                                            uso e e exatamente o que o Passo 0
#                                            manda nao encostar. Este tem conteudo.
$RaizesIntocaveis = @(
    (Join-Path $env:APPDATA 'QGIS'),
    (Join-Path $env:APPDATA 'InstitutoIMAN')
)
function SnapshotQgisDoUsuario {
    $h = [ordered]@{}
    foreach ($raiz in $RaizesIntocaveis) {
        if (-not (Test-Path -LiteralPath $raiz)) { continue }
        foreach ($f in (Get-ChildItem -LiteralPath $raiz -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            try { $h[$f.FullName] = (Get-FileHash -LiteralPath $f.FullName -Algorithm MD5).Hash } catch { }
        }
    }
    return $h
}
# ==========================================================================
#  S.5 - A ARVORE DE ORIGEM E COMPARTILHADA, e o QGIS ESCREVE NELA.
#
#  MEDIDO nesta bancada em 2026-09-16: o estado 10 sobe um QGIS de verdade
#  atraves da junction, e o Python dele grava __pycache__ DENTRO da arvore
#  estagiada - 836 arquivos .pyc numa passada. A junction e o alvo, entao a
#  escrita cai em installer\stage\, que e de onde o build.ps1 -ReusarArvore
#  empacota. Uma guarda que suja a fonte do proximo build nao e guarda.
#
#  Entao a hora de inicio e registrada, e no fim saem os .pyc que NASCERAM
#  durante esta suite - e so eles, e so .pyc. O que ja estava la fica.
$inicioSuite = Get-Date
$qgisUsuarioAntes = SnapshotQgisDoUsuario
foreach ($raiz in $RaizesIntocaveis) {
    $n = @($qgisUsuarioAntes.Keys | Where-Object { $_.ToLower().StartsWith($raiz.ToLower()) }).Count
    Escreve ("  BL-3/Passo 0: {0} - {1} arquivo(s), MD5 tirado antes da suite" -f $raiz, $n)
}
Escreve ''

# ==========================================================================
#  ESTADO 1 - perfil ausente (primeiro uso)
# ==========================================================================
if (Rodar 1) {
    $raiz = Join-Path $Sandbox 'e01'
    $app = NovoAppHome $raiz $TemplateRepo
    $perfil = PerfilDe $raiz
    $r = RodaLauncher $app $raiz 12
    $provas = @()
    $ok = ($r.Codigo -eq 0)
    $provas += (Resumo $r)
    $faltando = @()
    foreach ($rel in $hashTemplate.Keys) {
        $alvo = Join-Path $perfil ($rel -replace '/', '\')
        if (-not (Test-Path -LiteralPath $alvo)) { $faltando += "$rel (ausente)" }
        elseif ((Sha $alvo) -ne $hashTemplate[$rel]) { $faltando += "$rel (hash)" }
    }
    $ok = $ok -and ($faltando.Count -eq 0)
    $provas += ("{0} de {1} arquivos do template com SHA-256 identico no perfil" -f ($hashTemplate.Count - $faltando.Count), $hashTemplate.Count)
    if ($faltando.Count -gt 0) { $provas += ("divergentes: " + ($faltando -join ', ')) }
    $baseArq = Join-Path $perfil '.iman-terra\base.json'
    $temBase = Test-Path -LiteralPath $baseArq
    $ok = $ok -and $temBase
    $provas += ("base registrada: {0}" -f $temBase)
    if ($temBase) {
        $b = Get-Content -LiteralPath $baseArq -Raw -Encoding UTF8 | ConvertFrom-Json
        $provas += ("  template_digest={0}  chaves={1}" -f $b.template_digest.Substring(0, 16), @($b.chaves.PSObject.Properties).Count)
    }
    Registra 1 'perfil ausente -> perfil igual ao template, base registrada' $(if ($ok) { 'PASS' } else { 'FAIL' }) $provas $r.Saida
}

# ==========================================================================
#  ESTADO 2 - perfil ja igual ao template atual: NADA e escrito (R5)
# ==========================================================================
if (Rodar 2) {
    $raiz = Join-Path $Sandbox 'e02'
    $app = NovoAppHome $raiz $TemplateRepo
    $perfil = PerfilDe $raiz
    $r1 = RodaLauncher $app $raiz 12
    $antes = Instantaneo $perfil
    Start-Sleep -Milliseconds 1100      # mtime tem resolucao: a pausa garante
                                        # que uma reescrita APARECERIA.
    $r2 = RodaLauncher $app $raiz 12
    $depois = Instantaneo $perfil
    $dif = DiferencaInstantaneo $antes $depois
    $ok = ($r2.Codigo -eq 0) -and ((Campo $r2.Saida 'RECONCILIACAO') -eq 'NADA_A_FAZER') -and ($dif.Count -eq 0)
    $provas = @(
        ("1a: {0}  2a: {1}" -f (Campo $r1.Saida 'RECONCILIACAO'), (Campo $r2.Saida 'RECONCILIACAO')),
        ("{0} arquivos no perfil; {1} diferenca(s) de SHA-256 ou mtime entre as duas aberturas" -f $antes.Count, $dif.Count),
        ("custo da abertura sem nada a fazer: {0} ms na rotina de reconciliacao" -f (Campo $r2.Saida 'MS'))
    )
    if ($dif.Count -gt 0) { $provas += ("escreveu: " + ($dif -join ', ')) }
    Registra 2 'perfil ja igual -> nada escrito (R5)' $(if ($ok) { 'PASS' } else { 'FAIL' }) $provas $r2.Saida
}

# ==========================================================================
#  ESTADO 3 - perfil de template ANTERIOR ao #022 (ba58d14)
# ==========================================================================
if (Rodar 3) {
    $raiz = Join-Path $Sandbox 'e03'
    $app = NovoAppHome $raiz $TemplateRepo
    $perfil = PerfilDe $raiz
    $velho = TemplateDoCommit 'ba58d14' (Join-Path $raiz '_t-ba58d14')
    New-Item -ItemType Directory -Path $perfil -Force | Out-Null
    Copy-Item -Path (Join-Path $velho '*') -Destination $perfil -Recurse -Force
    $qss = Join-Path $perfil 'themes\IMAN Terra\style.qss'
    $plugin = Join-Path $perfil 'python\plugins\iman_brand\iman_brand.py'
    $raios58 = (ContaRaios $qss 5) + (ContaRaios $qss 6) + (ContaRaios $qss 7) + (ContaRaios $qss 8)
    $menu6x12 = @(Select-String -LiteralPath $qss -Pattern 'QMenuBar::item \{[^}]*padding:\s*6px 12px').Count
    $sufixoAntes = @(Select-String -LiteralPath $plugin -Pattern '_RE_SUFIXO_DO_QGIS').Count
    $seguir = ExigeDiferenca 3 'perfil de template anterior ao #022' @{
        'raios de 5 a 8 px no perfil semeado' = ($raios58 -eq 14)
        'QMenuBar::item 6px 12px'             = ($menu6x12 -eq 1)
        '_RE_SUFIXO_DO_QGIS ausente'          = ($sufixoAntes -eq 0)
    }
    if ($seguir) {
        $r = RodaLauncher $app $raiz 12
        $raios2 = (ContaRaios $qss 2)
        $raios58d = (ContaRaios $qss 5) + (ContaRaios $qss 6) + (ContaRaios $qss 7) + (ContaRaios $qss 8)
        $menu3x4 = @(Select-String -LiteralPath $qss -Pattern 'QMenuBar::item \{[^}]*padding:\s*3px 4px').Count
        $sufixoDepois = @(Select-String -LiteralPath $plugin -Pattern '_RE_SUFIXO_DO_QGIS').Count
        $divergentes = @()
        foreach ($rel in $hashTemplate.Keys) {
            $alvo = Join-Path $perfil ($rel -replace '/', '\')
            if (-not (Test-Path -LiteralPath $alvo)) { $divergentes += "$rel (ausente)" }
            elseif ((Sha $alvo) -ne $hashTemplate[$rel]) { $divergentes += "$rel (hash)" }
        }
        $ok = ($r.Codigo -eq 0) -and ($divergentes.Count -eq 0) -and ($raios2 -eq 20) -and
              ($raios58d -eq 0) -and ($menu3x4 -eq 1) -and ($sufixoDepois -eq 3)
        Registra 3 'perfil de template anterior ao #022 -> tema e plugin novos chegam' $(if ($ok) { 'PASS' } else { 'FAIL' }) @(
            (Resumo $r),
            ("raios: 5-8px {0} -> {1}   2px -> {2} (template tem 20)" -f $raios58, $raios58d, $raios2),
            ("QMenuBar::item: 6px 12px -> 3px 4px? {0}" -f ($menu3x4 -eq 1)),
            ("_RE_SUFIXO_DO_QGIS em iman_brand.py: {0} -> {1} (template tem 3)" -f $sufixoAntes, $sufixoDepois),
            ("arquivos do produto com SHA-256 do template: {0} de {1}" -f ($hashTemplate.Count - $divergentes.Count), $hashTemplate.Count)
        ) $r.Saida
    }
}

# ==========================================================================
#  ESTADO 4 - perfil de template ANTERIOR a 2026-07-07 (8cc4d5e^)
# ==========================================================================
if (Rodar 4) {
    $raiz = Join-Path $Sandbox 'e04'
    $app = NovoAppHome $raiz $TemplateRepo
    $perfil = PerfilDe $raiz
    $velho = TemplateDoCommit '8cc4d5e^' (Join-Path $raiz '_t-pre0707')
    New-Item -ItemType Directory -Path $perfil -Force | Out-Null
    Copy-Item -Path (Join-Path $velho '*') -Destination $perfil -Recurse -Force
    $obsA = Join-Path $perfil 'QGIS\iman-theme.qss'
    $obsB = Join-Path $perfil 'python\plugins\iman_brand\resources\logo.png'
    $ini = Join-Path $perfil 'QGIS\QGIS3.ini'
    $crsAntes = ValorChave $ini 'app/projections\defaultProjectCrs'
    $seguir = ExigeDiferenca 4 'perfil de template anterior a 07-07' @{
        'QGIS/iman-theme.qss presente no perfil semeado'   = (Test-Path -LiteralPath $obsA)
        'resources/logo.png presente no perfil semeado'    = (Test-Path -LiteralPath $obsB)
        'CRS padrao EPSG:4674 no perfil semeado'           = ($crsAntes -eq 'EPSG:4674')
    }
    if ($seguir) {
        $r = RodaLauncher $app $raiz 12
        $crsDepois = ValorChave $ini 'app/projections\defaultProjectCrs'
        $camadaDepois = ValorChave $ini 'app/projections\layerDefaultCrs'
        $uiDepois = ValorChave $ini 'UI/Customization\enabled'
        $ok = ($r.Codigo -eq 0) -and (-not (Test-Path -LiteralPath $obsA)) -and (-not (Test-Path -LiteralPath $obsB)) -and
              ($crsDepois -eq 'EPSG:31984') -and ($camadaDepois -eq 'EPSG:31984') -and ($uiDepois -eq 'true')
        Registra 4 'perfil anterior a 07-07 -> obsoletos saem, CRS corrige' $(if ($ok) { 'PASS' } else { 'FAIL' }) @(
            (Resumo $r),
            ("QGIS/iman-theme.qss     : presente -> {0}" -f (Test-Path -LiteralPath $obsA)),
            ("resources/logo.png      : presente -> {0}" -f (Test-Path -LiteralPath $obsB)),
            ("defaultProjectCrs       : {0} -> {1}" -f $crsAntes, $crsDepois),
            ("layerDefaultCrs         : -> {0}" -f $camadaDepois),
            ("[UI] Customization/enabled (secao que nem existia): -> {0}" -f $uiDepois)
        ) $r.Saida
    }
}

# ==========================================================================
#  ESTADOS 5, 6, 7, 8 - todos precisam de uma BASE registrada, e a base so
#  nasce de uma reconciliacao que terminou. Por isso os quatro partem de um
#  perfil velho REAL (ba58d14) JA reconciliado uma vez.
# ==========================================================================
function BaseParaTresVias {
    param([string]$Raiz)
    $app = NovoAppHome $Raiz $TemplateRepo
    $perfil = PerfilDe $Raiz
    $velho = TemplateDoCommit 'ba58d14' (Join-Path $Raiz '_t-ba58d14')
    New-Item -ItemType Directory -Path $perfil -Force | Out-Null
    Copy-Item -Path (Join-Path $velho '*') -Destination $perfil -Recurse -Force
    $r = RodaLauncher $app $Raiz 12
    if ($r.Codigo -ne 0) { throw "preparo da base falhou: $($r.Saida)" }
    return @{ App = $app; Perfil = $perfil }
}

if (Rodar 5) {
    $raiz = Join-Path $Sandbox 'e05'
    $c = BaseParaTresVias $raiz
    $ini = Join-Path $c.Perfil 'QGIS\QGIS3.ini'
    # showTips: o template declara false desde 536ad70 e NUNCA mudou. Se o
    # usuario liga, e escolha dele sobre uma chave que o produto nao mexeu.
    PoeChave $ini 'qgis/showTips' 'true'
    $seguir = ExigeDiferenca 5 'usuario mudou chave que o produto nao mudou' @{
        'showTips do usuario difere do template' = ((ValorChave $ini 'qgis/showTips') -eq 'true')
    }
    if ($seguir) {
        $r = RodaLauncher $c.App $raiz 12
        $depois = ValorChave $ini 'qgis/showTips'
        $ok = ($r.Codigo -eq 0) -and ($depois -eq 'true')
        Registra 5 'chave do usuario que o produto nao mudou -> a do usuario fica' $(if ($ok) { 'PASS' } else { 'FAIL' }) @(
            (Resumo $r),
            ("[qgis] showTips: template=false  usuario=true  depois={0}" -f $depois)
        ) $r.Saida
    }
}

if (Rodar 6) {
    $raiz = Join-Path $Sandbox 'e06'
    $c = BaseParaTresVias $raiz
    $ini = Join-Path $c.Perfil 'QGIS\QGIS3.ini'
    # O usuario troca o CRS padrao; e o produto tambem, no template seguinte.
    PoeChave $ini 'app/projections\defaultProjectCrs' 'EPSG:4326'
    # Template seguinte = o atual com o CRS movido para a zona vizinha. E
    # sintetico de proposito: HEAD e o template mais novo que existe, entao
    # "o produto mudou depois da base" so se constroi para frente.
    $t2 = TemplateVariante $raiz '_t-crs-novo'
    $iniT2 = Join-Path $t2 'QGIS\QGIS3.ini'
    PoeChave $iniT2 'app/projections\defaultProjectCrs' 'EPSG:31985'
    $app2 = NovoAppHome (Join-Path $raiz 'v2') $t2
    $perfil2 = PerfilDe (Join-Path $raiz 'v2')
    New-Item -ItemType Directory -Path (Split-Path -Parent $perfil2) -Force | Out-Null
    Copy-Item -LiteralPath $c.Perfil -Destination $perfil2 -Recurse -Force
    $ini2 = Join-Path $perfil2 'QGIS\QGIS3.ini'
    $seguir = ExigeDiferenca 6 'usuario e produto mudaram a mesma chave' @{
        'usuario pos EPSG:4326'         = ((ValorChave $ini2 'app/projections\defaultProjectCrs') -eq 'EPSG:4326')
        'template novo traz EPSG:31985' = ((ValorChave $iniT2 'app/projections\defaultProjectCrs') -eq 'EPSG:31985')
    }
    if ($seguir) {
        $r = RodaLauncher $app2 (Join-Path $raiz 'v2') 12
        $depois = ValorChave $ini2 'app/projections\defaultProjectCrs'
        $ok = ($r.Codigo -eq 0) -and ($depois -eq 'EPSG:31985')
        Registra 6 'usuario e produto mudaram a mesma chave -> o produto vence' $(if ($ok) { 'PASS' } else { 'FAIL' }) @(
            (Resumo $r),
            ("defaultProjectCrs: base=EPSG:31984  usuario=EPSG:4326  template=EPSG:31985  depois={0}" -f $depois)
        ) $r.Saida
    }
}

if (Rodar 7) {
    $raiz = Join-Path $Sandbox 'e07'
    $c = BaseParaTresVias $raiz
    $ini = Join-Path $c.Perfil 'QGIS\QGIS3.ini'
    # Plugin do usuario: pasta dele em python/plugins, ao lado do iman_brand,
    # e a chave [PythonPlugins] dele. Nada disso e nosso.
    $dele = Join-Path $c.Perfil 'python\plugins\plugin_do_usuario'
    New-Item -ItemType Directory -Path $dele -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dele '__init__.py') -Value 'def classFactory(iface): return None' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $dele 'metadata.txt') -Value "[general]`nname=Plugin do usuario" -Encoding UTF8
    New-Item -ItemType Directory -Path (Join-Path $dele 'dados') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dele 'dados\lote.csv') -Value 'id,area' -Encoding UTF8
    PoeChave $ini 'PythonPlugins/plugin_do_usuario' 'true'
    # E um arquivo do usuario dentro de QGIS/, a pasta compartilhada.
    Set-Content -LiteralPath (Join-Path $c.Perfil 'QGIS\bookmarks.xml') -Value '<Bookmarks/>' -Encoding UTF8
    $antes = Instantaneo $dele
    $marcaAntes = Sha (Join-Path $c.Perfil 'QGIS\bookmarks.xml')
    $seguir = ExigeDiferenca 7 'plugin do usuario e a chave dele' @{
        'o plugin do usuario nao esta no template' = (-not (Test-Path -LiteralPath (Join-Path $TemplateRepo 'python\plugins\plugin_do_usuario')))
        'a chave do usuario esta no perfil'        = ((ValorChave $ini 'PythonPlugins/plugin_do_usuario') -eq 'true')
    }
    if ($seguir) {
        $r = RodaLauncher $c.App $raiz 12
        $depois = Instantaneo $dele
        $dif = DiferencaInstantaneo $antes $depois
        $chave = ValorChave $ini 'PythonPlugins/plugin_do_usuario'
        $marcaDepois = Sha (Join-Path $c.Perfil 'QGIS\bookmarks.xml')
        $marca = ValorChave $ini 'PythonPlugins/iman_brand'
        $ok = ($r.Codigo -eq 0) -and ($dif.Count -eq 0) -and ($chave -eq 'true') -and ($marcaAntes -eq $marcaDepois)
        Registra 7 'plugin do usuario e a chave dele -> intactos byte a byte' $(if ($ok) { 'PASS' } else { 'FAIL' }) @(
            (Resumo $r),
            ("{0} arquivos do plugin do usuario, {1} diferenca(s) de SHA-256/mtime" -f $antes.Count, $dif.Count),
            ("[PythonPlugins] plugin_do_usuario={0}   iman_brand={1}" -f $chave, $marca),
            ("QGIS/bookmarks.xml: SHA-256 igual? {0}" -f ($marcaAntes -eq $marcaDepois))
        ) $r.Saida
        if ($dif.Count -gt 0) { $resultados[-1].Provas += ("mexeu: " + ($dif -join ', ')) }
    }
}

if (Rodar 8) {
    $raiz = Join-Path $Sandbox 'e08'
    $c = BaseParaTresVias $raiz
    # Template seguinte ACRESCENTA uma chave. E assim que o iman_plugin=true do
    # DA-3 vai chegar a quem ja instalou - e por isso a chave de teste existe:
    # para provar o mecanismo SEM embarcar o REURB (fora de escopo, P0.7).
    $t2 = TemplateVariante $raiz '_t-chave-nova'
    PoeChave (Join-Path $t2 'QGIS\QGIS3.ini') 'PythonPlugins/iman_teste_db26' 'true'
    $app2 = NovoAppHome (Join-Path $raiz 'v2') $t2
    $perfil2 = PerfilDe (Join-Path $raiz 'v2')
    New-Item -ItemType Directory -Path (Split-Path -Parent $perfil2) -Force | Out-Null
    Copy-Item -LiteralPath $c.Perfil -Destination $perfil2 -Recurse -Force
    $ini2 = Join-Path $perfil2 'QGIS\QGIS3.ini'
    $seguir = ExigeDiferenca 8 'template novo acrescenta uma chave' @{
        'a chave nova NAO esta no perfil velho' = ($null -eq (ValorChave $ini2 'PythonPlugins/iman_teste_db26'))
        'a chave nova esta no template novo'    = ((ValorChave (Join-Path $t2 'QGIS\QGIS3.ini') 'PythonPlugins/iman_teste_db26') -eq 'true')
    }
    if ($seguir) {
        $r = RodaLauncher $app2 (Join-Path $raiz 'v2') 12
        $depois = ValorChave $ini2 'PythonPlugins/iman_teste_db26'
        $ok = ($r.Codigo -eq 0) -and ($depois -eq 'true')
        Registra 8 'chave nova do template -> chega ao perfil velho' $(if ($ok) { 'PASS' } else { 'FAIL' }) @(
            (Resumo $r),
            ("[PythonPlugins] iman_teste_db26: ausente -> {0}" -f $depois)
        ) $r.Saida
    }
}

# ==========================================================================
#  ESTADO 9 - falha induzida NO MEIO da reconciliacao (R6, C.3)
#
#  A inducao e EXTERNA e nao esta commitada em lugar nenhum: um arquivo do
#  produto dentro do perfil e aberto com LOCK EXCLUSIVO enquanto a
#  reconciliacao roda. A copia daquele arquivo estoura, e a rodada morre depois
#  de ja ter mexido em outros. Nenhuma linha do produto foi tocada para isso.
# ==========================================================================
if (Rodar 9) {
    $raiz = Join-Path $Sandbox 'e09'
    $app = NovoAppHome $raiz $TemplateRepo
    $perfil = PerfilDe $raiz
    $velho = TemplateDoCommit 'ba58d14' (Join-Path $raiz '_t-ba58d14')
    New-Item -ItemType Directory -Path $perfil -Force | Out-Null
    Copy-Item -Path (Join-Path $velho '*') -Destination $perfil -Recurse -Force
    $alvo = Join-Path $perfil 'themes\IMAN Terra\style.qss'
    $baseArq = Join-Path $perfil '.iman-terra\base.json'
    $incompletoArq = Join-Path $perfil '.iman-terra\INCOMPLETO.txt'
    $seguir = ExigeDiferenca 9 'falha induzida no meio' @{
        'o perfil velho difere do template'   = ((Sha $alvo) -ne $hashTemplate['themes/IMAN Terra/style.qss'])
        'ainda nao ha base registrada'        = (-not (Test-Path -LiteralPath $baseArq))
    }
    if ($seguir) {
        # LOCK QUE DEIXA LER E NAO DEIXA ESCREVER - acesso Read, share Read.
        #
        # A regra do Windows olha OS DOIS LADOS: o acesso pedido tem de caber no
        # share de quem ja abriu, E o acesso de quem ja abriu tem de caber no
        # share pedido. Medido nesta bancada em 2026-09-16:
        #   acesso None      -> nem o Get-FileHash entra: morre ao montar o PLANO
        #   acesso ReadWrite -> idem (o Write nao cabe no share do Get-FileHash)
        #   acesso Read      -> o hash passa, a COPIA e barrada. E o que se quer.
        #
        # Com ele, o plano sai inteiro, os arquivos do plugin ja foram copiados
        # (a ordem e alfabetica: python/... antes de themes/...) e a copia do
        # style.qss e que estoura - falha NO MEIO, que e o estado do briefing.
        # Nada no produto foi tocado para induzir isto (a inducao nao e
        # commitada em lugar nenhum: ela vive nesta guarda, como lock externo).
        $fs = [IO.File]::Open($alvo, 'Open', 'Read', 'Read')
        try { $r = RodaLauncher $app $raiz 12 } finally { $fs.Close(); $fs.Dispose() }
        $temBase = Test-Path -LiteralPath $baseArq
        $temIncompleto = Test-Path -LiteralPath $incompletoArq
        $recusou = ($r.Codigo -ne 0)
        $disse = ((Campo $r.Saida 'RECONCILIACAO') -eq 'FALHOU')
        # E a prova de que o perfil nao fica meio aplicado passando por
        # atualizado: solto o lock, a abertura seguinte completa sozinha.
        $r2 = RodaLauncher $app $raiz 12
        $sarou = ($r2.Codigo -eq 0) -and ((Sha $alvo) -eq $hashTemplate['themes/IMAN Terra/style.qss']) -and
                 (Test-Path -LiteralPath $baseArq) -and (-not (Test-Path -LiteralPath $incompletoArq))
        $ok = $recusou -and $disse -and (-not $temBase) -and $temIncompleto -and $sarou
        Registra 9 'falha no meio -> fail-loud, e o perfil nao passa por atualizado' $(if ($ok) { 'PASS' } else { 'FAIL' }) @(
            ("exit={0}  RECONCILIACAO={1}" -f $r.Codigo, (Campo $r.Saida 'RECONCILIACAO')),
            ("DETALHE: {0}" -f (Campo $r.Saida 'DETALHE')),
            ("base.json escrita apesar da falha? {0}   INCOMPLETO.txt deixado? {1}" -f $temBase, $temIncompleto),
            ("abertura seguinte, com o lock solto: exit={0} {1} -> perfil completo e base registrada? {2}" -f $r2.Codigo, (Campo $r2.Saida 'RECONCILIACAO'), $sarou)
        ) ($r.Saida + "`n--- abertura seguinte ---`n" + $r2.Saida)
    }
}

# ==========================================================================
#  ESTADO 10 - QGIS ja aberto (R7)
#
#  Sobe o QGIS DE VERDADE a partir da arvore deste sandbox e mede as duas
#  metades do comportamento declarado:
#    a) ha o que aplicar  -> RECUSA (exit 2), e diz para fechar a janela;
#    b) nao ha o que fazer -> a segunda janela abre normalmente.
# ==========================================================================
if (Rodar 10) {
    if ($SemQgis) {
        Registra 10 'QGIS ja aberto' 'N/E' @('-SemQgis pedido: o estado 10 exige subir o QGIS de verdade e nao foi exercitado')
    } else {
        $raiz = Join-Path $Sandbox 'e10'
        $c = BaseParaTresVias $raiz
        $t2 = TemplateVariante $raiz '_t-chave-nova'
        PoeChave (Join-Path $t2 'QGIS\QGIS3.ini') 'PythonPlugins/iman_teste_db26' 'true'
        $raizV2 = Join-Path $raiz 'v2'
        $app2 = NovoAppHome $raizV2 $t2
        $perfil2 = PerfilDe $raizV2
        New-Item -ItemType Directory -Path (Split-Path -Parent $perfil2) -Force | Out-Null
        Copy-Item -LiteralPath $c.Perfil -Destination $perfil2 -Recurse -Force

        $qgisBat = Join-Path $app2 'qgis\bin\qgis-ltr.bat'
        $perfilRaiz = Join-Path $raizV2 'appdata\InstitutoIMAN\IMAN Terra'
        Escreve '        subindo o QGIS de verdade a partir desta arvore...' 'DarkGray'
        $env:PYTHONDONTWRITEBYTECODE = '1'      # S.5, ver RodaLauncher
        try {
            Start-Process -FilePath $qgisBat -WindowStyle Hidden -ArgumentList @(
                '--profiles-path', "`"$perfilRaiz`"", '--profile', 'iman-distro', '--noversioncheck') | Out-Null
        } finally { Remove-Item Env:\PYTHONDONTWRITEBYTECODE -ErrorAction SilentlyContinue }
        $curtaV2 = FormaCurta $raizV2
        $vivo = $null
        for ($i = 0; $i -lt 120; $i++) {
            Start-Sleep -Milliseconds 500
            $vivo = @(Get-CimInstance Win32_Process -Filter "Name='qgis-ltr-bin.exe'" -ErrorAction SilentlyContinue |
                      Where-Object { EhDoSandbox ([string]$_.ExecutablePath) $raizV2 $curtaV2 }) |
                    Select-Object -First 1
            if ($vivo) { break }
        }
        if (-not $vivo) {
            Registra 10 'QGIS ja aberto' 'FAIL' @('o QGIS desta arvore nao subiu em 60 s: o estado nao pode ser medido, e nao medido nao e PASS')
        } else {
            $chaveAntes = ValorChave (Join-Path $perfil2 'QGIS\QGIS3.ini') 'PythonPlugins/iman_teste_db26'
            $rA = RodaLauncher $app2 $raizV2 0
            $chaveDepois = ValorChave (Join-Path $perfil2 'QGIS\QGIS3.ini') 'PythonPlugins/iman_teste_db26'
            # metade b): sem nada a aplicar, a segunda janela nao e atrapalhada.
            $rB = RodaLauncher $c.App $raiz 0
            MataQgisDoSandbox $raizV2 3
            Start-Sleep -Seconds 2
            $okA = ($rA.Codigo -eq 2) -and ((Campo $rA.Saida 'RECONCILIACAO') -eq 'INSTANCIA_VIVA') -and ($null -eq $chaveDepois)
            $okB = ($rB.Codigo -eq 0)
            Registra 10 'QGIS ja aberto -> recusa quando ha o que aplicar; abre quando nao ha' $(if ($okA -and $okB) { 'PASS' } else { 'FAIL' }) @(
                ("instancia viva: PID {0} em {1}" -f $vivo.ProcessId, $vivo.ExecutablePath),
                ("(a) ha o que aplicar : exit={0}  RECONCILIACAO={1}" -f $rA.Codigo, (Campo $rA.Saida 'RECONCILIACAO')),
                ("    a chave nova NAO foi escrita embaixo da instancia viva: antes={0} depois={1}" -f $chaveAntes, $chaveDepois),
                ("(b) nada a aplicar   : exit={0}  RECONCILIACAO={1}" -f $rB.Codigo, (Campo $rB.Saida 'RECONCILIACAO'))
            ) ($rA.Saida + "`n--- sem nada a aplicar ---`n" + $rB.Saida)
        }
    }
}

# ==========================================================================
#  ESTADO 11 - DOWNGRADE (R10): instalar versao anterior por cima.
#  O template instalado e sempre a verdade. Nao existe "mais novo".
# ==========================================================================
if (Rodar 11) {
    $raiz = Join-Path $Sandbox 'e11'
    $c = BaseParaTresVias $raiz
    # "Versao anterior" = um template DECLARADO cujo conteudo e o de antes:
    # o style.qss de ba58d14 e o CRS de antes de 4dfeb93. Ele tem o mesmo
    # conjunto de arquivos do atual, que e o que um build desta era entregaria.
    $velho = TemplateDoCommit 'ba58d14' (Join-Path $raiz '_t-ba58d14b')
    $t0 = TemplateVariante $raiz '_t-anterior'
    Copy-Item -LiteralPath (Join-Path $velho 'themes\IMAN Terra\style.qss') `
              -Destination (Join-Path $t0 'themes\IMAN Terra\style.qss') -Force
    PoeChave (Join-Path $t0 'QGIS\QGIS3.ini') 'app/projections\defaultProjectCrs' 'EPSG:4674'
    $raizV0 = Join-Path $raiz 'v0'
    $app0 = NovoAppHome $raizV0 $t0
    $perfil0 = PerfilDe $raizV0
    New-Item -ItemType Directory -Path (Split-Path -Parent $perfil0) -Force | Out-Null
    Copy-Item -LiteralPath $c.Perfil -Destination $perfil0 -Recurse -Force
    $qss0 = Join-Path $perfil0 'themes\IMAN Terra\style.qss'
    $ini0 = Join-Path $perfil0 'QGIS\QGIS3.ini'
    $shaAntigo = Sha (Join-Path $t0 'themes\IMAN Terra\style.qss')
    $seguir = ExigeDiferenca 11 'downgrade' @{
        'o perfil esta com o tema NOVO'      = ((Sha $qss0) -eq $hashTemplate['themes/IMAN Terra/style.qss'])
        'o template anterior traz outro tema' = ($shaAntigo -ne $hashTemplate['themes/IMAN Terra/style.qss'])
        'o perfil esta com EPSG:31984'        = ((ValorChave $ini0 'app/projections\defaultProjectCrs') -eq 'EPSG:31984')
    }
    if ($seguir) {
        $r = RodaLauncher $app0 $raizV0 12
        $qssDepois = Sha $qss0
        $crsDepois = ValorChave $ini0 'app/projections\defaultProjectCrs'
        $ok = ($r.Codigo -eq 0) -and ($qssDepois -eq $shaAntigo) -and ($crsDepois -eq 'EPSG:4674')
        Registra 11 'downgrade -> o template anterior vence, nos arquivos e nas chaves' $(if ($ok) { 'PASS' } else { 'FAIL' }) @(
            (Resumo $r),
            ("style.qss: SHA-256 volta ao do template anterior? {0}" -f ($qssDepois -eq $shaAntigo)),
            ("defaultProjectCrs: EPSG:31984 -> {0}" -f $crsDepois)
        ) $r.Saida
    }
}

# ==========================================================================
#  R8 - %APPDATA%\QGIS intacto
# ==========================================================================
$qgisUsuarioDepois = SnapshotQgisDoUsuario
$mexidos = New-Object System.Collections.ArrayList
foreach ($k in $qgisUsuarioAntes.Keys) {
    if (-not $qgisUsuarioDepois.Contains($k)) { [void]$mexidos.Add("- $k") }
    elseif ($qgisUsuarioDepois[$k] -ne $qgisUsuarioAntes[$k]) { [void]$mexidos.Add("~ $k") }
}
foreach ($k in $qgisUsuarioDepois.Keys) { if (-not $qgisUsuarioAntes.Contains($k)) { [void]$mexidos.Add("+ $k") } }
$bl3ok = ($mexidos.Count -eq 0)
Escreve ''
Escreve ("  [{0}] BL-3 (R8) + Passo 0: {1} arquivo(s) intocaveis, {2} diferenca(s) de MD5" -f `
    $(if ($bl3ok) { 'PASS' } else { 'FAIL' }), $qgisUsuarioAntes.Count, $mexidos.Count) $(if ($bl3ok) { 'Green' } else { 'Red' })
foreach ($m in ($mexidos | Select-Object -First 10)) { Escreve "        $m" 'Red' }

# ==========================================================================
#  limpeza: as junctions saem SEM levar a arvore junto, e a arvore de origem
#  volta como estava (S.5).
# ==========================================================================
$pycNovos = @(Get-ChildItem -LiteralPath $Arvore -Recurse -File -Force -Filter '*.pyc' -ErrorAction SilentlyContinue |
              Where-Object { $_.CreationTime -ge $inicioSuite })
foreach ($f in $pycNovos) { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue }
$pycSobrando = @(Get-ChildItem -LiteralPath $Arvore -Recurse -File -Force -Filter '*.pyc' -ErrorAction SilentlyContinue |
                 Where-Object { $_.CreationTime -ge $inicioSuite }).Count
Escreve ("  arvore de origem: {0} .pyc nasceram durante a suite e foram removidos ({1} sobraram)" -f `
    $pycNovos.Count, $pycSobrando) $(if ($pycSobrando -eq 0) { 'Gray' } else { 'Red' })

foreach ($j in @(Get-ChildItem -LiteralPath $Sandbox -Recurse -Directory -Force -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -eq 'qgis' -and $_.Attributes -band [IO.FileAttributes]::ReparsePoint })) {
    [System.IO.Directory]::Delete($j.FullName, $false)
}

# ==========================================================================
#  placar
# ==========================================================================
$exercitados = @($resultados | Where-Object { $_.Veredito -in @('PASS', 'FAIL') })
$falhas = @($resultados | Where-Object { $_.Veredito -eq 'FAIL' })
$abortados = @($resultados | Where-Object { $_.Veredito -eq 'ABORTADO' })
$ne = @($resultados | Where-Object { $_.Veredito -eq 'N/E' })

Escreve ''
Escreve ("  {0} de {1} estados exercitados passaram." -f ($exercitados.Count - $falhas.Count), $exercitados.Count) 'White'
if ($ne.Count -gt 0)        { Escreve ("  {0} estado(s) N/E, nomeados acima." -f $ne.Count) 'DarkYellow' }
if ($abortados.Count -gt 0) { Escreve ("  {0} estado(s) ABORTADOS por E.1 - baseline invalido." -f $abortados.Count) 'Magenta' }

if ($Json) {
    [pscustomobject]@{
        QuandoUtc = (Get-Date).ToUniversalTime().ToString('o')
        Launcher  = $batLauncher
        Rotulo    = $rotuloLauncher
        Ref       = $Ref
        Bl3       = @{ Ok = $bl3ok; Raizes = @($RaizesIntocaveis); Arquivos = $qgisUsuarioAntes.Count; Mexidos = @($mexidos) }
        ArvoreOrigem = @{ Caminho = $Arvore; PycRemovidos = $pycNovos.Count; PycSobrando = $pycSobrando }
        Estados   = @($resultados)
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Json -Encoding UTF8
    Escreve "  JSON: $Json"
}

if ($script:AbortouE1) { exit 2 }
if ($falhas.Count -gt 0 -or -not $bl3ok) {
    Escreve '  A reconciliacao do perfil NAO esta cumprindo o contrato do DB-26.' 'Red'
    exit 1
}
if ($exercitados.Count -eq 0) { Escreve '  Nenhum estado exercitado.' 'Red'; exit 2 }
Escreve '  O perfil de quem ja instalou recebe a versao nova, e o que e do usuario fica.' 'Green'
exit 0
