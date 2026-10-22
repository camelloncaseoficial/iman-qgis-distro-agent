<#
=============================================================================
 #041 - GUARDA DO TRADUTOR SOBREPOSTO DA MARCA (D-IMAN-039 regra 3)

 POR QUE ELA EXISTE. O tradutor sobreposto falha em silencio de tres jeitos:
 um .qm com tabela errada devolve o texto do QGIS (RISCOS R7); um texto-fonte com
 um caractere trocado gera um .qm valido que o QGIS nunca consulta; e uma
 traducao que nomeia o produto onde o valor e a versao do QGIS afirma algo falso.
 Nenhum deles da erro na tela. Esta guarda os torna altos.

 O QUE ELA ASSERE (a fonte e app\i18n\iman_terra_pt_BR.json):
   T1 o gerador (installer\New-BrandTranslation.ps1) produz o .qm, com o
      lrelease fixado, e passa nas guardas dele;
   T2 todo texto-fonte EXISTE no qgis_pt_BR.qm da arvore, no mesmo contexto;
   T3 o nosso .qm devolve, sozinho, a traducao esperada de cada mensagem, com o
      nome do produto lido de brand.py;
   T4 com os dois tradutores na ordem do produto (o do QGIS, depois o nosso),
      QCoreApplication.translate devolve a nossa;
   T5 mensagens que a regra 3 manda NAO trocar (Doe, Membros de Suporte, Sobre,
      repositorio oficial, Contribuidores) saem com o texto do QGIS.

 GUARDA SO VALE VISTA FALHANDO. Sem -SemAdulteracao, ela tambem roda sobre duas
 fontes adulteradas e exige a reprovacao certa:
   V1 uma mensagem versao-motor que nomeia o produto -> o gerador recusa (T1)
   V2 um texto-fonte com um caractere trocado        -> T2 reprova

 Com -Qm, a guarda confere o .qm dado (o que o build vai empacotar) em vez de
 gerar um. Default de -Qgis: a arvore do produto instalado; recusa %ProgramFiles%.
 BL-3: nada e escrito fora de uma pasta temporaria.

 SAIDA: exit 0 ou 1; a ultima linha util e o placar "N de M asse rcoes passaram".

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    [string]$Qgis = '',
    [string]$Qm = '',
    [string]$Fonte = '',
    [switch]$SemAdulteracao
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$raizRepo   = (Get-Item (Join-Path $raizScript '..')).FullName
if (-not $Qgis)  { $Qgis  = Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra\qgis' }
if (-not $Fonte) { $Fonte = Join-Path $raizRepo 'app\i18n\iman_terra_pt_BR.json' }
$Qgis = [IO.Path]::GetFullPath($Qgis)
$sonda   = Join-Path $raizScript 'brand-guards\translation_probe.py'
$gerador = Join-Path $raizRepo 'installer\New-BrandTranslation.ps1'
$brandPy = Join-Path $raizRepo 'app\profile-template\iman-distro\python\plugins\iman_brand\brand.py'

function Escreve { param([string]$T, [string]$C = 'Gray') Write-Host $T -ForegroundColor $C }

Write-Host ''
Write-Host '  #041 - guarda do tradutor sobreposto' -ForegroundColor White
Write-Host "  fonte : $Fonte"
Write-Host "  qgis  : $Qgis"
Write-Host ''

foreach ($proibido in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
    if ($proibido -and $Qgis.ToLower().StartsWith($proibido.ToLower())) {
        Escreve "  ABORTADO: a raiz '$Qgis' cai em '$proibido'. A guarda mede a arvore do produto." 'Red'
        exit 2
    }
}
$py = Join-Path $Qgis 'bin\python-qgis-ltr.bat'
$qgisQm = Join-Path $Qgis 'apps\qgis-ltr\i18n\qgis_pt_BR.qm'
foreach ($p in @($py, $qgisQm, $sonda, $gerador, $brandPy, $Fonte)) {
    if (-not (Test-Path -LiteralPath $p)) { Escreve "  ABORTADO: nao existe $p" 'Red'; exit 2 }
}
$m = [regex]::Match((Get-Content -LiteralPath $brandPy -Raw -Encoding UTF8), '(?m)^\s*PRODUCT_NAME\s*=\s*"([^"]+)"')
if (-not $m.Success) { Escreve "  ABORTADO: PRODUCT_NAME nao encontrado em $brandPy" 'Red'; exit 2 }
$produto = $m.Groups[1].Value

$tmp = Join-Path ([IO.Path]::GetTempPath()) ('iman-brand-translation-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
$env:PYTHONDONTWRITEBYTECODE = '1'
$PsExe = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path -LiteralPath $PsExe)) { $PsExe = 'powershell.exe' }

