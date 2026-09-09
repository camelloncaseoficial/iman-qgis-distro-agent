# `#028` — O build canônico `327d9ee`: o artefato de onde o vídeo é gravado

**Executado em:** 2026-09-09 · branch **`develop`** · commit **`327d9ee`**
**Bancada:** Windows 11 Pro 10.0.26200 · PowerShell 5.1 · Inno Setup 7.1.0 · **sem QGIS de sistema**
**Tipo:** operacional — **nenhum arquivo de aplicação mudou**.

---

## 0. Legenda (`E.6`)

| marca | significa |
|---|---|
| **medido** | número obtido nesta bancada, nesta sessão, com evidência em `evidencia/` |
| **relatado** | veio de outra sessão ou de outro observador, identificado como tal |
| **`N/E`** | não medido — nomeado, com o motivo |

---

## VEREDITO

> ### O artefato do vídeo existe, e é o primeiro com os 20 raios em 2px
>
> ```
> Artefato        : Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe   (489,05 MB)
> SHA-256         : 38DA4709FB121C89C6A52FD96A107C5502316FBDD1BFEC07CE8B2809F68B73E7
> Commit          : 327d9ee2585da067296eeae0dacbcbbd37dbfca3   (== HEAD da develop)
> Branch          : develop
> Build canonico  : SIM
> ```
>
> **Medido dentro do produto instalado a partir dele:** `20` declarações de raio no `style.qss`
> (18 `border-radius` + 2 cantos de aba), **todas `2px`**, e **zero** raio inline no Python.
>
> **`13 PASS · 0 FAIL · 1 N/E`** contra este artefato, `INTEGRIDADE=OK`, contagem exata do manifesto.
> Na tela: `Projeto sem título - IMAN Terra` e `● versão 0.3.0 · 327d9ee`.

---

## 1. Pré-condição — conferida antes de extrair

A extração abre transação do Windows Installer contra o **mesmo ProductCode** do QGIS de sistema, e
foi essa operação que desinstalou o QGIS da bancada no `#019`. Conferido por nós, **antes** de rodar:

| verificação | resultado (**medido**) |
|---|---|
| `QGIS*` em `C:\Program Files` e `Program Files (x86)` | **nenhum diretório** |
| entradas `QGIS` na ARP — `HKLM` 64, `HKLM` 32 (`WOW6432Node`), `HKCU` | **nenhuma** |
| ProductCode `{740D7A65-CBA3-1014-A0B5-B03A9B7608F5}` registrado | **não** |
| processos `qgis-ltr-bin` / `qgis-bin` | **0** |
| `IMAN Terra.SOBRAS-GATE` (do arquiteto) | **intacta, não tocada** |

---

## 2. O build

`installer\build.ps1` **sem argumentos** — exige `develop`, e **sempre remonta** a árvore a partir do
payload conferido (sem `-ReusarArvore`).

```
OK  branch 'develop', arvore limpa
OK  ProductVersion 0.3.0 / QGIS embarcado 3.44.13
OK  launcher e .iss concordam em QGIS 3.44.13
OK  versao do produto 0.3.0 concorda nas tres fontes            (D9)
OK  payload conferido (42E2F1A6...44EB4)
OK  extracao concluida em 215,5 s (exit 0)
OK  arvore: 37337 arquivos / 2,224 GB
OK  manifesto de integridade gerado e conferido contra a arvore

  #019 - guarda de integridade do launcher       6 de 6 casos passaram
  #022 - guarda estatica do tema                 6 de 6 assercoes passaram

OK  BUILD_ID.txt: 0.3.0 / 327d9ee / develop (canonico: sim)
OK  Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe (489.05 MB)
```

> A guarda estática rodou aqui pela primeira vez com a asserção **6** (`#027`): **zero raio inline
> em Python**. Um build só sai se o tema estiver num lugar só.

---

## 3. `E.5` — o SHA-256, recalculado nesta máquina

```powershell
Get-FileHash .\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe -Algorithm SHA256
```

| | |
|---|---|
| calculado agora | `38DA4709FB121C89C6A52FD96A107C5502316FBDD1BFEC07CE8B2809F68B73E7` |
| gravado no `BUILD_INFO` | `38DA4709FB121C89C6A52FD96A107C5502316FBDD1BFEC07CE8B2809F68B73E7` |
| **batem** | **sim** |
| tamanho | **512.808.129 bytes** (489,05 MB) |

**Como conferir na VM** (`PowerShell 5.1`, sem nada instalado):

```powershell
Get-FileHash .\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe -Algorithm SHA256
```

---

## 4. O artefato instalado, e o que ele devolve

