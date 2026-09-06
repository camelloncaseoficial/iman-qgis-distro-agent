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
| `iman-symbol.png` | **Símbolo** oficial (folha + globo), 512×512 transparente. Master dos ícones. **Não re-colorido** (sem master vetorial). Proveniência: **`docs/icons/android-chrome-512x512.png`**, do favicon set oficial do Instituto IMAN — ver nota abaixo. |
| `logo-iman.png` | Logo institucional (arte própria IMAN). |
| `backgrounds/bg-iman-branco.jpeg` | Fundo institucional claro. |
| `backgrounds/bg-iman-verde.jpeg` | Fundo institucional verde. |

> **Re-ancoragem do símbolo (2026-07-22).** O `iman-symbol.png` anterior (411×333) era um recorte
> **defeituoso**: o globo estava **cortado reto** na borda inferior e na direita — a esfera perdia o
> arco. Como ele é o master de **todos** os ícones, o defeito propagou para o ícone da janela/taskbar,
> o `SetupIconFile`/`UninstallDisplayIcon`, os dois atalhos, o ícone do plugin e os wizards do
> instalador. O master passou a ser a arte **oficial** do favicon set do Instituto IMAN
> (`docs/icons/android-chrome-512x512.png`, 512×512 transparente), onde o globo é inteiro e com
> respiro. Os derivados foram regerados por script; **nenhuma cor foi alterada** (o STOP-AND-FLAG do
> `IMAN.cdr` segue de pé).
>
> **Duas consequências que precisam ser decididas por quem manda na marca, não pela crew:**
> 1. A arte oficial traz um **contorno branco** em volta de toda a forma (tratamento de favicon,
>    feito para assentar sobre qualquer fundo). Sobre o verde `brand` do `wizard-large` ele fica
>    **visível e marcante** — é uma mudança de aparência, não só a correção do corte.
> 2. O **`splash-iman-terra.png` commitado está dessincronizado do próprio master** — ver a
>    armadilha logo abaixo. Hoje: ícones com o globo inteiro, splash com o globo cortado.

