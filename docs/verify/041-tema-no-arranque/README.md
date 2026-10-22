# `#041`: o tema da marca entra no arranque, o logo do QGIS sai do Processamento, e "QGIS" vira "IMAN Terra" onde nomeia o aplicativo

**Executado em:** 2026-10-22 · branch `feat/041-tema-no-arranque` · PR #31
**Base:** `origin/develop` em `df761da` · **Decisão:** `D-IMAN-039` (emenda o `D-IMAN-033`)
**Bancada:** Windows 11 Pro 10.0.26200 · PowerShell 5.1 · sem QGIS de sistema
**Build medido:** não canônico `0.3.0-a447168`, SHA-256 `15FE26A111B0B9E3384319BA8093654175D2451C9609C9EB378A81C1D96F5C7A`
(`evidencia/build/BUILD_INFO.txt`). Lado `develop`: o canônico `0.3.0-5f7a1cb` instalado, com o
template e o startup de `origin/develop` (o `app/` dos dois commits é idêntico, conferido por `git diff`).
**Tipo:** fatia visual com código de marca (perfil, startup, plugin `iman_brand`).

---

## 0. Legenda (`E.6`)

| marca | significa |
|---|---|
| **medido** | obtido nesta bancada, nesta sessão, com evidência em `evidencia/` |
| **relatado** | veio do briefing, da forense do arquiteto ou de outra sessão, identificado como tal |
| **`N/E`** | não exercitado, nomeado, com o motivo |

---

## 1. A bancada (Passo 0), e o que aconteceu nela

**O sponsor autorizou** instalar o build da branch e restaurar o canônico no fim (2026-10-22,
pergunta "Passo 0", opção "Instalar e restaurar"). Foi o que aconteceu: `a447168` instalado em
silêncio, medido, e `5f7a1cb` reinstalado no fim (SHA-256 conferido contra o `BUILD_INFO.txt`).

### 1.1 Um teste existente reconciliou o perfil REAL do sponsor (medido, e desfeito)

`tools/test-reinstalacao.ps1` diz no cabeçalho que "não toca `%APPDATA%\InstitutoIMAN`". **Ele toca:**
as etapas 2 e 5 abrem o produto pelo launcher sem redirecionar `%APPDATA%`, e o launcher reconcilia o
perfil de `%APPDATA%\InstitutoIMAN\IMAN Terra\profiles\iman-distro`. Rodado com o instalador desta
branch, ele levou o template do `#041` ao perfil real do sponsor (`base.json` registrada às 16:51) e o
plugin da branch gravou nele as três chaves de endereço da Ajuda.

| | |
|---|---|
| **o que foi feito** | com autorização do sponsor: reinstalado o canônico `5f7a1cb`; rodado o `Sync-Perfil.ps1` **dele** sobre o perfil real (a mesma rotina do launcher, sem abrir o QGIS): `arq~2 arq-4 chave-4`, isto é, o downgrade do estado 11 tirou `UITheme`, `httpsfeedqgisorg\disabled`, `checkVersion`, `allowVersionCheck`, `translation.py`, `product_links.py` e os dois ícones; removidas à mão as 3 linhas `helpQgisHomePageUrl`/`reportaBugUrl`/`supportProvidersUrl` e os 2 `.pyc` órfãos |
| **conferido** | segunda passada da rotina: `RECONCILIACAO=NADA_A_FAZER`; nenhuma chave do `#041` no `QGIS3.ini`; `QGISCUSTOMIZATION3.ini` só com o `splashpath` (`evidencia/perfil-real/`) |
| **o que não volta** | o que o próprio QGIS grava em cada abertura (geometria de janela, estado de painéis) nas 4 aberturas do teste. Não se separa do uso normal |
| **o defeito do teste** | é pré-existente e **não foi editado** (`P0.10`). Vai como flag no `/deliver`: o `test-reinstalacao.ps1` precisa isolar `%APPDATA%` como o `test-reconciliacao-perfil.ps1` já faz |

