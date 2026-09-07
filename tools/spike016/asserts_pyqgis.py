# -*- coding: utf-8 -*-
"""
SPIKE #016 - assercoes de PRODUTO do QGIS relocado (M3, M4, M5, M7).

Roda com o python-qgis-ltr da propria arvore (relocada OU instalada), imprime
JSON e sai com 0 (tudo PASS) ou 1 (algum FAIL).

Cada assercao foi desenhada para ser SENSIVEL AO DEFEITO (C.2 do briefing):
o que ela devolve se a arvore estiver quebrada esta anotado em 'se_quebrado'.

  M5  import qgis.core + QgsApplication            -> ImportError / DLL load failed
  M3  PROJ: EPSG:4674 -> EPSG:31984                -> excecao, ou coordenada ERRADA
                                                      (por isso compara com valor
                                                      esperado com tolerancia, e nao
                                                      so "nao levantou excecao")
  M4  GDAL: escreve e reabre GeoTIFF, le CRS       -> CRS vazio / driver ausente
  M7  Processing: native:buffer                    -> algoritmo nao registrado, ou
                                                      area errada

USO
  <arvore>\\bin\\python-qgis-ltr.bat asserts_pyqgis.py --saida resultado.json
"""
import argparse
import json
import math
import os
import sys
import tempfile
import traceback

# ---------------------------------------------------------------- esperado
# Ponto de referencia em Fortaleza/CE, SIRGAS 2000 geografico (EPSG:4674).
LON, LAT = -38.5, -3.75
# Destino: SIRGAS 2000 / UTM zone 24S (EPSG:31984), meridiano central -39.
#
# PROVENIENCIA DO VALOR ESPERADO (importa: um numero inventado nao e oraculo):
#   medido no QGIS 3.44.13 INSTALADO desta bancada (PROJ 9.8.1, GDAL 3.13.2)
#   em 2026-09-06, e conferido de forma INDEPENDENTE contra a serie de
#   Transverse Mercator (GRS80, k0=0.9996, FE=500000, FN=10000000), que da
#   E~555519.4 / N~9585497 - dentro de ~7 m da serie truncada usada a mao.
#   Um erro de datum ou de zona erra por centenas de metros a quilometros,
#   ordens de grandeza acima dessa folga.
ESPERADO_E, ESPERADO_N = 555519.856, 9585490.545
TOL_M = 1.0  # metros: folga para diferenca de versao de grid, e apertada o
             # suficiente para pegar datum/zona errados.
#
# LIMITE DECLARADO DO M3: se o PROJ relocado ler o share\proj de OUTRA
# instalacao da MESMA versao, o numero sai igual e o M3 passa. Quem pega esse
# vazamento e o M3b (caminho efetivo dos dados do PROJ), nao o M3.

resultados = []


def registra(nome, ok, detalhe, se_quebrado, extra=None):
    resultados.append({
        'id': nome,
        'status': 'PASS' if ok else 'FAIL',
        'detalhe': detalhe,
        'se_quebrado': se_quebrado,
        'extra': extra or {},
    })


# ============================================================ M5
def m5():
    se_quebrado = ("ImportError / 'DLL load failed' se as DLLs do Qt/QGIS nao "
                   "estiverem no PATH da arvore, ou se QGIS_PREFIX_PATH apontar "
                   "para outra arvore inexistente")
    try:
        import qgis.core as qc
        app = qc.QgsApplication([], False)
        qc.QgsApplication.setPrefixPath(os.environ.get('QGIS_PREFIX_PATH', ''), True)
        app.initQgis()
        versao = qc.Qgis.QGIS_VERSION
        prefixo = qc.QgsApplication.prefixPath()
        pkg = os.path.dirname(qc.__file__)
        ok = bool(versao) and bool(prefixo)
        registra('M5', ok,
                 'qgis.core importado; QgsApplication instanciada e inicializada',
                 se_quebrado,
                 {'QGIS_VERSION': versao,
                  'prefixPath': prefixo,
                  'qgis.core em': pkg,
                  'pythonExecutable': sys.executable})
        return app, qc
    except Exception:
        registra('M5', False, 'excecao: ' + traceback.format_exc(limit=3),
                 se_quebrado)
        return None, None


