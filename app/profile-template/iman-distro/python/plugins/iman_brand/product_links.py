# -*- coding: utf-8 -*-
"""Enderecos do menu Ajuda que sao do PRODUTO (#041, D-IMAN-039 item 4).

"Pagina do IMAN Terra", "Relatar um problema" e "Suporte comercial" apontam para o
endereco do produto, lido da fonte unica de marca (`brand.URL_SITE`, BL-4). O QGIS
le estas chaves NA HORA DO CLIQUE, com o endereco do qgis.org como padrao, entao
basta que elas estejam no QgsSettings antes de o usuario clicar.

FICAM COM O QGIS, de proposito: "Doe para o QGIS" (`qgis/donate`), "Envolva-se"
(`qgis/getInvolved`), "Membros de Suporte do QGIS" (`qgis/qgisSponsorsUrl`) e a
ajuda F1 (`help/helpSearchPath`, o manual do QGIS; nao ha manual do produto).
Nenhuma delas e tocada aqui.

POR QUE NO PLUGIN E NAO NO TEMPLATE DO PERFIL. O template e um .ini estatico: o
endereco escrito nele seria uma segunda copia de `brand.URL_SITE`. Aqui ele e lido
da fonte. A chave so e escrita quando difere, entao abrir de novo nao escreve.
"""
from qgis.core import QgsSettings

from . import brand

HELP_URL_KEYS = (
    "qgis/helpQgisHomePageUrl",
    "qgis/reportaBugUrl",
    "qgis/supportProvidersUrl",
)


def apply():
    """Grava os enderecos do produto. Devolve {chave: valor}. Nunca levanta."""
    applied = {}
    try:
        settings = QgsSettings()
        for key in HELP_URL_KEYS:
            if settings.value(key, "") != brand.URL_SITE:
                settings.setValue(key, brand.URL_SITE)
            applied[key] = settings.value(key, "")
    except Exception as exc:
        applied["_erro"] = repr(exc)
    return applied
