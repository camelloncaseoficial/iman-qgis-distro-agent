# `#017` — BASELINE VERMELHA: a primeira execução do aceite de marca

**Materializa:** `D-IMAN-033` · **Executado em:** 2026-09-07 · branch `feat/017-aceite-marca`
(de `develop` = `ce2e53e`) · **Bancada:** Windows 11 Pro 10.0.26200, QGIS **3.44.13-Solothurn**
instalado, perfil `iman-distro` reconstruído do zero.

> **Regra de ouro (`BL-7`):** aqui está o que **aconteceu**. Onde não houve medição, está escrito
> **`N/E`** — nunca `PASS`.

---

## VEREDITO

> ### `13 asserções · 10 FAIL · 2 PASS · 1 N/E` — **a rodada é vermelha, como tinha de ser**
>
> **Cada um dos 10 `FAIL` aponta um defeito da lista do sponsor**, com número medido no widget vivo
> ou no pixel. Nenhum `FAIL` é ruído de harness: o baseline foi validado antes de asserir e a
> camada de marca subiu inteira (perfil certo, plugin vivo, QSS anexado, home instalada).
>
> **Cobertura honesta: 10 dos 12 defeitos têm asserção que reprova.** As duas exceções estão
> declaradas em §5 — **`D7` não foi reproduzido** em 7 estados observados, e **`D11` não é
> observável por automação** de dentro do processo. Nenhum dos dois está marcado como resolvido.
>
> **Achado novo:** o `D3`, que o briefing registrava como *"reportado pelo sponsor, ainda não
> reproduzido por ninguém"*, **foi reproduzido e medido** — ver §3.3. É a primeira vez.

---

## 0. Legenda (`E.6`)

| marca | significa |
|---|---|
| **`PASS`** / **`FAIL`** | **medido** nesta bancada, com número no relatório e evidência em `evidencia/` |
| **`N/E`** | **não medido** — nomeado, com o motivo e o passo manual proposto |
| `RELATADO` | vem do sponsor, não de execução nossa. Um defeito `RELATADO` que a asserção **não** reproduz continua `RELATADO` — não vira "resolvido" |

**Placar em `n de N com evidência`: 13 de 13 asserções executadas com evidência citável.**
Toda saída bruta está em `evidencia/aceite.json` e `evidencia/aceite-segunda.json`.

---

## 1. `E.1` — o baseline foi validado ANTES de asserir

Um aceite que roda com a camada de marca fora do ar não mede o produto: mede o QGIS pelado, e
devolveria *"nenhum defeito"* com o build quebrado. Aqui isso é **aborto**, não aviso — o
`acceptance_probe.py` grava `abortado: true` e **não emite asserção nenhuma** se qualquer condição
abaixo falhar.

| condição | critério | medido |
|---|---|---|
| perfil em uso | contém `iman-distro` | `…\_aceite017\perfil\profiles\iman-distro\` ✔ |
| plugin de marca | carregado e instanciado | `ImanBrandPlugin`, `mode = central` ✔ |
| QSS institucional | anexado à janela, com a marca `/* IMAN-THEME */` | **8171 bytes**, marca presente ✔ |
| home | `ImanHome` instalada no miolo | presente ✔ |
| janela assentou | ≥ 1 dock visível | **2** (`Camadas`, `Navegador`) ✔ |
| `iman_startup.py` | o **de verdade**, executado pela sonda | `ok` ✔ |

**`baseline.valido = true`.** Só depois disso as asserções rodaram.

> **Por que este passo existe.** Este repo já perdeu uma rodada por baseline degenerado
> (2026-07-30, `BL-3a` inconclusivo nos dois sentidos), e no `#016` um `FAIL` de `M8` acabou sendo
> defeito do próprio instrumento. Baseline validado é a diferença entre laudo e opinião.

---

## 2. Como o alvo foi renderizado (`V.1`, `V.4`)

Nada de mock, nada de leitura de `.qss`:

