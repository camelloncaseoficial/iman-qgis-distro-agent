# -*- coding: utf-8 -*-
"""Deriva os rasters do splash a partir do master OFICIAL do sponsor.

    python app/assets/rasterize-splash.py

Produz, a partir de `splash-iman-terra-master.png` (export do CorelDRAW,
3128x1504):

    app/assets/splash-iman-terra.png                              1000x480
    app/profile-template/iman-distro/QGIS/splash.png              1000x480  (splash NATIVO de boot)
    .../iman_brand/resources/splash.png                            760x365  (banner do dock)

POR QUE ISTO NÃO RASTERIZA MAIS O SVG — e por que não é preguiça
----------------------------------------------------------------
Até 2026-09-09 este script rasterizava `splash-iman-terra.svg` com o QtSvg
(`QSvgRenderer`), porque o master era um SVG-texto com fontes do sistema.

O master virou o **export do CorelDRAW 2021** (`IMAN.cdr`, drop do sponsor de
2026-09-09), que embute a fonte como **SVG font** (`<font>` + `<glyph>`) e
quebra o texto em 164 elementos `<text>` de um caractere. **O QtSvg não
implementa SVG fonts.** Rasterizado por ele, o resultado sai com glifos
FALTANDO — medido nesta bancada:

    "IMAN Terra"                        ->  "IMA Terra"
    "VERSÃO INSTITUCIONAL"              ->  "ERS O I STITUCIO AL"
    "REGULARIZAÇÃO FUNDIÁRIA"           ->  "REGULARI A   O U DIÁRIA"
    "POWERED BY QGIS"                   ->  "POWERED BY GIS"      <-- BL-1

A última linha é o motivo pelo qual isto está no código e não num comentário
de commit: rasterizar o SVG com QtSvg **apaga o crédito do QGIS** do splash de
boot. Não é degradação estética — é violação de invariante de licença, e sai
silenciosa, porque a imagem continua bonita.

O master vetorial (`splash-iman-terra.svg`) continua versionado como
**proveniência** e como fonte legível da paleta. O que ele NÃO é mais é a
entrada da rasterização: o raster vem do PNG que o próprio Corel exportou.

Se um dia entrar um rasterizador com suporte a SVG fonts (Inkscape, resvg,
librsvg), dá para voltar a sair do vetor — e aí este arquivo volta a mudar.
Enquanto isso, reduzir o raster oficial é o caminho FIEL, e é reprodutível.

Aspecto: o master é 3128x1504 (2,0798:1) e o alvo é 1000x480 (2,0833:1) — uma
diferença de 0,17%, absorvida no resize. Não há corte nem barra.
"""
import os

from PIL import Image

ASSETS = os.path.dirname(os.path.abspath(__file__))
APP = os.path.dirname(ASSETS)

MASTER = os.path.join(ASSETS, "splash-iman-terra-master.png")

SAIDAS = [
    (os.path.join(ASSETS, "splash-iman-terra.png"), (1000, 480)),
    (os.path.join(APP, "profile-template", "iman-distro", "QGIS", "splash.png"), (1000, 480)),
    (os.path.join(APP, "profile-template", "iman-distro", "python", "plugins",
                  "iman_brand", "resources", "splash.png"), (760, 365)),
]

src = Image.open(MASTER).convert("RGBA")
print("master: %s  %dx%d" % (os.path.basename(MASTER), src.width, src.height))

for destino, (w, h) in SAIDAS:
    Image.open(MASTER).convert("RGBA").resize((w, h), Image.LANCZOS).save(destino)
    print("  -> %-70s %dx%d  %d bytes"
          % (os.path.relpath(destino, APP), w, h, os.path.getsize(destino)))
