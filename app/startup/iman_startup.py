# -*- coding: utf-8 -*-
"""IMAN Terra — startup script (Opção 1, no-fork).

Executado pelo QGIS via `--code app/startup/iman_startup.py`. Responsabilidades
LEVES (a experiência maior mora no plugin de marca `iman_brand`):

1. Ativar o TEMA DE UI próprio (`themes/IMAN Terra` no perfil isolado) — D12.
   Desde o #041 ele já vem ativo do arranque; aqui é redundância.
2. Aplicar o tema QSS institucional à janela principal, ANEXANDO ao stylesheet do
   QGIS (não substitui os estilos nativos) e reaplicando após a UI assentar.
3. Trocar o ícone da APLICAÇÃO (todas as janelas e diálogos sem ícone próprio) e
   o da janela principal/taskbar para o emblema IMAN.

O TÍTULO DA JANELA NÃO É ESCRITO AQUI (D5, fatia #018). Ele tinha duas fontes —
esta e `iman_brand.py::_apply_title` — e as duas cravavam a mesma string
estática por cima do título que o QGIS acabara de compor, apagando o nome do
projeto aberto. Agora existe uma fonte só: o gancho `windowTitleChanged` do
plugin de marca, que troca apenas o SUFIXO. Não reintroduza `setWindowTitle`
neste arquivo.

O TEMA ENTRA NO ARRANQUE (#041, D-IMAN-039). O `[UI] UITheme=IMAN Terra` do
template do perfil faz o QGIS aplicar o tema ANTES de montar a janela. Os icones
de acao da toolbar NAO sao limite da Opcao 2: o QGIS os pede ao tema por nome
(`getThemeIcon`), e um arquivo com o mesmo nome em `<perfil>/themes/IMAN Terra/
icons/` vence o padrao. O que impedia isso era o momento: o QGIS guarda cada
icone em cache na primeira leitura, e o `setUITheme` daqui, que roda depois da
janela montada, nao limpa esse cache. A chamada abaixo fica como redundancia.

Limite honesto (BL-5): o que so muda com fork e o que o QGIS le por caminho
compilado (`:/images/...`) ou do binario: icone do executavel, logo dos projetos
no Navegador, icone das Propriedades da camada, o Sobre nativo (que fica por
BL-1). Documentado como limite, nao contornado por hack fragil.

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

# D12 (#017/A12) - o tema de icones/UI do produto e um tema PROPRIO, instalado
# no userThemesFolder do PERFIL ISOLADO. Nunca em C:\Program Files\QGIS* -
# sob o ramo DB-16 isso sobrescreveria o QGIS do proprio usuario (BL-3).
TEMA_UI = "IMAN Terra"


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


def _caminho_do_tema():
    """`<perfil>/themes/<TEMA_UI>` — o que o QGIS chama de userThemesFolder."""
    return os.path.join(_profile_dir(), "themes", TEMA_UI)


def _aplica_tema_ui():
    """Ativa o tema PRÓPRIO do produto (D12).

    Antes desta fatia o tema em uso era o `default` do QGIS e não existia
    nenhum tema no perfil — ou seja, toda a iconografia da UI era a do QGIS,
    logo incluído. Agora o produto tem tema próprio, e ele mora no perfil
    isolado: `QgsApplication.userThemesFolder()`.
    """
    try:
        if not os.path.isdir(_caminho_do_tema()):
            return False
        QgsApplication.setUITheme(TEMA_UI)
        return QgsApplication.themeName() == TEMA_UI
    except Exception:
        return False


def _read_qss(brand):
    # O QSS de marca É o style.qss do tema (fonte única).
    #
    # O FALLBACK PARA <perfil>/QGIS/iman-theme.qss SAIU na fatia #030 (DB-26).
    # Ele existia para perfis criados antes da #018, quando o QSS morava ali.
    # Com a reconciliação do perfil, esse arquivo é OBSOLETO declarado em
    # `profile-template/PERFIL-DO-PRODUTO.json`: a rotina do launcher o REMOVE
    # de qualquer perfil, e ela roda antes de o QGIS ler o perfil. O caminho
    # não podia mais ser alcançado - e um fallback que não pode disparar não
    # protege ninguém; só sugere que aquele arquivo ainda é uma fonte válida
    # de tema, que é exatamente o que deixou de ser.
    qss_path = os.path.join(_caminho_do_tema(), "style.qss")
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
        # O .ico primeiro (#041): ele traz 16 a 256 px, e o Qt escolhe o tamanho
        # de cada uso (barra de titulo, Alt-Tab, taskbar em alta densidade). O
        # PNG de 512 px e um tamanho so, reduzido pelo Qt.
        candidates.append(os.path.join(home, "assets", "icon-iman-terra.ico"))
        candidates.append(os.path.join(home, "assets", "icon-iman-terra.png"))
    candidates.append(os.path.join(
        _profile_dir(), "python", "plugins", "iman_brand",
        "resources", "icon.png"))
    for c in candidates:
        if c and os.path.exists(c):
            return c
    return None


def _apply_app_icon():
    """Icone da APLICACAO (#041, forense S16).

    O QGIS chama `setWindowIcon(appIconPath())` no main.cpp, com o PNG 60x60 do
    logo do QGIS que mora na arvore. Todo dialogo sem icone proprio herda o da
    aplicacao, entao trocar so o da janela principal deixava o logo do QGIS em
    cada dialogo. Trocar aqui alcanca os dialogos criados daqui em diante, sem
    tocar o `qgis-icon-60x60.png` da arvore (RISCOS R6).
    """
    path = _icon_path()
    if path:
        icon = QIcon(path)
        if not icon.isNull():
            QgsApplication.setWindowIcon(icon)


def _apply_window_icon(win):
    """Troca o icone da janela principal/taskbar (no-fork). Os icones de ACAO da
    toolbar vem do tema do perfil (#041); este e so o da janela."""
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

    _apply_app_icon()
    _set_app_user_model_id()
    _aplica_tema_ui()

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
