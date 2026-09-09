# `#022` — O que o usuário lê e vê: título, raio e densidade

**Executado em:** 2026-09-09 · branch `feat/022-titulo-raio-densidade`
**Base de trabalho:** `1b6a919` (ponta da `#021`), hoje ancestral de `develop` — ver §0.
**Bancada:** Windows 11 Pro 10.0.26200 · PowerShell 5.1 · Inno Setup 7.1.0 · **sem QGIS de sistema**

---

## 0. A premissa do briefing: satisfeita DEPOIS, e como a fatia foi feita antes

O briefing diz: *"Depende do PR #24 … Não comecem antes do merge"*, e declara a base como
`develop` **depois** do merge.

**Quando esta fatia foi executada, o PR #24 estava `OPEN`** e `origin/develop` seguia em `ba58d14`.
O `P0.6` proíbe a crew de mergear, então a premissa não estava ao alcance da execução. A saída foi
**empilhar** esta fatia sobre `feat/021-reinstalar-sem-laco-e-aceite`, onde o harness repontado
vive — trabalho **idêntico** ao que sairia de uma `develop` já mergeada, porque a `#021` era
fast-forward sobre `ba58d14`: diferença de ordem de merge, não de conteúdo.

> ### ✅ RESOLVIDO: o `#24` foi mergeado (`develop` = `a8673c3`)
>
> A premissa passou a valer, e o empilhamento deixou de ser necessário. O PR desta fatia foi
> **reapontado para `develop`**, e os 10 commits que ele acrescenta são exatamente os do `#022`
> — conferido com `git diff origin/develop...feat/022-titulo-raio-densidade`: **27 arquivos**,
> nenhum deles do `#021`.
>
> Fica o registro de **como** a fatia foi produzida, que é o que o `E.6` pede: a base de trabalho
> foi `1b6a919`, a ponta da `#021`, e ela hoje é ancestral da `develop`.

---

## 1. Legenda (`E.6`)

| marca | significa |
|---|---|
| **medido** | número obtido nesta bancada, nesta sessão, com evidência em `evidencia/` |
| **relatado** | veio de outra sessão ou de outro observador, identificado como tal |
| **`N/E`** | não medido — nomeado, com o motivo |

---

## VEREDITO

> ### O título deixou de dizer "QGIS", e a régua que deixou isso passar foi refeita
>
> **`Projeto sem título — QGIS [iman-distro]`** virou **`Projeto sem título - IMAN Terra`**.
> Não é só a substituição: o `A05` que dava `PASS` com o defeito na tela foi reescrito para
> asserir **por região**, e agora reprova — **provado nos dois sentidos**, com adulteração inversa
> e com controle de falso positivo.
>
> **Densidade, medida e não impressa:** a folga por item da barra de menus caiu de **24,5 px para
> 8,5 px**; a barra inteira encolheu de **1002 px para 794 px** (−20,8 %).
>
> **Raio:** as 12 declarações de `border-radius` **mais** os 2 cantos específicos da aba estão em
> `2px`, e a **guarda estática** reprova o build (`exit 7`) se qualquer um sair disso — demonstrado.
>
> **Aceite:** `12 PASS · 0 FAIL · 1 N/E`, com `A02` e `A04` verdes, **em três execuções
> consecutivas**.
>
> **Achado do caminho:** o `A02` estava intermitente por um defeito REAL do produto — o piso do
> campo de coordenadas era calculado antes de o tema assentar. Consertado (§6).
>
> **Pergunta do arquiteto, respondida:** são **7 janelas de topo**, e **nenhuma** carrega o sufixo
> do QGIS além da principal. O gancho basta; não há fatia própria a abrir.

---

## 2. `Entrega 1` — o título

### 2.1 A causa, e por que a âncora estava errada

`compoe_titulo` ancorava no **fim da string**:

```python
re.sub(r'QGIS(\s*)$', brand.PRODUCT_NAME + r'\1', titulo)
```

O QGIS acrescenta `" [<perfil>]"` **quando há mais de um perfil na raiz**. Com o colchete depois,
`QGIS` deixa de estar no fim, a regex não casa, e a substituição **nunca acontece**.

O gancho `windowTitleChanged` e a fonte única do `#018` estavam certos. **O defeito era a âncora, e
só ela.**

### 2.2 O conserto, e as quatro exigências do briefing

