<#
=============================================================================
 #022 - GUARDA ESTATICA DO TEMA (style.qss)

 POR QUE ELA EXISTE, na palavra do arquiteto: "screenshot nao distingue 2px de
 5px". As entregas visuais do #022 (raio 2px, densidade da barra de menus) nao
 tinham asse rcao nenhuma. Trocar 11 das 12 declaracoes e esquecer uma passaria
 despercebido - e passaria no aceite, que sobe o QGIS e mede widget, mas nao
 mede QUANTO vale um raio.

 As duas ultimas asse rcoes fazem mais do que guardar esta fatia: elas
 transformam a cerca de prosa do briefing em guarda de verdade, reprovando a
 REGRESSAO do D2 (padding no QStatusBar espremia o campo de coordenadas) e do
 D4 (padding vertical no QDockWidget::title cortava o glifo do titulo) - e sem
 precisar subir o QGIS.

 O QUE ELA ASSERE
   1. ha exatamente 12 declaracoes de `border-radius`, e todas valem 2px;
   2. `QMenuBar::item` tem padding exatamente `3px 4px`;
   3. `QStatusBar` NAO tem declaracao de padding            (regressao do D2);
   4. `QDockWidget::title` NAO tem padding vertical         (regressao do D4);
   5. os 2 cantos especificos da aba valem 2px           (extensao declarada).

 SAIDA: exit 0 se tudo passa; exit 1 nomeando ARQUIVO e LINHA do que falhou.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-tema-qss.ps1

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    [string]$Qss = ''
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$raizRepo   = (Get-Item (Join-Path $raizScript '..')).FullName
if ([string]::IsNullOrWhiteSpace($Qss)) {
    $Qss = Join-Path $raizRepo 'app\profile-template\iman-distro\themes\IMAN Terra\style.qss'
}

$RAIO_ESPERADO       = 2
$RAIOS_ESPERADOS     = 12
$CANTOS_ESPERADOS    = 2
$MENUBAR_PADDING     = '3px 4px'

function Escreve { param([string]$T, [string]$C = 'Gray') Write-Host $T -ForegroundColor $C }

Write-Host ''
Write-Host '  #022 - guarda estatica do tema' -ForegroundColor White
Write-Host "  qss : $Qss"
Write-Host ''

if (-not (Test-Path -LiteralPath $Qss)) {
    Escreve "  ABORTADO: style.qss nao encontrado em $Qss" 'Red'
    exit 2
}

