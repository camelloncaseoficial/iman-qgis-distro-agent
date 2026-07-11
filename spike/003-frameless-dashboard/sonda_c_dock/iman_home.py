# -*- coding: utf-8 -*-
"""Plugin de marca (spike) — dashboard como DOCK. Sonda C.

Importa o construtor de home compartilhado (`dashboard.build_home`) e os tokens
da paleta nova a partir de SPIKE_DIR (exportado pelo run-spike.bat). Como plugin
QGIS padrão, só adiciona/remove um dock — sem reparent de menuBar nem re-flag de
janela (por isso é a rede de segurança robusta, ao contrário da Sonda A).
"""
import os
import sys

# dashboard.py / tokens.py vivem em SPIKE_DIR (fonte única do spike).
_SPIKE = os.environ.get("SPIKE_DIR")
if _SPIKE and _SPIKE not in sys.path:
    sys.path.insert(0, _SPIKE)

from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtGui import QIcon
from qgis.PyQt.QtWidgets import QAction, QDockWidget

import dashboard  # noqa: E402

_DIR = os.path.dirname(__file__)
WINDOW_TITLE = "IMAN Terra — powered by QGIS"


class ImanHomePlugin:
    def __init__(self, iface):
        self.iface = iface
        self.dock = None
        self.action = None

    def initGui(self):
        icon_path = os.path.join(_DIR, "resources", "icon.png")
        icon = QIcon(icon_path) if os.path.exists(icon_path) else QIcon()
        self.action = QAction(icon, "Home IMAN Terra", self.iface.mainWindow())
        self.action.triggered.connect(self.show_home)
        self.iface.addToolBarIcon(self.action)
        self.iface.addPluginToMenu("IMAN Terra", self.action)

        # Título de marca (belt-and-suspenders; limite do no-fork é reescrever no
        # abrir/criar projeto — reaplicamos nos sinais).
        self._apply_title()
        try:
            self.iface.projectRead.connect(self._apply_title)
            self.iface.newProjectCreated.connect(self._apply_title)
        except Exception:
            pass

        self.show_home()

    def _apply_title(self):
        try:
            self.iface.mainWindow().setWindowTitle(WINDOW_TITLE)
        except Exception:
            pass

    def _build_dock(self):
        dock = QDockWidget("IMAN Terra — Início", self.iface.mainWindow())
        dock.setObjectName("ImanTerraHomeDock")
        home = dashboard.build_home(iface=self.iface, dark=False, res_dir=os.path.join(_DIR, "resources"))
        dock.setWidget(home)
        dock.setMinimumWidth(560)
        return dock

    def show_home(self):
        if self.dock is None:
            self.dock = self._build_dock()
            # Dock ancorável à direita, mas ABERTO FLUTUANTE e amplo no startup:
            # lê como uma "home" de boas-vindas sobre o canvas vazio, sem virar
            # widget central (Sonda B) nem tocar a janela (Sonda A). O usuário pode
            # ancorá-lo ou fechá-lo — é um dock comum, robusto.
            self.iface.addDockWidget(Qt.RightDockWidgetArea, self.dock)
            self.dock.setFloating(True)
            self.dock.resize(940, 640)
            try:
                mw = self.iface.mainWindow()
                c = mw.frameGeometry().center()
                self.dock.move(int(c.x() - 470), int(c.y() - 320))
            except Exception:
                pass
        self.dock.show()
        self.dock.raise_()

    def unload(self):
        for sig in ("projectRead", "newProjectCreated"):
            try:
                getattr(self.iface, sig).disconnect(self._apply_title)
            except Exception:
                pass
        if self.action is not None:
            self.iface.removeToolBarIcon(self.action)
            self.iface.removePluginMenu("IMAN Terra", self.action)
            self.action = None
        if self.dock is not None:
            self.iface.removeDockWidget(self.dock)
            self.dock.deleteLater()
            self.dock = None
