# Assets de marca — IMAN Terra (fonte única de asset, BL-4)

Arte **oficial** do Instituto IMAN. Proveniência: **drop do sponsor em 2026-07-06**, ingerido e
versionado na fatia 002 (`feat/002-branding`). Antes disso os arquivos estavam soltos e *untracked*
em `docs/`; aqui viram a fonte única de asset da distro. Nada de raster de trabalho solto em `docs/`.

> A paleta de marca é derivada **destes** assets (o `splash-iman-terra.svg` é a fonte legível por
> máquina). Os valores travados vivem em `docs/design-system.md` **e** em `brand.py` (BL-4).

## Masters (arte-fonte — não editar sem novo drop oficial)

| Arquivo | O que é |
|---|---|
| `splash-iman-terra.svg` | **Master vetorial** do splash oficial (1000×480). Fonte da paleta. |
| `iman-symbol.png` | **Símbolo** oficial (folha + globo), fundo transparente. Master dos ícones. |
| `logo-iman.png` | Logo institucional (arte própria IMAN). |
| `backgrounds/bg-iman-branco.jpeg` | Fundo institucional claro. |
| `backgrounds/bg-iman-verde.jpeg` | Fundo institucional verde. |

## Derivados reprodutíveis (regeráveis a partir dos masters)

| Arquivo | Como é gerado | Uso |
|---|---|---|
| `splash-iman-terra.png` | raster oficial → 1000×480 (LANCZOS) | banner do dock + wizard do instalador |
| `icon-iman-terra.ico` | símbolo → quadrado + respiro 10% → ICO 16/24/32/48/64/128/256, **transparente** | atalho / `SetupIconFile` / `UninstallDisplayIcon` |
| `icon-iman-terra.png` | símbolo → 512×512, transparente | ícone da janela (startup) |
| `wizard-large.png` | símbolo sobre `brand.primary-deep` (#0D5138), 410×797 | `WizardImageFile` (Inno) |
| `wizard-small.png` | símbolo sobre fundo claro, 138×140 | `WizardSmallImageFile` (Inno) |
| `../profile-template/iman-distro/python/plugins/iman_brand/resources/icon.png` | símbolo → 256×256 | ícone do plugin/toolbar/Sobre |
| `../profile-template/iman-distro/python/plugins/iman_brand/resources/splash.png` | splash → 760×365 | banner do dock de boas-vindas |

**Regeneração:** os derivados são produzidos a partir dos masters com Pillow (PIL disponível no
`python` do sistema — ver `.memory/reference_build_environment.md`). O `.ico` é multi-resolução e
**transparente** (a fatia 1 corrigiu o quadrado branco; manter). Se um master oficial for atualizado,
regenerar os derivados a partir dele — não editar os derivados à mão.

## Limite honesto (BL-5)

O `splash-iman-terra.svg` é o asset que a **Opção 2 (fork)** fiará como **splash nativo de boot** do
QGIS (DA-2). No no-fork (Opção 1), a arte oficial entra **só** onde é honesto — banner do dock do
plugin e imagens do wizard do instalador. **Nenhum** splash nativo é forjado, nem há 2º-splash
pós-load (removido na fatia 1). Ícone do executável `qgis-bin.exe`, About nativo e nome interno
seguem como limites da Opção 2.
