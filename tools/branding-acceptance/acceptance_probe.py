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
# #021/Entrega 2: a arvore PRIVADA do QGIS que o produto carrega. O aceite nao
# sobe mais o QGIS de C:\Program Files - e prova isso de dentro do processo.
QGIS_ROOT = os.environ.get('SPIKE017_QGIS_ROOT', '')
SHOTS    = os.path.join(OUT, 'shots')
# 'primeira' = suite completa; 'segunda' = so o pouso, no perfil ja usado (D7)
FASE     = os.environ.get('SPIKE017_FASE', 'primeira')

# Coordenada canonica que a status bar precisa caber: SIRGAS 2000 / UTM 24S,
# a projecao que o produto declara como padrao. E o texto REAL do dominio, nao
# um lorem ipsum: 555519,9  9585490,5
COORD_CANONICA = '555519,9  9585490,5'

resultados = []
notas = []
# Titulo do POUSO - capturado antes de qualquer projeto ser tocado (#022).
# Sem isso o estado "sem projeto" media o titulo DEPOIS de o A05 ja ter
# gravado um projeto, e o rotulo mentia sobre o que estava sendo medido.
titulo_do_pouso = {'valor': None}


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


# ================================================ #021/E2 - de QUAL QGIS somos
def caminho_longo(p):
    """O o4w_env.bat deriva OSGEO4W_ROOT em forma 8.3 (`%%~fsi`), entao
    sys.executable chega como ...\\IMANTE~1\\qgis\\bin\\... . Comparar isso com o
    caminho longo por string daria "nao e o do produto" numa arvore correta -
    exatamente o falso positivo que este bloco existe para nao criar."""
    if not p:
        return ''
    try:
        import ctypes
        from ctypes import wintypes
        f = ctypes.windll.kernel32.GetLongPathNameW
        f.argtypes = [wintypes.LPCWSTR, wintypes.LPWSTR, wintypes.DWORD]
        f.restype = wintypes.DWORD
        buf = ctypes.create_unicode_buffer(32768)
        if f(p, buf, 32768):
            return os.path.normpath(buf.value)
    except Exception:
        pass
    return os.path.normpath(p)


def sob(caminho, raiz):
    if not caminho or not raiz:
        return False
    c = caminho_longo(caminho).lower().rstrip('\\')
    r = caminho_longo(raiz).lower().rstrip('\\')
    return c == r or c.startswith(r + '\\')


def procedencia_do_qgis():
    """De onde veio o QGIS que esta rodando ESTA sonda.

    O orquestrador diz qual arvore mandou subir; aqui se confere o que o
    processo REALMENTE carregou. Sem isto, "o aceite roda contra a arvore do
    produto" seria afirmacao do orquestrador sobre si mesmo - e foi assim que
    a bancada passou meses medindo o QGIS de Program Files sem perceber.
    """
    prog = [d for d in (os.environ.get('ProgramFiles'),
                        os.environ.get('ProgramFiles(x86)'),
                        os.environ.get('ProgramW6432')) if d]

    fontes = {
        'sys.executable': sys.executable or '',
        'QgsApplication.prefixPath': QgsApplication.prefixPath() or '',
        'QgsApplication.pkgDataPath': QgsApplication.pkgDataPath() or '',
        'OSGEO4W_ROOT': os.environ.get('OSGEO4W_ROOT', ''),
        'QGIS_PREFIX_PATH': os.environ.get('QGIS_PREFIX_PATH', ''),
        'PROJ_DATA': os.environ.get('PROJ_DATA', ''),
        'GDAL_DATA': os.environ.get('GDAL_DATA', ''),
    }
    resolvidas = dict((k, caminho_longo(v.replace('/', '\\')) if v else '')
                      for k, v in fontes.items())

    # "Sem QGIS de sistema em lugar nenhum do caminho" - medido, nao assumido.
    em_program_files = []
    for k, v in list(resolvidas.items()):
        if v and any(sob(v, d) for d in prog):
            em_program_files.append({'fonte': k, 'caminho': v})
    for entrada in sys.path:
        if entrada and any(sob(entrada, d) for d in prog):
            em_program_files.append({'fonte': 'sys.path', 'caminho': caminho_longo(entrada)})

    raiz = caminho_longo(QGIS_ROOT) if QGIS_ROOT else ''
    dentro = {}
    for k in ('sys.executable', 'QgsApplication.prefixPath',
              'QgsApplication.pkgDataPath', 'OSGEO4W_ROOT'):
        dentro[k] = sob(resolvidas.get(k, ''), raiz) if raiz else None

    return {
        'raiz_esperada': raiz,
        'fontes': resolvidas,
        'dentro_da_arvore_do_produto': dentro,
        'tudo_dentro': all(v is True for v in dentro.values()) if raiz else None,
        'caminhos_em_program_files': em_program_files,
        'qgis_de_sistema_no_caminho': len(em_program_files) > 0,
    }


