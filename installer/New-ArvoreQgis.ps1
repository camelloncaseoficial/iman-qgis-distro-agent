<#
=============================================================================
 IMAN Terra - monta a ARVORE PRIVADA do QGIS e o MANIFESTO DE INTEGRIDADE

 Via A1 (D-IMAN-028, emenda 2026-09-06; executavel provado pelo spike #016):
 o QGIS deixa de ser instalado ao lado e passa a viver DENTRO do IMAN Terra.

 O QUE FAZ
   1. confere o payload ja estagiado (SHA-256 vindo do build.ps1);
   2. extrai a arvore com `msiexec /a` - instalacao administrativa, que
      EXTRAI sem instalar e sem elevacao (medido no #016: exit 0, ~300 s,
      37.338 arquivos, 2,23 GB). ATENCAO: ela NAO cria entrada de ARP, mas
      E UMA TRANSACAO REAL do Windows Installer contra o ProductCode do
      QGIS - ver a restricao de bancada logo abaixo;
   3. remove a copia residual do MSI que o /a deixa na raiz do TARGETDIR
      (8,57 MB que nao servem para rodar);
   4. gera o MANIFESTO DE INTEGRIDADE que o launcher confere na maquina do
      usuario ANTES de subir o QGIS.

 POR QUE O MANIFESTO EXISTE - e por que ele nao e burocracia:
   o #016 mediu que a arvore NAO se autodiagnostica. Com `share\proj`
   ausente, o QGIS responde `CRS validos? SAD69=True SIRGAS=True UTM=True` e
   devolve deslocamento de datum de 0,00 m onde o correto sao ~57 m. Uma
   copia truncada nao aparece como erro: aparece como COORDENADA ERRADA num
   memorial descritivo. Num produto de REURB e o defeito mais caro que existe.

 RESTRICAO DE BANCADA - NAO RODAR ONDE O QGIS ESTIVER INSTALADO
   Este script abre uma transacao do Windows Installer contra o MESMO
   ProductCode {740D7A65-CBA3-1014-A0B5-B03A9B7608F5} do QGIS 3.44.13
   oficial. Na sessao do #019, quatro extracoes rodaram numa bancada que
   tinha esse QGIS instalado e, ao fim, a instalacao dele havia sido
   REMOVIDA por uma transacao aberta por outro processo (log de eventos em
   docs/verify/019-a1-qgis-embarcado/README.md, secao 6). A causa nao ficou
   provada - nao ha nenhum `msiexec /x` neste repo - mas a correlacao basta
   para a regra:

     rode este script numa maquina de build SEM o QGIS instalado,
     ou reaproveite a arvore ja extraida com `build.ps1 -ReusarArvore`.

 O QUE ELE NAO FAZ
   nao roda o `etc\postinstall.bat` (o #016 mediu que ele nao e necessario, e
   ele escreveria em HKCR, no diretorio do Windows e no Menu Iniciar); nao
   instala; nao eleva; nao toca C:\Program Files nem %APPDATA%\QGIS.

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Msi,
    [Parameter(Mandatory = $true)][string]$Versao,
    [Parameter(Mandatory = $true)][string]$ShaDoPayload,
    [Parameter(Mandatory = $true)][string]$Destino,
    [string]$Manifesto = '',
    [switch]$Reaproveitar
)

$ErrorActionPreference = 'Stop'

function Passo([string]$T) { Write-Host "    -> $T" -ForegroundColor DarkCyan }
function Ok   ([string]$T) { Write-Host "    OK  $T" -ForegroundColor Green }

if ([string]::IsNullOrWhiteSpace($Manifesto)) {
    $Manifesto = Join-Path (Split-Path -Parent $Destino) 'qgis-manifest.txt'
}

