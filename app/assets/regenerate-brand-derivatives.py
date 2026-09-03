# -*- coding: utf-8 -*-
"""Regenera os derivados DEPENDENTES DE PALETA após a re-derivação INTERIM (#005).

Determinístico, PIL. NÃO re-colore o símbolo (`iman-symbol.png` = mark, sem master
vetorial — STOP-AND-FLAG até o IMAN.cdr); só troca fundos/chrome p/ a paleta nova e
re-deriva o banner do dock a partir do novo splash. O `.ico` e o `icon-iman-terra.png`
(símbolo transparente) NÃO mudam.

Rodar com o python do sistema:  python app/assets/regenerate-brand-derivatives.py
"""
import os
from PIL import Image

A = os.path.dirname(os.path.abspath(__file__))
SYM = Image.open(os.path.join(A, "iman-symbol.png")).convert("RGBA")

# Paleta nova (D-IMAN-026): brand=#103D29, neutro claro=#EBEEE8
BRAND = (0x10, 0x3D, 0x29)
LIGHT = (0xEB, 0xEE, 0xE8)


def _fit(sym, box_w, box_h, frac):
    w = int(box_w * frac)
    h = int(w * sym.height / sym.width)
    if h > box_h * frac:
        h = int(box_h * frac)
        w = int(h * sym.width / sym.height)
    return sym.resize((w, h), Image.LANCZOS)


def wizard(path, size, bg, frac, vpos):
    """`bg=None` => fundo TRANSPARENTE, com alfa real (D-IMAN-028/DB-21).

    POR QUE ALFA E NAO UMA COR: a pagina do wizard do Inno e `clWindow`, cor do
    tema do Windows - medida em 2026-09-03 num build real desta bancada, veio
    `#FFFFFF`, que NAO e token da paleta oficial. Cravar qualquer cor de fundo
    no PNG produz uma chapa visivel assim que a pagina nao for exatamente essa
    cor (tema escuro, alto contraste, outra versao do Inno). Com alfa real +
    `WizardImageAlphaFormat` no `.iss`, o simbolo assenta sobre a cor que a
    pagina tiver. Ver `docs/verify/015-db21-wizard/`.
    """
    if bg is None:
        canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    else:
        canvas = Image.new("RGB", size, bg)
    s = _fit(SYM, size[0], size[1], frac)
    x = (size[0] - s.width) // 2
    y = int(size[1] * vpos - s.height / 2)
    canvas.paste(s, (x, y), s)
    canvas.save(path)
    print("wizard:", os.path.basename(path), size, "bg", bg if bg else "TRANSPARENTE (RGBA)")


def plugin_banner():
    # banner do dock = novo splash reduzido p/ 760x365
    src = Image.open(os.path.join(A, "splash-iman-terra.png")).convert("RGBA")
    dst = src.resize((760, 365), Image.LANCZOS)
    out = os.path.join(A, "..", "profile-template", "iman-distro", "python",
                       "plugins", "iman_brand", "resources", "splash.png")
    dst.save(out)
    print("plugin banner:", os.path.relpath(out, A), dst.size)


if __name__ == "__main__":
    wizard(os.path.join(A, "wizard-large.png"), (410, 797), BRAND, 0.72, 0.34)
    # wizard-small: fundo TRANSPARENTE (DB-21). O `LIGHT` #EBEEE8 que estava
    # aqui e o que produzia a chapa cinza no canto do wizard.
    wizard(os.path.join(A, "wizard-small.png"), (138, 140), None, 0.74, 0.5)
    plugin_banner()
    print("OK — mark preservado; fundos/banner na paleta nova (INTERIM).")