# Ler LINHA A LINHA de proposito: a falha tem de nomear arquivo E linha, senao
# ela diz "algo esta errado" e devolve a busca para quem ja estava perdido.
$linhas = @(Get-Content -LiteralPath $Qss)
$rel = $Qss.Replace($raizRepo, '').TrimStart('\')

$falhas = New-Object System.Collections.ArrayList
function Reprova { param([int]$Linha, [string]$Texto)
    [void]$falhas.Add([pscustomobject]@{ Linha = $Linha; Texto = $Texto })
}

# ---- 1. border-radius: exatamente 12, todos 2px -----------------------------
# `border-radius` NAO casa com `border-top-left-radius` (a substring difere),
# entao as duas contagens sao independentes de verdade.
$raios = New-Object System.Collections.ArrayList
for ($i = 0; $i -lt $linhas.Count; $i++) {
    foreach ($m in [regex]::Matches($linhas[$i], '(?<![-\w])border-radius\s*:\s*(\d+)px')) {
        [void]$raios.Add([pscustomobject]@{ Linha = $i + 1; Valor = [int]$m.Groups[1].Value })
    }
}
$foraDoRaio = @($raios | Where-Object { $_.Valor -ne $RAIO_ESPERADO })
if ($raios.Count -ne $RAIOS_ESPERADOS) {
    Reprova 0 ("[1] esperava $RAIOS_ESPERADOS declaracoes de border-radius, achei $($raios.Count). " +
               "Se uma regra nasceu ou morreu, a contagem esperada muda AQUI, deliberadamente.")
}
foreach ($r in $foraDoRaio) {
    Reprova $r.Linha "[1] border-radius: $($r.Valor)px  (esperado ${RAIO_ESPERADO}px)"
}
Escreve ("  [1] border-radius : {0} declaracoes, {1} fora de {2}px" -f $raios.Count, $foraDoRaio.Count, $RAIO_ESPERADO) `
        $(if ($raios.Count -eq $RAIOS_ESPERADOS -and $foraDoRaio.Count -eq 0) { 'Green' } else { 'Red' })

# ---- 2. QMenuBar::item padding exatamente 3px 4px ---------------------------
$menubar = $null
for ($i = 0; $i -lt $linhas.Count; $i++) {
    if ($linhas[$i] -match 'QMenuBar::item\s*\{') {
        $m = [regex]::Match($linhas[$i], 'padding\s*:\s*([^;}]+)')
        $menubar = [pscustomobject]@{ Linha = $i + 1; Valor = $(if ($m.Success) { $m.Groups[1].Value.Trim() } else { '<ausente>' }) }
        break
    }
}
if ($null -eq $menubar) {
    Reprova 0 '[2] regra QMenuBar::item nao encontrada'
} elseif ($menubar.Valor -ne $MENUBAR_PADDING) {
    Reprova $menubar.Linha "[2] QMenuBar::item padding: '$($menubar.Valor)'  (esperado '$MENUBAR_PADDING')"
}
Escreve ("  [2] QMenuBar::item : padding '{0}'" -f $(if ($menubar) { $menubar.Valor } else { '<ausente>' })) `
        $(if ($menubar -and $menubar.Valor -eq $MENUBAR_PADDING) { 'Green' } else { 'Red' })

# ---- 3. QStatusBar SEM padding (regressao do D2) ----------------------------
# O QGIS FIXA a largura do campo de coordenadas (min == max). Num widget de
# largura fixa, padding do QSS e SUBTRACAO: 2px 8px mais a borda comiam 18 dos
# 24px e sobrava espaco para 1 caractere de 19. Quem reserva a largura e o
# plugin de marca, nao o tema.
$statusComPadding = @()
for ($i = 0; $i -lt $linhas.Count; $i++) {
    $l = $linhas[$i]
    if ($l -match '^\s*/\*' -or $l -match '^\s*\*') { continue }   # comentario
    if ($l -notmatch 'QStatusBar') { continue }
    if ($l -match '(?<![-\w])padding(-top|-bottom|-left|-right)?\s*:') {
        $statusComPadding += [pscustomobject]@{ Linha = $i + 1; Texto = $l.Trim() }
    }
}
foreach ($s in $statusComPadding) {
    Reprova $s.Linha "[3] QStatusBar voltou a ter padding (D2): $($s.Texto)"
}
Escreve ("  [3] QStatusBar     : {0} declaracao(oes) de padding" -f $statusComPadding.Count) `
        $(if ($statusComPadding.Count -eq 0) { 'Green' } else { 'Red' })

# ---- 4. QDockWidget::title SEM padding vertical (regressao do D4) -----------
# A altura da faixa de titulo o Qt calcula a partir da FONTE; padding vertical
# nao a faz crescer - so come o espaco do texto, e o glifo sai cortado ao meio.
# O recuo HORIZONTAL pode ficar (nao mexe na altura).
$dockVertical = @()
for ($i = 0; $i -lt $linhas.Count; $i++) {
    $l = $linhas[$i]
    if ($l -match '^\s*/\*' -or $l -match '^\s*\*') { continue }
    if ($l -notmatch 'QDockWidget::title') { continue }
    foreach ($m in [regex]::Matches($l, '(?<![-\w])padding(-top|-bottom)?\s*:\s*([^;}]+)')) {
        $prop = 'padding' + $m.Groups[1].Value
        # `padding: <...>` com 1..4 valores SEMPRE define o vertical.
        if ($m.Groups[1].Value -ne '' -or $true) {
            if ($prop -eq 'padding' -or $prop -eq 'padding-top' -or $prop -eq 'padding-bottom') {
                $dockVertical += [pscustomobject]@{ Linha = $i + 1; Texto = ($prop + ':' + $m.Groups[2].Value).Trim() }
            }
        }
    }
}
foreach ($d in $dockVertical) {
    Reprova $d.Linha "[4] QDockWidget::title voltou a ter padding vertical (D4): $($d.Texto)"
}
Escreve ("  [4] QDockWidget::title : {0} declaracao(oes) de padding vertical" -f $dockVertical.Count) `
        $(if ($dockVertical.Count -eq 0) { 'Green' } else { 'Red' })

# ---- 5. cantos especificos da aba (extensao declarada do #022) --------------
$cantos = New-Object System.Collections.ArrayList
for ($i = 0; $i -lt $linhas.Count; $i++) {
    foreach ($m in [regex]::Matches($linhas[$i], 'border-(?:top|bottom)-(?:left|right)-radius\s*:\s*(\d+)px')) {
        [void]$cantos.Add([pscustomobject]@{ Linha = $i + 1; Valor = [int]$m.Groups[1].Value })
    }
}
$foraDoCanto = @($cantos | Where-Object { $_.Valor -ne $RAIO_ESPERADO })
if ($cantos.Count -ne $CANTOS_ESPERADOS) {
    Reprova 0 "[5] esperava $CANTOS_ESPERADOS cantos especificos, achei $($cantos.Count)"
}
foreach ($c in $foraDoCanto) {
    Reprova $c.Linha "[5] border-*-radius: $($c.Valor)px  (esperado ${RAIO_ESPERADO}px)"
}
Escreve ("  [5] cantos da aba  : {0} declaracoes, {1} fora de {2}px" -f $cantos.Count, $foraDoCanto.Count, $RAIO_ESPERADO) `
        $(if ($cantos.Count -eq $CANTOS_ESPERADOS -and $foraDoCanto.Count -eq 0) { 'Green' } else { 'Red' })

# ------------------------------------------------------------------ veredito
Write-Host ''
if ($falhas.Count -eq 0) {
    Escreve '  5 de 5 asse rcoes passaram. O tema esta como o sponsor arbitrou.' 'Green'
    Write-Host ''
    exit 0
}
Escreve "  GUARDA REPROVOU - $($falhas.Count) problema(s):" 'Red'
foreach ($f in $falhas) {
    if ($f.Linha -gt 0) {
        Escreve ("    {0}:{1}  {2}" -f $rel, $f.Linha, $f.Texto) 'Yellow'
    } else {
        Escreve ("    {0}      {1}" -f $rel, $f.Texto) 'Yellow'
    }
}
Write-Host ''
exit 1
