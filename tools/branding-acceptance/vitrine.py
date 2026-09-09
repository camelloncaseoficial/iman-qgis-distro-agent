# -*- coding: utf-8 -*-
"""#022 - VITRINE: arruma a UI para UMA tomada de evidencia (V.1 / V.4).

Roda dentro do QGIS, pelo mesmo caminho do aceite (`Invoke-Aceite.ps1 -Sonda
vitrine.py -Manter`), e deixa na tela, ao mesmo tempo:

  - a barra de TITULO com o texto novo (moldura nativa, capturada de fora);
  - a barra de MENUS (densidade nova);
  - um MENU ABERTO (raio e padding do item);
  - um DOCK com titulo;
  - um DIALOGO com botao e campo (raio de QPushButton e QLineEdit).

Nao assere nada - o aceite e quem assere. Isto existe porque
"renderizem o alvo, nao descrevam o alvo": um laudo que diz "o raio agora e
2px" sem mostrar nao provou nada a quem le.

Grava `descoberta.json` (o orquestrador espera por ele) com o que ficou na
tela, e mantem tudo aberto para a captura de fora.
"""
import json
import os

from qgis.PyQt.QtCore import Qt, QTimer, QEventLoop, QPoint
from qgis.PyQt.QtWidgets import (
    QApplication, QDialog, QVBoxLayout, QHBoxLayout, QLabel, QLineEdit,
    QPushButton, QGroupBox, QDockWidget, QMenuBar, QWidget,
)
from qgis.utils import iface

OUT = os.environ.get('SPIKE017_OUT', r'C:\Temp\spike017')
STARTUP = os.environ.get('SPIKE017_STARTUP', '')

_vivos = {}


def espera(ms):
    loop = QEventLoop()
    QTimer.singleShot(ms, loop.quit)
    loop.exec_()


