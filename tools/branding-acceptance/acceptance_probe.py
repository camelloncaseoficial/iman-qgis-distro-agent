# -*- coding: utf-8 -*-
"""
#017 - TESTE DE ACEITE da camada de marca do IMAN Terra.

Roda DENTRO do QGIS real (perfil iman-distro, iman_startup.py de verdade),
dirige a UI como um usuario dirigiria, e mede WIDGET VIVO e PIXEL.

REGRA DA FATIA (a que separa asse rcao de ruido):
  NAO vale ler o .qss e procurar string. NAO vale "o tema foi aplicado".
  Vale: o botao existe, esta visivel, tem icone com pixel dentro e tem o
  tamanho do irmao ao lado.

Cada asse rcao carrega o campo `se_quebrado`, que responde a pergunta do C.2:
"o que ela devolve COM o defeito presente?" Se a resposta nao muda entre
produto sao e produto quebrado, a asse rcao nao e evidencia e tem de ser
reescrita - nao marcada como resolvida.

E.1: antes de asserir qualquer coisa, o BASELINE e validado (perfil certo,
plugin vivo, QSS anexado, home instalada). Sem isso, "nenhum defeito
encontrado" nao prova nada - so prova que a camada de marca nunca subiu.

Saida: %SPIKE017_OUT%\aceite.json + shots\*.png
"""
import json
import os
import re
import sys
import traceback

from qgis.PyQt.QtCore import Qt, QTimer, QEventLoop, QPoint, QPointF, QRect
from qgis.PyQt.QtGui import QMouseEvent, QImage, QIcon
from qgis.PyQt.QtWidgets import (
    QApplication, QDockWidget, QLineEdit, QLabel, QToolButton, QAbstractButton,
    QStackedWidget, QWidget, QStyle, QStyleOptionFrame, QStyleOptionDockWidget,
)
from qgis.core import QgsApplication, QgsProject, Qgis
from qgis.utils import iface

OUT      = os.environ.get('SPIKE017_OUT', r'C:\Temp\spike017')
STARTUP  = os.environ.get('SPIKE017_STARTUP', '')
REPO     = os.environ.get('SPIKE017_REPO', '')
SHOTS    = os.path.join(OUT, 'shots')
# 'primeira' = suite completa; 'segunda' = so o pouso, no perfil ja usado (D7)
FASE     = os.environ.get('SPIKE017_FASE', 'primeira')

# Coordenada canonica que a status bar precisa caber: SIRGAS 2000 / UTM 24S,
# a projecao que o produto declara como padrao. E o texto REAL do dominio, nao
# um lorem ipsum: 555519,9  9585490,5
COORD_CANONICA = '555519,9  9585490,5'

resultados = []
notas = []


# ============================================================ infraestrutura
def espera(ms):
    """Espera de verdade, girando o event loop (nao trava a UI)."""
    loop = QEventLoop()
    QTimer.singleShot(ms, loop.quit)
    loop.exec_()


def foto(widget, nome):
    """Foto pelo lado do Qt: independe de quem esta na frente na tela.
    (Aprendido no #016: CopyFromScreen fotografou a janela de outro app.)"""
    try:
        if widget is None:
            return ''
        if not os.path.isdir(SHOTS):
            os.makedirs(SHOTS)
        caminho = os.path.join(SHOTS, nome)
        widget.grab().save(caminho)
        return nome
    except Exception:
        return ''


def cores_distintas(img, limite=64):
    vistas = set()
    w, h = img.width(), img.height()
    if w <= 0 or h <= 0:
        return 0
    for y in range(h):
        for x in range(w):
            vistas.add(img.pixel(x, y))
            if len(vistas) >= limite:
                return len(vistas)
    return len(vistas)


def pixels_de_tinta(img, fundo=None):
    """Quantos pixels diferem da cor do canto superior esquerdo (o fundo).
    Um icone apagado por `titlebar-close-icon: none` desenha ZERO."""
    w, h = img.width(), img.height()
    if w <= 0 or h <= 0:
        return 0, 0
    if fundo is None:
        fundo = img.pixel(0, 0)
    n = 0
    for y in range(h):
        for x in range(w):
            if img.pixel(x, y) != fundo:
                n += 1
    return n, w * h


def registra(aid, defeito, regiao, criterio, ok, medido, se_quebrado,
             evidencia='', status=None):
    resultados.append({
        'id': aid,
        'defeito': defeito,
        'regiao': regiao,
        'criterio': criterio,
        'status': status if status else ('PASS' if ok else 'FAIL'),
        'medido': medido,
        'se_quebrado': se_quebrado,
        'evidencia': evidencia,
    })


def falhou(aid, defeito, regiao, criterio, se_quebrado):
    registra(aid, defeito, regiao, criterio, False,
             {'excecao': traceback.format_exc(limit=4)}, se_quebrado,
             status='N/E')


# ============================================================ localizadores
def win():
    return iface.mainWindow()


def docks_visiveis():
    return [d for d in win().findChildren(QDockWidget) if d.isVisible()]


def widget_coordenadas():
    """QgsStatusBarCoordinatesWidget: o pai do QLabel 'mCoordsLabel'.
    Devolve (container, lineEdit, botaoToggle)."""
    lbl = win().statusBar().findChild(QLabel, 'mCoordsLabel')
    if lbl is None:
        return None, None, None
    cont = lbl.parentWidget()
    le = cont.findChild(QLineEdit)
    btn = None
    for b in cont.findChildren(QToolButton):
        if b.isVisible():
            btn = b
            break
    return cont, le, btn


def largura_util_de_texto(le):
    """Largura REAL disponivel para texto dentro do QLineEdit, ja descontando
    o que o QSS come (padding + borda). O QStyleSheetStyle implementa
    SE_LineEditContents, entao este numero enxerga o tema."""
    opt = QStyleOptionFrame()
    le.initStyleOption(opt)
    r = le.style().subElementRect(QStyle.SE_LineEditContents, opt, le)
    return r.width(), r.height()


def stack_central():
    cw = win().centralWidget()
    return cw if isinstance(cw, QStackedWidget) else None


def plugin_marca():
    try:
        import qgis.utils as qu
        return qu.plugins.get('iman_brand')
    except Exception:
        return None


def home_widget():
    return win().findChild(QWidget, 'ImanHome')