| # | exigência | como está atendida |
|---|---|---|
| 1 | o sufixo `QGIS` vira `IMAN Terra` mesmo com `[perfil]` depois | a regex casa `[separador] QGIS [ " [perfil]" ]` no fim |
| 2 | o `[<perfil>]` **sai** do título | ele faz parte do trecho substituído |
| 3 | o separador de marca é **hífen**, nunca travessão | `SEPARADOR_DE_MARCA = " - "`, escrito por nós |
| 4 | o nome do projeto continua vindo do QGIS | o prefixo é `titulo[:m.start()]` — sai intocado |

**Item 5 — não realimentar**, por três travas independentes:

1. **a forma da regex**: depois da troca o título termina em `IMAN Terra`, e a regex exige `QGIS` no
   fim — a segunda passada não casa e devolve a mesma string (**verificado em 11 casos**, todos
   idempotentes);
2. `_retitula` só chama `setWindowTitle` **quando o valor muda**;
3. o guarda `_retitulando` continua no lugar.

### 2.3 Os 7 títulos — a pergunta que o arquiteto não tinha medido

> *"Levantem os 7, publiquem a lista crua, e digam quais têm o sufixo e quais não têm."*

**Medido** (`CENSO_DE_JANELAS` em `evidencia/aceite.json`), com o conserto aplicado:

| classe | é a principal? | tem sufixo do QGIS? | título |
|---|---|---|---|
| `QgisApp` | **sim** | **não** | `Caucaia — Setor 3 (QGIS) - IMAN Terra` |
| `QDialog` | não | não | `Configurações de aderência do projeto` |
| `QgsPluginManager` | não | não | `Complementos \| Tudo (0)` |
| `QgsMeasureDialog` | não | não | `Medir` |
| `QgsGpsToolBar` | não | não | `Barra de Ferramenta GPS` |
| `MetaSearchDialog` | não | não | `Metabusca` |
| `QgsCredentialDialog` | não | não | `Entre com as credenciais` |

> **7 janelas de topo, `0` com o sufixo do QGIS.** As outras seis nunca tiveram — são diálogos do
> core com título próprio. O `"IMAN Terra — Boas-vindas (powered by QGIS) — QGIS [iman-distro]"` que
> aparecia na evidência do `#24` **não era uma sétima janela**: era a **mesma** `QgisApp` com o
> projeto demo aberto, cujo *título de projeto* começa com "IMAN Terra".
>
> **Conclusão: `iface.mainWindow()` basta. Não há fatia própria a abrir.**

### 2.4 O `A05` reescrito — critério por região (`V.2`)

O título tem **duas regiões**, e só uma é nossa:

```
   Caucaia — Setor 3 (QGIS)   -   IMAN Terra
   ^ do usuário: nada se assere    ^ nosso: aqui tudo se assere
```

| | asserção | onde |
|---|---|---|
| **a** | termina com o separador de marca + `IMAN Terra`, com **hífen** | título |
| **b** | não há `QGIS` como **autodesignação** | **sufixo** |
| **c** | não há colchete de perfil | **sufixo** |
| **d** | não há travessão nem meia-risca | **sufixo** |
| **e** | com projeto aberto, contém o nome do projeto | título |
| **f** | muda ao criar projeto novo | título |
| **g** | **nada** se assere sobre o prefixo além de (e) | por construção |

**As duas ressalvas do briefing, implementadas literalmente:**

- **`powered by QGIS` não reprova.** É atribuição obrigatória (`BL-1`), definida em
  `brand.PRODUCT_SUBTITLE`. Ela é **removida do texto antes** da busca de (b): nenhuma asserção
  pode reprovar o produto por exibir o crédito que a licença exige.
- **O prefixo é do usuário.** Pode ter travessão, pode ter a palavra `QGIS`, pode ter qualquer
  coisa. (b), (c) e (d) rodam **só no sufixo**.

**Os quatro estados, medidos, com o conserto aplicado:**

| estado | título | (a) | (b) | (c) | (d) |
|---|---|---|---|---|---|
| sem projeto (pouso) | `Projeto sem título - IMAN Terra` | ✅ | ✅ | ✅ | ✅ |
| projeto aberto | `spike017-projeto-alfa - IMAN Terra` | ✅ | ✅ | ✅ | ✅ |
| projeto novo | `Projeto sem título - IMAN Terra` | ✅ | ✅ | ✅ | ✅ |
| modificado sem salvar | `*Projeto sem título - IMAN Terra` | ✅ | ✅ | ✅ | ✅ |
| **CONTROLE — nome hostil** | `Caucaia — Setor 3 (QGIS) - IMAN Terra` | ✅ | ✅ | ✅ | ✅ |

