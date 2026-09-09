# `#024` — O primeiro build canônico do IMAN Terra `0.3.0`

**Executado em:** 2026-09-09 · branch **`develop`** · commit **`374c0f5`**
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

> ### O candidato a release existe, pela primeira vez
>
> Até hoje todo artefato que a crew gateou saiu de **branch de trabalho**: o `BUILD_INFO` versionado
> dizia `Build canonico: NAO`, branch `feat/021-…`, commit `3ecea9c`. Agora:
>
> ```
> Artefato        : Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe   (489,05 MB)
> SHA-256         : F7BB8AAA9C25828B78EB71FC5A0E54AA73F8580EA653D330DA4BFCC200A6C74D
> Commit          : 374c0f50699187c14aaaa68f78d80dfc2d7e51e8   (== HEAD da develop)
> Branch          : develop
> Build canonico  : SIM
> ```
>
> **O artefato canônico é o que passa**, e não só a branch de onde veio: instalado, ele devolve
> `INTEGRIDADE=OK`, contagem **exata** do manifesto, e **`12 PASS · 0 FAIL · 1 N/E`**.
>
> **Duas coisas que o despacho pedia e eu NÃO pude entregar como escritas** — as duas viram relato,
> não conserto: o **plugin REURB não está embarcado** (§5.1), e o **`A02` reprova sob carga** (§6).

---

## 1. Pré-condição — conferida por nós, não herdada

O despacho exige confirmar que **não existe QGIS 3.44.13 instalado** antes de extrair: a extração
abre transação do Windows Installer contra o **mesmo ProductCode** do QGIS de sistema, e foi essa
operação que desinstalou o QGIS da bancada durante o `#019`.

| verificação | resultado (**medido**) |
|---|---|
| `QGIS*` em `C:\Program Files` e `Program Files (x86)` | **nenhum diretório** |
| entradas `QGIS` na ARP — `HKLM` 64, `HKLM` 32 (`WOW6432Node`) e `HKCU` | **nenhuma** |
| ProductCode `{740D7A65-CBA3-1014-A0B5-B03A9B7608F5}` registrado | **não** |
| processos `qgis-ltr-bin` / `qgis-bin` | **0** |

Só depois disso o build rodou.

---

## 2. O build

Rodado como `installer\build.ps1` **sem argumentos** — sem `-ExpectedBranch` (exige `develop`) e
**sem** `-ReusarArvore`: o canônico **sempre remonta** a árvore a partir do payload conferido.

Todas as guardas passaram, **na ordem em que reprovariam**:

```
OK  branch 'develop', arvore limpa
OK  ProductVersion 0.3.0 / QGIS embarcado 3.44.13
OK  launcher e .iss concordam em QGIS 3.44.13
OK  versao do produto 0.3.0 concorda nas tres fontes            (D9)
OK  payload conferido (42E2F1A6...44EB4)
OK  arvore: 37337 arquivos / 2,224 GB
OK  manifesto de integridade gerado e conferido contra a arvore

  #019 - guarda de integridade do launcher       6 de 6 casos passaram
  #022 - guarda estatica do tema                 5 de 5 assercoes passaram

OK  Inno Setup 7.1.0
OK  Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe (489.05 MB)
```

> A **guarda estática do tema** (`exit 7`), que o `#022` acabou de instalar, rodou pela primeira vez
> dentro de um build canônico. Passou.

---

## 3. `E.5` — o SHA-256, recalculado nesta máquina

Transcrever o valor do `BUILD_INFO` e compará-lo com ele mesmo não prova nada. O hash foi
**calculado sobre o `.exe`**:

```powershell
Get-FileHash .\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe -Algorithm SHA256
```

| | |
|---|---|
| calculado agora | `F7BB8AAA9C25828B78EB71FC5A0E54AA73F8580EA653D330DA4BFCC200A6C74D` |
| gravado no `BUILD_INFO` | `F7BB8AAA9C25828B78EB71FC5A0E54AA73F8580EA653D330DA4BFCC200A6C74D` |
| **batem** | **sim** |
| tamanho | **512.804.117 bytes** (489,05 MB) |

**Como conferir na VM** (`PowerShell 5.1`, sem nada instalado):

```powershell
Get-FileHash .\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe -Algorithm SHA256
```

---

## 4. O artefato canônico instalado — e o que ele devolve

O aceite e a guarda rodaram contra **este** artefato, não contra a branch: o `.exe` foi instalado, e
o harness sobe a árvore do produto instalado.

