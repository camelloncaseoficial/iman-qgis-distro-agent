# Evidência — fatia #007 (símbolo oficial: master re-ancorado)

Bancada: Windows 11 Pro, QGIS LTR 3.44.9, perfil isolado **resetado** antes do run.

| Arquivo | O quê |
|---|---|
| `01-simbolo-antes-depois.png` | derivado 512 antes (cortado) × depois (oficial), sobre branco e sobre `brand` |
| `02-piramide-ico.png` | o `.ico` final aberto em cada tamanho embutido — 16/24/32/48/64/128/256 |
| `03-wizard-antes-depois.png` | `wizard-large` e `wizard-small` antes × depois |
| `04-janela-e-toolbar.png` | runtime: ícone da barra de título e botão de marca na toolbar |

## O defeito, medido

O master anterior era **411×333** — nem quadrado. O conteúdo ocupava a tela inteira (margens de
0,7%–1,2%), ou seja: **recorte justo com a esfera decepada** embaixo e à direita. O master novo é
**512×512** e traz o globo completo.

Sobre fundo branco o corte é difícil de ver, porque a arte tem um contorno branco. **Sobre o verde
`brand` fica evidente** — por isso `01` e `03` mostram as duas versões nos dois fundos.

## O que foi verificado nesta bancada

- ✅ `.ico` com a pirâmide completa (7 tamanhos) e canto transparente (`alpha=0`).
- ✅ Globo inteiro em **todos** os tamanhos, **inclusive 16×16** (`02`).
- ✅ Ícone da janela/taskbar em runtime, com perfil resetado (`04`).
- ✅ Wizards regerados — o enquadramento **mudou de fato**, porque o aspect do master passou de
  411×333 (1,23:1) para 512×512 (1:1), e o compositor usa o aspect do símbolo.
- ✅ Banner do dock (`resources/splash.png`) saiu **byte-idêntico**: depende do splash, não do
  símbolo. Não entra no diff.

## O que NÃO foi verificado aqui (fica para a VM — BL-7)

Estas superfícies só existem depois de instalar, e a crew não roda a VM:

- atalho do **Menu Iniciar** e da **Área de Trabalho**
- **Adicionar/Remover Programas** (`UninstallDisplayIcon`)
- as telas do **wizard** do instalador rodando de verdade

Entram no `docs/verify/bl7-clean-vm/CHECKLIST.md` como parte dos passos 3, 4 e 10.

## Gate pendente para o BL-7 — respiro do ícone em 16×16 REAL

O `.ico` foi gerado com **`RESPIRO = 0`**, o que produz um ícone **edge-to-edge**. Medido
(`alpha > 128`): o master oficial tem margens **0,2% / 0,2% / 0,2% / 0,0%** e **13 pixels opacos na
última linha** — a arte encosta na borda. O derivado anterior tinha **9,2% / 17,0% / 9,2% / 17,0%**.

Na prática o ícone **renderiza maior que os vizinhos** e com a **base tangente à borda**. A escolha
foi feita comparando PNG ampliado (`02-piramide-ico.png`), **não** a barra de tarefas real.

**Passo a acrescentar ao `docs/verify/bl7-clean-vm/CHECKLIST.md`:**

> **Ícone na barra de tarefas (16×16 real).** Com o IMAN Terra aberto e o atalho fixado, comparar o
> ícone com os vizinhos da barra de tarefas e do Menu Iniciar.
> **Asserção:** o globo está inteiro **e** o ícone não parece desproporcional (maior/colado na borda)
> ao lado dos outros. `PASS / FAIL` · screenshot `15-icone-taskbar-16px.png`
> Se FAIL: subir `RESPIRO` para ~8% em `app/assets/regenerate-icons.py` e regerar — é um número.

> **Dependência entre branches:** o `CHECKLIST.md` **não existe** em `develop` — vive na
> `feat/005-kit-release-bl7` (PR #7). Este passo **ainda precisa ser inserido lá**; não foi possível
> fazê-lo a partir desta branch.

## Ressalva de marca (decisão não é da crew)

A arte oficial traz um **contorno branco** em volta de toda a forma — tratamento de favicon, para
assentar sobre qualquer fundo. Sobre o verde do `wizard-large` ele fica **bem marcante** (`03`).
É mudança de **aparência**, não só correção do corte. Ficou como está porque a arte é a oficial e
editá-la seria a crew cunhando decisão de marca.

E o **símbolo dentro do splash continua o recortado**. Correção de uma afirmação anterior: o splash
**não** tem master próprio de símbolo — o `splash-iman-terra.svg` **referencia o `iman-symbol.png`**
em duas tags `<image>` (`785.7×660` e `128.6×108`, ambas ~1,19:1, dimensionadas para o master antigo
de 1,2342:1). Com o master agora em 1:1 e o default `xMidYMid meet`, re-rasterizar hoje **mudaria
escala e posição** do símbolo — o `splash-iman-terra.png` commitado **já não é** o que o SVG
produziria. Dívida registrada em `app/assets/README.md`; reconciliar é fatia própria e **não** se
resolve rodando `rasterize-splash.py` sem antes corrigir as caixas.
