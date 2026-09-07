<#
=============================================================================
 SPIKE #016 - ESTADO D: arvore relocada INCOMPLETA

 O briefing exige que uma arvore incompleta falhe ALTO E VISIVEL, nunca em
 "canvas em branco silencioso". Este script quebra a arvore de proposito, de
 forma reversivel (renomeia um diretorio), sobe o QGIS relocado, registra o
 que aconteceu e RESTAURA - inclusive se der erro no meio (try/finally).

 NAO toca em nada fora da arvore relocada.

 POR QUE NAO TIRA SCREENSHOT: nesta bancada a captura por tela pegou a janela
 de OUTRO instalador que estava em primeiro plano (2026-09-06). Evidencia por
 pixel depende de quem esta na frente; evidencia por processo e janela, nao.
 Entao aqui se mede: exit code, stderr, e o titulo de TODAS as janelas de
 topo do processo - o que distingue "dialogo de erro" de "janela principal"
 e de "nada na tela".

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Assert-EstadoD.ps1 -Quebrar qt-plugins
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Assert-EstadoD.ps1 -Quebrar proj
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Assert-EstadoD.ps1 -Quebrar qgis-resources
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Assert-EstadoD.ps1 -Quebrar nenhum   # controle

 ASCII-only de proposito.
=============================================================================
#>
[CmdletBinding()]
param(
    [ValidateSet('qt-plugins','proj','qgis-resources','qgis-bin','nenhum')]
    [string]$Quebrar = 'qt-plugins',

    [string]$Raiz = (Join-Path $env:LOCALAPPDATA 'InstitutoIMAN\_spike016\IMAN Terra\qgis\QGIS 3.44.13'),
    [string]$ProfilesPath = (Join-Path $env:LOCALAPPDATA 'InstitutoIMAN\_spike016\perfil'),
    [string]$Perfil = 'iman-distro',
    [int]$Espera = 45,
    [string]$OutDir = ''
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
if ([string]::IsNullOrEmpty($OutDir)) { $OutDir = Join-Path $raizScript 'evidencia' }
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$sig = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public class Win16 {
    public delegate bool EnumProc(IntPtr h, IntPtr p);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr p);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    public static List<string> Janelas(uint alvo) {
        var lista = new List<string>();
        EnumWindows((h, p) => {
            uint pid; GetWindowThreadProcessId(h, out pid);
            if (pid != alvo || !IsWindowVisible(h)) return true;
            var t = new StringBuilder(512); GetWindowTextW(h, t, 512);
            var c = new StringBuilder(256); GetClassNameW(h, c, 256);
            lista.Add(c.ToString() + " | " + t.ToString());
            return true;
        }, IntPtr.Zero);
        return lista;
    }
}
'@
if (-not ('Win16' -as [type])) { Add-Type -TypeDefinition $sig }

$mapa = @{
    'qt-plugins'     = 'apps\qt5\plugins'
    'proj'           = 'share\proj'
    'qgis-resources' = 'apps\qgis-ltr\resources'
    'qgis-bin'       = 'apps\qgis-ltr\bin'
}

$alvo = $null; $quebrado = $null; $nome = $null
if ($Quebrar -ne 'nenhum') {
    $alvo = Join-Path $Raiz $mapa[$Quebrar]
    if (-not (Test-Path -LiteralPath $alvo)) { throw "Nao encontrei o alvo a quebrar: $alvo" }
    $nome = Split-Path -Leaf $alvo
    $quebrado = Join-Path (Split-Path -Parent $alvo) "$nome.SPIKE016-AUSENTE"
}

Write-Host ''
if ($Quebrar -eq 'nenhum') {
    Write-Host '  ESTADO D - CONTROLE (arvore intacta)' -ForegroundColor White
} else {
    Write-Host ("  ESTADO D - removendo '{0}' da arvore relocada" -f $mapa[$Quebrar]) -ForegroundColor Yellow
}

