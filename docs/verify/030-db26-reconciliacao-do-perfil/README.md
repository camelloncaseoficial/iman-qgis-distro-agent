# `#030`: uma atualização chega a quem já instalou (`DB-26`)

**Executado em:** 2026-09-16 · branch `feat/030-db26-atualizacao-chega-a-quem-ja-instalou`
**Base:** `733e129` - **o PR #28 (`#029`) ainda estava ABERTO quando esta fatia começou**, então,
como o briefing manda, ela parte de `733e129` e isso fica declarado aqui e no PR.
**Bancada:** Windows 11 Pro 10.0.26200 · PowerShell 5.1 · sem QGIS de sistema
**Tipo:** fatia de produto + guarda que sabe reprovar.

---

## 0. Legenda (`E.6`)

| marca | significa |
|---|---|
| **medido** | obtido nesta bancada, nesta sessão, com evidência em `evidencia/` |
| **relatado** | veio do briefing ou de outra sessão, identificado como tal |
| **`N/E`** | não exercitado, nomeado, com o motivo |

---

## 1. Passo 0 - a bancada é do sponsor, e está em uso

**Nenhum instalador foi compilado nesta fatia, e nada foi instalado na bancada.** O briefing proíbe
compilar antes do merge do PR #28, e ele continua aberto. **A pergunta de autorização do Passo 0 não
chegou a existir**: sem compilar, não há build de branch para instalar. O que isso deixa em aberto
está na §8.

**O perfil real do sponsor não foi tocado.** Todo estado da guarda roda com **`%APPDATA%`
redirecionado** para a sua pasta dentro do sandbox, só durante a execução do launcher - o launcher
deriva `PROFILES_ROOT` de `%APPDATA%\InstitutoIMAN\IMAN Terra`, então redirecionar `%APPDATA%` move
o perfil inteiro para o sandbox sem mudar uma linha do produto. A guarda **recusa rodar** se o
sandbox cair em `%APPDATA%`, `%ProgramFiles%`, `%LOCALAPPDATA%\Programs` ou na raiz do repo.

**Prova, e não promessa (`R8`):** MD5 **por arquivo** de duas raízes intocáveis, antes e depois de
cada suíte:

| raiz | arquivos | diferenças de MD5 |
|---|---|---|
| `%APPDATA%\QGIS` | 0 | 0 |
| `%APPDATA%\InstitutoIMAN` (o perfil **real**, em uso) | 26 | **0** |

> `%APPDATA%\QGIS` está **vazio nesta bancada** - não há QGIS de sistema desde a via A1. Sozinha,
> essa linha provaria pouco. Por isso a guarda mede também o perfil **real** do IMAN Terra, que tem
> conteúdo e é exatamente o que o Passo 0 manda não encostar.

### Um efeito colateral que a guarda causou, e que ela passou a impedir (`S.5`)

