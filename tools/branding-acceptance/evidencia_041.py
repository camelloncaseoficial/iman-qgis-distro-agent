# -*- coding: utf-8 -*-
"""#041 - SONDA DE EVIDENCIA do laudo (V.1 renderize o alvo, V.2 por regiao, V.4 build atual).

Roda dentro do QGIS pelo mesmo caminho do aceite:

    Invoke-Aceite.ps1 -Sonda evidencia_041.py

Nao assere nada (quem assere e o acceptance_probe.py, A14 a A17). Ela fotografa as
regioes que o briefing #041 pede e mede o que o laudo tabela:

  - caixa de Processamento: agrupada, com um grupo e um provedor abertos, e a busca;
  - Opcoes > Processamento > Provedores, e cada pagina das Opcoes (tema no arranque,
    R5, e o alcance do tradutor nos textos das Opcoes);
  - dialogo de um algoritmo nativo (native:buffer), antes e depois de rodar (log);
  - modelador com um algoritmo;
  - menu Ajuda aberto, e o CLIQUE em cada endereco dele, interceptado por um
    QDesktopServices.setUrlHandler (nenhum navegador e aberto);
  - um dialogo sem icone proprio, e Propriedades da camada;
  - ferramentas de depuracao (icone do registro de rede);
  - o registro de rede do proprio QGIS (QgsNetworkLogger), para a medicao do feed;
  - o alcance do tradutor, mensagem a mensagem: o que a API devolve e o que a tela
    mostra onde a mensagem aparece.

Cada foto e `<nome>.png` (widget.grab, so o conteudo do proprio QGIS). Quando o
icone da barra de titulo importa, sai tambem `<nome>-icone-da-janela.png`: o
windowIcon() que a janela entrega ao Windows. A tela NUNCA e fotografada (ver
foto_tela).

Grava `descoberta.json` no fim (o orquestrador espera por ele).
"""
import io
import json
import os
import re
import traceback

from qgis.PyQt.QtCore import QObject, QPoint, QPointF, QTimer, QEventLoop, QUrl, Qt, pyqtSlot
from qgis.PyQt.QtGui import QDesktopServices, QIcon, QImage
from qgis.PyQt.QtWidgets import (
    QAbstractButton, QApplication, QDialog, QDockWidget, QGroupBox, QLabel, QMenu,
    QPushButton, QStackedWidget, QTextBrowser, QTextEdit, QPlainTextEdit, QTreeView,
    QVBoxLayout, QWidget, QLineEdit,
)
from qgis.core import QgsApplication, QgsProject, QgsSettings, Qgis
from qgis.utils import iface

OUT = os.environ.get('SPIKE017_OUT', r'C:\Temp\spike017')
REPO = os.environ.get('SPIKE017_REPO', '')
SHOTS = os.path.join(OUT, 'shots')
TEMA = 'IMAN Terra'
doc = {'notas': []}
_vivos = []


# ------------------------------------------------------------- infraestrutura
def espera(ms):
    loop = QEventLoop()
    QTimer.singleShot(ms, loop.quit)
    loop.exec_()


def win():
    return iface.mainWindow()


def nota(t):
    doc['notas'].append(t)


def foto(widget, nome):
    try:
        if widget is None:
            return ''
        os.makedirs(SHOTS, exist_ok=True)
        widget.grab().save(os.path.join(SHOTS, nome + '.png'))
        return nome + '.png'
    except Exception:
        return ''


def foto_tela(widget, nome):
    """O icone que a janela de topo entrega ao Windows para a barra de titulo.

    NAO FOTOGRAFA A TELA, de proposito. A primeira versao desta sonda usava
    grabWindow na area da janela e, numa bancada em uso, pegou o que estava na
    frente (outro aplicativo, com dados de outra pessoa). A barra de titulo e
    desenhada pelo Windows a partir do windowIcon() da janela, entao e ele que
    se salva, a 32 px, ao lado da foto do conteudo (widget.grab)."""
    try:
        if widget is None:
            return ''
        topo = widget.window()
        os.makedirs(SHOTS, exist_ok=True)
        topo.windowIcon().pixmap(32, 32).save(os.path.join(SHOTS, nome + '-icone-da-janela.png'))
        return nome + '-icone-da-janela.png'
    except Exception:
        return ''


def img(icon, lado=24):
    if icon is None or icon.isNull():
        return QImage()
    return icon.pixmap(lado, lado).toImage().convertToFormat(QImage.Format_ARGB32)


