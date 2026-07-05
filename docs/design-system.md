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
> constantes que a espelham (plugin `metadata.txt`/about, startup, `.iss`, notices).
> `IMAN Terra` venceu `IMAN GIS` após `/critique` + `/signature-experience` (nomeia a promessa
> territorial, não a engrenagem; "powered by QGIS" credita o motor). Ver D-IMAN-025.

## Cores (placeholders — substituir pela paleta oficial do IMAN)

| Token | Uso | Placeholder |
|---|---|---|
| `brand.primary` | Marca / destaque | `#1F6F5C` |
| `brand.secondary` | Apoio | `#0E3D34` |
| `brand.accent` | Ação / links | `#E4A11B` |
| `brand.surface` | Fundo de painel | `#F5F7F6` |
| `brand.text` | Texto principal | `#1A2422` |

> A paleta oficial do IMAN entra na primeira fatia de `/branding` (fonte: `IMAN.cdr`/manual de marca).
> Enquanto isso, os placeholders permitem montar o tema sem travar a fatia.

## Assets (em `app/assets/`)

- `logo-iman.svg` — logo institucional.
- `icon-<produto>.ico` — ícone do atalho/instalador (multi-resolução).
- `splash-preview.png` — preview de splash (nativo só na Opção 2).

## Tipografia & espaçamento

- Tipografia: fontes do sistema (sem dependência externa no MVP).
- Espaçamento base: 4 / 8 / 12 / 16.

## Limite honesto

Este design system governa o que o **no-fork** alcança (tema QSS, plugin, título, ícone de atalho/
instalador). Splash nativo, ícone do executável, About e nome interno → Opção 2 (ver
`docs/distro-architecture.md`).