**Medido durante a construção, e relatado aqui porque mexeu na bancada.** A guarda monta a árvore do
QGIS por **junction** (2,2 GB copiados por estado a tornariam cara demais para alguém rodar). O
estado 10 sobe um QGIS de verdade - e o Python dele grava `__pycache__` **dentro da árvore**, que
pela junction é `installer\stage\`, de onde o próximo `build.ps1 -ReusarArvore` empacotaria. Numa
passada foram **836 arquivos `.pyc`**.

| | |
|---|---|
| **o que ficou** | os `.pyc` foram removidos. Os cinco pisos que o manifesto declara continuam **exatos**: `share\proj` 16, `apps\qgis-ltr\resources` 5.577, `apps\Python312` **19.666**, `apps\qt5\plugins` 85, `apps\gdal\share\gdal` 161 |
| **o que não voltou** | a contagem total da árvore ficou em **37.318**, contra as **37.337** do `TOTAL` do manifesto: **19 `.pyc` de `apps\grass`**, que a extração original trazia, saíram junto. O launcher não lê `TOTAL` (ele confere pisos por diretório e SHA-256 de dois arquivos), e `apps\grass` não é um dos pisos - então **o produto não é afetado**. Quem quiser a árvore idêntica à extração roda `installer\New-ArvoreQgis.ps1`, que regenera árvore **e** manifesto juntos |
| **não acontece mais** | a guarda passou a subir o QGIS com `PYTHONDONTWRITEBYTECODE=1`, o que corta o problema na fonte, **e** a remover no fim os `.pyc` que nasceram durante a suíte. Medido depois: `0 .pyc nasceram durante a suite` nas duas rodadas finais |
| **fora do git** | `installer/stage/` é ignorado (`.gitignore:71`), então nada disso entra em commit |

### Um achado do Passo 0 que muda o que dá para medir (`E.1`)

O briefing mediu, em 2026-09-09, a deriva do perfil vivo contra o `{app}\profile-template`:
`QMenuBar::item` `6px 12px` contra `3px 4px`, raios de 5 a 8 px contra 2 px, `_RE_SUFIXO_DO_QGIS`
ausente. **Isso não é mais mensurável nesta bancada**: o sponsor reinstalou o `327d9ee` em
2026-09-15 às 17:08 **com o perfil recriado do zero**, e hoje o perfil vivo bate com o template
instalado, arquivo por arquivo:

| sinal | perfil vivo (**medido** 2026-09-16) | template instalado |
|---|---|---|
| `QMenuBar::item` | `padding: 3px 4px; border-radius: 2px` | idem |
| raios | 20 × `2px` | 20 × `2px` |
| `_RE_SUFIXO_DO_QGIS` | 3 ocorrências | 3 |
| `defaultProjectCrs` | `EPSG:31984` | `EPSG:31984` |

A deriva de 09-09 entra neste laudo como **relatado**. O defeito não some com ela: ele é a linha do
launcher, e a linha estava lá até esta fatia. A guarda o reproduz a partir de **templates reais da
história do git**, que é o que torna a medição repetível sem depender do estado de uma bancada.

---

## 2. O desenho

| # | requisito | como ficou |
|---|---|---|
| **R1** | a primeira abertura depois de instalar já mostra o produto novo | a reconciliação roda **no launcher**, antes de o QGIS ler o perfil: `app/launcher/Sync-Perfil.ps1`, chamado por `IMAN-Terra.bat`. Custo da abertura em que **não há nada a fazer**: ver §5 |
| **R2** | arquivos do produto espelham o template | árvores do produto (`python/plugins/iman_brand`, `themes/IMAN Terra`) são **espelhadas**: o que sobra de uma versão anterior sai. Obsoletos avulsos saem por nome |
| **R3** | chaves em 3-way, base registrada **por conteúdo** | base em `<perfil>/.iman-terra/base.json`, com o **digest do conteúdo** do template e o mapa de chaves. Perfil sem base: aplica as chaves do produto uma vez e registra |
| **R4** | o que é do usuário fica byte a byte | o `.ini` é editado **linha a linha**, preservando bytes; só a linha da chave que muda é tocada. Nada fora da declaração é lido para escrita |
| **R5** | idempotente | a segunda abertura não escreve nada - **nem `base.json`, nem o `splashpath`** |
| **R6** | fail-loud | `base.json` é escrita **por último**; falha deixa `INCOMPLETO.txt` e o produto **recusa abrir** |
| **R7** | QGIS já aberto | recusa (`exit 2`) quando **há** o que aplicar; abre normalmente quando não há |
| **R8** | BL-3, MD5 por arquivo | §1 |
| **R9** | um lugar só declara o que é do produto | `app/profile-template/PERFIL-DO-PRODUTO.json` |
| **R10** | downgrade | o template instalado é sempre a verdade; o anterior vence |

### Por que no launcher, e não no instalador (`R1`)

O perfil **nasce na primeira abertura**, não na instalação - no instante do install ele pode nem
existir. Reconciliar no instalador exigiria manter **duas rotinas** que precisam concordar (a do
instalador e a semeadura do launcher), e a que roda menos é a que apodrece: o `DB-26` nasceu
exatamente de uma rotina que só rodava uma vez. Aqui há **uma só**, e ela é a mesma que semeia. De
quebra, é a única posição de onde se enxerga que o produto já está aberto (`R7`) e se pode recusar
mexer embaixo dele.

E não no `--code` do `iman_startup.py`: nessa hora o QGIS já importou o código velho do `iman_brand`.
Tarde por construção - é o próprio briefing quem nota.

### Por que `Sync-Perfil.ps1` em PowerShell, chamado por caminho absoluto

Reconciliar exige SHA-256 por arquivo e edição cirúrgica de `.ini` preservando bytes; em `cmd` puro
isso vira um emaranhado que ninguém audita. O caminho absoluto
(`%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe`) segue a regra já estabelecida do
`%WFIND%`/`%WCERTUTIL%` no mesmo launcher: **launcher que depende do `PATH` do usuário é launcher
que quebra na máquina de quem tem ferramentas instaladas** (medido em 2026-09-07, com o `find` do
MSYS). Ausência do PowerShell é tratada como falha alta, não como silêncio.

### A fronteira, e por que as chaves **não** estão listadas na declaração

`PERFIL-DO-PRODUTO.json` declara **arquivos**: as árvores espelhadas, os arquivos avulsos, as pastas
e os obsoletos. As **chaves** são "toda chave que o `QGIS3.ini` do template declara", e isso está
escrito lá - mas a lista de nomes **não** é repetida. Repeti-la criaria dois lugares dizendo a mesma
coisa, que é o que o `R9` proíbe; e no dia em que divergissem, **a chave nova pararia de chegar em
silêncio** - o `DB-26` outra vez, em miniatura. Acrescentar a chave ao template é acrescentá-la ao
produto, num movimento só. O `DA-3` acrescenta a pasta `iman_plugin` à declaração e a chave dele ao
template do perfil.

**Uma guarda de `C.3` sustenta isso:** a reconciliação **recusa** se o template tiver um arquivo que
a declaração não cobre. Sem ela, acrescentar arquivo ao template e esquecer de declará-lo faria ele
nunca chegar a quem já instalou - e o erro apareceria na prefeitura, não na bancada de quem
esqueceu. Medido: rodar a rotina contra o template de `8cc4d5e^` (que traz `QGIS/iman-theme.qss`)
sai `FALHOU`, nomeando o arquivo.

### As duas consequências da arbitragem, ditas em voz alta

1. **O produto nunca muda `iman_brand=true` depois da primeira vez.** O template declara esse valor
   desde `536ad70` e nunca o mudou; logo, pelo 3-way, ele nunca é reaplicado. **Quem desligar o
   plugin de marca fica com ele desligado** - e isso é escolha do usuário sobre uma chave que o
   produto não mexeu, não defeito.
2. **Chave que o produto ACRESCENTA chega a quem já instalou.** É assim que o `iman_plugin=true` do
   `DA-3` vai chegar. Provado com uma chave de teste (`iman_teste_db26`), **sem embarcar o REURB**
   (estado 8).

### Decisões que o briefing deixou em aberto, e como ficaram

| pergunta | decisão | por quê |
|---|---|---|
| `R6`: avisar ou recusar? | **recusa abrir** | abrir sem reconciliar pode ser abrir em `EPSG:4674`. O QGIS não reclama de CRS "errado" - ele só desenha, e a medição sai errada sem aviso. É a mesma classe de falha silenciosa da árvore truncada, e o produto já respondeu a ela recusando |
| `R7`: o que fazer com instância viva? | **recusa quando há o que aplicar; abre quando não há** | o QGIS **reescreve o `QGIS3.ini` ao sair**: aplicar embaixo de uma instância viva deixaria uma base dizendo "aplicado" sobre um `.ini` que voltou atrás - literalmente o "meio aplicado passando por atualizado" que o `R6` proíbe. Quando não há o que aplicar, não há razão para atrapalhar quem só quer duas janelas |
| chave que o produto **deixa de declarar** (o briefing é silente) | **sai, se o usuário não a mexeu desde a base** | é a face simétrica de "obsoleto sai". Se o usuário mexeu, a chave passou a ser dele e fica |
| `__pycache__` dentro da pasta do plugin do produto | **não é sobra: é ignorado** | o Python grava esse bytecode ao importar, e ele nasce de novo a cada abertura. Espelhar sobre ele faria **toda segunda abertura escrever no perfil**, quebrando o `R5` sem nada em troca |
| o `splashpath` (`QGISCUSTOMIZATION3.ini`) | **saiu do `.bat` e passou a ser escrito só quando difere** | ele era reescrito **a cada execução**. Enquanto fosse, "a segunda abertura não escreve nada no perfil" era impossível de cumprir - o `R5` falharia por causa de uma linha que ninguém associava a ele |
| o fallback do `iman_startup.py` para `QGIS/iman-theme.qss` | **removido** | vira código morto: o arquivo é obsoleto declarado, a reconciliação o remove de qualquer perfil, e ela roda antes de o QGIS ler o perfil. O caminho não podia mais ser alcançado |

---

## 3. A guarda (`C.1`, `C.2`)

`tools/test-reconciliacao-perfil.ps1`.

- **Exercita o launcher REAL.** `IMAN_TERRA_RECONCILE_ONLY=1` faz o launcher conferir a árvore,
  reconciliar, imprimir o relato cru e sair **sem abrir o QGIS**. É o precedente do
  `IMAN_TERRA_CHECK_ONLY` (`#019`): teste que reimplementa a reconciliação valida a cópia.
