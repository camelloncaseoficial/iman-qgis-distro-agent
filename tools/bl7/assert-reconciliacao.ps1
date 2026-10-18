<#
=============================================================================
 BL-7 - RECONCILIACAO DO PERFIL (DB-26), medida na VM

 O QUE ELE RESPONDE, em numero e nao em impressao:

   RAIOS58   quantas declaracoes de raio de 5 a 8 px o perfil tem
   RAIOS2    quantas declaracoes de raio de 2 px o perfil tem
   SUFIXO    quantas ocorrencias de _RE_SUFIXO_DO_QGIS ha no iman_brand.py
   ARQUIVOS  quantos arquivos DO PRODUTO batem, por SHA-256, com o template que
             ESTA INSTALADO em {app}\profile-template\<perfil>
   SOBRAS    arquivos dentro das arvores do produto que o template nao tem
   OBSOLETOS arquivos que o produto ja pos no perfil e nao poe mais
   CHAVES    chaves do QGIS3.ini declaradas pelo template que o perfil nao repete
   CRS       o defaultProjectCrs lido do QGIS3.ini do perfil
   BASE      se .iman-terra\base.json existe, e o template_digest dele

 QUEM DECIDE O QUE E DO PRODUTO: o proprio produto. Este script le
 {app}\profile-template\PERFIL-DO-PRODUTO.json, que e o MESMO arquivo que o
 Sync-Perfil.ps1 le. Nao ha segunda lista aqui - uma copia da fronteira seria
 mais um lugar para divergir em silencio.

 POR QUE O QGIS3.ini NAO E COMPARADO POR HASH: ele e COMPARTILHADO. O produto
 declara CHAVES nele; todo o resto do arquivo e do usuario, e o proprio QGIS o
 reescreve a cada sessao (geometria de janela, projetos recentes). Comparar o
 arquivo inteiro por hash daria FAIL numa instalacao perfeitamente sa - medido
 em 2026-09-20, no perfil real do sponsor.

 Rode o script ANTES e DEPOIS de abrir o produto. Sao os mesmos numeros dos
 dois lados, e e a DIFERENCA entre eles que prova a reconciliacao. Comparar o
 perfil com ele mesmo nao prova nada - por isso o modo -Semear imprime o
 baseline e o checklist exige conferi-lo (E.1) antes de seguir.

 MODO -Semear <arquivo.zip>
 Semeia o perfil a partir de um template HISTORICO, por COPIA CRUA, que e como
 o launcher da epoca o criava (`xcopy /E /I /Y`). O .zip sai da bancada, que
 tem git, porque a VM nao tem:

   git archive --format=zip -o perfil-velho-ba58d14.zip ba58d14 app/profile-template/iman-distro

 ONDE ELE ESCREVE: so no perfil isolado do produto, debaixo de
 %APPDATA%\InstitutoIMAN. O script RECUSA qualquer outro destino (BL-3), e
 RECUSA semear com o produto aberto.

 EXEMPLOS
   .\assert-reconciliacao.ps1 -Rotulo perfil-novo
   .\assert-reconciliacao.ps1 -Semear "$env:USERPROFILE\Desktop\perfil-velho-ba58d14.zip" -Rotulo velho-antes
   .\assert-reconciliacao.ps1 -Rotulo velho-depois

 REQUISITOS: Windows PowerShell 5.1. Sem Python, sem git, sem modulos de
 terceiros, sem privilegio de administrador. ASCII-only de proposito.
