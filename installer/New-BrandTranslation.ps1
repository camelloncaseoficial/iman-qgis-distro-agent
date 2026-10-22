<#
=============================================================================
 IMAN Terra - GERA O TRADUTOR SOBREPOSTO DA MARCA (.qm)   (#041, D-IMAN-039)

 Le a fonte versionada app\i18n\iman_terra_pt_BR.json, troca o token do nome
 pelo PRODUCT_NAME de brand.py (fonte unica, BL-4), escreve um .ts e o compila
 com lrelease. O .qm sai em -OutDir; o instalador o entrega em {app}\i18n\, e o
 plugin de marca (iman_brand\translation.py) o instala no arranque.

 A FERRAMENTA, declarada (o lrelease nao vem na arvore do QGIS):
   lrelease 5.15.2, de dentro do wheel qt5-applications 5.15.2.2.3 (PyPI),
   SHA-256 do wheel fixado abaixo. Licenca do pacote: LGPLv3 (ferramentas do
   Qt). Usada SO na bancada de build; NAO e redistribuida: nada dela entra no
   instalador, so o .qm que ela gera.
   A versao e a do Qt que o QGIS 3.44.13 embarcado usa (Qt 5.15): o formato do
   .qm e o que o QTranslator da arvore le.

 ONDE ELA FICA: installer\tools\qt5-applications-<versao>\ (fora do git). Se nao
 estiver la, o script baixa o wheel do PyPI, confere o SHA-256 e extrai so os 3
 arquivos que o lrelease precisa. -SemRede proibe o download; -Lrelease aponta
 um executavel explicito (a versao continua conferida).

 GUARDAS (a fonte e conferida antes de compilar, e o .qm depois):
   - rule "aplicativo"  : a traducao TEM o token do nome do produto;
   - rule "versao-motor": a traducao NAO tem o token (D-IMAN-039 regra 3: nunca
                          "versao do <produto>" onde o valor e a versao do QGIS);
   - os marcadores %1..%9 da traducao sao os mesmos do texto-fonte;
   - o lrelease declara ter gerado exatamente uma traducao por mensagem.

 SAIDA: uma linha TRADUCAO=OK|FALHOU e o resumo; exit 0 ou 1.

 ASCII-only de proposito: o PowerShell 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    [string]$Fonte = '',
    [string]$Brand = '',
    [string]$OutDir = '',
    [string]$Lrelease = $env:IMAN_LRELEASE,
    [string]$ToolsDir = '',
    [switch]$SemRede
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$raizRepo   = (Get-Item (Join-Path $raizScript '..')).FullName
if (-not $Fonte)    { $Fonte    = Join-Path $raizRepo 'app\i18n\iman_terra_pt_BR.json' }
if (-not $Brand)    { $Brand    = Join-Path $raizRepo 'app\profile-template\iman-distro\python\plugins\iman_brand\brand.py' }
if (-not $OutDir)   { $OutDir   = Join-Path $raizRepo 'installer\stage\i18n' }
if (-not $ToolsDir) { $ToolsDir = Join-Path $raizRepo 'installer\tools' }

$WheelVersion = '5.15.2.2.3'
$WheelName    = "qt5_applications-$WheelVersion-py3-none-win_amd64.whl"
$WheelUrl     = 'https://files.pythonhosted.org/packages/ae/a9/cd64cda6f58321c4a0021ced80117b225562efc42f1318ff2cea69c23eb7/' + $WheelName
$WheelSha256  = '5156CC710ED3942F736EC2C46889F73D829FCD4093BED8DBDDF2FD83929FDF0B'
$LreleaseVersion = '5.15.2'
$WheelMembers = @('lrelease.exe', 'Qt5Core.dll', 'Qt5Xml.dll')

function Falha([string]$Motivo) {
    Write-Output 'TRADUCAO=FALHOU'
    Write-Output ("MOTIVO=" + ($Motivo -replace '\s+', ' '))
    exit 1
}

# ------------------------------------------------------------ 1. a fonte
foreach ($p in @($Fonte, $Brand)) {
    if (-not (Test-Path -LiteralPath $p)) { Falha "nao existe: $p" }
}
$brandTexto = Get-Content -LiteralPath $Brand -Raw -Encoding UTF8
$m = [regex]::Match($brandTexto, '(?m)^\s*PRODUCT_NAME\s*=\s*"([^"]+)"')
if (-not $m.Success) { Falha "PRODUCT_NAME nao encontrado em $Brand" }
$ProductName = $m.Groups[1].Value

$doc = Get-Content -LiteralPath $Fonte -Raw -Encoding UTF8 | ConvertFrom-Json
$token = [string]$doc.product_token
$lingua = [string]$doc.language
if (-not $token)  { Falha 'a fonte nao declara product_token' }
if (-not $lingua) { Falha 'a fonte nao declara language' }
$msgs = @($doc.messages)
if ($msgs.Count -lt 1) { Falha 'a fonte nao tem mensagens' }

function Marcadores([string]$T) {
    return ((@([regex]::Matches($T, '%[1-9]') | ForEach-Object { $_.Value }) | Sort-Object -Unique) -join ',')
}

$erros = New-Object System.Collections.ArrayList
$vistos = @{}
foreach ($msg in $msgs) {
    $id = "[{0}] {1}" -f $msg.context, $msg.source
    if (-not $msg.context -or -not $msg.source -or -not $msg.iman_terra) { [void]$erros.Add("$id : campo vazio"); continue }
    $chave = "{0}`0{1}" -f $msg.context, $msg.source
    if ($vistos.ContainsKey($chave)) { [void]$erros.Add("$id : mensagem repetida") }
    $vistos[$chave] = $true
    $tem = ([string]$msg.iman_terra).Contains($token)
    switch ([string]$msg.rule) {
        'aplicativo'   { if (-not $tem) { [void]$erros.Add("$id : rule aplicativo sem $token") } }
        'versao-motor' { if ($tem) { [void]$erros.Add("$id : rule versao-motor nao pode nomear o produto (D-IMAN-039 regra 3)") } }
        default        { [void]$erros.Add("$id : rule desconhecida '$($msg.rule)'") }
    }
    if ((Marcadores $msg.source) -ne (Marcadores $msg.iman_terra)) {
        [void]$erros.Add("$id : marcadores %N diferem do texto-fonte")
    }
}
if ($erros.Count -gt 0) { Falha ("a fonte nao passa nas guardas: " + ($erros -join ' | ')) }

# ------------------------------------------------------------ 2. o lrelease
function Confere-Lrelease([string]$Exe) {
    if (-not (Test-Path -LiteralPath $Exe)) { return $false }
    $v = (& $Exe -version 2>&1 | Out-String)
    return ($v -match ('lrelease version ' + [regex]::Escape($LreleaseVersion) + '\b'))
}

if ($Lrelease) {
    if (-not (Confere-Lrelease $Lrelease)) { Falha "o lrelease em '$Lrelease' nao existe ou nao e a versao $LreleaseVersion" }
} else {
    $cache = Join-Path $ToolsDir ("qt5-applications-$WheelVersion")
    $Lrelease = Join-Path $cache 'lrelease.exe'
    if (-not (Confere-Lrelease $Lrelease)) {
        if ($SemRede) { Falha "lrelease ausente em $cache e -SemRede proibe baixar $WheelUrl" }
        New-Item -ItemType Directory -Path $cache -Force | Out-Null
        $whl = Join-Path $cache $WheelName
        if (-not (Test-Path -LiteralPath $whl) -or
            (Get-FileHash -LiteralPath $whl -Algorithm SHA256).Hash -ne $WheelSha256) {
            Write-Host "    baixando $WheelUrl (~61 MB, uma vez por bancada)"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $wc = New-Object System.Net.WebClient
            try { $wc.DownloadFile($WheelUrl, $whl) } finally { $wc.Dispose() }
        }
        $obtido = (Get-FileHash -LiteralPath $whl -Algorithm SHA256).Hash
        if ($obtido -ne $WheelSha256) {
            Remove-Item -LiteralPath $whl -Force -ErrorAction SilentlyContinue
            Falha "SHA-256 do wheel nao confere: esperado $WheelSha256, obtido $obtido"
        }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($whl)
        try {
            foreach ($nome in $WheelMembers) {
                $entrada = $zip.GetEntry("qt5_applications/Qt/bin/$nome")
                if (-not $entrada) { Falha "o wheel nao tem qt5_applications/Qt/bin/$nome" }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entrada, (Join-Path $cache $nome), $true)
            }
        } finally { $zip.Dispose() }
        # O wheel inteiro nao e necessario depois de extraido.
        Remove-Item -LiteralPath $whl -Force -ErrorAction SilentlyContinue
        if (-not (Confere-Lrelease $Lrelease)) { Falha "o lrelease extraido em $cache nao responde como $LreleaseVersion" }
    }
}

