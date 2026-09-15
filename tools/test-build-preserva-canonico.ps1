<#
=============================================================================
 #029 - GUARDA DO DB-25: um build nao destroi o candidato a release

 O DEFEITO QUE ELA EXISTE PARA PEGAR
   Ate a #029 o nome do instalador era fixo por versao
   (Instituto-IMAN-IMAN-Terra-Setup-<versao>.exe) e o BUILD_INFO.txt era um
   arquivo so, em installer\dist\. Todo build da mesma versao, canonico ou de
   branch, escrevia no MESMO caminho. Medido na historia da develop: o
   registro canonico foi sobrescrito em 4 de 4 vezes, e 3 dos 4 .exe
   canonicos de 0.3.0 foram destruidos por build de branch.

 A ASSERCAO (C.2)
   O SHA-256 do .exe canonico e o SHA-256 dos BYTES do registro dele, ANTES e
   DEPOIS da acao. Nunca "o arquivo existe": com nome fixo o build de branch
   RECRIA o arquivo no mesmo caminho, e "existe" passaria com o defeito
   presente.

 ONDE ESTA O CANONICO (P0.8)
   A guarda nao presume caminho nem nome. Ela le o que o build.ps1 PUBLICA ao
   terminar: as linhas "Artefato : <caminho>" e "Info : <caminho>". Por isso a
   mesma guarda roda contra o build.ps1 de qualquer commit, antigo ou novo, e
   e assim que ela reprova o build.ps1 de 733e129.

 MATRIZ DE ESTADOS (S.4), na ordem em que rodam
   4  nao ha canonico nenhum: roda o primeiro build do repo (canonico). Tem de
      passar SEM falso positivo. E este build que vira a semente de 1 a 3.
   1  ha canonico; roda build de branch que TERMINA com sucesso.
   2  ha canonico; roda build de branch que FALHA no ISCC, depois do ponto em
      que o build remove o alvo.
   3  ha canonico; roda SEGUNDO canonico da mesma versao (commit novo na
      develop). Os dois tem de coexistir (R4).

 ISOLAMENTO - nada disto escreve no repo de onde a guarda e chamada
   - cada estado roda num CLONE descartavel, sob -Trabalho (fora do repo);
   - a arvore do QGIS (2,2 GB) e COPIADA uma vez para -Trabalho e os clones a
     enxergam por junction. A arvore da bancada nunca fica ao alcance de um
     build: o extrator remove o destino quando nao reaproveita, e o teste da
     guarda de integridade do launcher renomeia pastas da arvore que recebe.
     Duas rodadas em paralelo nao podem dividir a mesma copia, por isso cada
     rodada faz a sua;
   - o payload entra por HARDLINK (mesmo volume) ou copia;
   - todo build roda com -ReusarArvore -SemRede, e a guarda confere que a
     arvore esta visivel ANTES de cada build: sem ela o extrator cairia no
     `msiexec /a`, que abre transacao contra o ProductCode do QGIS (#019).

 INDUCAO DA FALHA DO ESTADO 2
   -IsccPath aponta para um .cmd gerado AQUI, em tempo de execucao, dentro de
   -Trabalho. Ele repassa a sonda de versao ao ISCC real e, na chamada de
   compilacao (a que comeca por /Q, depois do ponto de remocao), grava um
   marcador e sai com 1. Nada no build.ps1 nem no .iss muda. Sem o marcador o
   estado e ABORTADO: falha que nao aconteceu nao prova nada.

 E.1
   Antes de cada rodada o canonico de referencia e conferido: o SHA do .exe
   tem de bater com o do cofre E com o que o proprio registro declara, e os
   bytes do registro com os do cofre. Se o "antes" ja estiver errado, a rodada
   e ABORTADA, nunca PASS nem FAIL.

 SAIDA
   0 = todos os estados PASS
   1 = algum estado FAIL
   2 = algum estado ABORTADO (ambiente, E.1, ou estado nao exercitado). Precede
       o 1: rodada incompleta se refaz, nao se le.

 USO
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-build-preserva-canonico.ps1 -Ref HEAD
   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-build-preserva-canonico.ps1 -Ref 733e129 -Saida .\guarda-733e129.json

 CUSTO: tres compilacoes reais (estados 4, 1 e 3; ~17 min cada nesta bancada
 no #028) mais a copia da arvore. O estado 2 nao compila.

 ASCII-only de proposito: PS 5.1 le .ps1 sem BOM como ANSI.
=============================================================================
#>
[CmdletBinding()]
param(
    # Commit cujo build.ps1 e posto a prova. Vira a 'develop' dos clones.
    [Parameter(Mandatory = $true)][string]$Ref,

    # Pasta de trabalho descartavel. Default: <volume do repo>\_iman-terra-guarda-db25\<data>-<commit>.
    [string]$Trabalho = '',

    # ISCC real. O .cmd do estado 2 repassa a sonda de versao para ele.
    [string]$Iscc = 'C:\Program Files\Inno Setup 7\ISCC.exe',

    # Relatorio JSON (opcional).
    [string]$Saida = '',

    # Nao remove clones nem a copia da arvore ao fim (para inspecao).
    [switch]$ManterTrabalho
)

$ErrorActionPreference = 'Stop'

$raizScript = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Repo       = (Get-Item (Join-Path $raizScript '..')).FullName

function Escreve([string]$T, [string]$C = 'Gray') { Write-Host $T -ForegroundColor $C }

$resultados = New-Object System.Collections.ArrayList
$clones     = New-Object System.Collections.ArrayList
$Commit     = ''
$Versao     = ''
$Arvore     = ''
$ArvoreExe  = ''
$Logs       = ''

function Aborta([string]$Motivo, [string[]]$Detalhe = @()) {
    Escreve ''
    Escreve "  ABORTADO: $Motivo" 'Red'
    foreach ($l in $Detalhe) { Escreve "    $l" 'Yellow' }
    Escreve '  (nem PASS nem FAIL: esta rodada nao prova nada - refaca)' 'Yellow'
    throw "GUARDA-DB25-ABORTADA: $Motivo"
}

# git sem deixar stderr virar excecao (avisos de CRLF nao sao erro).
function Invoke-Git([string]$Dir, [string[]]$A) {
    $ErrorActionPreference = 'Continue'
    $out = & git.exe -C $Dir @A 2>&1
    $code = $LASTEXITCODE
    $linhas = @($out | ForEach-Object { "$_" })
    if ($code -ne 0) { Aborta "git $($A -join ' ') falhou (exit $code) em $Dir" $linhas }
    return $linhas
}

function Sha([string]$P) {
    if (-not $P -or -not (Test-Path -LiteralPath $P -PathType Leaf)) { return '<ausente>' }
    return (Get-FileHash -LiteralPath $P -Algorithm SHA256).Hash
}

function Campo([string]$Registro, [string]$Nome) {
    if (-not $Registro -or -not (Test-Path -LiteralPath $Registro -PathType Leaf)) { return $null }
    $m = [regex]::Match([string](Get-Content -LiteralPath $Registro -Raw),
                        '(?m)^' + [regex]::Escape($Nome) + '\s*:\s*(.+?)\s*$')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

function Foto([string]$Exe, [string]$Reg) {
    [pscustomobject]@{ ExeSha = (Sha $Exe); RegSha = (Sha $Reg) }
}

function Relativo([string]$Base, [string]$Caminho) {
    $b = [IO.Path]::GetFullPath($Base).TrimEnd('\') + '\'
    $c = [IO.Path]::GetFullPath($Caminho)
    if (-not $c.StartsWith($b, [StringComparison]::OrdinalIgnoreCase)) {
        Aborta "o build publicou um caminho fora do proprio clone" @("Clone  : $Base", "Caminho: $Caminho")
    }
    return $c.Substring($b.Length)
}

function MesmoCaminho([string]$X, [string]$Y) {
    return [string]::Equals([IO.Path]::GetFullPath($X), [IO.Path]::GetFullPath($Y),
                            [StringComparison]::OrdinalIgnoreCase)
}

$gitId = @('-c', 'user.name=guarda-db25', '-c', 'user.email=guarda-db25@localhost')

function Assercao([string]$Nome, $Antes, $Depois, [bool]$Ok) {
    [pscustomobject]@{ Nome = $Nome; Antes = "$Antes"; Depois = "$Depois"; Ok = $Ok }
}

function Registra([string]$Estado, [string]$Descricao, $Assercoes, $Builds) {
    $falhou = @($Assercoes | Where-Object { -not $_.Ok }).Count -gt 0
    $v = if ($falhou) { 'FAIL' } else { 'PASS' }
    [void]$resultados.Add([pscustomobject]@{
        Estado = $Estado; Veredito = $v; Descricao = $Descricao
        Assercoes = @($Assercoes); Builds = @($Builds)
    })
    Escreve ''
    Escreve ("  [{0}] estado {1} - {2}" -f $v, $Estado, $Descricao) $(if ($falhou) { 'Red' } else { 'Green' })
    foreach ($a in $Assercoes) {
        $marca = if ($a.Ok) { 'ok  ' } else { 'FAIL' }
        Escreve ("         {0} {1}" -f $marca, $a.Nome) $(if ($a.Ok) { 'Gray' } else { 'Red' })
        Escreve ("              antes : {0}" -f $a.Antes)
        Escreve ("              depois: {0}" -f $a.Depois)
    }
}

function Registra-Aborto([string]$Estado, [string]$Descricao, [string]$Motivo) {
    [void]$resultados.Add([pscustomobject]@{
        Estado = $Estado; Veredito = 'ABORTADO'; Descricao = "$Descricao :: $Motivo"
        Assercoes = @(); Builds = @()
    })
    Escreve ("  [ABORTADO] estado {0} - {1}" -f $Estado, $Motivo) 'Red'
}

function Motivo($Err) {
    $msg = $Err.Exception.Message
    if ($msg -like 'GUARDA-DB25-ABORTADA*') { return $msg.Substring('GUARDA-DB25-ABORTADA: '.Length) }
    Escreve "  ERRO INESPERADO: $msg" 'Red'
    Escreve "  $($Err.InvocationInfo.PositionMessage)" 'DarkGray'
    return "erro inesperado: $msg"
}

function Novo-Clone([string]$Origem, [string]$Sha1, [string]$Nome) {
    $dir = Join-Path $Trabalho $Nome
    if (Test-Path -LiteralPath $dir) { Aborta "clone ja existe: $dir" }
    Invoke-Git $Trabalho @('clone', '--quiet', '--no-checkout', $Origem, $dir) | Out-Null
    [void]$clones.Add($dir)
    Invoke-Git $dir @('checkout', '--quiet', '-B', 'develop', $Sha1) | Out-Null

    New-Item -ItemType Directory -Force -Path (Join-Path $dir 'installer\stage')   | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $dir 'installer\payload') | Out-Null

    $j = Join-Path $dir 'installer\stage\qgis'
    $o = & cmd.exe /c mklink /J "$j" "$Arvore" 2>&1
    if ($LASTEXITCODE -ne 0) { Aborta "mklink /J falhou" @($o | ForEach-Object { "$_" }) }

    $alvoPayload = Join-Path $dir "installer\payload\$PayloadNome"
    if ([IO.Path]::GetPathRoot($PayloadBancada) -eq [IO.Path]::GetPathRoot($alvoPayload)) {
        New-Item -ItemType HardLink -Path $alvoPayload -Target $PayloadBancada | Out-Null
    } else {
        Copy-Item -LiteralPath $PayloadBancada -Destination $alvoPayload
    }
    return $dir
}

function Remove-Clone([string]$Dir) {
    if ($ManterTrabalho) { return }
    if (-not $Dir -or -not (Test-Path -LiteralPath $Dir)) { return }
    $full = [IO.Path]::GetFullPath($Dir)
    $raiz = [IO.Path]::GetFullPath($Trabalho).TrimEnd('\') + '\'
    if (-not $full.StartsWith($raiz, [StringComparison]::OrdinalIgnoreCase)) {
        Aborta "recuso remover fora de -Trabalho: $full"
    }
    # A junction sai PRIMEIRO, com rmdir sem /s: remove o link, nunca o alvo.
    $j = Join-Path $full 'installer\stage\qgis'
    if (Test-Path -LiteralPath $j) {
        $item = Get-Item -LiteralPath $j -Force
        if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            Aborta "installer\stage\qgis do clone deixou de ser junction - um build extraiu por conta propria?" @(
                "Clone: $full", "Nao removo nada. Confira se houve msiexec /a (ProductCode do QGIS).")
        }
        & cmd.exe /c rmdir "$j" | Out-Null
        if (Test-Path -LiteralPath $j) { Aborta "a junction nao saiu: $j" }
    }
    if (-not (Test-Path -LiteralPath $ArvoreExe)) { Aborta "a copia da arvore sumiu ao remover a junction: $ArvoreExe" }
    & cmd.exe /c rd /s /q "$full" | Out-Null
    [void]$clones.Remove($Dir)
}

function Invoke-Build([string]$Clone, [string[]]$BuildArgs, [string]$Rotulo) {
    $exeNoClone = Join-Path $Clone ("installer\stage\qgis\QGIS {0}\bin\qgis-ltr-bin.exe" -f $Versao)
    if (-not (Test-Path -LiteralPath $exeNoClone)) {
        Aborta "a arvore do QGIS nao esta visivel no clone antes do build ($Rotulo)" @(
            "Esperado: $exeNoClone",
            "Sem ela o extrator rodaria msiexec /a contra o ProductCode do QGIS. Nao rodo.")
    }
    $log = Join-Path $Logs "$Rotulo.log"
    $ps  = Join-Path $PSHOME 'powershell.exe'
    $lista = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Clone 'installer\build.ps1')) + $BuildArgs
    $linha = ($lista | ForEach-Object { if ($_ -match '[\s"]') { '"' + $_ + '"' } else { $_ } }) -join ' '
    Escreve ''
    Escreve ("    build [{0}] {1:HH:mm:ss}: build.ps1 {2}" -f $Rotulo, (Get-Date), ($BuildArgs -join ' ')) 'DarkCyan'
    $t0 = Get-Date
    $p = Start-Process -FilePath $ps -ArgumentList $linha -RedirectStandardOutput $log `
                       -RedirectStandardError "$log.err" -NoNewWindow -PassThru
    $null = $p.Handle
    $p.WaitForExit()
    $seg = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

    $texto = ''
    if (Test-Path -LiteralPath $log) { $texto = [string](Get-Content -LiteralPath $log -Raw) }
    # O que o build PUBLICA (P0.8). A ultima ocorrencia e a do resumo final.
    $art = [regex]::Matches($texto, '(?m)^\s*Artefato\s*:\s*(.+?)\s*$')
    $inf = [regex]::Matches($texto, '(?m)^\s*Info\s*:\s*(.+?)\s*$')
    $r = [pscustomobject]@{
        Rotulo   = $Rotulo
        Exit     = $p.ExitCode
        Segundos = $seg
        Log      = $log
        Artefato = $(if ($art.Count) { $art[$art.Count - 1].Groups[1].Value } else { $null })
        Info     = $(if ($inf.Count) { $inf[$inf.Count - 1].Groups[1].Value } else { $null })
    }
    Escreve ("    build [{0}]: exit {1} em {2} s" -f $Rotulo, $r.Exit, $seg) 'DarkCyan'
    Escreve  "      Artefato publicado: $($r.Artefato)"
    Escreve  "      Info publicado    : $($r.Info)"
    $cauda = @(Get-Content -LiteralPath $log -ErrorAction SilentlyContinue | Where-Object { $_.Trim() } | Select-Object -Last 14)
    foreach ($l in $cauda) { Escreve "      | $l" 'DarkGray' }
    return $r
}

function Arvore-Limpa([string]$Dir, [string]$Contexto) {
    $st = @(Invoke-Git $Dir @('status', '--porcelain', '--untracked-files=all') | Where-Object { $_.Trim() })
    if ($st.Count -gt 0) {
        Aborta "a arvore do clone esta suja antes de $Contexto - o build recusaria e o estado nao seria exercitado" $st
    }
}

function Publicou([object]$B) {
    return [bool]($B.Artefato -and $B.Info -and (Test-Path -LiteralPath $B.Artefato -PathType Leaf) -and
                  (Test-Path -LiteralPath $B.Info -PathType Leaf))
}

# ============================================================================

Escreve ''
Escreve '  #029 - guarda do DB-25: um build nao destroi o candidato a release' 'White'

$preparado = $false
try {
    if (-not (Test-Path -LiteralPath $Iscc -PathType Leaf)) { Aborta "ISCC real nao encontrado: $Iscc" }

    $Commit = @(Invoke-Git $Repo @('rev-parse', '--verify', "$Ref^{commit}"))[0].Trim()
    $issRef = (Invoke-Git $Repo @('show', "${Commit}:installer/iman-terra.iss")) -join "`n"
    $mv = [regex]::Match($issRef, '(?m)^\s*#define\s+QgisBaselineVersion\s+"([^"]+)"')
    if (-not $mv.Success) { Aborta "QgisBaselineVersion nao encontrado no .iss de $Commit" }
    $Versao = $mv.Groups[1].Value

    if (-not $Trabalho) {
        $Trabalho = Join-Path ([IO.Path]::GetPathRoot($Repo)) (
            '_iman-terra-guarda-db25\' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $Commit.Substring(0, 7))
    }
    $Trabalho = [IO.Path]::GetFullPath($Trabalho)
    $repoRaiz = [IO.Path]::GetFullPath($Repo).TrimEnd('\') + '\'
    if ($Trabalho.StartsWith($repoRaiz, [StringComparison]::OrdinalIgnoreCase)) {
        Aborta "-Trabalho nao pode ficar dentro do repo" @("Repo    : $Repo", "Trabalho: $Trabalho")
    }
    if (Test-Path -LiteralPath (Join-Path $Trabalho 'arvore')) { Aborta "-Trabalho ja foi usado por outra rodada: $Trabalho" }
    New-Item -ItemType Directory -Force -Path $Trabalho | Out-Null
    $Logs = Join-Path $Trabalho 'logs'
    New-Item -ItemType Directory -Force -Path $Logs | Out-Null

    $PayloadNome    = "QGIS-OSGeo4W-$Versao-1.msi"
    $PayloadBancada = Join-Path $Repo "installer\payload\$PayloadNome"
    if (-not (Test-Path -LiteralPath $PayloadBancada)) { Aborta "payload ausente na bancada: $PayloadBancada" }

    Escreve "  ref      : $Ref = $Commit"
    Escreve "  QGIS     : $Versao"
    Escreve "  trabalho : $Trabalho"

    # --- a arvore: copia desta rodada, nunca a da bancada ------------------
    $manifestoBancada = Join-Path $Repo 'installer\stage\qgis-manifest.txt'
    $mt = [regex]::Match([string](Get-Content -LiteralPath $manifestoBancada -Raw -ErrorAction SilentlyContinue),
                         '(?m)^TOTAL\|(\d+)\|')
    if (-not $mt.Success) { Aborta "manifesto da bancada sem TOTAL: $manifestoBancada" }
    $totalEsperado = [int]$mt.Groups[1].Value

    $Arvore = Join-Path $Trabalho 'arvore'
    $origemArvore = Join-Path $Repo 'installer\stage\qgis'
    if (-not (Test-Path -LiteralPath (Join-Path $origemArvore "QGIS $Versao\bin\qgis-ltr-bin.exe"))) {
        Aborta "arvore da bancada ausente em $origemArvore"
    }
    Escreve ("  copiando a arvore do QGIS para esta rodada ({0:HH:mm:ss})..." -f (Get-Date))
    & robocopy.exe $origemArvore $Arvore /E /R:0 /W:0 /MT:16 /NFL /NDL /NP /NJH /NJS | Out-Null
    if ($LASTEXITCODE -ge 8) { Aborta "robocopy falhou (exit $LASTEXITCODE)" }
    $ArvoreExe = Join-Path $Arvore "QGIS $Versao\bin\qgis-ltr-bin.exe"
    $contagem = @(Get-ChildItem -LiteralPath (Join-Path $Arvore "QGIS $Versao") -Recurse -File -Force).Count
    if ($contagem -ne $totalEsperado) {
        Aborta "a copia da arvore nao casa com o manifesto" @("Manifesto: $totalEsperado", "Copia    : $contagem")
    }
    Escreve "  arvore   : $Arvore ($contagem arquivos = manifesto)"
    $preparado = $true
}
catch {
    Registra-Aborto 'preparo' 'ambiente da guarda' (Motivo $_)
}

# --- ESTADO 4: nao ha canonico nenhum ---------------------------------------
#
# "Primeiro build do repo": o clone nasce sem .exe (o git os ignora) e sem
# registro canonico rastreado. A lista abaixo cobre os DOIS desenhos, o de
# antes da #029 (installer/dist/BUILD_INFO.txt) e o de depois
# (installer/canonico/), para a mesma guarda valer contra os dois.

$Semente = $null
$A = $null
if ($preparado) {
    Escreve ''
    Escreve '  -- estado 4: sem canonico nenhum (primeiro build do repo) --' 'White'
    try {
        $A = Novo-Clone $Repo $Commit 'e4-semente'
        Invoke-Git $A @('rm', '-r', '-q', '--ignore-unmatch', '--', 'installer/dist/BUILD_INFO.txt', 'installer/canonico') | Out-Null
        $pend = @(Invoke-Git $A @('status', '--porcelain') | Where-Object { $_.Trim() })
        if ($pend.Count -gt 0) {
            Invoke-Git $A ($gitId + @('commit', '-q', '-m', 'guarda db25: primeiro build do repo, sem canonico')) | Out-Null
        }
        $exesAntes = @(Get-ChildItem -LiteralPath $A -Recurse -Filter '*.exe' -File -Force -ErrorAction SilentlyContinue |
                       Where-Object { $_.FullName -notlike (Join-Path $A 'installer\stage\*') -and
                                      $_.FullName -notlike (Join-Path $A '.git\*') })
        if ($exesAntes.Count -gt 0) { Aborta "o clone do estado 4 ja tem .exe" @($exesAntes | ForEach-Object { $_.FullName }) }
        Arvore-Limpa $A 'o estado 4'

        $b4 = Invoke-Build $A @('-ReusarArvore', '-SemRede') 'e4-primeiro-build-canonico'
        $a4 = @()
        $a4 += Assercao 'o primeiro build do repo termina (exit 0)' 'sem canonico' "exit $($b4.Exit)" ($b4.Exit -eq 0)
        $pub4 = Publicou $b4
        $a4 += Assercao 'o build publica Artefato e Info, e os dois existem' '-' "$($b4.Artefato) | $($b4.Info)" $pub4
        if ($pub4) {
            $sha4  = Sha $b4.Artefato
            $decl4 = Campo $b4.Info 'SHA-256'
            $a4 += Assercao 'o registro descreve o artefato ao lado (SHA-256 declarado == calculado)' $decl4 $sha4 ($decl4 -eq $sha4)
            $tam4  = Campo $b4.Info 'Tamanho (bytes)'
            $len4  = (Get-Item -LiteralPath $b4.Artefato).Length
            $a4 += Assercao 'tamanho declarado == tamanho no disco' $tam4 $len4 ("$tam4" -eq "$len4")
            $can4  = Campo $b4.Info 'Build canonico'
            $a4 += Assercao "o registro diz 'Build canonico: SIM'" 'SIM' $can4 ("$can4" -match '^SIM\b')
        }
        Registra '4' 'nao ha canonico: o primeiro build do repo passa sem falso positivo' $a4 @($b4)

        if ($resultados[$resultados.Count - 1].Veredito -eq 'PASS') {
            # --- a semente: cofre + P0.6 simulada ---------------------------
            $cofre = Join-Path $Trabalho 'cofre'
            New-Item -ItemType Directory -Force -Path $cofre | Out-Null
            $Semente = [pscustomobject]@{
                RelExe   = (Relativo $A $b4.Artefato)
                RelReg   = (Relativo $A $b4.Info)
                ExeSha   = (Sha $b4.Artefato)
                RegSha   = (Sha $b4.Info)
                Versao   = (Campo $b4.Info 'ProductVersion')
                CofreExe = (Join-Path $cofre 'canonico.exe')
                CofreReg = (Join-Path $cofre 'BUILD_INFO.txt')
                Commit   = ''
            }
            Copy-Item -LiteralPath $b4.Artefato -Destination $Semente.CofreExe -Force
            Copy-Item -LiteralPath $b4.Info     -Destination $Semente.CofreReg -Force
            if ((Sha $Semente.CofreExe) -ne $Semente.ExeSha -or (Sha $Semente.CofreReg) -ne $Semente.RegSha) {
                Aborta "E.1: a copia do cofre nao confere com a semente"
            }

            # Quem compilou commita o registro (P0.6). O .exe nao pode entrar.
            Invoke-Git $A @('add', '-A') | Out-Null
            Invoke-Git $A ($gitId + @('commit', '-q', '-m', 'guarda db25: registro do canonico (P0.6 simulada)')) | Out-Null
            $Semente.Commit = @(Invoke-Git $A @('rev-parse', 'HEAD'))[0].Trim()
            $rastreados = @(Invoke-Git $A @('ls-files'))
            if ($rastreados -contains ($Semente.RelExe -replace '\\', '/')) {
                Aborta "o .exe canonico entrou no commit: $($Semente.RelExe)"
            }
            if (-not ($rastreados -contains ($Semente.RelReg -replace '\\', '/'))) {
                Aborta "o registro canonico NAO ficou rastreado depois do commit: $($Semente.RelReg)"
            }
            Arvore-Limpa $A 'os estados 1 a 3'
            Escreve ''
            Escreve "  semente : $($Semente.RelExe)" 'White'
            Escreve "            SHA-256 $($Semente.ExeSha)"
            Escreve "  registro: $($Semente.RelReg)   (SHA-256 dos bytes $($Semente.RegSha))"
            Escreve "  commit  : $($Semente.Commit)   (registro commitado, P0.6 simulada)"
        }
    }
    catch {
        $Semente = $null
        Registra-Aborto '4' 'sem canonico nenhum' (Motivo $_)
    }
}

function Prepara-Estado([string]$Nome) {
    $B = Novo-Clone $A $Semente.Commit $Nome
    $exeB = Join-Path $B $Semente.RelExe
    $regB = Join-Path $B $Semente.RelReg
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $exeB) | Out-Null
    Copy-Item -LiteralPath $Semente.CofreExe -Destination $exeB
    # E.1: o "antes" tem de estar certo, senao a rodada nao prova nada.
    $antes = Foto $exeB $regB
    $decl  = Campo $regB 'SHA-256'
    if ($antes.ExeSha -ne $Semente.ExeSha -or $antes.RegSha -ne $Semente.RegSha -or $decl -ne $antes.ExeSha) {
        Aborta "E.1: o canonico de referencia NAO confere antes da rodada ($Nome)" @(
            "exe : $($antes.ExeSha)  (cofre $($Semente.ExeSha))",
            "reg : $($antes.RegSha)  (cofre $($Semente.RegSha))",
            "SHA declarado no registro: $decl")
    }
    Escreve "    E.1 ok: o canonico de referencia confere antes da rodada" 'Green'
    Escreve "            exe $($antes.ExeSha) == cofre == declarado no registro"
    Escreve "            reg $($antes.RegSha) == cofre"
    Arvore-Limpa $B $Nome
    return [pscustomobject]@{ Dir = $B; Exe = $exeB; Reg = $regB; Antes = $antes }
}

function Assercoes-Canonico($E) {
    $d = Foto $E.Exe $E.Reg
    return @(
        (Assercao 'SHA-256 do .exe canonico inalterado' $E.Antes.ExeSha $d.ExeSha ($E.Antes.ExeSha -eq $d.ExeSha)),
        (Assercao 'SHA-256 dos bytes do registro canonico inalterado' $E.Antes.RegSha $d.RegSha ($E.Antes.RegSha -eq $d.RegSha))
    )
}

$descr = @{
    '1' = 'ha canonico; build de branch com sucesso'
    '2' = 'ha canonico; build de branch que falha no ISCC'
    '3' = 'ha canonico; segundo canonico da mesma versao'
}

if (-not $Semente) {
    foreach ($id in @('1', '2', '3')) { Registra-Aborto $id $descr[$id] 'sem semente canonica valida (estado 4)' }
} else {

    # --- ESTADO 1 -----------------------------------------------------------
    Escreve ''
    Escreve "  -- estado 1: $($descr['1']) --" 'White'
    $e = $null
    try {
        $e = Prepara-Estado 'e1-branch-sucesso'
        Invoke-Git $e.Dir @('checkout', '-q', '-b', 'guarda/db25-branch') | Out-Null
        $b = Invoke-Build $e.Dir @('-ExpectedBranch', 'guarda/db25-branch', '-ReusarArvore', '-SemRede') 'e1-build-de-branch'
        if ($b.Exit -ne 0 -or -not (Publicou $b)) {
            Aborta "estado 1 nao exercitado: o build de branch nao terminou com sucesso (exit $($b.Exit))" @("Log: $($b.Log)")
        }
        $as = @(Assercoes-Canonico $e)
        $leafC = Split-Path -Leaf $e.Exe
        $leafB = Split-Path -Leaf $b.Artefato
        $vB = Campo $b.Info 'ProductVersion'
        $cB = Campo $b.Info 'Commit (curto)'
        $as += Assercao 'R1: o artefato de branch sai em OUTRO caminho' $e.Exe $b.Artefato (-not (MesmoCaminho $e.Exe $b.Artefato))
        $as += Assercao 'R1: canonico e branch se distinguem pelo NOME' $leafC $leafB ($leafC -ne $leafB)
        $as += Assercao 'R1: o nome do artefato de branch carrega versao e commit curto' "versao $vB, commit $cB" $leafB (
            [bool]($vB -and $cB -and $leafB.Contains($vB) -and $leafB.Contains($cB)))
        Registra '1' $descr['1'] $as @($b)
    }
    catch { Registra-Aborto '1' $descr['1'] (Motivo $_) }
    finally { if ($e) { try { Remove-Clone $e.Dir } catch { Registra-Aborto '1-limpeza' 'remocao do clone' (Motivo $_) } } }

    # --- ESTADO 2 -----------------------------------------------------------
    Escreve ''
    Escreve "  -- estado 2: $($descr['2']) --" 'White'
    $e = $null
    try {
        $e = Prepara-Estado 'e2-branch-falha-iscc'
        Invoke-Git $e.Dir @('checkout', '-q', '-b', 'guarda/db25-falha') | Out-Null
        $marcador = Join-Path $Trabalho 'iscc-induzido.marcador'
        if (Test-Path -LiteralPath $marcador) { Remove-Item -LiteralPath $marcador -Force }
        $wrapper = Join-Path $Trabalho 'iscc-que-falha.cmd'
        Set-Content -LiteralPath $wrapper -Encoding Ascii -Value @(
            '@echo off',
            'rem Gerado por tools\test-build-preserva-canonico.ps1 para o estado 2. NAO e do produto.',
            'rem A sonda de versao do build passa para o ISCC real; a compilacao (/Q ...) falha.',
            'if /i "%~1"=="/Q" goto falha',
            ('"' + $Iscc + '" %*'),
            'exit /b %ERRORLEVEL%',
            ':falha',
            ('echo induzido>"' + $marcador + '"'),
            'echo [guarda DB-25] ISCC induzido a falhar na chamada de compilacao 1>&2',
            'exit /b 1'
        )
        $b = Invoke-Build $e.Dir @('-ExpectedBranch', 'guarda/db25-falha', '-ReusarArvore', '-SemRede',
                                   '-IsccPath', $wrapper) 'e2-build-de-branch-iscc-falha'
        if (-not (Test-Path -LiteralPath $marcador)) {
            Aborta "estado 2 nao exercitado: o build nao chegou a chamar o ISCC para compilar (exit $($b.Exit))" @("Log: $($b.Log)")
        }
        if ($b.Exit -ne 4) {
            Aborta "estado 2: a falha foi induzida, mas o build saiu com exit $($b.Exit) e nao 4" @("Log: $($b.Log)")
        }
        Escreve "    inducao confirmada: marcador presente, build exit 4" 'DarkCyan'
        $as = @(Assercoes-Canonico $e)
        Registra '2' $descr['2'] $as @($b)
    }
    catch { Registra-Aborto '2' $descr['2'] (Motivo $_) }
    finally { if ($e) { try { Remove-Clone $e.Dir } catch { Registra-Aborto '2-limpeza' 'remocao do clone' (Motivo $_) } } }

    # --- ESTADO 3 -----------------------------------------------------------
    Escreve ''
    Escreve "  -- estado 3: $($descr['3']) --" 'White'
    $e = $null
    try {
        $e = Prepara-Estado 'e3-segundo-canonico'
        Invoke-Git $e.Dir ($gitId + @('commit', '-q', '--allow-empty', '-m', 'guarda db25: segundo canonico da mesma versao')) | Out-Null
        $b = Invoke-Build $e.Dir @('-ReusarArvore', '-SemRede') 'e3-segundo-build-canonico'
        if ($b.Exit -ne 0 -or -not (Publicou $b)) {
            Aborta "estado 3 nao exercitado: o segundo canonico nao terminou com sucesso (exit $($b.Exit))" @("Log: $($b.Log)")
        }
        $v2 = Campo $b.Info 'ProductVersion'
        if ($v2 -ne $Semente.Versao) {
            Aborta "estado 3 nao exercitado: o segundo canonico e da versao $v2, nao $($Semente.Versao)"
        }
        $as = @(Assercoes-Canonico $e)
        $sha2  = Sha $b.Artefato
        $decl2 = Campo $b.Info 'SHA-256'
        $can2  = Campo $b.Info 'Build canonico'
        $as += Assercao 'R4: o registro do segundo canonico descreve o .exe dele' $decl2 $sha2 ($decl2 -eq $sha2)
        $as += Assercao "R4: o segundo diz 'Build canonico: SIM'" 'SIM' $can2 ("$can2" -match '^SIM\b')
        $coexistem = (-not (MesmoCaminho $e.Exe $b.Artefato)) -and
                     (Test-Path -LiteralPath $e.Exe -PathType Leaf) -and (Test-Path -LiteralPath $b.Artefato -PathType Leaf)
        $as += Assercao 'R4: os dois canonicos coexistem (caminhos distintos, os dois no disco)' $e.Exe $b.Artefato $coexistem
        Registra '3' $descr['3'] $as @($b)
    }
    catch { Registra-Aborto '3' $descr['3'] (Motivo $_) }
    finally { if ($e) { try { Remove-Clone $e.Dir } catch { Registra-Aborto '3-limpeza' 'remocao do clone' (Motivo $_) } } }
}

# --- limpeza ----------------------------------------------------------------
if (-not $ManterTrabalho) {
    try {
        foreach ($c in @($clones)) { Remove-Clone $c }
        if ($Arvore -and (Test-Path -LiteralPath $Arvore)) { & cmd.exe /c rd /s /q "$Arvore" | Out-Null }
        $cofreDir = if ($Trabalho) { Join-Path $Trabalho 'cofre' } else { $null }
        if ($cofreDir -and (Test-Path -LiteralPath $cofreDir)) { & cmd.exe /c rd /s /q "$cofreDir" | Out-Null }
    } catch { Registra-Aborto 'limpeza' 'remocao do trabalho' (Motivo $_) }
}

# --- matriz -----------------------------------------------------------------
$ordem = @{ 'preparo' = 0; '4' = 1; '1' = 2; '2' = 3; '3' = 4 }
Escreve ''
Escreve "  MATRIZ - build.ps1 de $Commit" 'White'
foreach ($r in ($resultados | Sort-Object { if ($ordem.ContainsKey($_.Estado)) { $ordem[$_.Estado] } else { 9 } })) {
    $cor = switch ($r.Veredito) { 'PASS' { 'Green' } 'FAIL' { 'Red' } default { 'Yellow' } }
    Escreve ("    estado {0,-9} {1,-9} {2}" -f $r.Estado, $r.Veredito, $r.Descricao) $cor
}
Escreve "  logs: $Logs"
Escreve ''

if ($Saida) {
    [pscustomobject]@{
        Guarda     = 'tools/test-build-preserva-canonico.ps1'
        Ref        = $Ref
        Commit     = $Commit
        Trabalho   = $Trabalho
        Logs       = $Logs
        Semente    = $Semente
        Resultados = @($resultados)
        Gerado     = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Saida -Encoding UTF8
}

if (@($resultados | Where-Object { $_.Veredito -eq 'ABORTADO' }).Count -gt 0) { exit 2 }
if (@($resultados | Where-Object { $_.Veredito -eq 'FAIL' }).Count -gt 0) { exit 1 }
exit 0