# ---------------------------------------------------------------------------
# AREAS CRITICAS - as seis que o spike #016 mediu como criticas.
#
# DIR  = presenca + CONTAGEM de arquivos (recursiva). Contagem, e nao so
#        "a pasta existe": uma copia truncada deixa a pasta la, com metade
#        dentro. Foi assim que o erro silencioso de PROJ aconteceu.
# FILE = presenca + TAMANHO + SHA-256, conferido NA MAQUINA DO USUARIO
#        (E.5: hash recalculado, nunca transcrito).
# ---------------------------------------------------------------------------
$DirsCriticos = @(
    'share\proj',                 # PROJ: sem ele, deslocamento de datum = 0,00 m
    'apps\qgis-ltr\resources',    # srs.db, symbology, templates
    'apps\Python312',             # PyQGIS inteiro
    'apps\qt5\plugins',           # sem o platform plugin o Qt nem abre
    'apps\gdal\share\gdal'        # GDAL_DATA: EPSG some sem ele
)
$ArquivosCriticos = @(
    'bin\qgis-ltr-bin.exe',       # o executavel
    'share\proj\proj.db'          # a base do PROJ - o coracao do erro silencioso
)

# --------------------------------------------------------------- 1. payload
if (-not (Test-Path -LiteralPath $Msi)) { throw "Payload nao encontrado: $Msi" }
$sha = (Get-FileHash -LiteralPath $Msi -Algorithm SHA256).Hash
if ($sha -ne $ShaDoPayload.ToUpper()) {
    throw "SHA-256 do payload nao confere.`n  esperado: $ShaDoPayload`n  obtido  : $sha"
}
Ok "payload conferido ($sha)"

# --------------------------------------------------------------- 2. destino
$paiDestino = Split-Path -Parent $Destino
foreach ($proibido in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, (Join-Path $env:APPDATA 'QGIS'))) {
    if ($proibido -and $paiDestino.ToLower().StartsWith($proibido.ToLower())) {
        throw "Destino '$Destino' cai em area protegida '$proibido'. Abortado (BL-3)."
    }
}

$jaExiste = (Test-Path -LiteralPath (Join-Path $Destino 'bin\qgis-ltr-bin.exe'))
if ($jaExiste -and $Reaproveitar) {
    Ok "arvore reaproveitada de $Destino (-Reaproveitar)"
} else {
    if (Test-Path -LiteralPath $paiDestino) {
        Passo "limpando a extracao anterior..."
        Remove-Item -LiteralPath $paiDestino -Recurse -Force
    }
    New-Item -ItemType Directory -Path $paiDestino -Force | Out-Null

    # ----------------------------------------------------------- 3. extracao
    # `/a` = instalacao administrativa: extrai a arvore para TARGETDIR sem
    # instalar, sem criar entrada de ARP e SEM ELEVACAO. Medido no #016 - o
    # log traz "MSI_LUA: Credential prompt not required, administrative
    # installation creation or servicing".
    $logMsi = Join-Path $paiDestino 'msiexec-admin-install.log'
    Passo "msiexec /a (extrai, NAO instala) - leva alguns minutos"
    $t0 = Get-Date
    $p = Start-Process -FilePath 'msiexec.exe' -Wait -PassThru -NoNewWindow -ArgumentList @(
        '/a', "`"$Msi`"", '/qn', "TARGETDIR=`"$paiDestino`"", '/L*v', "`"$logMsi`"")
    $dt = (Get-Date) - $t0
    if ($p.ExitCode -ne 0) {
        throw "msiexec /a falhou com exit $($p.ExitCode). Ver $logMsi"
    }
    Ok ("extracao concluida em {0:N1} s (exit 0)" -f $dt.TotalSeconds)

    if (-not (Test-Path -LiteralPath $Destino)) {
        throw "A extracao nao produziu '$Destino'. O /a coloca a arvore em TARGETDIR\QGIS <versao>\."
    }

    # ------------------------------------------------- 4. residuo do proprio /a
    # O /a deixa uma copia do MSI (sem os cabs, ~8,6 MB) na raiz do TARGETDIR.
    # Ela nao serve para rodar e viajaria no instalador.
    foreach ($residuo in (Get-ChildItem -LiteralPath $paiDestino -Filter '*.msi' -File -ErrorAction SilentlyContinue)) {
        Passo ("removendo residuo do /a: {0} ({1:N2} MB)" -f $residuo.Name, ($residuo.Length / 1MB))
        Remove-Item -LiteralPath $residuo.FullName -Force
    }
}

