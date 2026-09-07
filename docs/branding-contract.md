# Contrato da camada de marca — IMAN Terra

**Materializa:** `D-IMAN-033` (fatia `#017`) · **Emitido:** 2026-09-07
**Não é o design system.** `docs/design-system.md` diz *quais são* as cores, as fontes e os tokens.
Este documento diz **quem manda em cada região da janela** e **qual asserção prova**.

> **Por que existe.** O sponsor abriu o `0.3.0` e achou doze defeitos numa sessão. A causa raiz não
> é nenhum dos doze: é que **não existia critério que dissesse se um build está bom antes de ele
> usá-lo**. O QSS foi escrito à mão sem inventário de widgets — foi assim que uma regra de uma linha
> apagou o botão de fechar de todos os painéis sem ninguém notar. Este contrato é o critério.

---

## Teto honesto (V.3) — o que este contrato NÃO alcança

Declarado no topo, não escondido no rodapé:

| limite | por quê | quando cai |
|---|---|---|
| **Ícone do executável** (`qgis-ltr-bin.exe`) | está compilado no binário | só Opção 2 (fork) — é o `DB-4`, e tem consequência de licença |
| **Nome interno do processo** | idem | Opção 2 |
| **About nativo do QGIS** | diálogo do core | Opção 2 — e **por BL-1 ele fica**, não se remove |
| **Ícones de ação da toolbar** | vêm do tema de ícones do QGIS | o tema próprio **já existe e está ativo** (`#018`/`D12`); falta popular o `icons/` dele — ver §1.7 |
| **Agrupamento na barra de tarefas** | o shell do Windows lê o `AppUserModelID` no instante em que a janela nasce | depende de a identidade ser definida **antes** do processo criar a janela; hoje o startup roda via `--code`, tarde demais (`D11`) |
| **Chrome pixel-idêntica ao comp** | QSS colore, não reestrutura layout | teto já declarado no `#006` |

**O contrato abaixo só fala do que está dentro do alcance.** Onde a asserção não consegue medir, a
linha diz `N/E` e propõe o passo manual — nunca finge cobertura.

---

## 1. As regiões, e quem manda em cada uma

Legenda das asserções: `A01…A12` são executáveis (`tools/branding-acceptance/`); `M-*` são passos
manuais com critério explícito.

### 1.1 Barra de menus (`menubar`)

| o que a marca possui | o que é do QGIS e não se toca | a asserção que prova |
|---|---|---|
| Cor de fundo, cor do texto, realce do item ativo (`QMenuBar`, `QMenuBar::item`) | **Todos os menus nativos e suas ações** — `Projeto`, `Editar`, `Exibir`, `Camada`, `Configurações`, `Complementos`, `Vetor`, `Raster`, `Banco de Dados`, `Web`, `Malha`, `Processamento`, `Ajuda`. A camada de marca **acrescenta**, nunca remove nem renomeia | `A10` (presença do Sobre próprio no `Ajuda`, sem tirar o Sobre nativo) |
| Uma entrada própria em `Complementos ▸ IMAN Terra` | A ordem e o conteúdo dos menus nativos | `A10` |

### 1.2 Barras de ferramentas (`toolbars`)

| a marca possui | do QGIS, não se toca | asserção |
|---|---|---|
| Fundo, espaçamento, separador, estados hover/checked do `QToolButton` | **Os ícones de ação** (baked no core até o tema próprio existir) | `A12` |
| A toolbar própria `ImanTerraToolbar` e o botão `ImanTerraMenuBtn` | As toolbars nativas — o *declutter* apenas **oculta**, e é reversível em `Exibir ▸ Barras de Ferramentas` | `A12` |

### 1.3 Barra de status — **incluindo o campo de coordenadas**

| a marca possui | do QGIS, não se toca | asserção |
|---|---|---|
| Fundo, cor do texto, borda superior, aparência do campo (`QStatusBar QLineEdit`) · **e o piso e o teto de largura do campo** (ver abaixo) | **O texto** que o QGIS escreve no campo, e quando o escreve | `A02` |
| Nada mais | **O botão de alternar coordenada/extensão** e o conteúdo que ele escreve no campo | `A03` |