def versao_do_iss():
    if not REPO:
        return None
    p = os.path.join(REPO, 'installer', 'iman-terra.iss')
    if not os.path.exists(p):
        return None
    try:
        with open(p, 'r', encoding='utf-8', errors='replace') as fh:
            m = re.search(r'#define\s+ProductVersion\s+"([^"]+)"', fh.read())
            return m.group(1) if m else None
    except Exception:
        return None


def acoes_do_menu(titulo_regex):
    for a in win().menuBar().actions():
        if re.search(titulo_regex, a.text().replace('&', ''), re.I):
            m = a.menu()
            return list(m.actions()) if m else []
    return []


# ============================================================ E.1 - BASELINE
def valida_baseline():
    """Um aceite que roda sem a camada de marca instalada nao mede o produto -
    mede o QGIS pelado, e devolveria 'nenhum defeito' com o build quebrado.
    Aqui isso e ABORTO, nao aviso."""
    b = {}
    b['perfil'] = QgsApplication.qgisSettingsDirPath()
    b['perfil_e_iman_distro'] = 'iman-distro' in (b['perfil'] or '')
    p = plugin_marca()
    b['plugin_carregado'] = p is not None
    b['plugin_classe'] = type(p).__name__ if p else None
    b['plugin_mode'] = getattr(p, 'mode', None) if p else None
    qss = win().styleSheet() or ''
    b['qss_tamanho'] = len(qss)
    b['qss_marcado'] = '/* IMAN-THEME */' in qss
    b['home_instalada'] = home_widget() is not None
    b['docks_visiveis'] = len(docks_visiveis())
    b['qgis'] = Qgis.QGIS_VERSION
    b['startup_real'] = STARTUP

    falhas = []
    if not b['perfil_e_iman_distro']:
        falhas.append('o perfil em uso nao e o iman-distro (%s)' % b['perfil'])
    if not b['plugin_carregado']:
        falhas.append('o plugin iman_brand NAO esta carregado')
    if not b['qss_marcado']:
        falhas.append('o QSS institucional NAO esta anexado a janela')
    if b['qss_tamanho'] <= 0:
        falhas.append('stylesheet da janela vazio')
    if not b['home_instalada']:
        falhas.append('a home (ImanHome) nao foi instalada')
    if b['docks_visiveis'] <= 0:
        falhas.append('nenhum dock visivel - a janela nao assentou')
    b['falhas'] = falhas
    b['valido'] = (len(falhas) == 0)
    return b


# ================================================================ ASSERCOES
def a01_botao_fechar_dock():
    """D1 - QDockWidget { titlebar-close-icon: none; }"""
    crit = ('todo dock visivel tem botao de fechar VISIVEL, HABILITADO, com '
            'icone que desenha pixel, e com altura >= 60% da do botao de '
            'flutuar ao lado (o irmao nao tocado pelo QSS e a regua)')
    se_q = ('com titlebar-close-icon:none o botao continua existindo, visivel '
            'e habilitado - so nao desenha nada e encolhe. Uma assercao que '
            'perguntasse "o botao existe?" passaria com o defeito presente.')
    try:
        linhas = []
        ruins = 0
        for d in docks_visiveis():
            fechar = d.findChild(QAbstractButton, 'qt_dockwidget_closebutton')
            flutuar = d.findChild(QAbstractButton, 'qt_dockwidget_floatbutton')
            if fechar is None:
                linhas.append({'dock': d.windowTitle(), 'problema': 'sem botao de fechar'})
                ruins += 1
                continue
            img = fechar.grab().toImage()
            tinta, total = pixels_de_tinta(img)
            hf = flutuar.height() if flutuar is not None else None
            prop = (float(fechar.height()) / hf) if hf else None
            ok = (fechar.isVisible() and fechar.isEnabled()
                  and not fechar.icon().isNull() and tinta > 0
                  and (prop is None or prop >= 0.6))
            if not ok:
                ruins += 1
            linhas.append({
                'dock': d.windowTitle(),
                'visivel': fechar.isVisible(),
                'habilitado': fechar.isEnabled(),
                'icone_nulo': fechar.icon().isNull(),
                'pixels_de_tinta': tinta,
                'pixels_totais': total,
                'altura_fechar': fechar.height(),
                'altura_flutuar': hf,
                'proporcao': round(prop, 3) if prop else None,
                'ok': ok,
            })
        ev = ''
        if docks_visiveis():
            ev = foto(docks_visiveis()[0], 'A01-dock-titulo.png')
        registra('A01', 'D1', 'títulos e botões de dock', crit, ruins == 0,
                 {'docks_avaliados': len(linhas), 'docks_com_problema': ruins,
                  'detalhe': linhas}, se_q, ev)
    except Exception:
        falhou('A01', 'D1', 'títulos e botões de dock', crit, se_q)


def a02_campo_coordenadas():
    """D2 - QStatusBar QLineEdit { padding: 2px 8px } em widget de largura fixa"""
    crit = ('o campo de coordenadas cabe a coordenada canonica do produto '
            '(%r, EPSG:31984) inteira: largura util de texto >= largura que a '
            'fonte precisa' % COORD_CANONICA)
    se_q = ('com o padding do QSS num widget de largura FIXA, o campo continua '
            'visivel e o texto continua "presente" na API - so nao cabe na '
            'tela. Uma assercao sobre le.text() passaria com o defeito.')
    try:
        cont, le, btn = widget_coordenadas()
        if le is None:
            registra('A02', 'D2', 'status bar · coordenadas', crit, False,
                     {'erro': 'campo de coordenadas nao encontrado'}, se_q,
                     status='N/E')
            return
        fm = le.fontMetrics()
        precisa = fm.horizontalAdvance(COORD_CANONICA)
        util, util_h = largura_util_de_texto(le)
        cabe = 0
        for i in range(1, len(COORD_CANONICA) + 1):
            if fm.horizontalAdvance(COORD_CANONICA[:i]) <= util:
                cabe = i
            else:
                break
        ok = util >= precisa
        ev = foto(cont, 'A02-coordenadas.png')
        registra('A02', 'D2', 'status bar · coordenadas', crit, ok, {
            'texto_atual': le.text(),
            'coordenada_canonica': COORD_CANONICA,
            'caracteres_da_canonica': len(COORD_CANONICA),
            'caracteres_que_cabem': cabe,
            'largura_util_px': util,
            'largura_necessaria_px': precisa,
            'faltam_px': max(0, precisa - util),
            'largura_do_widget_px': le.width(),
            'largura_minima_fixada_px': le.minimumWidth(),
            'largura_maxima_fixada_px': le.maximumWidth(),
            'sizeHint_px': le.sizeHint().width(),
        }, se_q, ev)
    except Exception:
        falhou('A02', 'D2', 'status bar · coordenadas', crit, se_q)


