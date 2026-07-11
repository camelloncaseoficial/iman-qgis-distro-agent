# -*- coding: utf-8 -*-
"""
Fonte única de marca (código) — IMAN Terra.

BL-4 (BRAND_TOKENS_SINGLE_SOURCE): este módulo é a ÚNICA fonte de verdade em código
para o nome do produto, subtítulo, título de janela, paleta e textos de crédito.
A fonte humana equivalente é `docs/design-system.md`. Renomear o produto ou trocar a
paleta = editar AQUI (+ a tabela do design-system). Os artefatos não-Python que
espelham estas strings (metadata.txt, installer/*.iss, app/notices/*) carregam um
comentário apontando para esta fonte.

Nada aqui pode sugerir que o Instituto IMAN é autor do QGIS (BL-1/BL-2).
"""

# --- Identidade do produto (espelha docs/design-system.md) ---------------------
PRODUCT_NAME = "IMAN Terra"
PRODUCT_SUBTITLE = "Uma experiência geoespacial customizada, powered by QGIS."
WINDOW_TITLE = "IMAN Terra — powered by QGIS"
PUBLISHER = "Instituto IMAN"
ORG_FULL = ("Instituto de Monitoramento Ambiental e Desenvolvimento "
            "do Semiárido do Nordeste")
VERSION = "0.1.0"

# --- Paleta (amostrada do logo institucional real — verde IMAN #00A858) --------
# STOP-AND-FLAG: hex exato e paleta completa aguardam o manual de marca oficial
# (IMAN.cdr). Estes valores foram AMOSTRADOS de docs/IMAN_fundo_branco.jpeg e são
# provisórios; a fatia /branding os confirma. Ver docs/design-system.md.
COLOR_PRIMARY = "#00A858"    # verde IMAN (marca / destaque)
COLOR_SECONDARY = "#00753D"  # verde escuro (apoio) — derivado
COLOR_ACCENT = "#1C86C9"     # azul do globo do emblema (ação / links) — amostrado
COLOR_SURFACE = "#F4F8F5"    # fundo de painel (verde muito claro)
COLOR_TEXT = "#14231C"       # texto principal (quase preto esverdeado)

# --- Links (placeholders sinalizados — confirmar na fatia /branding) -----------
URL_SITE = "https://institutoiman.org.br"   # STOP-AND-FLAG: confirmar domínio oficial
URL_DOCS = "https://institutoiman.org.br"   # STOP-AND-FLAG: doc pública futura

# --- Crédito ao QGIS (BL-1/BL-2) — verbatim de docs/BRANDING_AND_LICENSE.md -----
# NUNCA remover, ocultar ou enfraquecer. Usado no "Sobre", boas-vindas e notices.
CREDITS_QGIS = (
    "{product} é uma experiência geoespacial desktop independente, powered by QGIS.\n"
    "O QGIS é um sistema de informação geográfica livre e de código aberto, "
    "desenvolvido por QGIS.ORG e contribuidores.\n"
    "Este projeto não é um produto oficial do QGIS e não é endossado pela QGIS.ORG."
).format(product=PRODUCT_NAME)