> O título do **pouso** passou a ser capturado **antes** de o `A05` tocar em projeto nenhum. Antes
> ele media o título depois de um projeto já ter sido gravado — o rótulo mentia sobre o que estava
> sendo medido.

### 2.5 Os dois testes do oráculo — os dois obrigatórios, os dois feitos

**(1) Adulteração inversa** — devolvida a âncora `$` original:

```
  referencia: 14 assercoes, 0 FAIL
  D1  -> A01 voltou a FAIL, e so ela
  D5  -> A05 voltou a FAIL, e so ela
  D8  -> A08 voltou a FAIL, e so ela
  3 de 3 reversoes acenderam a assercao certa, e so ela.
```

Com a âncora revertida, os **cinco** estados reprovam, e **os quatro critérios** acendem:

| estado | título com o defeito | (a) | (b) | (c) | (d) |
|---|---|---|---|---|---|
| sem projeto | `Projeto sem título — QGIS [iman-distro]` | ❌ | ❌ | ❌ | ❌ |
| projeto aberto | `spike017-projeto-alfa — QGIS [iman-distro]` | ❌ | ❌ | ❌ | ❌ |
| projeto novo | `Projeto sem título — QGIS [iman-distro]` | ❌ | ❌ | ❌ | ❌ |
| modificado | `*Projeto sem título — QGIS [iman-distro]` | ❌ | ❌ | ❌ | ❌ |
| nome hostil | `Caucaia — Setor 3 (QGIS) — QGIS [iman-distro]` | ❌ | ❌ | ❌ | ❌ |

**(2) Falso positivo** — um projeto chamado literalmente `Caucaia — Setor 3 (QGIS)`, com travessão
**e** a palavra QGIS no nome: **`A05` continua `PASS`**. O prefixo sai intocado, e o produto são
não reprova.

### 2.6 ⚠ O harness precisou de DOIS perfis — e é isso que fecha o buraco

**Achado durante o próprio teste do oráculo.** Na primeira execução da adulteração inversa, com **um
perfil** na raiz do harness, o título revertido saiu `Projeto sem título — IMAN Terra`: o `A05`
acendia por **(a)** e **(d)** — o separador — e **nunca** por (c), porque **o colchete nem chegava a
existir**. A asserção reprovava por um **proxy** do defeito, não pelo defeito.

O QGIS só pendura `" [<perfil>]"` com **mais de um** perfil. A raiz do **produto** tem dois na
própria bancada; a do **teste** tinha um. **O teste era mais estreito que o produto, e a diferença
era exatamente o defeito** — a mesma causa que deixou o `A05` cego desde o `#017`.

O orquestrador passou a montar um **perfil-vizinho vazio**, que não é carregado: existe para o QGIS
**contar** mais de um. Com ele, a reversão reproduz o defeito de campo, e os quatro critérios
acendem (tabela acima).

---

## 3. `Entrega 2` — raio: 2px em tudo

As **12** declarações de `border-radius` valiam `5, 6, 7, 8` px. Todas em **`2px`**.

> ### ⚠ Extensão declarada: mais 2 cantos que a enumeração não alcançava
>
> `QTabBar::tab` define `border-top-left-radius` e `border-top-right-radius` (8px). A contagem de
> `border-radius` **não os alcança** — os nomes de propriedade são outros, e por isso eles não
> estavam nas 12 do briefing. Deixá-los em 8px poria **uma aba arredondada ao lado de um botão de
> 2px**, que é a inconsistência que *"2px para tudo, já é muito"* existe para tirar.
>
> Foram para `2px` também. São **uma linha** para reverter (a regra `QTabBar::tab`), e a guarda os
> assere **em separado** (asserção 5) justamente para a decisão ficar visível em vez de diluída.

---

## 4. `Entrega 3` — densidade da barra de menus

`QMenuBar::item`: `padding: 6px 12px` → **`3px 4px`**.

**Medido** (`evidencia/vitrine-ANTES.json` / `vitrine-DEPOIS.json`), mesma janela maximizada,
mesmos 13 itens:

| | antes | depois | |
|---|---|---|---|
| folga média por item | **24,5 px** | **8,5 px** | −16 px |
| largura ocupada pela barra | **1002 px** | **794 px** | **−208 px (−20,8 %)** |

O sponsor estimou "~24px entre rótulos, com 4px cai para ~8px". **É exatamente isso**, medido.

