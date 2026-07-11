# Relatório de de-risk — spike #003: title bar frameless + welcome dashboard

**Materializa D-IMAN-026, sob D-IMAN-025/DA-2. Árbitro do BL-5 (fork vs no-fork).**
Este spike **não shippa hack**: produz evidência e decide, por sonda, se a peça segura
**robusta** via perfil/plugin/startup (→ candidata a fatia real, no-fork) ou se **só o
fork resolve** (→ BL-5 proíbe shippar o hack; vira norte de Opção 2 com custo consciente).

## TL;DR — vereditos

| Sonda | Peça | Veredito | Caminho |
|---|---|---|---|
| **A** | Title bar frameless de marca | **FRÁGIL — reprovada no-fork** | **exige Opção 2 (fork)** |
| **B** | Dashboard no lugar do canvas-vazio | **Viável no-fork, com ressalvas** | candidata a fatia real (com guardrails) |
| **C** | Home como **dock** do plugin de marca | **ROBUSTA — aprovada** | no-fork, entregue neste spike |

**Recomendação:** shippar **C** já (onboarding no-fork); promover **B** a fatia real com
guardrails; **não** perseguir **A** no no-fork — ela é o **argumento nº1 do fork**, agora
sustentado por crash reproduzível, não por opinião.

## Método (o gate: caminho REAL, não script solto)

Cada sonda foi exercida pelo **composition root real**: `run-spike.bat <a|b|c>` → detecta o
QGIS LTR → constrói um **perfil ISOLADO do spike** (`%APPDATA%\InstitutoIMAN\IMAN Terra
Spike\…`, publisher-dir próprio; nunca toca o perfil do usuário nem o de produção, BL-3) →
abre o **QGIS LTR de verdade** com a sonda via `--code`/plugin. Cada sonda auto-coleta
evidência em `evidence/` e fecha sozinha; o **exit code** do processo é evidência de
teardown (0 = limpo; `-1073741819` = 0xC0000005 access violation).

- **Ambiente:** QGIS **3.40.8 'Bratislava' LTR**, Qt **5.15.13**, GDAL 3.11.3, Windows 10
  (19045), **tela única @ 125% DPI**.
- **Achado de harness (documentado):** o `--code` do QGIS executa **sem definir `__file__`**;
  o launcher exporta `SPIKE_DIR` e os scripts leem daí.
- **Honestidade do gate:** comportamentos que este harness **não** automatiza (Aero Snap por
  arrasto à borda, Win+Setas, menu de sistema Alt+Espaço, snap-layouts do Win11 no hover do
  botão maximizar, DPI-misto ao mover entre monitores 100%/150%, multi-monitor) estão
  marcados **"requer verificação manual"** — nunca afirmados como testados.

---

## Sonda A — title bar frameless de marca → **FRÁGIL → Opção 2**

**Objetivo:** trocar a moldura nativa do Windows por uma barra de marca IMAN Terra só via
startup/plugin, sem perder arrastar/max/min/restaurar/snap/duplo-clique/menu de sistema/
multi-monitor/DPI. Implementamos o **melhor caminho no-fork** do Qt 5.15: `FramelessWindowHint`
+ barra de marca própria (via `setMenuWidget`, embrulhando o `menuBar` do QGIS) + arrasto
nativo por `QWindow.startSystemMove()` + duplo-clique/botões próprios.

### O que renderizou (parece funcionar)

A barra de marca substituiu a moldura nativa de forma convincente — logo + `IMAN TERRA`,
chip de busca `Ctrl K`, controles min/max/close próprios — e **maximizar respeitou a barra
de tarefas** (1536×824 = `availableGeometry`), sem cobrir o taskbar.
→ `evidence/sonda_a_initial.png`, `evidence/sonda_a_maximized.png`.

### O que quebrou (o que decide)

**O processo crashou** com `Windows fatal exception: access violation`, na descarga de
plugin do QGIS no shutdown (`MetaSearch/plugin.py … unload` ← `qgis/utils.py unloadPlugin`).
Não é glitch cosmético: é **crash do host**.

**Matriz de isolamento (atribuição limpa do crash):**

| Variante | Exit code | Resultado |
|---|---|---|
| Baseline (QGIS puro, abre/fecha) | `0` | limpo |
| **Só** o flag frameless (`FramelessWindowHint`) | `0` | limpo — **mas inerte** (sem barra, sem arrasto, sem controles, sem marca) |
| **Só** o reparent do `menuBar` (`setMenuWidget`) | `-1073741819` (0xC0000005) | **CRASH** |
| Frameless **+** barra de marca (as duas) | 0xC0000005 | **CRASH no unload** |