def monta():
    win = iface.mainWindow()
    # Maximizar: o enquadramento tem de ser o MESMO no antes e no depois, e
    # "maximizado" e o unico enquadramento que nao depende de onde a janela
    # nasceu. Sem isso, o desktop atras entra na foto e o leitor compara duas
    # imagens que diferem por acidente.
    try:
        win.showMaximized()
    except Exception:
        pass
    espera(1200)
    doc = {'titulo_da_janela': win.windowTitle()}

    # --- DB-24: o Sobre REAL do produto, nao uma imitacao. `show_about` usa
    # exec_() e bloquearia o event loop, entao o dialogo e construido aqui e
    # mostrado NAO-MODAL - mesma classe, mesmo conteudo, mesma fonte de versao.
    try:
        from iman_brand import sobre as _sobre
        sdlg = _sobre.SobreDialog(win)
        sdlg.setModal(False)
        sdlg.show()
        g0 = win.frameGeometry()
        sdlg.move(int(g0.x() + g0.width() * 0.06), int(g0.y() + g0.height() * 0.30))
        _vivos['sobre'] = sdlg
        doc['sobre'] = sdlg.windowTitle()
    except Exception as e:
        doc['sobre'] = 'erro: %r' % (e,)

    try:
        from iman_brand import brand as _brand
        doc['versao_exibida'] = _brand.versao_exibida()
        doc['build_id'] = _brand.build_id()
    except Exception as e:
        doc['versao_exibida'] = 'erro: %r' % (e,)

    # --- dialogo de marca: botao default, botao comum, campo, groupbox
    dlg = QDialog(win)
    dlg.setWindowTitle(u'IMAN Terra — exemplo de diálogo')
    dlg.setMinimumWidth(380)
    v = QVBoxLayout(dlg)
    gb = QGroupBox(u'Parâmetros do lote')
    gv = QVBoxLayout(gb)
    gv.addWidget(QLabel(u'Matrícula'))
    campo = QLineEdit()
    campo.setText(u'555519,9  9585490,5')
    gv.addWidget(campo)
    v.addWidget(gb)
    h = QHBoxLayout()
    b1 = QPushButton(u'Cancelar')
    b2 = QPushButton(u'Aplicar')
    b2.setDefault(True)
    h.addWidget(b1)
    h.addWidget(b2)
    v.addLayout(h)
    dlg.setModal(False)
    dlg.show()
    g = win.frameGeometry()
    dlg.move(int(g.x() + g.width() * 0.50), int(g.y() + g.height() * 0.30))
    _vivos['dlg'] = dlg
    doc['dialogo'] = dlg.windowTitle()

    # --- um dock visivel, com titulo
    docks = [d for d in win.findChildren(QDockWidget) if d.isVisible()]
    doc['docks_visiveis'] = [d.windowTitle() for d in docks]

    espera(400)

    # --- menu ABERTO. popup() em vez de click: nao bloqueia o event loop, e a
    # captura acontece de fora, por outro processo.
    # Abre um menu do MEIO da barra, nao o primeiro: o menu do primeiro item
    # cai por cima do dock da esquerda e esconde justamente o titulo de dock que
    # esta tomada precisa mostrar.
    mb = win.findChild(QMenuBar) or win.menuBar()
    aberto = None
    comMenu = [a for a in mb.actions() if a.menu() is not None]
    for a in comMenu[3:4] or comMenu[:1]:
        m = a.menu()
        r = mb.actionGeometry(a)
        m.popup(mb.mapToGlobal(QPoint(r.x(), r.y() + r.height())))
        aberto = a.text().replace('&', '')
        _vivos['menu'] = m
        break
    doc['menu_aberto'] = aberto

    # MEDIDA da densidade (#022/Entrega 3), para o laudo nao dizer "parece mais
    # apertado". Largura de cada item da barra e o vao entre rotulos vizinhos.
    itens = []
    for a in mb.actions():
        if not a.text():
            continue
        r = mb.actionGeometry(a)
        fm = mb.fontMetrics()
        itens.append({
            'rotulo': a.text().replace('&', ''),
            'x': r.x(), 'largura': r.width(),
            'largura_do_texto': fm.horizontalAdvance(a.text().replace('&', '')),
            'folga_no_item': r.width() - fm.horizontalAdvance(a.text().replace('&', '')),
        })
    doc['itens_da_barra'] = itens
    if itens:
        doc['barra_de_menus'] = {
            'itens': len(itens),
            'x_do_primeiro': itens[0]['x'],
            'fim_do_ultimo': itens[-1]['x'] + itens[-1]['largura'],
            'largura_total_ocupada': itens[-1]['x'] + itens[-1]['largura'] - itens[0]['x'],
            'folga_media_por_item': round(
                sum(i['folga_no_item'] for i in itens) / float(len(itens)), 1),
        }

    espera(800)

    # GRAB DO QT, e nao captura de tela: a foto pelo lado do Qt independe de
    # quem esta na frente. Aprendido no #016 (o CopyFromScreen fotografou a
    # janela de outro app) e reaprendido aqui - a captura de tela desta sessao
    # pegou um terminal por cima do produto.
    def grab(widget, nome):
        try:
            if widget is None:
                return None
            widget.grab().save(os.path.join(OUT, nome))
            return nome
        except Exception as e:
            return 'erro: %r' % (e,)

    doc['grabs'] = {
        'home': grab(win.findChild(QWidget, 'ImanHome'), 'vitrine-home.png'),
        'sobre': grab(_vivos.get('sobre'), 'vitrine-sobre.png'),
        'janela': grab(win, 'vitrine-janela.png'),
    }

    if not os.path.isdir(OUT):
        os.makedirs(OUT)
    with open(os.path.join(OUT, 'descoberta.json'), 'w', encoding='utf-8') as fh:
        json.dump(doc, fh, indent=2, ensure_ascii=False)
    print('VITRINE pronta: %s' % doc)


def principal():
    if STARTUP and os.path.exists(STARTUP):
        try:
            with open(STARTUP, 'r', encoding='utf-8') as fh:
                src = fh.read()
            exec(compile(src, STARTUP, 'exec'),
                 {'__name__': '__main__', '__file__': STARTUP})
        except Exception as e:
            print('startup falhou: %r' % (e,))
    # 8 s: o mesmo instante em que o aceite mede, ja com tema, home e o
    # ajuste do campo de coordenadas (4600 ms) assentados.
    QTimer.singleShot(8000, monta)


principal()