def semelhanca(a, b):
    if a.isNull() or b.isNull() or a.size() != b.size():
        return None
    w, h = a.width(), a.height()
    return sum(1 for y in range(h) for x in range(w) if a.pixel(x, y) == b.pixel(x, y)) / float(w * h)


def ref_provider():
    caminho = os.path.join(QgsApplication.userThemesFolder(), TEMA, 'icons', 'providerQgis.svg')
    tema = img(QIcon(caminho)) if os.path.exists(caminho) else QImage()
    padrao = img(QIcon(':/images/themes/default/providerQgis.svg'))
    return tema, padrao


def origem(icone, tema, padrao):
    i = img(icone)
    st, sp = semelhanca(i, tema), semelhanca(i, padrao)
    if st is not None and st >= 0.95 and (sp is None or st > sp):
        return 'tema'
    if sp is not None and sp >= 0.95:
        return 'padrao'
    return 'outro'


def normaliza(t):
    return re.sub(r'\s+', ' ', t or '').strip()


def textos_de(raiz):
    """Todo texto visivel ou de dica sob um widget (rotulo, botao, grupo, dica)."""
    out = []
    for w in raiz.findChildren(QWidget):
        for getter in ('text', 'title', 'toolTip', 'whatsThis'):
            try:
                if getter == 'text' and not isinstance(w, (QLabel, QAbstractButton, QLineEdit)):
                    continue
                if getter == 'title' and not isinstance(w, QGroupBox):
                    continue
                v = getattr(w, getter)()
                if v:
                    out.append(v)
            except Exception:
                pass
        if isinstance(w, (QTextBrowser, QTextEdit)):
            try:
                out.append(w.toHtml())
                out.append(w.toPlainText())
            except Exception:
                pass
        # QgsWebView (o painel de detalhes do gerenciador de complementos): o
        # texto mora na pagina, nao no widget.
        if hasattr(w, 'page') and callable(getattr(w, 'page')):
            try:
                quadro = w.page().mainFrame()
                out.append(quadro.toHtml())
                out.append(quadro.toPlainText())
            except Exception:
                pass
    return out


def abre_e_age(abrir, achar, agir, limite=20000):
    """Abre uma janela (modal ou nao) e age nela de dentro de um timer, porque
    exec_() bloqueia quem chamou. Fecha a janela no fim."""
    estado = {'feito': False, 'resultado': None, 'erro': None}
    tentativas = {'n': 0}

    def tick():
        w = achar()
        if w is None and tentativas['n'] < limite // 250:
            tentativas['n'] += 1
            QTimer.singleShot(250, tick)
            return
        try:
            estado['resultado'] = agir(w) if w is not None else {'erro': 'a janela nao apareceu'}
        except Exception:
            estado['erro'] = traceback.format_exc(limit=4)
        finally:
            try:
                if w is not None:
                    if isinstance(w, QDialog):
                        w.reject()
                    w.close()
            except Exception:
                pass
            estado['feito'] = True

    QTimer.singleShot(400, tick)
    try:
        abrir()
    except Exception:
        estado['erro'] = traceback.format_exc(limit=4)
        estado['feito'] = True
    t = 0
    while not estado['feito'] and t < limite + 5000:
        espera(200)
        t += 200
    return estado


def topo_da_classe(nome):
    def achar():
        m = QApplication.activeModalWidget()
        if m is not None and (not nome or nome in m.metaObject().className()):
            return m
        for w in QApplication.topLevelWidgets():
            if w.isVisible() and nome and nome in w.metaObject().className():
                return w
        return None
    return achar


# ------------------------------------------------------------- a fonte do tradutor
def fonte_do_tradutor():
    # IMAN041_FONTE: o lado develop do laudo nao tem a fonte, e mede o alcance
    # contra a fonte desta branch (o que a tela mostra la e o texto antigo).
    caminho = os.environ.get('IMAN041_FONTE') or (
        os.path.join(REPO, 'app', 'i18n', 'iman_terra_pt_BR.json') if REPO else '')
    if not caminho or not os.path.exists(caminho):
        return None, None
    with io.open(caminho, encoding='utf-8') as fh:
        fonte = json.load(fh)
    try:
        from iman_brand import brand
        produto = brand.PRODUCT_NAME
    except Exception:
        produto = 'IMAN Terra'
    for m in fonte['messages']:
        m['esperado'] = m['iman_terra'].replace(fonte['product_token'], produto)
    return fonte, produto