- **produto real** — `C:\Program Files\QGIS 3.44.13\bin\qgis-ltr-bin.exe`;
- **perfil `iman-distro` reconstruído do zero** a cada rodada, copiado de
  `app/profile-template/iman-distro` (12 arquivos) — perfil reaproveitado carregaria estado da
  rodada anterior e faria o aceite medir a bancada, não o build;
- **`iman_startup.py` de verdade**, executado pela sonda antes de qualquer medição;
- invocação **idêntica à do launcher** (`app/launcher/IMAN-Terra.bat`): `--profiles-path`,
  `--profile iman-distro`, `--noversioncheck`, **sem `--project`** — o launcher declara isso
  explicitamente: *"SEM `--project`: abrir mostra a HOME de boas-vindas no miolo"*;
- **`BL-3`**: tudo em `%LOCALAPPDATA%\InstitutoIMAN\_aceite017\`. O orquestrador **recusa rodar** se
  o destino cair em `%ProgramFiles%` ou `%APPDATA%\QGIS`. Nada foi escrito em nenhum dos dois.

**Fotos pelo lado do Qt** (`widget.grab()`), não por captura de tela — no `#016` a captura por tela
fotografou a janela de outro aplicativo que estava em primeiro plano.

---

## 3. As 13 asserções, com o número medido

Cada asserção carrega `se_quebrado` no JSON: a resposta a *"o que ela devolve COM o defeito
presente?"* (`C.2`). Onde a resposta não mudaria, a asserção foi **reescrita** — três foram, e §4
conta quais.

### 3.1 `A01` → `D1` · botão de fechar dos painéis — **FAIL**

**Critério:** todo dock visível tem botão de fechar visível, habilitado, **com ícone que desenha
pixel**, e com altura ≥ 60 % da do botão de flutuar ao lado (o irmão não tocado pelo QSS é a régua).

| dock | visível | habilitado | ícone nulo | **pixels de tinta** | altura fechar | altura flutuar | proporção |
|---|---|---|---|---|---|---|---|
| Camadas | sim | sim | **sim** | **0** de 80 | **4 px** | 15 px | **0,267** |
| Navegador | sim | sim | **sim** | **0** de 80 | **4 px** | 15 px | **0,267** |

**O botão existe, está visível e habilitado — e desenha zero pixel.** É um alvo de clique invisível,
pior que ausente. Uma asserção que perguntasse *"o botão existe?"* passaria com o defeito na tela.

Evidência: `evidencia/shots/A01-dock-titulo.png` (o botão de flutuar aparece; o de fechar, não).

### 3.2 `A02` → `D2` · campo de coordenadas — **FAIL**

**Critério:** o campo cabe a coordenada canônica do produto inteira — `555519,9  9585490,5`,
19 caracteres em `EPSG:31984`.

| grandeza | medido |
|---|---|
| largura do widget | **24 px** — e `minimumWidth == maximumWidth == 24`, **largura fixa** |
| `sizeHint()` do próprio widget | 107 px |
| **largura útil para texto**, já descontando o que o QSS come | **6 px** |
| largura necessária para a coordenada canônica | **104 px** |
| **faltam** | **98 px** |
| **caracteres que cabem** | **1** de 19 |

O QGIS dimensiona o campo pela métrica da fonte e **fixa** a largura; o `padding: 2px 8px` mais a
borda do QSS consomem 18 dos 24 px. Sobram **6 px** — um caractere. O relato do sponsor
(*"mal cabem 2 dígitos"*) era **otimista**.

Evidência: `evidencia/shots/A02-zoom-coordenadas.png`.

### 3.3 `A03` → `D3` · alternância coordenada/extensão — **FAIL** ⭐ **primeira reprodução**

O briefing registrava o `D3` como *"reportado pelo sponsor, ainda não reproduzido por ninguém"*.
**Foi reproduzido.**

**Critério:** depois de acionar o botão ao lado das coordenadas, o rodapé continua desenhando, o
campo continua visível, e a largura do campo não passa de 3× a de antes.