| | **medido** |
|---|---|
| instalar (sobre a instalação anterior) | `exit 0`, **130,8 s** |
| árvore instalada | **37.337** arquivos |
| manifesto | **37.337** — diferença **0** |
| guarda do próprio produto (`IMAN_TERRA_CHECK_ONLY=1`) | `exit 0`, **`INTEGRIDADE=OK`** |
| procedência do QGIS (`E.1`) | `tudo_dentro=True`, `caminhos_em_program_files=[]` |
| **aceite, 1ª execução** | **`12 PASS · 0 FAIL · 1 N/E`** |
| **aceite, 2ª execução** (`A07b`) | **`1 PASS · 0 FAIL`** |
| guarda estática do tema | **5 de 5** |

```
A01=PASS A02=PASS A03=PASS A04=PASS A05=PASS A06=PASS A07=PASS
A08=PASS A09=PASS A10=PASS A11=PASS A12=PASS   M-D11=N/E   A07b=PASS
```

`A02` e `A04` **explicitamente verdes** — com a ressalva medida da §6. O único `N/E` é o `M-D11`,
bloqueado em A1 desde a `#018`.

**Marca, no artefato canônico:** título `Projeto sem título - IMAN Terra`; censo de janelas
**7 janelas de topo, 0 com o sufixo do QGIS**.

Evidência: `evidencia/aceite.json`, `evidencia/aceite-segunda.json`,
`evidencia/BUILD_INFO-374c0f5.txt`.

---

## 5. Nota de release embrionária — o que entra pela primeira vez

Este é o primeiro artefato canônico, então **tudo** abaixo nunca tinha existido num candidato a
release. Por fatia:

| fatia | o que entra |
|---|---|
| **`#019`** | **o QGIS vive DENTRO do produto** (`{app}\qgis`, via A1): um produto, um instalador, **sem elevação**. Não exige QGIS instalado, não toca `Program Files`, não escreve no registro. **Guarda de integridade** no launcher: manifesto divergente ⇒ o produto **não abre** (uma cópia truncada devolveria coordenada errada em silêncio). |
| **`#020`** | **os avisos de licença corrigidos** — `LICENSE`, `THIRD_PARTY_NOTICES.md` e o inventário dos 159 componentes embarcados. **Nunca tinham sido compilados.** |
| **`#021`** | **o instalador sem laço (`DB-22`)**: `[InstallDelete]` limpa `{app}\qgis` antes de copiar, então "reinstalar" virou instrução verdadeira — inclusive sobre árvore em que alguém acrescentou arquivos. |
| **`#022`** | **título** `— QGIS [iman-distro]` → `- IMAN Terra`; **raio 2px** em toda a UI; **barra de menus densa** (folga por item 24,5 px → 8,5 px). |
| **arte** | o **splash oficial** (`IMAN Terra.cdr` → `splash-iman-terra.svg`, MD5 `32a43bb2b8babae2d0868b89f27cfbe7`), no splash nativo de boot, no banner da home e no wizard do instalador. |

### 5.1 ⚠ Uma linha do despacho que NÃO se confirma: o plugin REURB

O despacho pede que a nota de release diga *"plugin REURB embarcado do `#019`"*. **Ele não está
embarcado.** Medido no produto instalado a partir deste artefato:

| onde | o que existe |
|---|---|
| `profile-template\iman-distro\python\plugins` | **`iman_brand`**, e só |
| `qgis\apps\qgis-ltr\python\plugins` | `db_manager`, `grassprovider`, `MetaSearch`, `processing` — **os de estoque do QGIS** |
| busca por nome `*reurb*` em todo `{app}` | **nenhum resultado** |
| `git ls-files \| grep -i reurb` | **nenhum arquivo rastreado** |