def marca_na_tela(fonte, textos, onde):
    """Para cada mensagem, se a tela mostra o texto novo ou o antigo."""
    if not fonte:
        return
    def sem_marcacao(t):
        return normaliza(re.sub(r'<[^>]+>', ' ', t or ''))

    corpo = [normaliza(t) for t in textos] + [sem_marcacao(t) for t in textos]

    def casa(modelo):
        # %1..%9 chegam a tela ja substituidos: cada pedaco entre marcadores
        # tem de aparecer, nessa ordem. E o HTML pode chegar reformatado (o
        # QgsWebView reescreve as marcas), entao tambem se compara sem marcacao.
        for forma in (normaliza(modelo), sem_marcacao(modelo)):
            pedacos = [p for p in re.split(r'%\d', forma) if p.strip()]
            if not pedacos:
                continue
            rx = re.compile('.*?'.join(re.escape(p.strip()) for p in pedacos), re.S)
            if any(rx.search(t) for t in corpo):
                return True
        return False

    for m in fonte['messages']:
        if casa(m['esperado']):
            m.setdefault('tela', []).append({'onde': onde, 'mostra': 'novo'})
        elif casa(m['qgis_pt_BR']):
            m.setdefault('tela', []).append({'onde': onde, 'mostra': 'antigo'})


# ------------------------------------------------------------- as regioes
def regiao_tema():
    tema, padrao = ref_provider()
    reg = QgsApplication.processingRegistry()
    provs = []
    for p in reg.providers():
        provs.append({'id': p.id(), 'nome': p.name(), 'nome_longo': p.longName(),
                      'svgIconPath': p.svgIconPath(), 'icone': origem(p.icon(), tema, padrao)})
    doc['tema'] = {
        'themeName': QgsApplication.themeName(),
        'UI/UITheme': QgsSettings().value('UI/UITheme', ''),
        'qgis/style': QgsSettings().value('qgis/style', ''),
        'activeThemePath': QgsApplication.activeThemePath(),
        'iconPath(providerQgis.svg)': QgsApplication.iconPath('providerQgis.svg'),
        'provedores': provs,
    }


def regiao_janela():
    try:
        win().showMaximized()
    except Exception:
        pass
    espera(1200)
    doc['janela'] = {'titulo': win().windowTitle(),
                     'foto': foto(win(), '041-janela'), 'tela': foto_tela(win(), '041-janela')}


def dock_da_caixa():
    for d in win().findChildren(QDockWidget):
        if d.objectName() == 'ProcessingToolbox' or 'Processamento' in d.windowTitle():
            return d
    return None


def regiao_caixa():
    d = dock_da_caixa()
    if d is None:
        doc['caixa'] = {'erro': 'dock da caixa nao encontrado'}
        return
    d.setVisible(True)
    d.raise_()
    espera(800)
    arvore = d.findChild(QTreeView)
    modelo = arvore.model()
    tema, padrao = ref_provider()
    nos = []
    for r in range(modelo.rowCount()):
        idx = modelo.index(r, 0)
        ic = modelo.data(idx, Qt.DecorationRole)
        nos.append({'texto': modelo.data(idx, Qt.DisplayRole),
                    'icone': origem(ic if isinstance(ic, QIcon) else QIcon(), tema, padrao)})
    res = {'objectName': d.objectName(), 'titulo': d.windowTitle(), 'nos_de_topo': nos}
    res['agrupada'] = foto(d, '041-caixa-agrupada')
    # um grupo de topo do QGIS e um provedor (no por provedor) abertos
    abertos = []
    for r in range(modelo.rowCount()):
        idx = modelo.index(r, 0)
        t = modelo.data(idx, Qt.DisplayRole) or ''
        if t in ('Geometria vetorial', 'GDAL') or (not abertos and nos[r]['icone'] == 'tema'):
            arvore.expand(idx)
            abertos.append(t)
    espera(600)
    res['abertos'] = abertos
    res['por_provedor'] = foto(d, '041-caixa-grupo-e-provedor-abertos')
    # dica do algoritmo nativo: o provedor aparece no tooltip dos algoritmos
    busca = d.findChild(QLineEdit)
    if busca is not None:
        busca.setText('buffer')
        espera(900)
        arvore.expandAll()
        espera(400)
        res['busca'] = foto(d, '041-caixa-busca-buffer')
        busca.setText('')
        espera(400)
    arvore.collapseAll()
    doc['caixa'] = res


