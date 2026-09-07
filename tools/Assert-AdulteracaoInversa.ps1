<#
=============================================================================
 #018 - GATE DE ADULTERACAO INVERSA

 Uma baseline verde nao prova nada sozinha: ela pode significar "os defeitos
 sairam" ou "as assercoes morreram". Este gate separa os dois casos.

 Para CADA defeito consertado:
   1. reverte o conserto no codigo (uma edicao pequena e reversivel);
   2. roda o teste de aceite;
   3. exige que a assercao daquele defeito volte a FAIL - e que NENHUMA outra
      mude de status;
   4. restaura o codigo com `git checkout --`.

 Assercao que NAO volta a vermelho quando o defeito volta e assercao MORTA, e
 reprova a fatia mesmo com tudo verde. Assercao que arrasta OUTRAS junto esta
 acoplada e tambem e relatada.

 Este script NAO altera o teste de aceite - so o codigo de produto. Ele exige
 arvore limpa para comecar e a devolve limpa.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Assert-AdulteracaoInversa.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Assert-AdulteracaoInversa.ps1 -Somente D1,D4

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    [string[]]$Somente = @(),
    [string]$OutDir = '',
    [int]$Espera = 240
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$raizRepo   = (Get-Item (Join-Path $raizScript '..')).FullName
if ([string]::IsNullOrEmpty($OutDir)) { $OutDir = Join-Path $raizScript 'adulteracao' }
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$QSS     = Join-Path $raizRepo 'app\profile-template\iman-distro\themes\IMAN Terra\style.qss'
$PLUGIN  = Join-Path $raizRepo 'app\profile-template\iman-distro\python\plugins\iman_brand\iman_brand.py'
$DASH    = Join-Path $raizRepo 'app\profile-template\iman-distro\python\plugins\iman_brand\dashboard.py'
$BRAND   = Join-Path $raizRepo 'app\profile-template\iman-distro\python\plugins\iman_brand\brand.py'
$STARTUP = Join-Path $raizRepo 'app\startup\iman_startup.py'