def a03_toggle_da_status_bar():
    """D3 - ao clicar o botao ao lado, o campo estoura e o rodape fica branco"""
    crit = ('depois de acionar o botao de alternar coordenada/extensao, o '
            'rodape continua desenhando (>1 cor), o campo continua visivel, e '
            'a largura do campo nao passa de 3x a de antes')
    se_q = ('se o campo estourar, a largura cresce sem limite e o resto da '
            'status bar e empurrado para fora; se o rodape "ficar branco", a '
            'imagem da status bar passa a ter 1 cor so. Uma assercao que so '
            'olhasse isVisible() passaria nos dois casos.')
    try:
        sb = win().statusBar()
        cont, le, btn = widget_coordenadas()
        if le is None or btn is None:
            registra('A03', 'D3', 'status bar · alternância', crit, False,
                     {'erro': 'campo ou botao de alternancia nao encontrado'},
                     se_q, status='N/E')
            return

        tela = QApplication.primaryScreen().availableGeometry().width()
        antes = {'largura_campo': le.width(), 'texto': le.text(),
                 'largura_da_janela': win().width(),
                 'largura_da_status_bar': sb.width(),
                 'cores_no_rodape': cores_distintas(sb.grab().toImage())}
        foto(sb, 'A03-rodape-antes.png')

        btn.click()
        espera(1500)

        txt = le.text() or ''
        depois = {'largura_campo': le.width(),
                  'tamanho_do_texto': len(txt),
                  'texto_inicio': txt[:60],
                  'largura_da_janela': win().width(),
                  'largura_da_status_bar': sb.width(),
                  'cores_no_rodape': cores_distintas(sb.grab().toImage()),
                  'campo_visivel': le.isVisible()}
        ev = foto(sb, 'A03-rodape-depois.png')

        estourou = (antes['largura_campo'] > 0 and
                    depois['largura_campo'] > 3 * antes['largura_campo'])
        # "o rodape fica branco": os demais widgets do rodape sao empurrados
        # para fora da tela pelo campo estourado.
        empurrou_a_janela = depois['largura_da_janela'] > tela
        branco = depois['cores_no_rodape'] <= 1
        ok = (not estourou) and (not branco) and (not empurrou_a_janela) \
            and depois['campo_visivel']

        registra('A03', 'D3', 'status bar · alternância', crit, ok, {
            'largura_util_da_tela': tela,
            'antes': antes, 'depois': depois,
            'campo_estourou': estourou,
            'janela_ficou_maior_que_a_tela': empurrou_a_janela,
            'rodape_ficou_uniforme': branco,
            'NOTA': ('este passo roda POR ULTIMO de proposito: em 2026-09-07 ele '
                     'levou a janela principal de 1001 para 10413 px e '
                     'contaminou as assercoes seguintes.'),
        }, se_q, ev)
    except Exception:
        falhou('A03', 'D3', 'status bar · alternância', crit, se_q)


def caixa_de_tinta(img, x0, x1, y0, y1, fundo, tol=40):
    """Bounding box dos pixels que diferem do fundo, dentro do recorte."""
    minx, miny, maxx, maxy, n = None, None, None, None, 0
    fr, fg, fb = (fundo >> 16) & 255, (fundo >> 8) & 255, fundo & 255
    for y in range(max(0, y0), min(img.height(), y1)):
        for x in range(max(0, x0), min(img.width(), x1)):
            p = img.pixel(x, y)
            if (abs(((p >> 16) & 255) - fr) + abs(((p >> 8) & 255) - fg)
                    + abs((p & 255) - fb)) > tol:
                n += 1
                minx = x if minx is None else min(minx, x)
                maxx = x if maxx is None else max(maxx, x)
                miny = y if miny is None else min(miny, y)
                maxy = y if maxy is None else max(maxy, y)
    if n == 0:
        return None
    return {'x0': minx, 'y0': miny, 'x1': maxx, 'y1': maxy,
            'largura': maxx - minx + 1, 'altura': maxy - miny + 1, 'pixels': n}


