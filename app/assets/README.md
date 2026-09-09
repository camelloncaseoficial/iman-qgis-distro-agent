# Assets de marca — IMAN Terra (fonte única de asset, BL-4)

Arte **oficial** do Instituto IMAN. Proveniência: **drop do sponsor em 2026-07-06**, ingerido e
versionado na fatia 002 (`feat/002-branding`). Antes disso os arquivos estavam soltos e *untracked*
em `docs/`; aqui viram a fonte única de asset da distro. Nada de raster de trabalho solto em `docs/`.

> A paleta de marca é derivada **destes** assets (o `splash-iman-terra.svg` é a fonte legível por
> máquina). Os valores travados vivem em `docs/design-system.md` **e** em `brand.py` (BL-4).

> **~~Re-derivação INTERIM (fatia #005, D-IMAN-026)~~ — SUPERADA em 2026-09-09.** O master SVG
> tinha sido re-derivado por script (`derive-interim-palette.py`) e era declarado **INTERIM**,
> com a regra "o `IMAN.cdr`, chegando, prevalece".
>
> ### ✅ A ARTE OFICIAL CHEGOU (2026-09-09, drop do sponsor, ingerida na fatia `#021`)
>
> ⚠ **CORREÇÃO DE PROCEDÊNCIA (`#022`).** Este bloco dizia que a fonte era o `IMAN.cdr`. **Não é**, e
> o erro tem consequência: o sponsor leu "IMAN.cdr" e concluiu que a arte nova tinha sido ignorada.
> Medido pelo arquiteto e reconferido nesta bancada (`E.5`):
>
> | | |
> |---|---|
> | `IMAN.cdr` | **2025-06-30**, 7,16 MB — **não é a fonte** |
> | fonte real | **`IMAN Terra.cdr`** (2026-09-09 05:03) e **`IMAN Terra.svg`** (05:04) |
> | prova | `IMAN Terra.svg` e o `splash-iman-terra.svg` commitado têm o **mesmo MD5**, `32a43bb2b8babae2d0868b89f27cfbe7`, e os mesmos **104.557 bytes** |
>
> O artefato sempre esteve certo; o **registro** dele é que estava errado — e é assim que um acerto
> parece omissão. É a classe do `P0.8`: procedência se declara pelo que o sistema mostra, não pelo
> nome que a gente lembra.
>
> `splash-iman-terra.svg` é o **export do CorelDRAW 2021** de `IMAN Terra.cdr`, e
> `splash-iman-terra-master.png` (3128×1504) é o raster que o próprio Corel exportou. Os dois são
> **masters**; tudo que é 1000×480 ou menor é derivado deles.
>
> **A paleta NÃO mudou, e isso foi medido, não presumido.** Das 18 cores distintas da arte nova,
> **8 são token exato** de `brand.py` — `#0E1A14` `ink`, `#82D3A6` `mint`, `#EBEEE8` `bg`,
> `#8A7A55` `warm`/`earth`, `#2B8FD6` `accent`, `#E4F0E8` `active-bg`, `#1E7A4D` `primary`,
> `#103D29` `primary-deep`. As 10 restantes são **cor de emblema e de degradê de fundo**
> (`#00A85A` `#00AFF0` `#5AA832` `#059452` `#58AD55` `#ACC658` do símbolo folha+globo;
> `#6E5E3F` e `#F5F1E8` da faixa; `#0F3021` e `#0E2219` do `bgGrad`), que **nunca foram token
> de UI**. Ou seja: a arte oficial foi desenhada sobre a paleta de produção — **nenhum
> `COLOR_*`, nenhum QSS e nenhum derivado de ícone precisou mudar**.
>
> **O símbolo (`iman-symbol.png`) continua o mesmo arquivo**, e por isso `.ico`, `icon-*.png` e
> os dois `wizard-*.png` **não foram regerados** — eles derivam do símbolo, não do splash.
>
> **Créditos do QGIS preservados (BL-1/BL-2):** a arte traz `POWERED BY QGIS` — verificado no
> texto do SVG **e** no pixel do raster final.
>
> ### CERCA ZERO — a arte é ARBITRADA (sponsor, 2026-09-09)
>
> A crew levantou dois pontos: o rodapé diz **`v1.0 · LTR`** com o produto em **`0.3.0`**, e a faixa
> diz **`VERSÃO INSTITUCIONAL · CAUCAIA LTR`**. **A decisão veio, e é esta**, literal:
> *"é para usar as novas imagens as is, sem perguntas"*.
>
> São **entrada arbitrada, não defeito pendente** — registrado em `reference_decisions.md`, emenda de
> 2026-09-09, com o flag do arquiteto preservado ao lado. Em consequência:
>
> - **não editar a arte**, em nenhum master ou derivado;
> - **nenhuma asserção pode reprovar o produto por causa desses dois textos**;
> - **não "consertar"** a versão do splash para casar com o `BUILD_INFO`.
>
> Levantar foi certo. A decisão veio, e a cerca fecha o assunto.

## Masters (arte-fonte)

| Arquivo | O que é |
|---|---|
| `splash-iman-terra.svg` | **Master vetorial** do splash — export do **CorelDRAW 2021** de **`IMAN Terra.cdr`** (2026-09-09 05:03), idêntico ao `IMAN Terra.svg` (05:04): MD5 `32a43bb2b8babae2d0868b89f27cfbe7`, 104.557 bytes. viewBox `26478×12720`, ≈2,082:1. Fonte legível da paleta. **Não é mais a entrada da rasterização** — ver a armadilha do QtSvg abaixo. **NÃO confundir com `IMAN.cdr`** (2025-06-30, 7,16 MB), que **não** é a fonte desta arte. |
| `splash-iman-terra-master.png` | **Master raster**, 3128×1504, exportado pelo **próprio Corel**. É daqui que saem todos os rasters do splash. Existe porque nenhum rasterizador desta bancada renderiza o SVG fielmente. |
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
> 2. ~~O `splash-iman-terra.png` commitado está dessincronizado do próprio master.~~ **RESOLVIDO em
>    2026-09-09:** o splash passou a sair do master oficial do Corel, com o globo inteiro.

> ### ⚠️ Armadilha conhecida: o QtSvg NÃO rasteriza este master — e apaga o crédito do QGIS
>
> **Medido em 2026-09-09, ao ingerir a arte oficial.** O export do Corel embute a fonte como
> **SVG font** (`<font>` + `<glyph>`) e quebra o texto em **164 elementos `<text>` de um
> caractere**. O `QSvgRenderer` do Qt **não implementa SVG fonts** — e não falha: ele **omite os
> glifos** e devolve uma imagem que continua bonita.
>
> | o que a arte diz | o que o QtSvg desenhou |
> |---|---|
> | `IMAN Terra` | `IMA Terra` |
> | `VERSÃO INSTITUCIONAL` | `ERS O I STITUCIO AL` |
> | `REGULARIZAÇÃO FUNDIÁRIA` | `REGULARI A   O U DIÁRIA` |
> | **`POWERED BY QGIS`** | **`POWERED BY GIS`** |
>
> A última linha é a que importa: rasterizar este SVG com QtSvg **apaga o crédito do QGIS** do
> splash de boot. Não é degradação estética — é **BL-1**, e sai em silêncio.
>
> **Por isso o raster vem do `splash-iman-terra-master.png`**, que o próprio Corel exportou, e
> `rasterize-splash.py` passou a **reduzir** esse PNG em vez de rasterizar o vetor. O SVG continua
> versionado como proveniência e como fonte legível da paleta.
>
> **Quando isso pode voltar a sair do vetor:** com um rasterizador que implemente SVG fonts
> (Inkscape, resvg, librsvg) — nenhum deles existe nesta bancada hoje. Até lá, **não** apontar
> `rasterize-splash.py` para o SVG "porque é o master": o master ele é; renderizável aqui, não.
>
> ~~Armadilha anterior (fatia #007): as duas tags `<image>` do SVG interino referenciavam o
> `iman-symbol.png` com caixas dimensionadas para o master antigo (411×333).~~ **PERDEU OBJETO:**
> o SVG novo tem **zero** tags `<image>` — é autocontido.

## Derivados reprodutíveis (regeráveis a partir dos masters)

| Arquivo | Como é gerado | Uso |
|---|---|---|
| `splash-iman-terra.png` | **reduzido do master raster do Corel** com Pillow/LANCZOS (`rasterize-splash.py`), 1000×480 | **splash NATIVO de boot** (customização, no-fork) |
| `../profile-template/iman-distro/QGIS/splash.png` | idêntico ao de cima (`rasterize-splash.py`), 1000×480 | é o arquivo que a customização do perfil aponta no boot |
| `icon-iman-terra.ico` | símbolo → ICO 16/24/32/48/64/128/256, **transparente**, **sem respiro extra** (`regenerate-icons.py`) | atalho / `SetupIconFile` / `UninstallDisplayIcon` |
| `icon-iman-terra.png` | símbolo → 512×512, transparente (`regenerate-icons.py`) | ícone da janela (startup) |
| `wizard-large.png` | símbolo sobre `brand` (#103D29, paleta nova), 410×797 (`regenerate-brand-derivatives.py`) | `WizardImageFile` (Inno) |
| `wizard-small.png` | símbolo sobre **fundo transparente** (alfa real, RGBA), 138×140 (`regenerate-brand-derivatives.py`) | `WizardSmallImageFile` (Inno), com `WizardImageAlphaFormat=defined` |
| `../profile-template/iman-distro/python/plugins/iman_brand/resources/icon.png` | símbolo → 256×256 (`regenerate-icons.py`) | ícone do plugin/toolbar/Sobre |
| `../profile-template/iman-distro/python/plugins/iman_brand/resources/splash.png` | master raster → 760×365 (`rasterize-splash.py`) | banner do dock de boas-vindas |

**Regeneração:** os derivados são produzidos a partir dos masters com Pillow (PIL disponível no
`python` do sistema — ver `.memory/reference_build_environment.md`). O `.ico` é multi-resolução e
**transparente** (a fatia 1 corrigiu o quadrado branco; manter). Se um master oficial for atualizado,
regenerar os derivados a partir dele — não editar os derivados à mão.

```
python app/assets/rasterize-splash.py             # splash 1000×480 + perfil + banner do dock
python app/assets/regenerate-icons.py             # ícones (a partir de iman-symbol.png)
python app/assets/regenerate-brand-derivatives.py # wizards
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
