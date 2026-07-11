# -*- coding: utf-8 -*-
"""Rasteriza o master splash-iman-terra.svg -> splash-iman-terra.png (1000x480).

Rasterizador determinístico disponível no ambiente: **QtSvg** (`QSvgRenderer`), via
o Python do QGIS. NÃO usar a plataforma 'offscreen' (dá tofu nas fontes) — usar a
'windows' (base de fontes real). Rodar:

    C:\\OSGeo4W\\bin\\python-qgis-ltr.bat app\\assets\\rasterize-splash.py

Resolve o href relativo `iman-symbol.png` fazendo chdir p/ app/assets/.
"""
import os
import sys

from qgis.PyQt.QtWidgets import QApplication
from qgis.PyQt.QtSvg import QSvgRenderer
from qgis.PyQt.QtGui import QImage, QPainter, QColor
from qgis.PyQt.QtCore import QRectF

ASSETS = os.path.dirname(os.path.abspath(__file__))
SVG = os.path.join(ASSETS, "splash-iman-terra.svg")
PNG = os.path.join(ASSETS, "splash-iman-terra.png")
W, H = 1000, 480

app = QApplication(sys.argv)
os.chdir(ASSETS)  # href relativo do símbolo
r = QSvgRenderer(SVG)
assert r.isValid(), "SVG inválido"
img = QImage(W, H, QImage.Format_ARGB32)
img.fill(QColor("#0e1a14"))  # bg opaco (o SVG cobre tudo; segurança contra máscara)
p = QPainter(img)
p.setRenderHint(QPainter.Antialiasing, True)
p.setRenderHint(QPainter.TextAntialiasing, True)
p.setRenderHint(QPainter.SmoothPixmapTransform, True)
r.render(p, QRectF(0, 0, W, H))
p.end()
img.save(PNG)
print("splash rasterizado:", PNG, os.path.getsize(PNG), "bytes")