> **CONTRATO EXPLÍCITO (V.2).** O campo de coordenadas **cabe a coordenada canônica do produto
> inteira** — `555519,9  9585490,5`, 19 caracteres em `EPSG:31984` (SIRGAS 2000 / UTM 24S), que é a
> projeção que o produto declara como padrão. E **continua cabendo depois de acionar o botão ao
> lado**, sem que o campo empurre o resto do rodapé para fora da janela.
>
> Regra derivada: **num widget de largura fixa, `padding` do QSS é subtração.** O QGIS dimensiona o
> campo pela métrica do texto; cada pixel de padding é um pixel a menos de texto visível. Por isso o
> `padding` saiu dessa regra em `#018`.
>
> **Propriedade assumida em `#018`, e é uma exceção deliberada à regra de ouro do §2.** O QGIS
> dimensiona o campo **sem piso e sem teto**: vazio, ele encolhe a 24 px; exibindo a extensão de um
> projeto sem camadas, o texto vem em `DBL_MAX` e ele cresce a milhares de pixels, arrastando a
> janela para fora da tela. A camada de marca — que estilizou o campo — passa a **impor as duas
> pontas**: piso = a coordenada canônica; teto = uma extensão plausível. É mudança de geometria num
> widget do QGIS, feita de propósito, documentada aqui, e reimposta por filtro de evento porque o
> QGIS desfaz os limites a cada troca de texto.

### 1.4 Títulos e botões de painel (`QDockWidget`)

| a marca possui | do QGIS, não se toca | asserção |
|---|---|---|
| Fundo, cor e peso do título (`QDockWidget::title`) | **Os botões da barra de título** — flutuar e **fechar**. São affordances do Qt; a marca colore, não desliga | `A01` |
| — | A altura da barra de título, que o Qt calcula a partir da fonte | `A04` |

> **CONTRATO EXPLÍCITO.** Todo painel visível tem **botão de fechar visível, habilitado e que
> desenha pixel**, com altura comparável à do botão de flutuar ao lado. E o **título é renderizado
> inteiro** — a tinta do texto na tela tem a mesma altura que a mesma fonte produz sem corte.
>
> Regra derivada: **`padding` em `QDockWidget::title` sem a altura da barra acompanhar corta o
> glifo**; e `titlebar-close-icon: none` **não esconde o botão — apaga o ícone dele**, deixando um
> alvo de clique invisível, que é pior que ausente.

### 1.5 Título da janela

| a marca possui | do QGIS, não se toca | asserção |
|---|---|---|
| O **sufixo de marca** — `— IMAN Terra` | **O prefixo de contexto**: o nome do projeto aberto e o marcador de alterações não salvas (`*`). É informação de trabalho do usuário, não superfície de marca | `A05` |

> **CONTRATO EXPLÍCITO.** Abrir o projeto `X` faz o título **conter `X`**; criar um projeto novo
> **muda** o título. A marca compõe com o que o QGIS escreveu — **não sobrescreve**.
>
> **Fonte única obrigatória — e cumprida em `#018`.** Havia **duas**: `iman_startup.py`
> (5 aplicações, até 4 s) e `iman_brand.py::_apply_title` (a cada
> `projectRead`/`newProjectCreated`). As duas cravavam a mesma string estática por cima do que o
> QGIS acabara de compor — o `D5` era **regressão**, não ausência. Sobrou **uma**: o gancho
> `windowTitleChanged` do plugin, que troca só o sufixo, ancorado no fim da string. O
> `iman_startup.py` **não escreve mais título nenhum** e traz um aviso no cabeçalho para não
> reintroduzirem `setWindowTitle` ali.

### 1.6 Ícone de janela e de barra de tarefas

| a marca possui | do QGIS, não se toca | asserção |
|---|---|---|
| O ícone da **janela** (`setWindowIcon`) | O ícone do **arquivo executável** (teto declarado, `DB-4`) | `A11` |
| A identidade de agrupamento (`AppUserModelID`) | — | `M-D11` (manual) |

> **CONTRATO EXPLÍCITO.** O ícone da janela é o emblema IMAN. A **barra de tarefas** também — e essa
> metade **não é observável de dentro do processo**: o shell lê o `AppUserModelID` quando a janela
> nasce, e medir a variável depois não diz o que o shell usou. Ver `M-D11`.