**Leitura:** o `FramelessWindowHint` em si é sobrevivível, porém é inútil sozinho (janela sem
barra nenhuma). No `QMainWindow` **não há slot suportado acima da barra de menus**; a única
forma no-fork de encaixar uma barra de marca no topo é comandar o `menuBar` via
`setMenuWidget` — e **isso corrompe o grafo de posse de widgets** de que o core/plugins do
QGIS dependem no teardown → access violation. É exatamente a fronteira "só o fork resolve":
num fork você é dono do `QMainWindow` (subclasse C++) ou do `WndProc` nativo do Windows
(`WM_NCCALCSIZE`/`WM_NCHITTEST`) e monta a title bar de forma legítima.

**Além do crash (fragilidades intrínsecas, mesmo que o crash fosse contornado):** perda do
menu de sistema (Alt+Espaço), dos snap-layouts do Win11 (hover do botão maximizar — exige
identidade nativa do botão), e dependência de reimplementar arrasto/redimensionamento/duplo-
clique à mão. Sob DPI 125% (medido) a barra custom renderizou; **DPI-misto e multi-monitor
não foram testáveis** nesta máquina de tela única (requer verificação manual).

**Veredito A: FRÁGIL.** Por BL-5, o hack **não vai para o perfil de produção** — fica aqui,
como evidência. Title bar frameless de marca = **Opção 2 (fork)**.

**Evidência:** `evidence/sonda_a_observations.json`, `sonda_a_initial.png`,
`sonda_a_maximized.png`, `sonda_a_normal.png`; controles `flagonly.*`, `reparentonly.*`,
`control.*`; crash dumps `D:\_scratch\qgis-crash-info-*` / `qgis-python-crash-info-*`.

---

## Sonda B — dashboard no lugar do canvas-vazio → **viável no-fork (com ressalvas)**

**Objetivo:** home/dashboard no centro em vez do canvas vazio, provando o ciclo **abrir
projeto → canvas volta → fechar → home volta** sem tela-fantasma, sem quebrar Locator/docks/
layout. O gate avisa: **se o único caminho for `setCentralWidget` = FAIL** (porque
`setCentralWidget` **deleta** o central antigo — mataria o canvas do QGIS).

### Caminho robusto encontrado (não deleta o canvas)

```python
canvas = win.takeCentralWidget()          # remove SEM deletar (devolve posse)
stack  = QStackedWidget([canvas, home])   # embrulha
win.setCentralWidget(stack)               # agora o stack é o central
stack.setCurrentWidget(home)              # mostra a HOME; troca p/ canvas ao abrir projeto
```

Observado (`evidence/sonda_b_observations.json`, exit **0**):
- O central do QGIS é um **container `QWidget`** (não o `QgsMapCanvas` cru) — `takeCentralWidget`
  o remove sem deletar; o **canvas sobrevive** (`mapCanvas()` continua válido).
- **Ciclo sem tela-fantasma:** home → abrir demo → canvas renderiza (483×254, visível, camada
  OpenStreetMap, CRS do projeto) → novo projeto → home volta limpa. Sem resíduo entre páginas.
  → `sonda_b_home.png`, `sonda_b_canvas.png`, `sonda_b_home_again.png`.
- **Docks/Locator intactos** o tempo todo; **teardown limpo** (sem crash, ao contrário da A).

### Ressalvas (por que "com ressalvas", não "robusto liso")

1. **Contrato de central widget é do QGIS.** Comandamos `setCentralWidget`/`takeCentralWidget`,
   que o `QgisApp` possui. Se algum caminho do QGIS reinvocar `setCentralWidget` (toggle da
   welcome page nativa, outro plugin, versão futura), ele **deletaria nosso `QStackedWidget`**.
   Não observamos isso na sessão, mas é uso não-suportado → exige **guardrail** (reasserção
   defensiva do stack).
2. **Heurística de troca home↔canvas.** Não há sinal limpo do QGIS para "projeto vazio → mostrar
   home". Liga-se em `projectRead → canvas` e `newProjectCreated → home`, mais casos de borda
   (remover todas as camadas etc.) que são palpite.
3. **Welcome page nativa do QGIS** (Projetos recentes/Novidades) fica ocultada atrás da nossa
   home — aceitável, mas são dois conceitos de "boas-vindas" coexistindo.

**Veredito B: viável no-fork, promovível a fatia real COM guardrails.** Não colapsa no FAIL
do `setCentralWidget`-deleta; o caminho `takeCentralWidget`+`QStackedWidget` é mecanicamente
sólido. A versão totalmente nativa (home integrada ao ciclo de projeto e ao slot de welcome
do QGIS) é mais limpa na Opção 2, mas **não é pré-requisito** para entregar valor no-fork.