# --------------------------------------------------------- 5. sanidade minima
$exe = Join-Path $Destino 'bin\qgis-ltr-bin.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    throw "A arvore extraida NAO contem bin\qgis-ltr-bin.exe. Ela nao e executavel."
}
foreach ($d in $DirsCriticos) {
    if (-not (Test-Path -LiteralPath (Join-Path $Destino $d))) {
        throw "A arvore extraida NAO contem a area critica '$d'."
    }
}

# ------------------------------------------------------------- 6. manifesto
Passo "gerando o manifesto de integridade"
$linhas = New-Object System.Collections.ArrayList
[void]$linhas.Add('# IMAN Terra - manifesto de integridade da arvore privada do QGIS.')
[void]$linhas.Add('# Gerado por installer\New-ArvoreQgis.ps1. NAO editar a mao.')
[void]$linhas.Add('# O launcher confere este arquivo ANTES de subir o QGIS e RECUSA abrir')
[void]$linhas.Add('# se algo divergir. Motivo (spike #016): sem share\proj o QGIS responde')
[void]$linhas.Add('# "CRS validos" e devolve deslocamento de datum de 0,00 m onde o correto')
[void]$linhas.Add('# sao ~57 m - copia truncada vira coordenada errada, nao mensagem de erro.')
[void]$linhas.Add('#')
[void]$linhas.Add("# Gerado em      : $((Get-Date).ToUniversalTime().ToString('o'))")
[void]$linhas.Add("# Payload origem : $(Split-Path -Leaf $Msi)")
[void]$linhas.Add("# SHA-256 origem : $sha")
[void]$linhas.Add('#')
[void]$linhas.Add("VERSAO|$Versao")

$todos = @(Get-ChildItem -LiteralPath $Destino -Recurse -File -Force -ErrorAction SilentlyContinue)
$bytes = 0
foreach ($f in $todos) { $bytes += $f.Length }
[void]$linhas.Add("TOTAL|$($todos.Count)|$bytes")

# MAXREL - o caminho RELATIVO mais longo da arvore.
#
# POR QUE ISTO ESTA NO MANIFESTO: a verificacao do launcher conta arquivos com
# `dir /s`, que sob o limite classico de 260 caracteres PULA em silencio o que
# nao cabe. Numa instalacao em caminho longo a contagem viria mais baixa e a
# guarda acusaria "copia truncada" numa arvore intacta - um falso positivo que
# impediria o produto de abrir. Com este numero o launcher calcula, ANTES de
# contar, se o caminho de instalacao comporta a arvore, e diz o que realmente
# esta errado em vez de acusar corrupcao.
$corte = $Destino.TrimEnd('\').Length + 1
$maxRel = 0
foreach ($f in $todos) {
    $n = $f.FullName.Length - $corte
    if ($n -gt $maxRel) { $maxRel = $n }
}
[void]$linhas.Add("MAXREL|$maxRel")

foreach ($d in $DirsCriticos) {
    $alvo = Join-Path $Destino $d
    $n = @(Get-ChildItem -LiteralPath $alvo -Recurse -File -Force -ErrorAction SilentlyContinue).Count
    if ($n -le 0) { throw "Area critica '$d' saiu VAZIA da extracao." }
    [void]$linhas.Add("DIR|$d|$n")
}

foreach ($a in $ArquivosCriticos) {
    $alvo = Join-Path $Destino $a
    if (-not (Test-Path -LiteralPath $alvo)) { throw "Arquivo critico ausente: $a" }
    $fi = Get-Item -LiteralPath $alvo
    $h = (Get-FileHash -LiteralPath $alvo -Algorithm SHA256).Hash
    [void]$linhas.Add("FILE|$a|$h|$($fi.Length)")
}

Set-Content -LiteralPath $Manifesto -Value $linhas -Encoding Ascii

Ok ("arvore: {0} arquivos / {1:N3} GB" -f $todos.Count, ($bytes / 1GB))
Ok "manifesto: $Manifesto"

[pscustomobject]@{
    Raiz          = $Destino
    Manifesto     = $Manifesto
    TotalArquivos = $todos.Count
    TotalBytes    = $bytes
    ShaDoPayload  = $sha
}
