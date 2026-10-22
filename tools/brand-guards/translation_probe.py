# -*- coding: utf-8 -*-
"""Sonda da GUARDA DO TRADUTOR SOBREPOSTO (#041). Roda no Python da arvore do QGIS,
chamada por tools/test-brand-translation.ps1:

    python-qgis-ltr.bat translation_probe.py <nosso.qm> <qgis_pt_BR.qm> <fonte.json> <produto> <saida.json>

Mede, para cada mensagem da fonte:
  in_qgis    o texto-fonte EXISTE no qgis_pt_BR.qm da arvore (o mesmo contexto e o
             mesmo texto que o QGIS procura). Fonte com um caractere trocado
             geraria um .qm valido que nunca seria consultado;
  ours       o que o NOSSO .qm devolve sozinho (formato do .qm, RISCOS R7);
  effective  o que QCoreApplication.translate devolve com os dois tradutores
             instalados na ordem do produto: primeiro o do QGIS, depois o nosso
             (precedencia, U-05 no nivel da API).
E um controle: mensagens que a fonte NAO escolheu continuam com o texto do QGIS
(o tradutor sobreposto nao vaza para o Sobre, os creditos e a doacao).
"""
import io
import json
import sys

from qgis.PyQt.QtCore import QCoreApplication, QTranslator

# Mensagens que a regra 3 do D-IMAN-039 manda NAO trocar. Precisam sair do
# tradutor exatamente como o QGIS as traduz.
CONTROLS = [
    ("MainWindow", "Donate to QGIS"),
    ("MainWindow", "QGIS Sustaining Members"),
    ("QgsAbout", "About QGIS"),
    ("QgsPluginInstaller", "QGIS Official Plugin Repository"),
    ("QgsStatusBarCoordinatesWidget", "QGIS Contributors"),
]


def _tr(translator, ctx, src):
    """QTranslator.translate do PyQt5 recebe `const char*` e codifica str em ASCII:
    texto-fonte com reticencias tipograficas estoura. O Qt 5 espera UTF-8 ali,
    entao o texto vai como bytes UTF-8."""
    return translator.translate(ctx.encode("utf-8"), src.encode("utf-8"))


def main():
    ours_qm, qgis_qm, source, product, out = sys.argv[1:6]
    app = QCoreApplication([])
    with io.open(source, encoding="utf-8") as fh:
        doc = json.load(fh)
    token = doc["product_token"]

    qgis_tr = QTranslator()
    ours_tr = QTranslator()
    result = {"qgis_qm_loaded": qgis_tr.load(qgis_qm), "ours_qm_loaded": ours_tr.load(ours_qm),
              "messages": [], "controls": []}
    # A ordem do produto: o QGIS instala o dele no arranque; o plugin, depois.
    app.installTranslator(qgis_tr)
    app.installTranslator(ours_tr)

    for m in doc["messages"]:
        ctx, src = m["context"], m["source"]
        expected = m["iman_terra"].replace(token, product)
        result["messages"].append({
            "context": ctx,
            "source": src,
            "expected": expected,
            "in_qgis": bool(_tr(qgis_tr, ctx, src)),
            "ours": _tr(ours_tr, ctx, src),
            "effective": QCoreApplication.translate(ctx, src),
        })
    for ctx, src in CONTROLS:
        result["controls"].append({
            "context": ctx,
            "source": src,
            "qgis": _tr(qgis_tr, ctx, src),
            "ours": _tr(ours_tr, ctx, src),
            "effective": QCoreApplication.translate(ctx, src),
        })
    with io.open(out, "w", encoding="utf-8") as fh:
        json.dump(result, fh, ensure_ascii=False, indent=2)


main()
