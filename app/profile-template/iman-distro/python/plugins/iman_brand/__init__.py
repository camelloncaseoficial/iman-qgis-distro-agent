# -*- coding: utf-8 -*-
"""IMAN Terra — plugin de marca leve (powered by QGIS).

Entrypoint do plugin. Não reimplementa nem copia o plugin REURB (D-IMAN-025):
esta é a camada institucional de marca (menu, boas-vindas, créditos).
"""


def classFactory(iface):  # noqa: N802 (assinatura exigida pelo QGIS)
    # #041: o tradutor sobreposto entra o mais cedo que um plugin alcanca, antes
    # de qualquer widget da marca e de o QGIS pedir o nome dos provedores ao
    # montar a caixa de Processamento. Os enderecos da Ajuda sao lidos no clique,
    # entao basta que estejam gravados antes dele.
    from . import product_links, translation
    translation.install()
    product_links.apply()
    from .iman_brand import ImanBrandPlugin
    return ImanBrandPlugin(iface)