# Cada entrada devolve o defeito ao codigo. `De` TEM de existir no arquivo -
# se nao existir, o gate aborta: uma reversao que nao reverte nada tornaria o
# proprio gate teatro.
$Reversoes = @(
    @{ Id='D1';  Assercao='A01'; Arquivo=$QSS;
       De='QDockWidget::title {';
       Para="QDockWidget { titlebar-close-icon: none; }`nQDockWidget::title {" },

    # Acoplamento ESPERADO e declarado: o criterio do A03 e RELATIVO ("o campo
    # nao passa de 3x a largura de antes"), e quem define a largura de partida
    # e justamente o piso do D2. Tirar o piso acende os dois.
    @{ Id='D2';  Assercao='A02'; Arquivo=$PLUGIN; Acoplamento=@('A03');
       De='piso = fm.horizontalAdvance(COORD_REFERENCIA) + cromo + 2';
       Para='piso = 0  # REVERTIDO' },

    @{ Id='D3';  Assercao='A03'; Arquivo=$PLUGIN;
       De='teto = fm.horizontalAdvance(EXTENSAO_REFERENCIA) + cromo + 2';
       Para='teto = 16777215  # REVERTIDO' },

    # ACOPLAMENTO MEDIDO E DECLARADO: reverter o D2 tambem acende o A03,
    # porque o criterio do A03 e RELATIVO ("o campo nao passa de 3x a largura
    # de antes") e quem define essa largura de partida e o piso do D2. Nao e
    # assercao morta nem acoplamento escondido - esta na tabela do laudo.

    @{ Id='D4';  Assercao='A04'; Arquivo=$QSS;
       De='padding-left: 10px; padding-right: 10px;';
       Para='padding: 6px 10px;' },

    @{ Id='D5';  Assercao='A05'; Arquivo=$PLUGIN;
       De='        return re.sub(r''QGIS(\s*)$'', brand.PRODUCT_NAME + r''\1'', titulo)';
       Para='        return brand.WINDOW_TITLE  # REVERTIDO' },

    # Acoplamento ESPERADO: o A07 assere a politica INTEIRA, e o estado E4
    # ("criou um projeto -> canvas") e justamente o que o D6 conserta. Os dois
    # cobrirem o mesmo estado e desenho, nao acidente.
    @{ Id='D6';  Assercao='A06'; Arquivo=$PLUGIN; Acoplamento=@('A07');
       De="        # E4 - criou um projeto -> canvas. Antes desta fatia era _show_home(),`n        # e o comando `"Novo projeto`" parecia inerte (D6).`n        if not self._pousou:`n            return`n        self._show_canvas()";
       Para="        if not self._pousou:`n            return`n        self._show_home()  # REVERTIDO" },

    # D7 - LIMITE DECLARADO. Reverter o pouso-por-estado para pouso-por-evento
    # NAO re-arma o gatilho no codigo de hoje: medido tres vezes seguidas, o
    # A07b continuou PASS. O gatilho original era uma CORRIDA entre o evento de
    # arranque e o QTimer de 900 ms, e as mudancas de D8 e D12 deslocaram esse
    # tempo. Como o gate nao consegue reproduzir a corrida, ele prova o que
    # consegue: que o A07b ESTA VIVO - forcando um pouso errado, ele acende.
    # Isso NAO prova que o _decide_pouso e o que mantem o A07b verde.
    @{ Id='D7-vivacidade'; Assercao='A07b'; Arquivo=$PLUGIN; Fase='segunda';
       De='            self._show_home()        # E1 - o pouso';
       Para='            self._show_canvas()  # POUSO ERRADO DE PROPOSITO' },

    # D8 - o revert precisa reintroduzir a constante E RENDERIZA-LA. So
    # declarar TEMPLATES nao acende o A08, porque nada dela chegaria a tela -
    # e a assercao mede o que CHEGA A TELA, nao o que existe no codigo.
    @{ Id='D8';  Assercao='A08'; Arquivo=$DASH;
       De='def recentes_reais(limite=MAX_RECENTES):';
       Para=@'
TEMPLATES = [("Projeto cadastral vazio", "EPSG:31984"),
             ("Memorial descritivo", "Vertices - Azimutes")]


def recentes_reais(limite=MAX_RECENTES):
    return list(TEMPLATES)  # REVERTIDO: dado inventado de volta na tela


def _recentes_reais_original(limite=MAX_RECENTES):
'@ },

    @{ Id='D9';  Assercao='A09'; Arquivo=$BRAND;
       De='VERSION = "0.3.0"';
       Para='VERSION = "0.1.0"' },

    @{ Id='D10'; Assercao='A10'; Arquivo=$PLUGIN;
       De='            menu.addAction(self._acao_sobre_ajuda)';
       Para='            pass  # REVERTIDO' },

    @{ Id='D12'; Assercao='A12'; Arquivo=$STARTUP;
       De='    _aplica_tema_ui()';
       Para='    pass  # REVERTIDO' }
)

function Escreve { param([string]$T, [string]$C = 'Gray') Write-Host $T -ForegroundColor $C }

function Get-Placar {
    param([string]$Fase)
    $saida = Join-Path $env:LOCALAPPDATA 'InstitutoIMAN\_aceite017\saida'
    $arq = Join-Path $saida $(if ($Fase -eq 'segunda') { 'aceite-segunda.json' } else { 'aceite.json' })
    if (Test-Path -LiteralPath $arq) { Remove-Item -LiteralPath $arq -Force }

    $aceite = Join-Path $raizScript 'branding-acceptance\Invoke-Aceite.ps1'

    # A 2a execucao roda com -ReusarPerfil, que NAO reconstroi o perfil. Sem uma
    # 1a execucao antes, o codigo adulterado no repo nunca chegaria ao perfil e
    # a rodada mediria a versao anterior - foi o que aconteceu em 2026-09-07 e
    # fez o gate acusar o A07b de morto sem ele nunca ter visto a adulteracao.
    if ($Fase -eq 'segunda') {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $aceite `
            -Espera $Espera | Out-Null
        Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    $argv = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $aceite,
              '-Espera', "$Espera")
    if ($Fase -eq 'segunda') { $argv += @('-ReusarPerfil', '-Fase', 'segunda') }
    & powershell.exe @argv | Out-Null
    Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    if (-not (Test-Path -LiteralPath $arq)) { return $null }
    $doc = Get-Content -LiteralPath $arq -Raw | ConvertFrom-Json
    if (-not $doc.baseline.valido) { return $null }
    $h = @{}
    foreach ($r in $doc.resultados) { $h[$r.id] = $r.status }
    return $h
}

# --------------------------------------------------------------- arvore limpa
$sujo = & git -C $raizRepo status --porcelain
if ($sujo) {
    Escreve '  A arvore precisa estar limpa: o gate reverte e restaura com git checkout.' 'Red'
    $sujo | ForEach-Object { Escreve "    $_" }
    exit 2
}

Escreve ''
Escreve '  #018 - GATE DE ADULTERACAO INVERSA' 'White'
Escreve '  Reverte cada conserto e exige que SO a assercao dele volte a vermelho.'
Escreve ''

# ------------------------------------------------------ referencia (tudo verde)
Escreve '  medindo a referencia (codigo integro)...' 'DarkGray'
$refPrim = Get-Placar -Fase 'primeira'
$refSeg  = Get-Placar -Fase 'segunda'
if ($null -eq $refPrim -or $null -eq $refSeg) {
    Escreve '  ABORTADO: a referencia nao produziu baseline valido.' 'Red'
    exit 2
}
$refTodos = @{}
foreach ($k in $refPrim.Keys) { $refTodos[$k] = $refPrim[$k] }
foreach ($k in $refSeg.Keys)  { $refTodos[$k] = $refSeg[$k] }
$vermelhosRef = @($refTodos.Keys | Where-Object { $refTodos[$_] -eq 'FAIL' })
Escreve ("  referencia: {0} assercoes, {1} FAIL" -f $refTodos.Count, $vermelhosRef.Count) 'Green'
Escreve ''

$linhas = @()
$reprovas = @()

foreach ($rev in $Reversoes) {
    if ($Somente.Count -gt 0 -and $Somente -notcontains $rev.Id) { continue }

    $fase = if ($rev.Fase) { $rev.Fase } else { 'primeira' }
    Escreve ("  {0} -> reverte o conserto e espera {1} vermelho" -f $rev.Id, $rev.Assercao) 'Yellow'

    # Normaliza para LF antes de casar: o git devolve os arquivos com CRLF no
    # checkout, e um anchor de varias linhas escrito com LF nunca casaria.
    $orig = [IO.File]::ReadAllText($rev.Arquivo).Replace("`r`n", "`n")
    if ($orig.IndexOf($rev.De) -lt 0) {
        Escreve ("     ABORTADO: o trecho a reverter nao existe em {0}" -f (Split-Path -Leaf $rev.Arquivo)) 'Red'
        Escreve  '     Uma reversao que nao reverte nada tornaria este gate teatro.' 'Red'
        & git -C $raizRepo checkout -- . | Out-Null
        exit 2
    }
    [IO.File]::WriteAllText($rev.Arquivo, $orig.Replace($rev.De, $rev.Para))

    try {
        $h = Get-Placar -Fase $fase
    } finally {
        & git -C $raizRepo checkout -- . | Out-Null
    }

    if ($null -eq $h) {
        $linhas += [pscustomobject]@{ Defeito=$rev.Id; Assercao=$rev.Assercao
            StatusDaAssercao='<sem baseline>'; Voltou=$false; Arrastou=@(); Ok=$false }
        $reprovas += ("{0}: a rodada revertida nao produziu baseline valido" -f $rev.Id)
        Escreve '     rodada invalida' 'Red'
        continue
    }

    $status = $h[$rev.Assercao]
    $voltou = ($status -eq 'FAIL')

    # quem mais mudou de status em relacao a referencia?
    $esperados = @()
    if ($rev.Acoplamento) { $esperados = $rev.Acoplamento }
    $arrastou = @()
    $arrastouEsperado = @()
    foreach ($k in $h.Keys) {
        if ($k -eq $rev.Assercao) { continue }
        if ($refTodos.ContainsKey($k) -and $h[$k] -ne $refTodos[$k]) {
            if ($esperados -contains $k) { $arrastouEsperado += $k } else { $arrastou += $k }
        }
    }

    $ok = $voltou -and ($arrastou.Count -eq 0)
    $linhas += [pscustomobject]@{ Defeito=$rev.Id; Assercao=$rev.Assercao
        StatusDaAssercao=$status; Voltou=$voltou; Arrastou=$arrastou
        ArrastouEsperado=$arrastouEsperado; Ok=$ok }

    if (-not $voltou) {
        $reprovas += ("{0}: {1} NAO voltou a vermelho (status {2}) - assercao morta" -f $rev.Id, $rev.Assercao, $status)
        Escreve ("     {0} ficou {1} - ASSERCAO MORTA" -f $rev.Assercao, $status) 'Red'
    } elseif ($arrastou.Count -gt 0) {
        $reprovas += ("{0}: arrastou junto {1}" -f $rev.Id, ($arrastou -join ', '))
        Escreve ("     {0} voltou a FAIL, mas arrastou: {1}" -f $rev.Assercao, ($arrastou -join ', ')) 'Red'
    } elseif ($arrastouEsperado.Count -gt 0) {
        Escreve ("     {0} voltou a FAIL; junto veio {1}, acoplamento DECLARADO" -f
            $rev.Assercao, ($arrastouEsperado -join ', ')) 'Green'
    } else {
        Escreve ("     {0} voltou a FAIL, e so ela" -f $rev.Assercao) 'Green'
    }
}

$doc = [pscustomobject]@{
    QuandoUtc = (Get-Date).ToUniversalTime().ToString('o')
    Referencia = $refTodos
    Resultados = $linhas
    Reprovas = $reprovas
}
$doc | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $OutDir 'adulteracao-inversa.json') -Encoding UTF8

Escreve ''
Escreve ("  {0} de {1} reversoes acenderam a assercao certa, e so ela." -f
    (@($linhas | Where-Object { $_.Ok }).Count), $linhas.Count) 'White'
if ($reprovas.Count -gt 0) {
    Escreve ''
    foreach ($r in $reprovas) { Escreve "  REPROVA: $r" 'Red' }
    exit 1
}
Escreve '  GATE OK - nenhuma assercao morta, nenhum acoplamento.' 'Green'
exit 0