def a04_titulo_dos_docks():
    """D4 - QDockWidget::title com padding sem a altura acompanhar.

    PRIMEIRA VERSAO DESTA ASSERCAO ESTAVA ERRADA e passou no defeito (medido
    2026-09-07): ela perguntava a QStyle.SE_DockWidgetTitleBarText qual era o
    retangulo do texto, e a resposta (23 px de altura para uma fonte de 11 px)
    dizia que cabia. Mas o corte do D4 acontece na PINTURA, nao no calculo do
    retangulo - a foto do titulo mostra "Camadas" partido no meio dos glifos.
    Assercao geometrica nao ve isso. Esta versao mede TINTA."""
    crit = ('na faixa de titulo de cada dock visivel, a altura da TINTA do '
            'texto renderizado e >= a ASCENDENTE da fonte do widget - do topo '
            'das maiusculas a linha de base. E o que "nao cortado ao meio" '
            'significa em pixel')
    se_q = ('com padding sem a altura acompanhar, windowTitle() devolve a '
            'string inteira, o retangulo calculado pela QStyle diz que cabe, e '
            'so o PIXEL mostra o glifo cortado. Foi exatamente assim que a '
            'primeira versao desta assercao passou com o defeito na tela.')
    try:
        linhas = []
        ruins = 0
        for d in docks_visiveis():
            titulo = d.windowTitle()
            img = d.grab().toImage().convertToFormat(QImage.Format_ARGB32)
            # faixa de titulo = do topo do dock ate o topo do conteudo
            conteudo = d.widget()
            # -2 px para nao contar a borda inferior do titulo
            # (`border-bottom: 1px`) como se fosse tinta de glifo.
            faixa_h = (conteudo.y() - 2) if (conteudo is not None and conteudo.y() > 6) else 24
            # botoes ficam a direita; limita o recorte antes deles
            botoes_x = img.width()
            for b in d.findChildren(QAbstractButton):
                if b.isVisible() and b.parentWidget() is d and b.x() > 0:
                    botoes_x = min(botoes_x, b.x())
            fundo = img.pixel(1, 1)
            cx = caixa_de_tinta(img, 0, max(2, botoes_x - 2), 0, faixa_h, fundo)

            # ORACULO: o MESMO texto, com a MESMA fonte, desenhado num lugar
            # com espaco de sobra. Comparar contra fm.tightBoundingRect nao
            # serve - ele devolveu 7 px para "Camadas", o mesmo numero do
            # texto JA CORTADO, e a assercao passou com o defeito na tela
            # (medido 2026-09-07).
            # CRITERIO: a tinta do titulo tem de ser pelo menos tao alta quanto
            # a ASCENDENTE da fonte do widget. E o que "nao cortado ao meio"
            # quer dizer, em pixel: do topo das maiusculas ate a linha de base.
            #
            # Por que a ascendente, e nao uma renderizacao de referencia: o
            # titulo e pintado com a fonte do TEMA (mais pesada e mais larga
            # que `d.font()`), e o widget nao a entrega. Duas tentativas de
            # oraculo falharam em 2026-09-07 e estao registradas para nao
            # serem refeitas: redesenhar com `d.font()` deu 8 px de referencia
            # contra 11 px de um titulo integro (largura 42 contra 60 - era
            # outro texto); e pedir `CE_DockWidgetTitle` num QRect alto deu
            # 8 px / 37 px de largura, tambem sem reproduzir a fonte pintada.
            #
            # A ascendente de `d.font()` e um PISO CONSERVADOR: como a fonte
            # real e maior, a tinta verdadeira sempre a supera com folga, e
            # nenhum produto sao reprova por isso. E o corte do D4 fica abaixo
            # dela - medido: 7 px de tinta contra a ascendente da fonte.
            fm = d.fontMetrics()
            piso = fm.ascent()
            alt = cx['altura'] if cx else 0
            prop = (float(alt) / piso) if piso else None
            ok = bool(cx) and alt >= piso
            if not ok:
                ruins += 1
            linhas.append({
                'dock': titulo,
                'faixa_de_titulo_px': faixa_h,
                'altura_da_tinta_px': alt,
                'piso_ascendente_da_fonte_px': piso,
                'proporcao_tinta_sobre_piso': round(prop, 3) if prop else None,
                'largura_da_tinta_na_tela_px': cx['largura'] if cx else None,
                'tinta_encosta_no_fim_da_faixa': bool(cx and cx['y1'] >= faixa_h - 1),
                'caixa': cx,
                'ok': ok,
            })
        ev = ''
        if docks_visiveis():
            ev = foto(docks_visiveis()[0], 'A04-titulo-dock.png')
        registra('A04', 'D4', 'títulos e botões de dock', crit, ruins == 0,
                 {'docks_avaliados': len(linhas), 'docks_com_problema': ruins,
                  'detalhe': linhas}, se_q, ev)
    except Exception:
        falhou('A04', 'D4', 'títulos e botões de dock', crit, se_q)


def a08_home_sem_dado_inventado():
    """D8 - RECENTS/TEMPLATES/CHIPS fabricados"""
    crit = ('nenhuma string das constantes RECENTS/TEMPLATES/CHIPS do '
            'dashboard.py alcanca a tela; e nenhum widget se pinta como '
            'clicavel (regra :hover propria) sem ser clicavel de verdade')
    se_q = ('a maquete "funciona": os QLabel existem e o layout fica bonito. '
            'Uma assercao do tipo "a home tem conteudo" passaria justamente '
            'porque o conteudo inventado esta la.')
    try:
        home = home_widget()
        if home is None:
            registra('A08', 'D8', 'home', crit, False,
                     {'erro': 'home nao encontrada'}, se_q, status='N/E')
            return
        try:
            from iman_brand import dashboard as dash
        except Exception:
            sys.path.insert(0, os.path.join(QgsApplication.qgisSettingsDirPath(),
                                            'python', 'plugins'))
            from iman_brand import dashboard as dash

        inventadas = set()
        for nome, caminho, quando in getattr(dash, 'RECENTS', []):
            inventadas.add(nome); inventadas.add(caminho)
        for nome, meta in getattr(dash, 'TEMPLATES', []):
            inventadas.add(nome)
        for c in getattr(dash, 'CHIPS', []):
            inventadas.add(c)

        # Os 4 "projetos recentes" vivem num UNICO QLabel de rich text com o
        # nome, o caminho e a data dentro. Comparar text() por igualdade nao
        # acha nenhum deles - a 1a versao desta assercao contou 6 de 10 por
        # isso. Aqui o texto e limpo de marcacao e a busca e por SUBSTRING.
        def texto_limpo(w):
            return re.sub(r'<[^>]+>', ' ', w.text() or '')

        na_tela = set()
        for lb in home.findChildren(QLabel):
            t = texto_limpo(lb)
            if not t.strip():
                continue
            for s in inventadas:
                if s and s in t:
                    na_tela.add(s)

        # FALSO AFORDANCE: o widget se pinta como clicavel (tem regra :hover no
        # proprio stylesheet) mas nao e clicavel de verdade - nao e botao e nao
        # tem ninguem ouvindo um sinal clicked. E o que o sponsor chamou de
        # "TEMPLATES e CHIPS que nao clicam".
        falso_afordance = []
        clicaveis_de_verdade = 0
        for w in home.findChildren(QWidget):
            ss = w.styleSheet() or ''
            if ':hover' not in ss:
                continue
            if isinstance(w, QAbstractButton):
                clicaveis_de_verdade += 1
                continue
            sig = getattr(w, 'clicked', None)
            vivo = False
            if sig is not None:
                try:
                    vivo = w.receivers(w.clicked) > 0
                except Exception:
                    vivo = False
            if vivo:
                clicaveis_de_verdade += 1
            else:
                falso_afordance.append({
                    'classe': w.metaObject().className(),
                    'texto': texto_limpo(w).strip()[:70] if isinstance(w, QLabel) else '',
                })

        ok = (len(na_tela) == 0 and len(falso_afordance) == 0)
        ev = foto(home, 'A08-home.png')
        registra('A08', 'D8', 'home', crit, ok, {
            'strings_inventadas_no_codigo': len(inventadas),
            'strings_inventadas_na_tela': len(na_tela),
            'amostra': sorted(na_tela)[:12],
            'widgets_com_falso_afordance': len(falso_afordance),
            'quais': falso_afordance[:12],
            'widgets_clicaveis_de_verdade': clicaveis_de_verdade,
        }, se_q, ev)
    except Exception:
        falhou('A08', 'D8', 'home', crit, se_q)


