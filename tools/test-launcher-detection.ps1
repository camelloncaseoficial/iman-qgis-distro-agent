<#
=============================================================================
 DB-14 - teste de deteccao do QGIS pelo launcher

 O QUE ESTE TESTE PROVA
 ----------------------
 Que o launcher abre o QGIS que o instalador EMBARCOU, e nao outro que por
 acaso esteja na maquina.

 POR QUE ELE PRECISA DE MAIS DE UM QGIS
 --------------------------------------
 Com UM QGIS so, o teste passa identico ANTES e DEPOIS da correcao - ele nao
 e sensivel ao defeito e nao e evidencia de nada. O defeito do DB-14 so
 aparece quando ha ambiguidade: a rotina antiga aceitava o PRIMEIRO que o
 `for /d` enumerasse, e essa ordem e alfabetica POR TEXTO:

    "QGIS 3.34.15" < "QGIS 3.44.9"     -> escolhia a serie ERRADA
    "QGIS 3.44.12" < "QGIS 3.44.9"     -> porque '1' < '9'

 Por isso todo caso abaixo monta pelo menos DOIS QGIS e asseria QUAL foi
 escolhido - nunca apenas "achou alguma coisa".

 COMO ELE EXERCITA O CODIGO DE VERDADE
 -------------------------------------
 Chama o PROPRIO app\launcher\IMAN-Terra.bat com IMAN_TERRA_DETECT_ONLY=1 e
 com %ProgramFiles% apontado para uma raiz sintetica. Nada e instalado, nenhum
 QGIS e aberto e o perfil do usuario nao e tocado.

 USO
   .\tools\test-launcher-detection.ps1

 SAIDA: 0 = todos os casos passaram; 1 = algum caso falhou.

 REQUISITOS: PowerShell 5.1. Sem admin, sem rede, sem QGIS instalado.
 ASCII-only de proposito.
=============================================================================
#>
[CmdletBinding()]
param(
    # Versao que o launcher deve preferir. Espelha QGIS_VERSION no .bat e
    # QgisBaselineVersion no .iss.
    [string]$VersaoPayload = '3.44.9',

    # Launcher a testar. So mude para conferir a SENSIBILIDADE do teste:
    # apontando para a rotina ANTIGA, os casos M2b/M3/M3+ tem de FALHAR.
    # Um teste que passa nos dois nao e evidencia de correcao nenhuma.
    [string]$Launcher
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
if (-not $Launcher) { $Launcher = Join-Path $RepoRoot 'app\launcher\IMAN-Terra.bat' }

if (-not (Test-Path -LiteralPath $Launcher)) {
    Write-Host "  launcher nao encontrado: $Launcher" -ForegroundColor Red
    exit 1
}

$Sandbox = Join-Path $env:TEMP ('iman-db14-' + [Guid]::NewGuid().ToString('N').Substring(0,8))

function New-QgisFalso {
    param([string]$Raiz, [string[]]$Versoes, [string]$Exe = 'qgis-ltr-bin.exe')
    foreach ($v in $Versoes) {
        $bin = Join-Path $Raiz ("QGIS $v\bin")
        New-Item -ItemType Directory -Path $bin -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $bin $Exe) -Value 'stub' -Encoding Ascii
    }
}