# ====================================== #022 - o titulo, por REGIAO (V.2)
#
# O titulo tem DUAS regioes, e so uma e nossa:
#
#   <prefixo do QGIS>            <sufixo de marca>
#   Caucaia - Setor 3 (QGIS)  -  IMAN Terra
#   ^ do usuario, nada se assere    ^ nosso, e aqui tudo se assere
#
# Foi essa distincao que faltou ate agora. A versao anterior do A05 perguntava
# so "contem o nome do projeto?" e "mudou?", e as duas continuavam verdadeiras
# com "QGIS [iman-distro]" na tela - foi assim que ele deu PASS com o D5
# reaberto (medido no #021, evidencia/aceite-com-dois-perfis.json).
#
# Mas assere rir sobre o titulo INTEIRO seria pior: o prefixo e o nome do
# arquivo que o usuario escolheu. Ele pode conter travessao, pode conter a
# palavra QGIS, pode conter qualquer coisa. Um oraculo que reprova o produto
# porque o usuario chamou o projeto de "Caucaia - Setor 3 (QGIS)" e pior que
# oraculo nenhum.
SEPARADOR_DE_MARCA = ' - '
PRODUTO = 'IMAN Terra'
# Travessao, meia-risca, hifen inquebravel, travessao de figura, barra
# horizontal. O hifen ASCII NAO entra: ele e o separador legitimo.
_TRACOS_PROIBIDOS = u'‐‑‒–—―'


def sufixo_de_marca(titulo, nome_projeto=None):
    """A regiao do titulo que a camada de marca POSSUI.

    Com o nome do projeto conhecido, o sufixo e tudo depois da ULTIMA ocorrencia
    dele - o que vem antes e do usuario (criterio `g`). Sem projeto conhecido, o
    prefixo e a string que o QGIS compoe para "sem projeto", que nao carrega
    nenhum dos tokens proibidos; ai o sufixo e o titulo inteiro, e isso e mais
    severo, nao menos.
    """
    t = titulo or ''
    if nome_projeto:
        i = t.lower().rfind(nome_projeto.lower())
        if i >= 0:
            return t[i + len(nome_projeto):]
    return t


def avalia_titulo(titulo, nome_projeto=None):
    """Os criterios (a)..(d) do #022, aplicados SO no sufixo de marca."""
    t = titulo or ''
    suf = sufixo_de_marca(t, nome_projeto)

    # (b) `powered by QGIS` e ATRIBUICAO obrigatoria (BL-1), definida em
    # brand.PRODUCT_SUBTITLE e usada em quatro lugares. Nenhuma assercao pode
    # reprovar o produto por exibi-la - o que se procura e QGIS como
    # AUTODESIGNACAO, entao a atribuicao sai antes da busca.
    suf_sem_atribuicao = re.sub(r'powered\s+by\s+QGIS', '', suf, flags=re.I)

    return {
        'titulo': t,
        'sufixo_de_marca': suf,
        'a_termina_com_a_marca': t.endswith(SEPARADOR_DE_MARCA + PRODUTO) or t == PRODUTO,
        'b_sem_QGIS_como_autodesignacao': 'qgis' not in suf_sem_atribuicao.lower(),
        'c_sem_colchete_de_perfil': ('[' not in suf) and (']' not in suf),
        'd_sem_travessao_nem_meia_risca': not any(c in suf for c in _TRACOS_PROIBIDOS),
    }


