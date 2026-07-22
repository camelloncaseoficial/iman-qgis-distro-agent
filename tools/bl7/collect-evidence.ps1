<#
=============================================================================
 BL-7 - coleta do ambiente da VM + esqueleto do RESULT.md

 Le do proprio Windows os dados que o RESULT.md exige (e que ninguem lembra de
 anotar direito na hora): versao do Windows, versao EXATA do QGIS, resolucao,
 escala DPI, se a sessao e de administrador, onde o IMAN Terra foi instalado e
 se o perfil isolado existe. Grava um RESULT-esqueleto.md pronto para preencher.

 RODE DEPOIS de instalar e abrir o IMAN Terra ao menos uma vez.

 EXEMPLO
   .\collect-evidence.ps1

 REQUISITOS: Windows PowerShell 5.1. Sem Python, sem git, sem modulos de
 terceiros, sem privilegio de administrador. ASCII-only de proposito.
=============================================================================
#>
[CmdletBinding()]
param(
    [string]$OutDir = (Join-Path $env:USERPROFILE 'Desktop\bl7-evidence'),
    [string]$PerfilIsolado = (Join-Path $env:APPDATA 'InstitutoIMAN\IMAN Terra\profiles\iman-distro')
)

$ErrorActionPreference = 'Stop'

function Get-Safe([scriptblock]$Block, $Fallback = 'nao detectado') {
    try {
        $v = & $Block
        if ($null -eq $v -or "$v" -eq '') { return $Fallback }
        return $v
    } catch {
        return $Fallback
    }
}

Write-Host ""
Write-Host "  BL-7 - coleta de ambiente" -ForegroundColor White
Write-Host ""

# --- Windows -----------------------------------------------------------------

$os = Get-Safe { Get-CimInstance Win32_OperatingSystem } $null
$winCaption = 'nao detectado'
$winVersao  = 'nao detectado'
$winArch    = 'nao detectado'
if ($os) {
    $winCaption = $os.Caption
    $winVersao  = "$($os.Version) (build $($os.BuildNumber))"
    $winArch    = $os.OSArchitecture
}
$winIdioma = Get-Safe { (Get-Culture).Name }

# --- privilegio --------------------------------------------------------------
# O criterio de adocao (TI municipal) e instalar SEM elevar. Se esta sessao for
# de administrador, o passo 4 do checklist nao testa nada.
$ehAdmin = Get-Safe {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
} $null

# --- video: resolucao e escala ----------------------------------------------

$resolucao = 'nao detectado'
$video = Get-Safe {
    Get-CimInstance Win32_VideoController |
        Where-Object { $_.CurrentHorizontalResolution } |
        Select-Object -First 1
} $null
if ($video) {
    $resolucao = "$($video.CurrentHorizontalResolution)x$($video.CurrentVerticalResolution)"
} else {
    # Fallback: WinForms faz parte do .NET Framework do Windows (nao e modulo
    # de terceiros), mas so responde em sessao interativa.
    $resolucao = Get-Safe {
        Add-Type -AssemblyName System.Windows.Forms
        $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        "$($b.Width)x$($b.Height)"
    }
}

# Escala: 96 dpi = 100%, 120 = 125%, 144 = 150%.
$dpi = Get-Safe {
    (Get-ItemProperty 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name AppliedDPI -ErrorAction Stop).AppliedDPI
} $null
$escala = 'nao detectado'
if ($dpi) { $escala = "{0}% ({1} dpi)" -f ([math]::Round($dpi / 96 * 100)), $dpi }

# --- QGIS --------------------------------------------------------------------
# A versao do QGIS TESTADA vira a versao suportada declarada (regra de corte).

# ATENCAO: o qgis-ltr-bin.exe NAO tem resource de versao (ProductVersion e
# FileVersion vem VAZIOS - verificado no 3.44.9). Por isso a versao sai do NOME
# DA PASTA, que e como o instalador oficial do QGIS a registra. A chave de
# desinstalacao serve de confirmacao.
$qgisInstalacoes = @()