def regiao_opcoes(fonte):
    resultado = {}

    def agir(dlg):
        r = {'classe': dlg.metaObject().className(), 'icone_semelhanca_app':
             semelhanca(img(dlg.windowIcon(), 32), img(QApplication.windowIcon(), 32))}
        dlg.resize(1100, 760)
        espera(800)
        r['tela'] = foto_tela(dlg, '041-opcoes')
        pilha = dlg.findChild(QStackedWidget, 'mOptionsStackedWidget') or dlg.findChild(QStackedWidget)
        paginas = []
        for i in range(pilha.count()):
            pilha.setCurrentIndex(i)
            espera(350)
            pagina = pilha.widget(i)
            textos = textos_de(pagina)
            antes = sum(len(m.get('tela', [])) for m in fonte['messages']) if fonte else 0
            marca_na_tela(fonte, textos, 'Opcoes, pagina %d (%s)' % (i, pagina.objectName()))
            depois = sum(len(m.get('tela', [])) for m in fonte['messages']) if fonte else 0
            entrada = {'indice': i, 'objectName': pagina.objectName()}
            if depois > antes:
                entrada['foto'] = foto(dlg, '041-opcoes-pagina-%02d' % i)
            # Opcoes > Processamento > Provedores: abre o no e fotografa
            for tv in pagina.findChildren(QTreeView):
                mod = tv.model()
                if mod is None:
                    continue
                for rr in range(mod.rowCount()):
                    ix = mod.index(rr, 0)
                    if (mod.data(ix, Qt.DisplayRole) or '') in ('Provedores', 'Providers'):
                        tv.expand(ix)
                        espera(300)
                        nomes = [mod.data(mod.index(k, 0, ix), Qt.DisplayRole)
                                 for k in range(mod.rowCount(ix))]
                        entrada['provedores'] = nomes
                        entrada['foto_provedores'] = foto(dlg, '041-opcoes-processamento-provedores')
                        r['tela_provedores'] = foto_tela(dlg, '041-opcoes-processamento-provedores')
            paginas.append(entrada)
        r['paginas'] = paginas
        return r

    est = abre_e_age(lambda: iface.showOptionsDialog(win()), topo_da_classe('QgsOptions'), agir)
    resultado.update(est)
    doc['opcoes'] = resultado


def regiao_ajuda():
    menu = win().findChild(QMenu, 'mHelpMenu')
    if menu is None:
        doc['ajuda'] = {'erro': 'mHelpMenu nao encontrado'}
        return
    acoes = [{'objectName': a.objectName(), 'texto': a.text(), 'visivel': a.isVisible(),
              'no_menu': a in menu.actions()} for a in menu.actions()]
    todas = {a.objectName(): a for a in win().findChildren(type(menu.actions()[0]))}
    res = {'acoes_no_menu': acoes,
           'mActionCheckQgisVersion_no_menu': any(x['objectName'] == 'mActionCheckQgisVersion' for x in acoes)}
    menu.popup(win().mapToGlobal(QPoint(int(win().width() * 0.6), 40)))
    espera(700)
    res['foto'] = foto(menu, '041-menu-ajuda')
    menu.hide()
    espera(300)

    class Captura(QObject):
        def __init__(self):
            super().__init__()
            self.urls = []

        @pyqtSlot(QUrl)
        def abre(self, url):
            self.urls.append(url.toString())

    cap = Captura()
    _vivos.append(cap)
    QDesktopServices.setUrlHandler('https', cap, 'abre')
    QDesktopServices.setUrlHandler('http', cap, 'abre')
    cliques = []
    try:
        chaves = ('HomePage', 'ReportaBug', 'Support', 'Donate', 'GetInvolved', 'Sponsors', 'NeedSupport')
        for a in menu.actions():
            nome = a.objectName()
            if not any(k.lower() in nome.lower() for k in chaves):
                continue
            antes = len(cap.urls)
            a.trigger()
            espera(400)
            cliques.append({'objectName': nome, 'texto': a.text(),
                            'abriria': cap.urls[antes:] or None})
    finally:
        QDesktopServices.unsetUrlHandler('https')
        QDesktopServices.unsetUrlHandler('http')
    res['cliques'] = cliques
    s = QgsSettings()
    res['chaves'] = {k: s.value(k, None) for k in (
        'qgis/helpQgisHomePageUrl', 'qgis/reportaBugUrl', 'qgis/supportProvidersUrl',
        'qgis/donate', 'qgis/getInvolved', 'qgis/qgisSponsorsUrl', 'help/helpSearchPath')}
    doc['ajuda'] = res


