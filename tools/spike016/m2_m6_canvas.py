# -*- coding: utf-8 -*-
"""
SPIKE #016 - M2 (canvas renderiza vetor e raster) e M6 (plugin iman_brand
carrega no perfil isolado), dentro do QGIS RELOCADO.

Roda como startup script do QGIS:  qgis-ltr-bin.exe --code m2_m6_canvas.py

Nao decide nada sozinho: carrega as camadas, espera o canvas TERMINAR de
desenhar, e grava um JSON com o que deu. A janela fica aberta para a foto.

SENSIBILIDADE AO DEFEITO (C.2)
  M2 - nao basta 'a camada carregou'. O teste exige:
       * layer.isValid() == True para vetor E raster;
       * o canvas ter emitido renderComplete (se o provedor quebrar, o sinal
         nao vem e o teste estoura por timeout);
       * a imagem renderizada ter MAIS DE UMA COR - um canvas em branco
         silencioso (o modo de falha que o briefing nomeia) tem exatamente uma.
  M6 - nao basta o .py existir na pasta. O teste exige o plugin em
       qgis.utils.plugins (instancia viva) e a acao dele registrada na GUI.
"""
import json
import os
import traceback

from qgis.core import (QgsProject, QgsVectorLayer, QgsRasterLayer,
                       QgsCoordinateReferenceSystem, Qgis)
from qgis.PyQt.QtCore import QTimer
from qgis.PyQt.QtGui import QImage, QColor
# --code roda com um namespace proprio: 'iface' NAO vem de graca ali.
from qgis.utils import iface

SAIDA = os.environ.get('SPIKE016_SAIDA', r'C:\Temp\spike016-m2-m6.json')
DADOS = os.environ.get('SPIKE016_DADOS', r'C:\Temp\spike016-dados')

resultado = {'M2': None, 'M6': None, 'ambiente': {}}


def grava():
    with open(SAIDA, 'w', encoding='utf-8') as fh:
        json.dump(resultado, fh, indent=2, ensure_ascii=False)
    print('SPIKE016: gravado %s' % SAIDA)