**Segundo episódio, causado pela restauração (medido, e desfeito).** Instalar o canônico **por cima**
do build da branch não remove o que só a branch tinha: o Inno funde, e o `[InstallDelete]` só limpa
`{app}\qgis`. Ficaram em `{app}\profile-template` os 4 arquivos do `#041`, e a conferência do perfil
real (a rotina do produto) os copiou para ele (`arq+4`). Corrigido com desinstalação completa,
instalação limpa do canônico e a rotina de novo (`arq-4`, depois `NADA_A_FAZER`):
`evidencia/perfil-real/restauracao-2-sobras-do-instalador.txt`. É um achado de produto, a classe do
`DB-22` em `{app}\profile-template`, e vai como flag.

O relatório que o mesmo teste grava por padrão em `docs/verify/021-reinstalar-sem-laco/evidencia/
reinstalacao.json` (arquivo versionado de outro laudo) foi devolvido ao commit; a saída desta rodada
está em `evidencia/gate/reinstalacao.json`.

### 1.2 Nenhuma foto da tela entra neste laudo

A primeira versão da sonda de evidência fotografava a **tela** na área de cada janela, para mostrar a
barra de título. Numa bancada em uso, duas tomadas pegaram o que estava na frente: um terminal de
outra sessão e um navegador com dados pessoais. **Todas as 45 tomadas desse tipo foram apagadas** da
área de rascunho e a sonda deixou de fotografar a tela: o ícone da barra de título é salvo a partir do
`windowIcon()` da janela (`*-icone-da-janela.png`), que é o que o Windows desenha ali. As fotos da
janela principal também ficaram fora: o Navegador mostra rótulos de unidades com e-mails.

### 1.3 `BL-3`

`%APPDATA%\QGIS` com o mesmo conteúdo e as mesmas datas antes e depois da sessão (listagem por
arquivo, `evidencia/bl3-appdata-qgis.txt`). As guardas novas sobem o `QgsApplication` com
`QGIS_CUSTOM_CONFIG_PATH` numa pasta temporária.

---

## 2. O que mudou (os 8 itens do briefing)

| item | onde | estado |
|---|---|---|
| 1. tema no arranque | `[UI] UITheme=IMAN Terra` em `app/profile-template/iman-distro/QGIS/QGIS3.ini`; comentário falso do `iman_startup.py` e linha do teto do contrato corrigidos | **medido**: A14 PASS (FAIL na develop) |
| 2. logo fora do Processamento | `themes/IMAN Terra/icons/providerQgis.svg`, recortado do master **vetorial** `app/assets/splash-iman-terra.svg` por `app/assets/derive-theme-icons.py` (o símbolo existe em vetor no master; nada embutido); `icons/mIconNetworkLogger.svg` genérico | **medido**: A15 PASS; S46 ver §3.8 |
| 3. ícone IMAN nas janelas | `QgsApplication.setWindowIcon` com o `.ico` de 16 a 256 px no início do startup | **medido**: A16 PASS (FAIL na develop) |
| 4. guarda do tema | `tools/test-theme-icons.ps1` + `tools/brand-guards/theme_icons_probe.py`; roda no `build.ps1` (exit 8) | **medido**: 7 de 7, com V1 a V3 reprovados (§4) |
| 5. notícias e versão | `[core] httpsfeedqgisorg\disabled=true`, `[qgis] checkVersion=false`, `[qgis] allowVersionCheck=false`; `Menus\mHelpMenu\mActionCheckQgisVersion=false` declarado em `PERFIL-DO-PRODUTO.json` e escrito pelo `Sync-Perfil.ps1` | **medido**: §5 |
| 6. endereços da Ajuda | `iman_brand/product_links.py` grava as 3 chaves com `brand.URL_SITE` (lido da fonte única; o template seria uma segunda cópia) | **medido**: §5.2 |
| 7. tradutor sobreposto | fonte `app/i18n/iman_terra_pt_BR.json` (20 mensagens, original ao lado do novo, nome como token); `.qm` gerado no build por `installer/New-BrandTranslation.ps1` com `lrelease` 5.15.2 (wheel `qt5-applications` 5.15.2.2.3, SHA-256 fixado, não redistribuído); instalado por `iman_brand/translation.py` no `classFactory` | **medido**: §6 |
| 8. contrato | `docs/branding-contract.md`: ícones de ação saem do teto, regiões 1.11 a 1.14 com A14 a A17, emenda da regra "acrescenta, nunca remove nem renomeia" só com as exceções do `D-IMAN-039` | feito |