| | **medido** |
|---|---|
| instalar (sobre a instalação anterior) | `exit 0`, **161,7 s** |
| árvore instalada / manifesto | **37.337 / 37.337** — diferença **0** |
| guarda do próprio produto (`IMAN_TERRA_CHECK_ONLY=1`) | `exit 0`, **`INTEGRIDADE=OK`** |
| **aceite, 1ª execução** | **`13 PASS · 0 FAIL · 1 N/E`** |
| **aceite, 2ª execução** (`A07b`) | **`1 PASS · 0 FAIL`** |
| guarda estática do tema | **6 de 6** |

```
A01=PASS A02=PASS A03=PASS A04=PASS A05=PASS A06=PASS A07=PASS
A08=PASS A09=PASS A10=PASS A11=PASS A12=PASS A13=PASS   M-D11=N/E   A07b=PASS
```

Duas rodadas, a primeira logo após a instalação: **75,7 s** e **41,3 s**, ambas com `A02=PASS` e
`origem=evento-de-estilo` — o conserto do `DB-23` continua sendo o **evento**, não a rede.

O único `N/E` é o `M-D11`, bloqueado em A1 desde a `#018`.

### 4.1 Os 20 raios, medidos DENTRO do produto instalado

```
border-radius            : 18   valores distintos: 2
cantos especificos       :  2   valores distintos: 2
TOTAL de raios           : 20
raio inline no Python    :  0   ocorrencias
```

**É o primeiro artefato em que isso é verdade.**

### 4.2 A identidade, na tela e no arquivo

```
BUILD_ID ({app}) : versao=0.3.0  commit=327d9ee2585da...  branch=develop  build_canonico=sim
TELA             : 0.3.0 · 327d9ee
TITULO           : Projeto sem título - IMAN Terra
```

Evidência visual: `evidencia/shots/canonico-home.png` e `evidencia/shots/canonico-sobre.png`
(`grab()` do Qt). São as duas telas do vídeo.

---

## 5. O que entra neste artefato desde o canônico anterior (`374c0f5`)

| fatia | o que entra |
|---|---|
| **`#022`** | título `— QGIS [iman-distro]` → **`- IMAN Terra`**; raio `2px` no `style.qss`; barra de menus densa (folga por item **24,5 → 8,5 px**) |
| **`#025`** | **`DB-23`** — o piso do campo de coordenadas reage a **evento**, não a relógio; **`DB-24`** — o produto exibe **de que build ele é** (`{app}\BUILD_ID.txt` → home e *Sobre*) |
| **`#027`** | os **seis raios inline** saem do Python; o tema vira **um lugar só**, e a guarda passa a defender essa propriedade |

O `#024` (canônico `374c0f5`) já carregava, pela primeira vez: o QGIS dentro do produto (`#019`), os
avisos de licença corrigidos (`#020`), o instalador sem laço (`#021`) e a arte oficial.

---

## 6. ⚠ Uma imprecisão de log, nomeada e não consertada

O `build.ps1` imprime, depois da guarda do tema:

```
    OK  o tema esta como o sponsor arbitrou (5 de 5 asse rcoes)
```

**São 6 desde o `#027`.** A própria guarda imprime `6 de 6` duas linhas acima — o número errado está
só na linha de resumo do `build.ps1`, que ficou para trás quando a asserção 6 nasceu.

**Não consertei**, e é deliberado: este despacho é operacional, *"nenhum arquivo de aplicação muda"*,
e a imprecisão **não afeta o artefato nem nenhuma decisão** — a guarda roda completa e reprova
corretamente. Fica nomeada para virar uma linha em fatia futura.

---

## 7. O commit direto na `develop`

O `installer/dist/BUILD_INFO.txt` foi commitado direto na `develop` (`af2eef5`) — a **exceção**
aprovada ao `ship = abrir PR`: *um arquivo, um caminho, uma ocasião*. Vale o `D-IMAN-032` integral:
**quem compila é quem commita**, porque o Inno grava `mtime` e o git não o preserva.

**O build sujou exatamente esse arquivo** — `git status` acusou só ele, e só ele entrou.

> Este laudo é um segundo commit na `develop`, pela mesma razão declarada no `#024`: ele é o
> entregável do despacho, e não subproduto do build.

---

## 8. O que continua pendente

- **`BL-7` em VM limpa** — esta é a bancada do dev. O artefato para levar é o desta página, e o
  `SHA-256` da §3 é o que se confere lá.
- **Reescrever o `CHECKLIST.md` do `BL-7`** — fatia própria.
- **`#023`** (travessão) · **`DA-3`** (plugin REURB) · exclusão de pacotes do `#020` · `D11`.
