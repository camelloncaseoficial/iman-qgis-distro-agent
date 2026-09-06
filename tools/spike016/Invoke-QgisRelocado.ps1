<#
=============================================================================
 SPIKE #016 - executa o QGIS RELOCADO a partir da propria arvore

 Nao reimplementa o ambiente do QGIS: CHAMA os .bat da propria arvore
 (bin\o4w_env.bat + as linhas de bin\qgis-ltr.bat) e captura o environment
 resultante. Fidelidade maxima - se o contrato do OSGeo4W mudar, muda aqui
 junto, sem copia divergente.

 MODOS
   -Modo Env      : so imprime o environment montado (diagnostico)
   -Modo Python   : roda um .py com o python-qgis-ltr da arvore relocada
   -Modo Gui      : abre a janela principal do QGIS relocado
   -Modo Processo : roda qgis_process (headless) da arvore relocada

 SEMPRE passa --profiles-path para um perfil ISOLADO: o QGIS relocado nunca
 pode cair no %APPDATA%\QGIS do usuario (BL-3 / M8).

 CONTAMINACAO (estado C): -Contaminar injeta no ambiente as variaveis de um
 OUTRO QGIS (o instalado em Program Files) ANTES de chamar os .bat, para
 medir se o relocado se defende sozinho.

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    # OSGEO4W_ROOT da arvore relocada.
    [string]$Raiz = (Join-Path $env:LOCALAPPDATA 'InstitutoIMAN\_spike016\IMAN Terra\qgis\QGIS 3.44.13'),

    [ValidateSet('Env','Python','Gui','Processo')]
    [string]$Modo = 'Env',

    # Script .py para -Modo Python.
    [string]$Script = '',

    # Argumentos extras para -Modo Gui / -Modo Processo.
    [string[]]$Extra = @(),

    # -Modo Gui: script de startup passado como --code.
    [string]$Codigo = '',

    # -Modo Python: repassados ao asserts_pyqgis.py.
    [string]$Rotulo = 'relocado',
    [string]$SaidaJson = '',

    # Raiz de perfis isolada. O QGIS acrescenta 'profiles\' a este valor.
    [string]$ProfilesPath = (Join-Path $env:LOCALAPPDATA 'InstitutoIMAN\_spike016\perfil'),

    [string]$Perfil = 'iman-distro',

    # Estado C: polui o ambiente com o QGIS de OUTRA instalacao antes de rodar.
    [switch]$Contaminar,

    # Segundos de espera no -Modo Gui antes de fotografar e encerrar.
    [int]$EsperaGui = 45,

    [string]$OutDir = ''
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
if ([string]::IsNullOrEmpty($OutDir)) { $OutDir = Join-Path $raizScript 'evidencia' }
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

