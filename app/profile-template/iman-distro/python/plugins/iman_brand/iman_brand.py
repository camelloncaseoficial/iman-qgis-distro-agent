# -*- coding: utf-8 -*-
"""IMAN Terra — plugin de marca.

Camada de experiência institucional sobre o QGIS LTR (Opção 1, no-fork):
- **Home no MIOLO** (fatia #006): no lugar do canvas-vazio, uma home de boas-vindas
  (REURB/Ceará) via `takeCentralWidget()` + `QStackedWidget([canvas, home])` — o
  caminho ROBUSTO provado na Sonda B do spike #003. Guardrail defensivo re-instala o
  stack se o QGIS/outro plugin reivindicar o central widget; se o central
  desestabilizar, cai para um DOCK flutuante amplo (Sonda C, também robusto) —
  declarado, nunca silencioso.
- Menu próprio, toolbar, ação "Sobre o IMAN Terra" (mantendo o About nativo).

APIs públicas do QGIS/Qt (BL-6). Marca da fonte única `brand.py` (BL-4). Nada aqui
se apresenta como QGIS oficial (BL-1/BL-2).
"""
import os
import re
import webbrowser

from qgis.PyQt.QtCore import Qt, QUrl, QTimer, QSize, QObject, QEvent
from qgis.PyQt.QtGui import QIcon, QPixmap, QDesktopServices
from qgis.PyQt.QtWidgets import (
    QAction, QDockWidget, QWidget, QVBoxLayout, QStackedWidget, QMessageBox,
    QToolButton, QMenu, QToolBar, QLabel, QLineEdit, QStyle, QStyleOptionFrame,
)

from qgis.core import QgsProject

from . import brand
from . import dashboard
from . import sobre

_DIR = os.path.dirname(__file__)
_RES = os.path.join(_DIR, "resources")

# --- Status bar: o campo de coordenadas (D2/D3) -------------------------------
# O QGIS dimensiona esse campo pela metrica do texto que ele mesmo escreve, e
# nao tem piso nem teto: vazio, encolhe para 24 px; exibindo a EXTENSAO de um
# projeto sem camadas, o texto vem em DBL_MAX e o campo vai a milhares de px.
# A camada de marca, que estilizou o campo, assume as duas pontas.
COORD_REFERENCIA = "555519,9  9585490,5"                             # D2 - piso
EXTENSAO_REFERENCIA = "555519,9  9585490,5 : 557706,8  9587051,2"    # D3 - teto


class _ContemLargura(QObject):
    """Mantem o campo de coordenadas entre um piso e um teto (D2 e D3).

    Chamar setMinimumWidth/setMaximumWidth uma vez nao basta: o QGIS
    redimensiona o campo a cada troca de texto e a cada troca de projeto, e
    desfaz os dois limites. Medido em 2026-09-07: depois de um ciclo abrir
    projeto -> projeto novo, o campo voltava de 122 px para 24 px. Este filtro
    reimpoe os limites no proximo evento de geometria.
    """

    def __init__(self, alvo, piso, teto, parent=None):
        super().__init__(parent)
        self._alvo = alvo
        self._piso = int(piso)
        self._teto = int(teto)

    def eventFilter(self, obj, ev):
        if obj is self._alvo and ev.type() in (
                QEvent.Resize, QEvent.LayoutRequest, QEvent.Show,
                QEvent.PolishRequest):
            try:
                if self._alvo.minimumWidth() < self._piso:
                    self._alvo.setMinimumWidth(self._piso)
                if self._alvo.minimumWidth() > self._teto:
                    self._alvo.setMinimumWidth(self._teto)
                if self._alvo.maximumWidth() > self._teto:
                    self._alvo.setMaximumWidth(self._teto)
            except Exception:
                pass
        return False


def _res(name):
    return os.path.join(_RES, name)


