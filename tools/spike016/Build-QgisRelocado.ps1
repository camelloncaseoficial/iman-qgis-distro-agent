<#
=============================================================================
 SPIKE #016 - monta a arvore do QGIS RELOCADO a partir do MSI, SEM INSTALAR

 Via A1 (D-IMAN-028, emenda 2026-09-06): copia privada do QGIS dentro do
 IMAN Terra, fora de C:\Program Files, sem entrada na ARP, sem ProductCode.

 O QUE ESTE SCRIPT FAZ
   1. confere o payload (existencia + SHA-256 declarado);
   2. roda  msiexec /a  (instalacao administrativa) -> extrai a arvore para
      um diretorio arbitrario, SEM registrar produto nenhum no Windows;
   3. mede o que saiu (exit code, tempo, arquivos, bytes, shape da arvore);
   4. opcionalmente roda o  etc\postinstall.bat  DENTRO da arvore relocada -
      a acao customizada que o /a NAO executa - com 0/0 para nao criar
      atalho nenhum no menu iniciar nem na area de trabalho.

 O QUE ELE NAO FAZ
   nao instala, nao eleva, nao toca C:\Program Files\QGIS*, nao toca
   %APPDATA%\QGIS, nao escreve no registro.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-QgisRelocado.ps1
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-QgisRelocado.ps1 -PularPostInstall
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-QgisRelocado.ps1 -Destino "D:\outro\lugar"

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    # MSI de payload. Ja estagiado no repo; NAO baixar de novo (DB-5).
    [string]$Msi = '',

    # Raiz da copia privada. Default = o alvo real da via A1.
    [string]$Destino = (Join-Path $env:LOCALAPPDATA 'InstitutoIMAN\_spike016\IMAN Terra\qgis'),

    # Onde gravar logs de evidencia.
    [string]$OutDir = '',

    # Nao roda etc\postinstall.bat (para medir a arvore CRUA do /a).
    [switch]$PularPostInstall,

    # Apaga o destino antes de extrair.
    [switch]$Limpar
)

$ErrorActionPreference = 'Stop'

$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$raizRepo   = (Get-Item (Join-Path $raizScript '..\..')).FullName
if ([string]::IsNullOrEmpty($OutDir)) { $OutDir = Join-Path $raizScript 'evidencia' }
if ([string]::IsNullOrEmpty($Msi))    { $Msi    = Join-Path $raizRepo 'installer\payload\QGIS-OSGeo4W-3.44.13-1.msi' }

if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

# SHA-256 do payload canonico, conforme briefing #016 (prefixo/sufixo declarados).
$ShaEsperadoPrefixo = '42E2F1A6'
$ShaEsperadoSufixo  = '44EB4'

function Escreve { param([string]$T, [string]$C = 'Gray') Write-Host $T -ForegroundColor $C }

Escreve ''
Escreve '  SPIKE 016 - montando a arvore do QGIS RELOCADO (via A1)' 'White'
Escreve ''

# ---------------------------------------------------------------- 1. payload
if (-not (Test-Path -LiteralPath $Msi)) { throw "Payload nao encontrado: $Msi" }
$fiMsi = Get-Item -LiteralPath $Msi
Escreve ("  payload : {0}" -f $fiMsi.FullName)
Escreve ("  tamanho : {0} bytes ({1} MB)" -f $fiMsi.Length, [math]::Round($fiMsi.Length/1MB,2))
$sha = (Get-FileHash -LiteralPath $Msi -Algorithm SHA256).Hash
Escreve ("  sha-256 : {0}" -f $sha)
if (-not ($sha.StartsWith($ShaEsperadoPrefixo) -and $sha.EndsWith($ShaEsperadoSufixo))) {
    throw "SHA-256 do payload nao bate com o declarado no briefing ($ShaEsperadoPrefixo...$ShaEsperadoSufixo). Abortado."
}
Escreve '  sha-256 confere com o briefing.' 'Green'

# ---------------------------------------------------------------- 2. destino
if ($Limpar -and (Test-Path -LiteralPath $Destino)) {
    Escreve "  limpando destino anterior..." 'Yellow'
    Remove-Item -LiteralPath $Destino -Recurse -Force
}
if (-not (Test-Path -LiteralPath $Destino)) { New-Item -ItemType Directory -Path $Destino -Force | Out-Null }
$Destino = (Get-Item -LiteralPath $Destino).FullName.TrimEnd('\')
Escreve ("  destino : {0}" -f $Destino)

# GUARDA BL-3 / STOP-AND-FLAG: nunca extrair por cima de Program Files nem do
# perfil do usuario. Se o destino cair la, e defeito nosso - aborta alto.
foreach ($proibido in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, (Join-Path $env:APPDATA 'QGIS'))) {
    if ($proibido -and $Destino.ToLower().StartsWith($proibido.ToLower())) {
        throw "Destino '$Destino' cai dentro de area protegida '$proibido'. Abortado (BL-3)."
    }
}

# ---------------------------------------------------------------- 3. msiexec /a
$logMsi = Join-Path $OutDir 'msiexec-admin-install.log'
Escreve ''
Escreve '  msiexec /a  (instalacao administrativa: extrai, NAO instala)' 'White'
$cmd = 'msiexec.exe /a "{0}" /qn TARGETDIR="{1}" /L*v "{2}"' -f $fiMsi.FullName, $Destino, $logMsi
Escreve ("  > {0}" -f $cmd)