# ------------------------------------------------------------ 3. o .ts
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$base = "iman_terra_$lingua"
$ts = Join-Path $OutDir "$base.ts"
$qm = Join-Path $OutDir "$base.qm"
if (Test-Path -LiteralPath $qm) { Remove-Item -LiteralPath $qm -Force }

$cfg = New-Object System.Xml.XmlWriterSettings
$cfg.Encoding = New-Object System.Text.UTF8Encoding($false)
$cfg.Indent = $true
$w = [System.Xml.XmlWriter]::Create($ts, $cfg)
try {
    $w.WriteStartDocument()
    $w.WriteDocType('TS', $null, $null, $null)
    $w.WriteStartElement('TS')
    $w.WriteAttributeString('version', '2.1')
    $w.WriteAttributeString('language', $lingua)
    foreach ($grupo in ($msgs | Group-Object -Property context)) {
        $w.WriteStartElement('context')
        $w.WriteElementString('name', [string]$grupo.Name)
        foreach ($msg in $grupo.Group) {
            $w.WriteStartElement('message')
            $w.WriteElementString('source', [string]$msg.source)
            $w.WriteElementString('translation', ([string]$msg.iman_terra).Replace($token, $ProductName))
            $w.WriteEndElement()
        }
        $w.WriteEndElement()
    }
    $w.WriteEndElement()
    $w.WriteEndDocument()
} finally { $w.Close() }