function New-QgisInfo([string]$Pasta, [string]$Exe, [string]$VersaoPasta) {
    return [PSCustomObject]@{
        Pasta  = $Pasta
        Exe    = $Exe
        Versao = $VersaoPasta
        LTR    = (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $Exe) 'qgis-ltr-bin.exe'))
    }
}

$raizes = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
foreach ($raiz in $raizes) {
    $dirs = Get-Safe { Get-ChildItem -LiteralPath $raiz -Filter 'QGIS *' -Directory -ErrorAction SilentlyContinue } @()
    foreach ($d in $dirs) {
        $exe = Join-Path $d.FullName 'bin\qgis-ltr-bin.exe'
        if (-not (Test-Path -LiteralPath $exe)) { $exe = Join-Path $d.FullName 'bin\qgis-bin.exe' }
        if (-not (Test-Path -LiteralPath $exe)) { continue }
        # "QGIS 3.44.9" -> "3.44.9"
        $ver = $d.Name -replace '^QGIS\s*', ''
        if (-not $ver) { $ver = $d.Name }
        $qgisInstalacoes += (New-QgisInfo $d.FullName $exe $ver)
    }
}

foreach ($exe in @('C:\OSGeo4W\bin\qgis-ltr-bin.exe', 'C:\OSGeo4W\bin\qgis-bin.exe')) {
    if (Test-Path -LiteralPath $exe) {
        $qgisInstalacoes += (New-QgisInfo 'C:\OSGeo4W' $exe 'OSGeo4W (versao na pasta apps\qgis-ltr)')
        break
    }
}

# Confirmacao independente pela chave de desinstalacao do QGIS oficial.
$qgisRegistro = @()
foreach ($padrao in @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')) {
    $achados = Get-Safe {
        Get-ItemProperty -Path $padrao -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like 'QGIS*' }
    } @()
    foreach ($a in $achados) { $qgisRegistro += "$($a.DisplayName)" }
}
$qgisRegistro = @($qgisRegistro | Sort-Object -Unique)

# --- IMAN Terra instalado ----------------------------------------------------
# Instalacao sem elevar cai em HKCU; com elevacao, em HKLM. Procura nos dois.

$chavesUninstall = @(
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$instalacao = $null
foreach ($padrao in $chavesUninstall) {
    $achado = Get-Safe {
        Get-ItemProperty -Path $padrao -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like 'IMAN Terra*' } |
            Select-Object -First 1
    } $null
    if ($achado) { $instalacao = $achado; break }
}

$imanNome    = 'NAO INSTALADO'
$imanVersao  = '-'
$imanPasta   = '-'
$imanEscopo  = '-'
if ($instalacao) {
    $imanNome   = $instalacao.DisplayName
    $imanVersao = Get-Safe { $instalacao.DisplayVersion } '-'
    $imanPasta  = Get-Safe { $instalacao.InstallLocation } '-'
    $imanEscopo = 'por usuario (HKCU, sem elevacao)'
    if ($instalacao.PSPath -like '*HKEY_LOCAL_MACHINE*') { $imanEscopo = 'por maquina (HKLM, elevado)' }
}

# --- perfis ------------------------------------------------------------------

$perfilUsuarioRaiz = Join-Path $env:APPDATA 'QGIS\QGIS3\profiles'
$perfilUsuarioExiste = Test-Path -LiteralPath $perfilUsuarioRaiz
$isoladoExiste = Test-Path -LiteralPath $PerfilIsolado
$isoladoArquivos = 0
if ($isoladoExiste) {
    $isoladoArquivos = @(Get-ChildItem -LiteralPath $PerfilIsolado -Recurse -File -Force -ErrorAction SilentlyContinue).Count
}

# --- console -----------------------------------------------------------------

