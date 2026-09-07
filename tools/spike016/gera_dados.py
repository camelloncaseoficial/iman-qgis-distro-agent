# -*- coding: utf-8 -*-
"""
SPIKE #016 - gera os dados de teste do M2 usando o GDAL da PROPRIA arvore
relocada. Se o GDAL relocado estiver quebrado, este passo ja falha - o dado
de teste nao vem de fora, vem da arvore sob julgamento.

Saida (em SPIKE016_DADOS):
  spike016-vetor.geojson  - 3 poligonos em EPSG:31984
  spike016-raster.tif     - GeoTIFF 200x200 com gradiente (NAO uniforme, para
                            que 'canvas em branco' seja distinguivel de
                            'canvas desenhou')
"""
import json
import os
import sys

DADOS = os.environ.get('SPIKE016_DADOS', r'C:\Temp\spike016-dados')
os.makedirs(DADOS, exist_ok=True)

X0, Y0 = 555000.0, 9585000.0
TAM = 2000.0        # 2 km de lado
PX = 200            # 200x200 pixels -> 10 m/pixel

# ---------------------------------------------------------------- vetor
feicoes = []
for i, (dx, dy, nome) in enumerate([(200, 200, 'quadra A'),
                                    (900, 500, 'quadra B'),
                                    (1400, 1200, 'quadra C')]):
    x, y = X0 + dx, Y0 + dy
    L = 400.0
    anel = [[x, y], [x + L, y], [x + L, y + L], [x, y + L], [x, y]]
    feicoes.append({
        'type': 'Feature',
        'properties': {'id': i + 1, 'nome': nome},
        'geometry': {'type': 'Polygon', 'coordinates': [anel]},
    })

gj = {
    'type': 'FeatureCollection',
    'name': 'spike016_vetor',
    'crs': {'type': 'name', 'properties': {'name': 'urn:ogc:def:crs:EPSG::31984'}},
    'features': feicoes,
}
caminho_vetor = os.path.join(DADOS, 'spike016-vetor.geojson')
with open(caminho_vetor, 'w', encoding='utf-8') as fh:
    json.dump(gj, fh)
print('vetor : %s (%d feicoes)' % (caminho_vetor, len(feicoes)))

# ---------------------------------------------------------------- raster
from osgeo import gdal, osr
gdal.UseExceptions()

caminho_raster = os.path.join(DADOS, 'spike016-raster.tif')
drv = gdal.GetDriverByName('GTiff')
ds = drv.Create(caminho_raster, PX, PX, 3, gdal.GDT_Byte)
ds.SetGeoTransform([X0, TAM / PX, 0.0, Y0 + TAM, 0.0, -TAM / PX])
srs = osr.SpatialReference()
srs.ImportFromEPSG(31984)
ds.SetProjection(srs.ExportToWkt())

# gradiente + xadrez: garante muitas cores distintas no canvas
linhas_r, linhas_g, linhas_b = [], [], []
for j in range(PX):
    lr, lg, lb = [], [], []
    for i in range(PX):
        xadrez = 60 if ((i // 20) + (j // 20)) % 2 else 0
        lr.append((i * 255 // PX + xadrez) % 256)
        lg.append((j * 255 // PX) % 256)
        lb.append((255 - (i + j) * 255 // (2 * PX)) % 256)
    linhas_r.append(lr); linhas_g.append(lg); linhas_b.append(lb)

try:
    import numpy as np
    ds.GetRasterBand(1).WriteArray(np.array(linhas_r, dtype='uint8'))
    ds.GetRasterBand(2).WriteArray(np.array(linhas_g, dtype='uint8'))
    ds.GetRasterBand(3).WriteArray(np.array(linhas_b, dtype='uint8'))
except ImportError:
    print('numpy ausente na arvore relocada - abortando', file=sys.stderr)
    sys.exit(2)

ds.FlushCache()
ds = None

# reabre para provar que saiu valido
ver = gdal.Open(caminho_raster)
print('raster: %s (%dx%d, %d bandas, CRS=%s)'
      % (caminho_raster, ver.RasterXSize, ver.RasterYSize, ver.RasterCount,
         osr.SpatialReference(wkt=ver.GetProjection()).GetAuthorityCode(None)))
ver = None
print('gdal  : %s' % gdal.VersionInfo('RELEASE_NAME'))
