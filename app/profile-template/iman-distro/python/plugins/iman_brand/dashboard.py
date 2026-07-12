# -*- coding: utf-8 -*-
"""Home / dashboard IMAN Terra — miolo de boas-vindas (no lugar do canvas-vazio).

Promovido do spike #003 (`sonda_c_dock/dashboard.py`, ROBUSTO) para produção na
fatia #006. Paleta da FONTE ÚNICA de produção (`brand.py`, D-IMAN-026); conteúdo
REURB / cadastral do CEARÁ; fonte do sistema; CRS SIRGAS 2000 / UTM 24S. Quick-
actions ligadas a ações REAIS do QGIS. Créditos do QGIS no rodapé (BL-1/BL-2).
"""
from qgis.PyQt.QtCore import Qt, pyqtSignal
from qgis.PyQt.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QGridLayout, QLabel, QFrame,
    QScrollArea, QAction,
)

from . import brand

SUBTITLE = "Regularização fundiária, cadastro territorial e cartografia — em uma só plataforma geoespacial."
CRS_LABEL = "EPSG:31984 · SIRGAS 2000 / UTM 24S"

RECENTS = [
    ("REURB-S — Núcleo Alto da Boa Vista", "~/iman/reurb/sobral_alto_boa_vista.qgz", "Hoje"),
    ("Cadastro territorial urbano — Juazeiro do Norte", "~/iman/cadastro/juazeiro_urbano.qgz", "Ontem"),
    ("Parcelamento do solo — Quixadá", "~/iman/projetos/quixada_parcelamento.qgz", "3 dias"),
    ("Perímetro & confrontações — Crateús", "~/iman/reurb/crateus_perimetro.qgz", "1 sem"),
]
TEMPLATES = [
    ("Projeto cadastral vazio", "EPSG:31984"),
    ("REURB-S — núcleo informal", "Lotes · Vias"),
    ("Planta de parcelamento", "NBR 13.133"),
    ("Memorial descritivo", "Vértices · Azimutes"),
    ("Base cartográfica municipal", "Ceará"),
    ("Confrontações & vértices", "Cadastro"),
]
CHIPS = [
    "Camadas vetoriais", "Cadastro territorial", "Processamento",
    "Complementos IMAN", "Documentação REURB", "GPS/GNSS",
]


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
    tile.setStyleSheet("QLabel#qatile{background:%s;color:%s;border-radius:11px;font-size:20px;}"
                       % (pal["active_bg"], pal[accent_key]))
    v.addWidget(tile)
    t = QLabel("<div style='font-size:14px;font-weight:600;color:%s'>%s</div>"
               "<div style='font-size:12px;color:%s;margin-top:2px'>%s</div>"
               % (pal["text"], title, pal["text_faint"], sub))
    t.setTextFormat(Qt.RichText)
    v.addWidget(t)
    f.setStyleSheet("QFrame#qa{background:%s;border:1px solid %s;border-radius:14px;}"
                    "QFrame#qa:hover{border:1px solid %s;}"
                    % (pal["panel"], pal["border"], pal[accent_key]))
    if on_click is not None:
        f.clicked.connect(on_click)
    return f


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
    ver = QLabel("● versão %s" % brand.VERSION)
    ver.setStyleSheet("font-size:12px;color:%s;background:%s;border:1px solid %s;border-radius:9px;padding:6px 11px;"
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

    # two columns
    cols = QHBoxLayout()
    cols.setSpacing(24)
    rec = QVBoxLayout()
    rec.setSpacing(8)
    rec.addWidget(_section_title(pal, "Projetos recentes"))
    for name, path, date in RECENTS:
        item = QLabel(
            "<table width='100%%'><tr>"
            "<td><div style='font-size:13px;font-weight:600;color:%s'>%s</div>"
            "<div style='font-size:12px;color:%s'>%s</div></td>"
            "<td align='right' style='color:%s;font-size:11px'>%s</td></tr></table>"
            % (pal["text"], name, pal["text_faint"], path, pal["text_faint"], date))
        item.setTextFormat(Qt.RichText)
        item.setStyleSheet("QLabel{padding:9px 10px;border-radius:10px;}"
                           "QLabel:hover{background:%s;}" % pal["panel"])
        rec.addWidget(item)
    rec.addStretch(1)
    cols.addLayout(rec, 3)

    tpl = QVBoxLayout()
    tpl.setSpacing(8)
    tpl.addWidget(_section_title(pal, "Modelos de projeto"))
    grid = QGridLayout()
    grid.setSpacing(11)
    for idx, (name, meta) in enumerate(TEMPLATES):
        card = QFrame()
        card.setStyleSheet("QFrame{background:%s;border:1px solid %s;border-radius:12px;}"
                           "QFrame:hover{border:1px solid %s;}"
                           % (pal["panel"], pal["border"], pal["brand_2"]))
        cv = QVBoxLayout(card)
        cv.setContentsMargins(11, 10, 11, 10)
        cv.setSpacing(3)
        n = QLabel(name)
        n.setStyleSheet("font-size:12.5px;font-weight:600;color:%s;" % pal["text"])
        n.setWordWrap(True)
        m = QLabel(meta)
        m.setStyleSheet("font-size:11px;color:%s;" % pal["text_faint"])
        cv.addWidget(n)
        cv.addWidget(m)
        grid.addWidget(card, idx // 2, idx % 2)
    tpl.addLayout(grid)
    tpl.addStretch(1)
    cols.addLayout(tpl, 2)
    L.addLayout(cols)

    # recursos
    L.addWidget(_section_title(pal, "Recursos & atalhos"))
    chips = QHBoxLayout()
    chips.setSpacing(9)
    for c in CHIPS:
        ch = QLabel("●  " + c)
        ch.setStyleSheet("font-size:12px;color:%s;background:%s;border:1px solid %s;border-radius:9px;padding:7px 12px;"
                         % (pal["text_muted"], pal["panel"], pal["border"]))
        chips.addWidget(ch)
    chips.addStretch(1)
    L.addLayout(chips)

    # créditos do QGIS (BL-1/BL-2)
    L.addWidget(_divider(pal))
    credits = QLabel("powered by QGIS — " + brand.CREDITS_QGIS.replace("\n", " "))
    credits.setWordWrap(True)
    credits.setStyleSheet("font-size:11px;color:%s;" % pal["text_faint"])
    L.addWidget(credits)

    root.setStyleSheet("QWidget#ImanHome{background:%s;}" % pal["bg"])
    root._page = page
    return root