Write-Host "  Windows        : $winCaption"
Write-Host "  Versao         : $winVersao  ($winArch, $winIdioma)"
Write-Host "  Sessao admin   : $ehAdmin"
Write-Host "  Resolucao      : $resolucao"
Write-Host "  Escala         : $escala"
Write-Host "  PowerShell     : $($PSVersionTable.PSVersion)"
Write-Host ""
if ($qgisInstalacoes.Count -eq 0) {
    Write-Host "  QGIS           : NENHUM (esperado na VM-A)" -ForegroundColor Yellow
} else {
    foreach ($q in $qgisInstalacoes) {
        $marca = 'nao-LTR'
        if ($q.LTR) { $marca = 'LTR' }
        Write-Host "  QGIS           : $($q.Versao)  [$marca]  -  $($q.Pasta)"
    }
}
foreach ($r in $qgisRegistro) { Write-Host "  QGIS (registro): $r" -ForegroundColor DarkGray }
Write-Host ""
if ($instalacao) {
    Write-Host "  IMAN Terra     : $imanNome $imanVersao"
} else {
    Write-Host "  IMAN Terra     : NAO INSTALADO" -ForegroundColor Yellow
}
Write-Host "  Instalado em   : $imanPasta"
Write-Host "  Escopo         : $imanEscopo"
Write-Host "  Perfil isolado : $(if ($isoladoExiste) { "SIM ($isoladoArquivos arquivos)" } else { 'NAO' })"
Write-Host ""

# --- esqueleto do RESULT.md --------------------------------------------------

if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}
$OutFile = Join-Path $OutDir 'RESULT-esqueleto.md'

$linhasQgis = @()
if ($qgisInstalacoes.Count -eq 0) {
    $linhasQgis += '- nenhum QGIS encontrado nesta maquina'
} else {
    foreach ($q in $qgisInstalacoes) {
        $marca = 'nao-LTR'
        if ($q.LTR) { $marca = 'LTR' }
        $linhasQgis += "- ``$($q.Versao)`` ($marca) em ``$($q.Pasta)``"
    }
}
foreach ($r in $qgisRegistro) { $linhasQgis += "- confirmado no registro: ``$r``" }
$linhasQgis += ''
$linhasQgis += '> A versao vem do NOME DA PASTA: o `qgis-ltr-bin.exe` nao carrega resource de'
$linhasQgis += '> versao (ProductVersion/FileVersion vazios). Confirme em Ajuda > Sobre.'

$md = @()
$md += '<!-- Gerado por tools/bl7/collect-evidence.ps1. Cole estes dados no'
$md += '     docs/verify/bl7-clean-vm/RESULT.md e preencha o resto na mao. -->'
$md += ''
$md += '## Ambiente da VM'
$md += ''
$md += '| Campo | Valor |'
$md += '|---|---|'
$md += "| Windows | $winCaption |"
$md += "| Versao/build | $winVersao |"
$md += "| Arquitetura / idioma | $winArch / $winIdioma |"
$md += "| Sessao de administrador | $ehAdmin |"
$md += "| Resolucao | $resolucao |"
$md += "| Escala de exibicao | $escala |"
$md += "| PowerShell | $($PSVersionTable.PSVersion) |"
$md += "| Coletado em | $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')) |"
$md += ''
$md += '### QGIS presente (a versao TESTADA vira a versao suportada declarada)'
$md += ''
$md += $linhasQgis
$md += ''
$md += '### IMAN Terra'
$md += ''
$md += '| Campo | Valor |'
$md += '|---|---|'
$md += "| Produto | $imanNome |"
$md += "| Versao | $imanVersao |"
$md += "| Pasta de instalacao | $imanPasta |"
$md += "| Escopo | $imanEscopo |"
$md += "| Perfil do usuario existe | $perfilUsuarioExiste ($perfilUsuarioRaiz) |"
$md += "| Perfil isolado existe | $isoladoExiste ($isoladoArquivos arquivos) |"
$md += "| Perfil isolado | $PerfilIsolado |"
$md += ''
$md += '### A preencher na mao'
$md += ''
$md += '- SHA-256 do .exe baixado (`Get-FileHash .\<arquivo>.exe -Algorithm SHA256`)'
$md += '- Commit e ProductVersion conforme o BUILD_INFO.txt'
$md += '- Texto LITERAL exibido pelo SmartScreen'
$md += '- Tabela PASS/FAIL por BL-1..BL-7'
$md += ''

Set-Content -LiteralPath $OutFile -Value $md -Encoding UTF8

Write-Host "  Esqueleto do RESULT: $OutFile" -ForegroundColor Green
Write-Host ""
