<#
=============================================================================
 SPIKE #016 - de onde vem CADA DLL que o QGIS relocado carregou

 Esta bancada NAO tem o estado A (maquina sem QGIS nenhum) e nao pode obte-lo:
 desinstalar o QGIS daqui e destrutivo e a decisao nao e da crew (S.5). O mais
 proximo HONESTO que da para medir e este: com o processo relocado vivo,
 enumerar os modulos carregados e provar que NENHUM veio de
 C:\Program Files\QGIS*.

 Isso nao SUBSTITUI o estado A - uma dependencia que so aparece quando o outro
 QGIS some (uma chave de registro, um caminho em PATH do sistema) nao seria
 vista aqui. Mas fecha a pergunta "ele esta se apoiando nas DLLs do vizinho?",
 que e a forma mais provavel do estado A falhar.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Assert-ProcedenciaModulos.ps1 -ProcId 1234

 ASCII-only de proposito.
=============================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][int]$ProcId,
    [string]$RaizRelocada = (Join-Path $env:LOCALAPPDATA 'InstitutoIMAN\_spike016\IMAN Terra\qgis'),
    [string]$OutDir = ''
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrEmpty($OutDir)) {
    $OutDir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) 'evidencia'
}
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$p = Get-Process -Id $ProcId -ErrorAction Stop
$p.Refresh()

$mods = @($p.Modules | ForEach-Object { $_.FileName })
if ($mods.Count -eq 0) { throw "Nenhum modulo enumerado para o PID $ProcId." }

# Raiz canonica da copia privada, em forma longa E curta (8.3): o o4w_env.bat
# converte OSGEO4W_ROOT para caminho curto, entao os modulos aparecem assim.
$raizLonga = (Get-Item -LiteralPath $RaizRelocada).FullName.TrimEnd('\')
$fso = New-Object -ComObject Scripting.FileSystemObject
$raizCurta = $fso.GetFolder($raizLonga).ShortPath.TrimEnd('\')

$outrosQgis = @(Get-ChildItem 'C:\Program Files' -Directory -Filter 'QGIS *' -ErrorAction SilentlyContinue |
                ForEach-Object { $_.FullName })

function Ehda { param([string]$f, [string[]]$raizes)
    foreach ($r in $raizes) { if ($f.ToLower().StartsWith($r.ToLower())) { return $true } }
    return $false
}

$doRelocado = @($mods | Where-Object { Ehda $_ @($raizLonga, $raizCurta) })
$doOutroQgis = @($mods | Where-Object { Ehda $_ $outrosQgis })
$doWindows  = @($mods | Where-Object {
    (Ehda $_ @("$env:SystemRoot")) -and -not (Ehda $_ $outrosQgis)
})
$restantes = @($mods | Where-Object {
    -not (Ehda $_ @($raizLonga, $raizCurta)) -and
    -not (Ehda $_ $outrosQgis) -and
    -not (Ehda $_ @("$env:SystemRoot"))
})

Write-Host ''
Write-Host "  PROCEDENCIA DOS MODULOS - PID $ProcId ($($p.ProcessName))" -ForegroundColor White
Write-Host "  arvore relocada : $raizLonga"
Write-Host "                    $raizCurta  (forma 8.3)"
Write-Host "  outros QGIS     : $($outrosQgis -join ', ')"
Write-Host ''
Write-Host ("  total de modulos carregados      : {0}" -f $mods.Count)
Write-Host ("  da ARVORE RELOCADA               : {0}" -f $doRelocado.Count) -ForegroundColor Green
Write-Host ("  do Windows (system32, drivers)   : {0}" -f $doWindows.Count)
Write-Host ("  de OUTRO QGIS (Program Files)    : {0}" -f $doOutroQgis.Count) -ForegroundColor $(if ($doOutroQgis.Count -eq 0) { 'Green' } else { 'Red' })
Write-Host ("  de outro lugar qualquer          : {0}" -f $restantes.Count) -ForegroundColor $(if ($restantes.Count -eq 0) { 'Gray' } else { 'Yellow' })

foreach ($m in $doOutroQgis) { Write-Host "     ! $m" -ForegroundColor Red }
foreach ($m in ($restantes | Select-Object -First 25)) { Write-Host "     ? $m" -ForegroundColor Yellow }

$doc = [pscustomobject]@{
    QuandoUtc         = (Get-Date).ToUniversalTime().ToString('o')
    Pid               = $ProcId
    Processo          = $p.ProcessName
    RaizRelocadaLonga = $raizLonga
    RaizRelocadaCurta = $raizCurta
    OutrosQgis        = $outrosQgis
    TotalModulos      = $mods.Count
    DoRelocado        = $doRelocado.Count
    DoWindows         = $doWindows.Count
    DeOutroQgis       = $doOutroQgis.Count
    DeOutroLugar      = $restantes.Count
    ListaDeOutroQgis  = $doOutroQgis
    ListaDeOutroLugar = $restantes
    Modulos           = $mods
}
$out = Join-Path $OutDir 'procedencia-modulos.json'
$doc | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $out -Encoding UTF8

Write-Host ''
if ($doOutroQgis.Count -eq 0) {
    Write-Host '  PASS - nenhum modulo veio de outra instalacao do QGIS.' -ForegroundColor Green
    Write-Host "  gravado: $out"
    exit 0
}
Write-Host '  FAIL - o processo relocado carregou binario de OUTRO QGIS.' -ForegroundColor Red
Write-Host "  gravado: $out"
exit 1
