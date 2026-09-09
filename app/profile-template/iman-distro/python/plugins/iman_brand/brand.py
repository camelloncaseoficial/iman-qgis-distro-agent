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


# --- Identidade do BUILD (DB-24) ----------------------------------------------
# POR QUE ISTO EXISTE. O proprio BUILD_INFO.txt diz que a identidade de um
# artefato e o par (ProductVersion, Commit) - o SHA-256 muda com o mtime que o
# Inno grava e o git nao preserva. Mas o Commit NAO chegava ao usuario: o
# produto instalado declarava so VERSION = "0.3.0", e o artefato de branch e o
# canonico eram ambos 0.3.0 e INDISTINGUIVEIS de dentro do produto. Toda a
# procedencia que o D-IMAN-032 construiu morria na fronteira do instalador.
#
# Agora o instalador entrega {app}\BUILD_ID.txt, gerado pelo build.ps1, e o
# produto le DALI. O valor nunca e digitado aqui: se o arquivo nao existir
# (arvore de desenvolvimento, harness rodando do repo), a identidade e
# DESCONHECIDA e o produto diz isso - nao inventa um commit.
#
# O QUE NAO ESTA NO ARQUIVO, e por que: o SHA-256 do proprio .exe. Ele so
# existe DEPOIS de compilar, e o arquivo entra NA compilacao - embarca-lo
# exigiria um segundo passe sobre o instalador ja pronto. O SHA do artefato
# continua vivendo so no BUILD_INFO.txt do repo, que e onde se confere o
# arquivo que chegou na VM.
BUILD_ID_FILENAME = "BUILD_ID.txt"

_build_id_cache = None


def _raizes_do_app():
    """Onde {app} pode estar, na ordem em que se procura."""
    import os as _os
    raizes = []
    home = _os.environ.get("IMAN_TERRA_HOME")
    if home:
        raizes.append(home)
    # o plugin vive em <perfil>\python\plugins\iman_brand; o {app} nao esta
    # acima dele (o perfil mora em %APPDATA%), entao so subimos para cobrir o
    # caso de o profile-template ser lido de dentro do proprio {app}.
    aqui = _os.path.dirname(_os.path.abspath(__file__))
    for _ in range(6):
        aqui = _os.path.dirname(aqui)
        if aqui:
            raizes.append(aqui)
    return raizes


def build_id():
    """Identidade do build EM QUE ESTE PRODUTO FOI ENTREGUE.

    Devolve um dict com o que o build.ps1 gravou (chave=valor), ou {} quando o
    arquivo nao existe. Nunca levanta: um produto que nao consegue dizer de que
    build e ainda tem de abrir.
    """
    global _build_id_cache
    if _build_id_cache is not None:
        return _build_id_cache
    import os as _os
    dados = {}
    for raiz in _raizes_do_app():
        caminho = _os.path.join(raiz, BUILD_ID_FILENAME)
        if not _os.path.isfile(caminho):
            continue
        try:
            with open(caminho, "r", encoding="utf-8", errors="replace") as fh:
                for linha in fh:
                    linha = linha.strip()
                    if not linha or linha.startswith("#") or "=" not in linha:
                        continue
                    k, v = linha.split("=", 1)
                    dados[k.strip()] = v.strip()
            dados["_arquivo"] = caminho
            break
        except Exception:
            continue
    _build_id_cache = dados
    return dados


def build_commit_curto():
    """O commit curto do build, ou None se o produto nao sabe."""
    c = build_id().get("commit_curto") or ""
    return c or None


def versao_exibida():
    """A string de versao que o usuario ve, no unico lugar em que ela se monta.

    Com identidade de build:  "0.3.0 · 374c0f5"
    Sem identidade:           "0.3.0"

    O separador nao entra na versao em si: o A09 procura o padrao
    <maior>.<menor>.<correcao> e continua achando 0.3.0 nos dois casos.
    """
    c = build_commit_curto()
    return "%s · %s" % (VERSION, c) if c else VERSION

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
