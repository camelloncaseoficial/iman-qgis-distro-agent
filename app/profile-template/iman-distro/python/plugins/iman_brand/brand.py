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
VERSION = "0.3.0"   # DERIVADA do #define ProductVersion do .iss (D9). O build.ps1 recusa compilar se divergir.

# --- Paleta IMAN Terra (redesign D-IMAN-026 · ATIVA · INTERIM) ------------------
# PROMOVIDA na fatia #005 (feat/003-identidade-nofork): estes COLOR_* espelham,
# valor a valor, a tabela ATIVA de docs/design-system.md e spike/003 tokens.py
# (fonte única, BL-4). A arte de app/assets/ foi RE-DERIVADA p/ esta paleta (deixa
# de ser STALE). INTERIM: sobreponível pelo `IMAN.cdr`/manual se chegar (autoridade
# final). Constantes legadas (COLOR_PRIMARY/…/MINT/WARM) mantêm o NOME por compat e
# são re-apontadas ao PAPEL novo; `mint`/`warm` saíram da identidade (viram realce/earth).
COLOR_PRIMARY = "#1E7A4D"       # brand-2 — verde-marca / destaque / estado ativo
COLOR_PRIMARY_DEEP = "#103D29"  # brand — verde profundo; acento (diálogo Sobre/hover) + chrome NATIVA da futura Opção 2. (QSS suavizado 2026-07-15: não pinta mais a chrome do menubar/status/dock)
COLOR_INK = "#0E1A14"           # fundo escuro (bg dark do splash)
COLOR_ACCENT = "#2B8FD6"        # accent — azul dados/água / ação / links
COLOR_MINT = "#82D3A6"          # (legado) realce — mint saiu da identidade (D-IMAN-026)
COLOR_WARM = "#8A7A55"          # (legado) earth — warm/terracota saiu da identidade
COLOR_MOSS = "#6E9160"          # moss — apoio
COLOR_EARTH = "#8A7A55"         # earth — terroso (símbolos de limite)
COLOR_BG = "#EBEEE8"            # base neutra da área de trabalho
COLOR_PANEL = "#FFFFFF"         # painel / cartão
COLOR_PANEL_2 = "#F5F7F2"       # painel secundário / campo / linha alternada
COLOR_SURFACE = "#F5F7F2"       # (legado) = panel-2 (fundo de painel claro)
COLOR_BORDER = "#E2E5DE"        # borda
COLOR_BORDER_STRONG = "#D0D5C9" # borda forte / handle de scrollbar / campo da status bar
COLOR_BORDER_ACCENT = "#CFE0D2" # borda de realce suave (hover de botão de toolbar)
COLOR_TEXT = "#1A231D"          # texto principal sobre claro
COLOR_TEXT_MUTED = "#5E6A61"    # texto secundário
COLOR_TEXT_FAINT = "#95A093"    # texto terciário / meta
COLOR_HOVER = "#EFF2EC"         # hover neutro
COLOR_ACTIVE_BG = "#E4F0E8"     # fundo de item ativo
COLOR_ACTIVE_FG = "#155F3D"     # texto de item ativo
# Alias de compatibilidade: código legado usa COLOR_SECONDARY (= primary-deep/brand).
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