# Roda o launcher REAL com raizes sinteticas e devolve o caminho escolhido.
function Get-EscolhaDoLauncher {
    param([string]$RaizPF, [string]$RaizPF86)

    $bat = @(
        '@echo off',
        "set `"ProgramFiles=$RaizPF`"",
        "set `"ProgramFiles(x86)=$RaizPF86`"",
        'set "IMAN_TERRA_DETECT_ONLY=1"',
        'set "QGIS_BIN="',
        "call `"$Launcher`""
    ) -join "`r`n"

    $runner = Join-Path $Sandbox 'runner.bat'
    Set-Content -LiteralPath $runner -Value $bat -Encoding Ascii

    $saida = & cmd.exe /c "`"$runner`"" 2>&1
    $linha = $saida | Where-Object { $_ -match '^QGIS_EXE=' } | Select-Object -First 1
    if (-not $linha) { return '<<sem saida>>  [' + ($saida -join ' | ') + ']' }
    return ($linha -replace '^QGIS_EXE=', '').Trim()
}

$casos = @(
    @{
        Nome     = 'M2b - payload 3.44.9 convivendo com 3.44.12 (o caso comum no campo)'
        Versoes  = @('3.44.9', '3.44.12')
        Esperado = "QGIS $VersaoPayload"
        Porque   = "'QGIS 3.44.12' ordena ANTES de 'QGIS 3.44.9' ('1' < '9'): a rotina antiga pegava a 3.44.12"
    },
    @{
        Nome     = 'M3 - payload convivendo com minor mais antiga (3.34.15)'
        Versoes  = @('3.34.15', '3.44.9')
        Esperado = "QGIS $VersaoPayload"
        Porque   = "'QGIS 3.34.15' ordena primeiro: a rotina antiga abria a serie ERRADA"
    },
    @{
        Nome     = 'M3+ - payload no meio de tres versoes alheias'
        Versoes  = @('3.34.15', '3.40.3', '3.44.9', '3.44.12')
        Esperado = "QGIS $VersaoPayload"
        Porque   = 'com quatro instalacoes o acerto por acaso fica improvavel'
    },
    @{
        Nome     = 'Fallback de mesma minor - payload AUSENTE, existe 3.44.12'
        Versoes  = @('3.34.15', '3.44.12')
        Esperado = 'QGIS 3.44.12'
        Porque   = 'sem o payload, mesma minor (3.44.x) deve vencer uma serie diferente'
    },
    @{
        Nome     = 'Ultimo recurso - nenhuma 3.44.x presente'
        Versoes  = @('3.34.15', '3.40.3')
        Esperado = 'QGIS 3.'
        Porque   = 'sem nada da nossa serie, abrir algo e melhor que nao abrir nada'
    }
)

Write-Host ""
Write-Host "  DB-14 - deteccao do QGIS pelo launcher" -ForegroundColor White
Write-Host "  launcher : $Launcher"
Write-Host "  payload  : QGIS $VersaoPayload"
Write-Host ""

$falhas = 0
$n = 0

try {
    foreach ($caso in $casos) {
        $n++
        $raiz   = Join-Path $Sandbox ("caso$n\pf")
        $raiz86 = Join-Path $Sandbox ("caso$n\pf86")
        New-Item -ItemType Directory -Path $raiz, $raiz86 -Force | Out-Null
        New-QgisFalso -Raiz $raiz -Versoes $caso.Versoes

        $escolhido = Get-EscolhaDoLauncher -RaizPF $raiz -RaizPF86 $raiz86
        $nomePasta = if ($escolhido -match '\\(QGIS [^\\]+)\\bin\\') { $Matches[1] } else { $escolhido }

        $ok = $nomePasta.StartsWith($caso.Esperado)

        Write-Host ("  [{0}] {1}" -f $(if ($ok) { 'PASS' } else { 'FAIL' }), $caso.Nome) -ForegroundColor $(if ($ok) { 'Green' } else { 'Red' })
        Write-Host ("         montado  : " + (($caso.Versoes | ForEach-Object { "QGIS $_" }) -join ' + '))
        Write-Host ("         esperado : " + $caso.Esperado + '*')
        Write-Host ("         escolhido: " + $nomePasta) -ForegroundColor $(if ($ok) { 'Gray' } else { 'Yellow' })
        if (-not $ok) {
            Write-Host ("         por que importa: " + $caso.Porque) -ForegroundColor Yellow
            $falhas++
        }
        Write-Host ""
    }
}
finally {
    if (Test-Path -LiteralPath $Sandbox) {
        Remove-Item -LiteralPath $Sandbox -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ("  {0} de {1} casos passaram." -f ($n - $falhas), $n) -ForegroundColor $(if ($falhas -eq 0) { 'Green' } else { 'Red' })
Write-Host ""

if ($falhas -gt 0) { exit 1 }
exit 0
