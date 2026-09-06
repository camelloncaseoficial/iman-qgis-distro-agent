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

 (Esses dois exemplos sao as medicoes originais, da epoca em que o payload era
 o 3.44.9.) Nenhuma versao rival esta mais escrita a mao nos casos: o rival de
 mesma minor e derivado do payload e CONFERIDO - ver $RivalMesmaMinor. Trocar a
 baseline sem isso deixaria o teste passando com 5 de 5 e insensivel ao defeito,
 que e o pior resultado possivel para uma guarda de build.

 Por isso todo caso abaixo monta pelo menos DOIS QGIS e asseria QUAL foi
 escolhido - nunca apenas "achou alguma coisa".

 COMO ELE EXERCITA O CODIGO DE VERDADE
 -------------------------------------
 Chama o PROPRIO app\launcher\IMAN-Terra.bat com IMAN_TERRA_DETECT_ONLY=1 e
 com as TRES raizes apontadas para diretorios sinteticos. Nada e instalado,
 nenhum QGIS e aberto e o perfil do usuario nao e tocado.

 POR QUE AS TRES, E NAO SO DUAS (D-IMAN-028/DB-20)
 -------------------------------------------------
 Ate a fatia #015 o wrapper sobrescrevia so %ProgramFiles% e
 %ProgramFiles(x86)%. Isso tornava o teste CEGO ao DB-20 por construcao: ele
 media a ORDEM das sondagens - que estava certa - e nunca a ORIGEM das raizes,
 que era o defeito. O launcher sondava exclusivamente %ProgramFiles%, e num
 processo de 32 bits o WOW64 aponta essa variavel para "Program Files (x86)",
 onde o QGIS de 64 bits nao esta.

 A ARMADILHA QUE O CONSERTO CRIOU, E POR ISSO ESTA FECHADA AQUI: o launcher
 passou a PREFERIR %ProgramW6432%. Se o wrapper nao definisse essa variavel,
 ela chegaria com o VALOR REAL DA MAQUINA ("C:\Program Files") e os casos
 sinteticos passariam a achar o QGIS DE VERDADE desta bancada - que por acaso
 e o proprio payload. Todos passariam PELO MOTIVO ERRADO e o arquivo inteiro
 deixaria de medir qualquer coisa, inclusive o DB-14 que ele existe para
 guardar. Por isso Set-Raizes define AS TRES em TODOS os casos: o launcher fica
 isolado da maquina real por completo.

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
    [string]$VersaoPayload = '3.44.13',

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
#
# AS TRES RAIZES SAO SEMPRE DEFINIDAS - ver "POR QUE AS TRES" no cabecalho.
# Nenhuma delas pode vazar da maquina real para dentro do caso.
#
# O `< NUL` no `call` NAO e enfeite: quando o launcher nao acha QGIS nenhum ele
# imprime a tela de diagnostico e chama `pause`. Sem a entrada redirecionada,
# um caso que FALHA pendura o teste em vez de reportar a falha - e e justamente
# no caso que falha que a saida importa.
function Get-EscolhaDoLauncher {
    param([string]$RaizPF, [string]$RaizPF86, [string]$RaizW6432)

    $bat = @(
        '@echo off',
        "set `"ProgramFiles=$RaizPF`"",
        "set `"ProgramFiles(x86)=$RaizPF86`"",
        "set `"ProgramW6432=$RaizW6432`"",
        'set "IMAN_TERRA_DETECT_ONLY=1"',
        'set "QGIS_BIN="',
        "call `"$Launcher`" < NUL"
    ) -join "`r`n"

    $runner = Join-Path $Sandbox 'runner.bat'
    Set-Content -LiteralPath $runner -Value $bat -Encoding Ascii

    $saida = & cmd.exe /c "`"$runner`"" 2>&1
    $linha = $saida | Where-Object { $_ -match '^QGIS_EXE=' } | Select-Object -First 1
    if (-not $linha) { return '<<sem saida>>  [' + ($saida -join ' | ') + ']' }
    return ($linha -replace '^QGIS_EXE=', '').Trim()
}

# Rival de MESMA MINOR usado nos casos M2b e M3+.
#
# Ele so serve se ordenar ANTES do payload POR TEXTO - que e a ordem em que o
# `for /d` do cmd enumera os diretorios. Se ordenar DEPOIS, a rotina antiga
# tambem acertaria, o caso passaria por acaso e o teste deixaria de ser
# evidencia de coisa alguma. Por isso a escolha e CONFERIDA aqui, nao presumida:
# uma baseline futura que quebre a premissa para o teste em vez de silenciar.
$RivalMesmaMinor = '3.44.12'
if ($RivalMesmaMinor -eq $VersaoPayload) { $RivalMesmaMinor = '3.44.1' }

if ([string]::CompareOrdinal("QGIS $RivalMesmaMinor", "QGIS $VersaoPayload") -ge 0) {
    Write-Host ""
    Write-Host "  TESTE INVALIDO para o payload $VersaoPayload" -ForegroundColor Red
    Write-Host ""
    Write-Host "    Rival de mesma minor: QGIS $RivalMesmaMinor" -ForegroundColor Yellow
    Write-Host "    Ele NAO ordena antes de 'QGIS $VersaoPayload' por texto, entao os" -ForegroundColor Yellow
    Write-Host "    casos M2b/M3+ passariam mesmo com a rotina ANTIGA - e o teste" -ForegroundColor Yellow
    Write-Host "    deixaria de detectar o defeito do DB-14." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Escolha um rival 3.44.x que ordene ANTES do payload e ajuste" -ForegroundColor Yellow
    Write-Host "    `$RivalMesmaMinor neste arquivo." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

$casos = @(
    @{
        Nome     = "M2b - payload $VersaoPayload convivendo com $RivalMesmaMinor (o caso comum no campo)"
        Versoes  = @($VersaoPayload, $RivalMesmaMinor)
        Esperado = "QGIS $VersaoPayload"
        Porque   = "'QGIS $RivalMesmaMinor' ordena ANTES de 'QGIS $VersaoPayload' por TEXTO: a rotina antiga pegava a $RivalMesmaMinor"
    },
    @{
        Nome     = 'M3 - payload convivendo com minor mais antiga (3.34.15)'
        Versoes  = @('3.34.15', $VersaoPayload)
        Esperado = "QGIS $VersaoPayload"
        Porque   = "'QGIS 3.34.15' ordena primeiro: a rotina antiga abria a serie ERRADA"
    },
    @{
        Nome     = 'M3+ - payload no meio de tres versoes alheias'
        Versoes  = @('3.34.15', '3.40.3', $VersaoPayload, $RivalMesmaMinor)
        Esperado = "QGIS $VersaoPayload"
        Porque   = 'com quatro instalacoes o acerto por acaso fica improvavel'
    },
    @{
        Nome     = "Fallback de mesma minor - payload AUSENTE, existe $RivalMesmaMinor"
        Versoes  = @('3.34.15', $RivalMesmaMinor)
        Esperado = "QGIS $RivalMesmaMinor"
        Porque   = 'sem o payload, mesma minor (3.44.x) deve vencer uma serie diferente'
    },
    @{
        Nome     = 'Ultimo recurso - nenhuma 3.44.x presente'
        Versoes  = @('3.34.15', '3.40.3')
        Esperado = 'QGIS 3.'
        Porque   = 'sem nada da nossa serie, abrir algo e melhor que nao abrir nada'
    },
    @{
        # D-IMAN-028/DB-20. Este caso e o unico SENSIVEL a ORIGEM das raizes:
        # ele poe ProgramFiles == ProgramFiles(x86) (a assinatura exata da visao
        # WOW64, medida na bancada) e deixa o QGIS SO na raiz de 64 bits. Um
        # launcher que sonde %ProgramFiles% nao acha nada e cai na tela de erro.
        # Com a Entrega 1 REVERTIDA este caso TEM de falhar - se passar nos dois
        # estados, nao e evidencia de nada e precisa ser refeito.
        Nome     = 'WOW64 - processo de 32 bits: o QGIS so existe na raiz de 64 bits'
        Versoes  = @($VersaoPayload, $RivalMesmaMinor)
        Esperado = "QGIS $VersaoPayload"
        Porque   = 'sondar %ProgramFiles% num processo de 32 bits cai em "Program Files (x86)", onde o QGIS nao esta (DB-20)'
        Wow64    = $true
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

        # Caso comum: processo de 64 bits, onde ProgramW6432 == ProgramFiles.
        # Caso Wow64: ProgramFiles e ProgramFiles(x86) apontam para a MESMA raiz
        # x86 (que nao tem QGIS nenhum) e so ProgramW6432 leva ao QGIS montado.
        if ($caso.Wow64) {
            $visao = 'PF=PF(x86)=<raiz x86 vazia>  PW6432=<raiz 64 com o QGIS>'
            $escolhido = Get-EscolhaDoLauncher -RaizPF $raiz86 -RaizPF86 $raiz86 -RaizW6432 $raiz
        }
        else {
            $visao = 'PF=PW6432=<raiz com o QGIS>  PF(x86)=<vazia>'
            $escolhido = Get-EscolhaDoLauncher -RaizPF $raiz -RaizPF86 $raiz86 -RaizW6432 $raiz
        }
        $nomePasta = if ($escolhido -match '\\(QGIS [^\\]+)\\bin\\') { $Matches[1] } else { $escolhido }

        $ok = $nomePasta.StartsWith($caso.Esperado)

        Write-Host ("  [{0}] {1}" -f $(if ($ok) { 'PASS' } else { 'FAIL' }), $caso.Nome) -ForegroundColor $(if ($ok) { 'Green' } else { 'Red' })
        Write-Host ("         montado  : " + (($caso.Versoes | ForEach-Object { "QGIS $_" }) -join ' + '))
        Write-Host ("         visao    : " + $visao)
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
