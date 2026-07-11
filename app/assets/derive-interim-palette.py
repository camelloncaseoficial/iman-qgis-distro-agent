# -*- coding: utf-8 -*-
"""Re-derivação INTERIM da arte do splash — paleta D-IMAN-026 + copy REURB/Ceará.

Determinístico (find-replace por PAPEL, mapa do arquiteto — INTERIM, sobreponível
pelo `IMAN.cdr`). NÃO é trabalho de designer: transforma o master SVG-texto
`splash-iman-terra.svg` (hexes editáveis + copy em <text>). Reproduzível: rode com
o python do sistema; depois rasterize com QtSvg (ver app/assets/README.md).

Fatia #005 (feat/003-identidade-nofork). PRESERVA os créditos do QGIS (BL-1/BL-2):
"BASEADA EM QGIS", "POWERED BY QGIS" e o wordmark "QGIS" (cor de crédito mantida).
O símbolo (iman-symbol.png) NÃO é re-colorido (raster sem master vetorial —
STOP-AND-FLAG até o IMAN.cdr).
"""
import os
import re

SVG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "splash-iman-terra.svg")

# --- 1a) mapa de paleta OLD->NEW por PAPEL (hex, minúsculas como no SVG) --------
HEX = {
    "#0d5138": "#103d29",  # chrome / brand (topo do gradiente)
    "#083629": "#0f3021",  # bg gradiente (mid) — interpolado
    "#05241c": "#0e2219",  # bg gradiente (mid) — interpolado
    "#041c16": "#0e1a14",  # fundo escuro (bg dark)
    "#a8501f": "#6e5e3f",  # banda "versão institucional" (par escuro) -> earth escuro
    "#c56a2f": "#8a7a55",  # warm REMOVIDO -> earth
    "#00a85a": "#1e7a4d",  # verde-marca / destaque -> brand-2
    "#2ca8e0": "#2b8fd6",  # azul -> accent
    "#5fe0a0": "#82d3a6",  # mint REMOVIDO -> realce (dark active-fg)
    "#7fe3ac": "#82d3a6",  # acento "Terra" (mint) -> realce
    "#f2f8f3": "#ebeee8",  # surface -> neutro claro (wordmark IMAN)
    "#cfe6d8": "#e4f0e8",  # tint -> active-bg (tagline)
    "#fbeee4": "#f5f1e8",  # straggler texto da banda -> claro legível
    # #5aa832 (wordmark "QGIS") = crédito -> MANTIDO (não recolorir; BL-1)
}
# rgba por PAPEL (mantêm alpha p/ legibilidade; nunca apagam crédito/texto)
RGBA = {
    "rgba(160,224,192,": "rgba(130,211,166,",  # anéis decorativos (mint) -> realce
    "rgba(206,124,72,":  "rgba(138,122,85,",   # anéis (warm) -> earth
    "rgba(44,168,224,":  "rgba(43,143,214,",   # hidrografia (accent)
    "rgba(226,240,232,": "rgba(235,238,232,",  # grid/coord/crédito/status (neutro claro)
    "rgba(3,20,15,":     "rgba(14,26,20,",     # fundo da status bar (dark)
}

# --- 1b) copy REURB/Ceará (fonte única de posicionamento: spike/003 dashboard) --
COPY = {
    # remove a coord FALSA de Pernambuco (não inventar precisão cadastral); Ceará + CRS
    "24M   40°30&#39;W  |  8°10&#39;S  |  SIRGAS 2000":
        "CEARÁ  ·  SIRGAS 2000  ·  UTM 24S",
    # tagline: ambiental -> REURB/cadastral
    "MONITORAMENTO AMBIENTAL E INTELIGÊNCIA TERRITORIAL":
        "REGULARIZAÇÃO FUNDIÁRIA · CADASTRO TERRITORIAL",
}


def main():
    with open(SVG, "r", encoding="utf-8") as f:
        s = f.read()
    counts = {}
    for old, new in {**HEX, **RGBA}.items():
        s, n = re.subn(re.escape(old), new, s)
        counts[old] = n
    for old, new in COPY.items():
        if old not in s:
            raise SystemExit("COPY não encontrada (já derivado?): %r" % old[:30])
        s = s.replace(old, new)
        counts[old[:24] + "…"] = 1
    with open(SVG, "w", encoding="utf-8") as f:
        f.write(s)
    for k, v in counts.items():
        print("%3d  %s" % (v, k))
    # guarda BL-1: créditos preservados
    for must in ("BASEADA EM QGIS", "POWERED BY", "QGIS", "#5aa832"):
        assert must in s, "CRÉDITO REMOVIDO: %s" % must
    print("OK — créditos do QGIS preservados (BL-1/BL-2).")


if __name__ == "__main__":
    main()
