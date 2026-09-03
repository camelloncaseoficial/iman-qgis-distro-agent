# Design System — IMAN QGIS Distro (tokens de marca)

**Fonte única de marca** (BL-4). Todo texto/asset de marca visível referencia este doc + as
constantes do plugin/perfil. Renomear o produto ou trocar a paleta deve ser find-replace aqui,
não caça a strings espalhadas.

## Nome de produto (DEFINIDO — sponsor, 2026-07-05)

| Token | Valor |
|---|---|
| `PRODUCT_NAME` | `IMAN Terra` |
| `PRODUCT_SUBTITLE` | `Uma experiência geoespacial customizada, powered by QGIS.` |
| `WINDOW_TITLE` | `IMAN Terra — powered by QGIS` |
| `PUBLISHER` | `Instituto IMAN` |

> **Esta tabela é a fonte única do nome** (BL-4). Qualquer troca futura atualiza só aqui + as
> constantes que a espelham. A lista **completa** de superfícies que espelham `PRODUCT_NAME`
> (código, `.iss`, `.bat`, prosa dos notices e **nomes de arquivo**) está em
> **[`docs/RENAME_CHECKLIST.md`](RENAME_CHECKLIST.md)** — um rename futuro é find-replace guiado por lá.
> `IMAN Terra` venceu `IMAN GIS` após `/critique` + `/signature-experience` (nomeia a promessa
> territorial, não a engrenagem; "powered by QGIS" credita o motor). Ver D-IMAN-025.

## Cores — paleta IMAN Terra (redesign D-IMAN-026 · ATIVA · 2026-07-11)

**Fonte única da identidade em vigor** (BL-4). Decidida em **D-IMAN-026** a partir do
redesign da janela principal (`docs/TerraWindow.dc.html` + `docs/IMAN Terra.dc.html`,
drop do sponsor 2026-07-10). **Supera, valor a valor,** a paleta que o gate #002 travou do
`splash-iman-terra.svg` (logo abaixo, marcada OBSOLETA). O espelho desta tabela em código,
para as UIs do **spike #003**, é `spike/003-frameless-dashboard/tokens.py` (as duas fontes
batem — BL-4).

### Tema claro (institucional)

| Token | Hex | Uso |
|---|---|---|
| `brand` | `#103D29` | verde profundo — chrome (title bar / status bar) |
| `brand-2` | `#1E7A4D` | verde institucional — marca / estado ativo |
| `accent` | `#2B8FD6` | azul dados / água — acento, links, raster |
| `moss` | `#6E9160` | verde musgo — apoio |
| `earth` | `#8A7A55` | terra — terroso (símbolos de limite) |
| `bg` | `#EBEEE8` | base neutra da área de trabalho |
| `panel` | `#FFFFFF` | painel / cartão |
| `panel-2` | `#F5F7F2` | painel secundário / campo |
| `border` | `#E2E5DE` | borda |
| `border-strong` | `#D0D5C9` | borda forte / handle de scrollbar / campo da status bar |
| `border-accent` | `#CFE0D2` | borda de realce suave (hover de botão de toolbar) |
| `text` | `#1A231D` | texto principal |
| `text-muted` | `#5E6A61` | texto secundário |
| `text-faint` | `#95A093` | texto terciário / meta |
| `hover` | `#EFF2EC` | hover neutro |
| `active-bg` | `#E4F0E8` | fundo de item ativo |
| `active-fg` | `#155F3D` | texto de item ativo |
| `chrome` / `chrome-fg` | `#103D29` / `#EAF3EC` | verde profundo + texto sobre ele — **chrome NATIVA da Opção 2** e acento do diálogo "Sobre" (no no-fork **não** pinta mais a chrome do QSS — ver nota "chrome clara" abaixo) |

> **Chrome CLARA (suavização · sponsor, 2026-07-15).** A passada dark-chrome da fatia #006
> pintava toda a chrome do QSS (barra de menus, barra de status, títulos de dock, headers de
> tabela, tooltip) com o verde profundo `#103D29` — cansava a vista em sessão longa. Por decisão
> do sponsor, o QSS `app/profile-template/iman-distro/QGIS/iman-theme.qss` passou a **light-chrome**:
> essas superfícies agora são claras (`panel`/`panel-2`) com texto escuro, e o verde institucional
> (`#1E7A4D` / `active-fg #155F3D`) fica como **acento** (seleção, item ativo, sublinhado de aba,
> botão default, foco, borda de tooltip). **A paleta/identidade D-IMAN-026 não muda** — muda só
> *quais* superfícies recebem o verde escuro. O token `chrome`/`#103D29` permanece vivo para a
> chrome **nativa** da Opção 2 (fork) e para acentos pequenos (cabeçalho do diálogo "Sobre").