| | antes | depois de um clique |
|---|---|---|
| largura do campo | 24 px | **7 464 px** (311×) |
| largura da janela principal | 1 020 px | **8 334 px** |
| largura útil da tela | 1 536 px | — |
| tamanho do texto no campo | 0 | **1 245 caracteres** |
| início do texto | — | `179769313486231570814527423731704356798070567525844996598917…` |

O botão troca a exibição para a **extensão do mapa**. Sem projeto e sem camadas, a extensão do QGIS
vem em `DBL_MAX` (`1,797…e308`), quatro vezes. O campo — que o QGIS redimensiona pela métrica do
texto — vira **7 464 px**, e **arrasta a janela principal para 8 334 px**, muito além dos 1 536 px
de tela. Tudo o que estava à direita no rodapé sai da tela: é o *"rodapé fica branco"* do relato.

> **Nota de método:** o `A03` roda **por último** de propósito. Na primeira versão ele rodava no
> meio e levou a janela de 1 001 para 10 413 px, contaminando todas as asserções seguintes — que
> mediram uma janela de 10 mil pixels. O achado só apareceu porque a foto de `A05` saiu com 10 413
> px de largura.

Evidência: `evidencia/shots/A03-rodape-antes.png` e `A03-rodape-depois.png`.

### 3.4 `A04` → `D4` · títulos de painel cortados — **FAIL**

**Critério:** a altura da **tinta** do título renderizado é ≥ 85 % da altura que a mesma fonte
produz sem corte, **e** a tinta não termina numa linha ainda densa (corte reto).

| dock | altura da tinta | altura sem corte (oráculo) | proporção | densidade da última linha / máxima | corte reto |
|---|---|---|---|---|---|
| Camadas | 7 px | 8 px | 0,875 | **33 / 39 = 0,846** | **sim** |
| Navegador | 7 px | 10 px | **0,700** | **48 / 52 = 0,923** | **sim** |

O sinal decisivo é o segundo. Texto renderizado inteiro **afina** perto da linha de base; texto
cortado **termina numa linha ainda cheia**. Aqui a última linha com tinta tem 85–92 % da densidade
máxima: o corte é reto.

Evidência: `evidencia/shots/A04-zoom-titulo-cortado.png` — "Camadas" com a metade de baixo dos
glifos ausente.

### 3.5 `A05` → `D5` · título da janela — **FAIL**

**Critério:** abrir o projeto `X` faz o título **conter `X`**; criar um projeto novo **muda** o
título.

| momento | título da janela |
|---|---|
| logo após o projeto ser gravado (título posto pelo QGIS) | **`spike017-projeto-alfa — QGIS`** |
| **depois de abrir o projeto** (`iface.addProject`) | `IMAN Terra — powered by QGIS` |
| depois de criar projeto novo | `IMAN Terra — powered by QGIS` |

`título contém o nome do projeto` = **não** · `título mudou ao criar novo` = **não**.

> A linha do meio é a mais reveladora: **o QGIS tinha escrito o nome do projeto, e a camada de marca
> apagou.** Não é "a marca não acrescenta o nome" — é a marca **sobrescrevendo** informação de
> trabalho do usuário, de duas fontes independentes (`iman_startup.py:145`, 5 aplicações até 4 s, e
> `iman_brand.py::_apply_title`, a cada `projectRead`/`newProjectCreated`).

### 3.6 `A06` → `D6` · "Novo projeto" parece inerte — **FAIL**

**Critério:** depois de criar um projeto novo, o miolo mostra o **canvas**.

Medido: página no miolo após novo projeto = **`ImanHome`** (índice 1 do stack). Esperado: a página
do canvas do QGIS. `_on_new_project` → `_show_home()` repõe a home por cima do projeto recém-criado
— o comando roda, e a tela não muda.

Evidência: `evidencia/shots/A06-apos-novo-projeto.png`.

