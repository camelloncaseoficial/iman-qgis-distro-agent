# -*- coding: utf-8 -*-
"""Home / dashboard IMAN Terra — miolo de boas-vindas (no lugar do canvas-vazio).

Promovido do spike #003 (`sonda_c_dock/dashboard.py`, ROBUSTO) para produção na
fatia #006. Paleta da FONTE ÚNICA de produção (`brand.py`, D-IMAN-026); conteúdo
REURB / cadastral do CEARÁ; fonte do sistema; CRS SIRGAS 2000 / UTM 24S. Quick-
actions ligadas a ações REAIS do QGIS. Créditos do QGIS no rodapé (BL-1/BL-2).
"""
import os

from qgis.PyQt.QtCore import Qt, pyqtSignal
from qgis.PyQt.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QGridLayout, QLabel, QFrame,
    QScrollArea, QAction,
)

from . import brand

SUBTITLE = "Regularização fundiária, cadastro territorial e cartografia — em uma só plataforma geoespacial."
CRS_LABEL = "EPSG:31984 · SIRGAS 2000 / UTM 24S"

# D8 (#017/A08) - NAO REINTRODUZIR DADO INVENTADO.
#
# Aqui existiam tres listas de exemplo: RECENTS com quatro projetos que nao
# existem (com caminho de arquivo e data - "Hoje", "Ontem", "3 dias"),
# TEMPLATES com seis modelos e CHIPS com seis atalhos. Nenhum dos tres
# clicava. Medido no #017: 20 de 20 dessas strings alcancavam a tela e 10
# widgets se pintavam como clicaveis sem ser.
#
# O sponsor abriu quatro projetos que nao existem. Uma maquete que finge ser
# produto e pior que uma tela vazia.
#
# A lista de recentes agora vem do QGIS, que ja mantem a de verdade. Vazia,
# ela se mostra VAZIA, com estado proprio. TEMPLATES e CHIPS foram removidos -
# so voltam quando existirem e clicarem.

MAX_RECENTES = 6


def _pal():
    return {
        "bg": brand.COLOR_BG, "panel": brand.COLOR_PANEL, "panel_2": brand.COLOR_PANEL_2,
        "border": brand.COLOR_BORDER, "text": brand.COLOR_TEXT,
        "text_muted": brand.COLOR_TEXT_MUTED, "text_faint": brand.COLOR_TEXT_FAINT,
        "brand": brand.COLOR_PRIMARY_DEEP, "brand_2": brand.COLOR_PRIMARY,
        "accent": brand.COLOR_ACCENT, "moss": brand.COLOR_MOSS, "earth": brand.COLOR_EARTH,
        "hover": brand.COLOR_HOVER, "active_bg": brand.COLOR_ACTIVE_BG,
        "active_fg": brand.COLOR_ACTIVE_FG,
    }


class ClickableFrame(QFrame):
    clicked = pyqtSignal()

    def mousePressEvent(self, e):
        if e.button() == Qt.LeftButton:
            self.clicked.emit()
        super().mousePressEvent(e)


def _iface_action(iface, method_names, object_names):
    for m in method_names:
        fn = getattr(iface, m, None)
        if callable(fn):
            try:
                res = fn()
                if isinstance(res, QAction):
                    return res.trigger
                return None
            except Exception:
                pass
    try:
        for act in iface.mainWindow().findChildren(QAction):
            if act.objectName() in object_names:
                return act.trigger
    except Exception:
        pass
    return None


def _wire(iface, kind):
    if iface is None:
        return None
    if kind == "new":
        return lambda: (iface.newProject() if hasattr(iface, "newProject") else None)
    if kind == "open":
        return _iface_action(iface, ["actionOpenProject"], {"mActionOpenProject"})
    if kind == "data":
        return _iface_action(iface, ["actionDataSourceManager", "actionAddOgrLayer"],
                             {"mActionDataSourceManager", "mActionAddOgrLayer"})
    if kind == "layout":
        return _iface_action(iface, ["actionNewPrintLayout", "actionShowLayoutManager"],
                             {"mActionNewPrintLayout", "mActionShowLayoutManager"})
    return None