try {
    if ($alvo) { Rename-Item -LiteralPath $alvo -NewName (Split-Path -Leaf $quebrado) }

    $exe = Join-Path $Raiz 'bin\qgis-ltr-bin.exe'
    $errFile = Join-Path $OutDir ("estadoD-$Quebrar-stderr.txt")
    $outFile = Join-Path $OutDir ("estadoD-$Quebrar-stdout.txt")

    # Ambiente do proprio .bat da arvore (mesmo caminho do produto).
    $tmpBat = Join-Path $env:TEMP ("spike016-denv-{0}.bat" -f ([guid]::NewGuid().ToString('N')))
    @('@echo off', "call `"$Raiz\bin\o4w_env.bat`"",
      'path %OSGEO4W_ROOT%\apps\qgis-ltr\bin;%PATH%',
      'set QGIS_PREFIX_PATH=%OSGEO4W_ROOT:\=/%/apps/qgis-ltr',
      'set QT_PLUGIN_PATH=%OSGEO4W_ROOT%\apps\qgis-ltr\qtplugins;%OSGEO4W_ROOT%\apps\qt5\plugins',
      'set') | Set-Content -LiteralPath $tmpBat -Encoding Ascii
    $envLinhas = & cmd.exe /c "`"$tmpBat`"" 2>&1
    Remove-Item -LiteralPath $tmpBat -Force -ErrorAction SilentlyContinue
    $restaurar = @{}
    foreach ($l in $envLinhas) {
        $s = [string]$l; $i = $s.IndexOf('=')
        if ($i -gt 0) {
            $k = $s.Substring(0,$i)
            $restaurar[$k] = [Environment]::GetEnvironmentVariable($k,'Process')
            [Environment]::SetEnvironmentVariable($k, $s.Substring($i+1), 'Process')
        }
    }

    $p = Start-Process -FilePath $exe `
            -ArgumentList @('--profiles-path', "`"$ProfilesPath`"", '--profile', $Perfil, '--noversioncheck') `
            -PassThru -RedirectStandardError $errFile -RedirectStandardOutput $outFile

    $janelas = @()
    $tituloPrincipal = ''
    for ($i = 0; $i -lt $Espera; $i++) {
        Start-Sleep -Seconds 1
        if ($p.HasExited) { break }
        $p.Refresh()
        $janelas = @([Win16]::Janelas([uint32]$p.Id))
        if ($p.MainWindowTitle) { $tituloPrincipal = $p.MainWindowTitle }
        # janela principal do QGIS carregada => para de esperar
        if ($tituloPrincipal -match 'QGIS' -and $tituloPrincipal -ne 'QGIS3') { break }
    }

    $p.Refresh()
    $saiu = $p.HasExited
    $exitCode = $null
    if ($saiu) { $exitCode = $p.ExitCode }
    if (-not $saiu) { $janelas = @([Win16]::Janelas([uint32]$p.Id)) }

    $stderrTxt = ''; $stdoutTxt = ''
    if (Test-Path -LiteralPath $errFile) { $stderrTxt = (Get-Content -LiteralPath $errFile -Raw -ErrorAction SilentlyContinue) }
    if (Test-Path -LiteralPath $outFile) { $stdoutTxt = (Get-Content -LiteralPath $outFile -Raw -ErrorAction SilentlyContinue) }

    $chegouNaJanelaPrincipal = ($tituloPrincipal -match 'QGIS' -and $tituloPrincipal -ne 'QGIS3')

    $res = [pscustomobject]@{
        Quebrado                = $(if ($Quebrar -eq 'nenhum') { '<nada>' } else { $mapa[$Quebrar] })
        SegundosEsperados       = $Espera
        ProcessoSaiuSozinho     = $saiu
        ExitCode                = $exitCode
        TituloJanelaPrincipal   = $tituloPrincipal
        ChegouNaJanelaPrincipal = $chegouNaJanelaPrincipal
        JanelasVisiveis         = $janelas
        Stderr                  = ($stderrTxt | Out-String).Trim()
        Stdout                  = (($stdoutTxt | Out-String).Trim() -split "`n" | Select-Object -First 25) -join "`n"
    }
    $res | ConvertTo-Json -Depth 4 | Write-Host
    $res | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $OutDir "estadoD-$Quebrar.json") -Encoding UTF8

    if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
    foreach ($k in $restaurar.Keys) { [Environment]::SetEnvironmentVariable($k, $restaurar[$k], 'Process') }
}
finally {
    # RESTAURA SEMPRE. Uma arvore deixada quebrada envenenaria todas as outras
    # medicoes desta bancada.
    Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if ($quebrado -and (Test-Path -LiteralPath $quebrado)) {
        Rename-Item -LiteralPath $quebrado -NewName $nome
    }
    if ($alvo) {
        $ok = Test-Path -LiteralPath $alvo
        Write-Host ''
        Write-Host ("  arvore RESTAURADA: {0} -> {1}" -f $mapa[$Quebrar], $ok) -ForegroundColor $(if ($ok) { 'Green' } else { 'Red' })
        if (-not $ok) { Write-Host '  ATENCAO: restauracao falhou. NAO use esta arvore para mais medicoes.' -ForegroundColor Red }
    }
}