### 3.7 `A07` / `A07b` → `D7` · a home some depois do 1º uso — **PASS, defeito NÃO reproduzido**

Ver §5.1. **Não conte esta linha como defeito resolvido.**

### 3.8 `A08` → `D8` · a home é maquete — **FAIL**

**Critério:** nenhuma string das constantes `RECENTS`/`TEMPLATES`/`CHIPS` de `dashboard.py` alcança
a tela; e nenhum widget se pinta como clicável (regra `:hover` própria) sem ser clicável de verdade.

| grandeza | medido |
|---|---|
| strings inventadas no código | 20 |
| **strings inventadas que alcançam a tela** | **20 de 20** |
| amostra | `REURB-S — Núcleo Alto da Boa Vista`, `Cadastro territorial urbano — Juazeiro do Norte`, `Parcelamento do solo — Quixadá`, `Perímetro & confrontações — Crateús`, `Planta de parcelamento`, `Memorial descritivo`, `Base cartográfica municipal`, `Confrontações & vértices`, `Camadas vetoriais`, `Documentação REURB`, `GPS/GNSS`, `Complementos IMAN` |
| **widgets com falso afordance** | **10** — 4 `QLabel` de "projetos recentes" + 6 `QFrame` de "modelos de projeto" |
| widgets clicáveis de verdade | 4 (os quick-actions, esses funcionam) |

Quatro projetos que não existem, apresentados como "Projetos recentes" **com caminho de arquivo e
data** (`Hoje`, `Ontem`, `3 dias`, `1 sem`). Os dez widgets contados têm regra `:hover` no próprio
stylesheet — **pintam-se como clicáveis** — e não são botão nem têm ninguém ouvindo `clicked`.

> **Nota de método.** A 1ª versão desta asserção comparava `QLabel.text()` por igualdade e contou
> **6 de 20**, com `0` cartões mortos. Os quatro "projetos recentes" vivem num **único `QLabel` de
> rich text** com nome, caminho e data dentro do HTML — igualdade não acha nenhum. A versão atual
> limpa a marcação e busca por substring, e mede falso afordance pela regra `:hover`, não por
> `ClickableFrame`. Passou de 6 para 20 e de 0 para 10.

Evidência: `evidencia/shots/A08-home.png`.

### 3.9 `A09` → `D9` · a versão mente — **FAIL**

**Critério:** a versão **exibida na home** é a mesma que o instalador entrega.

| fonte | valor |
|---|---|
| exibida na home | `0.1.0` |
| `brand.py` | `0.1.0` |
| `metadata.txt` | `0.1.0` |
| **`.iss ProductVersion`** | **`0.3.0`** |

**Duas versões distintas.** O sponsor instalou o `0.3.0` e o produto disse na cara dele que era
`0.1.0`.

### 3.10 `A10` → `D10` · o "Sobre" está escondido — **FAIL**

**Critério:** o menu `Ajuda` contém uma ação "Sobre o IMAN Terra"; o Sobre nativo do QGIS continua
lá (`BL-1`).

- ações no menu `Ajuda`: 16 — **`Sobre` do QGIS presente** ✔ (`BL-1` honrado)
- **`Sobre o IMAN Terra` no `Ajuda`: nenhuma**
- onde a ação está hoje: **`Complementos > IMAN Terra > Sobre o IMAN Terra`** — três níveis

A ação existe e funciona. Uma asserção do tipo *"a ação Sobre existe"* passaria com o defeito
presente, porque ela existe mesmo — só não onde se procura.

Evidência: `evidencia/shots/A10-menubar.png`.

### 3.11 `A11` → `D11` (parcial) · ícone da janela — **PASS** · `M-D11` — **N/E**

**Critério do `A11`:** o ícone **da janela** é o emblema IMAN, não o do QGIS.

