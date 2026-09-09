<#
=============================================================================
 #017 - orquestrador do TESTE DE ACEITE da camada de marca

 Sobe o PRODUTO REAL (a arvore PRIVADA do QGIS que o produto carrega + perfil
 iman-distro montado do profile-template + iman_startup.py de verdade) e roda
 um script de sonda dentro dele via --code.

 V.5 (#021, Entrega 2) - O ACEITE RODA CONTRA A ARVORE DO PRODUTO.

 Ate a fatia #020 este script subia o QGIS de C:\Program Files\QGIS <versao>.
 Isso criou um LACO na bancada depois da via A1: o harness exigia esse QGIS
 instalado, e installer\New-ArvoreQgis.ps1 exige que ele NAO exista (a extracao
 abre uma transacao do Windows Installer contra o mesmo ProductCode). Instalar
 para testar desarmava o build; desinstalar para buildar desarmava o teste.

 O produto nao precisa de nenhum dos dois - ele carrega o proprio QGIS. Este
 script passa a subir ESSE:

   %LOCALAPPDATA%\Programs\IMAN Terra\qgis\bin\qgis-ltr.bat

 e RECUSA qualquer raiz sob %ProgramFiles% - nao por gosto, mas porque um
 aceite que sobe um QGIS de terceiro mede a bancada, nao o produto.

 Por que o .bat e nao o .exe: e o qgis-ltr.bat que chama o o4w_env.bat, que
 deriva OSGEO4W_ROOT de %~dp0, ZERA o PATH herdado e monta PROJ_DATA/GDAL_DATA/
 PYTHONHOME/QT_PLUGIN_PATH (medido no spike #016). E o MESMO caminho que o
 launcher do produto usa. Chamar o .exe direto subiria sem PROJ nem GDAL.

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

    # Raiz do QGIS a usar. Default: a ARVORE PRIVADA do produto instalado.
    # NAO aceita raiz sob %ProgramFiles% - ver a guarda na secao 1.
    [string]$Qgis = '',

    # Raiz do produto instalado (o pai da arvore do QGIS). Serve para derivar o
    # default de -Qgis e para ler o manifesto de integridade que o acompanha.
    [string]$Produto = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),

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

# O o4w_env.bat deriva OSGEO4W_ROOT em forma 8.3 (`%~fsi`), entao o executavel
# do processo chega como ...\IMANTE~1\qgis\bin\qgis-ltr-bin.exe. Comparar isso
# com o caminho longo por string acusaria "nao e o do produto" numa arvore
# CORRETA. A comparacao e feita na forma curta dos DOIS lados.
function Curto([string]$Caminho) {
    if ([string]::IsNullOrEmpty($Caminho)) { return '' }
    try {
        $fso = New-Object -ComObject Scripting.FileSystemObject
        return $fso.GetFile($Caminho).ShortPath
    } catch {
        return $Caminho
    }
}

Escreve ''
Escreve '  #017 - teste de aceite da camada de marca' 'White'
Escreve ''

# ------------------------------------------ 1. o QGIS: o DO PRODUTO (#021/E2)
if ([string]::IsNullOrEmpty($Qgis)) {
    $Qgis = Join-Path $Produto 'qgis'
}
$Qgis = [IO.Path]::GetFullPath($Qgis)

# GUARDA: nenhum QGIS de sistema em lugar nenhum do caminho. Esta e a assercao
# central da Entrega 2 - sem ela, um dia alguem passa -Qgis apontando para
# Program Files "so para destravar" e o laco volta sem ninguem perceber.
foreach ($proibido in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
    if ($proibido -and $Qgis.ToLower().StartsWith($proibido.ToLower())) {
        throw ("Raiz '$Qgis' cai em '$proibido'. O aceite NAO sobe QGIS de sistema: " +
               "ele mede o produto, e o produto carrega a propria arvore (#021/Entrega 2).")
    }
}

$exe       = Join-Path $Qgis 'bin\qgis-ltr-bin.exe'
$bat       = Join-Path $Qgis 'bin\qgis-ltr.bat'
$manifesto = Join-Path $Produto 'qgis-manifest.txt'

# O E.1 comeca AQUI: sem produto instalado nao ha o que asserir. Abortar e o
# comportamento certo - um aceite que "nao achou o produto e seguiu" mede o nada
# e devolve verde.
if (-not (Test-Path -LiteralPath $exe)) {
    throw ("qgis-ltr-bin.exe nao encontrado em $Qgis.`n" +
           "  O aceite roda contra a arvore do PRODUTO INSTALADO. Instale o IMAN Terra`n" +
           "  (installer\dist\*.exe) ou passe -Produto <raiz do produto>.")
}
if (-not (Test-Path -LiteralPath $bat)) {
    throw "qgis-ltr.bat nao encontrado em $Qgis\bin. A arvore do produto esta incompleta."
}
if (-not (Test-Path -LiteralPath $manifesto)) {
    throw ("qgis-manifest.txt nao encontrado em $Produto. Isso nao e uma instalacao do " +
           "IMAN Terra - o instalador sempre o entrega ao lado da arvore.")
}
$mVersao = Select-String -LiteralPath $manifesto -Pattern '^VERSAO\|(.+)$' | Select-Object -First 1
$mTotal  = Select-String -LiteralPath $manifesto -Pattern '^TOTAL\|(\d+)\|' | Select-Object -First 1
$versaoManifesto = if ($mVersao) { $mVersao.Matches[0].Groups[1].Value.Trim() } else { '?' }
$totalManifesto  = if ($mTotal)  { $mTotal.Matches[0].Groups[1].Value.Trim() }  else { '?' }

Escreve "  produto : $Produto"
Escreve "  QGIS    : $Qgis"
Escreve "            (arvore PRIVADA do produto - nenhum QGIS de sistema no caminho)"
Escreve "  manifesto: QGIS $versaoManifesto, $totalManifesto arquivos"

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

# ------------------- 3.0 SEGUNDO PERFIL: a condicao REAL do produto (#022)
#
# POR QUE O HARNESS PRECISA DE DOIS PERFIS, e por que ter UM escondeu um
# defeito por quatro fatias.
#
# O QGIS so acrescenta " [<perfil>]" ao titulo da janela quando ha MAIS DE UM
# perfil na raiz de perfis. O harness sempre montou UM, entao nunca viu o
# sufixo - e o A05 deu PASS enquanto o produto instalado exibia
# "Projeto sem titulo - QGIS [iman-distro]" na cara do usuario (medido no #021,
# evidencia/aceite-com-dois-perfis.json). A raiz do produto tem dois perfis na
# propria bancada; a do teste tinha um. O teste era mais estreito que o
# produto, e a diferenca era exatamente o defeito.
#
# Este perfil-vizinho e VAZIO e nao e carregado: ele existe para o QGIS
# CONTAR mais de um. E a diferenca entre exercitar o produto e exercitar uma
# versao mais gentil dele.
$perfilVizinho = Join-Path $perfilRaiz 'profiles\_vizinho-so-para-contar'
if (-not (Test-Path -LiteralPath $perfilVizinho)) {
    New-Item -ItemType Directory -Path (Join-Path $perfilVizinho 'QGIS') -Force | Out-Null
}
Set-Content -LiteralPath (Join-Path $perfilVizinho 'QGIS\QGIS3.ini') `
            -Value "[qgis]`nshowTips=false" -Encoding UTF8
$nPerfis = @(Get-ChildItem -LiteralPath (Join-Path $perfilRaiz 'profiles') -Directory).Count
Escreve "  perfis  : $nPerfis na raiz (o QGIS so pendura ' [<perfil>]' com mais de um)"

# ------------------------------- 3.1 SEMENTE DE RECENTE REAL (#021/Entrega 3)
#
# POR QUE ISTO EXISTE. O A08 passou a asserir PROCEDENCIA: todo item exibido em
# "Projetos recentes" corresponde a uma entrada real. Num perfil recem-criado a
# lista do QGIS esta VAZIA, a secao se mostra vazia, e "nenhum item sem
# procedencia" passaria por VACUIDADE - a mesma tautologia que a versao anterior
# da assercao tinha, um nivel acima.
#
# A semente desfaz isso: um projeto que EXISTE no disco entra na lista de
# recentes DO PROPRIO QGIS antes de o produto subir. Dai a assercao pode exigir
# PRESENCA ("o recente semeado chegou a tela") e nao so ausencia de invencao.
#
# A home e construida uma unica vez, no load do plugin - por isso a semente tem
# de estar no .ini ANTES do arranque; semear com o QGIS ja aberto nao apareceria.
$semente = Join-Path $raizRepo 'app\demo\welcome.qgz'
if (-not (Test-Path -LiteralPath $semente)) {
    throw "Projeto da semente nao encontrado: $semente (ele e o demo que o produto instala)."
}
$semente = (Get-Item -LiteralPath $semente).FullName
if (-not $ReusarPerfil) {
    $ini = Join-Path $perfilDir 'QGIS\QGIS3.ini'
    if (-not (Test-Path -LiteralPath $ini)) { throw "QGIS3.ini nao encontrado em $ini" }
    # QSettings/ini: a chave UI/recentProjects/1/path vira 'recentProjects\1\path'
    # dentro da secao [UI]. Barra normal no valor de proposito - e como o QGIS
    # grava, e os dois lados da comparacao normalizam.
    $sementeIni = $semente.Replace('\', '/')
    $linhas = Get-Content -LiteralPath $ini
    $novo = New-Object System.Collections.ArrayList
    foreach ($l in $linhas) {
        [void]$novo.Add($l)
        if ($l.Trim() -eq '[UI]') {
            [void]$novo.Add('; semeado pelo teste de aceite (#021/E3) - projeto REAL, existente em disco')
            [void]$novo.Add("recentProjects\1\path=$sementeIni")
            [void]$novo.Add('recentProjects\1\title=Boas-vindas ao IMAN Terra')
            [void]$novo.Add('recentProjects\1\crs=EPSG:31984')
        }
    }
    Set-Content -LiteralPath $ini -Value $novo -Encoding UTF8
    Escreve "  semente : $semente  (recente REAL na lista do proprio QGIS)"
} else {
    Escreve "  semente : (perfil reaproveitado - a lista de recentes e a que ficou)" 'Yellow'
}

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
# A sonda confere, de DENTRO do processo, que o QGIS que subiu foi este - e nao
# outro que estivesse na maquina. Sem isso, "rodou contra o produto" seria
# afirmacao do orquestrador sobre si mesmo.
$env:SPIKE017_QGIS_ROOT = $Qgis
# #021/E3: o recente REAL semeado. O A08 exige que ele chegue a tela - e o que
# tira a assercao da vacuidade quando a lista de recentes esta vazia.
$env:SPIKE017_RECENTE_SEMEADO = $(if ($ReusarPerfil) { '' } else { $semente })

Escreve "  sonda   : $sondaPath"
Escreve "  startup : $startup  (o de verdade)"
Escreve "  saida   : $saida"
Escreve "  fase    : $Fase"

# --------------------------------------------------------------- 6. executa
$argv = @('--profiles-path', "`"$perfilRaiz`"", '--profile', $Perfil, '--noversioncheck',
          '--code', "`"$sondaPath`"")

# Uma instancia anterior tornaria ambigua a captura do PID - e o PID e o que
# prova, logo adiante, QUAL executavel subiu.
$sobrando = @(Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue)
if ($sobrando.Count -gt 0) {
    throw ("Ja ha $($sobrando.Count) processo(s) qgis-ltr-bin rodando. Feche-os antes: " +
           "o aceite precisa saber qual processo e o dele.")
}

Escreve ''
Escreve "  > qgis-ltr.bat --profiles-path <perfil> --profile $Perfil --noversioncheck --code <sonda>"
# O .bat e quem monta o ambiente OSGeo4W (o4w_env.bat). Ele termina cedo, porque
# a ultima linha dele e `start /B` - entao o processo que interessa e localizado
# DEPOIS, pelo nome, e conferido pelo caminho do executavel.
Start-Process -FilePath $bat -ArgumentList $argv -WindowStyle Hidden | Out-Null

$p = $null
for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Milliseconds 500
    $p = Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p) { break }
}
if (-not $p) { throw "O qgis-ltr.bat nao subiu nenhum qgis-ltr-bin em 30 s. Arvore: $Qgis" }

# PROCEDENCIA DO PROCESSO: nao basta que ALGUM QGIS tenha subido - tem de ser o
# do produto. Este e o numero que sustenta a Entrega 2.
$exeDoProcesso = ''
try { $exeDoProcesso = $p.Path } catch { }
Escreve "  PID $($p.Id) - executavel: $exeDoProcesso"
if ($exeDoProcesso -and ((Curto $exeDoProcesso).ToLower() -ne (Curto $exe).ToLower())) {
    Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    throw ("O processo que subiu NAO e o do produto." +
           "`n  esperado: $exe" +
           "`n  obtido  : $exeDoProcesso")
}
Escreve "  aguardando ate $Espera s pela saida da sonda..."

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