---

## 3. Região por região, lado a lado (`V.2`)

Fotos em `evidencia/develop/shots/` e `evidencia/branch/shots/`, mesmos nomes dos dois lados.

### 3.1 Caixa de Processamento, agrupada (`041-caixa-agrupada.png`)

| | develop | branch | |
|---|---|---|---|
| nós de topo com o logo do QGIS | **29 de 31** | **0 de 31** | medido (A15) |
| nós de topo com o símbolo do tema | 0 | **29 de 31** | medido (A15) |
| os outros 2 | GDAL e GRASS, ícones próprios, sem logo | idem | medido |

### 3.2 Caixa por provedor (`041-caixa-grupo-e-provedor-abertos.png`, `041-caixa-busca-buffer.png`)

A caixa do 3.44 não tem modo "por provedor" para os provedores do QGIS: eles aparecem como grupos de
topo (3.1), e só GDAL e GRASS viram nó de provedor. "Por provedor" foi medido no registro de
provedores, que é de onde a caixa e as Opções tiram nome e ícone:

| provedor | develop: nome / ícone | branch: nome / ícone |
|---|---|---|
| `native` | QGIS (c++ nativo) / logo | **IMAN Terra (c++ nativo)** / símbolo do tema |
| `3d` | QGIS (3D) / logo | **IMAN Terra (3D)** / símbolo do tema |
| `pdal` | QGIS (PDAL) / logo | **IMAN Terra (PDAL)** / símbolo do tema |
| `qgis` (Python) | QGIS / logo | QGIS / símbolo do tema: o nome é literal no `.py`, sem `tr()` (S08, fora de escopo) |
| `gdal`, `grass`, `model`, `project`, `script` | ícones próprios | inalterados |

### 3.3 Opções ▸ Processamento ▸ Provedores (`041-opcoes-processamento-provedores.png`)

**medido, nos dois lados:** a página lista só **GDAL** e **GRASS** (os provedores com configuração).
Os provedores do QGIS não aparecem ali no 3.44, então esta região não mostra o `providerQgis.svg` em
nenhum lado. A forense (S01) a cita como superfície (relatado); aqui ela não exibe o logo.

### 3.4 Log do diálogo de um algoritmo nativo (`041-algoritmo-log.png`)

| develop | branch |
|---|---|
| `Versão do QGIS: 3.44.13-Solothurn` / `Código de revisão do QGIS: 2c8a7782a96` | `Versão do motor: 3.44.13-Solothurn` / `Revisão do código do motor: 2c8a7782a96` |

**medido.** O valor continua sendo a versão do QGIS, e o texto não diz "versão do IMAN Terra"
(`D-IMAN-039` regra 3; A17).

### 3.5 Modelador com um algoritmo (`041-modelador.png`)

**medido:** o modelo com `native:buffer` desenha o ícone próprio do algoritmo, sem logo, nos dois
lados. O `providerQgis.svg` do modelador aparece na aba Toolbox dele, que não foi fotografada
(`N/E`); o ícone vem do mesmo `svgIconPath()` medido em 3.2.

### 3.6 Menu Ajuda (`041-menu-ajuda.png`)

| | develop | branch |
|---|---|---|
| "Verificar a versão do QGIS" | presente | **ausente** (perfil reconciliado pelo `Sync-Perfil.ps1`, que escreve a regra) |
| "Página do QGIS" | texto do QGIS | texto do QGIS: **o tradutor não alcança** (§6) |
| "Sobre" | logo do QGIS | logo do QGIS: fica (`BL-1`), e "Sobre o IMAN Terra" ao lado |

> Achado de instrumento: o orquestrador do aceite monta o perfil por **cópia** do template, sem o
> `Sync-Perfil.ps1`, e por isso não escreve o `QGISCUSTOMIZATION3.ini`. A primeira medição do menu
> (sem `-Reconciliar`) mostrou o item de versão; com `-Reconciliar`, que é o caminho do launcher, ele
> sumiu. Toda evidência deste laudo foi tirada com `-Reconciliar`.

### 3.7 Diálogo sem ícone próprio (`041-dialogo-sem-icone-icone-da-janela.png`)