$t0 = Get-Date
$p = Start-Process -FilePath 'msiexec.exe' `
        -ArgumentList @('/a', "`"$($fiMsi.FullName)`"", '/qn', "TARGETDIR=`"$Destino`"", '/L*v', "`"$logMsi`"") `
        -Wait -PassThru -NoNewWindow
$dt = (Get-Date) - $t0
$exit = $p.ExitCode

Escreve ("  exit code : {0}" -f $exit) $(if ($exit -eq 0) { 'Green' } else { 'Red' })
Escreve ("  tempo     : {0:N1} s" -f $dt.TotalSeconds)
if ($exit -ne 0) { throw "msiexec /a falhou com exit $exit. Ver $logMsi" }

# ---------------------------------------------------------------- 4. shape
$exeAlvo = Get-ChildItem -LiteralPath $Destino -Recurse -Filter 'qgis-ltr-bin.exe' -File -ErrorAction SilentlyContinue |
           Select-Object -First 1
if (-not $exeAlvo) { throw "A arvore extraida NAO contem qgis-ltr-bin.exe. O /a nao produziu arvore executavel." }
$raizO4W = Split-Path -Parent (Split-Path -Parent $exeAlvo.FullName)   # ...\bin\x.exe -> raiz

$arquivos = @(Get-ChildItem -LiteralPath $Destino -Recurse -File -Force -ErrorAction SilentlyContinue)
$bytes = 0; foreach ($f in $arquivos) { $bytes += $f.Length }

Escreve ''
Escreve ("  arvore    : {0} arquivos / {1} GB" -f $arquivos.Count, [math]::Round($bytes/1GB,3)) 'Green'
Escreve ("  OSGEO4W_ROOT relocado : {0}" -f $raizO4W) 'Green'
Escreve ("  qgis-ltr-bin.exe      : {0}" -f $exeAlvo.FullName)

# O MSI deixa uma copia de si mesmo na raiz do admin install. Nao serve para
# rodar e custa 555 MB - relatar (a decisao de apagar e da fatia, nao do spike).
$msiResidual = Get-ChildItem -LiteralPath $Destino -Filter '*.msi' -File -ErrorAction SilentlyContinue
foreach ($m in $msiResidual) {
    Escreve ("  residual  : {0} ({1} MB) - copia do MSI deixada pelo /a" -f $m.Name, [math]::Round($m.Length/1MB,2)) 'Yellow'
}

# ---------------------------------------------------------------- 5. postinstall
$logPost = Join-Path $OutDir 'postinstall.log'
$postBat = Join-Path $raizO4W 'etc\postinstall.bat'
if ($PularPostInstall) {
    Escreve ''
    Escreve '  postinstall PULADO por -PularPostInstall (arvore CRUA do /a).' 'Yellow'
} elseif (-not (Test-Path -LiteralPath $postBat)) {
    Escreve ''
    Escreve "  postinstall AUSENTE em $postBat" 'Yellow'
} else {
    Escreve ''
    Escreve '  etc\postinstall.bat  (acao customizada que o /a NAO roda)' 'White'
    # args: %1 startmenu  %2 desktop  %3 desktop_links=0  %4 menu_links=0
    # 0/0 = nao cria atalho nenhum fora da arvore.
    $scratch = Join-Path $Destino '_spike-atalhos'
    if (-not (Test-Path -LiteralPath $scratch)) { New-Item -ItemType Directory -Path $scratch -Force | Out-Null }
    $t1 = Get-Date
    $saida = & cmd.exe /c "`"$postBat`" `"$scratch`" `"$scratch`" 0 0" 2>&1
    $exitPost = $LASTEXITCODE
    $dt1 = (Get-Date) - $t1
    $saida | Out-File -LiteralPath $logPost -Encoding ascii
    Escreve ("  exit code : {0}" -f $exitPost) $(if ($exitPost -eq 0) { 'Green' } else { 'Red' })
    Escreve ("  tempo     : {0:N1} s" -f $dt1.TotalSeconds)
    Escreve ("  log       : {0}" -f $logPost)
    $atalhos = @(Get-ChildItem -LiteralPath $scratch -Recurse -File -ErrorAction SilentlyContinue)
    Escreve ("  atalhos criados na pasta scratch: {0}" -f $atalhos.Count)
}

# ---------------------------------------------------------------- 6. resumo
$resumo = [pscustomobject]@{
    QuandoUtc        = (Get-Date).ToUniversalTime().ToString('o')
    Msi              = $fiMsi.FullName
    MsiBytes         = $fiMsi.Length
    MsiSha256        = $sha
    Destino          = $Destino
    Osgeo4wRoot      = $raizO4W
    ExitMsiexec      = $exit
    SegundosExtracao = [math]::Round($dt.TotalSeconds,1)
    TotalArquivos    = $arquivos.Count
    TotalBytes       = $bytes
    PostInstall      = (-not $PularPostInstall)
}
$outJson = Join-Path $OutDir 'build-relocado.json'
$resumo | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $outJson -Encoding UTF8

Escreve ''
Escreve ("  resumo gravado em {0}" -f $outJson) 'Green'
Escreve ''
exit 0
