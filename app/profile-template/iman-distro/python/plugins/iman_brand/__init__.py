# -*- coding: utf-8 -*-
"""IMAN Terra — plugin de marca leve (powered by QGIS).

Entrypoint do plugin. Não reimplementa nem copia o plugin REURB (D-IMAN-025):
esta é a camada institucional de marca (menu, boas-vindas, créditos).
"""


def classFactory(iface):  # noqa: N802 (assinatura exigida pelo QGIS)
    from .iman_brand import ImanBrandPlugin
    return ImanBrandPlugin(iface)