> ### ⚠️ Armadilha conhecida: o splash **não** tem master próprio de símbolo
>
> O `splash-iman-terra.svg` **referencia o `iman-symbol.png`** em duas tags `<image>`:
>
> | Linha | Caixa | Proporção |
> |---|---|---|
> | 43 | `785.7 × 660` (marca d'água, `opacity 0.10`) | 1,1905:1 |
> | 82 | `128.6 × 108` (símbolo ao lado do wordmark) | 1,1907:1 |
>
> As caixas foram dimensionadas para o master **antigo** (411×333 = **1,2342:1**). O master agora é
> **1:1**. Nenhuma das duas tags declara `preserveAspectRatio`, então vale o default
> **`xMidYMid meet`**: a imagem é encaixada **preservando o aspect** e centralizada — não é
> esticada. O efeito prático de re-rasterizar hoje, portanto, **não é distorção e sim mudança de
> escala e posição**: um símbolo 1:1 dentro de uma caixa 1,19:1 passa a ser limitado pela **altura**,
> ficando mais estreito e com folga lateral.
>
> Consequência: **o `splash-iman-terra.png` commitado já não é o que o SVG produziria hoje.** Ele foi
> rasterizado quando o master era o recortado. Isso é dívida registrada, **não** foi tocada nesta
> fatia (splash está fora do escopo) e **não** se resolve rodando `rasterize-splash.py` sem antes
> corrigir as caixas.
>
> **Fatia de reconciliação (a fazer):** recalcular as duas caixas para 1:1 — decidindo se a âncora é
> a largura ou a altura em cada uso — e **re-rasterizar com o python do QGIS**
> (`C:\Program Files\QGIS 3.44.9\bin\python-qgis-ltr.bat app\assets\rasterize-splash.py`, que usa
> QtSvg; ver `.memory/reference_build_environment.md`). Enquanto isso não acontecer, **não**
> re-rasterizar o splash.

## Derivados reprodutíveis (regeráveis a partir dos masters)

| Arquivo | Como é gerado | Uso |
|---|---|---|
| `splash-iman-terra.png` | **rasterizado do master SVG via QtSvg** (`rasterize-splash.py`, plataforma 'windows' p/ fontes), 1000×480 | **splash NATIVO de boot** (customização, no-fork) + banner do dock |
| `icon-iman-terra.ico` | símbolo → ICO 16/24/32/48/64/128/256, **transparente**, **sem respiro extra** (`regenerate-icons.py`) | atalho / `SetupIconFile` / `UninstallDisplayIcon` |
| `icon-iman-terra.png` | símbolo → 512×512, transparente (`regenerate-icons.py`) | ícone da janela (startup) |
| `wizard-large.png` | símbolo sobre `brand` (#103D29, paleta nova), 410×797 (`regenerate-brand-derivatives.py`) | `WizardImageFile` (Inno) |
| `wizard-small.png` | símbolo sobre **fundo transparente** (alfa real, RGBA), 138×140 (`regenerate-brand-derivatives.py`) | `WizardSmallImageFile` (Inno), com `WizardImageAlphaFormat=defined` |
| `../profile-template/iman-distro/python/plugins/iman_brand/resources/icon.png` | símbolo → 256×256 (`regenerate-icons.py`) | ícone do plugin/toolbar/Sobre |
| `../profile-template/iman-distro/python/plugins/iman_brand/resources/splash.png` | splash → 760×365 | banner do dock de boas-vindas |

**Regeneração:** os derivados são produzidos a partir dos masters com Pillow (PIL disponível no
`python` do sistema — ver `.memory/reference_build_environment.md`). O `.ico` é multi-resolução e
**transparente** (a fatia 1 corrigiu o quadrado branco; manter). Se um master oficial for atualizado,
regenerar os derivados a partir dele — não editar os derivados à mão.

```
python app/assets/regenerate-icons.py             # ícones (a partir de iman-symbol.png)
python app/assets/regenerate-brand-derivatives.py # wizards + banner do dock
```

> **Por que o `.ico` deixou de ter "respiro 10%" — e o que isso custa.**
>
> Medição real das margens (`alpha > 128`):
>
> | | L | T | R | B |
> |---|---|---|---|---|
> | **master oficial** (`iman-symbol.png`) | 0,2% | 0,2% | 0,2% | **0,0%** |
> | derivado `.ico` **anterior** | 9,2% | 17,0% | 9,2% | 17,0% |
>
> A arte oficial **encosta na borda inferior** — há **13 pixels opacos na última linha**. O contorno
> branco dela é **tinta opaca, não margem de tela**: lê como respiro sobre fundo claro e **some**
> sobre fundo escuro. *(Uma versão anterior desta nota afirmava que o master "já vem com margem
> embutida". Era **falso** — a medição acima desmente.)*
>
> Com `RESPIRO = 0` o resultado é um ícone **edge-to-edge**: ele **renderiza maior que os vizinhos**
> na barra de tarefas e no Menu Iniciar, e com a **base tangente à borda**. Isso é escolha
> deliberada, não propriedade da arte — em 16×16 o desenho maior leu melhor que a alternativa com
> 8% de respiro (`docs/verify/007-simbolo-oficial/02-piramide-ico.png`).
>
> **A comparação foi em PNG ampliado, não na barra de tarefas real.** Então a decisão é **empírica e
> provisória**, com **gate no 16×16 real durante o BL-7**: se o ícone ficar desproporcional ao lado
> dos vizinhos, subir `RESPIRO` para ~8% em `regenerate-icons.py` e regerar — é um número, não uma
> refatoração.

## Limite honesto (BL-5)

**Atualização (spikes #004/#005):** o **splash nativo de boot É no-fork** — o QGIS renderiza
`QgsCustomization::splashPath()+"splash.png"`, apontado pela customização do perfil
(`QGISCUSTOMIZATION3.ini`, escrito pelo launcher) para o `splash.png` do perfil. Não é hack/
2º-splash: é o próprio `QSplashScreen` nativo com o asset IMAN. Assim `splash-iman-terra.png`
entra como **splash nativo de boot** (fatia #005), banner do dock e wizard do instalador.
Limites que sobram para a Opção 2 (fork), de baixo valor (spike #004): **ícone do arquivo
`qgis-bin.exe`** (só num QGIS bundlado) e **nome interno** — o About tem substituto próprio
no-fork (mantendo o About nativo).
