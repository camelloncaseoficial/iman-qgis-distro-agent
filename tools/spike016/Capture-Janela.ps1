<#
=============================================================================
 SPIKE #016 - fotografa a janela de um processo (evidencia de M1/M2/M6)

 Captura o retangulo da janela principal do PID informado e grava .png.
 Se a janela nao existir, grava a tela inteira e diz que caiu no fallback -
 nunca mente sobre a origem da imagem.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Capture-Janela.ps1 -Pid 1234 -Saida foto.png

 ASCII-only de proposito.
=============================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][int]$ProcId,
    [Parameter(Mandatory=$true)][string]$Saida,
    [switch]$TelaInteira
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$sig = @'
using System;
using System.Runtime.InteropServices;
public class W16 {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
}
'@
if (-not ('W16' -as [type])) { Add-Type -TypeDefinition $sig }

$p = Get-Process -Id $ProcId -ErrorAction Stop
$p.Refresh()
$h = $p.MainWindowHandle

$origem = 'janela'
$rect = New-Object W16+RECT

if ($h -ne 0 -and -not $TelaInteira) {
    if ([W16]::IsIconic($h)) { [void][W16]::ShowWindow($h, 9) }   # SW_RESTORE
    [void][W16]::SetForegroundWindow($h)
    Start-Sleep -Milliseconds 1200
    [void][W16]::GetWindowRect($h, [ref]$rect)
}

if ($h -eq 0 -or $TelaInteira -or ($rect.R - $rect.L) -le 0) {
    $origem = 'tela-inteira-FALLBACK'
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $rect.L = $b.Left; $rect.T = $b.Top; $rect.R = $b.Right; $rect.B = $b.Bottom
}

$w = $rect.R - $rect.L
$ht = $rect.B - $rect.T
$bmp = New-Object System.Drawing.Bitmap($w, $ht)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($rect.L, $rect.T, 0, 0, (New-Object System.Drawing.Size($w, $ht)))
$g.Dispose()

$dir = Split-Path -Parent $Saida
if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$bmp.Save($Saida, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host ("  foto: {0}  origem={1}  {2}x{3}  titulo='{4}'" -f $Saida, $origem, $w, $ht, $p.MainWindowTitle)