# ------------------------------------------------------------ 4. o .qm
$saida = (& $Lrelease $ts -qm $qm 2>&1 | Out-String)
$rc = $LASTEXITCODE
if ($rc -ne 0 -or -not (Test-Path -LiteralPath $qm)) { Falha "lrelease saiu ${rc}: $saida" }
$g = [regex]::Match($saida, 'Generated (\d+) translation\(s\) \((\d+) finished and (\d+) unfinished\)')
if (-not $g.Success) { Falha "lrelease nao declarou o placar: $saida" }
if ([int]$g.Groups[1].Value -ne $msgs.Count -or [int]$g.Groups[3].Value -ne 0) {
    Falha ("lrelease gerou {0} traducao(oes), {1} sem terminar; a fonte tem {2} mensagens: {3}" -f `
           $g.Groups[1].Value, $g.Groups[3].Value, $msgs.Count, $saida)
}

Write-Output 'TRADUCAO=OK'
Write-Output ("MENSAGENS={0}" -f $msgs.Count)
Write-Output ("PRODUTO={0}" -f $ProductName)
Write-Output ("TS={0}" -f $ts)
Write-Output ("QM={0}" -f $qm)
Write-Output ("QM_SHA256={0}" -f (Get-FileHash -LiteralPath $qm -Algorithm SHA256).Hash)
Write-Output ("LRELEASE={0} ({1})" -f $Lrelease, $LreleaseVersion)
exit 0
