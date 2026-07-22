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

## Ressalva de marca (decisão não é da crew)

A arte oficial traz um **contorno branco** em volta de toda a forma — tratamento de favicon, para
assentar sobre qualquer fundo. Sobre o verde do `wizard-large` ele fica **bem marcante** (`03`).
É mudança de **aparência**, não só correção do corte. Ficou como está porque a arte é a oficial e
editá-la seria a crew cunhando decisão de marca.

E o **símbolo dentro do splash continua o recortado** — o splash tem master próprio
(`splash-iman-terra.svg`) e está fora do escopo. Hoje: ícones com globo inteiro, splash com globo
cortado. Reconciliar é fatia própria.