if (-not (Test-Path -LiteralPath $Raiz)) { throw "Arvore relocada nao encontrada: $Raiz" }
$Raiz = (Get-Item -LiteralPath $Raiz).FullName.TrimEnd('\')

$o4wEnv = Join-Path $Raiz 'bin\o4w_env.bat'
if (-not (Test-Path -LiteralPath $o4wEnv)) { throw "Arvore incompleta: falta $o4wEnv" }

# ------------------------------------------------------------------ ENV
# Monta o mesmo ambiente que bin\qgis-ltr.bat monta, chamando os .bat REAIS
# da arvore, e devolve o environment como hashtable.
function Get-EnvRelocado {
    param([string]$Root, [switch]$Poluir)

    $tmpBat = Join-Path $env:TEMP ("spike016-env-{0}.bat" -f ([guid]::NewGuid().ToString('N')))
    $linhas = @('@echo off')

    if ($Poluir) {
        # Estado C: finge que outra instalacao ja exportou seu ambiente.
        $outro = Get-ChildItem 'C:\Program Files' -Directory -Filter 'QGIS *' -ErrorAction SilentlyContinue |
                 Sort-Object Name | Select-Object -First 1
        if ($outro) {
            $o = $outro.FullName
            $linhas += "set OSGEO4W_ROOT=$o"
            $linhas += "set PROJ_DATA=$o\share\proj"
            $linhas += "set PROJ_LIB=$o\share\proj"
            $linhas += "set GDAL_DATA=$o\apps\gdal\share\gdal"
            $linhas += "set GDAL_DRIVER_PATH=$o\apps\gdal\lib\gdalplugins"
            $linhas += "set PYTHONHOME=$o\apps\Python312"
            $linhas += "set PYTHONPATH=$o\apps\qgis-ltr\python"
            $linhas += "set QT_PLUGIN_PATH=$o\apps\qgis-ltr\qtplugins;$o\apps\qt5\plugins"
            $linhas += "set QGIS_PREFIX_PATH=$($o -replace '\\','/')/apps/qgis-ltr"
            $linhas += "set GISBASE=$o\apps\grass\grass85"
            $linhas += "path $o\bin;%PATH%"
        }
    }

    # --- daqui para baixo e copia literal de bin\qgis-ltr.bat, sem o 'start'
    $linhas += "call `"$Root\bin\o4w_env.bat`""
    $linhas += "if not exist `"%OSGEO4W_ROOT%\apps\qgis-ltr\bin\qgisgrass8.dll`" goto nograss"
    $linhas += "if not exist `"%OSGEO4W_ROOT%\apps\grass\grass85\etc\env.bat`" goto nograss"
    $linhas += "set savedpath=%PATH%"
    $linhas += "call `"%OSGEO4W_ROOT%\apps\grass\grass85\etc\env.bat`""
    $linhas += "path %OSGEO4W_ROOT%\apps\grass\grass85\lib;%OSGEO4W_ROOT%\apps\grass\grass85\bin;%savedpath%"
    $linhas += ":nograss"
    $linhas += "path %OSGEO4W_ROOT%\apps\qgis-ltr\bin;%PATH%"
    $linhas += "set QGIS_PREFIX_PATH=%OSGEO4W_ROOT:\=/%/apps/qgis-ltr"
    $linhas += "set GDAL_FILENAME_IS_UTF8=YES"
    $linhas += "set VSI_CACHE=TRUE"
    $linhas += "set VSI_CACHE_SIZE=1000000"
    $linhas += "set QT_PLUGIN_PATH=%OSGEO4W_ROOT%\apps\qgis-ltr\qtplugins;%OSGEO4W_ROOT%\apps\qt5\plugins"
    # PYTHONPATH como o python-qgis-ltr.bat monta (necessario p/ import qgis.core)
    $linhas += "set PYTHONPATH=%OSGEO4W_ROOT%\apps\qgis-ltr\python;%PYTHONPATH%"
    $linhas += "set"

    Set-Content -LiteralPath $tmpBat -Value $linhas -Encoding Ascii
    $saida = & cmd.exe /c "`"$tmpBat`"" 2>&1
    Remove-Item -LiteralPath $tmpBat -Force -ErrorAction SilentlyContinue

    $h = @{}
    foreach ($l in $saida) {
        $s = [string]$l
        $i = $s.IndexOf('=')
        if ($i -gt 0) { $h[$s.Substring(0,$i)] = $s.Substring($i+1) }
    }
    return $h
}

$envReloc = Get-EnvRelocado -Root $Raiz -Poluir:$Contaminar

if ($envReloc.Count -lt 5) { throw "Nao consegui montar o environment da arvore relocada." }

# ------------------------------------------------------- aplica no processo
$restaurar = @{}
foreach ($k in $envReloc.Keys) {
    $restaurar[$k] = [Environment]::GetEnvironmentVariable($k, 'Process')
    [Environment]::SetEnvironmentVariable($k, $envReloc[$k], 'Process')
}

$interesse = @('OSGEO4W_ROOT','PATH','PROJ_DATA','PROJ_LIB','GDAL_DATA','GDAL_DRIVER_PATH',
               'PYTHONHOME','PYTHONPATH','PYTHONEXECUTABLE','QT_PLUGIN_PATH','QGIS_PREFIX_PATH',
               'GISBASE','GRASS_PYTHON','GS_LIB','PDAL_DRIVER_PATH','SSL_CERT_FILE','CURL_CA_BUNDLE')

if (-not (Test-Path -LiteralPath $ProfilesPath)) { New-Item -ItemType Directory -Path $ProfilesPath -Force | Out-Null }

try {
    switch ($Modo) {

        'Env' {
            Write-Host ''
            Write-Host "  ENV do QGIS relocado  (contaminado=$Contaminar)" -ForegroundColor White
            Write-Host "  raiz: $Raiz"
            Write-Host ''
            foreach ($k in $interesse) {
                $v = $envReloc[$k]
                if ($null -eq $v) { $v = '<nao definida>' }
                if ($k -eq 'PATH') { $v = ($v -split ';' | Select-Object -First 6) -join ';' ; $v += ' ...' }
                Write-Host ("  {0,-18} = {1}" -f $k, $v)
            }
            $env2 = @{}
            foreach ($k in $interesse) { $env2[$k] = $envReloc[$k] }
            $sufixo = 'limpo'; if ($Contaminar) { $sufixo = 'contaminado' }
            $env2 | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $OutDir "env-relocado-$sufixo.json") -Encoding UTF8
            Write-Host ''
        }

        'Python' {
            if (-not (Test-Path -LiteralPath $Script)) { throw "Script nao encontrado: $Script" }
            # Headless, o QgsApplication cai em %APPDATA%\QGIS\QGIS3\profiles\default
            # se ninguem disser o contrario - o que sozinho ja violaria o BL-3 e
            # sujaria a linha de base do M8. QGIS_CUSTOM_CONFIG_PATH desvia tudo
            # para o perfil isolado do spike.
            $cfg = Join-Path $ProfilesPath ("profiles\{0}" -f $Perfil)
            if (-not (Test-Path -LiteralPath $cfg)) { New-Item -ItemType Directory -Path $cfg -Force | Out-Null }
            [Environment]::SetEnvironmentVariable('QGIS_CUSTOM_CONFIG_PATH', $cfg, 'Process')
            Write-Host "  QGIS_CUSTOM_CONFIG_PATH = $cfg" -ForegroundColor DarkGray
            $py = Join-Path $Raiz 'bin\python3.exe'
            if (-not (Test-Path -LiteralPath $py)) { $py = Join-Path $Raiz 'apps\Python312\python3.exe' }
            Write-Host "  python relocado: $py" -ForegroundColor DarkGray
            $argPy = @()
            if ($Rotulo)    { $argPy += @('--rotulo', $Rotulo) }
            if ($SaidaJson) { $argPy += @('--saida',  $SaidaJson) }
            $argPy += $Extra
            & $py $Script @argPy
            exit $LASTEXITCODE
        }

        'Processo' {
            $qp = Join-Path $Raiz 'apps\qgis-ltr\bin\qgis_process-qgis-ltr.exe'
            if (-not (Test-Path -LiteralPath $qp)) { $qp = Join-Path $Raiz 'bin\qgis_process-qgis-ltr.exe' }
            if (-not (Test-Path -LiteralPath $qp)) { throw "qgis_process nao encontrado na arvore relocada." }
            & $qp @Extra
            exit $LASTEXITCODE
        }

        'Gui' {
            $exe = Join-Path $Raiz 'bin\qgis-ltr-bin.exe'
            if (-not (Test-Path -LiteralPath $exe)) { throw "qgis-ltr-bin.exe nao encontrado: $exe" }
            $argv = @('--profiles-path', $ProfilesPath, '--profile', $Perfil, '--noversioncheck')
            if ($Codigo) { $argv += @('--code', $Codigo) }
            $argv += $Extra
            Write-Host "  > $exe $($argv -join ' ')" -ForegroundColor DarkGray
            $p = Start-Process -FilePath $exe -ArgumentList $argv -PassThru
            Write-Host "  PID $($p.Id) - aguardando ate $EsperaGui s pela janela principal..."
            $titulo = ''
            for ($i = 0; $i -lt $EsperaGui; $i++) {
                Start-Sleep -Seconds 1
                $p.Refresh()
                if ($p.HasExited) { break }
                if ($p.MainWindowHandle -ne 0) {
                    $titulo = $p.MainWindowTitle
                    if ($titulo) { break }
                }
            }
            $p.Refresh()
            $saiu = $p.HasExited
            $res = [pscustomobject]@{
                Pid            = $p.Id
                JanelaHandle   = $(if ($saiu) { 0 } else { [int64]$p.MainWindowHandle })
                Titulo         = $titulo
                SaiuAntes      = $saiu
                ExitCode       = $(if ($saiu) { $p.ExitCode } else { $null })
                SegundosAteJan = $i
            }
            $res | ConvertTo-Json | Write-Host
            $res | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutDir 'gui-m1.json') -Encoding UTF8
            Write-Host ''
            Write-Host "  A janela continua aberta (PID $($p.Id)). Fotografe e encerre com:" -ForegroundColor Yellow
            Write-Host "    Stop-Process -Id $($p.Id)" -ForegroundColor Yellow
        }
    }
}
finally {
    foreach ($k in $restaurar.Keys) {
        [Environment]::SetEnvironmentVariable($k, $restaurar[$k], 'Process')
    }
}