class ImanBrandPlugin:
    def __init__(self, iface):
        self.iface = iface
        self.actions = []
        self.menu = brand.PRODUCT_NAME
        self.toolbar = None
        # host da home
        self.mode = None          # "central" | "dock"
        self.stack = None
        self.canvas_page = None   # container central original do QGIS (idx 0)
        self.home_page = None     # home (idx 1)
        self.dock = None
        self._guard = None
        self._reinstalls = 0
        self._hidden_toolbars = []
        self._contem_coords = None
        self._campo_coords = None
        self._retitulando = False
        self._pousou = False
        self._acao_sobre_ajuda = None

    # ------------------------------------------------------------------ setup
    def initGui(self):
        self.toolbar = self.iface.addToolBar(brand.PRODUCT_NAME)
        self.toolbar.setObjectName("ImanTerraToolbar")
        icon = QIcon(_res("icon.png"))

        # Ações (vão para o menu Complementos ▸ IMAN Terra e para o dropdown).
        self._add_action(icon, "Início", self.show_home,
                         tip="Mostrar a home do %s" % brand.PRODUCT_NAME)
        self._add_action(icon, "Abrir projeto demo", self.open_demo,
                         tip="Abrir o projeto de demonstração welcome.qgz")
        self._add_action(icon, "Documentação", self.open_docs,
                         tip="Abrir a documentação do %s" % brand.PRODUCT_NAME)
        self._add_action(icon, "Site do Instituto IMAN", self.open_site,
                         tip="Abrir o site do Instituto IMAN")
        self._add_action(icon, "Sobre o %s" % brand.PRODUCT_NAME, self.show_about,
                         tip="Sobre o %s (créditos do QGIS; o About nativo segue "
                             "em Ajuda ▸ Sobre)" % brand.PRODUCT_NAME)

        # UM botão de marca proeminente na toolbar (comp: dropdown "Complementos
        # IMAN"), no lugar de 5 ícones repetidos.
        self._build_menu_button(icon)

        self._instala_sobre_no_ajuda()
        self._instala_titulo()
        for sig, slot in (("projectRead", self._on_project_read),
                          ("newProjectCreated", self._on_new_project)):
            try:
                getattr(self.iface, sig).connect(slot)
            except Exception:
                pass

        # Instala a home no centro depois que o startup do QGIS assenta; declutter
        # das toolbars nativas ruidosas + banner de versão (Fase 3).
        QTimer.singleShot(900, self._install_center)
        QTimer.singleShot(1600, self._declutter_toolbars)
        QTimer.singleShot(1800, self._ajusta_campo_de_coordenadas)
        QTimer.singleShot(2200, self._version_banner)

    def _build_menu_button(self, icon):
        btn = QToolButton(self.iface.mainWindow())
        btn.setObjectName("ImanTerraMenuBtn")
        btn.setIcon(icon)
        btn.setText(" %s " % brand.PRODUCT_NAME)
        btn.setToolButtonStyle(Qt.ToolButtonTextBesideIcon)
        btn.setPopupMode(QToolButton.InstantPopup)
        btn.setIconSize(QSize(18, 18))
        btn.setCursor(Qt.PointingHandCursor)
        menu = QMenu(btn)
        for a in self.actions:
            menu.addAction(a)
        btn.setMenu(menu)
        btn.setStyleSheet(
            "QToolButton#ImanTerraMenuBtn{background:%s;color:#FFFFFF;border:none;"
            "border-radius:8px;padding:5px 10px;font-weight:600;}"
            "QToolButton#ImanTerraMenuBtn:hover{background:%s;}"
            "QToolButton#ImanTerraMenuBtn::menu-indicator{image:none;width:0;}"
            % (brand.COLOR_PRIMARY, brand.COLOR_PRIMARY_DEEP))
        self.toolbar.addWidget(btn)
        self._menu_button = btn

    def _declutter_toolbars(self):
        """Densidade minimalista do comp: oculta toolbars nativas ruidosas, deixa as
        essenciais (arquivo, navegação, atributos, fonte de dados, digitalização —
        cadastro precisa dela — e a de marca). Reversível em Exibir ▸ Barras."""
        keep = {
            "mFileToolBar", "mMapNavToolBar", "mAttributesToolBar",
            "mDataSourceManagerToolBar", "mDigitizeToolBar",
            "mAdvancedDigitizeToolBar", "mShapeDigitizeToolBar",
            "ImanTerraToolbar",
        }
        try:
            for tb in self.iface.mainWindow().findChildren(QToolBar):
                name = tb.objectName()
                if name and name not in keep and tb.isVisible():
                    tb.hide()
                    self._hidden_toolbars.append(tb)
        except Exception:
            pass

    # ------------------------------------------------- status bar (D2 / D3)
    def _campo_de_coordenadas(self):
        """O QLineEdit do QgsStatusBarCoordinatesWidget: irmao de 'mCoordsLabel'."""
        try:
            lbl = self.iface.mainWindow().statusBar().findChild(QLabel, "mCoordsLabel")
            if lbl is None:
                return None
            return lbl.parentWidget().findChild(QLineEdit)
        except Exception:
            return None

    def _ajusta_campo_de_coordenadas(self):
        """Reserva o piso (D2) e impoe o teto (D3) do campo de coordenadas.

        D2 - vazio, o campo encolhe para 24 px e nao cabe uma coordenada. Quem
        estilizou o campo assume reservar espaco para o texto que o produto
        exibe: a coordenada em EPSG:31984, a projecao padrao da distro.
        D3 - exibindo a extensao de um projeto sem camadas, o QGIS escreve
        DBL_MAX e o campo cresce sem teto, arrastando a janela principal para
        fora da tela. O teto e a extensao plausivel; o excedente e cortado no
        campo em vez de deformar a janela.
        """
        le = self._campo_de_coordenadas()
        if le is None:
            return
        try:
            fm = le.fontMetrics()
            # cromo = o que a borda/o tema consomem, medido no proprio widget
            opt = QStyleOptionFrame()
            le.initStyleOption(opt)
            interno = le.style().subElementRect(
                QStyle.SE_LineEditContents, opt, le).width()
            cromo = max(0, le.width() - interno)

            piso = fm.horizontalAdvance(COORD_REFERENCIA) + cromo + 2
            teto = fm.horizontalAdvance(EXTENSAO_REFERENCIA) + cromo + 2

            le.setMinimumWidth(piso)
            le.setMaximumWidth(teto)
            self._contem_coords = _ContemLargura(le, piso, teto, self.iface.mainWindow())
            le.installEventFilter(self._contem_coords)
            self._campo_coords = le
        except Exception:
            pass

    def _version_banner(self):
        try:
            bar = self.iface.messageBar()
            bar.pushMessage(
                brand.PRODUCT_NAME,
                "Versão %s — plataforma geoespacial institucional, powered by QGIS. "
                "Comece pela home (Complementos ▸ %s ▸ Início)."
                % (brand.VERSION, brand.PRODUCT_NAME),
                level=0, duration=9)
        except Exception:
            pass

    def _instala_sobre_no_ajuda(self):
        """Poe "Sobre o <produto>" no menu Ajuda (D10).

        O Sobre existia so no dropdown da toolbar, tres niveis abaixo em
        `Complementos > IMAN Terra >`. Existia e funcionava - so nao estava
        onde se procura. Medido no #017: zero ocorrencias no menu Ajuda.

        O Sobre NATIVO do QGIS continua no mesmo menu, ao lado. BL-1.
        """
        try:
            menu = self.iface.helpMenu()
            if menu is None:
                return
            self._acao_sobre_ajuda = QAction(
                QIcon(_res("icon.png")),
                "Sobre o %s" % brand.PRODUCT_NAME,
                self.iface.mainWindow())
            self._acao_sobre_ajuda.triggered.connect(self.show_about)
            menu.addAction(self._acao_sobre_ajuda)
        except Exception:
            self._acao_sobre_ajuda = None

    # --------------------------------------------- titulo da janela (D5)
    #
    # O titulo NAO e nosso para escrever - so o sufixo e. Quem sabe qual
    # projeto esta aberto, se ha alteracao nao salva e como isso se escreve no
    # idioma do usuario e o QGIS. Antes desta fatia a camada de marca cravava
    # `WINDOW_TITLE` por cima, de DUAS fontes independentes (aqui e no
    # iman_startup.py), e o resultado era regressao, nao ausencia: medido em
    # 2026-09-07, o QGIS tinha escrito "spike017-projeto-alfa - QGIS" e a
    # marca apagava, deixando "IMAN Terra - powered by QGIS" em todo estado.
    #
    # Agora existe UMA fonte: este gancho, que reage ao titulo que o QGIS
    # acabou de compor e troca apenas o sufixo.
    def _instala_titulo(self):
        try:
            win = self.iface.mainWindow()
            win.windowTitleChanged.connect(self._retitula)
            self._retitula(win.windowTitle())
        except Exception:
            pass

    # Separador de marca: HIFEN, sempre. O QGIS compoe com TRAVESSAO (U+2014,
    # medido no #021); o produto nao. Quem escreve o sufixo somos nos, entao a
    # pontuacao do sufixo e nossa - o prefixo continua como o usuario o nomeou.
    SEPARADOR_DE_MARCA = " - "

    # O que o QGIS pendura no FIM do titulo:
    #     [separador opcional] QGIS [ " [<perfil>]" opcional ]
    #
    # O colchete so aparece quando ha MAIS DE UM perfil na raiz de perfis - e
    # foi por ele que o D5 reabriu. A ancora anterior era `QGIS(\s*)$`: com
    # " [iman-distro]" depois, "QGIS" deixa de estar no fim, a regex nao casa,
    # e a substituicao NUNCA acontece. O produto passava a exibir o nome do
    # QGIS como se fosse o seu, e o nome interno do perfil vazava para a barra
    # de titulo. Medido em 2026-09-09: a propria bancada ja estava nesse
    # estado, com dois perfis na raiz do produto.
    #
    # A classe de separadores e larga de proposito (hifen, hifen inquebravel,
    # travessao de figura, meia-risca, travessao, barra horizontal): o QGIS
    # compoe em U+2014 hoje, e nao ha contrato upstream que o congele.
    _RE_SUFIXO_DO_QGIS = re.compile(
        u"(?:\\s*[‐-―\\-]\\s*)?QGIS\\s*(?:\\[[^\\]]*\\])?\\s*$"
    )

    @staticmethod
    def compoe_titulo(titulo):
        """"<Projeto> — QGIS [perfil]"  ->  "<Projeto> - IMAN Terra".

        SO O SUFIXO E NOSSO. O prefixo e o nome que o usuario deu ao arquivo -
        pode ter travessao, pode ter a palavra QGIS, pode ter qualquer coisa - e
        sai daqui intocado. Quem sabe qual projeto esta aberto e se ha alteracao
        nao salva e o QGIS; recompor o titulo do zero foi o defeito original do
        D5 e nao volta.

        NAO SE REALIMENTA: depois da troca o titulo termina em IMAN Terra, e
        `_RE_SUFIXO_DO_QGIS` exige QGIS no fim - entao a segunda passada nao
        casa e devolve a mesma string. `_retitula` so chama `setWindowTitle`
        quando o valor MUDA, e ainda ha o guarda `_retitulando`. Sao tres
        travas, e a primeira e a propria forma da regex.
        """
        if not titulo:
            return titulo
        m = ImanBrandPlugin._RE_SUFIXO_DO_QGIS.search(titulo)
        if m is None:
            return titulo
        prefixo = titulo[:m.start()].rstrip()
        if not prefixo:
            # O QGIS nao pendurou projeto nenhum: o titulo E o sufixo.
            return brand.PRODUCT_NAME
        return prefixo + ImanBrandPlugin.SEPARADOR_DE_MARCA + brand.PRODUCT_NAME

    def _retitula(self, titulo=None):
        if self._retitulando:
            return
        try:
            win = self.iface.mainWindow()
            atual = titulo if titulo is not None else win.windowTitle()
            novo = self.compoe_titulo(atual)
            if novo and novo != atual:
                self._retitulando = True
                try:
                    win.setWindowTitle(novo)
                finally:
                    self._retitulando = False
        except Exception:
            self._retitulando = False

    def _add_action(self, icon, text, callback, tip=""):
        action = QAction(icon, text, self.iface.mainWindow())
        action.triggered.connect(callback)
        if tip:
            action.setStatusTip(tip)
            action.setToolTip(tip)
        self.iface.addPluginToMenu(self.menu, action)
        self.actions.append(action)
        return action

    # -------------------------------------------------------- home no centro
    def _install_center(self):
        """ALVO: home no miolo (Sonda B). Fallback declarado: dock (Sonda C)."""
        try:
            win = self.iface.mainWindow()
            central = win.takeCentralWidget()   # container central do QGIS (sem deletar)
            if central is None:
                raise RuntimeError("takeCentralWidget devolveu None")
            stack = QStackedWidget()
            stack.addWidget(central)                       # idx 0 = canvas/welcome do QGIS
            home = dashboard.build_home(self.iface)        # idx 1 = home IMAN
            stack.addWidget(home)
            win.setCentralWidget(stack)
            self.stack, self.canvas_page, self.home_page = stack, central, home
            self.mode = "central"
            self._show_home()                              # provisorio
            # O POUSO e decidido por ESTADO, depois que o arranque assenta -
            # nunca por evento. Ver _decide_pouso.
            QTimer.singleShot(2500, self._decide_pouso)
            # Guardrail: reasserção defensiva do contrato de central widget.
            self._guard = QTimer(win)
            self._guard.timeout.connect(self._reassert)
            self._guard.start(2000)
        except Exception as e:
            self._install_dock_fallback("erro ao instalar no centro: %s" % e)

    def _reassert(self):
        """Guardrail: detecta se o contrato de central widget foi quebrado por
        terceiro (QGIS/outro plugin chamou setCentralWidget) e, nesse caso, cai para
        o DOCK robusto — SEM re-embrulhar o central. Re-embrulhar é inseguro: um
        setCentralWidget de terceiro já deletou o container do canvas, e tentar
        reconstruir por cima corrompe o heap. O dock é a recuperação segura e
        declarada (Sonda C). Em uso normal, o QGIS NÃO reivindica o central (spike
        #003), então o guard fica quieto."""
        if self.mode != "central":
            return
        reclaimed = False
        try:
            if self.iface.mainWindow().centralWidget() is not self.stack:
                reclaimed = True
        except Exception:
            reclaimed = True  # self.stack já foi deletado pelo terceiro
        if reclaimed:
            self._reinstalls += 1
            try:
                self._guard.stop()
            except Exception:
                pass
            self.mode = None
            self.stack = self.home_page = self.canvas_page = None
            self._install_dock_fallback("central widget reivindicado por terceiro")

    def _show_home(self):
        if self.mode == "central" and self.stack is not None and self.home_page is not None:
            try:
                self.stack.setCurrentWidget(self.home_page)
            except Exception:
                pass

    def _show_canvas(self):
        if self.mode == "central" and self.stack is not None and self.canvas_page is not None:
            try:
                self.stack.setCurrentWidget(self.canvas_page)
            except Exception:
                pass

    # ------------------------------------------- politica do miolo (D6/D7)
    #
    # Regra unica, escrita em docs/branding-contract.md §1.8: a home e o
    # POUSO; qualquer acao de projeto leva ao CANVAS; "Inicio" traz a home de
    # volta. Nada mais move o miolo.
    #
    # `_pousou` existe porque no arranque o QGIS emite eventos de projeto
    # ANTES de a home existir. Sem essa guarda, o estado E1 (o produto abre
    # sem projeto -> home) dependeria de quem chega primeiro, o evento ou o
    # QTimer de 900 ms - e "depende" e exatamente como o D7 nasce.
    def _decide_pouso(self):
        """Decide E1/E7 pelo ESTADO, uma vez, quando o arranque assenta.

        D7, reproduzido em 2026-09-07 na SEGUNDA execucao com o perfil ja
        usado: o QGIS emite `newProjectCreated` para o projeto vazio inicial
        DEPOIS que a home foi instalada. Reagindo a esse evento como se fosse
        acao do usuario (E4 -> canvas), a home saia do miolo e o que aparecia
        era a welcome NATIVA do QGIS na pagina 0. Medido: pagina
        'centralwidget', welcome nativa visivel, home escondida.

        Reagir a evento e frageil por construcao - o resultado depende de quem
        chega primeiro. Aqui o pouso olha o ESTADO: se ha projeto carregado,
        canvas (E7); se nao ha, home (E1). Depois disso os eventos passam a
        valer, porque a partir dai eles sao mesmo do usuario.
        """
        try:
            tem_projeto = bool(QgsProject.instance().fileName())
        except Exception:
            tem_projeto = False
        if tem_projeto:
            self._show_canvas()      # E7 - o QGIS restaurou um projeto
        else:
            self._show_home()        # E1 - o pouso
        self._pousou = True

    def _on_project_read(self):
        # E2/E3/E5 - abriu um projeto -> canvas
        if not self._pousou:
            return
        self._show_canvas()

    def _on_new_project(self):
        # E4 - criou um projeto -> canvas. Antes desta fatia era _show_home(),
        # e o comando "Novo projeto" parecia inerte (D6).
        if not self._pousou:
            return
        self._show_canvas()

    # ------------------------------------------- fallback: dock (Sonda C)
    def _install_dock_fallback(self, reason):
        if self.mode == "dock":
            return
        try:
            QgsMessageLog = __import__("qgis.core", fromlist=["QgsMessageLog"]).QgsMessageLog
            QgsMessageLog.logMessage("Home no centro indisponível (%s); usando dock." % reason,
                                     "IMAN Terra")
        except Exception:
            pass
        # restaura o canvas do QGIS ao miolo (tira-o do stack ANTES de trocar o
        # central, senão o delete do stack levaria o canvas junto)
        try:
            win = self.iface.mainWindow()
            if self.canvas_page is not None and win.centralWidget() is self.stack:
                self.stack.removeWidget(self.canvas_page)
                win.setCentralWidget(self.canvas_page)
        except Exception:
            pass
        self.mode = "dock"
        self.stack = self.home_page = self.canvas_page = None
        self._build_dock()

    def _build_dock(self):
        if self.dock is not None:
            self.dock.show(); self.dock.raise_(); return
        dock = QDockWidget("IMAN Terra — Início", self.iface.mainWindow())
        dock.setObjectName("ImanTerraHomeDock")
        holder = QWidget()
        lay = QVBoxLayout(holder)
        lay.setContentsMargins(0, 0, 0, 0)
        lay.addWidget(dashboard.build_home(self.iface))
        dock.setWidget(holder)
        dock.setMinimumWidth(560)
        self.iface.addDockWidget(Qt.RightDockWidgetArea, dock)
        dock.setFloating(True)
        dock.resize(940, 640)
        try:
            c = self.iface.mainWindow().frameGeometry().center()
            dock.move(int(c.x() - 470), int(c.y() - 320))
        except Exception:
            pass
        self.dock = dock

    # ---------------------------------------------------------------- actions
    def show_home(self):
        if self.mode == "dock":
            self._build_dock()
        else:
            self._show_home()

    def open_demo(self):
        candidates = []
        env = os.environ.get("IMAN_TERRA_HOME")
        if env:
            candidates.append(os.path.join(env, "demo", "welcome.qgz"))
        here = _DIR
        for _ in range(6):
            here = os.path.dirname(here)
            candidates.append(os.path.join(here, "demo", "welcome.qgz"))
        for path in candidates:
            if path and os.path.exists(path):
                self.iface.addProject(path)
                return
        QMessageBox.information(self.iface.mainWindow(), brand.PRODUCT_NAME,
                               "Projeto demo não encontrado.\nEle é instalado em app/demo/welcome.qgz.")

    def open_docs(self):
        self._open_url(brand.URL_DOCS)

    def open_site(self):
        self._open_url(brand.URL_SITE)

    def _open_url(self, url):
        if not QDesktopServices.openUrl(QUrl(url)):
            webbrowser.open(url)

    def show_about(self):
        """Janela propria, nao mais um QMessageBox (D10)."""
        dlg = sobre.SobreDialog(self.iface.mainWindow())
        dlg.exec_()

    # ---------------------------------------------------------------- unload
    def unload(self):
        if self._guard is not None:
            try:
                self._guard.stop()
            except Exception:
                pass
            self._guard = None
        for sig, slot in (("projectRead", self._on_project_read),
                          ("newProjectCreated", self._on_new_project)):
            try:
                getattr(self.iface, sig).disconnect(slot)
            except Exception:
                pass
        try:
            self.iface.mainWindow().windowTitleChanged.disconnect(self._retitula)
        except Exception:
            pass
        # restaura o central widget nativo do QGIS
        if self.mode == "central" and self.stack is not None and self.canvas_page is not None:
            try:
                win = self.iface.mainWindow()
                if win.centralWidget() is self.stack:
                    self.stack.removeWidget(self.canvas_page)
                    win.setCentralWidget(self.canvas_page)
                if self.home_page is not None:
                    self.home_page.deleteLater()
            except Exception:
                pass
        if self.dock is not None:
            try:
                self.iface.removeDockWidget(self.dock)
                self.dock.deleteLater()
            except Exception:
                pass
            self.dock = None
        # tira a acao do menu Ajuda (D10)
        if self._acao_sobre_ajuda is not None:
            try:
                self.iface.helpMenu().removeAction(self._acao_sobre_ajuda)
            except Exception:
                pass
            self._acao_sobre_ajuda = None
        # solta o campo de coordenadas (D2/D3)
        if self._campo_coords is not None:
            try:
                if self._contem_coords is not None:
                    self._campo_coords.removeEventFilter(self._contem_coords)
                self._campo_coords.setMinimumWidth(0)
                self._campo_coords.setMaximumWidth(16777215)
            except Exception:
                pass
            self._campo_coords = None
            self._contem_coords = None
        # restaura as toolbars nativas que o declutter ocultou
        for tb in self._hidden_toolbars:
            try:
                tb.show()
            except Exception:
                pass
        self._hidden_toolbars = []
        for action in self.actions:
            self.iface.removePluginMenu(self.menu, action)
        self.actions = []
        if self.toolbar is not None:
            del self.toolbar
            self.toolbar = None
        self.stack = self.home_page = self.canvas_page = None
