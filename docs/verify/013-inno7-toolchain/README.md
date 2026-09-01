# Fatia #013 — Inno Setup 7 como compilador do release (`D-IMAN-030`)

Medido em **2026-09-01** na bancada do dev: Windows 11 Pro 10.0.26200, PowerShell 5.1,
**Inno Setup 7.1.0** (`C:\Program Files\Inno Setup 7\`, ARP `Inno Setup 7_is1`), **nenhum Inno 6**.
Commit do artefato: `be05420`, branch `chore/013-inno7-toolchain`.

> **O build desta fatia é NÃO-CANÔNICO por construção.** A guarda 2 do `build.ps1` exige `develop`,
> e a correção que faz o build funcionar ainda está na branch. O artefato canônico sai de `develop`
> depois do merge — o `BUILD_INFO.txt` registra `Build canonico: NAO` exatamente para isso não ser
> confundido depois.

---

## 1. Descoberta e validação do ISCC — 7 sondas

O trecho real de `installer/build.ps1` (localização + validação de versão) foi extraído e executado
contra ambientes falsificados. **O código é o do arquivo, lido a cada execução; só o ambiente é
falso.** As raízes sintéticas são *junctions* para o Inno 7 real — não há Inno 6 nesta máquina para
apontar, e instalá-lo está fora de escopo (§7 do briefing).

| # | Cenário | Resultado |
|---|---|---|
| C1 | Descoberta automática, sem `-IsccPath` e sem `$env:ISCC` | ✅ `C:\Program Files\Inno Setup 7\ISCC.exe` · `7.1.0` |
| C2 | Só um diretório `Inno Setup 6`; ARP e PATH neutralizados | ✅ acha o caminho da major **6** |
| C3 | `Inno Setup 6` **e** `7` na mesma base | ✅ vence o **7** |
| C3b | **6 em `LOCALAPPDATA` (1º do array) × 7 em `ProgramFiles` (3º)** | ✅ vence o **7** — a precedência é da major, não da ordem dos caminhos |
| C4 | `-IsccPath` apontado para `C:\Windows\System32\whoami.exe` | ✅ **`Fail 2`**, build recusado |
| C5 | ISCC real `7.1.0` contra `$IsccMajoresAceitas = @(6)` | ✅ **`Fail 2`** — "Inno Setup 7.1.0 nao e uma versao aceita" |
| C6 | `-IsccPath` explícito | ✅ vence a descoberta |
| C7 | `$env:ISCC` | ✅ vence a descoberta |

C3b é o caso que importa: com o 6 no **primeiro** diretório procurado e o 7 no **terceiro**, o 7
ainda vence. A precedência é arbitrada, não acidental.

## 2. Como a versão do compilador é medida — as duas fontes óbvias não servem

Descoberta empírica exigida pelo §4 do briefing:

| Fonte | O que devolve no Inno 7.1.0 |
|---|---|
| `(Get-Item ISCC.exe).VersionInfo.FileVersion` | `0.0.0.0` |
| `.ProductVersion` | `0.0.0.0` |
| Banner do ISCC sem argumentos | `Inno Setup 7 Command-Line Compiler` — **só a major** |
| ISCC com um `.iss`, **sem `/Q`** | `Compiler engine version: Inno Setup 7.1.0` ✅ |
| ARP `Inno Setup 7_is1` → `DisplayVersion` | `7.1.0` (corrobora) |
| ISPP `Ver` | `117506048` = `0x07010000` (corrobora) |

O `/Q` que o build usa para compilar **suprime** a linha. Por isso a sonda é uma chamada separada:
manda o ISCC compilar um `.iss` descartável que aborta no pré-processador — a linha sai antes do
erro. **Custo medido: ~60 ms.** Roda com timeout, porque `-IsccPath` e `$env:ISCC` apontam para um
executável arbitrário.

`BUILD_INFO.txt` agora traz:

```
Compilador            : Inno Setup 7.1.0
Compilador (caminho)  : C:\Program Files\Inno Setup 7\ISCC.exe
```

A versão bate com a do ARP.

## 3. Build completo

```
==> Rodando o teste de deteccao do QGIS pelo launcher
    ...
    5 de 5 casos passaram.
    OK  launcher passa no teste de deteccao (5 de 5)
==> Estagiando o payload do QGIS 3.44.13
    OK  payload ja estagiado e conferido
    OK  QGIS-OSGeo4W-3.44.13-1.msi (555,23 MB)
==> Localizando o compilador do Inno Setup
    OK  Inno Setup 7.1.0  (C:\Program Files\Inno Setup 7\ISCC.exe)
==> Compilando
    OK  Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe (558.33 MB)

  BUILD OK   exit 0   (8,3 s com o payload já estagiado)
```

**Guarda do `DB-18`: 5 de 5** — primeira execução num build de verdade desde o merge do PR #15.
Conferida também a **sensibilidade** ao defeito: o mesmo teste, apontado para uma reprodução da
rotina antiga do launcher, dá **1 de 5** (caem M2b, M3, M3+ e o fallback). Um teste que passasse nos
dois não seria evidência de nada.

Também exercitado sem querer, e funcionou: um download interrompido deixou 383,92 MB estagiados, e o
build **descartou** o arquivo por SHA-256 divergente antes de recopiar.

### Um defeito real do `.iss`, achado aqui — e que não é do Inno 7

Primeira tentativa: `Error on line 163 ... Column 44: String error`. Causa: o comentário que
documenta a troca de `ProductCode` citava o GUID antigo **entre chaves**, e em Pascal Script a chave
de fechar encerra o comentário onde aparecer. O resto do texto virou código. **O Inno 6 faria
igual** — não é incompatibilidade, é bug nosso, corrigido.

## 4. Avisos do ISCC 7 — transcrição integral

Compilado **sem `/Q`**, com a saída desviada para não tocar o artefato que o `BUILD_INFO` descreve:

```
Inno Setup 7 Command-Line Compiler
Copyright (C) 1997-2026 Jordan Russell. All rights reserved.
Portions Copyright (C) 2000-2026 Martijn Laan. All rights reserved.
Portions Copyright (C) 2001-2004 Alex Yackimoff. All rights reserved.
https://www.innosetup.com

Compiler engine version: Inno Setup 7.1.0
Non-commercial use only
...
Successful compile (5,360 sec).
```

**Avisos: NENHUM.** 107 linhas de log, zero `Warning`, zero menção a depreciação. Especificamente
**nada** sobre `ArchitecturesInstallIn64BitMode=x64compatible`, `Compression=lzma2`,
`SolidCompression=no`, os PNG do wizard ou `compiler:Languages\`.

> ### ⚠ STOP-AND-FLAG — licenciamento do compilador
> O Inno 7 imprime **`Non-commercial use only`** no cabeçalho de cada compilação. É uma mudança de
> licenciamento do próprio Inno Setup, não do nosso pacote. O IMAN Terra é distribuído
> gratuitamente como peça institucional, mas **se essa cláusula alcança ou não este uso é decisão do
> sponsor/arquiteto**, não da crew. Registrado aqui porque a linha aparece em todo build a partir de
> agora.

## 5. `[Languages]` sob o Inno 7 (§5.4)

`compiler:Languages\BrazilianPortuguese.isl` resolve para
`C:\Program Files\Inno Setup 7\Languages\BrazilianPortuguese.isl` e compila. O arquivo tem **zero
diretivas `#`**, então a restrição nova do Inno 7 não morde aqui.

Diff real contra o `.isl` do **Inno 6.7.3** (baixado do `issrc`, tag `is-6_7_3` — o 6 não existe
mais nesta máquina para comparar localmente). **Dois strings mudaram, no arquivo inteiro:**

| Mensagem | 6.7.3 | 7.1.0 |
|---|---|---|
| `OnlyOnTheseArchitectures` | `...arquiteturas de processadores:%n%n% 1` | `...:%n%n%1` (corrige o `% 1`, que não substituía) |
| `SelectLanguageLabel` | `Selecione o idioma pra usar durante a instalação:` | `...instalação.` |

**Nenhum dos dois é alcançável no nosso wizard:** só há um idioma no `[Languages]`, então o diálogo
de seleção não aparece, e `OnlyOnTheseArchitectures` só sai em máquina de arquitetura incompatível.
**Conclusão: o texto do wizard não mudou em relação ao 0.2.0 por causa do `.isl`.**

## 6. `DB-16` exercitado — e o que ficou sem prova

**Lado que PULA — provado, com a chave REAL.** Baseline agora é `3.44.13`, que é o QGIS desta
bancada, então o `ProductCode` do payload está de fato no registro. Rodando o setup com `/LOG`:

```
2026-09-01 17:41:30.383   Setup version: Inno Setup version 7.1.0 (32-bit)
2026-09-01 17:41:30.390   64-bit install mode: Yes
2026-09-01 17:41:55.408   QGIS 3.44.13 ({740D7A65-CBA3-1014-A0B5-B03A9B7608F5}) ja instalado: PULANDO o encadeamento.
2026-09-01 17:41:55.816   Installation process succeeded.
```

Corroborado: `LastWriteTime` de `C:\Program Files\QGIS 3.44.13` **inalterado** (`2026-08-31
07:39:24`, antes e depois) e **nenhum** `qgis-install.log` criado, nem em busca recursiva.

> **O log confirma que a armadilha do `DB-16` é real.** `Setup version: ... (32-bit)`: o executável
> gerado continua sendo de 32 bits sob o Inno 7. Um `RegKeyExists(HKLM, ...)` seria redirecionado
> para `WOW6432Node` e devolveria `False` **sempre**. É o `HKLM64` explícito do `[Code]` que segura
> isso — e a razão do comentário no `.iss` envelheceu bem.

**Lado que ENCADEIA — NÃO exercitado.** Decisão do sponsor (2026-09-01): não desinstalar o QGIS da
bancada nem forjar o registro só para isso. Fica pendente para a rodada de VM limpa (BL-7), onde a
máquina naturalmente não tem o `ProductCode`.

> ⚠ **Furo declarado.** Sozinho, o lado "pula" não distingue *"pulou porque a chave existe"* de
> *"`RegKeyExists` devolve `True` sempre"*. O que reduz — mas não elimina — a dúvida é que o mesmo
> código já foi visto encadeando na fatia #011. **A prova completa é o `M1` do CHECKLIST.**

## 7. Caminhos estendidos no log (§5.5)

**Sim, o Inno 7 loga caminhos `\\?\`-prefixados** — e só num lugar:

```
2026-09-01 17:41:55.463   Dest filename: \\?\C:\Program Files\IMAN Terra\assets\icon-iman-terra.ico
```

**34 de 290 linhas**, todas do tipo `Dest filename:`. Todo o resto do log traz caminho normal —
`Original Setup EXE`, o diretório temporário (`...\Temp\is-5X8UGQYLZF.tmp`), `Directory for
uninstall files`, a chave de desinstalação e a nossa própria linha do `Log()`.

### Passos do `CHECKLIST.md` afetados — a lista (não o conserto; §7)

**Nenhum passo casa caminho dentro de um log.** A varredura completa achou um único passo que toca
log, e por existência, não por texto. Mas ela expôs dois problemas de outra natureza, para a fatia
do **D3**:

1. **`16.4` não pode falhar.** Ele confere `Get-ChildItem $env:TEMP -Filter 'qgis-install.log'`, sem
   `-Recurse`. O `.iss` escreve esse log em `{tmp}`, que é `%TEMP%\is-XXXXXXXX.tmp\` — um
   **subdiretório** — e o Inno o apaga ao sair. **Medido hoje:** depois de um run, nem a busca
   recursiva acha o arquivo. O passo dá `PASS` tenha o encadeamento rodado ou não: é insensível ao
   próprio defeito que deveria detectar.
2. **Toda a baseline do checklist ficou STALE.** Passos `4.3`, `5.7`, `16.3`, `16.4`, `17.x` e os
   cabeçalhos das rodadas `M2a`/`M2b` falam em `3.44.9`. Com a baseline em `3.44.13`, o texto do
   `M2b` também perde o sentido: ele explica a ambiguidade por `'1' < '9'`, e agora o par relevante
   é `3.44.12` × `3.44.13`, isto é `'2' < '3'`.

Verificado por medição, e **não** houve regressão: a chave ARP do IMAN Terra continua na view de
**64 bits** depois do build com o Inno 7 (a linha `Deleting uninstall key left over from previous
administrative 64-bit install` é housekeeping de re-registro, não mudança de view).

## 8. Tamanho do artefato — a emenda ao `DB-5`

| | Payload | Artefato | Diferença |
|---|---|---|---|
| `DB-5`, Inno **6.7.3**, `lzma2` + sólido | 541,14 MB | **534,44 MB** | — |
| `DB-5`, Inno **6.7.3**, MSI `nocompression` | 541,14 MB | **544,13 MB** | **+2,99 MB** |
| **Hoje**, Inno **7.1.0**, MSI `nocompression` | 555,23 MB | **558,33 MB** | **+3,10 MB** |

> **O número bruto não é comparável:** entre as duas medições mudaram **duas** coisas — o compilador
> **e** o payload (`3.44.9` → `3.44.13`, +14,09 MB). Comparar `544,13` com `558,33` mediria a versão
> do QGIS, não o Inno 7.
>
> **O que é comparável é o excedente sobre o payload** — a camada de marca comprimida mais o stub do
> Setup, que é a única parte que o compilador de fato comprime: **2,99 MB → 3,10 MB**, ou
> **+0,11 MB (+3,7%)**. É esse o número que emenda o `DB-5`. Não foi isolado o efeito do compilador
> puro (exigiria recompilar a baseline `3.44.9` sob o 7, e o download não cabia nesta fatia).

Tempo de compilação: **5,360 s** (`Successful compile`), contra os 11,1 s do não-sólido medidos na
fatia #010 sob o Inno 6 — máquina e payload diferentes, então é referência, não medição de ganho.

---

## Como reproduzir

```powershell
# build (a branch é exigida; use -PayloadCache para não rebaixar 555 MB)
.\installer\build.ps1 -ExpectedBranch <branch> -PayloadCache '<pasta com o .msi>'

# avisos do compilador, sem tocar o artefato de dist\
& 'C:\Program Files\Inno Setup 7\ISCC.exe' "/O<pasta-descartavel>" .\installer\iman-terra.iss

# o log do setup (é ele que traz a linha do DB-16)
.\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe /LOG="<arquivo>"
```