| | develop | branch |
|---|---|---|
| ícone da aplicação | logo do QGIS (semelhança 1,0 com `qgis-icon-60x60.png`) | emblema IMAN (1,0 com o `.ico`) |
| `QDialog` **sem pai** | logo do QGIS (1,0) | **emblema IMAN** (1,0) |

> Achado (medido): um diálogo **filho** da janela principal já mostrava o emblema na develop, porque
> herda o ícone da janela, que o startup troca desde antes. A primeira versão do A16 usava um diálogo
> filho e media a coisa errada; ele passou a usar um diálogo sem pai, que só herda o ícone da
> aplicação. O que o item 3 muda é tudo que não tem a janela principal como pai, e o que nasce antes
> do startup.

### 3.8 Ferramentas de depuração (`041-ferramentas-de-depuracao.png`) e a S46

**medido:** `getThemeIcon('/mIconNetworkLogger.svg')` devolve o arquivo do tema (semelhança 1,0), mas
a aba "Registrador de rede" do painel usa **outro** ícone (0,24 contra o do tema, 0,13 contra o padrão;
`evidencia/s46.json`). Não localizei na interface onde o nome `mIconNetworkLogger.svg` é exibido:
**`N/E`**. O arquivo está no tema, passa na guarda, e não exibe o logo em lugar nenhum que se tenha
visto.

### 3.9 Tema nas Opções (`041-opcoes-pagina-00.png`)

| | develop | branch |
|---|---|---|
| Tema da interface do usuário | `default` (o tema entrava tarde e o combo lia a chave vazia) | **IMAN Terra** |
| "Verificar a versão do QGIS ao iniciar" | presente, marcado | **ausente** (`allowVersionCheck=false`) |
| "Mostrar feed de notícias QGIS" | marcado | **desmarcado** |
| Estilo | Fusion | Fusion: a inferência do R5 de que o QGIS já gravava `qgis/style=fusion` confere (medido nos dois lados) |

---

## 4. Testes

Saídas inteiras em `evidencia/gate/`. Rodados com a árvore commitada: os cinco primeiros no HEAD
`89e6ea2`, o `test-build-preserva-canonico.ps1` em `c7df919` (o código de build não mudou depois), o
`test-reinstalacao.ps1` com o instalador `a447168`.

| teste | resultado |
|---|---|
| `tools/test-tema-qss.ps1` | **6 de 6** |
| `tools/test-theme-icons.ps1` (novo) | **7 de 7** |
| `tools/test-brand-translation.ps1` (novo) | **7 de 7** |
| `tools/test-launcher-manifest.ps1` | **6 de 6** |
| `tools/test-reconciliacao-perfil.ps1` | **10 de 11**: o estado 3 FALHA. **STOP declarado** (§8.1) |
| `tools/test-reinstalacao.ps1 -Instalador <branch>` | 6 etapas, exit 0, 0 sobras (com o efeito colateral da §1.1) |
| `tools/test-build-preserva-canonico.ps1 -Ref HEAD` | **4 de 4 estados** em `c7df919` (a primeira rodada, em `ccc7d32`, falhou: §4.2) |
| aceite `tools/branding-acceptance/Invoke-Aceite.ps1` | branch: **17 PASS, 0 FAIL, 1 N/E** (`M-D11`, manual de sempre); segunda execução **1 de 1**. develop, mesmo instrumento: 13 PASS, **4 FAIL (A14 a A17)**, 1 N/E |

### 4.1 Guarda só vale vista falhando (item 4)

| adulteração | quem reprova | resultado |
|---|---|---|
| V1 `providerQgis.svg` vazio | A2 (transparente a 16 e 24 px) | **reprovado** |
| V2 `mActionHelpSponsors.svg` (o original é `.png`) | A1 (o nome não existe no tema padrão) | **reprovado** |
| V3 `style.qss` cita `@theme_path/icons/mActionZoomIn.svg` | A3 (sem prefixo `qss-` e colide com ícone) | **reprovado** |
| tradutor V1: mensagem `versao-motor` nomeando o produto | o gerador recusa (regra 3) | **reprovado** |
| tradutor V2: texto-fonte com um espaço a mais | T2 (a fonte não existe no `qgis_pt_BR.qm`) | **reprovado** |

