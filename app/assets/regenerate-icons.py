# -*- coding: utf-8 -*-
"""Regenera TODOS os derivados de ícone a partir do master `iman-symbol.png`.

Determinístico, só Pillow. Rodar com o python do sistema:

    python app/assets/regenerate-icons.py

Saídas (ver a tabela de derivados em app/assets/README.md):
  - icon-iman-terra.png                       512x512, transparente
  - icon-iman-terra.ico                       16/24/32/48/64/128/256, transparente
  - ../profile-template/.../resources/icon.png 256x256, transparente

RESPIRO = 0 — o que isso PRODUZ, medido (alpha > 128):

    master oficial ............ margens L/T/R/B = 0,2% / 0,2% / 0,2% / 0,0%
                                (13 pixels OPACOS na ultima linha)
    derivado .ico anterior .... margens L/T/R/B = 9,2% / 17,0% / 9,2% / 17,0%

Ou seja: a arte oficial ENCOSTA na borda inferior da tela. O contorno branco dela e
TINTA OPACA, nao margem de tela - le como respiro sobre fundo claro e SOME sobre
fundo escuro. Com RESPIRO = 0 o icone fica edge-to-edge: renderiza MAIOR que os
vizinhos na barra de tarefas e no Menu Iniciar, e com a base TANGENTE a borda.

Isso e escolha deliberada, nao propriedade da arte: em 16x16 o desenho maior leu
melhor do que a alternativa com 8% de respiro. Mas a comparacao foi feita em PNG
ampliado, nao na barra de tarefas real - entao a decisao e EMPIRICA e PROVISORIA,
com gate no 16x16 real durante o BL-7. Se ficar desproporcional ao lado dos outros
icones, subir RESPIRO para ~8% e regerar; e um numero, nao uma refatoracao.

Este script NÃO re-colore o símbolo (STOP-AND-FLAG do IMAN.cdr segue de pé) e não
mexe em splash, wizard ou tema.
"""
import os

from PIL import Image

A = os.path.dirname(os.path.abspath(__file__))
MASTER = os.path.join(A, "iman-symbol.png")

ICO_SIZES = [16, 24, 32, 48, 64, 128, 256]
PLUGIN_ICON = os.path.join(A, "..", "profile-template", "iman-distro", "python",
                           "plugins", "iman_brand", "resources", "icon.png")

# Margem transparente em CADA lado, como fração do lado do ícone.
# 0.0 = edge-to-edge (estado atual, provisório — ver a docstring e o gate do BL-7).
# 0.08 = a alternativa comparada em 16x16. Mexer aqui e rodar o script de novo é
# a correção inteira, caso o gate na barra de tarefas real reprove o edge-to-edge.
RESPIRO = 0.0


def _quadrado(sym):
    """Garante tela quadrada, centralizando sem distorcer o desenho."""
    if sym.width == sym.height:
        return sym
    lado = max(sym.width, sym.height)
    tela = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    tela.paste(sym, ((lado - sym.width) // 2, (lado - sym.height) // 2), sym)
    return tela


def _escala(sym, lado):
    """Reamostra para `lado`x`lado`, reservando RESPIRO de margem em cada borda."""
    dentro = max(1, int(round(lado * (1 - 2 * RESPIRO))))
    s = sym.resize((dentro, dentro), Image.LANCZOS)
    if dentro == lado:
        return s
    tela = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    off = (lado - dentro) // 2
    tela.paste(s, (off, off), s)
    return tela


def main():
    sym = _quadrado(Image.open(MASTER).convert("RGBA"))
    print("master: %s  %sx%s" % (os.path.basename(MASTER), sym.width, sym.height))

    png512 = os.path.join(A, "icon-iman-terra.png")
    _escala(sym, 512).save(png512)
    print("  ->", os.path.basename(png512), "512x512")

    # Cada tamanho é reamostrado explicitamente com LANCZOS e embutido no .ico.
    # Deixar o Pillow reamostrar sozinho a partir de UMA imagem entrega 16x16
    # visivelmente pior.
    quadros = [_escala(sym, s) for s in ICO_SIZES]
    ico = os.path.join(A, "icon-iman-terra.ico")
    quadros[-1].save(ico, format="ICO",
                     sizes=[(s, s) for s in ICO_SIZES],
                     append_images=quadros[:-1])
    print("  ->", os.path.basename(ico), "/".join(str(s) for s in ICO_SIZES))

    destino = os.path.normpath(PLUGIN_ICON)
    _escala(sym, 256).save(destino)
    print("  -> resources/icon.png 256x256")

    print("OK - simbolo NAO re-colorido; splash/tema/launcher intocados.")


if __name__ == "__main__":
    main()
