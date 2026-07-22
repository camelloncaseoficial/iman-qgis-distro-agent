# -*- coding: utf-8 -*-
"""Regenera TODOS os derivados de ícone a partir do master `iman-symbol.png`.

Determinístico, só Pillow. Rodar com o python do sistema:

    python app/assets/regenerate-icons.py

Saídas (ver a tabela de derivados em app/assets/README.md):
  - icon-iman-terra.png                       512x512, transparente
  - icon-iman-terra.ico                       16/24/32/48/64/128/256, transparente
  - ../profile-template/.../resources/icon.png 256x256, transparente

RESPIRO = 0 (e por quê): a spec anterior mandava "quadrado + respiro 10%" porque o
master antigo era um recorte JUSTO, sem margem nenhuma — sem o respiro o ícone
encostava nas bordas. O master oficial já vem quadrado e com margem embutida (o
contorno branco da arte funciona como respiro), então aplicar mais 10% empilharia
margem sobre margem e comeria nitidez justo em 16x16, que é o tamanho crítico do
atalho e da barra de tarefas. Verificado lado a lado antes de fixar.

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


def _quadrado(sym):
    """Garante tela quadrada, centralizando sem distorcer o desenho."""
    if sym.width == sym.height:
        return sym
    lado = max(sym.width, sym.height)
    tela = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    tela.paste(sym, ((lado - sym.width) // 2, (lado - sym.height) // 2), sym)
    return tela


def _escala(sym, lado):
    return sym.resize((lado, lado), Image.LANCZOS)


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
