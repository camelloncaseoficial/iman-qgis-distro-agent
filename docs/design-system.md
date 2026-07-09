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

## Cores (paleta oficial travada — reconciliada do master vetorial, 2026-07-07)

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
- `wizard-large.png` / `wizard-small.png` — imagens do wizard do instalador Inno (símbolo sobre
  `brand.primary-deep` / fundo claro).
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
