# -*- coding: utf-8 -*-
"""Sondas I (runtime) / III / IV — camada de identidade RUNTIME (no-fork).

Executado via `--code` no QGIS real (perfil isolado do spike). Cobre numa só sessão:
  I  (runtime): mainWindow().setWindowIcon(IMAN) + AppUserModelID (janela/taskbar).
  III (About):  diálogo próprio "Sobre o IMAN Terra" (versão, powered by QGIS, créditos
                QGIS.ORG, independência BL-1/BL-2) MANTENDO o About nativo do QGIS.
  IV (nome):    o que o runtime influencia (AppUserModelID, applicationDisplayName) vs o
                que é C++-baked (applicationName/organizationName/crash reporter/classe).

Grava observações + screenshots em evidence/. Não toca o core (BL-5); perfil isolado (BL-3).
"""
import ctypes
import json
import os

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import Qt, QTimer, QCoreApplication
from qgis.PyQt.QtGui import QIcon, QPixmap
from qgis.PyQt.QtWidgets import (
    QAction, QDialog, QVBoxLayout, QLabel, QMessageBox, QPushButton,
)
from qgis.utils import iface

_DIR = os.environ.get("SPIKE_DIR", os.getcwd())
EVID = os.path.join(_DIR, "evidence")
os.makedirs(EVID, exist_ok=True)

PRODUCT = "IMAN Terra"
VERSION = "0.1.0"
WINDOW_TITLE = "IMAN Terra — powered by QGIS"
CREDITS = ("IMAN Terra é uma experiência geoespacial desktop independente, powered by QGIS. "
           "O QGIS é um SIG livre e de código aberto, desenvolvido por QGIS.ORG e contribuidores. "
           "Este projeto não é um produto oficial do QGIS e não é endossado pela QGIS.ORG.")

OBS = {"sondas": "I(runtime)/III/IV", "I_icon": {}, "III_about": {}, "IV_name": {}}


def _icon_path():
    for c in [
        os.path.join(os.environ.get("IMAN_TERRA_HOME", ""), "assets", "icon-iman-terra.png"),
        os.path.join(_DIR, "custom_splash", "splash.png"),
    ]:
        if c and os.path.exists(c):
            return c
    return None


def _own_about():
    dlg = QDialog(iface.mainWindow())
    dlg.setWindowTitle("Sobre o %s" % PRODUCT)
    dlg.setObjectName("ImanAboutDialog")
    v = QVBoxLayout(dlg)
    ic = _icon_path()
    if ic:
        logo = QLabel()
        logo.setPixmap(QPixmap(ic).scaledToWidth(96, Qt.SmoothTransformation))
        logo.setAlignment(Qt.AlignCenter)
        v.addWidget(logo)
    title = QLabel("<h2>%s</h2><p>Versão %s · powered by QGIS</p>" % (PRODUCT, VERSION))
    title.setAlignment(Qt.AlignCenter)
    title.setTextFormat(Qt.RichText)
    v.addWidget(title)
    body = QLabel(CREDITS + "<br><br><b>Instituto IMAN</b> — independente; não é o QGIS oficial.")
    body.setWordWrap(True)
    body.setTextFormat(Qt.RichText)
    v.addWidget(body)
    b = QPushButton("Fechar")
    b.clicked.connect(dlg.close)
    v.addWidget(b)
    dlg.resize(460, 360)
    return dlg


def phase():
    win = iface.mainWindow()

    # ---- Sonda I (runtime): AppUserModelID + window icon ----
    appid_ok = None
    try:
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(
            "InstitutoIMAN.IMANTerra.Distro.1")
        appid_ok = True
    except Exception as e:
        appid_ok = "ERRO: %s" % e
    ic = _icon_path()
    icon_set = False
    if ic:
        icon = QIcon(ic)
        if not icon.isNull():
            win.setWindowIcon(icon)
            QgsApplication.setWindowIcon(icon)  # ícone da app (afeta janelas filhas)
            icon_set = True
    win.setWindowTitle(WINDOW_TITLE)
    OBS["I_icon"] = {
        "AppUserModelID_set": appid_ok,
        "window_icon_set": icon_set,
        "icon_path": ic,
        "bucket": "RUNTIME (janela/taskbar) — no-fork",
    }

    # ---- Sonda IV (nome interno): baked vs runtime ----
    before = {
        "applicationName": QgsApplication.applicationName(),
        "organizationName": QgsApplication.organizationName(),
        "applicationDisplayName": QgsApplication.applicationDisplayName(),
    }
    # tenta mudar em runtime
    try:
        QgsApplication.setApplicationDisplayName("IMAN Terra")
    except Exception:
        pass
    after = {
        "applicationName": QgsApplication.applicationName(),
        "organizationName": QgsApplication.organizationName(),
        "applicationDisplayName": QgsApplication.applicationDisplayName(),
    }
    OBS["IV_name"] = {
        "before": before, "after_runtime_set": after,
        "runtime_influenciavel": {
            "AppUserModelID": "SIM (identidade de taskbar/pin no Windows)",
            "applicationDisplayName": "SIM (mas uso interno; pouco/nada visível)",
        },
        "cpp_baked_irredutivel": [
            "applicationName='QGIS' (base do caminho de QSettings — já contornado pelo perfil isolado)",
            "organizationName ('QGIS')",
            "diálogo/executável do crash reporter (mostra 'QGIS')",
            "nome da classe de janela nativa / applicationName no nível do processo",
        ],
        "bucket": "IRREDUTÍVEL (payoff ~zero — técnico municipal não vê)",
    }

    # ---- Sonda III: About próprio + About nativo intacto ----
    native_about = None
    try:
        act = getattr(iface, "actionAbout", None)
        if callable(act):
            a = act()
            native_about = isinstance(a, QAction) and a is not None
    except Exception as e:
        native_about = "ERRO: %s" % e
    # adiciona ação própria ao menu (coexiste com o About nativo)
    own_action = QAction("Sobre o %s" % PRODUCT, win)
    iface.addPluginToMenu(PRODUCT, own_action)
    dlg = _own_about()
    own_action.triggered.connect(dlg.show)
    OBS["III_about"] = {
        "native_about_action_present": native_about,
        "own_about_added": True,
        "bucket": "RUNTIME (no-fork) — próprio coexiste com o nativo (BL-1/BL-2)",
    }

    # screenshots: janela (ícone/título) e o About próprio
    win.setWindowTitle(WINDOW_TITLE)
    QTimer.singleShot(400, lambda: _shoot(win, dlg))


def _shoot(win, dlg):
    try:
        win.grab().save(os.path.join(EVID, "sonda_runtime_window.png"))
    except Exception:
        pass
    dlg.show()
    dlg.raise_()
    QTimer.singleShot(700, lambda: _shoot2(win, dlg))


def _shoot2(win, dlg):
    try:
        dlg.grab().save(os.path.join(EVID, "sonda_iii_own_about.png"))
    except Exception:
        pass
    with open(os.path.join(EVID, "sonda_runtime_observations.json"), "w", encoding="utf-8") as f:
        json.dump(OBS, f, indent=2, ensure_ascii=False)
    QTimer.singleShot(600, QCoreApplication.quit)


def main():
    if iface is None:
        return
    QTimer.singleShot(4500, phase)
    QTimer.singleShot(20000, QCoreApplication.quit)  # backstop


main()
