# -*- coding: utf-8 -*-
"""IMAN Terra — startup script (Opção 1, no-fork).

Executado pelo QGIS via `--code app/startup/iman_startup.py`. Responsabilidades
LEVES (a experiência maior mora no plugin de marca `iman_brand`):

1. Ajustar o título da janela para `WINDOW_TITLE` (fonte única de marca, BL-4).
2. Aplicar o tema QSS institucional à janela principal (no-fork; limite honesto:
   splash/ícone-exe/About nativos só na Opção 2).
3. Garantir que o painel de boas-vindas do plugin apareça, se o plugin carregar.

Este script NÃO se apresenta como QGIS oficial (BL-1/BL-2) e não toca o perfil do
usuário — roda no perfil isolado `iman-distro` (BL-3).
"""
import os

from qgis.core import QgsApplication
from qgis.utils import iface


def _brand():
    """Importa a fonte única de marca do plugin (BL-4).

    O plugin `iman_brand` está no perfil isolado; garantimos o import mesmo que o
    startup rode antes do carregamento de plugins, adicionando o caminho.
    """
    try:
        from iman_brand import brand  # plugin já no sys.path
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


def _apply_theme(win, brand):
    qss_path = os.path.join(
        QgsApplication.qgisSettingsDirPath(), "QGIS", "iman-theme.qss"
    )
    if os.path.exists(qss_path):
        try:
            with open(qss_path, "r", encoding="utf-8") as fh:
                win.setStyleSheet(fh.read())
            return
        except Exception:
            pass
    # Fallback mínimo se o .qss não vier no perfil.
    if brand is not None:
        win.setStyleSheet(
            "QStatusBar { color: %s; }" % brand.COLOR_SECONDARY
        )


def main():
    if iface is None:
        return
    win = iface.mainWindow()
    brand = _brand()

    title = brand.WINDOW_TITLE if brand else "IMAN Terra — powered by QGIS"
    win.setWindowTitle(title)
    _apply_theme(win, brand)


main()