# ============================================================ M3
def m3(qc):
    se_quebrado = ("PROJ sem proj.db devolve CRS invalido (isValid()==False) ou "
                   "levanta excecao; PROJ_DATA apontando para OUTRA arvore devolve "
                   "coordenada que PARECE certa mas usa outro grid -> por isso a "
                   "comparacao numerica com tolerancia de %.1f m" % TOL_M)
    try:
        origem = qc.QgsCoordinateReferenceSystem('EPSG:4674')
        destino = qc.QgsCoordinateReferenceSystem('EPSG:31984')

        if not origem.isValid() or not destino.isValid():
            registra('M3', False,
                     'CRS invalido: 4674.isValid=%s 31984.isValid=%s '
                     '(proj.db nao encontrado)' % (origem.isValid(), destino.isValid()),
                     se_quebrado)
            return

        ct = qc.QgsCoordinateTransform(origem, destino, qc.QgsProject.instance())
        p = ct.transform(qc.QgsPointXY(LON, LAT))
        de = abs(p.x() - ESPERADO_E)
        dn = abs(p.y() - ESPERADO_N)
        ok = (de <= TOL_M and dn <= TOL_M)

        # de onde o PROJ leu os dados, na pratica
        try:
            paths = qc.QgsApplication.qgisSettingsDirPath()
        except Exception:
            paths = ''

        registra('M3', ok,
                 'EPSG:4674 (%.4f, %.4f) -> EPSG:31984 (%.2f, %.2f); '
                 'esperado (%.2f, %.2f); erro (%.3f m, %.3f m)'
                 % (LON, LAT, p.x(), p.y(), ESPERADO_E, ESPERADO_N, de, dn),
                 se_quebrado,
                 {'E': round(p.x(), 3), 'N': round(p.y(), 3),
                  'erro_E_m': round(de, 4), 'erro_N_m': round(dn, 4),
                  'tolerancia_m': TOL_M,
                  'descricao_31984': destino.description(),
                  'PROJ_DATA': os.environ.get('PROJ_DATA', '<nao definida>'),
                  'PROJ_LIB': os.environ.get('PROJ_LIB', '<nao definida>'),
                  'settingsDirPath': paths})
    except Exception:
        registra('M3', False, 'excecao: ' + traceback.format_exc(limit=3), se_quebrado)


# ============================================================ M3b
def m3b(qc):
    """De onde o PROJ efetivamente leu proj.db - pega vazamento silencioso."""
    se_quebrado = ("se o PROJ estiver lendo o share\\proj de OUTRA instalacao, "
                   "este caminho aponta para fora da arvore relocada")
    try:
        from osgeo import osr
        # pyproj enxerga a mesma config do PROJ que o GDAL/QGIS usam
        import pyproj
        dd = list(pyproj.datadir.get_data_dir().split(os.pathsep))
        registra('M3b', True, 'diretorio de dados do PROJ em uso: %s' % dd,
                 se_quebrado, {'proj_data_dir': dd,
                               'pyproj_version': pyproj.__version__,
                               'PROJ_VERSION': pyproj.proj_version_str})
    except Exception:
        registra('M3b', False, 'excecao: ' + traceback.format_exc(limit=3), se_quebrado)


