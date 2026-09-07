<#
=============================================================================
 SPIKE #016 - M8 / E.1 : inventario ANTES-DEPOIS da pegada externa

 Fotografa as tres areas que o QGIS RELOCADO nao pode tocar (BL-3):
   1) %APPDATA%\QGIS            - perfil pessoal do usuario
   2) C:\Program Files\QGIS*    - instalacao oficial de terceiro
   3) ARP / Uninstall           - nenhuma entrada nova de produto

 E.1 - VALIDACAO DE BASELINE: inventario vazio NAO prova nada. Este script
 exige TotalArquivos > 0 nas areas que devem existir nesta bancada e ABORTA
 com exit 2 mandando refazer se degenerar. O repo ja perdeu uma rodada
 exatamente assim (2026-07-30, BL-3a inconclusivo nos dois sentidos).

 USO
   powershell -ExecutionPolicy Bypass -File .\Snapshot-Footprint.ps1 -Rotulo antes
   powershell -ExecutionPolicy Bypass -File .\Snapshot-Footprint.ps1 -Rotulo depois
   powershell -ExecutionPolicy Bypass -File .\Snapshot-Footprint.ps1 -Comparar

 Manifesto por arquivo: caminho relativo + tamanho + LastWriteTimeUtc.
 SHA-256 so em %APPDATA%\QGIS (poucos arquivos). Em Program Files\QGIS* sao
 ~35 mil arquivos / 2,2 GB - la a assercao e (contagem, tamanho, mtime), que
 ja e sensivel a qualquer escrita. Limite declarado, nao escondido.

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    [string]$Rotulo = 'antes',
    [switch]$Comparar,
    [string]$OutDir = ''
)

$ErrorActionPreference = 'Stop'

# PS 5.1 nao popula $PSScriptRoot em default de param quando chamado com -File
# e caminho relativo; resolve aqui.
if ([string]::IsNullOrEmpty($OutDir)) {
    $raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $OutDir = Join-Path $raizScript 'evidencia'
}

if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

