# -*- coding: utf-8 -*-
"""IMAN Terra — plugin de marca leve.

Camada de experiência institucional sobre o QGIS LTR (Opção 1, no-fork):
menu próprio, toolbar, painel (dock) de boas-vindas e ação "Sobre" com os
créditos do QGIS. Usa apenas APIs públicas do QGIS/Qt (BL-6). Toda a marca vem
de `brand.py` (fonte única, BL-4). Nada aqui se apresenta como QGIS oficial
(BL-1/BL-2).
"""
import os
import webbrowser

from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtGui import QIcon, QPixmap, QDesktopServices
from qgis.PyQt.QtCore import QUrl
from qgis.PyQt.QtWidgets import (
    QAction, QDockWidget, QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QFrame, QScrollArea, QMessageBox, QSizePolicy,
)

from . import brand

_DIR = os.path.dirname(__file__)
_RES = os.path.join(_DIR, "resources")


def _res(name):
    return os.path.join(_RES, name)


class ImanBrandPlugin:
    """Plugin de marca: registra menu/toolbar/dock e a ação Sobre."""

    def __init__(self, iface):
        self.iface = iface
        self.actions = []
        self.menu = brand.PRODUCT_NAME
        self.toolbar = None
        self.dock = None

    # ------------------------------------------------------------------ setup
    def initGui(self):
        self.toolbar = self.iface.addToolBar(brand.PRODUCT_NAME)
        self.toolbar.setObjectName("ImanTerraToolbar")

        icon = QIcon(_res("icon.png"))

        self._add_action(
            icon, "Boas-vindas", self.show_welcome,
            tip="Abrir o painel de boas-vindas do %s" % brand.PRODUCT_NAME,
        )
        self._add_action(
            icon, "Abrir projeto demo", self.open_demo,
            tip="Abrir o projeto de demonstração welcome.qgz",
        )
        self._add_action(
            icon, "Documentação", self.open_docs,
            tip="Abrir a documentação do %s" % brand.PRODUCT_NAME,
        )
        self._add_action(
            icon, "Site do Instituto IMAN", self.open_site,
            tip="Abrir o site do Instituto IMAN",
        )
        self._add_action(
            icon, "Sobre", self.show_about,
            tip="Sobre o %s (créditos do QGIS)" % brand.PRODUCT_NAME,
        )

        # Título da janela (belt-and-suspenders com o startup script). O QGIS
        # reescreve o título ao abrir/criar projeto (limite do no-fork), então
        # reaplicamos nos sinais de projeto para que o branding persista.
        self._apply_title()
        try:
            self.iface.projectRead.connect(self._apply_title)
            self.iface.newProjectCreated.connect(self._apply_title)
        except Exception:
            pass

        # Painel de boas-vindas visível na primeira carga.
        self.show_welcome()

    def _apply_title(self):
        try:
            self.iface.mainWindow().setWindowTitle(brand.WINDOW_TITLE)
        except Exception:
            pass

    def _add_action(self, icon, text, callback, tip=""):
        action = QAction(icon, text, self.iface.mainWindow())
        action.triggered.connect(callback)
        if tip:
            action.setStatusTip(tip)
            action.setToolTip(tip)
        self.toolbar.addAction(action)
        self.iface.addPluginToMenu(self.menu, action)
        self.actions.append(action)
        return action

    # --------------------------------------------------------------- welcome
    def show_welcome(self):
        if self.dock is None:
            self.dock = self._build_dock()
            self.iface.addDockWidget(Qt.RightDockWidgetArea, self.dock)
        self.dock.show()
        self.dock.raise_()

    def _build_dock(self):
        dock = QDockWidget(brand.PRODUCT_NAME, self.iface.mainWindow())
        dock.setObjectName("ImanTerraWelcomeDock")

        inner = QWidget()
        inner.setObjectName("ImanTerraWelcome")
        layout = QVBoxLayout(inner)
        layout.setContentsMargins(16, 16, 16, 16)
        layout.setSpacing(12)

        # Banner do splash oficial (arte que já credita o QGIS — BL-1). É o mesmo
        # master que a Opção 2 (fork) usará como splash nativo de boot (DA-2);
        # aqui, no no-fork, entra só como banner honesto do painel (BL-5).
        banner_path = _res("splash.png")
        if os.path.exists(banner_path):
            banner = QLabel()
            pix = QPixmap(banner_path)
            if not pix.isNull():
                banner.setPixmap(pix.scaledToWidth(248, Qt.SmoothTransformation))
            banner.setAlignment(Qt.AlignCenter)
            layout.addWidget(banner)

        title = QLabel(brand.PRODUCT_NAME)
        title.setObjectName("ImanTitle")
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)

        subtitle = QLabel(brand.PRODUCT_SUBTITLE)
        subtitle.setObjectName("ImanSubtitle")
        subtitle.setWordWrap(True)
        subtitle.setAlignment(Qt.AlignCenter)
        layout.addWidget(subtitle)

        layout.addWidget(self._divider())

        steps = QLabel(
            "<b>Primeiros passos</b>"
            "<ol style='margin-left:-18px'>"
            "<li>Abra o <b>projeto demo</b> para ver um mapa de exemplo.</li>"
            "<li>Explore o menu <b>%s</b> na barra de menus.</li>"
            "<li>Consulte a <b>documentação</b> e o site do Instituto.</li>"
            "</ol>" % brand.PRODUCT_NAME
        )
        steps.setWordWrap(True)
        layout.addWidget(steps)

        btn_demo = QPushButton("Abrir projeto demo")
        btn_demo.setObjectName("ImanPrimaryBtn")
        btn_demo.clicked.connect(self.open_demo)
        layout.addWidget(btn_demo)

        row = QHBoxLayout()
        btn_docs = QPushButton("Documentação")
        btn_docs.clicked.connect(self.open_docs)
        btn_site = QPushButton("Site IMAN")
        btn_site.clicked.connect(self.open_site)
        row.addWidget(btn_docs)
        row.addWidget(btn_site)
        layout.addLayout(row)

        layout.addStretch(1)
        layout.addWidget(self._divider())

        credits = QLabel(
            "<span style='color:%s'>%s</span>" % (
                brand.COLOR_SECONDARY,
                brand.CREDITS_QGIS.replace("\n", "<br>"),
            )
        )
        credits.setObjectName("ImanCredits")
        credits.setWordWrap(True)
        layout.addWidget(credits)

        btn_about = QPushButton("Sobre / créditos do QGIS")
        btn_about.clicked.connect(self.show_about)
        layout.addWidget(btn_about)

        inner.setStyleSheet(self._dock_qss())

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setWidget(inner)
        scroll.setFrameShape(QFrame.NoFrame)
        dock.setWidget(scroll)
        dock.setMinimumWidth(280)
        return dock

    def _divider(self):
        line = QFrame()
        line.setFrameShape(QFrame.HLine)
        line.setFrameShadow(QFrame.Sunken)
        line.setStyleSheet("color:%s;" % brand.COLOR_SURFACE)
        return line

    def _dock_qss(self):
        # Legibilidade (fatia 002): o verde vivo `primary` (#00A85A) fica em FILLS/
        # bordas (bloco), nunca como texto sobre claro — sobre `surface` daria ~2.9:1.
        # Todo TEXTO usa `primary-deep`/`ink` (~9:1 sobre surface). O botão primário
        # usa fundo `primary-deep` com texto branco (~8:1), não verde vivo (~3.1:1).
        return """
        QWidget#ImanTerraWelcome {{ background: {surface}; color: {text}; }}
        QLabel {{ color: {text}; }}
        QLabel#ImanTitle {{ font-size: 20px; font-weight: 700; color: {deep}; }}
        QLabel#ImanSubtitle {{ font-size: 12px; color: {deep}; }}
        QLabel#ImanCredits {{ font-size: 10px; color: {text}; }}
        QPushButton {{
            padding: 6px 10px; border-radius: 6px;
            border: 1px solid {primary}; color: {deep}; background: white;
        }}
        QPushButton:hover {{ background: {surface}; }}
        QPushButton#ImanPrimaryBtn {{
            background: {deep}; color: white; border: 1px solid {deep};
            font-weight: 600;
        }}
        QPushButton#ImanPrimaryBtn:hover {{ background: {ink}; }}
        """.format(
            surface=brand.COLOR_SURFACE, text=brand.COLOR_TEXT,
            primary=brand.COLOR_PRIMARY, deep=brand.COLOR_PRIMARY_DEEP,
            ink=brand.COLOR_INK,
        )

    # ---------------------------------------------------------------- actions
    def open_demo(self):
        # O demo vive ao lado do perfil, empacotado pelo instalador em app/demo/.
        # Procura caminhos prováveis; se não achar, orienta o usuário.
        candidates = []
        env = os.environ.get("IMAN_TERRA_HOME")
        if env:
            candidates.append(os.path.join(env, "demo", "welcome.qgz"))
        # Layout instalado: <app>/profile-template/... e <app>/demo/welcome.qgz
        here = _DIR
        for _ in range(6):
            here = os.path.dirname(here)
            candidates.append(os.path.join(here, "demo", "welcome.qgz"))
        for path in candidates:
            if path and os.path.exists(path):
                self.iface.addProject(path)
                return
        QMessageBox.information(
            self.iface.mainWindow(), brand.PRODUCT_NAME,
            "Projeto demo não encontrado.\nEle é instalado em app/demo/welcome.qgz.",
        )

    def open_docs(self):
        self._open_url(brand.URL_DOCS)

    def open_site(self):
        self._open_url(brand.URL_SITE)

    def _open_url(self, url):
        if not QDesktopServices.openUrl(QUrl(url)):
            webbrowser.open(url)

    def show_about(self):
        box = QMessageBox(self.iface.mainWindow())
        box.setWindowTitle("Sobre — %s" % brand.PRODUCT_NAME)
        box.setIconPixmap(
            QPixmap(_res("icon.png")).scaledToWidth(72, Qt.SmoothTransformation)
        )
        box.setTextFormat(Qt.RichText)
        box.setText(
            "<h3 style='color:%s'>%s</h3>"
            "<p>%s</p>"
            "<p><b>%s</b><br>%s</p>"
            "<hr>"
            "<p style='color:%s'>%s</p>"
            "<p style='font-size:10px;color:%s'>Versão %s · sem fork do QGIS "
            "(Opção 1). Limites conhecidos do no-fork — splash nativo, ícone do "
            "executável, About nativo e nome interno — são resolvidos só na "
            "Opção 2 (fork), documentados como limite.</p>" % (
                brand.COLOR_PRIMARY_DEEP, brand.PRODUCT_NAME, brand.PRODUCT_SUBTITLE,
                brand.PUBLISHER, brand.ORG_FULL,
                brand.COLOR_SECONDARY,
                brand.CREDITS_QGIS.replace("\n", "<br>"),
                brand.COLOR_SECONDARY, brand.VERSION,
            )
        )
        box.setStandardButtons(QMessageBox.Ok)
        box.exec_()

    # ---------------------------------------------------------------- unload
    def unload(self):
        for sig in ("projectRead", "newProjectCreated"):
            try:
                getattr(self.iface, sig).disconnect(self._apply_title)
            except Exception:
                pass
        for action in self.actions:
            self.iface.removePluginMenu(self.menu, action)
        self.actions = []
        if self.dock is not None:
            self.iface.removeDockWidget(self.dock)
            self.dock.deleteLater()
            self.dock = None
        if self.toolbar is not None:
            del self.toolbar
            self.toolbar = None
