<#
=============================================================================
 IMAN Terra - RECONCILIACAO DO PERFIL ISOLADO (DB-26, fatia #030)

 O DEFEITO QUE ISTO CONSERTA. Ate a fatia #029 o launcher semeava o perfil
 no PRIMEIRO uso e nunca mais o reconciliava:

     if not exist "%PROFILE_DIR%\QGIS\QGIS3.ini" ( xcopy ... )

 Tema, plugin de marca, splash e chaves do QGIS3.ini: quem ja tinha perfil
 NAO recebia nada de uma versao nova. Tres fatias instaladas, nenhuma visivel.
 E um perfil semeado antes de 4dfeb93 (2026-07-12) abria com CRS padrao
 EPSG:4674 para sempre - num produto de REURB isso nao e tema velho, e
 medicao nova no CRS errado.

 POR QUE AQUI, E NAO NO iman_startup.py (R1). O --code do startup roda DEPOIS
 de o QGIS carregar os plugins do perfil: nessa hora o codigo velho do
 iman_brand ja foi importado. Reconciliar la seria tarde por construcao. Isto
 roda ANTES de o QGIS ler o perfil, chamado pelo launcher.

 POR QUE NO LAUNCHER, E NAO NO INSTALADOR. O perfil nasce na PRIMEIRA
 ABERTURA, nao na instalacao - no instante do install ele pode nem existir.
 Reconciliar la exigiria manter DUAS rotinas (a do instalador e a semeadura do
 launcher) que precisam concordar, e a que roda menos e a que apodrece. Aqui ha
 uma so, e ela e a mesma que semeia. De quebra, e a unica posicao de onde se
 pode ver que o produto ja esta aberto (R7) e recusar-se a mexer embaixo dele.

 A FRONTEIRA (arbitrada pelo sponsor em 2026-09-15) mora em
 profile-template\PERFIL-DO-PRODUTO.json, e so la:

   arquivo do produto  espelha o template. Obsoleto sai, sobra sai (R2).
   chave do produto    3-way contra a base registrada no perfil (R3).
   do usuario          nunca tocado, byte a byte (R4).

 ASCII-only de proposito: o PowerShell 5.1 le .ps1 sem BOM como ANSI.

 SAIDA (uma linha por campo, para o launcher e para a guarda lerem):
   RECONCILIACAO=NADA_A_FAZER | SEMEADO | APLICADA | INSTANCIA_VIVA | FALHOU
   PLANO=arq+N arq~N arq-N chave+N chave~N chave-N pasta+N splash+N base+N
   MS=<milissegundos>
   DETALHE=<uma linha, so quando ha o que dizer>

 EXIT
   0  nada a fazer, ou reconciliado com sucesso   -> o launcher abre
   1  falhou                                      -> o launcher RECUSA abrir
   2  ha o que aplicar e o produto ja esta aberto -> o launcher RECUSA abrir
=============================================================================
#>
[CmdletBinding()]
param(
    # <APP_HOME>\profile-template\<perfil> - o template desta instalacao.
    [Parameter(Mandatory = $true)][string]$Template,

    # <APP_HOME>\profile-template\PERFIL-DO-PRODUTO.json - a fronteira (R9).
    [Parameter(Mandatory = $true)][string]$Declaracao,

    # <PROFILES_ROOT>\profiles\<perfil> - o perfil isolado do usuario.
    [Parameter(Mandatory = $true)][string]$Perfil,

    # Raiz da arvore privada do QGIS. So serve para a deteccao de instancia
    # viva (R7); sem ela a deteccao e pulada e isso e dito na saida.
    [string]$QgisRoot = '',

    # Itemiza o plano no stdout. A guarda usa; o launcher nao.
    [switch]$Detalhe
)

$ErrorActionPreference = 'Stop'
$cronometro = [System.Diagnostics.Stopwatch]::StartNew()

# --------------------------------------------------------------------------
# O relato sai SEMPRE, inclusive quando algo estoura no meio. Sem isto, uma
# falha viraria uma pilha de excecao do PowerShell na cara do usuario e o
# launcher nao teria o que dizer - e "abrir em silencio com o produto velho"
# e exatamente o que o R6 proibe.
# --------------------------------------------------------------------------
$script:Detalhes = New-Object System.Collections.ArrayList

function Relata {
    param([string]$Estado, [hashtable]$Plano, [string]$Motivo = '')
    $cronometro.Stop()
    Write-Output ("RECONCILIACAO={0}" -f $Estado)
    if ($Plano) {
        Write-Output ("PLANO=arq+{0} arq~{1} arq-{2} chave+{3} chave~{4} chave-{5} pasta+{6} splash+{7} base+{8}" -f `
            $Plano.ArqNovos, $Plano.ArqTrocados, $Plano.ArqRemovidos,
            $Plano.ChaveNovas, $Plano.ChaveTrocadas, $Plano.ChaveRemovidas,
            $Plano.PastasNovas, $Plano.Splash, $Plano.Base)
    }
    Write-Output ("MS={0}" -f [int]$cronometro.ElapsedMilliseconds)
    if ($Motivo) { Write-Output ("DETALHE={0}" -f ($Motivo -replace '\s+', ' ')) }
    if ($Detalhe) { foreach ($d in $script:Detalhes) { Write-Output ("  {0}" -f $d) } }
}

function Nota { param([string]$T) [void]$script:Detalhes.Add($T) }

function PlanoVazio {
    @{ ArqNovos = 0; ArqTrocados = 0; ArqRemovidos = 0
       ChaveNovas = 0; ChaveTrocadas = 0; ChaveRemovidas = 0
       PastasNovas = 0; Splash = 0; Base = 0 }
}

# ============================================================== utilitarios

function Sha256 {
    param([string]$Caminho)
    return (Get-FileHash -LiteralPath $Caminho -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Ignorado {
    param([string]$Rel, [string[]]$Padroes)
    $partes = $Rel -split '/'
    foreach ($p in $Padroes) {
        foreach ($parte in $partes) { if ($parte -like $p) { return $true } }
        if ($Rel -like $p) { return $true }
    }
    return $false
}

# Caminhos relativos com '/', sempre - e o que a declaracao usa e o que vai
# gravado na base. Comparar '\' com '/' acusaria diferenca onde nao ha.
function Relativo {
    param([string]$Raiz, [string]$Completo)
    $r = $Raiz.TrimEnd('\', '/')
    $c = $Completo
    if ($c.Length -le $r.Length) { return '' }
    return ($c.Substring($r.Length + 1) -replace '\\', '/')
}

function ListaArquivos {
    param([string]$Raiz, [string[]]$Ignorar)
    $saida = New-Object System.Collections.ArrayList
    if (-not (Test-Path -LiteralPath $Raiz)) { return , @() }
    foreach ($f in (Get-ChildItem -LiteralPath $Raiz -Recurse -File -Force)) {
        $rel = Relativo $Raiz $f.FullName
        if ($rel -and -not (Ignorado $rel $Ignorar)) { [void]$saida.Add($rel) }
    }
    return , @($saida)
}

# --------------------------------------------------------------------------
# .ini do QGIS, PRESERVANDO BYTES (R4).
#
# Nao se usa parser-e-regrava: reescrever o arquivo inteiro a partir de uma
# estrutura normalizaria aspas, ordem, comentarios e espacamento do QGIS - e
# "o que e do usuario fica byte a byte" morreria no primeiro update. O arquivo
# e tratado como LISTA DE LINHAS com o terminador colado em cada uma; so as
# linhas das chaves que mudam sao tocadas, e o resto volta identico.
# --------------------------------------------------------------------------
function LeIni {
    param([string]$Caminho)
    $bytes = [System.IO.File]::ReadAllBytes($Caminho)
    $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $enc = New-Object System.Text.UTF8Encoding($false)
    $texto = $enc.GetString($bytes, $(if ($bom) { 3 } else { 0 }), $bytes.Length - $(if ($bom) { 3 } else { 0 }))
    # -------- "byte a byte" (R4) TEM DE SER VERIFICAVEL, e nao prometido ----
    # Este arquivo e do USUARIO: o QGIS o reescreve a cada saida, e o que esta
    # nele veio dele. Reescreve-lo a partir de um texto DECODIFICADO so e
    # seguro se decodificar e recodificar devolver os MESMOS bytes. Se nao
    # devolver (arquivo que nao esta em UTF-8, byte invalido no meio), a
    # regravacao trocaria caracteres do usuario por U+FFFD em silencio - que e
    # o pior desfecho possivel numa rotina cujo contrato e nao encostar no que
    # e dele. Entao a rotina RECUSA, em vez de "dar um jeito".
    $volta = $enc.GetBytes($texto)
    $iguais = ($volta.Length -eq ($bytes.Length - $(if ($bom) { 3 } else { 0 })))
    if ($iguais) {
        $desloc = $(if ($bom) { 3 } else { 0 })
        for ($i = 0; $i -lt $volta.Length; $i++) {
            if ($volta[$i] -ne $bytes[$i + $desloc]) { $iguais = $false; break }
        }
    }
    if (-not $iguais) {
        throw ("'$Caminho' nao esta em UTF-8 valido. A reconciliacao NAO reescreve um .ini que " +
               "ela nao consegue devolver byte a byte - regravar assim trocaria caracteres do " +
               "usuario em silencio.")
    }
    # Lookbehind em \n: o terminador fica colado na linha que ele termina, e
    # ($linhas -join '') devolve o texto original, byte a byte.
    $linhas = [System.Text.RegularExpressions.Regex]::Split($texto, '(?<=\n)')
    $mapa = MapeiaIni $linhas
    $mapa.Linhas = @($linhas)
    $mapa.Bom = $bom
    return $mapa
}

# Le a estrutura A PARTIR DAS LINHAS (e nao do disco): depois de inserir ou
# apagar uma linha, todos os indices seguintes andam, e recalcular sobre a
# lista em memoria e o unico jeito honesto de nao escrever na linha errada.
function MapeiaIni {
    param([string[]]$Linhas)
    $fim = "`r`n"
    foreach ($l in $Linhas) { if ($l -match '\r\n$') { $fim = "`r`n"; break } elseif ($l -match '\n$') { $fim = "`n"; break } }

    $chaves = @{}         # 'secao/chave' -> valor
    $indices = @{}        # 'secao/chave' -> indice da linha
    $fimSecao = @{}       # 'secao' -> indice da ULTIMA linha util da secao
    $secao = ''
    for ($i = 0; $i -lt $Linhas.Count; $i++) {
        $nu = $Linhas[$i] -replace '\r?\n$', ''
        if ($nu -match '^\s*\[(.+)\]\s*$') {
            $secao = $Matches[1].Trim()
            if (-not $fimSecao.ContainsKey($secao)) { $fimSecao[$secao] = $i }
            continue
        }
        if ($nu -match '^\s*[;#]') { continue }
        if ($nu -match '^([^=\[\]]+?)=(.*)$') {
            $nome = $Matches[1].Trim()
            $k = "$secao/$nome"
            $chaves[$k] = $Matches[2]
            $indices[$k] = $i
            if ($secao -ne '') { $fimSecao[$secao] = $i }
        }
    }
    return @{ Linhas = @($Linhas); Chaves = $chaves; Indices = $indices
              FimSecao = $fimSecao; Fim = $fim; Bom = $false }
}

# Troca SO O VALOR da linha: nome, espacamento e terminador ficam como o QGIS
# os escreveu. Sem regex de substituicao - o valor pode conter '$', e nada no
# valor do usuario pode ser interpretado como padrao.
function TrocaValor {
    param([string]$Linha, [string]$Valor)
    $term = ''
    if ($Linha -match '(\r?\n)$') { $term = $Matches[1] }
    $nu = $Linha.Substring(0, $Linha.Length - $term.Length)
    $eq = $nu.IndexOf('=')
    if ($eq -lt 0) { return $Linha }
    return $nu.Substring(0, $eq + 1) + $Valor + $term
}

function GravaIni {
    param([string[]]$Linhas, [bool]$Bom, [string]$Caminho)
    $texto = ($Linhas -join '')
    $enc = New-Object System.Text.UTF8Encoding($Bom)
    $tmp = "$Caminho.iman-tmp"
    [System.IO.File]::WriteAllText($tmp, $texto, $enc)
    Move-Item -LiteralPath $tmp -Destination $Caminho -Force
}

# ============================================== 0. pre-requisitos (C.3)

$plano = PlanoVazio
try {
    foreach ($p in @($Template, $Declaracao)) {
        if (-not (Test-Path -LiteralPath $p)) {
            throw "o produto esta incompleto: nao existe '$p'"
        }
    }
    $decl = Get-Content -LiteralPath $Declaracao -Raw -Encoding ASCII | ConvertFrom-Json
} catch {
    Relata 'FALHOU' $plano ("pre-requisito: " + $_.Exception.Message)
    exit 1
}

$ignorar = @($decl.ignorar)
$iniRel  = [string]$decl.ini_do_produto
$baseDir = Join-Path $Perfil ([string]$decl.registro_da_base)
$baseArq = Join-Path $baseDir 'base.json'
$incompletoArq = Join-Path $baseDir 'INCOMPLETO.txt'

$iniTemplate = Join-Path $Template ($iniRel -replace '/', '\')

# ================================== 1. o template, e a guarda do R9 (C.3)
#
# Todo arquivo do template tem de estar coberto pela declaracao. Sem esta
# guarda, acrescentar um arquivo ao template e esquecer de declara-lo faria
# ele nunca chegar a quem ja instalou - o DB-26 de novo, em miniatura, e em
# silencio. Aqui isso vira uma recusa alta, na bancada de quem esqueceu.

try {
    $arqTemplate = ListaArquivos $Template $ignorar
    if ($arqTemplate.Count -le 0) { throw "o template em '$Template' esta vazio" }
    if (-not (Test-Path -LiteralPath $iniTemplate)) { throw "o template nao tem '$iniRel'" }

    $cobertos = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    [void]$cobertos.Add($iniRel)
    foreach ($a in @($decl.arquivos_do_produto)) { [void]$cobertos.Add([string]$a) }
    foreach ($arv in @($decl.arvores_do_produto)) {
        $pre = ([string]$arv).TrimEnd('/') + '/'
        foreach ($rel in $arqTemplate) { if ($rel.StartsWith($pre, 'OrdinalIgnoreCase')) { [void]$cobertos.Add($rel) } }
    }
    $descobertos = @($arqTemplate | Where-Object { -not $cobertos.Contains($_) })
    if ($descobertos.Count -gt 0) {
        throw ("o template tem arquivo que PERFIL-DO-PRODUTO.json nao declara, e por isso nunca chegaria " +
               "a quem ja instalou: " + ($descobertos -join ', '))
    }
} catch {
    Relata 'FALHOU' $plano $_.Exception.Message
    exit 1
}

# ============================================ 2. a base registrada (R3)
#
# POR CONTEUDO, nunca por numero de versao: o template mudou varias vezes
# DENTRO da mesma 0.3.0 (#022, #027). Um "se a versao mudou, reaplica" daria
# verde sem ter reaplicado nada.

$base = $null
$baseValida = $false
if (Test-Path -LiteralPath $baseArq) {
    try {
        $base = Get-Content -LiteralPath $baseArq -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($base.template_digest -and $base.chaves) { $baseValida = $true }
    } catch { $base = $null }
}
$incompleto = Test-Path -LiteralPath $incompletoArq
if ($incompleto) {
    # A rodada anterior morreu no meio. A base NAO foi atualizada (ela e
    # escrita por ultimo, de proposito), entao o plano abaixo recalcula tudo e
    # o perfil se conserta sozinho. O marcador so some quando isso terminar.
    Nota 'rodada anterior terminou INCOMPLETA; o plano foi recalculado do zero'
}

# Digest do template POR CONTEUDO: caminho relativo + SHA-256, em ordem.
$hashTemplate = @{}
$digestFonte = New-Object System.Text.StringBuilder
foreach ($rel in ($arqTemplate | Sort-Object)) {
    $h = Sha256 (Join-Path $Template ($rel -replace '/', '\'))
    $hashTemplate[$rel] = $h
    [void]$digestFonte.Append($rel).Append("`0").Append($h).Append("`n")
}
$sha = [System.Security.Cryptography.SHA256]::Create()
$templateDigest = ([BitConverter]::ToString(
    $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($digestFonte.ToString()))) -replace '-', '')
$sha.Dispose()

# ============================================= 3. perfil ausente = semear
#
# R1/estado 1. Semear e reconciliar sao A MESMA rotina: se fossem duas, a que
# roda menos seria a que apodrece, e o DB-26 nasceu exatamente disso.

$iniPerfil = Join-Path $Perfil ($iniRel -replace '/', '\')
$semear = -not (Test-Path -LiteralPath $iniPerfil)

# ============================================ 4. o plano, antes de escrever

$copiar   = New-Object System.Collections.ArrayList   # rel
$remover  = New-Object System.Collections.ArrayList   # rel
$criarDir = New-Object System.Collections.ArrayList   # rel
$chavesAplicar = New-Object System.Collections.ArrayList   # @{K;Valor;Novo}
$chavesRemover = New-Object System.Collections.ArrayList   # K

# --- o splash NATIVO, que e derivado e nao vem do template ------------------
# O splashpath e ABSOLUTO e por-instalacao, entao nao pode viver no template.
# Ate a #029 o launcher o reescrevia a CADA execucao - o que, sozinho, fazia a
# segunda abertura escrever no perfil e tornaria o R5 impossivel de cumprir.
# Aqui ele e escrito so quando o conteudo difere.
$splashAlvo = ("[Customization]`r`nsplashpath={0}/QGIS/`r`n" -f ($Perfil -replace '\\', '/'))
$splashArq  = Join-Path $Perfil 'QGIS\QGISCUSTOMIZATION3.ini'
$splashPrecisa = $true
if (Test-Path -LiteralPath $splashArq) {
    try {
        $atual = [System.IO.File]::ReadAllText($splashArq, (New-Object System.Text.UTF8Encoding($false)))
        $splashPrecisa = ($atual -ne $splashAlvo)
    } catch { $splashPrecisa = $true }
}

if ($semear) {
    foreach ($rel in $arqTemplate) { [void]$copiar.Add($rel) }
    foreach ($d in @($decl.pastas_do_produto)) { [void]$criarDir.Add([string]$d) }
} else {
    try {
        # ---- arquivos do produto: espelho (R2) -----------------------------
        $doProduto = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach ($a in @($decl.arquivos_do_produto)) { [void]$doProduto.Add([string]$a) }
        foreach ($arv in @($decl.arvores_do_produto)) {
            $pre = ([string]$arv).TrimEnd('/') + '/'
            foreach ($rel in $arqTemplate) { if ($rel.StartsWith($pre, 'OrdinalIgnoreCase')) { [void]$doProduto.Add($rel) } }
        }
        foreach ($rel in ($doProduto | Sort-Object)) {
            $alvo = Join-Path $Perfil ($rel -replace '/', '\')
            if (-not (Test-Path -LiteralPath $alvo)) { [void]$copiar.Add($rel); Nota "+ $rel" }
            elseif ((Sha256 $alvo) -ne $hashTemplate[$rel]) { [void]$copiar.Add($rel); Nota "~ $rel" }
        }
        # ---- sobras dentro de arvore do produto: saem ----------------------
        # Copiar por cima nao remove. E a classe do DB-22, so que dentro do
        # perfil: sem isto, o modulo de uma versao anterior continuaria
        # importavel ao lado do novo.
        foreach ($arv in @($decl.arvores_do_produto)) {
            $rel0 = ([string]$arv).TrimEnd('/')
            $dirPerfil = Join-Path $Perfil ($rel0 -replace '/', '\')
            foreach ($r in (ListaArquivos $dirPerfil $ignorar)) {
                $rel = "$rel0/$r"
                if (-not $doProduto.Contains($rel)) { [void]$remover.Add($rel); Nota "- $rel (sobra)" }
            }
        }
        # ---- obsoletos nomeados -------------------------------------------
        foreach ($o in @($decl.obsoletos)) {
            $rel = [string]$o
            if ($remover -contains $rel) { continue }
            if (Test-Path -LiteralPath (Join-Path $Perfil ($rel -replace '/', '\'))) {
                [void]$remover.Add($rel); Nota "- $rel (obsoleto)"
            }
        }
        # ---- pastas do produto --------------------------------------------
        foreach ($d in @($decl.pastas_do_produto)) {
            if (-not (Test-Path -LiteralPath (Join-Path $Perfil ([string]$d -replace '/', '\')))) {
                [void]$criarDir.Add([string]$d); Nota "+ $d/ (pasta)"
            }
        }
        # ---- chaves: 3-way -------------------------------------------------
        $iniT = LeIni $iniTemplate
        $iniP = LeIni $iniPerfil
        $baseChaves = @{}
        if ($baseValida) {
            foreach ($p in $base.chaves.PSObject.Properties) { $baseChaves[$p.Name] = [string]$p.Value }
        }
        foreach ($k in ($iniT.Chaves.Keys | Sort-Object)) {
            $vT = [string]$iniT.Chaves[$k]
            $produtoMexeu = $false
            $porque = ''
            if (-not $baseValida) {
                # R3: perfil SEM base registrada. So existe em bancada - nenhuma
                # prefeitura instalou o 0.3.0. Aplica todas as chaves do produto
                # uma vez e registra a base a partir dai.
                $produtoMexeu = $true; $porque = 'sem base registrada'
            } elseif (-not $baseChaves.ContainsKey($k)) {
                $produtoMexeu = $true; $porque = 'o produto ACRESCENTOU a chave'
            } elseif ($baseChaves[$k] -ne $vT) {
                $produtoMexeu = $true; $porque = ("o produto mudou {0} -> {1}" -f $baseChaves[$k], $vT)
            }
            if (-not $produtoMexeu) {
                if ($iniP.Chaves.ContainsKey($k) -and $iniP.Chaves[$k] -ne $vT) {
                    Nota ("= {0}: fica '{1}' (do usuario; o produto nao mexeu)" -f $k, $iniP.Chaves[$k])
                }
                continue
            }
            if ($iniP.Chaves.ContainsKey($k)) {
                if ($iniP.Chaves[$k] -eq $vT) { continue }   # ja esta la: idempotencia
                [void]$chavesAplicar.Add(@{ K = $k; Valor = $vT; Novo = $false })
                Nota ("~ {0}: '{1}' -> '{2}' ({3})" -f $k, $iniP.Chaves[$k], $vT, $porque)
            } else {
                [void]$chavesAplicar.Add(@{ K = $k; Valor = $vT; Novo = $true })
                Nota ("+ {0} = '{1}' ({2})" -f $k, $vT, $porque)
            }
        }
        if ($baseValida) {
            foreach ($k in ($baseChaves.Keys | Sort-Object)) {
                if ($iniT.Chaves.ContainsKey($k)) { continue }
                if (-not $iniP.Chaves.ContainsKey($k)) { continue }
                if ($iniP.Chaves[$k] -ne $baseChaves[$k]) {
                    Nota ("= {0}: o produto deixou de declarar, mas o usuario mexeu - fica" -f $k)
                    continue
                }
                [void]$chavesRemover.Add($k); Nota ("- {0} (o produto deixou de declarar)" -f $k)
            }
        }
    } catch {
        Relata 'FALHOU' $plano ("ao montar o plano: " + $_.Exception.Message)
        exit 1
    }
}

$plano.ArqNovos       = @($copiar | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Perfil ($_ -replace '/', '\'))) }).Count
$plano.ArqTrocados    = $copiar.Count - $plano.ArqNovos
$plano.ArqRemovidos   = $remover.Count
$plano.ChaveNovas     = @($chavesAplicar | Where-Object { $_.Novo }).Count
$plano.ChaveTrocadas  = $chavesAplicar.Count - $plano.ChaveNovas
$plano.ChaveRemovidas = $chavesRemover.Count
$plano.PastasNovas    = $criarDir.Count
$plano.Splash         = $(if ($splashPrecisa) { 1 } else { 0 })

$baseDesatualizada = (-not $baseValida) -or ($base.template_digest -ne $templateDigest)
$plano.Base = $(if ($baseDesatualizada) { 1 } else { 0 })

$mexeNoPerfil = ($copiar.Count + $remover.Count + $criarDir.Count +
                 $chavesAplicar.Count + $chavesRemover.Count + $plano.Splash) -gt 0

# ================================================ 5. R5: nada a fazer
if (-not $mexeNoPerfil -and -not $baseDesatualizada -and -not $incompleto) {
    Relata 'NADA_A_FAZER' $plano
    exit 0
}

# ============================ 6. R7: o produto ja esta aberto?
#
# Reconciliar embaixo de uma instancia viva e pior que nao reconciliar: o QGIS
# REESCREVE o QGIS3.ini ao sair, e apagaria as chaves que acabamos de aplicar -
# ficando uma base que diz "aplicado" sobre um .ini que voltou atras. Isso e
# literalmente "perfil meio aplicado passando por atualizado" (R6).
#
# Quando NAO ha o que aplicar, a segunda janela abre normalmente: nao ha razao
# para atrapalhar quem so quer duas janelas.
if ($mexeNoPerfil -and $QgisRoot) {
    try {
        $curto = $QgisRoot
        try {
            $fso = New-Object -ComObject Scripting.FileSystemObject
            $curto = $fso.GetFolder($QgisRoot).ShortPath
        } catch { }
        $vivos = @()
        foreach ($proc in @(Get-CimInstance Win32_Process -Filter "Name='qgis-ltr-bin.exe'" -ErrorAction SilentlyContinue)) {
            $exe = [string]$proc.ExecutablePath
            if (-not $exe) { continue }
            # O o4w_env.bat deriva OSGEO4W_ROOT em forma 8.3 (%~fsi), entao o
            # executavel do processo chega encurtado. Os dois lados sao
            # conferidos, longo e curto - comparar so o longo nao acharia nada.
            if ($exe.StartsWith($QgisRoot, 'OrdinalIgnoreCase') -or
                ($curto -and $exe.StartsWith($curto, 'OrdinalIgnoreCase'))) { $vivos += $exe }
        }
        if ($vivos.Count -gt 0) {
            Relata 'INSTANCIA_VIVA' $plano ("ha {0} janela(s) deste produto abertas: {1}" -f $vivos.Count, $vivos[0])
            exit 2
        }
    } catch {
        # Nao saber responder nao autoriza escrever embaixo de uma instancia
        # viva: na duvida, recusa (C.3).
        Relata 'FALHOU' $plano ("nao foi possivel conferir se o produto ja esta aberto: " + $_.Exception.Message)
        exit 1
    }
}

# ===================================================== 7. aplicar (R6)
#
# ORDEM, e ela e o contrato do fail-loud:
#   1. INCOMPLETO.txt entra ANTES da primeira escrita;
#   2. arquivos e chaves;
#   3. INCOMPLETO.txt sai;
#   4. base.json por ULTIMO.
# Morrer em qualquer ponto deixa a base APONTANDO PARA O TEMPLATE ANTIGO - o
# perfil nunca passa por atualizado - e deixa o marcador para o launcher
# recusar abrir e dizer por que.

try {
    if (-not (Test-Path -LiteralPath $baseDir)) { New-Item -ItemType Directory -Path $baseDir -Force | Out-Null }
    Set-Content -LiteralPath $incompletoArq -Encoding ASCII -Value @(
        "IMAN Terra - reconciliacao do perfil EM ANDAMENTO.",
        ("iniciada em : " + (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')),
        ("template    : " + $templateDigest),
        ("plano       : arq+{0} arq~{1} arq-{2} chave+{3} chave~{4} chave-{5}" -f `
            $plano.ArqNovos, $plano.ArqTrocados, $plano.ArqRemovidos,
            $plano.ChaveNovas, $plano.ChaveTrocadas, $plano.ChaveRemovidas),
        "",
        "Se este arquivo existir, a rodada anterior NAO terminou. O perfil pode",
        "estar meio aplicado. A base (base.json) NAO foi atualizada, entao a",
        "proxima abertura refaz o plano inteiro."
    )

    foreach ($rel in $remover) {
        $alvo = Join-Path $Perfil ($rel -replace '/', '\')
        if (Test-Path -LiteralPath $alvo) { Remove-Item -LiteralPath $alvo -Force -Recurse }
    }
    foreach ($rel in $criarDir) {
        New-Item -ItemType Directory -Path (Join-Path $Perfil ($rel -replace '/', '\')) -Force | Out-Null
    }
    foreach ($rel in $copiar) {
        $de = Join-Path $Template ($rel -replace '/', '\')
        $para = Join-Path $Perfil ($rel -replace '/', '\')
        $dir = Split-Path -Parent $para
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Copy-Item -LiteralPath $de -Destination $para -Force
    }

    if ($chavesAplicar.Count -gt 0 -or $chavesRemover.Count -gt 0) {
        $iniP = LeIni $iniPerfil
        $bom = [bool]$iniP.Bom
        $linhas = New-Object System.Collections.ArrayList
        [void]$linhas.AddRange($iniP.Linhas)

        # Remocoes de tras para a frente: apagar uma linha mexe no indice de
        # todas as seguintes.
        $apagar = New-Object System.Collections.ArrayList
        foreach ($k in $chavesRemover) { if ($iniP.Indices.ContainsKey($k)) { [void]$apagar.Add($iniP.Indices[$k]) } }
        foreach ($i in (@($apagar) | Sort-Object -Descending)) { $linhas.RemoveAt($i) }

        foreach ($c in $chavesAplicar) {
            $k = [string]$c.K
            $sec, $nome = $k -split '/', 2
            $mapa = MapeiaIni @($linhas)     # recalculado a cada chave
            if ($mapa.Indices.ContainsKey($k)) {
                $i = $mapa.Indices[$k]
                $linhas[$i] = TrocaValor ([string]$linhas[$i]) ([string]$c.Valor)
            } elseif ($mapa.FimSecao.ContainsKey($sec)) {
                $linhas.Insert($mapa.FimSecao[$sec] + 1, ("{0}={1}{2}" -f $nome, $c.Valor, $mapa.Fim))
            } else {
                # Secao inexistente (ex.: [UI] chegando a um perfil anterior a
                # e9efa77). Entra no fim, com a ultima linha terminada.
                if ($linhas.Count -gt 0) {
                    $ultima = [string]$linhas[$linhas.Count - 1]
                    if ($ultima -ne '' -and $ultima -notmatch '\n$') { $linhas[$linhas.Count - 1] = $ultima + $mapa.Fim }
                }
                [void]$linhas.Add("[$sec]" + $mapa.Fim)
                [void]$linhas.Add(("{0}={1}{2}" -f $nome, $c.Valor, $mapa.Fim))
            }
        }
        GravaIni @($linhas) $bom $iniPerfil
    }

    if ($splashPrecisa) {
        $dirQgis = Split-Path -Parent $splashArq
        if (-not (Test-Path -LiteralPath $dirQgis)) { New-Item -ItemType Directory -Path $dirQgis -Force | Out-Null }
        [System.IO.File]::WriteAllText($splashArq, $splashAlvo, (New-Object System.Text.UTF8Encoding($false)))
    }

    # -------- a base, por ULTIMO e so agora (R3) ---------------------------
    $chavesBase = [ordered]@{}
    $iniT2 = LeIni $iniTemplate
    foreach ($k in ($iniT2.Chaves.Keys | Sort-Object)) { $chavesBase[$k] = [string]$iniT2.Chaves[$k] }
    $arquivosBase = [ordered]@{}
    foreach ($rel in ($hashTemplate.Keys | Sort-Object)) { $arquivosBase[$rel] = $hashTemplate[$rel] }

    $registro = [ordered]@{
        _leia = ("A BASE do 3-way (DB-26). Escrita pelo produto, POR CONTEUDO: e o template " +
                 "que este perfil recebeu por ultimo. Apagar este arquivo nao quebra nada - a " +
                 "proxima abertura reaplica as chaves do produto uma vez e o registra de novo.")
        esquema = 1
        gerado_em = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        template_digest = $templateDigest
        chaves = $chavesBase
        arquivos = $arquivosBase
    }
    $tmpBase = "$baseArq.iman-tmp"
    ($registro | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $tmpBase -Encoding UTF8
    Move-Item -LiteralPath $tmpBase -Destination $baseArq -Force

    Remove-Item -LiteralPath $incompletoArq -Force -ErrorAction SilentlyContinue
} catch {
    Relata 'FALHOU' $plano ("ao aplicar: " + $_.Exception.Message)
    exit 1
}

Relata $(if ($semear) { 'SEMEADO' } else { 'APLICADA' }) $plano
exit 0
