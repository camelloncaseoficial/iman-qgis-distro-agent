# -*- coding: utf-8 -*-
"""Tradutor SOBREPOSTO da marca (#041, D-IMAN-039 regra 3).

"QGIS" vira o nome do produto SO onde a palavra nomeia o aplicativo em uso: o nome
dos provedores nativos do Processamento, "Pagina do QGIS", os textos das Opcoes e
do gerenciador de complementos que falam do aplicativo ("requer reiniciar o QGIS").
Onde o valor exibido e a versao do QGIS, o texto diz "motor". Nao muda onde a
palavra nomeia o projeto QGIS, a comunidade, os creditos, a licenca ou o Sobre
(BL-1, BL-2).

COMO. Um `QTranslator` com SO as mensagens escolhidas, instalado DEPOIS do
`qgis_pt_BR.qm` que o QGIS carrega no arranque. O Qt consulta os tradutores do
mais recente para o mais antigo: o nosso responde pelas mensagens dele e deixa o
resto para o do QGIS. Nenhum arquivo da arvore do QGIS e tocado.

DE ONDE VEM O .qm. A fonte e `app/i18n/iman_terra_pt_BR.json` (o texto original do
QGIS ao lado do novo, e o nome do produto como token). O `installer/build.ps1`
gera o `.ts` com o nome lido de `brand.PRODUCT_NAME` e compila com `lrelease`; o
instalador entrega `{app}\\i18n\\iman_terra_pt_BR.qm`. Sem o arquivo (arvore de
desenvolvimento), o produto abre com os textos do QGIS e diz por que em `status()`.

O QUE ELE NAO ALCANCA. Texto que o QGIS ja montou antes de o plugin carregar (o
splash, menus montados no construtor da janela) so muda se o widget se retraduzir.
O alcance e MEDIDO mensagem a mensagem no laudo do #041; o que nao foi alcancado
fica registrado, e nao ganha outro caminho nesta fatia.
"""
import os

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import QCoreApplication, QTranslator

from . import brand

QM_BASENAME = "iman_terra"
I18N_DIRNAME = "i18n"

# O QTranslator precisa viver enquanto o processo viver: se o objeto Python for
# coletado, o Qt perde o tradutor em silencio.
_translator = None
_status = {"installed": False, "qm": None, "locale": None, "reason": "nao tentado"}


def _locale():
    try:
        loc = QgsApplication.locale()
    except Exception:
        loc = ""
    return loc or "pt_BR"


def _candidate_dirs():
    return [os.path.join(raiz, I18N_DIRNAME) for raiz in brand._raizes_do_app()]


def install():
    """Instala o tradutor sobreposto. Idempotente; nunca levanta."""
    global _translator
    if _translator is not None:
        return _status
    loc = _locale()
    _status["locale"] = loc
    for folder in _candidate_dirs():
        if not os.path.isdir(folder):
            continue
        tr = QTranslator()
        # load(nome, pasta) tenta iman_terra_pt_BR.qm, depois iman_terra_pt.qm.
        if tr.load("%s_%s" % (QM_BASENAME, loc), folder) and not tr.isEmpty():
            app = QCoreApplication.instance()
            if app is None or not app.installTranslator(tr):
                _status["reason"] = "installTranslator recusou"
                return _status
            _translator = tr
            _status.update(installed=True, qm=tr.filePath() if hasattr(tr, "filePath") else folder,
                           reason="instalado")
            return _status
    _status["reason"] = "nenhum %s_%s.qm em %s" % (QM_BASENAME, loc, ", ".join(_candidate_dirs()))
    return _status


def status():
    """Estado do tradutor, para o aceite e para o laudo."""
    return dict(_status)