=============================================================================
#>
[CmdletBinding()]
param(
    # Raiz do produto instalado. E de la que saem o template e a declaracao.
    [string]$Produto = (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'),

    [string]$NomeDoPerfil = 'iman-distro',

    # Perfil isolado a inspecionar.
    [string]$Perfil = (Join-Path $env:APPDATA 'InstitutoIMAN\IMAN Terra\profiles\iman-distro'),

    [string]$OutDir = (Join-Path $env:USERPROFILE 'Desktop\bl7-evidence'),

    # Rotulo da medicao. Vira o nome do .json.
    [string]$Rotulo = 'reconciliacao',

    # Caminho de um .zip com app/profile-template/<perfil> de um commit antigo.
    # Com ele, o script SEMEIA o perfil por copia crua antes de medir.
    [string]$Semear = ''
)

$ErrorActionPreference = 'Stop'

function Escreve { param([string]$T, [string]$C = 'Gray') Write-Host $T -ForegroundColor $C }
function Sha { param([string]$P) (Get-FileHash -LiteralPath $P -Algorithm SHA256).Hash.ToUpperInvariant() }

# ==========================================================================
#  GUARDA DE DESTINO (BL-3). Primeira coisa que roda: um script de perfil que
#  erra o destino estraga o perfil do QGIS do usuario, e nao ha desfazer.
# ==========================================================================
$raizPermitida = Join-Path $env:APPDATA 'InstitutoIMAN'
$perfilCheio = [IO.Path]::GetFullPath($Perfil)
if (-not $perfilCheio.ToLower().StartsWith($raizPermitida.ToLower())) {
    Escreve "  O perfil '$perfilCheio' esta fora de '$raizPermitida'." 'Red'
    Escreve '  Abortado (BL-3): este script so mexe no perfil isolado do produto.' 'Red'
    exit 2
}

$templateInstalado = Join-Path $Produto ("profile-template\{0}" -f $NomeDoPerfil)
$declaracaoArq     = Join-Path $Produto 'profile-template\PERFIL-DO-PRODUTO.json'
foreach ($p in @($templateInstalado, $declaracaoArq)) {
    if (-not (Test-Path -LiteralPath $p)) {
        Escreve "  Nao encontrado: $p" 'Red'
        Escreve '  Isto nao parece uma instalacao do IMAN Terra desta versao.' 'Red'
        exit 2
    }
}
$decl = Get-Content -LiteralPath $declaracaoArq -Raw -Encoding UTF8 | ConvertFrom-Json

Escreve ''
Escreve '  BL-7 - reconciliacao do perfil (DB-26)' 'White'
Escreve "  produto   : $Produto"
Escreve "  template  : $templateInstalado  (o que o INSTALADOR entregou)"
Escreve "  fronteira : $declaracaoArq"
Escreve "  perfil    : $perfilCheio"
Escreve ''

# ==========================================================================
#  MODO SEMEAR
# ==========================================================================
if ($Semear) {
    if (-not (Test-Path -LiteralPath $Semear)) {
        Escreve "  Arquivo nao encontrado: $Semear" 'Red'
        exit 2
    }
    $vivos = @(Get-Process -Name qgis-ltr-bin, qgis-bin -ErrorAction SilentlyContinue)
    if ($vivos.Count -gt 0) {
        Escreve "  Ha $($vivos.Count) processo(s) do QGIS aberto(s). FECHE o IMAN Terra antes de semear." 'Red'
        Escreve '  Semear por baixo de uma instancia viva deixaria o perfil meio trocado.' 'Red'
        exit 2
    }

    $destmp = Join-Path $env:TEMP ('bl7-semente-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $destmp -Force | Out-Null
    try {
        try {
            Expand-Archive -LiteralPath $Semear -DestinationPath $destmp -Force
        } catch {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($Semear, $destmp)
        }
        # O .zip do `git archive` traz app/profile-template/<perfil>/... na raiz.
        # Procuramos a pasta do perfil em vez de presumir a profundidade.
        $origem = Get-ChildItem -LiteralPath $destmp -Recurse -Directory -Force |
                    Where-Object { $_.Name -eq $NomeDoPerfil } |
                    Select-Object -First 1
        if (-not $origem) {
            Escreve "  O .zip nao contem uma pasta '$NomeDoPerfil'. Ele foi gerado com o caminho certo?" 'Red'
            exit 2
        }
        if (Test-Path -LiteralPath $perfilCheio) { Remove-Item -LiteralPath $perfilCheio -Recurse -Force }
        New-Item -ItemType Directory -Path $perfilCheio -Force | Out-Null
        Copy-Item -Path (Join-Path $origem.FullName '*') -Destination $perfilCheio -Recurse -Force
        # __pycache__, .pyc e .gitkeep do repositorio nao viajam para um perfil
        # de verdade: a declaracao os ignora e o .iss os exclui do pacote.
        Get-ChildItem -LiteralPath $perfilCheio -Recurse -Directory -Filter '__pycache__' -Force -ErrorAction SilentlyContinue |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
        Get-ChildItem -LiteralPath $perfilCheio -Recurse -File -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq '.gitkeep' -or $_.Extension -eq '.pyc' } |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
        Escreve "  SEMEADO por copia crua de: $Semear" 'Yellow'
        Escreve ''
    } finally {
        Remove-Item -LiteralPath $destmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ==========================================================================
#  ferramentas de medicao
# ==========================================================================
function ContaRaios {
    param([string]$Qss, [int]$Px)
    if (-not (Test-Path -LiteralPath $Qss)) { return 0 }
    $txt = Get-Content -LiteralPath $Qss -Raw
    return @([regex]::Matches($txt, ('[a-z-]*radius:\s*' + $Px + 'px'))).Count
}

# Le um .ini inteiro como 'secao/chave' -> valor. So para ASSERIR: o produto
# edita preservando bytes; aqui so se le.
function LeIni {
    param([string]$Arquivo)
    $h = [ordered]@{}
    if (-not (Test-Path -LiteralPath $Arquivo)) { return $h }
    $sec = ''
    foreach ($linha in (Get-Content -LiteralPath $Arquivo -Encoding UTF8)) {
        if ($linha -match '^\s*\[(.+)\]\s*$') { $sec = $Matches[1].Trim(); continue }
        if ($linha -match '^\s*[;#]') { continue }
        if ($linha -match '^([^=\[\]]+?)=(.*)$') { $h["$sec/$($Matches[1].Trim())"] = $Matches[2] }
    }
    return $h
}

function Ignorado {
    param([string]$Rel)
    return ($Rel -match '(^|/)__pycache__/' -or $Rel -like '*.pyc' -or $Rel -like '*.gitkeep')
}

# Caminhos relativos (com '/') de todos os arquivos de uma raiz.
# O tipo de retorno e DECLARADO string[]: sem isso o PowerShell devolve a
# ArrayList como UM objeto, e `-notcontains` passa a comparar a lista inteira
# com uma string - todo arquivo virava "sobra". Medido em 2026-09-20.
function RelativosDe {
    param([string]$Raiz)
    $r = New-Object System.Collections.ArrayList
    if (-not (Test-Path -LiteralPath $Raiz)) { return [string[]]@() }
    foreach ($f in (Get-ChildItem -LiteralPath $Raiz -Recurse -File -Force)) {
        $rel = $f.FullName.Substring($Raiz.Length + 1) -replace '\\', '/'
        if (Ignorado $rel) { continue }
        [void]$r.Add($rel)
    }
    return [string[]]$r.ToArray()
}

if (-not (Test-Path -LiteralPath $perfilCheio)) {
    Escreve '  O perfil NAO EXISTE ainda.' 'Yellow'
    Escreve '  Isso e o esperado ANTES da primeira abertura do produto (estado (a) do checklist).' 'Yellow'
    Escreve ''
}

# ==========================================================================
#  1. ARQUIVOS DO PRODUTO, por SHA-256 (arvores espelhadas + avulsos)
# ==========================================================================
$relsDoProduto = New-Object System.Collections.ArrayList
foreach ($arvore in @($decl.arvores_do_produto)) {
    foreach ($rel in (RelativosDe (Join-Path $templateInstalado ($arvore -replace '/', '\')))) {
        [void]$relsDoProduto.Add(($arvore + '/' + $rel))
    }
}
foreach ($arq in @($decl.arquivos_do_produto)) { [void]$relsDoProduto.Add($arq) }

$divergentes = New-Object System.Collections.ArrayList
foreach ($rel in $relsDoProduto) {
    $noTemplate = Join-Path $templateInstalado ($rel -replace '/', '\')
    $noPerfil   = Join-Path $perfilCheio ($rel -replace '/', '\')
    if (-not (Test-Path -LiteralPath $noPerfil)) { [void]$divergentes.Add("$rel (ausente)") ; continue }
    if ((Sha $noPerfil) -ne (Sha $noTemplate)) { [void]$divergentes.Add("$rel (hash)") }
}
$iguais = $relsDoProduto.Count - $divergentes.Count

# ==========================================================================
#  2. SOBRAS: arquivo dentro de arvore do produto que o template nao tem.
#     E o R2 (espelho): o que sobrou de uma versao anterior tem de sair.
# ==========================================================================
$sobras = New-Object System.Collections.ArrayList
foreach ($arvore in @($decl.arvores_do_produto)) {
    [string[]]$noTemplate = RelativosDe (Join-Path $templateInstalado ($arvore -replace '/', '\'))
    foreach ($rel in (RelativosDe (Join-Path $perfilCheio ($arvore -replace '/', '\')))) {
        if ($noTemplate -notcontains $rel) { [void]$sobras.Add($arvore + '/' + $rel) }
    }
}

# ==========================================================================
#  3. OBSOLETOS: o que o produto ja pos no perfil e nao poe mais.
# ==========================================================================
$obsoletosPresentes = New-Object System.Collections.ArrayList
foreach ($rel in @($decl.obsoletos)) {
    if (Test-Path -LiteralPath (Join-Path $perfilCheio ($rel -replace '/', '\'))) {
        [void]$obsoletosPresentes.Add($rel)
    }
}

# ==========================================================================
#  4. PASTAS que so precisam existir.
# ==========================================================================
$pastasFaltando = New-Object System.Collections.ArrayList
foreach ($rel in @($decl.pastas_do_produto)) {
    if (-not (Test-Path -LiteralPath (Join-Path $perfilCheio ($rel -replace '/', '\')))) {
        [void]$pastasFaltando.Add($rel)
    }
}

# ==========================================================================
#  5. CHAVES do QGIS3.ini. RELATADAS, nao vetadas: o 3-way pode, com razao,
#     manter o valor do USUARIO numa chave que o produto nao mudou desde a
#     base. Os valores esperados de cada estado estao no CHECKLIST.md.
# ==========================================================================
$relIni = [string]$decl.ini_do_produto
$iniTemplate = LeIni (Join-Path $templateInstalado ($relIni -replace '/', '\'))
$iniPerfil   = LeIni (Join-Path $perfilCheio ($relIni -replace '/', '\'))
$chavesAusentes = New-Object System.Collections.ArrayList
$chavesComOutroValor = New-Object System.Collections.ArrayList
foreach ($k in $iniTemplate.Keys) {
    if (-not $iniPerfil.Contains($k)) { [void]$chavesAusentes.Add($k) }
    elseif ($iniPerfil[$k] -ne $iniTemplate[$k]) {
        [void]$chavesComOutroValor.Add(("{0}  template='{1}'  perfil='{2}'" -f $k, $iniTemplate[$k], $iniPerfil[$k]))
    }
}

# ==========================================================================
#  6. Sinais visiveis da fatia #022 e do D5, e a base do 3-way.
# ==========================================================================
$qss    = Join-Path $perfilCheio 'themes\IMAN Terra\style.qss'
$plugin = Join-Path $perfilCheio 'python\plugins\iman_brand\iman_brand.py'
$custom = Join-Path $perfilCheio 'QGIS\QGISCUSTOMIZATION3.ini'
$baseArq = Join-Path $perfilCheio ((([string]$decl.registro_da_base) -replace '/', '\') + '\base.json')

$raios58 = 0
foreach ($px in 5, 6, 7, 8) { $raios58 += (ContaRaios $qss $px) }
$raios2 = ContaRaios $qss 2
$sufixo = 0
if (Test-Path -LiteralPath $plugin) {
    $sufixo = @(Select-String -LiteralPath $plugin -Pattern '_RE_SUFIXO_DO_QGIS').Count
}
$crs       = $iniPerfil['app/projections\defaultProjectCrs']
$camadaCrs = $iniPerfil['app/projections\layerDefaultCrs']

$temBase = Test-Path -LiteralPath $baseArq
$digest = ''
$chavesNaBase = 0
if ($temBase) {
    try {
        $b = Get-Content -LiteralPath $baseArq -Raw -Encoding UTF8 | ConvertFrom-Json
        $digest = [string]$b.template_digest
        $chavesNaBase = @($b.chaves.PSObject.Properties).Count
    } catch {
        $digest = 'ILEGIVEL'
    }
}

$secCustom = 0
$splash = 0
if (Test-Path -LiteralPath $custom) {
    foreach ($l in (Get-Content -LiteralPath $custom -Encoding UTF8)) {
        if ($l -match '^\s*\[Customization\]\s*$') { $secCustom++ }
        if ($l -match '^\s*splashpath\s*=') { $splash++ }
    }
}

$arquivosNoPerfil = 0
if (Test-Path -LiteralPath $perfilCheio) {
    $arquivosNoPerfil = @(Get-ChildItem -LiteralPath $perfilCheio -Recurse -File -Force).Count
}

# ==========================================================================
#  RELATO
# ==========================================================================
Escreve ("  RAIOS58   : {0}   (declaracoes de raio de 5 a 8 px no style.qss)" -f $raios58)
Escreve ("  RAIOS2    : {0}   (declaracoes de raio de 2 px)" -f $raios2)
Escreve ("  SUFIXO    : {0}   (_RE_SUFIXO_DO_QGIS em iman_brand.py)" -f $sufixo)
Escreve ("  ARQUIVOS  : {0} de {1} arquivos DO PRODUTO com SHA-256 do template instalado" -f $iguais, $relsDoProduto.Count)
foreach ($d in $divergentes) { Escreve ("              DIVERGE   {0}" -f $d) 'Yellow' }
Escreve ("  SOBRAS    : {0}   (arquivo em arvore do produto que o template nao tem)" -f $sobras.Count)
foreach ($s in $sobras) { Escreve ("              SOBRA     {0}" -f $s) 'Yellow' }
Escreve ("  OBSOLETOS : {0}   (arquivo que o produto nao poe mais e devia ter saido)" -f $obsoletosPresentes.Count)
foreach ($o in $obsoletosPresentes) { Escreve ("              OBSOLETO  {0}" -f $o) 'Yellow' }
Escreve ("  PASTAS    : {0} faltando de {1}" -f $pastasFaltando.Count, @($decl.pastas_do_produto).Count)
Escreve ("  CHAVES    : {0} do template ausentes, {1} com outro valor (de {2})" -f `
            $chavesAusentes.Count, $chavesComOutroValor.Count, $iniTemplate.Count)
foreach ($k in $chavesAusentes)      { Escreve ("              AUSENTE   {0}" -f $k) 'Yellow' }
foreach ($k in $chavesComOutroValor) { Escreve ("              DIFERENTE {0}" -f $k) 'Yellow' }
Escreve ("  CRS       : projeto={0}   camada={1}" -f $crs, $camadaCrs)
if ($temBase) {
    Escreve ("  BASE      : existe   template_digest={0}   chaves={1}" -f $digest, $chavesNaBase)
} else {
    Escreve '  BASE      : AUSENTE (.iman-terra\base.json)' 'Yellow'
}
Escreve ("  CUSTOM    : [Customization] x{0}   splashpath x{1}" -f $secCustom, $splash)
Escreve ("  PERFIL    : {0} arquivo(s) no total" -f $arquivosNoPerfil)
Escreve ''

# Veredito GENERICO: o que e do produto esta como este build instalou, e a base
# esta registrada. As CHAVES ficam fora do veredito de proposito (ver secao 5).
# Os valores esperados de cada ESTADO estao no CHECKLIST.md - este script nao
# sabe em qual estado voce esta, e nao deve adivinhar.
$ok = ($divergentes.Count -eq 0) -and ($sobras.Count -eq 0) -and ($obsoletosPresentes.Count -eq 0) -and
      ($pastasFaltando.Count -eq 0) -and $temBase -and ($secCustom -le 1) -and ($splash -le 1)
if ($ok) {
    Escreve '  [OK]  o que e do produto esta como este build instalou, e a base esta registrada.' 'Green'
} else {
    Escreve '  [NAO CONFERE]  ver as linhas acima. No checklist, compare com o estado que voce mede:' 'Yellow'
    Escreve '                 (a) perfil ausente antes de abrir / (b) perfil igual / (c) perfil velho.' 'Yellow'
}
Escreve ''

if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }
$destino = Join-Path $OutDir ("reconciliacao-{0}.json" -f $Rotulo)
[pscustomobject]@{
    Quando              = (Get-Date).ToString('o')
    Rotulo              = $Rotulo
    Produto             = $Produto
    TemplateInstalado   = $templateInstalado
    Declaracao          = $declaracaoArq
    Perfil              = $perfilCheio
    Semeado             = $Semear
    Raios58             = $raios58
    Raios2              = $raios2
    SufixoDoQgis        = $sufixo
    ArquivosDoProduto   = $relsDoProduto.Count
    ArquivosIguais      = $iguais
    Divergentes         = @($divergentes)
    Sobras              = @($sobras)
    ObsoletosPresentes  = @($obsoletosPresentes)
    PastasFaltando      = @($pastasFaltando)
    ChavesNoTemplate    = $iniTemplate.Count
    ChavesAusentes      = @($chavesAusentes)
    ChavesComOutroValor = @($chavesComOutroValor)
    CrsProjeto          = $crs
    CrsCamada           = $camadaCrs
    BaseExiste          = $temBase
    TemplateDigest      = $digest
    ChavesNaBase        = $chavesNaBase
    SecoesCustomization = $secCustom
    LinhasSplashpath    = $splash
    ArquivosNoPerfil    = $arquivosNoPerfil
    Veredito            = $(if ($ok) { 'OK' } else { 'NAO CONFERE' })
} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $destino -Encoding UTF8

Escreve "  Evidencia: $destino" 'Green'
Escreve ''

if ($ok) { exit 0 } else { exit 1 }