def a09_versao():
    """D9 - brand.VERSION 0.1.0 x .iss ProductVersion 0.3.0"""
    crit = ('a versao EXIBIDA na home e a mesma que o instalador entrega '
            '(ProductVersion do .iss)')
    se_q = ('as duas fontes existem e sao strings validas; nada quebra. Uma '
            'assercao "a home mostra uma versao" passaria exibindo a versao '
            'errada - que e exatamente o defeito.')
    try:
        home = home_widget()
        exibida = None
        for lb in (home.findChildren(QLabel) if home else []):
            t = (lb.text() or '')
            m = re.search(r'vers[aã]o\s*([0-9]+\.[0-9]+\.[0-9]+)', t, re.I)
            if m:
                exibida = m.group(1)
                break
        try:
            from iman_brand import brand
            do_codigo = brand.VERSION
        except Exception:
            do_codigo = None
        do_iss = versao_do_iss()
        meta = None
        try:
            mp = os.path.join(QgsApplication.qgisSettingsDirPath(), 'python',
                              'plugins', 'iman_brand', 'metadata.txt')
            with open(mp, 'r', encoding='utf-8', errors='replace') as fh:
                m = re.search(r'^version=(.+)$', fh.read(), re.M)
                meta = m.group(1).strip() if m else None
        except Exception:
            pass
        fontes = {'exibida_na_home': exibida, 'brand.py': do_codigo,
                  'metadata.txt': meta, 'iss ProductVersion': do_iss}
        distintas = set(v for v in fontes.values() if v)
        ok = (exibida is not None and do_iss is not None
              and exibida == do_iss and len(distintas) == 1)
        registra('A09', 'D9', 'versão', crit, ok, {
            'fontes': fontes,
            'valores_distintos': sorted(distintas),
            'quantas_fontes_em_desacordo': len(distintas),
        }, se_q, foto(home, 'A09-versao-na-home.png') if home else '')
    except Exception:
        falhou('A09', 'D9', 'versão', crit, se_q)


def a10_sobre_alcancavel():
    """D10 - o Sobre existe e esta escondido no dropdown"""
    crit = ('o menu Ajuda contem uma acao "Sobre o <produto>" - o lugar onde '
            'o usuario procura. O Sobre NATIVO do QGIS continua la (BL-1)')
    se_q = ('a acao existe e funciona; so nao esta onde se procura. Uma '
            'assercao "a acao Sobre existe" passaria com o defeito presente, '
            'porque ela existe mesmo - dentro do dropdown da toolbar.')
    try:
        try:
            from iman_brand import brand
            produto = brand.PRODUCT_NAME
        except Exception:
            produto = 'IMAN Terra'

        ajuda = acoes_do_menu(r'ajuda|help')
        textos_ajuda = [a.text().replace('&', '') for a in ajuda]
        no_ajuda = [t for t in textos_ajuda if 'sobre' in t.lower() and produto.lower() in t.lower()]
        sobre_nativo = [t for t in textos_ajuda if t.strip().lower().startswith('sobre')]

        # onde ela esta hoje
        onde = []
        for a in win().menuBar().actions():
            m = a.menu()
            if m is None:
                continue
            for sub in m.actions():
                sm = sub.menu()
                if sm is None:
                    continue
                for x in sm.actions():
                    if 'sobre' in x.text().lower() and produto.lower() in x.text().lower():
                        onde.append('%s > %s > %s' % (a.text().replace('&', ''),
                                                      sub.text(), x.text()))
        ok = len(no_ajuda) > 0
        registra('A10', 'D10', 'Sobre', crit, ok, {
            'acoes_do_menu_ajuda': textos_ajuda,
            'sobre_do_produto_no_ajuda': no_ajuda,
            'sobre_nativo_do_qgis_presente': sobre_nativo,
            'onde_a_acao_esta_hoje': onde,
        }, se_q, foto(win().menuBar(), 'A10-menubar.png'))
    except Exception:
        falhou('A10', 'D10', 'Sobre', crit, se_q)


