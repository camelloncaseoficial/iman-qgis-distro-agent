# -*- coding: utf-8 -*-
"""Instrumentação da Sonda C (--code): confirma o dock de home carregado pelo
plugin (caminho real: perfil isolado -> plugin habilitado), exercita um ciclo de
novo projeto para provar que o dock sobrevive, tira screenshot e encerra. O exit
code do processo (capturado pelo run) atesta teardown limpo (vs. crash da Sonda A).
"""
import os
import sys

_DIR = os.environ.get("SPIKE_DIR", os.getcwd())
if _DIR not in sys.path:
    sys.path.insert(0, _DIR)

from qgis.utils import iface
from qgis.PyQt.QtWidgets import QDockWidget
import probe_common as ev

_OBS = {"sonda": "C", "steps": []}


def _find_dock():
    for d in iface.mainWindow().findChildren(QDockWidget):
        if d.objectName() == "ImanTerraHomeDock":
            return d
    return None


def phase1():
    dock = _find_dock()
    _OBS["steps"].append({
        "step": "loaded",
        "dock_found": dock is not None,
        "dock_visible": dock.isVisible() if dock else False,
        "windowTitle": iface.mainWindow().windowTitle(),
        "plugin_loaded": "iman_home" in _loaded_plugins(),
        "dock_floating": dock.isFloating() if dock else None,
    })
    # o dock flutua (top-level próprio) -> screenshot do DOCK e do contexto
    if dock is not None:
        ev.screenshot(dock, "sonda_c_home.png")
    ev.screenshot(iface.mainWindow(), "sonda_c_context.png")
    # ciclo: novo projeto -> o dock deve permanecer
    try:
        iface.newProject(False)
    except Exception as e:
        _OBS["steps"].append({"step": "newProject_error", "error": str(e)})
    ev.after(1500, phase2)


def phase2():
    dock = _find_dock()
    _OBS["steps"].append({
        "step": "after_new_project",
        "dock_still_present": dock is not None,
        "dock_visible": dock.isVisible() if dock else False,
        "windowTitle": iface.mainWindow().windowTitle(),
    })
    ev.screenshot(iface.mainWindow(), "sonda_c_after_newproject.png")
    ev.write_json("sonda_c_observations.json", _OBS)
    ev.after(1000, _quit)


def _quit():
    from qgis.PyQt.QtCore import QCoreApplication
    QCoreApplication.quit()


def _loaded_plugins():
    try:
        import qgis.utils
        return list(qgis.utils.plugins.keys())
    except Exception:
        return []


def main():
    if iface is None:
        return
    ev.after(5000, phase1)
    ev.schedule_quit(20)  # backstop


main()