| grandeza | medido |
|---|---|
| ícone da janela nulo | não |
| tamanhos disponíveis | 512×512 |
| **semelhança com o logo do QGIS** | **0,091** (9 %) — não é o logo do QGIS |
| `AppUserModelID` do processo | `InstitutoIMAN.IMANTerra.Distro.1` — **está definido** |

**Este `PASS` não cobre o `D11`.** Ver §5.2.

### 3.12 `A12` → `D12` · tema de ícones — **FAIL**

**Critério:** nenhum widget visível da chrome exibe o logo do QGIS, **e** o tema de ícones em uso é
um tema próprio instalado no `userThemesFolder` do perfil.

| grandeza | medido |
|---|---|
| widgets visíveis exibindo o logo do QGIS | **0** (ver limite abaixo) |
| **tema de ícones em uso** | **`default`** — o do QGIS |
| `userThemesFolder` | `…\perfil\profiles\iman-distro\themes` — **dentro do perfil**, como o `BL-3` exige |
| **temas instalados no perfil** | **nenhum** |
| tema é próprio do produto | **não** |

**Limite declarado desta asserção:** a varredura de logo comparou o ícone de cada `QAbstractButton`
e `QLabel` **visível** contra `qgis-icon-16x16.png` (85 % de pixels idênticos a 16×16) e achou
**zero**. Ela **não** varre `QAction` dentro de menus fechados, nem diálogos não abertos, nem o
`QgsWelcomePage` (oculto). O `FAIL` vem da segunda metade do critério, que é a substantiva: **não
existe tema próprio**, logo o produto exibe o conjunto de ícones do QGIS inteiro.

---

## 4. Três asserções foram reescritas por não medirem o defeito

O critério da fatia diz: *se alguma asserção passar num defeito conhecido, a asserção está errada —
reescreva-a*. Aconteceu três vezes, e as três estão registradas em comentário no código, com o
número que a versão anterior devolvia.

### 4.1 `A04` — a `QStyle` mentiu, o pixel não

**1ª versão:** perguntava a `QStyle.SE_DockWidgetTitleBarText` qual era o retângulo do texto.
Resposta: **23 px de altura para uma fonte de 11 px** → "cabe" → **`PASS` com o título cortado na
tela**.

**Por que falhou como asserção:** o corte do `D4` acontece na **pintura**, não no cálculo do
retângulo. Geometria não vê isso.

**2ª versão:** ainda geométrica, comparando contra `fm.tightBoundingRect(titulo)` — que devolveu
**7 px para "Camadas"**, exatamente a altura do texto **já cortado**. **`PASS` de novo.**

**3ª e atual:** desenha o mesmo texto com a mesma fonte num alvo com espaço de sobra e mede a tinta
(oráculo real), **e** analisa o perfil de tinta por linha para detectar corte reto na base. Pega os
dois docks.

> A lição, e ela é o assunto desta fatia: **um oráculo derivado da mesma API que está errada não é
> oráculo.** `tightBoundingRect` e a pintura clipada concordaram — porque a pergunta era a mesma.

### 4.2 `A08` — igualdade de string não acha texto dentro de rich text

**1ª versão:** comparava `QLabel.text()` por **igualdade** contra as constantes. Contou **6 de 20**
strings e **0** cartões mortos — e um `FAIL` fraco, pelos motivos errados.

**Por que falhou como medida:** os quatro "projetos recentes" são **um único `QLabel`** cujo texto é
HTML com nome, caminho e data embutidos. Nenhum bate por igualdade. E o "não clicam" do sponsor não
é sobre `ClickableFrame` sem receptor — é sobre `QLabel`/`QFrame` com regra `:hover` que **parecem**
clicáveis e não são.

**2ª e atual:** limpa a marcação e busca por **substring**; mede falso afordance por **regra
`:hover` sem clique real**. Passou de 6 para **20 de 20**, e de 0 para **10** widgets.

### 4.3 `A07` — medir uma execução só passa no defeito por construção

**1ª versão:** verificava, numa única execução, se a home voltava ao miolo. Voltava. **`PASS`.**
Mas o `D7` é *"a home some **depois do 1º uso**"* — por definição não existe na 1ª execução.