def a11_icone_janela_e_taskbar():
    """D11 - icone do QGIS na taskbar (AppUserModelID roda tarde demais)"""
    crit = ('o icone DA JANELA e o emblema IMAN, nao o do QGIS. A identidade '
            'de agrupamento da barra de tarefas e medida no passo manual M-D11')
    se_q = ('o icone da janela pode estar certo e a taskbar continuar errada - '
            'sao coisas diferentes. Por isso esta assercao NAO cobre o D11 '
            'inteiro, e o que falta esta declarado como N/E, nao como PASS.')
    try:
        ic = win().windowIcon()
        img_janela = ic.pixmap(64, 64).toImage() if not ic.isNull() else QImage()
        logo_qgis = os.path.join(QgsApplication.pkgDataPath(), 'images', 'icons',
                                 'qgis-icon-512x512.png')
        igual_ao_qgis = None
        if os.path.exists(logo_qgis) and not img_janela.isNull():
            q = QImage(logo_qgis).scaled(64, 64, Qt.IgnoreAspectRatio,
                                         Qt.SmoothTransformation)
            a = img_janela.convertToFormat(QImage.Format_ARGB32)
            b = q.convertToFormat(QImage.Format_ARGB32)
            iguais = sum(1 for y in range(64) for x in range(64)
                         if a.pixel(x, y) == b.pixel(x, y))
            igual_ao_qgis = iguais / 4096.0
        # Identidade que o shell usa para agrupar/pinar. Que ela ESTEJA setada
        # nao prova que o shell a viu: o startup a define via --code, depois de
        # a janela nascer. E exatamente esse descompasso o D11.
        appid = None
        try:
            import ctypes
            from ctypes import wintypes
            buf = ctypes.c_wchar_p()
            hr = ctypes.windll.shell32.GetCurrentProcessExplicitAppUserModelID(
                ctypes.byref(buf))
            appid = buf.value if hr == 0 else 'HRESULT=0x%08X' % (hr & 0xFFFFFFFF)
        except Exception as e:
            appid = 'erro: %r' % (e,)

        ok = (not ic.isNull()) and (igual_ao_qgis is None or igual_ao_qgis < 0.9)
        registra('A11', 'D11 (parcial)', 'ícone de janela/taskbar', crit, ok, {
            'icone_da_janela_nulo': ic.isNull(),
            'tamanhos_disponiveis': [[s.width(), s.height()] for s in ic.availableSizes()],
            'semelhanca_com_o_logo_do_qgis': igual_ao_qgis,
            'AppUserModelID_do_processo': appid,
            'nome_do_processo': os.path.basename(sys.executable or ''),
            'AVISO': ('cobre so o icone da JANELA. O agrupamento da barra de '
                      'tarefas depende do AppUserModelID ter sido definido ANTES '
                      'de a janela nascer, e isso nao e observavel de dentro do '
                      'processo - ver M-D11.'),
        }, se_q, foto(win().menuBar(), 'A11-janela.png'))

        registra('M-D11', 'D11', 'ícone de janela/taskbar',
                 'PASSO MANUAL: com o IMAN Terra aberto, olhar o icone na barra '
                 'de tarefas do Windows. CRITERIO: e o emblema IMAN, nao o do '
                 'QGIS. Falha se aparecer o logo do QGIS.',
                 False, {'motivo': 'nao observavel de dentro do processo'},
                 'o AppUserModelID e lido pelo shell no momento em que a janela '
                 'nasce; medir a variavel depois nao diz o que o shell usou.',
                 status='N/E')
    except Exception:
        falhou('A11', 'D11', 'ícone de janela/taskbar', crit, se_q)


def a12_logo_do_qgis_na_ui():
    """D12 - logo do QGIS vazando na UI (tema de icones)"""
    crit = ('nenhum widget VISIVEL da chrome exibe o logo do QGIS; e o tema de '
            'icones em uso e um tema proprio instalado no userThemesFolder do '
            'perfil (nunca em C:\\Program Files\\QGIS*)')
    se_q = ('o logo do QGIS e um icone valido que renderiza bem - nada falha. '
            'Uma assercao "os icones carregam" passaria exibindo o logo do '
            'QGIS na cara do usuario.')
    try:
        logo = os.path.join(QgsApplication.pkgDataPath(), 'images', 'icons',
                            'qgis-icon-16x16.png')
        ref = QImage(logo).convertToFormat(QImage.Format_ARGB32) if os.path.exists(logo) else QImage()

        def igual(img):
            if ref.isNull() or img.isNull():
                return False
            a = img.scaled(16, 16, Qt.IgnoreAspectRatio, Qt.SmoothTransformation)
            a = a.convertToFormat(QImage.Format_ARGB32)
            iguais = sum(1 for y in range(16) for x in range(16)
                         if a.pixel(x, y) == ref.pixel(x, y))
            return (iguais / 256.0) >= 0.85

        vazando = []
        for b in win().findChildren(QAbstractButton):
            if not b.isVisible() or b.icon().isNull():
                continue
            if igual(b.icon().pixmap(16, 16).toImage()):
                vazando.append({'classe': b.metaObject().className(),
                                'objectName': b.objectName(),
                                'texto': b.text()})
        for lb in win().findChildren(QLabel):
            if not lb.isVisible():
                continue
            pm = lb.pixmap()
            if pm is not None and not pm.isNull() and igual(pm.toImage()):
                vazando.append({'classe': 'QLabel', 'objectName': lb.objectName(),
                                'texto': lb.text()})

        tema = QgsApplication.themeName()
        pasta_temas = QgsApplication.userThemesFolder()
        temas_no_perfil = []
        try:
            if os.path.isdir(pasta_temas):
                temas_no_perfil = sorted(os.listdir(pasta_temas))
        except Exception:
            pass
        tema_proprio = (tema not in ('default', '') and tema in temas_no_perfil)

        ok = (len(vazando) == 0 and tema_proprio)
        registra('A12', 'D12', 'tema de ícones', crit, ok, {
            'widgets_visiveis_exibindo_o_logo_do_qgis': len(vazando),
            'quais': vazando[:10],
            'tema_de_icones_em_uso': tema,
            'userThemesFolder': pasta_temas,
            'temas_instalados_no_perfil': temas_no_perfil,
            'tema_e_proprio_do_produto': tema_proprio,
            'referencia_do_logo': logo,
        }, se_q, foto(win().menuBar(), 'A12-chrome.png'))
    except Exception:
        falhou('A12', 'D12', 'tema de ícones', crit, se_q)


