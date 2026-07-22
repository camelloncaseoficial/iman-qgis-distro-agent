<#
=============================================================================
 BL-7 / BL-3 - snapshot do perfil QGIS DO USUARIO

 Fotografa recursivamente o perfil do QGIS do proprio usuario (o que a distro
 NUNCA pode tocar), com SHA-256 por arquivo, e grava em JSON.

 Rode DUAS vezes:
   1) ANTES de instalar o IMAN Terra      -Rotulo antes
   2) DEPOIS de instalar, abrir e fechar  -Rotulo depois
 Depois compare com assert-bl3.ps1.

 EXEMPLO
   .\snapshot-user-profile.ps1 -Rotulo antes
   .\snapshot-user-profile.ps1 -Rotulo depois

 REQUISITOS: Windows PowerShell 5.1. Sem Python, sem git, sem modulos de
 terceiros, sem privilegio de administrador. ASCII-only de proposito (o PS 5.1
 le .ps1 sem BOM como ANSI).
=============================================================================
#>
[CmdletBinding()]
param(
    # Rotulo desta captura. Vira parte do nome do arquivo de saida.
    [string]$Rotulo = 'antes',

    # Raiz dos perfis do QGIS do USUARIO. So mude se souber o que esta fazendo.
    [string]$Path = (Join-Path $env:APPDATA 'QGIS\QGIS3\profiles'),

    # Onde gravar a evidencia.
    [string]$OutDir = (Join-Path $env:USERPROFILE 'Desktop\bl7-evidence')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}
$OutFile = Join-Path $OutDir ("perfil-usuario-{0}.json" -f $Rotulo)

Write-Host ""
Write-Host "  BL-3 - snapshot do perfil do usuario  [$Rotulo]" -ForegroundColor White
Write-Host "  Raiz: $Path"
Write-Host ""

$existe = Test-Path -LiteralPath $Path

# Canonicaliza a raiz ANTES de qualquer calculo de caminho relativo. Sem isto,
# um caminho curto 8.3 (FRANCI~1), um caminho relativo ou uma barra sobrando no
# fim mudariam o comprimento da string e deslocariam o recorte - o baseline e a
# assercao veriam nomes diferentes para o MESMO arquivo e o BL-3 daria FAIL
# falso (tudo aparecendo como adicionado + removido).
if ($existe) { $Path = (Get-Item -LiteralPath $Path).FullName }
$Path = $Path.TrimEnd('\')

$arquivos = @()
$totalBytes = 0

if ($existe) {
    # -Force para incluir arquivos ocultos: um .ini oculto alterado tambem e
    # violacao de BL-3.
    $itens = Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue

    foreach ($item in $itens) {
        # Caminho RELATIVO a raiz: a comparacao nao pode depender do nome do
        # usuario do Windows (que muda entre a bancada e a VM).
        $rel = $item.FullName.Substring($Path.Length).TrimStart('\')

        $hash = $null
        try {
            $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
        } catch {
            # Arquivo travado (ex.: QGIS aberto). Registrado como erro em vez de
            # sumir do snapshot - um arquivo que some viraria falso PASS.
            $hash = "ERRO_LEITURA: " + $_.Exception.Message
        }

        $arquivos += [PSCustomObject]@{
            Caminho = $rel
            Bytes   = $item.Length
            SHA256  = $hash
        }
        $totalBytes += $item.Length
    }

    $arquivos = @($arquivos | Sort-Object Caminho)
} else {
    Write-Host "  AVISO: a raiz nao existe." -ForegroundColor Yellow
    Write-Host "  Isso e ESPERADO na VM-A (maquina sem QGIS nenhum)." -ForegroundColor Yellow
    Write-Host "  Na VM-B seria um erro de preparo: abra o QGIS uma vez antes." -ForegroundColor Yellow
}

$snapshot = [PSCustomObject]@{
    Ferramenta    = 'snapshot-user-profile.ps1'
    Formato       = 1
    Rotulo        = $Rotulo
    CapturadoEm   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
    Raiz          = $Path
    RaizExiste    = $existe
    TotalArquivos = $arquivos.Count
    TotalBytes    = $totalBytes
    Arquivos      = $arquivos
}

$snapshot | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $OutFile -Encoding UTF8

Write-Host "  Arquivos : $($arquivos.Count)"
Write-Host "  Bytes    : $totalBytes"
Write-Host "  Gravado  : $OutFile" -ForegroundColor Green
Write-Host ""
