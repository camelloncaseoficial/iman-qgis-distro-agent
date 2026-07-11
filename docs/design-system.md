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

## Cores (amostradas do logo IMAN real — provisórias até o manual de marca)

| Token | Uso | Valor | Origem |
|---|---|---|---|
| `brand.primary` | Marca / destaque | `#00A858` | verde IMAN amostrado de `docs/IMAN_fundo_branco.jpeg` |
| `brand.secondary` | Apoio | `#00753D` | derivado (verde escuro) |
| `brand.accent` | Ação / links | `#1C86C9` | azul do globo do emblema (amostrado) |
| `brand.surface` | Fundo de painel | `#F4F8F5` | verde muito claro |
| `brand.text` | Texto principal | `#14231C` | quase preto esverdeado |

> **STOP-AND-FLAG:** estes valores foram **amostrados da arte do logo** presente no repo — são
> mais fiéis que os placeholders antigos (`#1F6F5C`), mas o **hex exato e a paleta completa oficiais**
> ainda dependem do manual de marca do Instituto (`IMAN.cdr`) e entram na fatia `/branding`.
> Espelhados em código por `brand.py` (constantes `COLOR_*`) — fonte única (BL-4).

## Assets (em `app/assets/`)

Gerados a partir da **arte institucional real** do IMAN presente no repo (`docs/IMAN_*.jpeg`,
`docs/Splash.png`) — não são placeholders genéricos:

- `logo-iman.png` — logo institucional (arte própria IMAN).
- `icon-iman-terra.png` / `icon-iman-terra.ico` — ícone do atalho/instalador (emblema folha+globo,
  multi-resolução: 16/24/32/48/64/128/256).
- `splash-preview.png` — preview de splash (arte que já credita o QGIS; splash **nativo** só na Opção 2).

> Cópias em `app/profile-template/iman-distro/python/plugins/iman_brand/resources/` (icon/logo do plugin).

## Tipografia & espaçamento

- Tipografia: fontes do sistema (sem dependência externa no MVP).
- Espaçamento base: 4 / 8 / 12 / 16.

## Limite honesto

Este design system governa o que o **no-fork** alcança (tema QSS, plugin, título, ícone de atalho/
instalador). Splash nativo, ícone do executável, About e nome interno → Opção 2 (ver
`docs/distro-architecture.md`).