# ------------------------------------------------- fases que dirigem a UI
def a05_a06_a07_ciclo_de_projeto():
    """D5 (titulo estatico) · D6 (novo projeto inerte) · D7 (home some)"""
    crit5 = ('abrir o projeto X faz o titulo da janela CONTER o nome de X, '
             'mantendo a marca; criar um projeto novo MUDA o titulo')
    seq5 = ('o titulo estatico e uma string valida e bonita - nada falha. Uma '
            'assercao "o titulo contem IMAN Terra" passaria em 100% dos casos, '
            'inclusive com o titulo nunca mudando, que e o defeito.')
    crit6 = ('depois de criar um projeto novo, o miolo mostra o CANVAS - o '
             'usuario ve que algo aconteceu')
    seq6 = ('a home continua desenhando normalmente; nenhuma excecao. Uma '
            'assercao "a home aparece" passaria exatamente no defeito, que e a '
            'home aparecer quando nao devia.')
    crit7 = ('depois de um ciclo abrir-projeto -> novo-projeto, a home continua '
             'no MIOLO (mode == "central") e a welcome NATIVA do QGIS nunca '
             'fica visivel')
    seq7 = ('se a home cair para o fallback de dock, ela continua existindo e '
            'visivel - so nao esta mais no miolo. Uma assercao "a home existe" '
            'passaria com a home exilada num dock flutuante.')
    try:
        p = plugin_marca()
        stack = stack_central()
        welcome = None
        for w in win().findChildren(QWidget):
            if w.metaObject().className() == 'QgsWelcomePage':
                welcome = w
                break

        nome_proj = 'spike017-projeto-alfa'
        caminho = os.path.join(OUT, nome_proj + '.qgz')
        proj = QgsProject.instance()
        proj.setTitle(nome_proj)
        proj.write(caminho)
        espera(600)

        titulo_antes = win().windowTitle()

        # ---- abrir o projeto (caminho real do produto)
        iface.addProject(caminho)
        espera(2500)
        titulo_apos_abrir = win().windowTitle()
        estado_apos_abrir = {
            'mode': getattr(p, 'mode', None),
            'reinstalls': getattr(p, '_reinstalls', None),
            'stack_index': stack.currentIndex() if stack else None,
            'welcome_visivel': bool(welcome.isVisible()) if welcome else None,
        }
        foto(win(), 'A05-apos-abrir-projeto.png')

        # ---- criar projeto novo
        iface.newProject()
        espera(2500)
        titulo_apos_novo = win().windowTitle()
        stack2 = stack_central()
        idx_novo = stack2.currentIndex() if stack2 else None
        pagina_novo = None
        if stack2 is not None and idx_novo is not None:
            w = stack2.widget(idx_novo)
            pagina_novo = w.objectName() or w.metaObject().className()
        estado_apos_novo = {
            'mode': getattr(p, 'mode', None),
            'reinstalls': getattr(p, '_reinstalls', None),
            'stack_index': idx_novo,
            'pagina_visivel': pagina_novo,
            'welcome_visivel': bool(welcome.isVisible()) if welcome else None,
        }
        ev = foto(win(), 'A06-apos-novo-projeto.png')

        # ---------------------------------------------------------- A05 / D5
        contem_nome = nome_proj.lower() in (titulo_apos_abrir or '').lower()
        mudou = (titulo_apos_novo != titulo_apos_abrir)
        registra('A05', 'D5', 'título da janela', crit5,
                 contem_nome and mudou, {
                     'titulo_no_inicio': titulo_antes,
                     'titulo_apos_abrir_projeto': titulo_apos_abrir,
                     'titulo_apos_projeto_novo': titulo_apos_novo,
                     'projeto_aberto': nome_proj,
                     'titulo_contem_o_nome_do_projeto': contem_nome,
                     'titulo_mudou_ao_criar_novo': mudou,
                 }, seq5, 'A05-apos-abrir-projeto.png')

        # ---------------------------------------------------------- A06 / D6
        mostra_canvas = (pagina_novo is not None and 'ImanHome' not in str(pagina_novo))
        registra('A06', 'D6', 'home', crit6, mostra_canvas, {
            'pagina_no_miolo_apos_novo_projeto': pagina_novo,
            'indice_no_stack': idx_novo,
            'esperado': 'a pagina do canvas do QGIS (nao ImanHome)',
        }, seq6, ev)

        # ------------------------------------------- A07 / D7 : a POLITICA
        crit7 = ('cada estado do miolo bate com a politica declarada em '
                 'docs/branding-contract.md §1.8: E1 pouso -> home; '
                 'E2/E3/E5 projeto aberto -> canvas; E4 projeto criado -> '
                 'canvas; E6 "Inicio" -> home; E8 a welcome NATIVA do QGIS '
                 'nunca visivel. Cada estado tem pagina ESPERADA, e a '
                 'assercao compara a pagina observada com ela')
        seq7 = ('a versao anterior desta assercao so perguntava se a welcome '
                'nativa NAO tinha aparecido e se "Inicio" ainda funcionava - '
                'ou seja, passava por AUSENCIA de defeito. Com a politica '
                'escrita, ela passa por PRESENCA de comportamento: trocar '
                'qualquer handler (E4 voltar a mostrar a home, por exemplo) '
                'muda a pagina observada e a assercao reprova nomeando o '
                'estado.')

        # 'home' = a pagina ImanHome; 'canvas' = a pagina 0, o container do QGIS
        def qual_pagina():
            st = stack_central()
            if st is None:
                return None, None
            w = st.widget(st.currentIndex())
            nome = w.objectName() or w.metaObject().className()
            return ('home' if nome == 'ImanHome' else 'canvas'), nome

        def estado(rotulo, esperado):
            qual, nome = qual_pagina()
            st = stack_central()
            wv = bool(welcome.isVisible()) if welcome else None
            return {
                'estado': rotulo,
                'esperado': esperado,
                'observado': qual,
                'pagina_no_miolo': nome,
                'indice': st.currentIndex() if st else None,
                'welcome_nativa_visivel': wv,
                'modo_do_host': getattr(p, 'mode', None),
                'titulo': win().windowTitle(),
                'ok': (qual == esperado) and not wv,
            }

        def normaliza(rot, esperado, e):
            nome = e.get('pagina_visivel') or (
                'centralwidget' if e.get('stack_index') == 0 else None)
            qual = ('home' if nome == 'ImanHome'
                    else ('canvas' if nome else None))
            wv = e.get('welcome_visivel')
            return {'estado': rot,
                    'esperado': esperado,
                    'observado': qual,
                    'pagina_no_miolo': nome,
                    'indice': e.get('stack_index'),
                    'welcome_nativa_visivel': wv,
                    'modo_do_host': e.get('mode'),
                    'titulo': None,
                    'ok': (qual == esperado) and not wv}

        caminhada = [
            normaliza('E2 abriu um projeto', 'canvas', estado_apos_abrir),
            normaliza('E4 criou um projeto', 'canvas', estado_apos_novo),
        ]
        # S3: o usuario pede a home de volta
        try:
            p.show_home(); espera(1200)
        except Exception:
            pass
        caminhada.append(estado('E6 acionou "Inicio"', 'home'))
        # S4: abre o projeto demo pelo caminho REAL do produto
        try:
            p.open_demo(); espera(3000)
        except Exception:
            pass
        caminhada.append(estado('E5 abriu o projeto demo', 'canvas'))
        # S5: pede a home de novo
        try:
            p.show_home(); espera(1200)
        except Exception:
            pass
        caminhada.append(estado('E6 acionou "Inicio" de novo', 'home'))
        # S6: outro projeto novo
        try:
            iface.newProject(); espera(2000)
        except Exception:
            pass
        caminhada.append(estado('E4 criou outro projeto', 'canvas'))

        fora_da_politica = [c for c in caminhada if not c['ok']]
        ok7 = (len(fora_da_politica) == 0)
        registra('A07', 'D7', 'home', crit7, ok7, {
            'estados_avaliados': len(caminhada),
            'estados_fora_da_politica': len(fora_da_politica),
            'quais': [{'estado': c['estado'], 'esperado': c['esperado'],
                       'observado': c['observado'],
                       'welcome_visivel': c['welcome_nativa_visivel']}
                      for c in fora_da_politica],
            'caminhada': caminhada,
            'quantas_vezes_caiu_para_o_fallback_de_dock': getattr(p, '_reinstalls', None),
        }, seq7, foto(win(), 'A07-caminhada-final.png'))

        # deixa um projeto como "o ultimo aberto", para a 2a execucao encontrar
        # a maquina no estado em que o sponsor a encontrou.
        try:
            iface.addProject(caminho)
            espera(2000)
        except Exception:
            pass
    except Exception:
        falhou('A05', 'D5', 'título da janela', crit5, seq5)
        falhou('A06', 'D6', 'home', crit6, seq6)