### 1.7 Tema de ícones

| a marca possui | do QGIS, não se toca | asserção |
|---|---|---|
| Um tema de ícones próprio, instalado no **`QgsApplication.userThemesFolder()` do perfil isolado** | O conjunto de ícones do QGIS, que continua no lugar como base | `A12` |

> **CONTRATO EXPLÍCITO e `BL-3` inegociável.** O tema próprio vai para o `userThemesFolder` **do
> perfil** — medido: `<perfil>/themes`. **NUNCA** em `C:\Program Files\QGIS*`; sob o ramo `DB-16`
> escrever lá sobrescreveria o QGIS do próprio usuário.
>
> **Estado em `#018`:** o tema **`IMAN Terra` existe no perfil e está ativo** — o `style.qss` dele é
> o QSS de marca (movido para lá, fonte única, sem cópia). **Limite declarado:** o diretório
> `icons/` do tema ainda está **vazio**. Um tema do QGIS usa `icons/` para sobrescrever a
> iconografia de chrome (setas, fechar, olho, alças) — trocar esses SVGs é o passo seguinte e não
> foi feito aqui: um `close.svg` malfeito reabriria o `D1`.

### 1.8 Home (o miolo)

| a marca possui | do QGIS, não se toca | asserção |
|---|---|---|
| A página `ImanHome` no `QStackedWidget` central | **A página 0 do stack**, que é o container central do QGIS (canvas + welcome nativa). A marca a *empilha*, não a substitui | `A06`, `A07` |
| O conteúdo da home | — | `A08` |

> **CONTRATO EXPLÍCITO — a política do miolo, estado a estado.**
>
> Uma regra, em uma frase: **a home é o pouso; qualquer ação de projeto leva ao canvas; "Início"
> traz a home de volta.** Fora isso, nenhuma outra coisa move o miolo.
>
> | # | estado | o que o miolo mostra | por quê |
> |---|---|---|---|
> | E1 | o produto abre, sem projeto | **home** | é o pouso. O launcher já declara: *"SEM `--project`: abrir mostra a HOME no miolo"* |
> | E2 | um projeto **com conteúdo** é aberto | **canvas** | o usuário quer o mapa, não a recepção |
> | E3 | um projeto **vazio** é aberto | **canvas** | idem — quem abre um projeto pediu para trabalhar |
> | E4 | um projeto é **criado** (`Projeto ▸ Novo`) | **canvas** | o usuário acabou de pedir um projeto; repor a home faz o comando parecer inerte — é o `D6` |
> | E5 | o **projeto demo** é aberto pela home | **canvas** | é E2 |
> | E6 | **"Início"** é acionado | **home** | é a única ação que traz a home de volta, e ela sempre traz |
> | E7 | **2ª execução**, perfil já usado | **E1 ou E2**, pela mesma regra: se o QGIS restaurar um projeto, canvas; se abrir vazio, home | não existe regra especial de "segunda vez" — é isso que o `D7` alega, e o contrato nega |
> | E8 | qualquer estado | a **welcome nativa do QGIS nunca fica visível** | ver as duas recepções é ver dois produtos |
>
> **Determinismo do pouso.** No arranque o QGIS emite eventos de projeto antes de a home existir. A
> política só vale depois que o miolo está montado: os handlers ignoram eventos até o pouso
> acontecer. Sem isso, E1 depende de quem chega primeiro — e "depende" é como o `D7` nasce.
>
> **Zero dado inventado alcança a tela.** Nenhuma string de `RECENTS`/`TEMPLATES`/`CHIPS`
> hardcoded, e nada que se pinte como clicável sem ser. Uma maquete que finge ser produto é pior
> que uma tela vazia — o sponsor abriu quatro projetos que não existem. Lista vazia se mostra
> **vazia, com estado próprio**; nunca preenchida com exemplo.

### 1.9 Sobre

| a marca possui | do QGIS, não se toca | asserção |
|---|---|---|
| Um "Sobre o IMAN Terra" próprio, alcançável no menu **`Ajuda`** | **O `Ajuda ▸ Sobre` nativo do QGIS permanece** — `BL-1`, inegociável | `A10` |