def cores_distintas(img, limite=8):
    """Conta cores distintas amostrando a imagem. Canvas em branco -> 1."""
    vistas = set()
    w, h = img.width(), img.height()
    passo_x = max(1, w // 60)
    passo_y = max(1, h // 60)
    for y in range(0, h, passo_y):
        for x in range(0, w, passo_x):
            vistas.add(img.pixel(x, y))
            if len(vistas) >= limite:
                return len(vistas)
    return len(vistas)


def medir_m6():
    se_quebrado = ("se o perfil isolado nao for o perfil em uso, ou o plugin nao "
                   "carregar, 'iman_brand' nao aparece em qgis.utils.plugins e a "
                   "acao nao existe na GUI - diferente de 'o arquivo esta la'")
    try:
        import qgis.utils as qu
        carregado = 'iman_brand' in qu.plugins
        instancia = qu.plugins.get('iman_brand')
        # sinal de GUI: o menu proprio da marca
        menus = [m.text() for m in iface.mainWindow().menuBar().actions()]
        perfil = QgsProject.instance().homePath()
        from qgis.core import QgsApplication
        dir_perfil = QgsApplication.qgisSettingsDirPath()

        resultado['M6'] = {
            'status': 'PASS' if (carregado and instancia is not None) else 'FAIL',
            'se_quebrado': se_quebrado,
            'em_qgis_utils_plugins': carregado,
            'classe_instancia': type(instancia).__name__ if instancia else None,
            'plugins_carregados': sorted(qu.plugins.keys()),
            'menus_da_barra': menus,
            'qgisSettingsDirPath': dir_perfil,
            'titulo_janela': iface.mainWindow().windowTitle(),
        }
    except Exception:
        resultado['M6'] = {'status': 'FAIL', 'se_quebrado': se_quebrado,
                           'excecao': traceback.format_exc(limit=4)}


def medir_m2():
    se_quebrado = ("provedor quebrado -> isValid()==False; render que nunca "
                   "completa -> timeout; canvas em branco silencioso -> 1 cor "
                   "distinta na imagem")
    try:
        # Maximiza antes de medir: um canvas de 125x38 px renderiza, mas nao
        # serve de evidencia visual - a foto tem de mostrar o mapa de verdade.
        iface.mainWindow().showMaximized()
        canvas = iface.mapCanvas()
        vetor = os.path.join(DADOS, 'spike016-vetor.geojson')
        raster = os.path.join(DADOS, 'spike016-raster.tif')

        vl = QgsVectorLayer(vetor, 'spike016-vetor', 'ogr')
        rl = QgsRasterLayer(raster, 'spike016-raster', 'gdal')

        info = {
            'vetor_arquivo': vetor,
            'vetor_valido': vl.isValid(),
            'vetor_n_feicoes': vl.featureCount() if vl.isValid() else -1,
            'vetor_crs': vl.crs().authid() if vl.isValid() else '',
            'raster_arquivo': raster,
            'raster_valido': rl.isValid(),
            'raster_dim': [rl.width(), rl.height()] if rl.isValid() else [],
            'raster_crs': rl.crs().authid() if rl.isValid() else '',
            'raster_provedor': rl.dataProvider().name() if rl.isValid() else '',
        }

        if not (vl.isValid() and rl.isValid()):
            resultado['M2'] = dict(info, status='FAIL', se_quebrado=se_quebrado,
                                   motivo='camada invalida')
            grava()
            return

        QgsProject.instance().addMapLayer(rl)
        QgsProject.instance().addMapLayer(vl)
        canvas.setDestinationCrs(QgsCoordinateReferenceSystem('EPSG:31984'))
        canvas.setExtent(rl.extent())
        canvas.refresh()

        estado = {'pronto': False}

        def ao_terminar(painter=None):
            estado['pronto'] = True

        canvas.renderComplete.connect(ao_terminar)

        def conferir(tentativa=[0]):
            tentativa[0] += 1
            if not estado['pronto'] and tentativa[0] < 40:
                QTimer.singleShot(500, conferir)
                return
            img = canvas.grab().toImage()
            n = cores_distintas(img)
            ok = estado['pronto'] and n > 1
            resultado['M2'] = dict(
                info, status='PASS' if ok else 'FAIL', se_quebrado=se_quebrado,
                renderComplete_emitido=estado['pronto'],
                tentativas=tentativa[0],
                cores_distintas_no_canvas=n,
                canvas_px=[img.width(), img.height()],
                extent=canvas.extent().toString(2),
                crs_canvas=canvas.mapSettings().destinationCrs().authid(),
                camadas_no_canvas=[l.name() for l in canvas.layers()])
            sufixo = os.environ.get('SPIKE016_TAG', 'x')
            img.save(os.path.join(DADOS, 'canvas-%s.png' % sufixo))
            # Foto pelo lado do Qt: independe de quem esta na frente na tela.
            # (A captura por CopyFromScreen pegou a janela errada em 2026-09-06,
            #  quando outro instalador roubou o foreground desta bancada.)
            try:
                iface.mainWindow().grab().save(
                    os.path.join(DADOS, 'janela-%s.png' % sufixo))
            except Exception:
                pass
            medir_m6()
            resultado['ambiente'] = {
                'QGIS_VERSION': Qgis.QGIS_VERSION,
                'OSGEO4W_ROOT': os.environ.get('OSGEO4W_ROOT', ''),
                'QGIS_PREFIX_PATH': os.environ.get('QGIS_PREFIX_PATH', ''),
                'PROJ_DATA': os.environ.get('PROJ_DATA', ''),
            }
            grava()

        QTimer.singleShot(3000, conferir)
    except Exception:
        resultado['M2'] = {'status': 'FAIL', 'se_quebrado': se_quebrado,
                           'excecao': traceback.format_exc(limit=4)}
        grava()


QTimer.singleShot(6000, medir_m2)
print('SPIKE016: startup instalado; medindo M2/M6 em 3 s')