def censo_de_janelas():
    """As janelas de topo e seus titulos, cruas (#022).

    O conserto do D5 mexe em `iface.mainWindow()`. Se houver janela FORA do
    alcance desse gancho exibindo o sufixo do QGIS, isso e achado - e vira
    fatia propria, nao conserto improvisado. Por isso a lista sai crua, com
    quem tem e quem nao tem o sufixo, em vez de um veredito.
    """
    linhas = []
    try:
        vistos = set()
        for w in QApplication.topLevelWidgets():
            try:
                if not w.isWindow():
                    continue
                t = w.windowTitle() or ''
                chave = (w.metaObject().className(), w.objectName(), t)
                if chave in vistos:
                    continue
                vistos.add(chave)
                if not t and not w.isVisible():
                    continue
                linhas.append({
                    'classe': w.metaObject().className(),
                    'objectName': w.objectName(),
                    'titulo': t,
                    'visivel': bool(w.isVisible()),
                    'e_a_janela_principal': (w is win()),
                    'tem_sufixo_do_qgis': bool(re.search(
                        r'QGIS\s*(?:\[[^\]]*\])?\s*$', t)),
                    'tem_colchete_de_perfil': bool(re.search(r'\[[^\]]*\]\s*$', t)),
                })
            except Exception:
                continue
    except Exception:
        pass
    return linhas


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
    # #021/Entrega 2 - o baseline novo: produto instalado, e o QGIS que subiu e
    # o DELE. Um aceite verde rodado sobre um QGIS de terceiro nao aprova nada.
    b['procedencia_do_qgis'] = procedencia_do_qgis()

    falhas = []
    proc = b['procedencia_do_qgis']
    if proc['raiz_esperada'] and proc['tudo_dentro'] is not True:
        fora = [k for k, v in proc['dentro_da_arvore_do_produto'].items() if v is not True]
        falhas.append('o QGIS que subiu nao e o da arvore do produto (fora: %s)'
                      % ', '.join(fora))
    if proc['qgis_de_sistema_no_caminho']:
        falhas.append('ha caminho sob %%ProgramFiles%% no ambiente do QGIS: %s'
                      % proc['caminhos_em_program_files'][:4])
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


def _diagnostico_do_campo():
    """O que o filtro de largura do plugin diz sobre si mesmo (DB-23)."""
    try:
        p = plugin_marca()
        f = getattr(p, '_contem_coords', None)
        if f is None:
            return {'erro': 'filtro de largura nao instalado'}
        return f.diagnostico()
    except Exception as e:
        return {'erro': repr(e)}


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
            # DB-23: QUEM fechou a conta do piso - o evento de estilo ou a rede
            # de seguranca. E o que prova, de fora, que o mecanismo e o evento.
            'DB23_diagnostico_do_filtro': _diagnostico_do_campo(),
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


def recentes_do_qgis():
    """A lista de recentes DO PROPRIO QGIS - a fonte da verdade contra a qual a
    procedencia e conferida. Lida aqui, no processo vivo, e nao do codigo do
    produto: se ela viesse do dashboard.py, a assercao estaria conferindo o
    produto contra ele mesmo."""
    fonte = {}
    try:
        from qgis.core import QgsSettings
        s = QgsSettings()
        s.beginGroup('UI/recentProjects')
        try:
            for chave in s.childGroups():
                s.beginGroup(chave)
                try:
                    caminho = s.value('path', '') or ''
                    titulo = s.value('title', '') or ''
                finally:
                    s.endGroup()
                if caminho:
                    fonte[chave_de_caminho(caminho)] = {
                        'chave': chave, 'path': caminho, 'title': titulo}
        finally:
            s.endGroup()
    except Exception:
        pass
    return fonte


def chave_de_caminho(p):
    """Forma canonica para comparar caminhos: o QGIS grava com barra normal, o
    Windows nao distingue maiuscula, e a semente entra pelo .ini. Comparar
    string crua daria 'sem procedencia' num item legitimo."""
    try:
        return os.path.normcase(os.path.abspath(os.path.normpath(str(p))))
    except Exception:
        return str(p)