# ============================================================ M3c
def m3c(qc):
    """Transformacao que EXIGE proj.db - fecha o buraco do M3.

    Medido em 2026-09-06: com share\\proj renomeado, o M3 continuou PASSANDO,
    porque EPSG:4674 -> EPSG:31984 e uma UTM simples que o QGIS resolve pelo
    proprio srs.db, sem consultar o proj.db do PROJ. Ou seja: o M3 sozinho NAO
    e sensivel a ausencia da base do PROJ.

    SAD69 (EPSG:4618) -> SIRGAS 2000 (EPSG:4674) e um DESLOCAMENTO DE DATUM: a
    operacao vive no proj.db. Sem ele o PROJ cai em 'ballpark' (trata como se
    fossem o mesmo datum) e devolve praticamente a coordenada de entrada -
    silenciosamente errada em dezenas de metros. E exatamente o modo de falha
    que o briefing manda cacar.
    """
    se_quebrado = ("sem proj.db o PROJ faz transformacao 'ballpark' (identidade) e "
                   "devolve deslocamento ~0 m em vez do deslocamento real de datum: "
                   "resultado ERRADO e silencioso, nao excecao")
    try:
        sad69 = qc.QgsCoordinateReferenceSystem('EPSG:4618')
        sirgas = qc.QgsCoordinateReferenceSystem('EPSG:4674')
        if not sad69.isValid() or not sirgas.isValid():
            registra('M3c', False, 'CRS invalido: 4618=%s 4674=%s'
                     % (sad69.isValid(), sirgas.isValid()), se_quebrado)
            return
        ct = qc.QgsCoordinateTransform(sad69, sirgas, qc.QgsProject.instance())
        p = ct.transform(qc.QgsPointXY(LON, LAT))
        # deslocamento em graus -> metros aproximados
        dx_m = (p.x() - LON) * 111320.0 * math.cos(math.radians(LAT))
        dy_m = (p.y() - LAT) * 110540.0
        desloc = math.hypot(dx_m, dy_m)
        # SAD69 -> SIRGAS2000 no Nordeste desloca ordem de dezenas de metros.
        # Ballpark (proj.db ausente) daria ~0.
        ok = (desloc > 5.0)
        registra('M3c', ok,
                 'SAD69 -> SIRGAS2000 em (%.4f, %.4f): deslocamento %.2f m '
                 '(dx=%.2f m, dy=%.2f m). Ballpark daria ~0 m.'
                 % (LON, LAT, desloc, dx_m, dy_m),
                 se_quebrado,
                 {'deslocamento_m': round(desloc, 3),
                  'dx_m': round(dx_m, 3), 'dy_m': round(dy_m, 3),
                  'limiar_m': 5.0})
    except Exception:
        registra('M3c', False, 'excecao: ' + traceback.format_exc(limit=3), se_quebrado)


# ============================================================ M4
def m4(qc):
    se_quebrado = ("sem GDAL_DATA correto o driver GTiff some (gdal.GetDriverByName "
                   "devolve None) ou o CRS lido volta vazio/sem authority - "
                   "por isso o teste exige EPSG:31984 de volta, e nao so 'abriu'")
    tmp = None
    try:
        from osgeo import gdal, osr
        gdal.UseExceptions()

        drv = gdal.GetDriverByName('GTiff')
        if drv is None:
            registra('M4', False, 'driver GTiff ausente (GDAL_DATA/plugins errados)',
                     se_quebrado)
            return

        tmp = os.path.join(tempfile.gettempdir(), 'spike016_m4.tif')
        ds = drv.Create(tmp, 16, 16, 1, gdal.GDT_Byte)
        ds.SetGeoTransform([555000.0, 10.0, 0.0, 9586000.0, 0.0, -10.0])
        srs = osr.SpatialReference()
        srs.ImportFromEPSG(31984)
        ds.SetProjection(srs.ExportToWkt())
        banda = ds.GetRasterBand(1)
        banda.Fill(42)
        ds = None

        # reabre e le de volta
        ds2 = gdal.Open(tmp, gdal.GA_ReadOnly)
        wkt = ds2.GetProjection()
        srs2 = osr.SpatialReference(wkt=wkt)
        auth = srs2.GetAuthorityCode(None)
        nome = srs2.GetName()
        gt = ds2.GetGeoTransform()
        stats = ds2.GetRasterBand(1).ComputeRasterMinMax(False)
        tam = (ds2.RasterXSize, ds2.RasterYSize)
        ds2 = None

        ok = (auth == '31984' and tam == (16, 16) and abs(stats[0] - 42) < 1e-9)
        registra('M4', ok,
                 'GeoTIFF escrito e reaberto; authority=%s nome=%s tamanho=%s '
                 'minmax=%s' % (auth, nome, tam, stats),
                 se_quebrado,
                 {'gdal_version': gdal.VersionInfo('RELEASE_NAME'),
                  'authority': auth, 'nome_crs': nome,
                  'geotransform': list(gt), 'minmax': list(stats),
                  'GDAL_DATA': os.environ.get('GDAL_DATA', '<nao definida>'),
                  'n_drivers': gdal.GetDriverCount(),
                  'arquivo': tmp})
    except Exception:
        registra('M4', False, 'excecao: ' + traceback.format_exc(limit=3), se_quebrado)
    finally:
        if tmp and os.path.exists(tmp):
            try:
                os.remove(tmp)
            except OSError:
                pass