def a07_segunda_execucao():
    """D7 - a home some depois do 1o uso.

    So e observavel na SEGUNDA execucao, no mesmo perfil, com um projeto ja
    usado - que e como o sponsor encontrou o produto. Na 1a execucao a home
    aparece e tudo parece bem; medir so a 1a execucao passa no defeito (foi o
    que a primeira versao desta assercao fez, em 2026-09-07)."""
    crit = ('CONTRATO: a home do IMAN Terra e a tela de pouso SEMPRE - 1a '
            'execucao ou centesima, com ou sem projeto recente. Ao abrir, o '
            'miolo mostra a ImanHome e a welcome NATIVA do QGIS nunca fica '
            'visivel')
    se_q = ('na 1a execucao a home aparece normalmente e nada falha; o defeito '
            'so existe a partir da 2a. Uma assercao que rodasse so uma vez '
            'passaria com o defeito intacto.')
    try:
        p = plugin_marca()
        stack = stack_central()
        pagina = None
        if stack is not None:
            w = stack.widget(stack.currentIndex())
            pagina = w.objectName() or w.metaObject().className()
        welcome = None
        for w in win().findChildren(QWidget):
            if w.metaObject().className() == 'QgsWelcomePage':
                welcome = w
                break
        welcome_visivel = bool(welcome.isVisible()) if welcome else False
        home = home_widget()
        proj = QgsProject.instance()

        ok = (pagina == 'ImanHome') and (not welcome_visivel) and \
             (home is not None and home.isVisible())
        registra('A07b', 'D7', 'home', crit, ok, {
            'execucao': 'SEGUNDA (perfil reaproveitado)',
            'pagina_no_miolo_ao_abrir': pagina,
            'indice_no_stack': stack.currentIndex() if stack else None,
            'home_existe': home is not None,
            'home_visivel': bool(home.isVisible()) if home else None,
            'welcome_nativa_do_qgis_visivel': welcome_visivel,
            'modo_do_host_da_home': getattr(p, 'mode', None),
            'projeto_carregado': proj.fileName(),
            'titulo_da_janela': win().windowTitle(),
        }, se_q, foto(win(), 'A07-segunda-execucao.png'))
    except Exception:
        falhou('A07b', 'D7', 'home', crit, se_q)


# ==================================================================== main
def principal():
    # o produto de verdade: roda o iman_startup.py, nao uma imitacao
    startup_ok = 'ausente'
    if STARTUP and os.path.exists(STARTUP):
        try:
            with open(STARTUP, 'r', encoding='utf-8') as fh:
                src = fh.read()
            exec(compile(src, STARTUP, 'exec'),
                 {'__name__': '__main__', '__file__': STARTUP})
            startup_ok = 'ok'
        except Exception as e:
            startup_ok = 'ERRO: %r' % (e,)

    def rodar():
        doc = {
            'quando': __import__('datetime').datetime.now().isoformat(),
            'qgis': Qgis.QGIS_VERSION,
            'startup_real': startup_ok,
        }
        base = valida_baseline()
        doc['baseline'] = base
        if not base['valido']:
            doc['abortado'] = True
            doc['resultados'] = []
            gravar(doc)
            return

        foto(win(), 'A00-janela-inteira.png')
        foto(win().statusBar(), 'A00-status-bar.png')

        if FASE == 'segunda':
            a07_segunda_execucao()
        else:
            a01_botao_fechar_dock()
            a04_titulo_dos_docks()
            a02_campo_coordenadas()
            a08_home_sem_dado_inventado()
            a09_versao()
            a10_sobre_alcancavel()
            a11_icone_janela_e_taskbar()
            a12_logo_do_qgis_na_ui()
            a05_a06_a07_ciclo_de_projeto()
            # POR ULTIMO: o A03 estoura a janela principal (medido: 1001 ->
            # 10413 px) e contaminaria tudo que rodasse depois dele.
            a03_toggle_da_status_bar()

        doc['abortado'] = False
        doc['fase'] = FASE
        doc['notas'] = notas
        doc['resultados'] = resultados
        gravar(doc)

    def gravar(doc):
        n = len(doc.get('resultados', []))
        doc['placar'] = {
            'total': n,
            'PASS': len([r for r in doc.get('resultados', []) if r['status'] == 'PASS']),
            'FAIL': len([r for r in doc.get('resultados', []) if r['status'] == 'FAIL']),
            'N/E': len([r for r in doc.get('resultados', []) if r['status'] == 'N/E']),
        }
        if not os.path.isdir(OUT):
            os.makedirs(OUT)
        nome = 'aceite.json' if FASE != 'segunda' else 'aceite-segunda.json'
        with open(os.path.join(OUT, nome), 'w', encoding='utf-8') as fh:
            json.dump(doc, fh, indent=2, ensure_ascii=False)
        print('SPIKE017: aceite gravado - %s' % doc['placar'])

    # o plugin instala a home em 900 ms, declutter 1600, banner 2200;
    # o startup reaplica identidade ate 4000 ms. Medir depois de assentar.
    QTimer.singleShot(8000, rodar)


principal()
