# -*- coding: utf-8 -*-
"""SONDA B — dashboard NO LUGAR do canvas-vazio (área central).

Testa o caminho robusto pedido pelo gate: NÃO `setCentralWidget(home)` cru (que
DELETA o canvas do QGIS — o QMainWindow assume posse e destrói o central antigo),
e sim envolver o canvas num QStackedWidget:

    canvas = win.takeCentralWidget()      # remove SEM deletar (devolve posse)
    stack  = QStackedWidget([canvas, home])
    win.setCentralWidget(stack)

e provar o CICLO: home -> abrir projeto -> canvas volta -> fechar (novo projeto)
-> home volta, SEM tela-fantasma, sem quebrar Locator/docks/layout. Se o único
caminho fosse `setCentralWidget` (deletando o canvas) = FAIL.

Roda no perfil ISOLADO do spike. Instrumenta e registra evidência em evidence/.
"""
import os
import sys

_DIR = os.environ.get("SPIKE_DIR", os.getcwd())
if _DIR not in sys.path:
    sys.path.insert(0, _DIR)

from qgis.PyQt.QtWidgets import QStackedWidget
from qgis.utils import iface

import dashboard
import probe_common as ev

_OBS = {"sonda": "B", "steps": []}
_S = {}  # estado (stack, canvas, home)


def _log(step, **kw):
    e = {"step": step}
    e.update(kw)
    _OBS["steps"].append(e)


def _canvas_alive():
    """O canvas do QGIS continua vivo e utilizável?"""
    try:
        c = iface.mapCanvas()
        return {
            "mapCanvas_not_none": c is not None,
            "size": [c.width(), c.height()] if c is not None else None,
            "isVisible": c.isVisible() if c is not None else None,
        }
    except Exception as e:
        return {"error": str(e)}


def _locator_docks_ok():
    from qgis.PyQt.QtWidgets import QDockWidget
    mw = iface.mainWindow()
    docks = [d.objectName() for d in mw.findChildren(QDockWidget) if d.isVisible()]
    return {"visible_docks_count": len(docks), "has_layers_dock": any("Layer" in d or "Camad" in d or "Legend" in d for d in docks)}


def setup():
    win = iface.mainWindow()
    _log("pre", central_before=type(win.centralWidget()).__name__, **_canvas_alive())

    take_note = "ok"
    canvas = None
    try:
        canvas = win.takeCentralWidget()
        _log("takeCentralWidget", returned=type(canvas).__name__ if canvas else None,
             canvas_is_mapCanvas=(canvas is iface.mapCanvas()))
    except Exception as e:
        take_note = "ERRO: %s" % e
        _log("takeCentralWidget", note=take_note)

    try:
        stack = QStackedWidget()
        home = dashboard.build_home(iface=iface, dark=False)
        if canvas is not None:
            stack.addWidget(canvas)      # idx 0 (reparenta o canvas p/ o stack)
        stack.addWidget(home)            # idx 1
        win.setCentralWidget(stack)
        stack.setCurrentWidget(home)     # mostra a HOME primeiro
        _S.update(stack=stack, canvas=canvas, home=home)
        _log("stacked_installed", note="ok", current="home",
             canvas_alive=_canvas_alive(), **_locator_docks_ok())
    except Exception as e:
        _log("stacked_installed", note="ERRO: %s" % e)
        return _finish()

    ev.after(1200, lambda: (ev.screenshot(win, "sonda_b_home.png"), open_project()))


def open_project():
    """Simula 'abrir projeto': carrega o demo e volta ao canvas."""
    demo = None
    home_env = os.environ.get("IMAN_TERRA_HOME", "")
    for cand in [os.path.join(home_env, "demo", "welcome.qgz")]:
        if cand and os.path.exists(cand):
            demo = cand
            break
    opened = False
    if demo:
        try:
            iface.addProject(demo)
            opened = True
        except Exception as e:
            _log("open_project", note="ERRO addProject: %s" % e)
    # troca para o canvas (hook que, em produção, viria de projectRead)
    try:
        if _S.get("canvas") is not None:
            _S["stack"].setCurrentWidget(_S["canvas"])
    except Exception as e:
        _log("switch_to_canvas", note="ERRO: %s" % e)
    _log("opened_project", demo_found=bool(demo), opened=opened, current="canvas",
         canvas_alive=_canvas_alive())
    ev.after(1600, lambda: (ev.screenshot(iface.mainWindow(), "sonda_b_canvas.png"), close_project()))


def close_project():
    """Simula 'fechar/novo projeto vazio' -> a home volta."""
    try:
        iface.newProject(False)
    except Exception as e:
        _log("newProject", note="ERRO: %s" % e)
    try:
        _S["stack"].setCurrentWidget(_S["home"])
    except Exception as e:
        _log("switch_to_home", note="ERRO: %s" % e)
    _log("closed_to_home", current="home", canvas_alive=_canvas_alive(), **_locator_docks_ok())
    ev.after(1400, lambda: (ev.screenshot(iface.mainWindow(), "sonda_b_home_again.png"), _finish()))


def _finish():
    _OBS["notes"] = (
        "Ghost/tela-fantasma e integridade de layout são avaliados por inspeção "
        "visual dos 3 screenshots (home -> canvas -> home). O exit code do processo "
        "(capturado pelo run) atesta se o wrap do central widget desestabiliza o "
        "teardown do QGIS."
    )
    ev.write_json("sonda_b_observations.json", _OBS)
    ev.schedule_quit(2)


def main():
    if iface is None:
        return
    ev.after(3000, setup)
    ev.schedule_quit(24)  # backstop


main()
