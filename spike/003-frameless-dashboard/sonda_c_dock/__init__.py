# -*- coding: utf-8 -*-
"""SONDA C — plugin de marca que hospeda a home como DOCK (rede de segurança).

Caminho de plugin PADRÃO do QGIS (addDockWidget/removeDockWidget): não toca a
janela principal, não re-flagga, não reparenta o menuBar — logo NÃO tem a
instabilidade da Sonda A. Entrega o valor de onboarding do comp no no-fork mesmo
que A e B falhem. Créditos do QGIS presentes (BL-1/BL-2)."""


def classFactory(iface):
    from .iman_home import ImanHomePlugin
    return ImanHomePlugin(iface)