> **Zero hex órfão (BL-4).** Todo hexadecimal usado em
> `app/profile-template/iman-distro/QGIS/iman-theme.qss` precisa existir como token **nesta
> tabela E em `brand.py`**. Hex solto no QSS foi exatamente o mecanismo que produziu **três
> fontes de marca em desacordo** na fatia 002. A passada dark-chrome do #006 tinha criado seis
> (`#0B2C1E`, `#0F3021`, `#2C5A45`, `#C6D3C2`, `#CFE0D2`, `#CFE3D6`): quatro eram derivados da
> chrome escura e **morreram com a suavização**; `border-strong` absorveu o tom de scrollbar
> (a tabela já prometia esse papel — quem tinha divergido era o QSS) e `border-accent` foi
> **promovido a token nomeado**. Ao mexer no QSS, reconferir a varredura.

### Tema escuro (trabalho prolongado / imagem de satélite)

| Token | Hex |  | Token | Hex |
|---|---|---|---|---|
| `bg` | `#0E1A14` |  | `text` | `#E7EEE9` |
| `panel` | `#15241D` |  | `text-muted` | `#93A69B` |
| `panel-2` | `#111F19` |  | `text-faint` | `#617468` |
| `border` | `#243830` |  | `brand-2` | `#3DA76B` |
| `border-strong` | `#2E463A` |  | `accent` | `#4BA3DC` |
| `chrome` | `#0A2016` |  | `moss` | `#7FA271` |

> **`mint` e `warm`/terracota SAÍRAM** da identidade — não têm equivalente no comp;
> reintroduzir só com nova arte que os justifique (D-IMAN-026).

> **Fonte / ícones / CRS do redesign:** fonte do **SISTEMA** (o comp puxa Google Fonts —
> fere local-first; no MVP não se bundla fonte); iconografia própria da **fatia #008** (o
> comp usa traços placeholder); CRS **SIRGAS 2000 / UTM** (EPSG:31984 no Ceará), **nunca
> EPSG:4326** (o comp mostra 4326, impróprio p/ área/cadastro).