**2ª e atual:** caminhada de **6 estados** na 1ª execução **+** uma **2ª execução** com o perfil
reaproveitado. Continua `PASS` — ver §5.1.

---

## 5. Os dois defeitos sem asserção que os pegue (buraco declarado)

### 5.1 `D7` — não reproduzido em 7 observações

O `A07` caminha o percurso real do usuário; o `A07b` reabre o produto no perfil já usado.

| estado | página no miolo | welcome nativa visível | modo do host |
|---|---|---|---|
| S1 após abrir projeto | canvas (`centralwidget`, índice 0) | não | central |
| S2 após projeto novo | `ImanHome` | não | central |
| S3 após acionar "Início" | `ImanHome` | não | central |
| S4 após abrir o **projeto demo** (caminho real do produto) | canvas (índice 0) | não | central |
| S5 após acionar "Início" de novo | `ImanHome` | não | central |
| S6 após outro projeto novo | `ImanHome` | não | central |
| **2ª execução, perfil reaproveitado** | `ImanHome` | não | central |

`quantas vezes caiu para o fallback de dock` = **0**. A welcome nativa do QGIS **nunca** ficou
visível; "Início" **sempre** trouxe a home.

**Status: `D7` continua `RELATADO`, não reproduzido, não resolvido.** A asserção é sensível por
construção — ela reprova se a welcome nativa aparecer ou se "Início" não trouxer a home — mas a
condição não ocorreu nesta bancada, neste QGIS `3.44.13`, neste percurso.

**O que falta, para o `#018`:** o percurso exato do sponsor. Duas hipóteses que este teste **não**
cobriu, ambas baratas de acrescentar quando houver o dado:
1. `Configurações ▸ Opções ▸ Geral ▸ Abrir projeto ao iniciar = "o mais recente"` — aí `projectRead`
   dispara no boot, antes de `_install_center` (900 ms), e `_on_project_read → _show_canvas()`
   roda com `mode = None`, virando no-op; o que acontece depois não foi medido.
2. Um projeto que faça o QGIS reivindicar o central widget, disparando o `_reassert` para o fallback
   de dock — que aqui ficou em zero.

### 5.2 `D11` — não observável de dentro do processo

O `A11` mede que o **ícone da janela** é o emblema IMAN (9 % de semelhança com o do QGIS) e que o
`AppUserModelID` **está** definido (`InstitutoIMAN.IMANTerra.Distro.1`). **Nada disso prova que a
barra de tarefas mostra o ícone IMAN.**

O shell do Windows lê o `AppUserModelID` **no instante em que a janela nasce**. O
`iman_startup.py` o define via `--code`, que roda **depois**. Medir a variável mais tarde diz que a
chamada aconteceu — não diz o que o shell usou. É o descompasso que **é** o `D11`.

**Passo manual `M-D11`, com critério explícito:**

> 1. Abrir o IMAN Terra pelo atalho do Menu Iniciar (não pelo `qgis-ltr-bin.exe` direto).
> 2. Esperar a janela principal aparecer.
> 3. Olhar o ícone na **barra de tarefas do Windows**.
>
> **PASSA** se o ícone for o emblema IMAN. **FALHA** se for o logo do QGIS.
> Registrar com foto da barra de tarefas, não da janela.

**Status: `N/E`.** Não foi executado nesta rodada — exige um humano olhando a barra de tarefas.

---

## 6. Mapa `asserção → defeito`, fechado