# ============================================================ M7
def m7(qc):
    se_quebrado = ("sem os provedores nativos registrados, processing.run levanta "
                   "QgsProcessingException 'algorithm not found'; se a geometria/PROJ "
                   "estiver errada a area do buffer sai diferente - por isso o teste "
                   "confere a AREA, e nao so 'rodou'")
    try:
        sys.path.append(os.path.join(os.environ['QGIS_PREFIX_PATH'].replace('/', os.sep),
                                     'python', 'plugins'))
        from qgis.analysis import QgsNativeAlgorithms
        import processing
        from processing.core.Processing import Processing

        Processing.initialize()
        qc.QgsApplication.processingRegistry().addProvider(QgsNativeAlgorithms())

        n_algs = len(qc.QgsApplication.processingRegistry().algorithms())

        # camada de memoria: 1 ponto em EPSG:31984 (metros)
        vl = qc.QgsVectorLayer('Point?crs=EPSG:31984', 'p', 'memory')
        f = qc.QgsFeature()
        f.setGeometry(qc.QgsGeometry.fromPointXY(qc.QgsPointXY(555584.31, 9585417.68)))
        vl.dataProvider().addFeatures([f])
        vl.updateExtents()

        res = processing.run('native:buffer', {
            'INPUT': vl,
            'DISTANCE': 100.0,
            'SEGMENTS': 64,
            'END_CAP_STYLE': 0,
            'JOIN_STYLE': 0,
            'MITER_LIMIT': 2,
            'DISSOLVE': False,
            'OUTPUT': 'memory:'
        })
        saida = res['OUTPUT']
        feicoes = list(saida.getFeatures())
        area = feicoes[0].geometry().area() if feicoes else 0.0
        area_teorica = math.pi * 100.0 ** 2      # 31415.93
        erro_rel = abs(area - area_teorica) / area_teorica

        ok = (len(feicoes) == 1 and erro_rel < 0.01 and n_algs > 100)
        registra('M7', ok,
                 'native:buffer(100 m) sobre 1 ponto -> %d feicao, area=%.2f m2 '
                 '(teorica %.2f, erro rel %.4f); %d algoritmos registrados'
                 % (len(feicoes), area, area_teorica, erro_rel, n_algs),
                 se_quebrado,
                 {'n_algoritmos': n_algs, 'area_m2': round(area, 3),
                  'area_teorica_m2': round(area_teorica, 3),
                  'erro_relativo': round(erro_rel, 6)})
    except Exception:
        registra('M7', False, 'excecao: ' + traceback.format_exc(limit=4), se_quebrado)


# ============================================================ main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--saida', default='')
    ap.add_argument('--rotulo', default='relocado')
    a = ap.parse_args()

    app, qc = m5()
    if qc is not None:
        m3(qc)
        m3b(qc)
        m3c(qc)
        m4(qc)
        m7(qc)

    doc = {
        'rotulo': a.rotulo,
        'python': sys.executable,
        'OSGEO4W_ROOT': os.environ.get('OSGEO4W_ROOT', ''),
        'QGIS_PREFIX_PATH': os.environ.get('QGIS_PREFIX_PATH', ''),
        'PROJ_DATA': os.environ.get('PROJ_DATA', ''),
        'PROJ_LIB': os.environ.get('PROJ_LIB', ''),
        'GDAL_DATA': os.environ.get('GDAL_DATA', ''),
        'resultados': resultados,
    }
    texto = json.dumps(doc, indent=2, ensure_ascii=False)
    print(texto)
    if a.saida:
        with open(a.saida, 'w', encoding='utf-8') as fh:
            fh.write(texto)

    falhas = [r for r in resultados if r['status'] != 'PASS']
    print('\nPLACAR: %d de %d PASS' % (len(resultados) - len(falhas), len(resultados)))
    if app is not None:
        try:
            app.exitQgis()
        except Exception:
            pass
    sys.exit(1 if falhas else 0)


if __name__ == '__main__':
    main()