def regiao_dialogo_sem_icone():
    # SEM PAI de proposito: um dialogo filho da janela principal herda o icone
    # DELA (que o startup ja trocava antes do #041). Sem pai, ele so herda o da
    # aplicacao, que e o que o #041 troca.
    dlg = QDialog(None)
    dlg.setWindowTitle('IMAN Terra #041 - dialogo sem pai e sem icone proprio')
    lay = QVBoxLayout(dlg)
    lay.addWidget(QLabel('Um QDialog novo, sem pai e sem setWindowIcon: herda o icone da aplicacao.'))
    lay.addWidget(QPushButton('OK'))
    dlg.resize(520, 140)
    dlg.show()
    _vivos.append(dlg)
    espera(700)
    home = os.environ.get('IMAN_TERRA_HOME', '')
    ico = os.path.join(home, 'assets', 'icon-iman-terra.ico')
    logo = os.path.join(QgsApplication.pkgDataPath(), 'images', 'icons', 'qgis-icon-60x60.png')
    doc['dialogo_sem_icone'] = {
        'semelhanca_iman': semelhanca(img(dlg.windowIcon(), 32), img(QIcon(ico), 32)) if os.path.exists(ico) else None,
        'semelhanca_qgis': semelhanca(img(dlg.windowIcon(), 32), img(QIcon(logo), 32)),
        'foto': foto(dlg, '041-dialogo-sem-icone'),
        'tela': foto_tela(dlg, '041-dialogo-sem-icone'),
    }
    dlg.close()


def camada_de_teste():
    from qgis.core import QgsFeature, QgsGeometry, QgsPointXY, QgsVectorLayer
    lyr = QgsVectorLayer('Point?crs=EPSG:31984&field=nome:string', 'pontos_041', 'memory')
    f = QgsFeature(lyr.fields())
    f.setAttribute('nome', 'IMAN')
    f.setGeometry(QgsGeometry.fromPointXY(QgsPointXY(555519.9, 9585490.5)))
    lyr.dataProvider().addFeatures([f])
    QgsProject.instance().addMapLayer(lyr)
    return lyr


def regiao_algoritmo(lyr, fonte):
    import processing
    dlg = processing.createAlgorithmDialog('native:buffer', {
        'INPUT': lyr.id(), 'DISTANCE': 10.0, 'OUTPUT': 'TEMPORARY_OUTPUT'})
    dlg.show()
    _vivos.append(dlg)
    espera(1000)
    res = {'classe': dlg.metaObject().className(), 'titulo': dlg.windowTitle()}
    res['parametros'] = foto(dlg, '041-algoritmo-parametros')
    res['parametros_tela'] = foto_tela(dlg, '041-algoritmo-parametros')
    try:
        dlg.runAlgorithm()
    except Exception:
        res['erro_ao_rodar'] = traceback.format_exc(limit=3)
    espera(4500)
    logs = []
    for w in dlg.findChildren(QTextEdit) + dlg.findChildren(QPlainTextEdit):
        try:
            t = w.toPlainText()
            if t.strip():
                logs.append(t)
        except Exception:
            pass
    res['log'] = logs[:2]
    res['log_foto'] = foto(dlg, '041-algoritmo-log')
    res['log_tela'] = foto_tela(dlg, '041-algoritmo-log')
    marca_na_tela(fonte, logs, 'dialogo do algoritmo, aba Log')
    dlg.close()
    doc['algoritmo'] = res


def regiao_modelador():
    from qgis.core import QgsProcessingModelAlgorithm, QgsProcessingModelChildAlgorithm
    from processing.modeler.ModelerDialog import ModelerDialog
    modelo = QgsProcessingModelAlgorithm('modelo_041', 'IMAN Terra #041')
    filho = QgsProcessingModelChildAlgorithm('native:buffer')
    filho.generateChildId(modelo)
    filho.setDescription('Buffer')
    filho.setPosition(QPointF(320, 180))
    modelo.addChildAlgorithm(filho)
    dlg = ModelerDialog.create()
    dlg.setModel(modelo)
    dlg.resize(1200, 760)
    dlg.show()
    _vivos.append(dlg)
    espera(1500)
    tema, padrao = ref_provider()
    doc['modelador'] = {'foto': foto(dlg, '041-modelador'), 'tela': foto_tela(dlg, '041-modelador')}
    try:
        dlg.setDirty(False)
    except Exception:
        pass
    dlg.hide()


