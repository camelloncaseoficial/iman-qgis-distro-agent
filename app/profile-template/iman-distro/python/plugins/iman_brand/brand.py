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

# --- Paleta oficial (travada da arte oficial) ----------------------------------
# STOP-AND-FLAG (D-IMAN-026, 2026-07-11): esta paleta foi SUPERADA pela paleta do
# redesign "IMAN Terra" (docs/design-system.md, seção ATIVA). Estes COLOR_* seguem
# aqui — e a arte de app/assets/ segue derivada deles — como STALE declarado, até a
# fatia de promoção (brand.py + QSS + re-derivação da arte). O spike #003 NÃO troca
# estes valores (evitar produção meio-tematizada). Paleta nova só nas UIs do spike
# (spike/003-frameless-dashboard/tokens.py). Ver design-system.md e o REPORT do spike.
# Reconciliada 2026-07-07 (fatia 002) a partir do master vetorial oficial
# `app/assets/splash-iman-terra.svg` (drop do sponsor 2026-07-06). ESPELHA a tabela
# de docs/design-system.md (BL-4): as duas fontes DEVEM bater, valor a valor.
# STOP-AND-FLAG (autoridade final): o SVG é arte DERIVADA (splash), não o manual de
# marca. Se/quando o `IMAN.cdr`/manual oficial chegar, ele PREVALECE — travar o que
# temos, sem inventar cores fora da arte. Nota: `brand.text` foi reconciliado para
# `#041C16` (wordmark real do SVG); o `#0F1F18` proposto no briefing 002 não consta
# na arte, então usa-se o valor de fato presente.
COLOR_PRIMARY = "#00A85A"       # brand.primary — verde-marca / destaque (SVG)
COLOR_PRIMARY_DEEP = "#0D5138"  # brand.primary-deep — verde de apoio / chrome escura (SVG)
COLOR_INK = "#041C16"           # brand.ink — verde quase-preto / fundos escuros do splash (SVG)
COLOR_ACCENT = "#2CA8E0"        # brand.accent — azul do globo / ação / links (SVG)
COLOR_MINT = "#5FE0A0"          # brand.mint — realce / highlight (SVG)
COLOR_WARM = "#C56A2F"          # brand.warm — accent quente (terracota) (SVG)
COLOR_SURFACE = "#F2F8F3"       # brand.surface — fundo de painel claro (SVG)
COLOR_TEXT = "#041C16"          # brand.text — texto sobre claro (= ink; wordmark do SVG)
# Alias de compatibilidade: código legado usa COLOR_SECONDARY (= primary-deep).
COLOR_SECONDARY = COLOR_PRIMARY_DEEP

# --- Links (STOP-AND-FLAG mantido — domínio NÃO confirmado nesta fatia) ---------
# Dono da resposta: arquiteto (PPSA) + crew do site institucional (iman-web-frontend).
# Pergunta explícita: o domínio oficial é `institutoiman.org.br`? Há URL de docs
# pública distinta? Enquanto não confirmado, mantém-se este palpite sinalizado — não
# se cunha decisão de produto aqui (a crew consome D-IDs, não os cria).
URL_SITE = "https://institutoiman.org.br"   # STOP-AND-FLAG: confirmar domínio oficial
URL_DOCS = "https://institutoiman.org.br"   # STOP-AND-FLAG: confirmar URL de docs pública

# --- Crédito ao QGIS (BL-1/BL-2) — verbatim de docs/BRANDING_AND_LICENSE.md -----
# NUNCA remover, ocultar ou enfraquecer. Usado no "Sobre", boas-vindas e notices.
CREDITS_QGIS = (
    "{product} é uma experiência geoespacial desktop independente, powered by QGIS.\n"
    "O QGIS é um sistema de informação geográfica livre e de código aberto, "
    "desenvolvido por QGIS.ORG e contribuidores.\n"
    "Este projeto não é um produto oficial do QGIS e não é endossado pela QGIS.ORG."
).format(product=PRODUCT_NAME)