def a08_home_sem_dado_inventado():
    """D8 - dado fabricado na home.

    CRITERIO TROCADO NA #021 (Entrega 3), e a troca e DECLARADA.

    Ate a #020 esta assercao procurava, na tela, as strings das constantes
    RECENTS/TEMPLATES/CHIPS do dashboard.py. Com as constantes REMOVIDAS pelo
    conserto do D8, `getattr(dash, 'RECENTS', [])` devolve lista vazia, o
    conjunto de strings procuradas fica vazio, e a metade passava por
    TAUTOLOGIA - a propria crew declarou a ressalva no #018.

    Ela servia como guarda de regressao DESTE conserto (o revert do D8 a
    acende), mas era cega a um dataset fabricado NOVO, com outras strings: foi
    escrita contra a INSTANCIA do defeito, nao contra a CLASSE.

    O criterio novo e PROCEDENCIA: todo item exibido em "Projetos recentes"
    corresponde a uma entrada REAL - caminho que existe em disco E entrada da
    lista de recentes do proprio QGIS. Assim, dado fabricado com QUALQUER
    string e pego. E o C.2 - asserir propriedade, nunca representacao - um
    nivel acima.

    A contagem de strings das constantes continua sendo MEDIDA e relatada,
    mas NAO entra mais no criterio: ela e observacao historica, nao evidencia.
    """
    crit = ('PROCEDENCIA: todo item exibido em "Projetos recentes" corresponde '
            'a uma entrada REAL - o caminho existe em disco E esta na lista de '
            'recentes do proprio QGIS, com o mesmo titulo. E o recente REAL '
            'semeado antes do arranque CHEGA a tela (senao a assercao passaria '
            'por lista vazia). E nenhum widget se pinta como clicavel (regra '
            ':hover propria) sem ser clicavel de verdade')
    se_q = ('a maquete "funciona": os QLabel existem e o layout fica bonito. '
            'Uma assercao do tipo "a home tem conteudo" passaria justamente '
            'porque o conteudo inventado esta la. E uma assercao sobre as '
            'strings CONHECIDAS passaria com um dataset fabricado NOVO - por '
            'isso o criterio e procedencia, e nao lista de strings.')
    try:
        home = home_widget()
        if home is None:
            registra('A08', 'D8', 'home', crit, False,
                     {'erro': 'home nao encontrada'}, se_q, status='N/E')
            return

        def texto_limpo(w):
            return re.sub(r'<[^>]+>', ' ', w.text() or '')

        # ------------------------------------------------ 1. o que ESTA na tela
        # Os itens de recente sao QFrame#rec com dois QLabel: titulo e caminho.
        # Se o nome de objeto mudar, nenhum item e encontrado - e a exigencia de
        # PRESENCA da semente reprova alto, em vez de passar em silencio.
        itens = []
        for f in home.findChildren(QWidget):
            if f.objectName() != 'rec':
                continue
            rotulos = [texto_limpo(l).strip() for l in f.findChildren(QLabel)]
            rotulos = [r for r in rotulos if r]
            itens.append({
                'titulo': rotulos[0] if len(rotulos) > 0 else '',
                'caminho': rotulos[1] if len(rotulos) > 1 else '',
                'rotulos': rotulos,
            })

        fonte = recentes_do_qgis()
        semeado = os.environ.get('SPIKE017_RECENTE_SEMEADO', '')

        sem_procedencia = []
        for it in itens:
            k = chave_de_caminho(it['caminho'])
            entrada = fonte.get(k)
            existe = bool(it['caminho']) and os.path.exists(it['caminho'])
            titulo_bate = False
            if entrada is not None:
                esperados = set()
                if entrada['title']:
                    esperados.add(entrada['title'])
                esperados.add(os.path.splitext(os.path.basename(entrada['path']))[0])
                titulo_bate = it['titulo'] in esperados
            it['existe_em_disco'] = existe
            it['na_lista_do_qgis'] = entrada is not None
            it['titulo_bate_com_a_entrada'] = titulo_bate
            it['ok'] = bool(existe and entrada is not None and titulo_bate)
            if not it['ok']:
                sem_procedencia.append(it)

        # Varredura larga: um caminho fabricado pode ser pintado FORA do
        # QFrame#rec. Todo texto com cara de CAMINHO de projeto tem de ter
        # procedencia tambem.
        #
        # O padrao exige raiz (letra de unidade ou UNC): sem isso ele casava com
        # o subtitulo do cartao "Abrir projeto / Arquivos .qgz / .qgs", que nao e
        # caminho nenhum - falso positivo medido na 1a rodada desta versao.
        PADRAO_CAMINHO = re.compile(r'(?:[A-Za-z]:[\\/]|\\\\)[^\r\n]*?\.qg[zs]\b', re.I)
        fora_do_cartao = []
        for lb in home.findChildren(QLabel):
            for t in PADRAO_CAMINHO.findall(texto_limpo(lb)):
                t = t.strip()
                if any(t == it['caminho'] for it in itens):
                    continue
                if chave_de_caminho(t) not in fonte or not os.path.exists(t):
                    fora_do_cartao.append(t)

        semeado_na_tela = None
        if semeado:
            alvo = chave_de_caminho(semeado)
            semeado_na_tela = any(chave_de_caminho(it['caminho']) == alvo for it in itens)

        # ------------------------------- 2. observacao historica (fora do criterio)
        try:
            from iman_brand import dashboard as dash
        except Exception:
            sys.path.insert(0, os.path.join(QgsApplication.qgisSettingsDirPath(),
                                            'python', 'plugins'))
            from iman_brand import dashboard as dash

        inventadas = set()
        for tupla in getattr(dash, 'RECENTS', []):
            for parte in tupla:
                inventadas.add(parte)
        for tupla in getattr(dash, 'TEMPLATES', []):
            inventadas.add(tupla[0] if isinstance(tupla, (list, tuple)) else tupla)
        for c in getattr(dash, 'CHIPS', []):
            inventadas.add(c)

        na_tela = set()
        for lb in home.findChildren(QLabel):
            t = texto_limpo(lb)
            if not t.strip():
                continue
            for s in inventadas:
                if s and isinstance(s, str) and s in t:
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

        ok = (len(sem_procedencia) == 0
              and len(fora_do_cartao) == 0
              and (semeado_na_tela is not False)
              and len(falso_afordance) == 0)
        ev = foto(home, 'A08-home.png')
        registra('A08', 'D8', 'home', crit, ok, {
            'CRITERIO': ('procedencia (#021/E3): caminho existe em disco E esta '
                         'na lista de recentes do proprio QGIS, com o mesmo titulo'),
            'itens_exibidos_em_projetos_recentes': len(itens),
            'itens_sem_procedencia': len(sem_procedencia),
            'quais_sem_procedencia': sem_procedencia[:8],
            'itens': itens[:8],
            'entradas_na_lista_de_recentes_do_qgis': len(fonte),
            'lista_do_qgis': [v['path'] for v in fonte.values()][:8],
            'recente_real_semeado': semeado,
            'recente_semeado_chegou_a_tela': semeado_na_tela,
            'caminhos_de_projeto_pintados_fora_do_cartao': fora_do_cartao[:8],
            'widgets_com_falso_afordance': len(falso_afordance),
            'quais': falso_afordance[:12],
            'widgets_clicaveis_de_verdade': clicaveis_de_verdade,
            'HISTORICO_fora_do_criterio': {
                'NOTA': ('a metade antiga procurava as strings das constantes '
                         'RECENTS/TEMPLATES/CHIPS. Com elas removidas o conjunto '
                         'e vazio e a busca passava por tautologia - por isso '
                         'estes numeros sao MEDIDOS e relatados, mas nao entram '
                         'no criterio.'),
                'strings_inventadas_no_codigo': len(inventadas),
                'strings_inventadas_na_tela': len(na_tela),
                'amostra': sorted(na_tela)[:12],
            },
        }, se_q, ev)
    except Exception:
        falhou('A08', 'D8', 'home', crit, se_q)