- **Perfil velho vem de template REAL da história do git**, materializado por `git archive`:

  | commit | o que ele carrega | provado por |
  |---|---|---|
  | `ba58d14` (2026-09-07, merge do PR #22, **anterior ao `#022`**) | **14** declarações de raio de 5 a 8 px; `QMenuBar::item` `padding: 6px 12px`; `iman_brand.py` **sem** `_RE_SUFIXO_DO_QGIS` | `git show` na §3.1 |
  | `8cc4d5e^` = `f728e4f` (2026-07-05, **anterior a `8cc4d5e` de 07-07**) | os **dois** obsoletos (`QGIS/iman-theme.qss`, `.../resources/logo.png`) e `defaultProjectCrs=EPSG:4674` | §3.1 |

- **Semeado por CÓPIA CRUA, não pela rotina nova.** É como ele nasceu de verdade: o launcher da
  época fazia `xcopy /E /I /Y`. E template antigo **não é** "o template deste build" - o produto
  sempre reconcilia contra o template que **ele** embarca.
- **Asserção por hash e por valor de chave lido do `.ini`**, nunca "o arquivo existe".
- **`E.1` antes de cada rodada:** confere-se que o perfil semeado **de fato difere** do template
  naquilo que a rodada assere. Se já saísse igual, o estado vira `ABORTADO` e a suíte sai `exit 2`.
- **A árvore do QGIS entra por junction** (2,2 GB copiados por estado tornariam a guarda cara demais
  para alguém rodar). Medido nesta bancada: `Win32_Process.ExecutablePath` reporta **o caminho da
  junction**, não o do alvo - por isso o estado 10 consegue dizer "é o QGIS deste sandbox".

### 3.1 O que cada template histórico carrega (**medido**, pelo git)

Saída crua integral: `evidencia/templates-historicos-pelo-git.txt`.

| | `8cc4d5e^` = `f728e4f` (07-05) | `ba58d14` (09-07, pré-`#022`) | `HEAD` (o template desta fatia) |
|---|---|---|---|
| `QGIS/iman-theme.qss` | **presente** | ausente | ausente |
| `.../resources/logo.png` | **presente** | ausente | ausente |
| `QGIS/splash.png` | ausente | presente | presente |
| `themes/IMAN Terra/style.qss` | **não existe** | presente | presente |
| `dashboard.py` / `sobre.py` | ausentes | presentes | presentes |
| `defaultProjectCrs` | **`EPSG:4674`** | `EPSG:31984` | `EPSG:31984` |
| `[UI] Customization\enabled` | **seção nem existe** | `true` | `true` |
| raios no tema | (não há tema) | **14** de 5 a 8 px | **20** de 2 px |
| `QMenuBar::item` | (não há tema) | `padding: 6px 12px` | `padding: 3px 4px` |
| `_RE_SUFIXO_DO_QGIS` | 0 | **0** | **3** |

As 14 declarações de 5 a 8 px de `ba58d14` conferem com o número do briefing, e vêm da contagem por
valor: `2 × 5px`, `4 × 6px`, `3 × 7px`, `3 × 8px`, `1 × border-top-left-radius: 8px`,
`1 × border-top-right-radius: 8px`.

### 3.2 A matriz (`S.4`) - **medido**

Saída crua integral: `evidencia/guarda-desta-fatia.out` · JSON: `evidencia/guarda-desta-fatia.json` ·
SHA-256 do que rodou: `evidencia/procedencia.txt`.

| # | estado | launcher de `733e129` | **launcher desta fatia** |
|---|---|---|---|
| 1 | perfil ausente (primeiro uso) | **`FAIL`** | **`PASS`** |
| 2 | perfil já igual ao template atual (`R5`) | **`FAIL`** | **`PASS`** |
| 3 | perfil de template anterior ao `#022` | **`FAIL`** | **`PASS`** |
| 4 | perfil de template anterior a 07-07 | **`FAIL`** | **`PASS`** |
| 5 | usuário mudou chave que o produto não mudou | `PASS` (vacuamente, ver §3.3) | **`PASS`** |
| 6 | usuário e produto mudaram a mesma chave | **`FAIL`** | **`PASS`** |
| 7 | plugin do usuário e a chave dele | `PASS` (vacuamente) | **`PASS`** |
| 8 | template novo acrescenta uma chave de teste | **`FAIL`** | **`PASS`** |
| 9 | falha induzida no meio | **`FAIL`** | **`PASS`** |
| 10 | QGIS já aberto | `N/E` (não exercitado na rodada vermelha) | **`PASS`** |
| 11 | downgrade (`R10`) | **`ABORTADO` por `E.1`**, ver §3.3 | **`PASS`** |
| | **BL-3 / Passo 0** | `PASS` | `PASS` |
| | **exit da guarda** | **`2`** (46 s) | **`0`** (76 s) |

**Os números que cada estado devolveu no verde:**

| # | o que foi medido |
|---|---|
| 1 | `SEMEADO`, `arq+11 pasta+2 splash+1 base+1`; **11 de 11** arquivos do template com SHA-256 idêntico no perfil; base registrada com `template_digest` e **8** chaves |
| 2 | `NADA_A_FAZER`; **13 arquivos no perfil, 0 diferenças** de SHA-256 **ou de mtime** entre as duas aberturas |
| 3 | `APLICADA`, `arq~7`; raios de 5 a 8 px **14 → 0**, raios de 2 px **→ 20** (o template tem 20); `QMenuBar::item` **`6px 12px` → `3px 4px`**; `_RE_SUFIXO_DO_QGIS` **0 → 3**; **11 de 11** arquivos do produto com o SHA-256 do template |
| 4 | `APLICADA`, `arq+5 arq~3 arq-2 chave+1 chave~2`; **os dois obsoletos removidos**; `defaultProjectCrs` **`EPSG:4674` → `EPSG:31984`**; `layerDefaultCrs` **→ `EPSG:31984`**; `[UI] Customization\enabled` **→ `true`** numa seção que **não existia no perfil** |
| 5 | `NADA_A_FAZER`; `[qgis] showTips`: template `false`, usuário `true`, **depois `true`** |
| 6 | `APLICADA`, `chave~1`; base `EPSG:31984`, usuário `EPSG:4326`, template `EPSG:31985`, **depois `EPSG:31985`** |
| 7 | `NADA_A_FAZER`; **3 arquivos** do plugin do usuário, **0 diferenças** de SHA-256/mtime; `plugin_do_usuario=true` e `iman_brand=true` preservados; `QGIS/bookmarks.xml` com o mesmo SHA-256 |
| 8 | `APLICADA`, `chave+1`; `[PythonPlugins] iman_teste_db26` **ausente → `true`** |
| 9 | `FALHOU`, `exit 1`, com o `DETALHE` **"ao aplicar"** (e não "ao montar o plano"): a rodada morreu **depois** de já ter copiado outros arquivos. **`base.json` não foi escrita**; **`INCOMPLETO.txt` ficou**. Solto o lock, a abertura seguinte saiu `APLICADA` e o perfil ficou completo com base registrada |
| 10 | instância viva em `C:\_IMANT~3\e10\v2\app\qgis\bin\qgis-ltr-bin.exe` (**forma 8.3**, que é a que o `o4w_env.bat` produz). **(a)** havendo o que aplicar: `exit 2`, `INSTANCIA_VIVA`, e **a chave nova não foi escrita** embaixo da instância viva. **(b)** sem nada a aplicar: `exit 0`, abre |
| 11 | `APLICADA`, `arq~1 chave~1`; `style.qss` **volta ao SHA-256 do template anterior**; `defaultProjectCrs` **`EPSG:31984` → `EPSG:4674`** |

**Duas coisas que a matriz prova de lado, e que valem ser ditas:**

- **O estado 10 exercita o ramo 8.3 da detecção.** O sandbox foi posto em `C:\_imant30-guarda`
  (mais de 8 caracteres) **de propósito**: assim o `o4w_env.bat` precisa de um alias (`C:\_IMANT~3`) e
  a comparação curta do produto é posta à prova. Com a raiz anterior (`C:\_imant30`, já válida em
  8.3) as duas formas coincidiam e esse ramo nunca era exercitado.
- **O que é do usuário dentro de `themes/` continua dele.** Só `themes/IMAN Terra` é árvore do
  produto; um tema de UI que o usuário tenha criado em `themes/<outro nome>/` não é tocado.

### 3.3 Adulteração inversa - a mesma guarda contra o launcher de `733e129`

`-Ref 733e129` extrai `app/launcher/` daquele commit e põe **esse** launcher à prova, com o
**template e a declaração desta fatia**. A pergunta é exata: *o launcher daquele commit entrega este
produto?* Saída crua: `evidencia/guarda-733e129.out` · JSON: `evidencia/guarda-733e129.json`.

**Os quatro estados que o briefing pediu em `FAIL`, com o que a guarda leu:**

```
  [FAIL] estado 3 - perfil de template anterior ao #022 -> tema e plugin novos chegam
        raios: 5-8px 14 -> 14   2px -> 0 (template tem 20)
        QMenuBar::item: 6px 12px -> 3px 4px? False
        _RE_SUFIXO_DO_QGIS em iman_brand.py: 0 -> 0 (template tem 3)
        arquivos do produto com SHA-256 do template: 4 de 11

  [FAIL] estado 4 - perfil anterior a 07-07 -> obsoletos saem, CRS corrige
        QGIS/iman-theme.qss     : presente -> True
        resources/logo.png      : presente -> True
        defaultProjectCrs       : EPSG:4674 -> EPSG:4674

  [FAIL] estado 6 - usuario e produto mudaram a mesma chave -> o produto vence
        defaultProjectCrs: base=EPSG:31984  usuario=EPSG:4326  template=EPSG:31985  depois=EPSG:4326

  [FAIL] estado 8 - chave nova do template -> chega ao perfil velho
        [PythonPlugins] iman_teste_db26: ausente ->
```

**E mais três, que a guarda pegou sem terem sido pedidas:**

- **estado 1:** o `xcopy` do launcher velho **acerta** os 11 arquivos no primeiro uso - isso sempre
  funcionou. O que ele não faz é **registrar a base**, e sem base não há 3-way na próxima versão.
- **estado 2 (`R5`):** **6 diferenças** no perfil entre duas aberturas seguidas, sem nada ter mudado.
  Uma delas é o `QGISCUSTOMIZATION3.ini` reescrito **a cada execução** - a linha que, sozinha,
  tornava o `R5` impossível. As outras cinco são o QGIS gravando `qgis.db`, `bookmarks.xml`,
  `symbology-style.db`: essas são dele, e por isso a asserção do verde compara o perfil entre **duas
  reconciliações**, não entre duas sessões do QGIS.
- **estado 9:** sem reconciliação não há fail-loud nenhum: `exit 0`, sem `INCOMPLETO.txt`, e o perfil
  fica velho **em silêncio**.

**Os estados 5 e 7 saem `PASS` na rodada vermelha, e isso é informação, não ruído (`C.2`).** Os dois
asseveram **preservação** ("a chave do usuário fica", "o plugin dele fica intacto"), e um launcher que
**não faz nada** satisfaz preservação trivialmente. Eles não discriminam o defeito - discriminam a
**regressão oposta**, o dia em que a reconciliação passar a pisar no que é do usuário. É para isso
que servem, e o lugar de dizer isso é aqui.

**O estado 11 sai `ABORTADO`, e é a guarda funcionando (`E.1`).** O downgrade parte de um perfil que
**já recebeu o template novo** - e quem o levaria até lá é justamente a reconciliação, que o launcher
velho não tem. A pré-condição "o perfil está com o tema NOVO" não se cumpre, a guarda **recusa rodar
a rodada** em vez de devolver um `FAIL` que mediria outra coisa, e a suíte sai `exit 2` (baseline
inválido), não `exit 1`. Um `FAIL` ali seria mais bonito no laudo e valeria menos.

---

## 4. Prova de produto (`D-IMAN-033`, `V.4`)

**O que era para ser, e o que foi.** O briefing condiciona esta seção a *"com o PR #28 mergeado e a
autorização do sponsor para instalar"*. **O PR #28 continua aberto**, e o mesmo briefing proíbe
compilar instalador antes do merge dele. Então não há build desta fatia para instalar, e nada foi
instalado.

**O que foi feito no lugar, e por que ele vale.** As duas tomadas e as três rodadas de aceite abaixo
sobem o **produto realmente instalado nesta bancada** - a árvore privada do QGIS de
`%LOCALAPPDATA%\Programs\IMAN Terra` (build canônico `327d9ee`, `0.3.0`, QGIS `3.44.13-Solothurn`) -
com a camada de marca desta fatia, pelo mesmo caminho de sempre (`qgis-ltr.bat` → `o4w_env.bat` →
`--code`). **O que muda entre "antes" e "depois" é uma coisa só: a reconciliação ter rodado.**
O que **não** foi exercitado assim é o instalador, e isso está na §8.

### 4.1 O mesmo perfil, o mesmo enquadramento, antes e depois (**medido**)

Perfil semeado por cópia crua do `profile-template` de **`ba58d14`**, na raiz de teste
`%LOCALAPPDATA%\InstitutoIMAN\_aceite017` (**nunca** o perfil real). Sonda `vitrine.py`, que maximiza
a janela e deixa na tela, de uma vez, título, barra de menus, um menu aberto, um dock e um diálogo
com botão e campo.

| | |
|---|---|
| **antes** | `evidencia/shots/antes-perfil-de-ba58d14.png` |
| **depois** | `evidencia/shots/depois-mesmo-perfil-reconciliado.png` |

| sinal | antes (perfil de `ba58d14`) | depois (o mesmo perfil, reconciliado) |
|---|---|---|
| **título da janela** | `Projeto sem título — QGIS [iman-distro]` | **`Projeto sem título - IMAN Terra`** |
| **barra de menus** | itens largos (`padding: 6px 12px`) | **itens densos** (`padding: 3px 4px`) |
| **raio do menu aberto e dos botões** | arredondado (5 a 8 px) | **quadrado (2 px)** |
| **o que a reconciliação disse** | (não rodou) | `APLICADA`, `arq~7`, `380 ms`, e nomeou os 7: `brand.py`, `dashboard.py`, `iman_brand.py`, `resources/splash.png`, `sobre.py`, `QGIS/splash.png`, `themes/IMAN Terra/style.qss` |

O relato cru de cada rodada, com de que template o perfil partiu e se foi reconciliado, fica em
`evidencia/aceite-*-origem-do-perfil.txt` - gravado pelo próprio harness, porque dois `aceite.json`
sairiam indistinguíveis sem isso.

> **O CRS na barra de status não aparece nas tomadas.** O `ba58d14` já traz `EPSG:31984`, igual ao
> template atual: sobre **esse** perfil não há o que mostrar. O perfil que abre em `EPSG:4674` é o
> anterior a `4dfeb93`, e ele está medido **por valor lido do `.ini`** no estado 4 da matriz
> (`EPSG:4674 → EPSG:31984`), que é asserção mais forte que um pixel de barra de status.

### 4.2 O aceite passa a rodar sobre perfil velho, e é ele que fecha a cegueira

`Invoke-Aceite.ps1 -PerfilVelhoDe ba58d14 [-Reconciliar]`. **Três rodadas, a mesma suíte
`A01…A13` + `M-D11`, o mesmo produto instalado:**

| rodada | `PASS` | `FAIL` | `N/E` |
|---|---|---|---|
| perfil velho (`ba58d14`), **sem** reconciliar | 11 | **2** | 1 |
| o mesmo perfil, **reconciliado** | **13** | **0** | 1 |
| perfil novo, do template atual (a rodada de sempre) | 13 | 0 | 1 |

**As duas que reprovam no perfil velho, e o que elas leram:**

- **`A05` - título da janela.** Os **5** estados avaliados ficaram fora do critério. O medido:
  `"titulo": "Projeto sem título — QGIS [iman-distro]"`, com
  `a_termina_com_a_marca: false`, `b_sem_QGIS_como_autodesignacao: false`,
  `c_sem_colchete_de_perfil: false`, `d_sem_travessao_nem_meia_risca: false`. É o defeito do `#022`,
  **vivo num perfil que já estava na máquina**, três fatias depois de consertado no template.
- **`A13` - identidade do build.** `o_que_o_produto_diz` devolveu
  `AttributeError("module 'iman_brand.brand' has no attribute 'versao_exibida'")`: o `brand.py` do
  perfil é o de antes do `DB-24`. O `{app}\BUILD_ID.txt` do produto instalado está correto
  (`0.3.0`, `327d9ee`, canônico) - **quem não sabe lê-lo é o plugin velho que ficou no perfil.**

**Esta é a medida exata da cegueira.** O aceite, que sempre passou, **reprova** quando roda sobre um
perfil de versão anterior; e **volta a passar, com o mesmo placar do perfil novo**, depois que a
rotina do produto reconcilia. Antes desta fatia esse par de rodadas não existia: o harness
reconstruía o perfil do zero (`V.4`) e, por construção, nunca podia ver o `DB-26`.

`M-D11` sai `N/E` nas três, com o motivo registrado (`"nao observavel de dentro do processo"`) - é o
mesmo `N/E` de sempre, não um efeito desta fatia.

**Saída crua:** `evidencia/aceite-perfil-velho-SEM-reconciliar.out`,
`evidencia/aceite-perfil-velho-RECONCILIADO.out`, `evidencia/aceite-perfil-novo.out`, com o
`aceite.json` de cada uma ao lado.

---

## 5. Custo da reconciliação na abertura (`R1`)

O briefing pede: *"se for no launcher, meçam o custo na abertura em que não há nada a fazer"*.

| | **medido** |
|---|---|
| rotina de reconciliação, abertura sem nada a fazer | **239 ms** (estado 2 da rodada final; 231, 235 e 236 ms em rodadas anteriores desta sessão) |
| o que ela faz nesses 231 ms | lê a declaração, lista o template, calcula **SHA-256 de 11 arquivos** do template **e dos 11 correspondentes no perfil**, compara o digest com a base, lê as chaves dos dois `.ini` e conclui `NADA_A_FAZER` |
| o que ela **não** faz | nenhuma escrita: 13 arquivos no perfil, **0 diferenças de SHA-256 ou mtime** |
| custo somado à abertura | esses 231 ms **mais** o arranque de um `powershell.exe -NoProfile` |

**Contra o que comparar:** a guarda de integridade que já roda antes dela confere **37.337 arquivos**
da árvore do QGIS, e o boot do QGIS leva dezenas de segundos. A reconciliação é a parte barata da
abertura, e a alternativa (a chave do CRS errada num memorial) não tem preço comparável.

**Por que não há um atalho mais barato.** Poderia-se pular tudo quando o template "parece o mesmo"
por data ou versão - e é exatamente isso que o `R3` proíbe: o template mudou **duas vezes dentro da
mesma `0.3.0`** (`#022`, `#027`). Um atalho por versão devolveria `NADA_A_FAZER` em 0 ms e estaria
errado.

---

## 6. O que ficou fora, e por quê (`P0.7`)

| fora | situação |
|---|---|
| **`DA-3`**, embarque do REURB | fora. Só a prova de que **chave nova chega** (estado 8), com uma chave de teste `iman_teste_db26` que **não existe no produto** - ela só vive na variante de template que a guarda monta em tempo de execução |
| **`#023`**, varredura de travessão | fora. Vale a regra 1 do `D-IMAN-034`: **texto novo sem travessão nem meia-risca**. Conferido nos arquivos novos e nas linhas reescritas - ver §7 |
| **Reescrita do `CHECKLIST.md`** | fora. O §15 ficou **stale** com este merge; a dívida está nomeada em §7 e o procedimento que a reescrita vai citar está lá |
| **Build canônico pós-merge** | fora - despacho próprio, sob o desenho do `#029` |
| **Desinstalar apagando o perfil** | fora. O BL-3 continua: o perfil fica. Nada no `.iss` mudou |
| **Botão de "resetar perfil"** e migração de dado do usuário | fora |
| **O fallback do `iman_startup.py` para `QGIS/iman-theme.qss`** | **removido**, e declarado em §2. Virou código morto: o arquivo é obsoleto declarado, a reconciliação o remove de qualquer perfil, e ela roda antes de o QGIS ler o perfil |

**O `.iss` não foi tocado.** `Sync-Perfil.ps1` e `PERFIL-DO-PRODUTO.json` já viajam pela regra que
existe (`Source: "..\app\*"; Flags: recursesubdirs`), e o `Excludes` atual (`*.pyc,__pycache__,.gitkeep`)
continua correto para os dois. Nada que entra no `.exe` mudou de forma.

---

## 7. Dívidas nomeadas (`E.3`)

### 7.1 `CHECKLIST.md` §15 - **stale a partir deste merge**

O §15 do BL-7 diz "espera-se FAIL" para o update-path. **Com esta fatia, o esperado passa a ser
PASS.** Quem seguir a instrução como está escrita vai registrar um FAIL falso.

Um aviso foi posto **no topo do §15** apontando para cá - isso não é a reescrita, é impedir que uma
instrução sabidamente errada seja seguida. **A reescrita é fatia própria.**

**O procedimento que a reescrita vai citar**, na VM limpa:

1. Instalar uma versão **anterior** e abrir uma vez, para o perfil nascer. (Alternativa sem duas
   instalações, e é a que a guarda usa: semear o perfil por cópia crua a partir do
   `app/profile-template/iman-distro` de um commit anterior - `ba58d14` para o visual, `8cc4d5e^`
   para os obsoletos e o CRS.)
2. **`E.1` antes de medir:** conferir que o perfil semeado **de fato difere** do template que a
   versão nova instala, no que o passo vai asserir. Perfil que já sai igual não prova nada.
3. Instalar a versão nova **por cima** e abrir.
4. Conferir, **por valor e por hash**, e não "parece certo":

   | sinal | onde se lê | esperado |
   |---|---|---|
   | CRS padrão | `...\profiles\iman-distro\QGIS\QGIS3.ini`, `[app] projections\defaultProjectCrs` | `EPSG:31984` |
   | tema novo | SHA-256 de `...\themes\IMAN Terra\style.qss` == o do `{app}\profile-template\...` | iguais |
   | plugin novo | SHA-256 de cada arquivo de `...\python\plugins\iman_brand\` == o do template | iguais |
   | obsoletos | `...\QGIS\iman-theme.qss` e `...\resources\logo.png` | **ausentes** |
   | base | `...\.iman-terra\base.json` | existe, com `template_digest` |
   | idempotência | fechar e abrir de novo | nada muda de SHA-256 nem de mtime no perfil |

5. **A segunda abertura é parte do passo**, não um extra: é ela que mostra que a reconciliação não
   fica reescrevendo o perfil a cada vez.
6. **Na bancada, sem VM, o mesmo passo se roda em um comando**, e é o que a §4.2 fez:
   `Invoke-Aceite.ps1 -PerfilVelhoDe ba58d14` deve **reprovar** (`A05`, `A13`), e
   `Invoke-Aceite.ps1 -PerfilVelhoDe ba58d14 -Reconciliar` deve dar o **mesmo placar do perfil
   novo**. Se os dois derem igual, o passo perdeu o poder de reprovar e é ele que está quebrado.

### 7.2 `README.md` - "Pré-requisito de runtime: QGIS LTR instalado"

O bloco **Build & execução** do `README.md` ainda descreve o instalador como **leve** e o QGIS LTR
como pré-requisito de runtime. Isso morreu na `#019` (via A1): o QGIS vive dentro do produto. **Não
foi consertado aqui** - é texto de outra fatia, e carona de higiene em fatia de produto é
exatamente o que o `#029` acabou de tirar do caminho. **Dívida nomeada.** O que esta fatia
atualizou no `README.md` foi só o que ela mesma mudou: a linha do launcher, a árvore do
`profile-template` e o passo "rodar sem instalar".

### 7.3 Travessão (`D-IMAN-034`, regra 1)

Arquivos novos e linhas reescritas nesta fatia saem **sem travessão e sem meia-risca**. Os arquivos
novos (`Sync-Perfil.ps1`, `PERFIL-DO-PRODUTO.json`, `test-reconciliacao-perfil.ps1`) são ASCII-only
por construção, e as linhas novas dos `.md` foram varridas.

**As duas exceções deste laudo são deliberadas e não devem ser "consertadas":** as ocorrências de
`—` nas §4.1 e §4.2 estão dentro de **citação do valor medido** - o título defeituoso que o `A05`
leu no perfil velho (`Projeto sem título — QGIS [iman-distro]`). O travessão **é o defeito relatado**
(`d_sem_travessao_nem_meia_risca: false`). Trocá-lo apagaria a evidência.

---

## 8. O que esta fatia NÃO mediu, e por quê

| não medido | por quê |
|---|---|
| **Instalar um build desta fatia na bancada** | o briefing proíbe compilar instalador antes do merge do PR #28, e ele **continua aberto**. Sem compilar não há o que instalar, e a pergunta de autorização do Passo 0 não chegou a existir |
| **O `grab()` sobre o produto recém-instalado desta fatia** | consequência do item acima. O que foi feito no lugar está na §4: as duas tomadas saem da **árvore do produto realmente instalada na bancada** (`327d9ee`), com a camada de marca desta fatia - mesmo perfil, mesmo enquadramento, mesma sonda. O que **não** está coberto é o caminho do instalador em si: se o `.iss` entrega `Sync-Perfil.ps1` e `PERFIL-DO-PRODUTO.json` em `{app}`. O `.iss` não foi tocado e os dois caem na regra `..\app\*` que já existe, mas **isso é raciocínio, não medição** |
| **BL-7 em VM limpa** | fatia própria, e depende de um build. O procedimento que o §15 vai passar a exigir está na §7.1 |
| **A deriva do perfil vivo de 2026-09-09** | o sponsor recriou o perfil do zero em 15/09 (§1). Entra como **relatado** |
| **Perfil de uma prefeitura real** | o `0.3.0` não foi liberado: **nenhuma prefeitura instalou**. É por isso que o `R3` pôde escolher "perfil sem base registrada aplica tudo uma vez" sem risco - hoje **todo** perfil existente está nessa situação, e todos estão em bancada |