| defeito | asserção | reprova? | número que prova |
|---|---|---|---|
| `D1` botão de fechar sumiu | `A01` | **sim** | 0 pixels de tinta; 4 px contra 15 px do irmão |
| `D2` coordenadas espremidas | `A02` | **sim** | 6 px úteis para 104 px necessários; 1 caractere de 19 |
| `D3` campo estoura, rodapé some | `A03` | **sim** ⭐ | campo 24 → 7 464 px; janela 1 020 → 8 334 px (tela: 1 536) |
| `D4` títulos cortados | `A04` | **sim** | tinta 7 px contra 10 px; última linha com 92 % da densidade máxima |
| `D5` título estático | `A05` | **sim** | `spike017-projeto-alfa — QGIS` → `IMAN Terra — powered by QGIS` |
| `D6` "Novo projeto" inerte | `A06` | **sim** | página no miolo = `ImanHome` |
| `D7` home some após 1º uso | `A07` + `A07b` | **NÃO** | 7 estados, welcome nunca visível — §5.1 |
| `D8` home é maquete | `A08` | **sim** | 20 de 20 strings inventadas na tela; 10 widgets com falso afordance |
| `D9` versão mente | `A09` | **sim** | `0.1.0` exibido contra `0.3.0` entregue |
| `D10` Sobre escondido | `A10` | **sim** | 0 ocorrências no `Ajuda`; está em `Complementos > IMAN Terra >` |
| `D11` ícone na taskbar | `A11` + `M-D11` | **NÃO** | §5.2 — `A11` passa e **não cobre**; `M-D11` é `N/E` |
| `D12` ícones do QGIS na UI | `A12` | **sim** | tema `default`, zero temas no `userThemesFolder` do perfil |

**10 de 12 defeitos reprovados por asserção.**

---

## 7. `V.5` — zero hex órfão

O corpo do `iman-theme.qss` usa **12 cores**; **todas as 12** existem em `brand.py` **e** em
`docs/design-system.md`. **Zero órfãos.** Comando de reprodução em `docs/branding-contract.md` §2.1.

---

## 8. O que esta fatia NÃO fez

1. **Não consertou nenhum dos doze.** É o `#018`. Uma fatia que conserta e testa junto não prova que
   o teste pega o defeito — o vermelho tem de existir antes do verde. Esta é a prova de que o teste
   pega.
2. **Não tocou** instalador, `.iss`, `build.ps1` nem a via A1.
3. **Não escreveu** em `C:\Program Files\QGIS*` nem em `%APPDATA%\QGIS`.
4. **Não fez** o manifesto de integridade da árvore (é entrega do instalador, sai do `#016`).
5. **Não embarcou** o plugin `IMAN REURB` real.
6. **Não mediu** o `M-D11` (exige humano) nem reproduziu o `D7`.
7. **Não cobriu** diálogos (Opções, Gerenciador de Complementos, Propriedades de Camada) — o QSS os
   estiliza via `QPushButton` e `QLineEdit`, e o inventário do contrato marca esses dois como risco
   **médio** justamente por isso. Nenhum diálogo foi aberto nesta rodada.
8. **Não cobriu** temas de sistema em modo escuro, DPI diferente de 100 %, nem outra versão de
   Windows. Uma bancada, um QGIS, uma resolução.

---

## 9. Como reproduzir

```powershell
cd tools\branding-acceptance

# 1a execucao - perfil NOVO, suite completa (13 assercoes)
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1

# 2a execucao - perfil REAPROVEITADO (o unico caminho que poderia ver o D7)
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1 -ReusarPerfil -Fase segunda

# passada de descoberta (nao e o aceite): despeja nomes de objeto do QGIS
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1 -Sonda discover.py
```

Saída em `%LOCALAPPDATA%\InstitutoIMAN\_aceite017\saida\` — `aceite.json`, `aceite-segunda.json` e
`shots\`. A cópia curada desta rodada está em `evidencia/`.

**Limpeza:** `Remove-Item -Recurse -Force "$env:LOCALAPPDATA\InstitutoIMAN\_aceite017"`.

---

**Nada foi instalado, alterado ou removido nesta máquina.** `C:\Program Files\QGIS 3.44.13` e
`%APPDATA%\QGIS` intocados — o orquestrador recusa destino nessas áreas por construção. Nenhum
processo `qgis-ltr-bin` órfão ao final.