> **CONTRATO EXPLÍCITO.** Os dois convivem no `Ajuda`. O Sobre próprio carrega os créditos do QGIS
> verbatim (`BL-1`) e o aviso de independência (`BL-2`). Estar só num dropdown de toolbar não conta
> como alcançável.

### 1.10 Versão

| a marca possui | do QGIS, não se toca | asserção |
|---|---|---|
| A versão do **produto** (`IMAN Terra`) | A versão do **QGIS**, exibida onde o QGIS a exibe | `A09` |

> **CONTRATO EXPLÍCITO — fonte única (`BL-4`).** A versão exibida na home, no "Sobre", no banner e
> no `metadata.txt` é **a mesma** que o instalador entrega (`ProductVersion` do `.iss`). Hoje há
> **duas** em desacordo: `0.1.0` no código e `0.3.0` no instalador.

---

## 2. Inventário de widgets que o QSS estiliza (item obrigatório)

> **Por que este inventário é obrigatório.** O `D1` existe porque alguém escreveu
> `QDockWidget { titlebar-close-icon: none; }` sem saber o que a regra desligava. Uma regra de QSS
> não atinge "a aparência" — atinge **widgets nomeados**, inclusive os que o QGIS usa para funções
> que não são de marca. Antes de acrescentar regra, ela entra aqui.

`app/profile-template/iman-distro/themes/IMAN Terra/style.qss` — **49 regras, 23 classes Qt**
(medido em 2026-09-07; o arquivo era `QGIS/iman-theme.qss` até o `#018` mover o QSS de marca para
dentro do tema de UI próprio, ver §1.7):

| classe Qt | seletores usados | o que a regra atinge além da cor | risco |
|---|---|---|---|
| `QMenuBar` | `QMenuBar`, `::item`, `::item:selected`, `::item:pressed` | padding do item | baixo |
| `QMenu` | `QMenu`, `::item`, `::item:selected`, `::separator` | padding, raio | baixo |
| `QToolBar` | `QToolBar`, `::separator` | spacing, padding | baixo |
| `QToolButton` | `QToolButton`, `:hover`, `:checked`, `:pressed`, `::menu-button` | borda do botão de menu | **médio** — `::menu-button { border: none }` afeta todo dropdown de toolbar |
| `QStatusBar` | `QStatusBar`, `::item`, ` QLabel`, ` QToolButton`, ` QToolButton:hover`, ` QLineEdit`, ` QComboBox` | ~~`padding: 2px 8px`~~ **removido em `#018`**; resta a borda | era **ALTO — o `D2`** |
| `QDockWidget` | `::title`, `> QWidget` | ~~`titlebar-close-icon: none`~~ e ~~`padding` vertical no `::title`~~ **removidos em `#018`**; resta o recuo horizontal | era **ALTO — o `D1`/`D4`** |
| `QTreeView` `QListView` `QTableView` | base, `::item`, `:hover`, `:selected` | padding e raio do item | baixo |
| `QHeaderView` | `::section` | padding, bordas | baixo |
| `QTabBar` | `::tab`, `:selected`, `:hover` | padding, raio | baixo |
| `QPushButton` | base, `:hover`, `:pressed`, `:default`, `:default:hover`, `:disabled` | padding, raio, borda | **médio** — atinge botões de **todos** os diálogos do QGIS |
| `QLineEdit` `QComboBox` `QSpinBox` `QDoubleSpinBox` `QPlainTextEdit` `QTextEdit` | base + `:focus` | padding em **todo** campo de entrada do QGIS | **médio** — mesma classe de risco do `D2`, em diálogos |
| `QGroupBox` | base, `::title` | margem superior | baixo |
| `QScrollBar` | 8 seletores | largura, margem, `min-height` do handle | baixo |
| `QToolTip` | base | padding, borda | baixo |
| `QLabel` | só dentro de `QStatusBar` | cor | baixo |
| `QWidget` | só em `QDockWidget > QWidget` | fundo | baixo |

**Regra de ouro do inventário:** propriedade que muda **geometria** (`padding`, `margin`, `border`,
`width`, `height`, `min-*`) num widget que **o QGIS dimensionou** é mudança de comportamento
disfarçada de cor. Toda linha marcada **ALTO** ou **médio** acima é exatamente isso.

### 2.1 `V.5` — zero hex órfão