def a13_identidade_do_build():
    """DB-24 - o produto instalado sabe dizer QUAL build ele e.

    O proprio BUILD_INFO.txt declara que a identidade de um artefato e o par
    (ProductVersion, Commit): o SHA-256 muda com o mtime que o Inno grava e o
    git nao preserva. Mas o Commit nao chegava ao usuario - o produto declarava
    so "0.3.0", e o artefato de branch das 05:29 e o canonico eram ambos 0.3.0
    e INDISTINGUIVEIS de dentro do produto.

    Esta assercao mede a cadeia inteira: o arquivo que o instalador entregou,
    o valor que o produto LE dele, e o que chega a TELA. Se qualquer elo
    quebrar, o produto volta a nao saber de si.
    """
    crit = ('o produto exibe, na home, uma identidade de build que casa com o '
            '{app}\BUILD_ID.txt entregue pelo instalador: o commit curto na '
            'tela e o mesmo do arquivo, o arquivo traz versao/commit/branch, e '
            'o commit curto e prefixo do commit completo')
    se_q = ('sem isto o produto exibe "versao 0.3.0" e nada mais - uma string '
            'valida, bonita, e identica em TODO artefato 0.3.0 ja compilado. '
            'Uma assercao do tipo "a home mostra uma versao" passa com o '
            'defeito presente, porque a versao esta la; o que nao esta e a '
            'resposta a pergunta "qual build e este?".')
    try:
        home = home_widget()
        app = os.environ.get('IMAN_TERRA_HOME', '')
        arquivo = os.path.join(app, 'BUILD_ID.txt') if app else ''

        if not arquivo or not os.path.isfile(arquivo):
            registra('A13', 'DB-24', 'identidade do build', crit, False, {
                'IMAN_TERRA_HOME': app,
                'arquivo_procurado': arquivo,
                'erro': ('BUILD_ID.txt nao encontrado. Numa arvore de '
                         'desenvolvimento isso e esperado - o arquivo nasce no '
                         'build; contra um PRODUTO INSTALADO, e o defeito.'),
            }, se_q, status='N/E')
            return

        do_arquivo = {}
        with open(arquivo, 'r', encoding='utf-8', errors='replace') as fh:
            for linha in fh:
                linha = linha.strip()
                if linha and not linha.startswith('#') and '=' in linha:
                    k, v = linha.split('=', 1)
                    do_arquivo[k.strip()] = v.strip()

        curto = do_arquivo.get('commit_curto', '')
        completo = do_arquivo.get('commit', '')
        versao_arq = do_arquivo.get('versao', '')

        # o que chegou a TELA
        na_tela = None
        for lb in (home.findChildren(QLabel) if home else []):
            t = re.sub(r'<[^>]+>', ' ', lb.text() or '')
            m = re.search(r'vers[aã]o\s*([0-9]+\.[0-9]+\.[0-9]+)\s*[^\w]*\s*([0-9a-f]{7,40})', t, re.I)
            if m:
                na_tela = {'versao': m.group(1), 'commit_curto': m.group(2),
                           'texto': t.strip()}
                break

        # o que o proprio produto diz de si
        do_produto = None
        try:
            from iman_brand import brand as _b
            do_produto = {'versao_exibida': _b.versao_exibida(),
                          'commit_curto': _b.build_commit_curto(),
                          'arquivo_lido': _b.build_id().get('_arquivo')}
        except Exception as e:
            do_produto = {'erro': repr(e)}

        campos_ok = all(do_arquivo.get(k) for k in ('versao', 'commit', 'commit_curto', 'branch'))
        curto_e_prefixo = bool(curto) and bool(completo) and completo.startswith(curto)
        tela_bate = bool(na_tela) and na_tela['commit_curto'] == curto
        versao_bate = bool(na_tela) and na_tela['versao'] == versao_arq

        ok = campos_ok and curto_e_prefixo and tela_bate and versao_bate
        registra('A13', 'DB-24', 'identidade do build', crit, ok, {
            'arquivo': arquivo,
            'do_arquivo': do_arquivo,
            'na_tela': na_tela,
            'o_que_o_produto_diz': do_produto,
            'campos_obrigatorios_presentes': campos_ok,
            'commit_curto_e_prefixo_do_completo': curto_e_prefixo,
            'commit_da_tela_bate_com_o_arquivo': tela_bate,
            'versao_da_tela_bate_com_o_arquivo': versao_bate,
            'NOTA_SHA': ('o SHA-256 do .exe NAO esta no BUILD_ID de proposito: '
                         'ele so existe depois de compilar, e o arquivo entra '
                         'NA compilacao. Ele vive no BUILD_INFO.txt do repo.'),
        }, se_q, foto(home, 'A13-identidade-do-build.png') if home else '')
    except Exception:
        falhou('A13', 'DB-24', 'identidade do build', crit, se_q)


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
    crit5 = ('CRITERIO POR REGIAO (#022): em cada estado - sem projeto, projeto '
             'aberto, projeto novo, projeto modificado sem salvar - (a) o titulo '
             'termina com " - IMAN Terra", com HIFEN; e no SUFIXO DE MARCA '
             '(b) nao ha QGIS como autodesignacao (a atribuicao "powered by '
             'QGIS" nao reprova), (c) nao ha colchete de perfil, (d) nao ha '
             'travessao nem meia-risca. Com projeto aberto, (e) o titulo contem '
             'o nome do projeto e (f) o titulo muda ao criar um novo. '
             '(g) NADA se assere sobre o prefixo alem de (e)')
    seq5 = ('o titulo estatico e uma string valida e bonita - nada falha. E o '
            'criterio ANTERIOR ("contem o nome do projeto" + "mudou") continuava '
            'VERDADEIRO com "QGIS [iman-distro]" na tela: foi assim que o A05 '
            'deu PASS com o D5 reaberto, medido no #021. Um titulo que perde a '
            'marca, ou que vaza o nome interno do perfil, so aparece se a '
            'assercao olhar a REGIAO que a camada de marca possui.')
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
        #
        # ESTADO EXTRA (#022) - o projeto modificado sem salvar. O QGIS marca o
        # titulo quando o projeto fica sujo, e essa marca entra no PREFIXO;
        # serve para provar que o sufixo nao se desfaz quando o prefixo muda.
        try:
            QgsProject.instance().setDirty(True)
            espera(1500)
        except Exception:
            pass
        titulo_modificado = win().windowTitle()

        # CONTROLE DE FALSO POSITIVO (#022, obrigatorio). Um projeto cujo NOME
        # tem travessao e a palavra QGIS. Se o A05 reprovar aqui, ele nao esta
        # medindo o produto - esta medindo o gosto de quem nomeia arquivo, e
        # "um oraculo que reprova produto sao e pior que oraculo nenhum".
        nome_hostil = u'Caucaia — Setor 3 (QGIS)'
        titulo_hostil = None
        try:
            caminho_hostil = os.path.join(OUT, nome_hostil + '.qgz')
            ph = QgsProject.instance()
            ph.setTitle(nome_hostil)
            ph.write(caminho_hostil)
            espera(600)
            iface.addProject(caminho_hostil)
            espera(2500)
            titulo_hostil = win().windowTitle()
        except Exception:
            titulo_hostil = None

        estados = [
            {'estado': 'sem projeto (pouso)', 'nome_projeto': None,
             'titulo': titulo_do_pouso['valor'] or titulo_antes},
            {'estado': 'projeto aberto', 'nome_projeto': nome_proj,
             'titulo': titulo_apos_abrir},
            {'estado': 'projeto novo', 'nome_projeto': None,
             'titulo': titulo_apos_novo},
            {'estado': 'projeto modificado sem salvar', 'nome_projeto': None,
             'titulo': titulo_modificado},
        ]
        if titulo_hostil is not None:
            estados.append({'estado': u'CONTROLE - projeto de nome hostil',
                            'nome_projeto': nome_hostil,
                            'titulo': titulo_hostil})

        avaliados = []
        for e in estados:
            r = avalia_titulo(e['titulo'], e['nome_projeto'])
            r['estado'] = e['estado']
            r['nome_do_projeto'] = e['nome_projeto']
            r['ok'] = (r['a_termina_com_a_marca']
                       and r['b_sem_QGIS_como_autodesignacao']
                       and r['c_sem_colchete_de_perfil']
                       and r['d_sem_travessao_nem_meia_risca'])
            avaliados.append(r)

        fora = [r for r in avaliados if not r['ok']]

        # (e) e (f) - os criterios de hoje, mantidos
        contem_nome = nome_proj.lower() in (titulo_apos_abrir or '').lower()
        mudou = (titulo_apos_novo != titulo_apos_abrir)

        janelas = censo_de_janelas()
        com_sufixo = [j for j in janelas if j['tem_sufixo_do_qgis']]

        ok5 = (len(fora) == 0 and contem_nome and mudou)
        registra('A05', 'D5', 'título da janela', crit5, ok5, {
            'estados_avaliados': len(avaliados),
            'estados_fora_do_criterio': len(fora),
            'quais_fora': fora,
            'por_estado': avaliados,
            'e_titulo_contem_o_nome_do_projeto': contem_nome,
            'f_titulo_mudou_ao_criar_novo': mudou,
            'separador_de_marca_exigido': SEPARADOR_DE_MARCA,
            'CONTROLE_falso_positivo': {
                'projeto': nome_hostil,
                'titulo': titulo_hostil,
                'NOTA': ('o nome do arquivo tem travessao E a palavra QGIS. O '
                         'criterio olha so o SUFIXO, entao o prefixo passa '
                         'intocado - e o produto sao nao reprova.'),
            },
            'CENSO_DE_JANELAS': {
                'NOTA': ('o conserto do D5 mexe em iface.mainWindow(). Janela '
                         'com sufixo do QGIS fora dela e ACHADO, e vira fatia '
                         'propria - nao entra no criterio desta.'),
                'janelas_de_topo': len(janelas),
                'com_sufixo_do_qgis': len(com_sufixo),
                'quais_com_sufixo': com_sufixo,
                'lista_crua': janelas,
            },
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

        titulo_do_pouso['valor'] = win().windowTitle()
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
            a13_identidade_do_build()
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