def _card(pal, glyph, accent_key, title, sub, on_click=None):
    f = ClickableFrame()
    f.setObjectName("qa")
    f.setCursor(Qt.PointingHandCursor)
    v = QVBoxLayout(f)
    v.setContentsMargins(16, 16, 16, 16)
    v.setSpacing(12)
    tile = QLabel(glyph)
    tile.setObjectName("qatile")
    tile.setAlignment(Qt.AlignCenter)
    tile.setFixedSize(42, 42)
    # RAIO no style.qss (#027). Cor e font-size ficam: a cor e interpolada de
    # brand.COLOR_* por PAPEL (accent_key muda por cartao), e mover isso para o
    # .qss exigiria uma regra por papel - deixaria de ser recolocacao.
    tile.setStyleSheet("QLabel#qatile{background:%s;color:%s;font-size:20px;}"
                       % (pal["active_bg"], pal[accent_key]))
    v.addWidget(tile)
    t = QLabel("<div style='font-size:14px;font-weight:600;color:%s'>%s</div>"
               "<div style='font-size:12px;color:%s;margin-top:2px'>%s</div>"
               % (pal["text"], title, pal["text_faint"], sub))
    t.setTextFormat(Qt.RichText)
    v.addWidget(t)
    # RAIO no style.qss (#027). A borda de :hover fica: ela e interpolada por
    # papel (accent_key), como a cor do tile acima.
    f.setStyleSheet("QFrame#qa{background:%s;border:1px solid %s;}"
                    "QFrame#qa:hover{border:1px solid %s;}"
                    % (pal["panel"], pal["border"], pal[accent_key]))
    if on_click is not None:
        f.clicked.connect(on_click)
    return f


def recentes_reais(limite=MAX_RECENTES):
    """A lista de projetos recentes DO QGIS (D8).

    O QGIS ja mantem a lista de verdade em QgsSettings, sob
    `UI/recentProjects/<n>/{title,path,crs}` - a mesma que alimenta a welcome
    nativa. Lemos dela; nao inventamos nenhuma.

    Devolve [(titulo, caminho, existe)], so com projetos cujo arquivo ainda
    esta no disco: um recente apagado do disco e um link morto, e link morto
    e a mesma mentira dos dados de exemplo, com outra cara.
    """
    itens = []
    try:
        from qgis.core import QgsSettings
        s = QgsSettings()
        s.beginGroup("UI/recentProjects")
        try:
            for chave in s.childGroups():
                s.beginGroup(chave)
                try:
                    caminho = s.value("path", "") or ""
                    titulo = s.value("title", "") or ""
                finally:
                    s.endGroup()
                if not caminho:
                    continue
                if not os.path.exists(caminho):
                    continue
                if not titulo:
                    titulo = os.path.splitext(os.path.basename(caminho))[0]
                itens.append((titulo, caminho))
        finally:
            s.endGroup()
    except Exception:
        return []
    return itens[:limite]


def _item_recente(pal, titulo, caminho, on_click):
    """Um recente REAL, e clicavel de verdade (D8)."""
    f = ClickableFrame()
    f.setObjectName("rec")
    f.setCursor(Qt.PointingHandCursor)
    v = QVBoxLayout(f)
    v.setContentsMargins(10, 8, 10, 8)
    v.setSpacing(1)
    t = QLabel(titulo)
    t.setStyleSheet("font-size:13px;font-weight:600;color:%s;" % pal["text"])
    c = QLabel(caminho)
    c.setStyleSheet("font-size:11px;color:%s;" % pal["text_faint"])
    v.addWidget(t)
    v.addWidget(c)
    # RAIO no style.qss (#027).
    f.setStyleSheet("QFrame#rec{background:transparent;border:1px solid transparent;}"
                    "QFrame#rec:hover{background:%s;border:1px solid %s;}"
                    % (pal["panel"], pal["border"]))
    f.clicked.connect(on_click)
    return f


def _vazio(pal, texto):
    """Estado vazio EXPLICITO (D8): sem hover, sem cursor de mao, sem moldura
    de cartao - nada que prometa clique."""
    l = QLabel(texto)
    l.setWordWrap(True)
    l.setStyleSheet("font-size:12px;color:%s;padding:10px 0;" % pal["text_faint"])
    return l


def _section_title(pal, text):
    l = QLabel(text)
    l.setStyleSheet("font-size:15px;font-weight:600;color:%s;" % pal["text"])
    return l


def _divider(pal):
    line = QFrame()
    line.setFrameShape(QFrame.HLine)
    line.setStyleSheet("color:%s;background:%s;max-height:1px;" % (pal["border"], pal["border"]))
    return line