Medido em 2026-09-07: o corpo do QSS usa **12 cores**; **todas as 12** existem em `brand.py` **e** em
`docs/design-system.md`. **Zero órfãos.** Reproduzir:

```bash
python - <<'EOF'
import re, io
qss = re.sub(r'/\*.*?\*/', '', io.open('app/profile-template/iman-distro/themes/IMAN Terra/style.qss',
                                       encoding='utf-8').read(), flags=re.S)
brand = io.open('app/profile-template/iman-distro/python/plugins/iman_brand/brand.py', encoding='utf-8').read()
ds    = io.open('docs/design-system.md', encoding='utf-8').read()
h  = set(x.upper() for x in re.findall(r'#([0-9A-Fa-f]{6})', qss))
bh = set(x.upper() for x in re.findall(r'#([0-9A-Fa-f]{6})', brand))
dh = set(x.upper() for x in re.findall(r'#([0-9A-Fa-f]{6})', ds))
print('orfaos:', sorted((h - bh) | (h - dh)) or 'NENHUM')
EOF
```

---

## 3. Tabela-resumo: região → asserção → defeito

| região | asserção | defeito que ela pega | estado em 2026-09-07 |
|---|---|---|---|
| títulos e botões de dock | `A01` | `D1` botão de fechar apagado | **PASS** |
| títulos e botões de dock | `A04` | `D4` título cortado | **PASS** |
| status bar · coordenadas | `A02` | `D2` campo espremido | **PASS** |
| status bar · alternância | `A03` | `D3` campo estoura, rodapé some | **PASS** |
| título da janela | `A05` | `D5` título estático, duas fontes | **PASS** |
| home | `A06` | `D6` "Novo projeto" parece inerte | **PASS** |
| home | `A07` / `A07b` | `D7` a home some depois do 1º uso | **PASS** |
| home | `A08` | `D8` maquete com dados inventados | **PASS** |
| versão | `A09` | `D9` versão mente | **PASS** |
| Sobre | `A10` | `D10` Sobre escondido | **PASS** |
| ícone de janela/taskbar | `A11` + `M-D11` | `D11` ícone do QGIS na taskbar | **PASS (parcial) + N/E — BLOQUEADO EM A1** |
| tema de ícones | `A12` | `D12` ícones do QGIS na UI | **PASS** |

**Estado em 2026-09-07 (`#018`): 12 asserções PASS, 0 FAIL, 1 N/E.** Onze dos doze defeitos
consertados; o `D11` está **bloqueado na via A1** — não existe conserto honesto enquanto o `.exe`
não for nosso. Ver `docs/verify/018-conserto/BASELINE-VERDE.md`.

**O verde é auditado.** `tools/Assert-AdulteracaoInversa.ps1` reverte cada conserto, um a um, e
exige que a asserção correspondente volte a vermelho — e só ela. Asserção que não acende quando o
defeito volta é asserção morta, e reprova a fatia mesmo com tudo verde. Última execução:
**12 de 12**.

---

## 4. Como rodar o contrato

```powershell
cd tools\branding-acceptance
# 1a execucao - perfil NOVO, suite completa
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1
# 2a execucao - perfil REAPROVEITADO (unico jeito de ver o D7)
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1 -ReusarPerfil -Fase segunda
```

O aceite **aborta** (`baseline.valido = false`) se a camada de marca não tiver subido — perfil
errado, plugin não carregado, QSS não anexado ou home ausente. Um aceite verde sobre um build onde a
marca nunca carregou não é aprovação: é medição do QGIS pelado.

---

## 5. Quando este contrato muda

- Regra nova no QSS → **entra no inventário §2 antes de entrar no arquivo**, com a coluna de risco.
- Região nova da janela → linha nova em §1, com as três colunas e uma asserção.
- Defeito novo achado pelo sponsor → asserção que **reprova** antes de qualquer conserto.
- Teto que cair (ex.: o tema de ícones sair do `D12`) → sai da tabela do topo, vira linha de §1.

**Referências:** `docs/design-system.md` (tokens) · `docs/BRANDING_AND_LICENSE.md` (`BL-1`…`BL-7`) ·
`docs/distro-architecture.md` · `docs/verify/017-aceite-marca/BASELINE-VERMELHA.md` (a rodada que
originou este contrato).
