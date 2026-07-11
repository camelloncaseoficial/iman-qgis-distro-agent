# -*- coding: utf-8 -*-
"""SONDA A — title bar frameless de marca (a mais arriscada).

Objetivo do gate: substituir a moldura NATIVA do Windows por uma barra de marca
IMAN Terra, SÓ via startup/plugin (no-fork), sem perder os comportamentos de janela
que o usuário espera: arrastar, maximizar, minimizar, restaurar, Aero Snap, duplo-
clique na barra, menu de sistema, multi-monitor e DPI 125–150%.

Implementa o MELHOR caminho no-fork disponível no QGIS 3.40 / Qt 5.15:
  - Qt.FramelessWindowHint (remove a moldura nativa)
  - barra de marca própria acima do menu (setMenuWidget)
  - arrasto + Aero Snap via QWindow.startSystemMove() (Qt >= 5.15)
  - duplo-clique alterna maximizar/restaurar; botões min/max/close próprios

E MEDE o que sobra de pé e o que quebra, gravando evidência em evidence/. O
resultado esperado (declarado no briefing) é FRÁGIL — e um FAIL bem-documentado é
o argumento nº1 do fork (BL-5). Este script roda no perfil ISOLADO do spike; NADA
aqui vai para o perfil de produção.
"""
import os
import sys

# QGIS roda `--code` sem __file__; o run-spike.bat exporta SPIKE_DIR.
_DIR = os.environ.get("SPIKE_DIR", os.getcwd())
if _DIR not in sys.path:
    sys.path.insert(0, _DIR)

from qgis.PyQt.QtCore import Qt, QObject, QEvent, QSize
from qgis.PyQt.QtGui import QIcon, QPixmap
from qgis.PyQt.QtWidgets import (
    QWidget, QHBoxLayout, QVBoxLayout, QLabel, QToolButton, QSizePolicy,
)
from qgis.utils import iface

import tokens
import probe_common as ev

PAL = tokens.LIGHT
_OBS = {"sonda": "A", "steps": []}


def _log(step, **kw):
    entry = {"step": step}
    entry.update(kw)
    _OBS["steps"].append(entry)


class _TitleBarFilter(QObject):
    """Arrasto nativo (startSystemMove) + duplo-clique p/ maximizar."""

    def __init__(self, win):
        super().__init__(win)
        self._win = win
        self._sysmove_ok = None

    def eventFilter(self, obj, e):
        if e.type() == QEvent.MouseButtonPress and e.button() == Qt.LeftButton:
            wh = self._win.windowHandle()
            if wh is not None and hasattr(wh, "startSystemMove"):
                try:
                    wh.startSystemMove()
                    self._sysmove_ok = True
                except Exception as ex:
                    self._sysmove_ok = "ERRO: %s" % ex
            else:
                self._sysmove_ok = False
            return False
        if e.type() == QEvent.MouseButtonDblClick and e.button() == Qt.LeftButton:
            self._toggle_max()
            return True
        return False

    def _toggle_max(self):
        if self._win.isMaximized():
            self._win.showNormal()
        else:
            self._win.showMaximized()


def _asset_icon():
    for c in [
        os.path.join(os.environ.get("IMAN_TERRA_HOME", ""), "assets", "icon-iman-terra.png"),
        os.path.join(_DIR, "sonda_c_dock", "resources", "icon.png"),
    ]:
        if c and os.path.exists(c):
            return c
    return None


def _ctrl_button(glyph, tip, on_click, danger=False):
    b = QToolButton()
    b.setText(glyph)
    b.setToolTip(tip)
    b.setCursor(Qt.PointingHandCursor)
    b.setFixedSize(QSize(38, 30))
    hover = "#c0392b" if danger else PAL["hover"]
    hover_fg = "#FFFFFF" if danger else PAL["chrome_fg"]
    b.setStyleSheet(
        "QToolButton{{background:transparent;color:%s;border:none;border-radius:7px;"
        "font-size:15px;}}"
        "QToolButton:hover{{background:%s;color:%s;}}" % (
            PAL["chrome_muted"].replace("rgba(234,243,236,0.62)", "#EAF3EC"),
            hover, hover_fg)
    )
    b.clicked.connect(on_click)
    return b