> **Estado de implementação (PROMOVIDA na fatia #005, `feat/003-identidade-nofork`):** esta
> paleta agora é a de **produção**. `brand.py` (`COLOR_*`), o QSS
> `app/profile-template/iman-distro/QGIS/iman-theme.qss` e as UIs do plugin foram promovidos;
> a arte de `app/assets/` foi **RE-DERIVADA** para esta paleta (splash re-rasterizado +
> copy REURB/Ceará; wizard/banner na paleta nova) — **deixa de ser STALE**. Reprodutível por
> `app/assets/derive-interim-palette.py` + `rasterize-splash.py` + `regenerate-brand-derivatives.py`.
> **INTERIM (STOP-AND-FLAG):** o mapa OLD→NEW é do arquiteto (D-IMAN-026); o **símbolo**
> (`iman-symbol.png`, raster sem master vetorial) **não** foi re-colorido — espera o `IMAN.cdr`,
> que, chegando, **prevalece** sobre tudo (autoridade final, regra abaixo permanece viva).

## Cores — paleta 002 (OBSOLETA · superada por D-IMAN-026 · mantida como registro)

> ⚠️ **OBSOLETA (D-IMAN-026, 2026-07-11).** Esta é a paleta travada no gate #002; o sponsor
> a substituiu pela paleta do redesign (acima). Desde a **fatia #005**, `brand.py`, o QSS e
> a arte de `app/assets/` **já NÃO a usam** (foram promovidos/re-derivados). Mantida só como
> registro histórico dos valores antigos.

Extraída **diretamente** do master vetorial oficial `app/assets/splash-iman-terra.svg`
(drop do sponsor 2026-07-06). Esta tabela **é idêntica**, valor a valor, às constantes
`COLOR_*` de `brand.py` (BL-4) — as duas fontes têm de bater. Colapsa as três fontes que
antes divergiam (o placeholder genérico da fatia 0, a amostra de JPEG da fatia 1 e a arte
oficial) numa só, ancorada na arte oficial.

| Token | `brand.py` | Uso | Hex | Origem |
|---|---|---|---|---|
| `brand.primary` | `COLOR_PRIMARY` | verde-marca / destaque | `#00A85A` | SVG oficial |
| `brand.primary-deep` | `COLOR_PRIMARY_DEEP` | verde de apoio / chrome escura | `#0D5138` | SVG oficial |
| `brand.ink` | `COLOR_INK` | verde quase-preto / fundos escuros do splash | `#041C16` | SVG oficial |
| `brand.accent` | `COLOR_ACCENT` | azul do globo / ação / links | `#2CA8E0` | SVG oficial |
| `brand.mint` | `COLOR_MINT` | realce / highlight | `#5FE0A0` | SVG oficial |
| `brand.warm` | `COLOR_WARM` | accent quente (terracota) | `#C56A2F` | SVG oficial |
| `brand.surface` | `COLOR_SURFACE` | fundo de painel claro | `#F2F8F3` | SVG oficial |
| `brand.text` | `COLOR_TEXT` | texto principal sobre claro | `#041C16` | SVG oficial (wordmark; = `ink`) |

> `COLOR_SECONDARY` permanece em código como **alias** de `COLOR_PRIMARY_DEEP` (compat.).
>
> **Tints funcionais** do tema QSS (hover/linha-alternada/bordas — ex.: `#CFE6D8`, `#E8F3EC`,
> `#CDE9D8`, `#A9DCBF`) são **derivados** dos verdes acima para estados de UI; não são cor de
> identidade. `#CFE6D8` consta na própria arte; os demais são tints neutros.
>
> **STOP-AND-FLAG (autoridade final):** o SVG é arte **derivada** (splash), não o manual de
> marca. Se/quando o `IMAN.cdr`/manual oficial chegar, ele **prevalece** — travar o que temos,
> sem inventar cores fora da arte. O `brand.text` foi reconciliado para `#041C16` (wordmark real
> do SVG); o `#0F1F18` proposto no briefing 002 **não consta** na arte, então fica o valor de fato.
> Legibilidade/contraste sobre os verdes reais verificados na fatia 002 (notas no PR).

## Assets (em `app/assets/` — fonte única de asset, BL-4)

Arte **oficial** do drop do sponsor (2026-07-06). O **master** de cada peça é o vetor/símbolo
oficial; os rasters são derivados reprodutíveis (ver `app/assets/README.md` para proveniência e
receita de regeneração). Nada de raster de trabalho solto em `docs/`.

- `splash-iman-terra.svg` — **master vetorial** do splash (fonte legível por máquina da paleta).
- `splash-iman-terra.png` — splash rasterizado 1000×480 (banner do dock do plugin + wizard do instalador).
- `iman-symbol.png` — símbolo oficial (folha + globo), transparente — master dos ícones.
- `icon-iman-terra.png` / `icon-iman-terra.ico` — ícone do atalho/instalador, **regerado do símbolo
  oficial**: transparente, multi-resolução (16/24/32/48/64/128/256).
- `wizard-large.png` / `wizard-small.png` — imagens do wizard do instalador Inno: o grande
  traz o símbolo sobre `brand` (`#103D29`); o pequeno tem **fundo transparente** (alfa real).

> **O logo do wizard não carrega cor de fundo (`D-IMAN-028`/DB-21, 2026-09-03).** O `wizard-small.png`
> era RGB sem alfa, com `#EBEEE8` cravado nos pixels, e isso aparecia como uma **chapa cinza**
> atrás do logo em toda página interna do instalador. A página do wizard é `clWindow` — cor do
> **tema do Windows**, medida em `#FFFFFF` num build real — e `#FFFFFF` **não é token desta paleta**.
> Repintar o PNG com a cor da página só mudaria a chapa de lugar no próximo tema; por isso o fundo
> saiu do arquivo e virou **alfa**, com `WizardImageAlphaFormat=defined` no `.iss`. Evidência
> antes/depois em `docs/verify/015-db21-wizard/`.
- `logo-iman.png` — logo institucional (arte própria IMAN).
- `backgrounds/bg-iman-branco.jpeg` / `backgrounds/bg-iman-verde.jpeg` — fundos institucionais oficiais.

> Cópias no plugin em `.../iman_brand/resources/`: `icon.png` (símbolo) e `splash.png` (banner do dock).
>
> **Splash nativo de boot = Opção 2 (fork).** O `splash-iman-terra.svg` é o asset que a Opção 2 fiará
> como splash nativo do QGIS (DA-2). No no-fork ele é usado **só** onde é honesto (banner do dock,
> wizard do instalador); **nenhum** splash nativo é forjado (BL-5).

## Tipografia & espaçamento

- Tipografia: fontes do sistema (sem dependência externa no MVP).
- Espaçamento base: 4 / 8 / 12 / 16.

## Limite honesto

Este design system governa o que o **no-fork** alcança (tema QSS, plugin, título, ícone de atalho/
instalador). Splash nativo, ícone do executável, About e nome interno → Opção 2 (ver
`docs/distro-architecture.md`).

**Spike #003 (D-IMAN-026) — árbitro do BL-5, arqueado por evidência em
`spike/003-frameless-dashboard/REPORT.md`:**
- **Title bar frameless de marca → só Opção 2 (fork).** O `FramelessWindowHint` sozinho é
  estável, mas é inerte; a única forma no-fork de hospedar uma barra de marca acima do menu
  (`setMenuWidget`, reparentando o `menuBar` do QGIS) **corrompe o teardown e crasha** com
  access violation (0xC0000005). BL-5 proíbe shippar o hack.
- **Dashboard/home no MIOLO → SHIPPADO no-fork (fatia #006).** `takeCentralWidget` +
  `QStackedWidget([canvas, home])` no plugin `iman_brand`: ciclo home→canvas→home sem
  tela-fantasma (3 estados verificados pelo launcher, `mode='central'`, exit 0). Guardrail
  defensivo: se um terceiro reivindicar o central widget, cai para o DOCK — **não** re-embrulha
  (re-embrulhar por cima de um canvas já deletado corrompe o heap; o dock é a recuperação segura).
- **Home como DOCK do plugin de marca → robusto no-fork (rede de segurança / fallback declarado).**
