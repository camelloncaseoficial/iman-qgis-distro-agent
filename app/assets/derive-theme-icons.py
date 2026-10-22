# -*- coding: utf-8 -*-
"""Deriva o icone do provedor do Processamento a partir do MASTER VETORIAL (#041).

    python app/assets/derive-theme-icons.py           # escreve
    python app/assets/derive-theme-icons.py --check   # so confere; exit 1 se divergir

O QUE ELE FAZ. O `splash-iman-terra.svg` (export do Corel de `IMAN Terra.cdr`) traz
o simbolo IMAN (folha + globo) em VETOR: um grupo de paths com as cores do emblema
(`#00A85A`, `#00AFF0`, o degrade `#059452 -> #ACC658` e o contorno branco). Este
script recorta ESSE grupo, sem redesenhar nada, e o grava como

    profile-template/iman-distro/themes/IMAN Terra/icons/providerQgis.svg

que e o nome que o QGIS pede ao tema para o provedor nativo, os grupos de topo da
caixa de Processamento, o modelador e Opcoes > Processamento > Provedores
(forense do #041: S01, S02, S11).

POR QUE DO SVG E NAO DO `iman-symbol.png`. O PNG e raster 512x512; embuti-lo num SVG
so valeria se fosse legivel a 16 e 24 px, medido. O vetor existe no master, entao
nao ha o que embutir. Legibilidade a 16 e 24 px: medida em
`docs/verify/041-tema-no-arranque/` e guardada por `tools/test-theme-icons.ps1`.

A ARMADILHA DO QtSvg (app/assets/README.md) NAO SE APLICA AQUI: ela e sobre os
GLIFOS de SVG font do master. O recorte leva so `<path>` e um `<linearGradient>`,
sem texto nenhum.

O ENQUADRAMENTO (`VIEWBOX`) e MEDIDO, nao calculado aqui: a caixa da tinta do grupo,
renderizada pelo QSvgRenderer da arvore do QGIS em 2026-10-22, foi
x 2859,8..6269,6 e y 3740,0..7230,0 (unidades do master). O quadrado abaixo e
centrado nela, com lado 3560 (a maior dimensao, 3490, mais ~1% de respiro de
cada lado). Sem stdlib que rasterize SVG, recalcular a caixa aqui exigiria
reimplementar a geometria dos paths; o numero fica declarado e o teste renderiza
o resultado.

Nao re-colore nada (a arte e arbitrada, ver README) e nao mexe em outro arquivo.
"""
import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MASTER = os.path.join(HERE, "splash-iman-terra.svg")
THEME_ICONS = os.path.join(HERE, "..", "profile-template", "iman-distro", "themes",
                           "IMAN Terra", "icons")
OUTPUT = os.path.join(THEME_ICONS, "providerQgis.svg")

# Centro e lado do enquadramento, em unidades do master (ver a docstring).
CENTER_X = (2859.82 + 6269.61) / 2
CENTER_Y = (3740.0 + 7230.0) / 2
SIDE = 3560.0
VIEWBOX = "%.2f %.2f %.0f %.0f" % (CENTER_X - SIDE / 2, CENTER_Y - SIDE / 2, SIDE, SIDE)

# A classe que so o simbolo usa: o degrade da folha. O grupo do simbolo e o
# grupo MAIS INTERNO que contem um path com ela.
SYMBOL_MARKER_CLASS = "fil28"


def _css_fills(svg):
    """classe -> valor de fill, lido do <style> do proprio master."""
    style = re.search(r"<style[^>]*>(.*?)</style>", svg, re.S)
    if not style:
        raise SystemExit("master sem <style>: nao da para resolver as cores das classes")
    fills = {}
    for name, body in re.findall(r"\.(fil\d+)\s*\{([^}]*)\}", style.group(1)):
        m = re.search(r"fill\s*:\s*([^;]+)", body)
        if m:
            fills[name] = m.group(1).strip()
    return fills


def _symbol_group(svg):
    """O texto do <g> mais interno que contem o marcador do simbolo."""
    body_start = svg.find("</defs>")
    if body_start < 0:
        raise SystemExit("master sem </defs>")
    marker = svg.find('class="%s"' % SYMBOL_MARKER_CLASS, body_start)
    if marker < 0:
        raise SystemExit("o marcador do simbolo (%s) nao esta no master" % SYMBOL_MARKER_CLASS)
    stack = []
    best = None
    for m in re.finditer(r"<g\b[^>]*>|</g>", svg[body_start:]):
        pos = body_start + m.start()
        if m.group(0).startswith("</"):
            opened = stack.pop()
            if opened < marker < pos:
                return svg[opened:pos + len("</g>")]
        else:
            stack.append(pos)
    raise SystemExit("nao achei o grupo do simbolo")


def _gradient(svg, gradient_id):
    m = re.search(r'<linearGradient id="%s".*?</linearGradient>' % re.escape(gradient_id), svg, re.S)
    if not m:
        raise SystemExit("degrade %s nao encontrado no master" % gradient_id)
    # Normaliza as paradas para atributos: o QtSvg le os dois, mas atributo nao
    # depende do parser de CSS inline.
    text = m.group(0)
    text = re.sub(r'style="stop-opacity:1; stop-color:(#[0-9A-Fa-f]{6})"', r'stop-color="\1"', text)
    return re.sub(r"\s+", " ", text)


def derive():
    with io.open(MASTER, "r", encoding="utf-8") as fh:
        svg = fh.read()
    fills = _css_fills(svg)
    group = _symbol_group(svg)
    paths = re.findall(r'<path class="(fil\d+)" d="([^"]+)"/>', group)
    visible = [(cls, d) for cls, d in paths if fills.get(cls, "none") != "none"]
    if not visible:
        raise SystemExit("o grupo do simbolo nao tem path visivel")
    defs = []
    for cls, _ in visible:
        m = re.match(r"url\(#([^)]+)\)", fills[cls])
        if m and m.group(1) not in [d[0] for d in defs]:
            defs.append((m.group(1), _gradient(svg, m.group(1))))
    out = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        "<!-- IMAN Terra: simbolo IMAN (folha + globo) para o tema de UI do produto.",
        "     GERADO por app/assets/derive-theme-icons.py a partir de",
        "     app/assets/splash-iman-terra.svg. Nao editar a mao: regerar. -->",
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="%s">' % VIEWBOX,
    ]
    if defs:
        out.append("<defs>%s</defs>" % "".join(d[1] for d in defs))
    for cls, d in visible:
        out.append('<path fill="%s" d="%s"/>' % (fills[cls], d))
    out.append("</svg>")
    return "\n".join(out) + "\n"


def main(argv):
    text = derive()
    if "--check" in argv:
        try:
            with io.open(OUTPUT, "r", encoding="utf-8", newline="") as fh:
                current = fh.read()
        except OSError:
            print("DIVERGE: %s nao existe" % OUTPUT)
            return 1
        # Fim de linha nao e conteudo: com core.autocrlf o checkout pode trazer
        # CRLF, e isso nao faz do arquivo outra derivacao.
        if current.replace("\r\n", "\n") != text:
            print("DIVERGE: %s nao e a derivacao do master; rode o script sem --check" % OUTPUT)
            return 1
        print("OK: providerQgis.svg e a derivacao do master")
        return 0
    os.makedirs(THEME_ICONS, exist_ok=True)
    with io.open(OUTPUT, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    print("escrito: %s" % os.path.normpath(OUTPUT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
