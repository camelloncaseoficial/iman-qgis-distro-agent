# -*- coding: utf-8 -*-
"""Helpers de EVIDÊNCIA das sondas do spike #003.

Não faz parte do produto: instrumenta o QGIS real (aberto pelo run-spike.bat no
perfil isolado do spike) para registrar fatos de janela, tirar screenshots e
encerrar sozinho — de modo que cada sonda seja repetível e produza artefato em
`evidence/` sem depender de clique manual.

O que NÃO dá pra automatizar (Aero Snap por arrasto até a borda, Win+Setas, menu de
sistema Alt+Espaço, layouts de snap do Win11 no hover do botão maximizar, troca de
DPI ao vivo entre monitores 100%/150%) é registrado como "requer verificação manual"
com o comportamento esperado/observado anotado no relatório — nunca afirmado como
testado quando não foi (honestidade do gate).
"""
import json
import os
import platform

from qgis.PyQt.QtCore import Qt, QTimer, QCoreApplication
from qgis.PyQt.QtWidgets import QApplication

# QGIS executa `--code` sem definir __file__; o run-spike.bat exporta SPIKE_DIR.
SPIKE_DIR = os.environ.get("SPIKE_DIR", os.getcwd())
EVIDENCE_DIR = os.path.join(SPIKE_DIR, "evidence")


def _ensure_dir():
    try:
        os.makedirs(EVIDENCE_DIR, exist_ok=True)
    except Exception:
        pass


def _screens_info():
    out = []
    for i, s in enumerate(QApplication.screens()):
        g = s.geometry()
        ag = s.availableGeometry()
        out.append({
            "index": i,
            "name": s.name(),
            "geometry": [g.x(), g.y(), g.width(), g.height()],
            "available": [ag.x(), ag.y(), ag.width(), ag.height()],
            "devicePixelRatio": round(s.devicePixelRatio(), 3),
            "logicalDpi": round(s.logicalDotsPerInch(), 1),
        })
    return out


def _flag_names(flags):
    known = {
        "Window": Qt.Window,
        "FramelessWindowHint": Qt.FramelessWindowHint,
        "CustomizeWindowHint": Qt.CustomizeWindowHint,
        "WindowTitleHint": Qt.WindowTitleHint,
        "WindowSystemMenuHint": Qt.WindowSystemMenuHint,
        "WindowMinMaxButtonsHint": Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint,
        "WindowMinimizeButtonHint": Qt.WindowMinimizeButtonHint,
        "WindowMaximizeButtonHint": Qt.WindowMaximizeButtonHint,
        "WindowCloseButtonHint": Qt.WindowCloseButtonHint,
    }
    present = []
    for name, bit in known.items():
        try:
            if int(flags) & int(bit) == int(bit) and int(bit) != 0:
                present.append(name)
        except Exception:
            pass
    return present


def observe_window(win, extra=None):
    """Coleta fatos objetivos da janela principal — a base do matrix da sonda."""
    fr = win.frameGeometry()
    cl = win.geometry()
    wh = win.windowHandle()
    data = {
        "platform": platform.platform(),
        "qt_startSystemMove_available": hasattr(wh, "startSystemMove") if wh else False,
        "qt_startSystemResize_available": hasattr(wh, "startSystemResize") if wh else False,
        "window_flags": _flag_names(win.windowFlags()),
        "isMaximized": win.isMaximized(),
        "isMinimized": win.isMinimized(),
        "isFullScreen": win.isFullScreen(),
        "frameGeometry": [fr.x(), fr.y(), fr.width(), fr.height()],
        "clientGeometry": [cl.x(), cl.y(), cl.width(), cl.height()],
        # margem do frame nativo: 0,0,0,0 == não há moldura do SO (frameless)
        "frameMargins": [cl.x() - fr.x(), cl.y() - fr.y(),
                         fr.right() - cl.right(), fr.bottom() - cl.bottom()],
        "screens": _screens_info(),
        "windowTitle": win.windowTitle(),
    }
    if extra:
        data.update(extra)
    return data


def maximized_covers_taskbar(win):
    """Bug clássico de frameless: ao maximizar, a janela cobre a barra de tarefas.
    True == comportamento CORRETO (respeita availableGeometry da tela)."""
    scr = win.windowHandle().screen() if win.windowHandle() else QApplication.primaryScreen()
    ag = scr.availableGeometry()
    g = win.frameGeometry()
    # tolerância de 2px
    return abs(g.width() - ag.width()) <= 2 and abs(g.height() - ag.height()) <= 2


def screenshot(win, name):
    _ensure_dir()
    path = os.path.join(EVIDENCE_DIR, name)
    try:
        pix = win.grab()
        pix.save(path)
        return path if os.path.exists(path) else None
    except Exception as e:
        return "ERRO: %s" % e


def write_json(name, data):
    _ensure_dir()
    path = os.path.join(EVIDENCE_DIR, name)
    try:
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2, ensure_ascii=False, default=str)
        return path
    except Exception as e:
        return "ERRO: %s" % e


def schedule_quit(seconds=14):
    """Fecha o QGIS depois de coletar evidência (harness não-interativo)."""
    QTimer.singleShot(int(seconds * 1000), QCoreApplication.quit)


def after(ms, fn):
    QTimer.singleShot(int(ms), fn)