def build_home(iface=None):
    pal = _pal()
    root = QWidget()
    root.setObjectName("ImanHome")
    outer = QVBoxLayout(root)
    outer.setContentsMargins(0, 0, 0, 0)

    scroll = QScrollArea()
    scroll.setWidgetResizable(True)
    scroll.setFrameShape(QFrame.NoFrame)
    outer.addWidget(scroll)

    page = QWidget()
    scroll.setWidget(page)
    L = QVBoxLayout(page)
    L.setContentsMargins(30, 28, 30, 26)
    L.setSpacing(22)

    # hero
    hero = QHBoxLayout()
    left = QVBoxLayout()
    left.setSpacing(6)
    eyebrow = QLabel("INTELIGÊNCIA TERRITORIAL · CADASTRO & REURB — CEARÁ")
    eyebrow.setStyleSheet("font-size:11px;letter-spacing:1.4px;color:%s;font-weight:600;" % pal["brand_2"])
    left.addWidget(eyebrow)
    h1 = QLabel("Bem-vindo ao %s" % brand.PRODUCT_NAME)
    h1.setStyleSheet("font-size:26px;font-weight:600;color:%s;" % pal["text"])
    left.addWidget(h1)
    sub = QLabel(SUBTITLE)
    sub.setWordWrap(True)
    sub.setStyleSheet("font-size:14px;color:%s;" % pal["text_muted"])
    sub.setMaximumWidth(620)
    left.addWidget(sub)
    hero.addLayout(left, 1)

    right = QVBoxLayout()
    right.setAlignment(Qt.AlignRight | Qt.AlignTop)
    right.setSpacing(8)
    # DB-24: a versao exibida vem de brand.versao_exibida(), que acrescenta o
    # commit curto do BUILD_ID.txt que o instalador entregou. Sem o arquivo
    # (arvore de desenvolvimento) mostra so a versao - nao inventa commit.
    ver = QLabel("● versão %s" % brand.versao_exibida())
    # NOME DE OBJETO NOVO (#027), e nome de objeto e CONTRATO: este estilo nao
    # tinha seletor nenhum - era uma lista de propriedades solta - e sem nome
    # nao havia como o .qss alcancar so este QLabel. "ImanHomeVersao" e o badge
    # de versao da home, e o style.qss depende dele.
    ver.setObjectName("ImanHomeVersao")
    # RAIO no style.qss (#027).
    ver.setStyleSheet("QLabel#ImanHomeVersao{font-size:12px;color:%s;background:%s;"
                      "border:1px solid %s;padding:6px 11px;}"
                      % (pal["text_muted"], pal["panel"], pal["border"]))
    right.addWidget(ver, 0, Qt.AlignRight)
    crs = QLabel("🌐 " + CRS_LABEL)
    crs.setStyleSheet("font-size:12px;color:%s;" % pal["text_faint"])
    right.addWidget(crs, 0, Qt.AlignRight)
    hero.addLayout(right, 0)
    L.addLayout(hero)

    # quick actions
    qa = QGridLayout()
    qa.setSpacing(14)
    cards = [
        ("＋", "brand_2", "Novo projeto", "Comece do zero", _wire(iface, "new")),
        ("📂", "brand_2", "Abrir projeto", "Arquivos .qgz / .qgs", _wire(iface, "open")),
        ("⬆", "accent", "Carregar dados", "Raster · Vetor · Malha", _wire(iface, "data")),
        ("▤", "moss", "Novo layout", "Composição de impressão", _wire(iface, "layout")),
    ]
    for i, (g, key, t, s, cb) in enumerate(cards):
        qa.addWidget(_card(pal, g, key, t, s, cb), 0, i)
    L.addLayout(qa)

    # --------------------------------------------- projetos recentes (D8)
    # A lista vem do QGIS. Vazia, mostra-se vazia.
    L.addWidget(_section_title(pal, "Projetos recentes"))
    recentes = recentes_reais()
    if recentes:
        for titulo, caminho in recentes:
            def _abre(c=caminho):
                if iface is not None:
                    try:
                        iface.addProject(c)
                    except Exception:
                        pass
            L.addWidget(_item_recente(pal, titulo, caminho, _abre))
    else:
        L.addWidget(_vazio(
            pal,
            "Nenhum projeto recente ainda. Comece por “Novo projeto” "
            "ou abra um projeto existente — os que você usar aparecem aqui."))

    # créditos do QGIS (BL-1/BL-2)
    L.addWidget(_divider(pal))
    credits = QLabel("powered by QGIS — " + brand.CREDITS_QGIS.replace("\n", " "))
    credits.setWordWrap(True)
    credits.setStyleSheet("font-size:11px;color:%s;" % pal["text_faint"])
    L.addWidget(credits)

    root.setStyleSheet("QWidget#ImanHome{background:%s;}" % pal["bg"])
    root._page = page
    return root