As adulterações rodam dentro dos próprios testes, a cada execução (o build também as roda). O tema
padrão é enumerado do recurso `:/images/themes/default/` da árvore: **941 nomes**.

### 4.2 `test-build-preserva-canonico.ps1`: uma regressão minha, achada e corrigida

A primeira rodada (`ccc7d32`) **falhou no estado 4 (exit 9)**: o teste compila de um clone limpo com
`-SemRede`, e o gerador do `.qm` procurava o `lrelease` num cache **dentro** do repo
(`installer/tools`, fora do git), que o clone não tinha. Corrigido em `c7df919`: o cache é da bancada
(`%LOCALAPPDATA%\InstitutoIMAN\build-tools\`). O teste não foi tocado. Rodada sobre o HEAD
corrigido: **estados 4, 1, 2 e 3 PASS** (`evidencia/gate/test-build-preserva-canonico.out`).

### 4.3 Mudança de critério declarada (instrumento novo desta fatia)

O `A16` nasceu medindo um diálogo **filho** da janela principal, que herda o ícone dela (§3.7). Ele
passou a medir um diálogo **sem pai**. Números da develop, antes e depois: aplicação 1,0 com o logo
do QGIS nas duas versões; diálogo 0,28 com o `.ico` IMAN (era o PNG IMAN da janela, herdado) e
depois 1,0 com o logo do QGIS. Na branch, 1,0 com o `.ico` nas duas. Os dois lados do lado a lado
deste laudo foram refeitos com o instrumento final.

---

## 5. Feed, versão e endereços

### 5.1 O feed (item 5, `U-04`), com controle positivo

O registro de rede do QGIS (`QgsNetworkLogger`) **não grava desde o arranque** por padrão (medido: 0
pedidos na develop, onde o feed está ligado). Ele grava com `logNetworkRequests=true` (string em
`qgis_app.dll@0x00a2b0e8`). A medição reabre o mesmo perfil com essa chave e faz, de dentro do
processo, um pedido de **controle** a `https://institutoiman.org.br/`, que tem de aparecer no registro.

| rodada | pedidos registrados | controle no registro |
|---|---|---|
| develop | `GET https://feed.qgis.org/?after=...&lang=pt` | sim |
| branch, template do produto | **nenhum a `feed.qgis.org`** | sim |
| branch, mesmo perfil com `httpsfeedqgisorg\disabled=false` | `GET https://feed.qgis.org/?lang=pt` e uma imagem do feed | sim |

**medido:** a chave derivada da URL desliga o feed (`U-04` respondida), e o instrumento vê o feed
quando ele está ligado. A checagem de versão não aparece em nenhum lado porque o launcher e o
orquestrador passam `--noversioncheck`; as chaves `checkVersion`/`allowVersionCheck` foram medidas
pelo efeito nas Opções (3.9).

### 5.2 O clique em cada endereço da Ajuda (item 6)

Interceptado por `QDesktopServices.setUrlHandler`: nenhum navegador abriu.

| item | develop abriria | branch abriria |
|---|---|---|
| Página do QGIS | `https://qgis.org` | **`https://institutoiman.org.br`** |
| Reportar um problema | `https://qgis.org/resources/support/bug-reporting/` | **`https://institutoiman.org.br`** |
| Precisa de Suporte Comercial? | `https://qgis.org/resources/support/commercial-support/` | **`https://institutoiman.org.br`** |
| Doe para o QGIS | `https://qgis.org/funding/donate/` | `https://qgis.org/funding/donate/` (fica) |
| Envolva-se | `https://qgis.org/community/involve/` | `https://qgis.org/community/involve/` (fica) |
| Membros de Suporte do QGIS | `https://qgis.org/funding/membership/members/` | idem (fica) |

`help/helpSearchPath` segue `https://docs.qgis.org/$qgis_short_version/...` (F1 no manual do QGIS).

> **FLAG (medido):** `institutoiman.org.br` **não existe no DNS público**: `NXDOMAIN` em `8.8.8.8`, e
> `www.institutoiman.org.br` também. O pedido de controle da §5.1 volta com erro 3 (HostNotFound). O
> `D-IMAN-039` item 4 o trata como "o único endereço do produto que existe". A Crew implementou a
> decisão e não a muda; os três itens da Ajuda levam hoje a um endereço que não resolve.

---

## 6. Alcance do tradutor, mensagem a mensagem (`U-05`)

"API" é o que `QCoreApplication.translate` devolve com os dois tradutores instalados; "tela" é o que
o widget mostra onde a mensagem aparece. Medido no build `a447168` (branch) e no `5f7a1cb` (develop).

| L-08 | contexto | texto novo | API develop | API branch | tela branch | alcance |
|---|---|---|---|---|---|---|
| 186 | `QgsNativeAlgorithms` | IMAN Terra (c++ nativo) | antigo | novo | nome do provedor (caixa e Opções): novo | **alcançou** |
| 80 | `Qgs3DAlgorithms` | IMAN Terra (3D) | antigo | novo | nome do provedor: novo | **alcançou** |
| 208 | `QgsPdalAlgorithms` | IMAN Terra (PDAL) | antigo | novo | nome do provedor: novo | **alcançou** |
| 234 | `QgsProcessingFeedback` | Versão do motor: %1 | antigo | novo | log do algoritmo: novo | **alcançou** |
| 233 | `QgsProcessingFeedback` | Revisão do código do motor: %1 | antigo | novo | log do algoritmo: novo | **alcançou** |
| 7 | `MainWindow` | Página do IMAN Terra | antigo | novo | menu Ajuda: **antigo** | **não alcançou** |
| 190 | `QgsOptions` | ...novos projetos criados no IMAN Terra. | antigo | novo | não exibida nas telas exercitadas | alcança na API; tela `N/E` |
| 191 | `QgsOptions` | %1 é o idioma atualmente ativo em seu IMAN Terra | antigo | novo | Opções, Geral: novo | **alcançou** |
| 192 | `QgsOptions` | ...depois que o IMAN Terra for reiniciado. | antigo | novo | só em evento (não exercitado) | alcança na API; tela `N/E` |
| 196 | `QgsOptions` | Necessário reiniciar o IMAN Terra | antigo | novo | Opções, Geral: novo | **alcançou** |
| 197 | `QgsOptionsBase` | ...tem de reiniciar o IMAN Terra | antigo | novo | Opções, Geral: novo | **alcançou** |
| 198 | `QgsOptionsBase` | O suporte a OpenCL do IMAN Terra... | antigo | novo | Opções, Aceleração: novo | **alcançou** |
| 199 | `QgsOptionsBase` | ...reiniciar o IMAN Terra... | antigo | novo | Opções, Rede: novo | **alcançou** |
| 205 | `QgsOptionsBase` | Estilo (necessário o reinício do IMAN Terra) | antigo | novo | Opções, Geral: novo | **alcançou** |
| 206 | `QgsOptionsBase` | ...requer que o IMAN Terra seja reiniciado | antigo | novo | Opções, Aceleração: novo | **alcançou** |
| 211 | `QgsPluginInstaller` | ...nas opções do IMAN Terra. | antigo | novo | só em evento (não exercitado) | alcança na API; tela `N/E` |
| 212 | `QgsPluginInstaller` | ...na janela de opções do IMAN Terra. | antigo | novo | só em evento (não exercitado) | alcança na API; tela `N/E` |
| 215 | `QgsPluginInstaller` | O IMAN Terra detectou um complemento obsoleto... | antigo | novo | só em evento (não exercitado) | alcança na API; tela `N/E` |
| 221 | `QgsPluginManager` | ...disponíveis para o IMAN Terra... | antigo | novo | complementos, aba Tudo (`041-complementos-tudo.png`): **antigo** | **não alcançou** |
| 222 | `QgsPluginManager` | ...instalados no seu IMAN Terra | antigo | novo | complementos, aba Instalados (`041-complementos-instalados.png`): **antigo** | **não alcançou** |

**Resumo:** 13 alcançaram na tela; 3 não alcançaram (7, 221, 222); 4 alcançam na API e só aparecem
em evento que não foi provocado (192, 211, 212, 215) ou não foram achadas nas telas exercitadas (190).
O que não alcançou é texto que o QGIS monta **antes** de o plugin carregar (o menu Ajuda e o
gerenciador de complementos nascem no construtor da janela). Pelo briefing, fica registrado e **não
ganha outro caminho** nesta fatia.

Os controles (Doe, Membros de Suporte, Sobre, repositório oficial, Contribuidores) saem com o texto do
QGIS: `tools/test-brand-translation.ps1`, T5.

---

## 7. Diálogos com o tema desde o arranque (`R5`)

**medido, lado a lado:** Opções, Propriedades da camada e o diálogo de um algoritmo abertos com o tema
ativo desde o arranque.

| diálogo | o que mudou | leitura e affordance |
|---|---|---|
| Opções (`041-opcoes-pagina-00.png`) | o combo de tema mostra "IMAN Terra"; a lista lateral sem mudança visível | intactas |
| Propriedades da camada (`041-propriedades-da-camada.png`) | **a lista lateral passou de escura (padrão do QGIS) para clara** (`QListView` do tema): o `style.qss` pega um diálogo que antes não pegava | intactas: item selecionado destacado, textos legíveis, botões presentes |
| Ferramentas de depuração (`041-ferramentas-de-depuracao.png`) | a coluna de abas passou de escura para clara, pelo mesmo motivo | intactas |
| diálogo do algoritmo (`041-algoritmo-log.png`) | nenhuma mudança de estilo visível | intactas |

Nada quebrou leitura nem affordance, então o STOP de estilo do briefing não disparou e o `style.qss`
**não foi tocado**. O ícone das Propriedades da camada segue o logo do QGIS: é teto (S43, formulário
compilado).

---

## 8. STOP e flags

### 8.1 STOP `P0.10`: `tools/test-reconciliacao-perfil.ps1`, estado 3

**Qual teste:** o estado 3 ("perfil de template anterior ao #022 → tema e plugin novos chegam") exige
que, depois da reconciliação, **todo** arquivo do template seja byte a byte igual no perfil, incluindo
o `QGIS/QGIS3.ini`.
**Qual item do briefing:** 1 (`UITheme` no template, "reconciliado como as outras chaves") e 5 (feed e
versão no template).
**Por quê:** a reconciliação (`DB-26`) mexe só nas **chaves**: não copia comentários e põe uma seção nova
(`[core]`) no fim do arquivo do usuário. Medido sobre o perfil de `ba58d14`: todas as chaves chegam com
o valor certo, e o arquivo difere do template em comentários e ordem. O estado passava só porque o
`.ini` do template não mudava desde `ba58d14` (idênticos, conferido). Reescrever o `.ini` do usuário no
layout do template quebra o R4 (estados 5 e 7); moldar o template ao fixture é moldar o código ao teste.
**Decisão do sponsor (2026-10-22):** seguir, com o teste **intocado** e vermelho, e levar ao arquiteto.

### 8.2 Flags

- **`institutoiman.org.br` não resolve** (§5.2). Decisão de produto do arquiteto.
- **`test-reinstalacao.ps1` reconcilia o perfil real** (§1.1). O teste não foi editado.
- **Instalar uma versão por cima de outra mais nova deixa sobras em `{app}\profile-template`**, e o
  launcher as propaga ao perfil como "do produto" (§1.1, segundo episódio). Vale também para todo
  arquivo que uma versão futura tirar do template: ele nunca sai de quem atualizou.
- **Instrumento:** o orquestrador do aceite sem `-Reconciliar` não escreve o `QGISCUSTOMIZATION3.ini`
  (§3.6), então qualquer regra de customização fica fora do aceite padrão.
- **Mensagens que a regra 3 cobriria e o briefing não listou** (fora do escopo, não trocadas):
  "Sair do QGIS" (`MainWindow`, `QgisApp`), "Você realmente deseja sair do QGIS?", o título "QGIS" no
  contexto `QgisApp`. Ficam para decisão do arquiteto.
- **S46:** o lugar onde o QGIS exibe `mIconNetworkLogger.svg` não foi achado (§3.8).

---

## 9. O que não foi feito aqui

- **VM limpa (`BL-7`): não rodou.** Tudo acima é bancada. A verdade da entrega é a VM, e isso é lacuna
  declarada, não "pronto".
- **Build canônico e release:** fora de escopo (`P0.7`).
- **Gate oficial:** o kind `qgis-distro` ainda não tem comando no `crew_gate.sh`. A proposta vai no
  `/deliver`.