**A cerca é por seletor, e foi respeitada:**

| seletor | padding | estado |
|---|---|---|
| `QStatusBar` | — | **não tocado** (era o `D2`) — asserção 3 da guarda |
| `QDockWidget::title` | `padding-left/right` só | **não tocado** (era o `D4`) — asserção 4 da guarda |
| `QMenuBar::item` | `3px 4px` | alvo desta entrega |
| `QMenu::item` | `6px 26px 6px 22px` | **fora de escopo** — calha de ícone e marca de seleção |

Nenhum outro `padding`, `margin`, `spacing`, `min-height` ou `min-width` mudou.

---

## 5. `Entrega 4` — a guarda que faltava

`tools/test-tema-qss.ps1`, sem subir o QGIS:

```
  [1] border-radius : 12 declaracoes, 0 fora de 2px
  [2] QMenuBar::item : padding '3px 4px'
  [3] QStatusBar     : 0 declaracao(oes) de padding
  [4] QDockWidget::title : 0 declaracao(oes) de padding vertical
  [5] cantos da aba  : 2 declaracoes, 0 fora de 2px

  5 de 5 asse rcoes passaram.
```

As asserções **3 e 4** valem mais do que a fatia que as criou: transformam a **cerca de prosa** do
briefing em guarda de verdade, reprovando a **regressão do `D2` e do `D4`** em milissegundos.

### 5.1 Prova de que reprova — as duas demonstrações pedidas

```
CASO A - devolve UM raio para 6px (QGroupBox)
  [1] border-radius : 12 declaracoes, 1 fora de 2px
  GUARDA REPROVOU - 1 problema(s):
    app\profile-template\iman-distro\themes\IMAN Terra\style.qss:132  [1] border-radius: 6px  (esperado 2px)
  exit=1

CASO B - devolve padding ao QStatusBar (regressao do D2)
  [3] QStatusBar     : 1 declaracao(oes) de padding
  GUARDA REPROVOU - 1 problema(s):
    app\profile-template\iman-distro\themes\IMAN Terra\style.qss:65  [3] QStatusBar voltou a ter padding (D2): ...
  exit=1
```

**Arquivo e linha**, como pedido.

### 5.2 E o build inteiro reprova junto (`exit 7`)

A guarda entrou no `installer/build.ps1`. **Medido**, com a regressão **commitada** numa branch
descartável (a guarda de árvore suja, `exit 3`, vem antes e impede o teste com a árvore só editada —
o que é o comportamento certo):

```
  BUILD RECUSADO: a guarda estatica do tema REPROVOU
    Teste : tools\test-tema-qss.ps1   (exit 1)
EXIT DO BUILD: 7
```

O build **não chega ao compilador**. Um instalador só sai se o tema estiver como o sponsor arbitrou.

---

## 6. ⚠ Achado do caminho: o `A02` estava intermitente por um defeito REAL

O `A02` reprovou em **2 de 6** rodadas, sempre com a mesma assinatura: largura útil de **92 px**
para os **104 px** que a coordenada canônica precisa, piso em **108 px** onde deviam ser **122 px**.

**Não era flake do teste.** O piso do `D2` sai do *cromo* — o que a borda e o tema comem do widget —
e o cromo só vale se o QSS já estiver aplicado quando se mede. O `iman_startup.py` reaplica o tema em
**800, 1500, 2500 e 4000 ms**; a passada do plugin em **1800 ms** cai **no meio disso**. Numa máquina
lenta ela media o widget **despolido**: cromo saía 2 px em vez de 16, e o piso saía 14 px curto.

**Quem recebia isso era o usuário de máquina lenta**, com o campo de coordenadas espremido — o `D2`
voltando de forma intermitente.

**Conserto:** uma segunda passada em **4600 ms**, depois da última reaplicação do tema. O método
virou **idempotente** — retira o filtro de largura anterior antes de instalar o novo, senão o piso
**velho** continuaria sendo reimposto a cada evento de geometria e o conserto se desfaria sozinho.

**Depois:** três execuções consecutivas com `min=122`, `max=236`, `util=106` para `104` necessários.
`12 PASS · 0 FAIL · 1 N/E` nas três.

---

## 7. `Entrega 5` — a procedência do splash

O documento dizia que a fonte era o `IMAN.cdr`. **Não é** — e o erro tem consequência: o sponsor leu
"IMAN.cdr" e concluiu que a arte nova tinha sido ignorada.

