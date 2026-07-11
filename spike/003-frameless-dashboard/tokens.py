# -*- coding: utf-8 -*-
"""IMAN Terra — tokens de marca do redesign (D-IMAN-026), escopo do SPIKE #003.

Fonte única (em código) da paleta NOVA do comp `docs/TerraWindow.dc.html` /
`docs/IMAN Terra.dc.html`, decidida em D-IMAN-026 (2026-07-11). Espelha a tabela
que este spike adiciona a `docs/design-system.md` (BL-4).

IMPORTANTE (limite do spike): a arte oficial em `app/assets/` (SVG master, símbolo,
`.ico`, wizard, splash) foi derivada da paleta VELHA (#00A85A…) e está **STALE** —
re-derivar é uma **fatia de branding própria**, NÃO entra neste spike. Aqui a paleta
nova só pinta as UIs das sondas (o "comp" re-materializado), re-tematizadas pra
REURB/cadastral do Ceará (não pro vertical ambiental que o comp desenha).

Este módulo vive em `spike/` de propósito: o spike PRODUZ EVIDÊNCIA, não shippa hack
no perfil de produção (BL-5). A promoção destes tokens para `brand.py`/QSS de produção
é a fatia "aplica nova paleta", recomendada no relatório conforme o veredito.
"""

# --- Tema claro (institucional) — do renderVals() do comp -----------------------
LIGHT = {
    "bg": "#EBEEE8",
    "panel": "#FFFFFF",
    "panel_2": "#F5F7F2",
    "border": "#E2E5DE",
    "border_strong": "#D0D5C9",
    "text": "#1A231D",
    "text_muted": "#5E6A61",
    "text_faint": "#95A093",
    "brand": "#103D29",          # verde profundo — chrome
    "brand_2": "#1E7A4D",        # verde institucional — marca / ativo
    "accent": "#2B8FD6",         # azul dados / água — acento
    "moss": "#6E9160",           # verde musgo — apoio
    "earth": "#8A7A55",          # terra — terroso (do style guide 1c)
    "hover": "#EFF2EC",
    "active_bg": "#E4F0E8",
    "active_fg": "#155F3D",
    "chrome": "#103D29",
    "chrome_fg": "#EAF3EC",
    "chrome_muted": "rgba(234,243,236,0.62)",
    "chrome_line": "rgba(255,255,255,0.13)",
}

# --- Tema escuro (trabalho prolongado / imagem de satélite) — do comp -----------
DARK = {
    "bg": "#0E1A14",
    "panel": "#15241D",
    "panel_2": "#111F19",
    "border": "#243830",
    "border_strong": "#2E463A",
    "text": "#E7EEE9",
    "text_muted": "#93A69B",
    "text_faint": "#617468",
    "brand": "#0B2C1E",
    "brand_2": "#3DA76B",
    "accent": "#4BA3DC",
    "moss": "#7FA271",
    "earth": "#8A7A55",
    "hover": "#1B2C23",
    "active_bg": "rgba(61,167,107,0.16)",
    "active_fg": "#82D3A6",
    "chrome": "#0A2016",
    "chrome_fg": "#E7EEE9",
    "chrome_muted": "rgba(231,238,233,0.55)",
    "chrome_line": "rgba(255,255,255,0.08)",
}


def palette(dark=False):
    return DARK if dark else LIGHT
