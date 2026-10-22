# -*- coding: utf-8 -*-
"""Sonda da GUARDA DO TEMA DE ICONES (#041, forense R2 R3 R4). Roda no Python da
arvore do QGIS, chamada por tools/test-theme-icons.ps1:

    python-qgis-ltr.bat theme_icons_probe.py <pasta do tema> <saida.json>

Para cada arquivo de `<tema>/icons/` (subpastas inclusive):

  A1 o nome, com subpasta e extensao, EXISTE no tema padrao. O padrao e
     enumerado AQUI, do recurso compilado `:/images/themes/default/` da propria
     arvore, e nao de lista copiada: um nome que o QGIS nao pede cai no padrao
     em silencio e deixa a interface misturada (R3).
  A2 o arquivo renderiza a 16 e a 24 px, e a imagem NAO e transparente nem de
     cor unica. O QGIS so testa se o arquivo existe; um SVG vazio vira botao sem
     icone, sem erro nenhum (R2).
  A3 nenhuma imagem citada pelo style.qss como `@theme_path/icons/<nome>` colide
     com um nome de icone do padrao, e toda ela leva o prefixo `qss-` (R4). Os
     arquivos `qss-*` sao imagens do QSS e ficam fora de A1.

A sonda nao decide sozinha: ela grava o que mediu, e o .ps1 da o veredito.
"""
import json
import os
import re
import sys

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import QByteArray, QDirIterator, QRectF, Qt
from qgis.PyQt.QtGui import QImage, QPainter
from qgis.PyQt.QtSvg import QSvgRenderer

DEFAULT_ROOT = ":/images/themes/default/"
SIZES = (16, 24)
QSS_PREFIX = "qss-"


def default_names():
    names = set()
    it = QDirIterator(DEFAULT_ROOT, QDirIterator.Subdirectories)
    while it.hasNext():
        path = it.next()
        if it.fileInfo().isFile():
            names.add(path[len(DEFAULT_ROOT):])
    return names


def render(path, size):
    """QImage size x size, ARGB32, com o arquivo desenhado; None se nao abre."""
    img = QImage(size, size, QImage.Format_ARGB32)
    img.fill(0)
    if path.lower().endswith(".svg"):
        with open(path, "rb") as fh:
            data = fh.read()
        renderer = QSvgRenderer(QByteArray(data))
        if not renderer.isValid():
            return None
        painter = QPainter(img)
        painter.setRenderHint(QPainter.Antialiasing)
        renderer.render(painter, QRectF(0, 0, size, size))
        painter.end()
        return img
    src = QImage(path)
    if src.isNull():
        return None
    scaled = src.scaled(size, size, Qt.KeepAspectRatio, Qt.SmoothTransformation)
    painter = QPainter(img)
    painter.drawImage((size - scaled.width()) // 2, (size - scaled.height()) // 2, scaled)
    painter.end()
    return img


def measure(img):
    values = set()
    opaque = 0
    for y in range(img.height()):
        for x in range(img.width()):
            px = img.pixel(x, y)
            values.add(px)
            if (px >> 24) & 0xFF:
                opaque += 1
    return {"distinct": len(values), "pixels_with_ink": opaque}


def qss_images(theme_dir):
    qss = os.path.join(theme_dir, "style.qss")
    if not os.path.isfile(qss):
        return []
    with open(qss, "r", encoding="utf-8") as fh:
        text = re.sub(r"/\*.*?\*/", "", fh.read(), flags=re.S)
    return sorted(set(re.findall(r"@theme_path/icons/([^)\"'\s;]+)", text)))


def main():
    theme_dir, out = sys.argv[1], sys.argv[2]
    app = QgsApplication([], False)
    app.initQgis()
    defaults = default_names()
    icons_dir = os.path.join(theme_dir, "icons")
    files = []
    if os.path.isdir(icons_dir):
        for root, _, names in os.walk(icons_dir):
            for n in names:
                full = os.path.join(root, n)
                files.append(os.path.relpath(full, icons_dir).replace(os.sep, "/"))
    files.sort()

    result = {"theme_dir": theme_dir, "default_root": DEFAULT_ROOT,
              "default_count": len(defaults), "files": [], "qss_images": []}
    for rel in files:
        entry = {"name": rel, "qss_image": os.path.basename(rel).startswith(QSS_PREFIX)}
        entry["in_default"] = rel in defaults
        entry["renders"] = {}
        for size in SIZES:
            img = render(os.path.join(icons_dir, rel.replace("/", os.sep)), size)
            entry["renders"][str(size)] = None if img is None else measure(img)
        result["files"].append(entry)
    for name in qss_images(theme_dir):
        result["qss_images"].append({"name": name, "prefixed": name.startswith(QSS_PREFIX),
                                     "collides_with_default": name in defaults})
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(result, fh, ensure_ascii=False, indent=2)
    app.exitQgis()


main()
