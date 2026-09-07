# -*- coding: utf-8 -*-
"""
#017 - passada de DESCOBERTA (nao e o teste de aceite).

Roda dentro do QGIS real, com o perfil iman-distro e o iman_startup.py de
verdade, e despeja o que existe: nomes de objeto da status bar, docks e seus
botoes de titulo, a arvore do central widget, onde o logo do QGIS aparece.

Existe para que as assercoes do acceptance_probe.py sejam escritas sobre nomes
MEDIDOS, nao adivinhados. Rode de novo quando a baseline do QGIS mudar.

Saida: JSON em %SPIKE017_OUT%\descoberta.json
"""
import json
import os
import sys

from qgis.PyQt.QtCore import QTimer
from qgis.PyQt.QtWidgets import (
    QApplication, QDockWidget, QLineEdit, QLabel, QToolButton, QAbstractButton,
    QStatusBar, QStackedWidget, QWidget, QMenu,
)
from qgis.utils import iface

OUT = os.environ.get('SPIKE017_OUT', r'C:\Temp\spike017')
STARTUP = os.environ.get('SPIKE017_STARTUP', '')


def roda_startup_real():
    """Executa o iman_startup.py DE VERDADE - o produto, nao uma imitacao."""
    if not STARTUP or not os.path.exists(STARTUP):
        return 'AUSENTE: %s' % STARTUP
    try:
        with open(STARTUP, 'r', encoding='utf-8') as fh:
            src = fh.read()
        g = {'__name__': '__main__', '__file__': STARTUP}
        exec(compile(src, STARTUP, 'exec'), g)
        return 'ok'
    except Exception as e:
        return 'ERRO: %r' % (e,)


def desc(w):
    try:
        return {
            'classe': w.metaObject().className(),
            'objectName': w.objectName(),
            'visivel': w.isVisible(),
            'geom': [w.x(), w.y(), w.width(), w.height()],
        }
    except Exception:
        return {'classe': '?', 'objectName': '?'}


def arvore(w, prof=0, maxprof=3):
    n = desc(w)
    n['filhos'] = []
    if prof < maxprof:
        for c in w.children():
            if isinstance(c, QWidget):
                n['filhos'].append(arvore(c, prof + 1, maxprof))
    return n


def coleta():
    win = iface.mainWindow()
    d = {}

    # ---- status bar: tudo que existe la dentro
    sb = win.statusBar()
    itens = []
    for c in sb.findChildren(QWidget):
        e = desc(c)
        if isinstance(c, QLineEdit):
            e['tipo'] = 'QLineEdit'
            e['texto'] = c.text()
            e['minW'] = c.minimumWidth()
            e['maxW'] = c.maximumWidth()
            e['sizeHintW'] = c.sizeHint().width()
        elif isinstance(c, QLabel):
            e['tipo'] = 'QLabel'
            e['texto'] = c.text()
        elif isinstance(c, QToolButton):
            e['tipo'] = 'QToolButton'
            e['tooltip'] = c.toolTip()
            e['checkable'] = c.isCheckable()
            e['iconNull'] = c.icon().isNull()
        itens.append(e)
    d['status_bar'] = {'geom': [sb.x(), sb.y(), sb.width(), sb.height()], 'itens': itens}

    # ---- docks e os botoes da barra de titulo
    docks = []
    for dw in win.findChildren(QDockWidget):
        botoes = []
        for b in dw.findChildren(QAbstractButton):
            botoes.append({
                'classe': b.metaObject().className(),
                'objectName': b.objectName(),
                'visivel': b.isVisible(),
                'habilitado': b.isEnabled(),
                'iconNull': b.icon().isNull(),
                'geom': [b.x(), b.y(), b.width(), b.height()],
            })
        docks.append({
            'titulo': dw.windowTitle(),
            'objectName': dw.objectName(),
            'visivel': dw.isVisible(),
            'flutuante': dw.isFloating(),
            'features': int(dw.features()),
            'geom': [dw.x(), dw.y(), dw.width(), dw.height()],
            'botoes': botoes,
        })
    d['docks'] = docks

    # ---- central widget
    cw = win.centralWidget()
    d['central'] = arvore(cw, maxprof=2) if cw is not None else None
    if isinstance(cw, QStackedWidget):
        d['central_stack'] = {
            'count': cw.count(),
            'currentIndex': cw.currentIndex(),
            'paginas': [desc(cw.widget(i)) for i in range(cw.count())],
        }

    # ---- onde vive a welcome nativa do QGIS
    welcome = []
    for w in win.findChildren(QWidget):
        cn = w.metaObject().className()
        if 'Welcome' in cn or 'welcome' in (w.objectName() or ''):
            welcome.append(desc(w))
    d['welcome_nativa'] = welcome

    # ---- menus de topo e onde esta o "Sobre"
    menus = []
    for a in win.menuBar().actions():
        m = a.menu()
        acoes = []
        if m is not None:
            for sub in m.actions():
                acoes.append({
                    'texto': sub.text(),
                    'temSubmenu': sub.menu() is not None,
                    'sub': [x.text() for x in sub.menu().actions()] if sub.menu() else [],
                })
        menus.append({'texto': a.text(), 'acoes': acoes})
    d['menubar'] = menus

    # ---- titulo da janela e icone
    ic = win.windowIcon()
    d['janela'] = {
        'titulo': win.windowTitle(),
        'iconeNull': ic.isNull(),
        'iconeTamanhos': [[s.width(), s.height()] for s in ic.availableSizes()],
    }

    # ---- o QSS realmente anexado
    qss = win.styleSheet() or ''
    d['qss'] = {
        'tamanho': len(qss),
        'temMarcaImanTheme': '/* IMAN-THEME */' in qss,
        'temTitlebarCloseNone': 'titlebar-close-icon' in qss,
    }

    # ---- plugin carregado
    try:
        import qgis.utils as qu
        p = qu.plugins.get('iman_brand')
        d['plugin'] = {
            'carregado': p is not None,
            'classe': type(p).__name__ if p else None,
            'mode': getattr(p, 'mode', None),
            'todos': sorted(qu.plugins.keys()),
        }
    except Exception as e:
        d['plugin'] = {'erro': repr(e)}

    return d


def principal():
    res_startup = roda_startup_real()

    def medir():
        try:
            d = coleta()
        except Exception:
            import traceback
            d = {'excecao': traceback.format_exc()}
        d['startup_real'] = res_startup
        d['perfil'] = None
        try:
            from qgis.core import QgsApplication
            d['perfil'] = QgsApplication.qgisSettingsDirPath()
        except Exception:
            pass
        if not os.path.isdir(OUT):
            os.makedirs(OUT)
        with open(os.path.join(OUT, 'descoberta.json'), 'w', encoding='utf-8') as fh:
            json.dump(d, fh, indent=2, ensure_ascii=False)
        print('SPIKE017: descoberta gravada')

    # o plugin instala a home em 900 ms, declutter em 1600, banner em 2200;
    # o startup reaplica identidade ate 4000 ms. Medir depois de tudo assentar.
    QTimer.singleShot(7000, medir)


principal()
