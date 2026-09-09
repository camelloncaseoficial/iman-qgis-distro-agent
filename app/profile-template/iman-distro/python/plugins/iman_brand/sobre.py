# -*- coding: utf-8 -*-
"""Janela "Sobre o IMAN Terra" (D10, fatia #018).

Antes desta fatia o "Sobre" era um `QMessageBox` alcançável só pelo dropdown
da toolbar — três níveis abaixo, em `Complementos ▸ IMAN Terra ▸`. Existia e
funcionava; só não estava onde se procura. Medido no #017: zero ocorrências no
menu `Ajuda`.

Agora é janela própria, no menu `Ajuda`, **ao lado do Sobre nativo do QGIS**,
que permanece — `BL-1` é inegociável: nada aqui esconde, enfraquece ou
substitui o crédito ao QGIS.

Conteúdo obrigatório (decisão do sponsor): logo · versão real · publisher ·
créditos do QGIS · licenças de terceiros · link do site.
"""
import os

from qgis.PyQt.QtCore import Qt, QUrl
from qgis.PyQt.QtGui import QPixmap, QDesktopServices
from qgis.PyQt.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QLabel, QPushButton, QTextBrowser,
    QDialogButtonBox, QWidget,
)

from . import brand

_DIR = os.path.dirname(__file__)


def _notices():
    """Texto dos avisos de terceiros. Procura o arquivo que o instalador
    entrega em {app}\\THIRD_PARTY_NOTICES.md; se não achar, diz onde ele está
    em vez de inventar conteúdo."""
    candidatos = []
    home = os.environ.get("IMAN_TERRA_HOME")
    if home:
        candidatos.append(os.path.join(home, "notices", "THIRD_PARTY_NOTICES.md"))
        candidatos.append(os.path.join(os.path.dirname(home),
                                       "THIRD_PARTY_NOTICES.md"))
    aqui = _DIR
    for _ in range(7):
        aqui = os.path.dirname(aqui)
        candidatos.append(os.path.join(aqui, "notices", "THIRD_PARTY_NOTICES.md"))
        candidatos.append(os.path.join(aqui, "THIRD_PARTY_NOTICES.md"))
    for c in candidatos:
        if c and os.path.exists(c):
            try:
                with open(c, "r", encoding="utf-8", errors="replace") as fh:
                    return fh.read(), c
            except Exception:
                pass
    return None, None


def _versao_do_qgis():
    try:
        from qgis.core import Qgis
        return Qgis.QGIS_VERSION
    except Exception:
        return ""


class SobreDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setObjectName("ImanSobreDialog")
        self.setWindowTitle("Sobre o %s" % brand.PRODUCT_NAME)
        self.setMinimumSize(620, 520)

        pal_texto = brand.COLOR_TEXT
        pal_fraco = brand.COLOR_TEXT_FAINT

        raiz = QVBoxLayout(self)
        raiz.setContentsMargins(22, 22, 22, 18)
        raiz.setSpacing(14)

        # ---- cabeçalho: logo + identidade + versão REAL
        topo = QHBoxLayout()
        topo.setSpacing(16)
        logo = QLabel()
        pix = QPixmap(os.path.join(_DIR, "resources", "icon.png"))
        if not pix.isNull():
            logo.setPixmap(pix.scaledToWidth(72, Qt.SmoothTransformation))
        logo.setFixedWidth(78)
        logo.setAlignment(Qt.AlignTop | Qt.AlignHCenter)
        topo.addWidget(logo)

        ident = QLabel(
            "<div style='font-size:20px;font-weight:700;color:%s'>%s</div>"
            "<div style='font-size:13px;color:%s;margin-top:2px'>%s</div>"
            "<div style='font-size:12px;color:%s;margin-top:8px'>"
            "Versão <b>%s</b>&nbsp;&nbsp;·&nbsp;&nbsp;sobre QGIS %s</div>"
            "<div style='font-size:12px;color:%s;margin-top:6px'>%s<br>%s</div>"
            % (brand.COLOR_PRIMARY_DEEP, brand.PRODUCT_NAME,
               pal_texto, brand.PRODUCT_SUBTITLE,
               pal_fraco, brand.versao_exibida(), _versao_do_qgis(),
               pal_fraco, brand.PUBLISHER, brand.ORG_FULL))
        ident.setTextFormat(Qt.RichText)
        ident.setWordWrap(True)
        topo.addWidget(ident, 1)
        raiz.addLayout(topo)

        # ---- créditos do QGIS (BL-1/BL-2) — verbatim da fonte única
        creditos = QLabel(brand.CREDITS_QGIS.replace("\n", "<br>"))
        creditos.setTextFormat(Qt.RichText)
        creditos.setWordWrap(True)
        # NOME DE OBJETO NOVO (#027), e nome de objeto e CONTRATO: o seletor
        # era `QLabel` NU. Inline isso so atinge este widget, mas no .qss
        # pegaria TODO QLabel da aplicacao. "ImanSobreCreditos" e o bloco de
        # creditos do QGIS no dialogo Sobre, e o style.qss depende dele.
        creditos.setObjectName("ImanSobreCreditos")
        # RAIO no style.qss (#027).
        creditos.setStyleSheet(
            "QLabel#ImanSobreCreditos{background:%s;border:1px solid %s;"
            "padding:12px 14px;font-size:12px;color:%s;}"
            % (brand.COLOR_PANEL_2, brand.COLOR_BORDER, pal_texto))
        raiz.addWidget(creditos)

        # ---- licenças de terceiros
        raiz.addWidget(QLabel(
            "<div style='font-size:13px;font-weight:600;color:%s'>"
            "Licenças de terceiros</div>" % pal_texto))
        texto, caminho = _notices()
        avisos = QTextBrowser()
        avisos.setOpenExternalLinks(True)
        if texto:
            try:
                avisos.setMarkdown(texto)
            except AttributeError:      # Qt < 5.14
                avisos.setPlainText(texto)
            avisos.setToolTip(caminho)
        else:
            avisos.setPlainText(
                "O arquivo THIRD_PARTY_NOTICES.md não foi encontrado nesta "
                "instalação.\nEle é entregue na pasta do produto, ao lado do "
                "LICENSE.")
        raiz.addWidget(avisos, 1)

        # ---- rodapé: site + fechar
        botoes = QDialogButtonBox()
        site = QPushButton("Site do %s" % brand.PUBLISHER)
        site.clicked.connect(
            lambda: QDesktopServices.openUrl(QUrl(brand.URL_SITE)))
        botoes.addButton(site, QDialogButtonBox.ActionRole)
        botoes.addButton(QDialogButtonBox.Close)
        botoes.rejected.connect(self.reject)
        raiz.addWidget(botoes)