---

## Sonda C — home como **dock** do plugin de marca → **ROBUSTA (rede de segurança, entregue)**

**Objetivo (deve passar):** a home vira dock do plugin de marca, aberta no startup, com
quick-actions reais. Entrega o onboarding no-fork mesmo que A e B falhem.

Caminho de plugin **padrão** (`addDockWidget`/`removeDockWidget`) — não toca a janela, não
re-flagga, não reparenta o `menuBar`. Observado (`evidence/sonda_c_observations.json`, exit **0**):
- Plugin carregado, **dock visível**, **título de marca** aplicado (`IMAN Terra — powered by
  QGIS`), **sobrevive** a um ciclo de novo projeto, **teardown limpo**.
- A home renderiza fiel ao comp, **re-tematizada** (paleta D-IMAN-026), **REURB/cadastral do
  Ceará** (recentes: Sobral/Juazeiro do Norte/Quixadá/Crateús; modelos cadastrais), **CRS
  EPSG:31984 (SIRGAS 2000 / UTM 24S)**, fonte do sistema, e **créditos do QGIS** no rodapé.
  → `evidence/sonda_c_home.png`, `sonda_c_context.png`.

**Veredito C: ROBUSTA.** É a entrega concreta no-fork deste spike.

> Ressalva honesta de C: como dock, a home é um **painel**, não a área central (isso é a
> Sonda B). Aberta flutuante/ampla no startup, lê como "boas-vindas", mas não substitui o
> canvas. Iconografia dos tiles usa **glifos do sistema como stand-in** — a definitiva vem
> da **fatia #008** (declarado; sem placeholder forjado).

---

## Invariantes (BL-1/BL-2/BL-5) — intactos

- **BL-1/BL-2:** "powered by QGIS" + aviso de independência presentes na home (C) e nos
  metadados do plugin; nada se apresenta como QGIS oficial/endossado. A paleta/UX mudou; os
  **créditos, não**.
- **BL-3:** todas as sondas rodaram em **perfil isolado do spike** (publisher-dir próprio).
- **BL-5:** o hack frágil da Sonda A **não** foi para o perfil de produção — está no spike,
  como evidência. Limite documentado, não contornado.
- **BL-7 não é gate deste spike** (é de release). A verdade aqui é o **caminho real no dev**;
  VM limpa fica para a fatia de entrega.

## O custo do fork (nomeado, para a decisão ser consciente)

Comprar a Opção 2 pela Sonda A significa assumir o **treadmill de rebase de segurança**: um
fork do QGIS LTR precisa reaplicar os patches de branding a cada release de correção do
upstream e **re-validar** — para uma base que se pretende distribuir a **~35 prefeituras**.
O ganho da A (chrome frameless de marca) é estético; o custo é manutenção perpétua + risco de
regressão de segurança. **B e C entregam ~90% do "uau" do redesign (home de onboarding) com
custo de manutenção ~zero.** Recomendação de sequência: **C agora → B com guardrails → A só
se/quando o fork for comprado por outra razão de peso** (splash nativo, ícone do executável,
About, nome interno — os limites já conhecidos), amortizando o custo do fork entre vários itens.

## Fora de escopo (declarado)

Re-derivar a arte oficial na paleta nova (SVG master + símbolo + `.ico`/wizard/splash) =
**fatia de branding própria** (D-IMAN-026); bundle do REURB; iniciar o fork; fechar BL-7.
A promoção da paleta nova para `brand.py`/QSS de produção idem — hoje a produção segue
STALE, declarado em `docs/design-system.md` e `brand.py`.

## Índice de evidência (`evidence/`)

| Arquivo | Sonda | Mostra |
|---|---|---|
| `sonda_a_initial.png` / `_maximized.png` / `_normal.png` | A | title bar frameless renderizada (normal/maximizada/restaurada) |
| `sonda_a_observations.json` | A | matriz de janela (flags, geometria, taskbar, DPI) |
| `control.*` / `flagonly.*` / `reparentonly.*` | A | controles de isolamento do crash (exit codes) |
| `sonda_b_home.png` / `_canvas.png` / `_home_again.png` | B | ciclo home→canvas→home sem tela-fantasma |
| `sonda_b_observations.json` | B | canvas vivo, docks intactos, exit 0 |
| `sonda_c_home.png` / `_context.png` / `_after_newproject.png` | C | home re-tematizada + dock no contexto do QGIS |
| `sonda_c_observations.json` | C | dock carregado/visível, título de marca, exit 0 |