def _build_titlebar(win):
    bar = QWidget()
    bar.setObjectName("ImanTitleBar")
    bar.setFixedHeight(46)
    bar.setStyleSheet(
        "QWidget#ImanTitleBar{background:%s;}"
        "QLabel{color:%s;}" % (PAL["chrome"], PAL["chrome_fg"]))
    h = QHBoxLayout(bar)
    h.setContentsMargins(12, 0, 8, 0)
    h.setSpacing(11)

    icon_path = _asset_icon()
    if icon_path:
        logo = QLabel()
        logo.setPixmap(QPixmap(icon_path).scaledToHeight(24, Qt.SmoothTransformation))
        h.addWidget(logo)

    brand = QLabel("<span style='font-size:15px;font-weight:700;letter-spacing:.5px'>IMAN</span>"
                   "<span style='font-size:15px;font-weight:300;letter-spacing:3px;color:%s'> TERRA</span>"
                   % "#9FC6AE")
    h.addWidget(brand)

    sep = QLabel("|")
    sep.setStyleSheet("color:%s;" % "#2C5A45")
    h.addWidget(sep)
    proj = QLabel("Projeto sem título")
    proj.setStyleSheet("color:%s;font-size:12px;" % "#9FC6AE")
    h.addWidget(proj)

    h.addStretch(1)
    search = QLabel("  \U0001F50D  Buscar ferramentas, dados e projetos…    Ctrl K  ")
    search.setStyleSheet(
        "color:%s;background:%s;border:1px solid %s;border-radius:8px;padding:4px 10px;font-size:12px;"
        % ("#CFE3D6", "#1B4D36", "#2C5A45"))
    h.addWidget(search)
    h.addStretch(1)

    h.addWidget(_ctrl_button("–", "Minimizar", win.showMinimized))
    h.addWidget(_ctrl_button("□", "Maximizar/Restaurar",
                             lambda: win.showNormal() if win.isMaximized() else win.showMaximized()))
    h.addWidget(_ctrl_button("✕", "Fechar", win.close, danger=True))

    # arrasto/duplo-clique no corpo da barra (não nos botões)
    filt = _TitleBarFilter(win)
    bar.installEventFilter(filt)
    for w in (brand, proj, search, sep):
        w.installEventFilter(filt)
    bar._filt = filt  # manter referência viva
    return bar, filt


def _apply_frameless(win):
    _log("pre", **ev.observe_window(win))

    # 1) barra de marca acima do menu (embrulha o menuBar existente)
    reparent_note = "ok"
    try:
        titlebar, filt = _build_titlebar(win)
        wrapper = QWidget()
        v = QVBoxLayout(wrapper)
        v.setContentsMargins(0, 0, 0, 0)
        v.setSpacing(0)
        v.addWidget(titlebar)
        mb = win.menuBar()
        v.addWidget(mb)          # reparenta o menuBar nativo do QGIS para dentro
        win.setMenuWidget(wrapper)
        wrapper.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
    except Exception as e:
        reparent_note = "ERRO ao embutir menuBar: %s" % e
    _log("titlebar_injected", note=reparent_note)

    # 2) frameless — remove a moldura nativa (destrói/recria a janela nativa)
    flag_note = "ok"
    try:
        win.setWindowFlags(Qt.Window | Qt.FramelessWindowHint)
        win.show()   # obrigatório após setWindowFlags
    except Exception as e:
        flag_note = "ERRO: %s" % e
    _log("frameless_flags_set", note=flag_note, **ev.observe_window(win))

    # 3) matrix programático: maximizar cobre a barra de tarefas?
    def probe_max():
        win.showMaximized()
        ev.after(600, probe_max_observe)

    def probe_max_observe():
        covers = ev.maximized_covers_taskbar(win)
        obs = ev.observe_window(win, {"maximized_respects_taskbar": covers})
        obs["startSystemMove_used"] = filt._sysmove_ok
        _log("maximized", **obs)
        ev.screenshot(win, "sonda_a_maximized.png")
        ev.after(500, probe_restore)

    def probe_restore():
        win.showNormal()
        ev.after(600, probe_restore_observe)

    def probe_restore_observe():
        _log("restored", **ev.observe_window(win))
        ev.screenshot(win, "sonda_a_normal.png")
        _finish()

    ev.after(1200, lambda: (ev.screenshot(win, "sonda_a_initial.png"), probe_max()))


def _finish():
    _OBS["verdict_inputs"] = {
        "note": "Comportamentos que exigem verificação MANUAL (não automatizáveis "
                "por este harness) estão listados no REPORT.md: Aero Snap por arrasto "
                "à borda, Win+Setas, menu de sistema Alt+Espaço, snap-layouts do "
                "hover do botão maximizar (Win11), e re-render de DPI ao mover entre "
                "monitores 100%/150%.",
    }
    ev.write_json("sonda_a_observations.json", _OBS)
    ev.schedule_quit(2)


def main():
    if iface is None:
        return
    win = iface.mainWindow()
    # deixa a UI do QGIS assentar antes de re-flaggar a janela principal
    ev.after(2500, lambda: _apply_frameless(win))
    ev.schedule_quit(20)  # backstop


main()
