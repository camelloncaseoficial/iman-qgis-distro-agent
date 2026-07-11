# Assets de marca — IMAN Terra (fonte única de asset, BL-4)

Arte **oficial** do Instituto IMAN. Proveniência: **drop do sponsor em 2026-07-06**, ingerido e
versionado na fatia 002 (`feat/002-branding`). Antes disso os arquivos estavam soltos e *untracked*
em `docs/`; aqui viram a fonte única de asset da distro. Nada de raster de trabalho solto em `docs/`.

> A paleta de marca é derivada **destes** assets (o `splash-iman-terra.svg` é a fonte legível por
> máquina). Os valores travados vivem em `docs/design-system.md` **e** em `brand.py` (BL-4).

> **Re-derivação INTERIM (fatia #005, D-IMAN-026):** o master SVG foi re-derivado para a
> paleta nova + copy REURB/Ceará de forma **determinística** (mapa OLD→NEW por papel, do
> arquiteto), via `derive-interim-palette.py`. **INTERIM** — o `IMAN.cdr`/manual, chegando,
> prevalece. O **símbolo** (`iman-symbol.png`) NÃO foi re-colorido (raster sem master
> vetorial — STOP-AND-FLAG). Créditos do QGIS preservados no splash (BL-1/BL-2).

## Masters (arte-fonte)

| Arquivo | O que é |
|---|---|
| `splash-iman-terra.svg` | **Master vetorial** do splash (1000×480), SVG-texto. Fonte da paleta. Re-derivável INTERIM por script (acima); sobreponível pelo `IMAN.cdr`. |
| `iman-symbol.png` | **Símbolo** oficial (folha + globo), transparente. Master dos ícones. **Não re-colorido** (sem master vetorial). |
| `logo-iman.png` | Logo institucional (arte própria IMAN). |
| `backgrounds/bg-iman-branco.jpeg` | Fundo institucional claro. |
| `backgrounds/bg-iman-verde.jpeg` | Fundo institucional verde. |

## Derivados reprodutíveis (regeráveis a partir dos masters)

| Arquivo | Como é gerado | Uso |
|---|---|---|
| `splash-iman-terra.png` | **rasterizado do master SVG via QtSvg** (`rasterize-splash.py`, plataforma 'windows' p/ fontes), 1000×480 | **splash NATIVO de boot** (customização, no-fork) + banner do dock |
| `icon-iman-terra.ico` | símbolo → quadrado + respiro 10% → ICO 16/24/32/48/64/128/256, **transparente** | atalho / `SetupIconFile` / `UninstallDisplayIcon` |
| `icon-iman-terra.png` | símbolo → 512×512, transparente | ícone da janela (startup) |
| `wizard-large.png` | símbolo sobre `brand` (#103D29, paleta nova), 410×797 (`regenerate-brand-derivatives.py`) | `WizardImageFile` (Inno) |
| `wizard-small.png` | símbolo sobre neutro claro (#EBEEE8), 138×140 (`regenerate-brand-derivatives.py`) | `WizardSmallImageFile` (Inno) |
| `../profile-template/iman-distro/python/plugins/iman_brand/resources/icon.png` | símbolo → 256×256 | ícone do plugin/toolbar/Sobre |
| `../profile-template/iman-distro/python/plugins/iman_brand/resources/splash.png` | splash → 760×365 | banner do dock de boas-vindas |

**Regeneração:** os derivados são produzidos a partir dos masters com Pillow (PIL disponível no
`python` do sistema — ver `.memory/reference_build_environment.md`). O `.ico` é multi-resolução e
**transparente** (a fatia 1 corrigiu o quadrado branco; manter). Se um master oficial for atualizado,
regenerar os derivados a partir dele — não editar os derivados à mão.

## Limite honesto (BL-5)

**Atualização (spikes #004/#005):** o **splash nativo de boot É no-fork** — o QGIS renderiza
`QgsCustomization::splashPath()+"splash.png"`, apontado pela customização do perfil
(`QGISCUSTOMIZATION3.ini`, escrito pelo launcher) para o `splash.png` do perfil. Não é hack/
2º-splash: é o próprio `QSplashScreen` nativo com o asset IMAN. Assim `splash-iman-terra.png`
entra como **splash nativo de boot** (fatia #005), banner do dock e wizard do instalador.
Limites que sobram para a Opção 2 (fork), de baixo valor (spike #004): **ícone do arquivo
`qgis-bin.exe`** (só num QGIS bundlado) e **nome interno** — o About tem substituto próprio
no-fork (mantendo o About nativo).