# Gera um .qm a partir de uma fonte. Devolve @{ Ok; Qm; Saida }.
function Gera([string]$FonteJson, [string]$Rotulo) {
    $dir = Join-Path $tmp "qm-$Rotulo"
    $saida = (& $PsExe -NoProfile -ExecutionPolicy Bypass -File $gerador -Fonte $FonteJson -OutDir $dir 2>&1 | Out-String)
    $ok = ($LASTEXITCODE -eq 0) -and ($saida -match 'TRADUCAO=OK')
    $qmGerado = [regex]::Match($saida, '(?m)^QM=(.+?)\s*$')
    return @{ Ok = $ok; Qm = $(if ($qmGerado.Success) { $qmGerado.Groups[1].Value } else { '' }); Saida = $saida.Trim() }
}

function Mede([string]$QmPath, [string]$FonteJson, [string]$Rotulo) {
    $out = Join-Path $tmp "medida-$Rotulo.json"
    $log = (& $py $sonda $QmPath $qgisQm $FonteJson $produto $out 2>&1 | Out-String)
    if (-not (Test-Path -LiteralPath $out)) { throw "a sonda nao gravou medida para '$Rotulo'. Saida: $log" }
    return (Get-Content -LiteralPath $out -Raw -Encoding UTF8 | ConvertFrom-Json)
}

# Reprovacoes de uma medida, com a asse rcao (T2..T5).
function Avalia($Medida) {
    $r = New-Object System.Collections.ArrayList
    if (-not $Medida.qgis_qm_loaded) { [void]$r.Add([pscustomobject]@{ A = 'T2'; Texto = 'o qgis_pt_BR.qm da arvore nao carregou' }) }
    if (-not $Medida.ours_qm_loaded) { [void]$r.Add([pscustomobject]@{ A = 'T3'; Texto = 'o nosso .qm nao carregou' }) }
    foreach ($x in @($Medida.messages)) {
        $id = "[{0}] {1}" -f $x.context, $(if ($x.source.Length -gt 60) { $x.source.Substring(0, 60) + '...' } else { $x.source })
        if (-not $x.in_qgis) { [void]$r.Add([pscustomobject]@{ A = 'T2'; Texto = "$id : o QGIS nao tem esta mensagem neste contexto" }) }
        if ($x.ours -ne $x.expected) { [void]$r.Add([pscustomobject]@{ A = 'T3'; Texto = "$id : o .qm devolve '$($x.ours)'" }) }
        if ($x.effective -ne $x.expected) { [void]$r.Add([pscustomobject]@{ A = 'T4'; Texto = "$id : com os dois tradutores sai '$($x.effective)'" }) }
    }
    foreach ($c in @($Medida.controls)) {
        if ($c.ours) { [void]$r.Add([pscustomobject]@{ A = 'T5'; Texto = "[$($c.context)] $($c.source) : o tradutor da marca responde '$($c.ours)'" }) }
        if ($c.effective -ne $c.qgis) { [void]$r.Add([pscustomobject]@{ A = 'T5'; Texto = "[$($c.context)] $($c.source) : sai '$($c.effective)' em vez de '$($c.qgis)'" }) }
    }
    return , @($r)
}

