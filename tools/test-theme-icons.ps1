<#
=============================================================================
 #041 - GUARDA DO TEMA DE ICONES (forense R2, R3, R4; D-IMAN-039)

 POR QUE ELA EXISTE. Desde o #041 o tema "IMAN Terra" entra no arranque e a
 pasta icons\ dele SUBSTITUI icones do QGIS por nome. O QGIS so testa se o
 arquivo existe: um SVG vazio vira botao sem icone, uma extensao trocada cai no
 padrao em silencio, e uma imagem do QSS com nome de icone troca os dois de uma
 vez. Nenhum desses erros da mensagem. Esta guarda os torna altos.

 O QUE ELA ASSERE, para cada arquivo de <tema>\icons\ (subpastas inclusive):
   A1 o nome, com subpasta e extensao, EXISTE no tema padrao, enumerado na hora
      do recurso :/images/themes/default/ da arvore do QGIS (nao de lista
      copiada). Arquivos qss-* sao imagens do QSS e ficam fora desta regra;
   A2 renderiza a 16 e a 24 px, e a imagem nao e transparente nem de cor unica;
   A3 toda imagem que o style.qss cita como @theme_path/icons/<nome> leva o
      prefixo qss- e nao colide com nome de icone do padrao;
   A4 icons\providerQgis.svg e a derivacao do master vetorial de app\assets\
      (app\assets\derive-theme-icons.py --check): o simbolo tem fonte unica.

 GUARDA SO VALE VISTA FALHANDO. Sem -SemAdulteracao, a guarda tambem roda sobre
 TRES copias adulteradas do tema e exige que cada uma seja reprovada, pela
 asse rcao certa:
   V1 providerQgis.svg vazio (svg sem desenho)        -> A2 reprova
   V2 um icone com a extensao trocada (.svg por .png) -> A1 reprova
   V3 o style.qss cita uma imagem com nome de icone   -> A3 reprova
 Uma adulteracao que passa e guarda morta, e reprova esta guarda.

 ONDE RODA. No Python da arvore do QGIS (python-qgis-ltr.bat). Default: a arvore
 do produto instalado; o build passa -Qgis com a arvore estagiada. Recusa raiz
 sob %ProgramFiles% (o mesmo motivo do aceite: mediria outro QGIS).
 BL-3: o QgsApplication da sonda usa QGIS_CUSTOM_CONFIG_PATH numa pasta
 temporaria; nada e escrito em %APPDATA%\QGIS.

 SAIDA: exit 0 se tudo passa; exit 1 nomeando o arquivo e a asse rcao. A ultima
 linha util e o placar "N de M asse rcoes passaram", que o build.ps1 le.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-theme-icons.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-theme-icons.ps1 -Qgis <raiz>

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    [string]$Tema = '',
    [string]$Qgis = '',
    [switch]$SemAdulteracao
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$raizRepo   = (Get-Item (Join-Path $raizScript '..')).FullName
if (-not $Tema) { $Tema = Join-Path $raizRepo 'app\profile-template\iman-distro\themes\IMAN Terra' }
if (-not $Qgis) { $Qgis = Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra\qgis' }
$Qgis = [IO.Path]::GetFullPath($Qgis)
$sonda  = Join-Path $raizScript 'brand-guards\theme_icons_probe.py'
$derive = Join-Path $raizRepo 'app\assets\derive-theme-icons.py'

function Escreve { param([string]$T, [string]$C = 'Gray') Write-Host $T -ForegroundColor $C }

Write-Host ''
Write-Host '  #041 - guarda do tema de icones' -ForegroundColor White
Write-Host "  tema : $Tema"
Write-Host "  qgis : $Qgis"
Write-Host ''

foreach ($proibido in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
    if ($proibido -and $Qgis.ToLower().StartsWith($proibido.ToLower())) {
        Escreve "  ABORTADO: a raiz '$Qgis' cai em '$proibido'. A guarda mede a arvore do produto." 'Red'
        exit 2
    }
}
$py = Join-Path $Qgis 'bin\python-qgis-ltr.bat'
foreach ($p in @($py, $sonda, $derive, $Tema)) {
    if (-not (Test-Path -LiteralPath $p)) { Escreve "  ABORTADO: nao existe $p" 'Red'; exit 2 }
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) ('iman-theme-icons-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$env:QGIS_CUSTOM_CONFIG_PATH = Join-Path $tmp 'qgis-config'
$env:PYTHONDONTWRITEBYTECODE = '1'

# Roda a sonda sobre um tema e devolve o JSON medido.
function Mede([string]$Dir, [string]$Rotulo) {
    $out = Join-Path $tmp ("medida-$Rotulo.json")
    $log = (& $py $sonda $Dir $out 2>&1 | Out-String)
    if (-not (Test-Path -LiteralPath $out)) {
        throw "a sonda nao gravou medida para '$Rotulo'. Saida: $log"
    }
    return (Get-Content -LiteralPath $out -Raw -Encoding UTF8 | ConvertFrom-Json)
}

# Avalia uma medida. Devolve as reprovacoes, cada uma com a asse rcao (A1..A3).
function Avalia($Medida) {
    $r = New-Object System.Collections.ArrayList
    if ([int]$Medida.default_count -lt 100) {
        [void]$r.Add([pscustomobject]@{ A = 'A1'; Texto = ("o tema padrao enumerou so {0} nomes; o recurso :/images/themes/default/ nao foi lido" -f $Medida.default_count) })
    }
    foreach ($f in @($Medida.files)) {
        if (-not $f.qss_image -and -not $f.in_default) {
            [void]$r.Add([pscustomobject]@{ A = 'A1'; Texto = ("icons/{0}: o tema padrao nao tem este nome (subpasta e extensao inclusive); o QGIS nunca o pediria" -f $f.name) })
        }
        foreach ($tam in @('16', '24')) {
            $m = $f.renders.$tam
            if ($null -eq $m) {
                [void]$r.Add([pscustomobject]@{ A = 'A2'; Texto = ("icons/{0}: nao renderiza a {1} px (arquivo invalido)" -f $f.name, $tam) })
            } elseif ([int]$m.pixels_with_ink -eq 0) {
                [void]$r.Add([pscustomobject]@{ A = 'A2'; Texto = ("icons/{0}: transparente a {1} px (nenhum pixel com tinta)" -f $f.name, $tam) })
            } elseif ([int]$m.distinct -lt 2) {
                [void]$r.Add([pscustomobject]@{ A = 'A2'; Texto = ("icons/{0}: cor unica a {1} px" -f $f.name, $tam) })
            }
        }
    }
    foreach ($q in @($Medida.qss_images)) {
        if (-not $q.prefixed) {
            [void]$r.Add([pscustomobject]@{ A = 'A3'; Texto = ("style.qss cita @theme_path/icons/{0} sem o prefixo qss-" -f $q.name) })
        }
        if ($q.collides_with_default) {
            [void]$r.Add([pscustomobject]@{ A = 'A3'; Texto = ("style.qss cita @theme_path/icons/{0}, que e nome de icone do QGIS: trocaria os dois" -f $q.name) })
        }
    }
    return , @($r)
}

$falhas  = New-Object System.Collections.ArrayList
$rodadas = New-Object System.Collections.ArrayList
$passou  = 0

try {
    # ---------------------------------------------------- o tema de verdade
    $medida = Mede $Tema 'tema'
    $reprovas = Avalia $medida
    Escreve ("  tema padrao: {0} nomes enumerados de {1}" -f $medida.default_count, $medida.default_root)
    foreach ($f in @($medida.files)) {
        Escreve ("    icons/{0,-28} padrao={1,-5} 16px={2} cores  24px={3} cores" -f $f.name, $f.in_default,
                 $(if ($f.renders.'16') { $f.renders.'16'.distinct } else { '-' }),
                 $(if ($f.renders.'24') { $f.renders.'24'.distinct } else { '-' }))
    }
    if (@($medida.files).Count -eq 0) {
        [void]$falhas.Add('o tema nao tem icons\ (o #041 entrega ao menos providerQgis.svg)')
    }
    foreach ($a in @('A1', 'A2', 'A3')) {
        $desta = @($reprovas | Where-Object { $_.A -eq $a })
        foreach ($x in $desta) { [void]$falhas.Add(("[{0}] {1}" -f $a, $x.Texto)) }
        $ok = ($desta.Count -eq 0) -and (@($medida.files).Count -gt 0)
        if ($ok) { $passou++ }
        [void]$rodadas.Add($a)
        Escreve ("  [{0}] {1}" -f $a, $(if ($ok) { 'PASS' } else { 'FAIL' })) $(if ($ok) { 'Green' } else { 'Red' })
    }

    # ---------------------------------------------- A4: a fonte unica do simbolo
    $chk = (& $py $derive --check 2>&1 | Out-String).Trim()
    $okA4 = ($LASTEXITCODE -eq 0)
    if (-not $okA4) { [void]$falhas.Add("[A4] $chk") } else { $passou++ }
    [void]$rodadas.Add('A4')
    Escreve ("  [A4] {0}  ({1})" -f $(if ($okA4) { 'PASS' } else { 'FAIL' }), $chk) $(if ($okA4) { 'Green' } else { 'Red' })

    # ------------------------------------- V1..V3: a guarda vista falhando
    if (-not $SemAdulteracao) {
        $adulteracoes = @(
            @{ Id = 'V1'; Espera = 'A2'; Descricao = 'providerQgis.svg vazio'; Faz = {
                param($d)
                Set-Content -LiteralPath (Join-Path $d 'icons\providerQgis.svg') -Encoding ASCII `
                    -Value '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"></svg>'
            } },
            @{ Id = 'V2'; Espera = 'A1'; Descricao = 'extensao trocada (mActionHelpSponsors.svg, o original e .png)'; Faz = {
                param($d)
                Copy-Item -LiteralPath (Join-Path $d 'icons\mIconNetworkLogger.svg') `
                          -Destination (Join-Path $d 'icons\mActionHelpSponsors.svg') -Force
            } },
            @{ Id = 'V3'; Espera = 'A3'; Descricao = 'style.qss cita @theme_path/icons/mActionZoomIn.svg'; Faz = {
                param($d)
                Add-Content -LiteralPath (Join-Path $d 'style.qss') -Encoding ASCII `
                    -Value 'QToolButton#imanAdulteracao { image: url(@theme_path/icons/mActionZoomIn.svg); }'
            } }
        )
        foreach ($ad in $adulteracoes) {
            $copia = Join-Path $tmp ("tema-" + $ad.Id)
            Copy-Item -LiteralPath $Tema -Destination $copia -Recurse -Force
            & $ad.Faz $copia
            $rep = Avalia (Mede $copia $ad.Id)
            $acertou = @($rep | Where-Object { $_.A -eq $ad.Espera }).Count -gt 0
            [void]$rodadas.Add($ad.Id)
            if ($acertou) {
                $passou++
                $quais = (@($rep | ForEach-Object { $_.A }) | Sort-Object -Unique) -join ','
                Escreve ("  [{0}] PASS  adulteracao '{1}' REPROVADA por {2}" -f $ad.Id, $ad.Descricao, $quais) 'Green'
            } else {
                [void]$falhas.Add(("[{0}] a adulteracao '{1}' NAO foi reprovada por {2}: guarda morta" -f $ad.Id, $ad.Descricao, $ad.Espera))
                Escreve ("  [{0}] FAIL  adulteracao '{1}' passou" -f $ad.Id, $ad.Descricao) 'Red'
            }
        }
    }
} catch {
    [void]$falhas.Add("erro: " + $_.Exception.Message)
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
foreach ($f in $falhas) { Escreve ("  REPROVADO  " + $f) 'Red' }
$cor = $(if ($falhas.Count -eq 0) { 'Green' } else { 'Red' })
Escreve ("  {0} de {1} asse rcoes passaram" -f $passou, $rodadas.Count) $cor
if ($falhas.Count -gt 0) { exit 1 }
exit 0