def regiao_propriedades(lyr, fonte):
    def agir(dlg):
        dlg.resize(1000, 700)
        espera(1000)
        marca_na_tela(fonte, textos_de(dlg), 'Propriedades da camada')
        return {'classe': dlg.metaObject().className(), 'tela': foto_tela(dlg, '041-propriedades-da-camada'),
                'foto': foto(dlg, '041-propriedades-da-camada')}
    doc['propriedades'] = abre_e_age(lambda: iface.showLayerProperties(lyr),
                                     topo_da_classe('LayerProperties'), agir)


def regiao_complementos(fonte):
    """Gerenciador de complementos: as abas Todos e Instalados mostram, no painel
    de detalhes, os textos 221 e 222 da fonte."""
    def agir(dlg):
        dlg.resize(1100, 720)
        espera(1500)
        r = {'classe': dlg.metaObject().className(), 'abas': []}
        from qgis.PyQt.QtWidgets import QListWidget
        lista = dlg.findChild(QListWidget, 'mOptionsListWidget') or dlg.findChild(QListWidget)
        for i in range(lista.count() if lista else 0):
            texto = lista.item(i).text()
            if texto not in ('Tudo', 'Todos', 'Instalados', 'All', 'Installed'):
                continue
            lista.setCurrentRow(i)
            espera(1200)
            marca_na_tela(fonte, textos_de(dlg), 'gerenciador de complementos, aba %s' % texto)
            r['abas'].append({'aba': texto, 'foto': foto(dlg, '041-complementos-%s' % texto.lower())})
        return r
    acao = iface.actionManagePlugins()
    doc['complementos'] = abre_e_age(acao.trigger, topo_da_classe('QgsPluginManager'), agir, limite=30000)


def regiao_depuracao():
    alvo = None
    for d in win().findChildren(QDockWidget):
        t = (d.windowTitle() or '') + ' ' + d.objectName()
        if 'epura' in t or 'DevTools' in t or 'Development' in t:
            alvo = d
            break
    if alvo is None:
        doc['depuracao'] = {'erro': 'dock de ferramentas de depuracao nao encontrado'}
        return
    alvo.setVisible(True)
    alvo.raise_()
    espera(900)
    doc['depuracao'] = {'titulo': alvo.windowTitle(), 'foto': foto(alvo, '041-ferramentas-de-depuracao')}


def regiao_rede():
    from qgis.PyQt.QtCore import QAbstractItemModel
    try:
        import sip
    except ImportError:
        from qgis.PyQt import sip
    achados = []
    for o in win().findChildren(QObject):
        if o.metaObject().className() == 'QgsNetworkLogger':
            achados.append(o)
    res = {'loggers': len(achados), 'pedidos': [],
           'logNetworkRequests': {k: QgsSettings().value(k, None) for k in ('app/logNetworkRequests', 'logNetworkRequests')}}
    # CONTROLE POSITIVO: um pedido feito AGORA a um endereco do produto tem de
    # aparecer no registro. Sem isso, "nenhum pedido a feed.qgis.org" poderia ser
    # so um registro desligado (medido: na rodada padrao ele nao grava nada).
    try:
        from qgis.core import QgsNetworkAccessManager
        from qgis.PyQt.QtNetwork import QNetworkRequest
        r = QgsNetworkAccessManager.instance().blockingGet(QNetworkRequest(QUrl('https://institutoiman.org.br/')))
        res['controle'] = {'url': 'https://institutoiman.org.br/', 'erro_de_rede': int(r.error())}
    except Exception:
        res['controle'] = {'excecao': traceback.format_exc(limit=2)}
    espera(500)
    for o in achados:
        try:
            m = o if isinstance(o, QAbstractItemModel) else sip.cast(o, QAbstractItemModel)
            for r in range(m.rowCount()):
                res['pedidos'].append(m.data(m.index(r, 0), Qt.DisplayRole))
        except Exception:
            res['erro'] = traceback.format_exc(limit=3)
    res['controle_no_registro'] = any(p and 'institutoiman.org.br' in p for p in res['pedidos'])
    res['feed_qgis_org'] = [p for p in res['pedidos'] if p and 'feed.qgis.org' in p]
    res['version_qgis_org'] = [p for p in res['pedidos'] if p and 'version.qgis.org' in p]
    doc['rede'] = res


