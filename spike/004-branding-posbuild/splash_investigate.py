# -*- coding: utf-8 -*-
"""Sonda II (headless) — descobre COMO o splash nativo de boot é resolvido.

Roda via `python-qgis-ltr.bat splash_investigate.py`. Responde, com evidência (não
por suposição): o splash vem de um arquivo em disco (→ trocável pós-build, no-fork)
ou de um resource Qt COMPILADO no binário (→ irredutível sem rebuild)? E o path é
influenciável pela customização do QGIS (QgsCustomization)?
"""
import json
import os

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import QFile

out = {}
app = QgsApplication([], False)

try:
    sp = QgsApplication.splashPath()
    out["splashPath()"] = sp
    out["pkgDataPath()"] = QgsApplication.pkgDataPath()
    # arquivo em disco no splashPath?
    disk = {}
    for name in ("splash.png", "splashscreen.png"):
        if sp.startswith(":"):
            p = sp + name
            disk[p] = {"qt_resource_exists": QFile(p).exists()}
        else:
            p = os.path.join(sp, name)
            disk[p] = {"disk_exists": os.path.exists(p)}
    out["splashPath_candidates"] = disk
    # resources Qt compilados (o splash real do QGIS costuma ser :/images/splash/…)
    qtres = {}
    for r in (":/images/splash/splashscreen.png", ":/images/splash/splash.png",
              ":/images/splash/", ":/images/qgis-icon-60x60.png"):
        qtres[r] = QFile(r).exists()
    out["qt_resources"] = qtres
    # há splash.png em disco em qualquer subdir do pkgDataPath?
    found = []
    pkg = QgsApplication.pkgDataPath()
    if pkg and os.path.isdir(pkg):
        for root, _dirs, files in os.walk(pkg):
            for f in files:
                if f.lower() in ("splash.png", "splashscreen.png"):
                    found.append(os.path.join(root, f))
    out["disk_splash_files_under_pkgDataPath"] = found
except Exception as e:
    out["error"] = repr(e)

d = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(d, "evidence", "splash_mechanism.json"), "w", encoding="utf-8") as fh:
    json.dump(out, fh, indent=2, ensure_ascii=False)
print(json.dumps(out, indent=2, ensure_ascii=False))