function Get-Manifesto {
    param([string]$Raiz, [switch]$ComHash)

    $existe = Test-Path -LiteralPath $Raiz
    $itens  = New-Object System.Collections.ArrayList
    $bytes  = [int64]0

    if ($existe) {
        $raizFull = (Get-Item -LiteralPath $Raiz).FullName.TrimEnd('\')
        $corte    = $raizFull.Length + 1
        foreach ($f in (Get-ChildItem -LiteralPath $raizFull -Recurse -File -Force -ErrorAction SilentlyContinue)) {
            # ATENCAO (defeito real, corrigido em 2026-09-06): um .db aberto por
            # outro processo faz o Get-FileHash falhar. Se essa falha virar um
            # VALOR ('ERRO'), a comparacao contra o hash real da captura seguinte
            # acusa "modificado" para um arquivo que nao mudou byte nenhum. Foi o
            # que aconteceu com qgis-auth.db, symbology-style.db e
            # user-history.db do perfil default. Agora a indisponibilidade e
            # marcada como tal ($null) e a comparacao NAO a trata como diferenca.
            $h = $null
            if ($ComHash) {
                try { $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash }
                catch { $h = $null }
            }
            [void]$itens.Add([pscustomobject]@{
                Rel   = $f.FullName.Substring($corte)
                Bytes = $f.Length
                Mtime = $f.LastWriteTimeUtc.ToString('o')
                Sha         = $h
                HashObtido  = ($null -ne $h)
            })
            $bytes += $f.Length
        }
    }

    [pscustomobject]@{
        Raiz          = $Raiz
        ComHash       = [bool]$ComHash
        Existe        = $existe
        TotalArquivos = $itens.Count
        TotalBytes    = $bytes
        Arquivos      = @($itens | Sort-Object Rel)
    }
}

function Get-ArpQgis {
    $chaves = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    $r = New-Object System.Collections.ArrayList
    foreach ($k in $chaves) {
        if (-not (Test-Path $k)) { continue }
        foreach ($sub in (Get-ChildItem $k -ErrorAction SilentlyContinue)) {
            $p = Get-ItemProperty $sub.PSPath -ErrorAction SilentlyContinue
            if ($p -and $p.DisplayName -and ($p.DisplayName -match 'QGIS|OSGeo|GRASS|IMAN')) {
                [void]$r.Add([pscustomobject]@{
                    Hive        = $k
                    Chave       = $sub.PSChildName
                    DisplayName = $p.DisplayName
                    Versao      = $p.DisplayVersion
                    Local       = $p.InstallLocation
                })
            }
        }
    }
    @($r | Sort-Object Chave)
}

function Get-RaizProgramFilesQgis {
    $d = Get-ChildItem 'C:\Program Files' -Directory -Filter 'QGIS *' -ErrorAction SilentlyContinue |
         Sort-Object Name | Select-Object -First 1
    if ($d) { return $d.FullName }
    return 'C:\Program Files\QGIS 3.44.13'
}

# ---------------------------------------------------------------- COMPARAR
if ($Comparar) {
    $fAntes  = Join-Path $OutDir 'footprint-antes.json'
    $fDepois = Join-Path $OutDir 'footprint-depois.json'
    foreach ($f in @($fAntes, $fDepois)) {
        if (-not (Test-Path -LiteralPath $f)) { throw "Falta $f - rode as duas capturas primeiro." }
    }
    $a = Get-Content -LiteralPath $fAntes  -Raw | ConvertFrom-Json
    $d = Get-Content -LiteralPath $fDepois -Raw | ConvertFrom-Json

    Write-Host ''
    Write-Host '  M8 - o QGIS relocado tocou algo fora da propria arvore?' -ForegroundColor White
    Write-Host ''

    # E.1 de novo na comparacao: baseline degenerado invalida a assercao.
    foreach ($nome in @('AppDataQgis','ProgramFilesQgis')) {
        if ([int]$a.$nome.TotalArquivos -le 0) {
            Write-Host "  E.1 FALHA: baseline 'antes' de $nome tem 0 arquivos. PARE E REFACA." -ForegroundColor Red
            exit 2
        }
    }

    $falhas = New-Object System.Collections.ArrayList
    foreach ($nome in @('AppDataQgis','ProgramFilesQgis')) {
        $ma = $a.$nome; $md = $d.$nome
        $chaveA = @{}; foreach ($x in $ma.Arquivos) { $chaveA[$x.Rel] = $x }
        $chaveD = @{}; foreach ($x in $md.Arquivos) { $chaveD[$x.Rel] = $x }

        $add = @($chaveD.Keys | Where-Object { -not $chaveA.ContainsKey($_) })
        $rem = @($chaveA.Keys | Where-Object { -not $chaveD.ContainsKey($_) })
        $mod = New-Object System.Collections.ArrayList
        $semHash = New-Object System.Collections.ArrayList
        foreach ($k in $chaveA.Keys) {
            if (-not $chaveD.ContainsKey($k)) { continue }
            $x = $chaveA[$k]; $y = $chaveD[$k]
            $difere = ($x.Bytes -ne $y.Bytes) -or ($x.Mtime -ne $y.Mtime)
            # Hash so entra na conta quando existe DOS DOIS LADOS. Sem isso um
            # arquivo apenas bloqueado numa das capturas apareceria como alterado.
            if (-not $difere -and $x.HashObtido -and $y.HashObtido -and $x.Sha -ne $y.Sha) {
                $difere = $true
            }
            # So conta como "hash indisponivel" onde o hash foi PEDIDO. Onde nao
            # foi (Program Files, 38 mil arquivos), a assercao e tamanho + mtime
            # por desenho - e isso esta declarado no cabecalho, nao escondido.
            if ($ma.ComHash -and (-not $x.HashObtido -or -not $y.HashObtido)) { [void]$semHash.Add($k) }
            if ($difere) { [void]$mod.Add($k) }
        }

        $ok  = ($add.Count -eq 0 -and $rem.Count -eq 0 -and $mod.Count -eq 0)
        $tag = 'FAIL'; $cor = 'Red'
        if ($ok) { $tag = 'PASS'; $cor = 'Green' }
        Write-Host ("  [{0}] {1}  baseline {2} arquivos  ->  +{3} adicionados / -{4} removidos / ~{5} modificados" -f `
            $tag, $nome, $ma.TotalArquivos, $add.Count, $rem.Count, $mod.Count) -ForegroundColor $cor
        foreach ($k in ($add | Sort-Object | Select-Object -First 25)) { Write-Host "        + $k" -ForegroundColor Yellow }
        foreach ($k in ($rem | Sort-Object | Select-Object -First 25)) { Write-Host "        - $k" -ForegroundColor Yellow }
        foreach ($k in ($mod | Sort-Object | Select-Object -First 25)) { Write-Host "        ~ $k" -ForegroundColor Yellow }
        if (-not $ma.ComHash) {
            Write-Host ("        nota: assercao por tamanho + data de modificacao (SHA-256 nao aplicado a {0} arquivos por custo)." -f $ma.TotalArquivos) -ForegroundColor DarkGray
        }
        if ($semHash.Count -gt 0) {
            Write-Host ("        nota: {0} arquivo(s) sem SHA-256 em alguma das capturas (bloqueados por outro processo);" -f $semHash.Count) -ForegroundColor DarkGray
            Write-Host  "              para esses a comparacao usou tamanho + data de modificacao." -ForegroundColor DarkGray
            foreach ($k in ($semHash | Sort-Object | Select-Object -First 10)) { Write-Host "              ? $k" -ForegroundColor DarkGray }
        }
        if (-not $ok) { [void]$falhas.Add($nome) }
    }

    $arpA = (@($a.Arp) | ForEach-Object { $_.Chave }) -join '|'
    $arpD = (@($d.Arp) | ForEach-Object { $_.Chave }) -join '|'
    $arpOk = ($arpA -eq $arpD)
    $tag = 'FAIL'; $cor = 'Red'
    if ($arpOk) { $tag = 'PASS'; $cor = 'Green' }
    Write-Host ("  [{0}] Arp  {1} entradas antes / {2} depois" -f $tag, @($a.Arp).Count, @($d.Arp).Count) -ForegroundColor $cor
    if (-not $arpOk) {
        [void]$falhas.Add('Arp')
        Write-Host "        antes : $arpA"
        Write-Host "        depois: $arpD"
    }

    Write-Host ''
    if ($falhas.Count -eq 0) {
        Write-Host '  M8 = PASS - nada fora da arvore relocada foi lido-para-escrita nem alterado.' -ForegroundColor Green
        exit 0
    }
    Write-Host ("  M8 = FAIL - areas tocadas: {0}" -f ($falhas -join ', ')) -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------- CAPTURA
Write-Host ''
Write-Host "  SPIKE 016 - inventario de pegada externa  [$Rotulo]" -ForegroundColor White

$appdataQgis = Join-Path $env:APPDATA 'QGIS'
$pfQgis      = Get-RaizProgramFilesQgis

Write-Host "  1) $appdataQgis"
$mApp = Get-Manifesto -Raiz $appdataQgis -ComHash
Write-Host ("     {0} arquivos / {1} MB" -f $mApp.TotalArquivos, [math]::Round($mApp.TotalBytes/1MB,2))

Write-Host "  2) $pfQgis"
$mPf = Get-Manifesto -Raiz $pfQgis
Write-Host ("     {0} arquivos / {1} GB" -f $mPf.TotalArquivos, [math]::Round($mPf.TotalBytes/1GB,3))

Write-Host "  3) ARP (QGIS|OSGeo|GRASS|IMAN)"
$arp = Get-ArpQgis
foreach ($e in $arp) { Write-Host ("     - {0} [{1}]" -f $e.DisplayName, $e.Versao) }

# ---- E.1 GUARDA NUMERICA DE BASELINE ------------------------------------
$degenerado = New-Object System.Collections.ArrayList
if ($mApp.TotalArquivos -le 0) { [void]$degenerado.Add("%APPDATA%\QGIS vazio ou ausente ($($mApp.TotalArquivos) arquivos)") }
if ($mPf.TotalArquivos  -le 0) { [void]$degenerado.Add("$pfQgis vazio ou ausente ($($mPf.TotalArquivos) arquivos)") }
if (@($arp).Count       -le 0) { [void]$degenerado.Add('ARP sem nenhuma entrada QGIS') }

if ($degenerado.Count -gt 0) {
    Write-Host ''
    Write-Host '  E.1 BASELINE DEGENERADO - PARE E REFACA:' -ForegroundColor Red
    foreach ($x in $degenerado) { Write-Host "     * $x" -ForegroundColor Red }
    Write-Host '  Inventario vazio nao prova nem inocenta: nenhuma assercao de M8 pode' -ForegroundColor Red
    Write-Host '  ser feita sobre este baseline.' -ForegroundColor Red
    exit 2
}

$snap = [pscustomobject]@{
    Rotulo           = $Rotulo
    QuandoUtc        = (Get-Date).ToUniversalTime().ToString('o')
    Maquina          = $env:COMPUTERNAME
    Usuario          = $env:USERNAME
    AppDataQgis      = $mApp
    ProgramFilesQgis = $mPf
    Arp              = $arp
}

$out = Join-Path $OutDir ("footprint-{0}.json" -f $Rotulo)
$snap | ConvertTo-Json -Depth 8 -Compress | Set-Content -LiteralPath $out -Encoding UTF8

Write-Host ''
Write-Host ("  E.1 BASELINE VALIDO - todas as areas > 0. Gravado: {0}" -f $out) -ForegroundColor Green
exit 0