| | |
|---|---|
| `IMAN.cdr` | **2025-06-30**, 7,16 MB — **não é a fonte** |
| fonte real | **`IMAN Terra.cdr`** (2026-09-09 05:03) e **`IMAN Terra.svg`** (05:04) |
| prova | mesmo **MD5** `32a43bb2b8babae2d0868b89f27cfbe7` e mesmos **104.557 bytes** que o `splash-iman-terra.svg` commitado — **recalculado nesta bancada** (`E.5`) |

Corrigido nos **quatro** lugares que *afirmavam* a procedência: `app/assets/README.md`,
`docs/design-system.md`, o laudo do `#021` e a memória do projeto. As linhas que **citam a regra
antiga** ("o `IMAN.cdr`, chegando, prevalece") ficam como estão — são histórico, não afirmação.

**O artefato sempre esteve certo; o registro dele é que estava errado.** É a classe do `P0.8`.

---

## 8. Cerca zero — a arte é arbitrada

O `v1.0 · LTR` e o `VERSÃO INSTITUCIONAL · CAUCAIA LTR` do splash são **entrada arbitrada**
(sponsor, 2026-09-09: *"é para usar as novas imagens as is, sem perguntas"*), **não defeito
pendente**.

- **nenhum** master ou derivado da arte foi tocado nesta fatia;
- **nenhuma** asserção reprova o produto por causa desses dois textos;
- a versão do splash **não** foi "consertada" para casar com o `BUILD_INFO`.

Registrado em `app/assets/README.md` e na memória do projeto.

---

## 9. `V.3` — o teto, declarado e medido

| superfície | alcance | estado |
|---|---|---|
| widget Qt (menu, botão, campo, aba, dock, scrollbar, tooltip) | **QSS alcança** | **2px, entregue** |
| **moldura de janela e de diálogo** | **QSS NÃO alcança** — quem arredonda é o **Windows 11 (DWM)** | **teto, não defeito** |
| o que o QGIS desenha por conta própria no canvas | QSS não alcança | teto |
| strings de dentro do QGIS (diálogos nativos, "Sobre o QGIS", erros do core) | não é o título da janela principal | **teto — upstream, 2,2 GB** |

Evidência do teto: `evidencia/shots/comparacao-4-teto-moldura-nativa.png` — o canto do diálogo, no
build **depois**, ampliado 8×: a curva que sobra é da moldura nativa.

---

## 10. Evidência

| arquivo | o que é |
|---|---|
| `evidencia/aceite.json` · `aceite-segunda.json` | `12 PASS · 0 FAIL · 1 N/E`, com o `A05` reescrito |
| `evidencia/aceite-com-D5-revertido.json` | o `A05` reprovando nos 5 estados, com os 4 critérios |
| `evidencia/adulteracao-inversa.json` | `D1`, `D5`, `D8` — 3 de 3 acenderam a asserção certa |
| `evidencia/vitrine-ANTES.json` · `vitrine-DEPOIS.json` | a medida da densidade da barra de menus |
| `evidencia/shots/ANTES-…png` · `DEPOIS-…png` | a tomada inteira, mesmo enquadramento |
| `evidencia/shots/comparacao-1…4.png` | recortes ampliados: título+barra, raio dos botões, raio do campo, o teto |

---

## 11. Fora de escopo (`P0.7`)

- **A arte** — cerca zero, §8.
- **Varredura de travessão** — é o `#023`, fatia própria. Um diff textual de 96 arquivos aqui
  enterraria o `A05`.
- **Build canônico** — o impasse do `#021` é do arquiteto; não foi tocado.
- **Procedência do plugin REURB no `BUILD_INFO`** — fatia posterior.
- **`CHECKLIST.md` do `BL-7`** · exclusão de pacotes do `#020` · `D11` · espelho de fonte.

---

## 12. Como reproduzir

```powershell
# aceite (exige o produto INSTALADO; monta 2 perfis por desenho)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\branding-acceptance\Invoke-Aceite.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\branding-acceptance\Invoke-Aceite.ps1 -ReusarPerfil -Fase segunda

# o oraculo ainda sabe reprovar? (exige arvore git limpa)
powershell -NoProfile -ExecutionPolicy Bypass -Command "& .\tools\Assert-AdulteracaoInversa.ps1 -Somente D1,D5,D8"

# a guarda estatica do tema
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-tema-qss.ps1

# a vitrine (screenshot do alvo, uma tomada)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Capture-Vitrine.ps1 -Saida .\vitrine.png
```
