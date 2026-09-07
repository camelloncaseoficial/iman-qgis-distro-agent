# -*- coding: utf-8 -*-
"""IMAN Terra — startup script (Opção 1, no-fork).

Executado pelo QGIS via `--code app/startup/iman_startup.py`. Responsabilidades
LEVES (a experiência maior mora no plugin de marca `iman_brand`):

1. Aplicar o tema QSS institucional à janela principal, ANEXANDO ao stylesheet do
   QGIS (não substitui os estilos nativos) e reaplicando após a UI assentar.
2. Trocar o ícone da janela/taskbar para o emblema IMAN.

O TÍTULO DA JANELA NÃO É ESCRITO AQUI (D5, fatia #018). Ele tinha duas fontes —
esta e `iman_brand.py::_apply_title` — e as duas cravavam a mesma string
estática por cima do título que o QGIS acabara de compor, apagando o nome do
projeto aberto. Agora existe uma fonte só: o gancho `windowTitleChanged` do
plugin de marca, que troca apenas o SUFIXO. Não reintroduza `setWindowTitle`
neste arquivo.

Limite honesto (BL-5): o **splash nativo de boot** ("QGIS x.y Bratislava LTR") e os
**ícones de ação da toolbar** são do core do QGIS e só mudam na Opção 2 (fork) —
documentados como limite, não contornados por hack frágil (ex.: um 2º splash flash).

Roda no perfil isolado `iman-distro` — não toca o perfil do usuário (BL-3) — e não
se apresenta como QGIS oficial (BL-1/BL-2).
"""
import ctypes
import os

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import QTimer
from qgis.PyQt.QtGui import QIcon
from qgis.utils import iface

_IMAN_MARK = "/* IMAN-THEME */"


def _brand():
    """Importa a fonte única de marca do plugin (BL-4)."""
    try:
        from iman_brand import brand
        return brand
    except Exception:
        import sys
        prof = QgsApplication.qgisSettingsDirPath()
        plugin_dir = os.path.join(prof, "python", "plugins")
        if plugin_dir not in sys.path:
            sys.path.insert(0, plugin_dir)
        try:
            from iman_brand import brand
            return brand
        except Exception:
            return None


def _profile_dir():
    return QgsApplication.qgisSettingsDirPath()


def _app_home():
    """Raiz do app instalado (contém assets/). Setada pelo launcher."""
    return os.environ.get("IMAN_TERRA_HOME")


def _read_qss(brand):
    qss_path = os.path.join(_profile_dir(), "QGIS", "iman-theme.qss")
    if os.path.exists(qss_path):
        try:
            with open(qss_path, "r", encoding="utf-8") as fh:
                return fh.read()
        except Exception:
            pass
    if brand is not None:
        # Fallback mínimo derivado das constantes (caso o .qss não venha no perfil).
        # Cores vêm da fonte única brand.py (paleta oficial travada, BL-4).
        # Light-chrome (suavizado 2026-07-15): chrome CLARA, verde só no acento — espelha
        # a passada do iman-theme.qss para o fallback não reintroduzir o verde escuro.
        return (
            "QMenuBar {{ background-color: {panel}; color: {text}; "
            "border-bottom: 1px solid {border}; }}\n"
            "QMenuBar::item:selected {{ background-color: {activebg}; color: {activefg}; }}\n"
            "QStatusBar {{ background-color: {panel2}; color: {muted}; "
            "border-top: 1px solid {border}; }}\n"
            "QDockWidget::title {{ background-color: {panel2}; color: {activefg}; "
            "padding: 4px 8px; font-weight: 600; border-bottom: 1px solid {border}; }}\n"
        ).format(panel=brand.COLOR_PANEL, panel2=brand.COLOR_PANEL_2,
                 text=brand.COLOR_TEXT, muted=brand.COLOR_TEXT_MUTED,
                 border=brand.COLOR_BORDER, activebg=brand.COLOR_ACTIVE_BG,
                 activefg=brand.COLOR_ACTIVE_FG)
    return ""


def _apply_theme(win, qss):
    if not qss:
        return
    current = win.styleSheet() or ""
    if _IMAN_MARK in current:
        return  # já aplicado
    win.setStyleSheet(current + "\n" + _IMAN_MARK + "\n" + qss)


def _icon_path():
    home = _app_home()
    candidates = []
    if home:
        candidates.append(os.path.join(home, "assets", "icon-iman-terra.png"))
    candidates.append(os.path.join(
        _profile_dir(), "python", "plugins", "iman_brand",
        "resources", "icon.png"))
    for c in candidates:
        if c and os.path.exists(c):
            return c
    return None


def _apply_window_icon(win):
    """Troca o icone da janela/taskbar (no-fork). Os icones de ACAO da toolbar
    continuam do QGIS (baked no core) — isso e limite da Opcao 2."""
    path = _icon_path()
    if path:
        icon = QIcon(path)
        if not icon.isNull():
            win.setWindowIcon(icon)


def _set_app_user_model_id():
    """Identidade de taskbar/pin no Windows (agrupa a janela sob a marca IMAN,
    nao sob o QGIS). No-fork, runtime. Falha silenciosa fora do Windows."""
    try:
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(
            "InstitutoIMAN.IMANTerra.Distro.1")
    except Exception:
        pass


def main():
    if iface is None:
        return
    win = iface.mainWindow()
    brand = _brand()

    _set_app_user_model_id()

    def apply_identity():
        # Só o ícone. O QGIS reescreve o ícone TARDE no boot (achado dos spikes
        # #004/#005), então reaplicamos algumas vezes. O TÍTULO é do plugin de
        # marca, fonte única (D5).
        _apply_window_icon(win)

    apply_identity()
    qss = _read_qss(brand)
    _apply_theme(win, qss)

    # Reaplica identidade + tema depois que a UI do QGIS assenta (evita clobber).
    for delay in (800, 1500, 2500, 4000):
        QTimer.singleShot(delay, apply_identity)
        QTimer.singleShot(delay, lambda: _apply_theme(win, qss))


main()