$falhas  = New-Object System.Collections.ArrayList
$rodadas = New-Object System.Collections.ArrayList
$passou  = 0
function Registra([string]$Id, [bool]$Ok, [string]$Texto) {
    [void]$rodadas.Add($Id)
    if ($Ok) { $script:passou++ } else { [void]$falhas.Add("[$Id] $Texto") }
    Escreve ("  [{0}] {1}  {2}" -f $Id, $(if ($Ok) { 'PASS' } else { 'FAIL' }), $Texto) $(if ($Ok) { 'Green' } else { 'Red' })
}

try {
    # ------------------------------------------------------------ T1
    if ($Qm) {
        $okT1 = Test-Path -LiteralPath $Qm
        Registra 'T1' $okT1 ("conferindo o .qm dado: $Qm")
        $qmAlvo = $Qm
    } else {
        $g = Gera $Fonte 'fonte'
        Registra 'T1' $g.Ok $(if ($g.Ok) { "gerado: $($g.Qm)" } else { $g.Saida })
        $qmAlvo = $g.Qm
    }

    # ------------------------------------------------------------ T2..T5
    if ($qmAlvo -and (Test-Path -LiteralPath $qmAlvo)) {
        $medida = Mede $qmAlvo $Fonte 'fonte'
        Escreve ("  {0} mensagens, produto '{1}'" -f @($medida.messages).Count, $produto)
        foreach ($x in @($medida.messages)) {
            $e = $x.effective -replace '\s+', ' '
            Escreve ("    [{0}] {1}" -f $x.context, $(if ($e.Length -gt 90) { $e.Substring(0, 90) + '...' } else { $e }))
        }
        $rep = Avalia $medida
        foreach ($a in @('T2', 'T3', 'T4', 'T5')) {
            $desta = @($rep | Where-Object { $_.A -eq $a })
            Registra $a ($desta.Count -eq 0) $(if ($desta.Count -eq 0) { '' } else { ($desta | ForEach-Object { $_.Texto }) -join ' | ' })
        }
    } else {
        foreach ($a in @('T2', 'T3', 'T4', 'T5')) { Registra $a $false 'sem .qm para medir' }
    }

    # ------------------------------------------------------------ V1, V2
    if (-not $SemAdulteracao) {
        $doc = Get-Content -LiteralPath $Fonte -Raw -Encoding UTF8 | ConvertFrom-Json
        $utf8 = New-Object System.Text.UTF8Encoding($false)

        $v1 = Join-Path $tmp 'fonte-V1.json'
        $motor = @($doc.messages | Where-Object { $_.rule -eq 'versao-motor' })[0]
        $motor.iman_terra = 'Versao do ' + $doc.product_token + ': %1'
        [IO.File]::WriteAllText($v1, ($doc | ConvertTo-Json -Depth 6), $utf8)
        $g1 = Gera $v1 'V1'
        Registra 'V1' (-not $g1.Ok) 'adulteracao: versao-motor nomeando o produto; o gerador tem de RECUSAR'

        $doc = Get-Content -LiteralPath $Fonte -Raw -Encoding UTF8 | ConvertFrom-Json
        $v2 = Join-Path $tmp 'fonte-V2.json'
        $doc.messages[0].source = ([string]$doc.messages[0].source) + ' '
        [IO.File]::WriteAllText($v2, ($doc | ConvertTo-Json -Depth 6), $utf8)
        $g2 = Gera $v2 'V2'
        $okV2 = $false
        if ($g2.Ok) {
            $rep2 = Avalia (Mede $g2.Qm $v2 'V2')
            $okV2 = @($rep2 | Where-Object { $_.A -eq 'T2' }).Count -gt 0
        }
        Registra 'V2' $okV2 'adulteracao: texto-fonte com um espaco a mais; T2 tem de REPROVAR'
    }
} catch {
    [void]$falhas.Add("erro: " + $_.Exception.Message)
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
foreach ($f in $falhas) { Escreve ("  REPROVADO  " + $f) 'Red' }
Escreve ("  {0} de {1} asse rcoes passaram" -f $passou, $rodadas.Count) $(if ($falhas.Count -eq 0) { 'Green' } else { 'Red' })
if ($falhas.Count -gt 0) { exit 1 }
exit 0