O `#019` foi *"o QGIS passa a viver dentro do IMAN Terra"* — não o bundle do REURB. O bundle
continua sendo o **STOP-AND-FLAG faseado de `D-IMAN-025`** (registrado em
`.memory/project_iman_qgis_distro.md` e no protocolo da crew: *"bundlar o plugin REURB na distro
fica para fatia futura"*).

**Não escrevi essa linha na nota de release.** É a classe do `P0.8` que o próprio arquiteto invocou
no `#022`: *procedência se declara pelo que o sistema mostra, não pelo nome que a gente lembra* — e
uma nota de release que promete um plugin ausente é a pior versão desse erro, porque o `BL-7` vai
apoiar-se nela.

*(Nota lateral: o item "procedência do plugin REURB no `BUILD_INFO`" que o `#022` deixou para fatia
posterior também perde objeto enquanto não houver plugin a proceder.)*

---

## 6. ⚠ ACHADO — o `A02` reprova sob carga; o conserto do `#022` estreitou a janela, não a fechou

**Correção de uma afirmação minha.** O laudo do `#022` diz que o conserto do piso do campo de
coordenadas deixou o `A02` determinístico, com "três rodadas consecutivas verdes". As três rodadas
aconteceram — mas a conclusão foi longe demais.

**Medido hoje, contra este artefato:**

| condição | duração da rodada | `A02` | `min` / `max` / útil |
|---|---|---|---|
| logo após um build de ~16 min **e** uma instalação de 130 s | **57 s** | **`FAIL`** | `108` / `24` / **`92`** para 104 |
| bancada quieta — rodada 1 | 40,3 s | `PASS` | `122` / `236` / `106` |
| bancada quieta — rodada 2 | 40,3 s | `PASS` | `122` / `236` / `106` |
| bancada quieta — rodada 3 | 40,3 s | `PASS` | `122` / `236` / `106` |
| bancada quieta — rodada 4 | 41,3 s | `PASS` | `122` / `236` / `106` |

**4 de 4 verdes com a máquina quieta; 1 vermelho com a máquina carregada** — e a assinatura do
vermelho é **exatamente** a do `D2`: o piso sai `108 px` em vez de `122 px` porque o *cromo* foi
medido com o widget ainda **despolido**.

**Por quê:** o `iman_startup.py` reaplica o tema em 800/1500/2500/**4000** ms; o `#022` moveu a
segunda passada do plugin para **4600 ms**. Sob carga pesada, 600 ms depois da última reaplicação
**ainda não bastam**. O conserto reduziu a frequência; não eliminou a corrida.

**Quem recebe isso é o usuário de máquina lenta**, com o campo de coordenadas cabendo 16 de 19
caracteres da coordenada.

**NÃO consertei aqui**, e é deliberado: o despacho diz *"se algo precisar mudar para o build passar,
pare e relate: vira fatia, não conserto no meio do build"*. Este despacho é operacional e **nenhum
arquivo de aplicação mudou**.

**A forma do conserto, para quando houver briefing** — trocar o *tempo* por um *evento*: reagir ao
`QEvent.PolishRequest` / `StyleChange` do próprio campo, ou recalcular o piso dentro do
`_ContemLargura` quando o cromo medido mudar, em vez de confiar num instante fixo. Enquanto for
temporizador, é aposta contra a carga da máquina.

> **Isto não invalida o artefato canônico.** É um defeito de arranque da camada de marca, presente
> igualmente na branch e no canônico, e anterior a este despacho.

---

## 7. O que este despacho NÃO fez (`P0.7`)

- **Nenhum** arquivo de aplicação mudou: arte, QSS, plugin, instalador e asserções intactos.
- **Não** "consertei" o `v1.0` nem o `CAUCAIA` do splash — arte arbitrada, emenda de 2026-09-09.
- **Não** abri PR — este é o caso da exceção aprovada.
- **Não** toquei em `%LOCALAPPDATA%\Programs\IMAN Terra.SOBRAS-GATE` (**conferido: intacta**).
- **`BL-7` em VM limpa** continua pendente — esta é a bancada do dev. É o próximo passo natural, e
  agora ele tem, pela primeira vez, um artefato **rastreável a um commit de `develop`** para levar.

---

## 8. Sobre o commit direto na `develop`

O `installer/dist/BUILD_INFO.txt` foi commitado direto na `develop` (`abab05c`) — a **exceção**
aprovada pelo sponsor em 2026-09-09 ao `ship = abrir PR`: *um arquivo, um caminho, uma ocasião*.
Vale o `D-IMAN-032` integral: **quem compila é quem commita**, porque o Inno grava `mtime` e o git
não o preserva.

**O build sujou exatamente esse arquivo** — `git status` acusou só ele, e só ele entrou.

> **Este laudo é um segundo commit na `develop`.** Ele não é subproduto do build: é o entregável 5
> do próprio despacho, que ao mesmo tempo proíbe abrir PR. Fica declarado para o arquiteto corrigir
> a convenção se a intenção era outra.