def regiao_tradutor(fonte):
    from qgis.PyQt.QtCore import QCoreApplication
    try:
        from iman_brand import translation as _t
        estado = _t.status()
    except Exception as e:
        estado = {'installed': False, 'reason': repr(e)}
    tabela = []
    if fonte:
        # Nomes dos provedores, como a caixa e as Opcoes os pedem.
        reg = QgsApplication.processingRegistry()
        nomes = [p.name() for p in reg.providers()]
        marca_na_tela(fonte, nomes, 'QgsProcessingProvider.name() (caixa e Opcoes)')
        menu = win().findChild(QMenu, 'mHelpMenu')
        if menu is not None:
            marca_na_tela(fonte, [a.text().replace('&', '') for a in menu.actions()], 'menu Ajuda')
        for m in fonte['messages']:
            api = QCoreApplication.translate(m['context'], m['source'])
            tabela.append({
                'l08_index': m['l08_index'], 'contexto': m['context'],
                'fonte': m['source'][:90], 'esperado': m['esperado'][:120],
                'api': 'novo' if api == m['esperado'] else ('antigo' if api == m['qgis_pt_BR'] else api[:120]),
                'tela': m.get('tela', []),
            })
    doc['tradutor'] = {'estado': estado, 'mensagens': tabela}


def principal():
    # o produto de verdade: o --code e esta sonda, entao ela roda o iman_startup.py
    # como o aceite faz (o mesmo do launcher, nao uma imitacao)
    startup = os.environ.get('SPIKE017_STARTUP', '')
    doc['startup_real'] = 'ausente'
    if startup and os.path.exists(startup):
        try:
            with io.open(startup, 'r', encoding='utf-8') as fh:
                src = fh.read()
            exec(compile(src, startup, 'exec'), {'__name__': '__main__', '__file__': startup})
            doc['startup_real'] = startup
        except Exception as e:
            doc['startup_real'] = 'ERRO: %r' % (e,)

    def rodar():
        fonte, produto = fonte_do_tradutor()
        doc['quando'] = __import__('datetime').datetime.now().isoformat()
        doc['qgis'] = Qgis.QGIS_VERSION
        doc['produto'] = produto
        doc['perfil'] = QgsApplication.qgisSettingsDirPath()
        for nome, f in (('tema', regiao_tema), ('janela', regiao_janela), ('caixa', regiao_caixa),
                        ('rede', regiao_rede), ('depuracao', regiao_depuracao),
                        ('dialogo_sem_icone', regiao_dialogo_sem_icone)):
            try:
                f()
            except Exception:
                doc[nome] = {'excecao': traceback.format_exc(limit=4)}
        for nome, f in (('opcoes', lambda: regiao_opcoes(fonte)), ('ajuda', regiao_ajuda),
                        ('complementos', lambda: regiao_complementos(fonte))):
            try:
                f()
            except Exception:
                doc[nome] = {'excecao': traceback.format_exc(limit=4)}
        lyr = None
        try:
            lyr = camada_de_teste()
        except Exception:
            nota('camada de teste: ' + traceback.format_exc(limit=3))
        for nome, f in (('algoritmo', lambda: regiao_algoritmo(lyr, fonte)),
                        ('modelador', regiao_modelador),
                        ('propriedades', lambda: regiao_propriedades(lyr, fonte))):
            try:
                f()
            except Exception:
                doc[nome] = {'excecao': traceback.format_exc(limit=4)}
        try:
            regiao_tradutor(fonte)
        except Exception:
            doc['tradutor'] = {'excecao': traceback.format_exc(limit=4)}
        os.makedirs(OUT, exist_ok=True)
        with io.open(os.path.join(OUT, 'descoberta.json'), 'w', encoding='utf-8') as fh:
            json.dump(doc, fh, indent=2, ensure_ascii=False, default=str)
        print('EVIDENCIA041: gravada')

    # mesmo assentamento do aceite: plugin, home, declutter e startup ate ~4 s
    QTimer.singleShot(8000, rodar)


principal()
