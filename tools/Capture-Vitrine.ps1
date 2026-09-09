<#
=============================================================================
 #022 - captura a VITRINE (V.1 "renderize o alvo", V.4 "build atual")

 Sobe o produto pelo mesmo caminho do aceite, com a sonda `vitrine.py` (que
 maximiza a janela, abre um menu e mostra um dialogo), e fotografa a TELA
 INTEIRA.

 POR QUE A TELA INTEIRA, e nao `widget.grab()`: a barra de TITULO e desenhada
 pelo Windows, fora do Qt - um grab do widget nao a contem. E o menu aberto e
 o dialogo sao janelas de topo SEPARADAS, que so aparecem juntas numa tomada
 da tela. "Numa tomada" era o pedido.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Capture-Vitrine.ps1 -Saida foto.png

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Saida,
    [int]$Assenta = 4
)

$ErrorActionPreference = 'Stop'
$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$aceite = Join-Path $raizScript 'branding-acceptance\Invoke-Aceite.ps1'

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $aceite `
    -Sonda 'vitrine.py' -Manter | Out-Null

Start-Sleep -Seconds $Assenta

$p = Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { throw 'O QGIS nao ficou aberto para a captura.' }

$dir = Split-Path -Parent $Saida
if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.Left, $b.Top, 0, 0, $bmp.Size)
$bmp.Save($Saida, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

Write-Host ("  capturado: {0}  ({1}x{2})" -f $Saida, $b.Width, $b.Height) -ForegroundColor Green

Get-Process -Name 'qgis-ltr-bin' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
