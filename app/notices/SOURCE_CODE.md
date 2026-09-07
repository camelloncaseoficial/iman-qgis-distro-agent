# Código-fonte — IMAN Terra

O IMAN Terra **redistribui** o QGIS e todo o seu ecossistema — **159 componentes de terceiros** ao
todo (ver `THIRD_PARTY_NOTICES.md`). Entre eles há **20 sob copyleft forte** (GPL/AGPL) e **14 sob
LGPL**.

Para esses componentes, quem recebeu o binário **do Instituto IMAN** tem direito a obter o
**código-fonte correspondente do Instituto IMAN**. Apontar para `qgis.org` é cortesia, não
cumprimento: a QGIS.ORG não assumiu obrigação nenhuma perante um usuário nosso.

---

## 1. Componentes próprios do Instituto IMAN

Plugin de marca `iman_brand`, startup script, launcher, scripts de build e configuração de perfil:
**GPL-3.0-or-later** (ver `LICENSE`).

O código viaja **legível dentro do pacote instalado** (Python, `.bat`, `.ps1`, configuração), na
pasta `app\` da instalação. O repositório de desenvolvimento é mantido pelo Instituto IMAN.

---

## 2. Componentes de terceiros sob copyleft

### 2.1 O que identifica exatamente o que você recebeu

Todo instalador do IMAN Terra é acompanhado de `BUILD_INFO.txt`, que registra:

```
ProductVersion   : a versão do IMAN Terra
Commit           : o commit exato que gerou o instalador
QGIS embarcado   : a versão do QGIS
Payload SHA-256  : o hash do instalador oficial do QGIS de onde a árvore foi extraída
Origem oficial   : a URL de onde esse payload veio
```

**É esse par (`ProductVersion`, `Payload SHA-256`) que identifica o conjunto de fontes
correspondentes.** Ao solicitar o fonte, informe esses dois valores.

### 2.2 O fonte correspondente NÃO é o pacote `-src` do OSGeo4W

Registro de um achado que muda como isso tem de ser feito, para que ninguém o refaça errado:

O repositório do OSGeo4W publica, para cada pacote, um `<pacote>-<versão>-src.tar.bz2`. **Esses
arquivos não são o código-fonte** — são a *receita de build*. Medido em 2026-09-07 sobre os 155
pacotes correspondentes à nossa árvore:

- somados, os 155 dão **271.074 bytes (0,26 MB)**; **todos** têm menos de 100 KB;
- `qgis-ltr-3.44.13-1-src.tar.bz2` tem **7.723 bytes** e contém apenas `osgeo4w/package.sh` e um
  punhado de `.bat` — **nenhuma linha de código do QGIS**.

O fonte correspondente é o **tarball upstream** que o `package.sh` de cada pacote baixa e compila.
Esses URLs estão registrados, pacote a pacote, na coluna `url_da_fonte` de
`docs/licencas/inventario.csv`.

*(Nota útil: o arquivo `osgeo4w/patch` da receita do QGIS tem **0 byte** — o OSGeo4W não aplica patch
ao QGIS. O fonte correspondente é o tarball upstream, sem modificação nossa nem do OSGeo4W.)*

### 2.3 Como pedir o fonte — enquanto o espelho não está no ar

> ⚠ **Estado atual:** o mecanismo de espelho descrito em §3 é uma **proposta**, ainda pendente de
> decisão de hospedagem e custo pelo Instituto IMAN. **Até que esteja no ar**, o compromisso vale por
> solicitação:

**Escreva ao Instituto IMAN informando `ProductVersion` e `Payload SHA-256` do seu `BUILD_INFO.txt`,
e indique de quais componentes deseja o fonte.** O Instituto IMAN fornecerá o código-fonte
correspondente em mídia física ou por download, sem custo além do custo de distribuição.

Este compromisso alcança os 34 componentes de copyleft (forte e fraco) listados em
`THIRD_PARTY_NOTICES.md` §4.

---

## 3. Espelho de fonte — mecanismo proposto

**Esta seção é proposta técnica com números. A escolha e o custo são decisão do sponsor.**

### 3.1 O tamanho do problema, medido

Tamanho dos tarballs de fonte upstream dos principais componentes copyleft
(medido por `Content-Length` em 2026-09-07):

| Componente | Fonte upstream | Tamanho |
|---|---|---:|
| Qt 5.15.13 (`qt-everywhere-opensource-src`) | download.qt.io | **630,17 MB** |
| QGIS 3.44.13 | qgis.org | **183,05 MB** |
| Ghostscript / ghostpdl 10.07.1 | GitHub Artifex | **95,33 MB** |
| GRASS GIS 8.5.0 | grass.osgeo.org | **64,75 MB** |
| cairo 1.18.4 | cairographics.org | 31,07 MB |
| wxWidgets 3.2.9 | GitHub wxWidgets | 26,10 MB |
| SAGA 9.12.4 | SourceForge | 13,15 MB |
| GNU GSL 2.7.1 | ftp.gnu.org | 7,16 MB |
| GEOS 3.14.1 | download.osgeo.org | 6,69 MB |
| libspatialite 5.1.0 | gaia-gis.it | 6,22 MB |
| GNU libiconv 1.17 | ftp.gnu.org | 5,16 MB |
| poppler 26.06.0 | poppler.freedesktop.org | 1,95 MB |
| QCA 2.3.8 | download.kde.org | 0,73 MB |
| **Subtotal medido** | | **≈ 1.071 MB** |
| Demais copyleft (exiv2, GPSBabel, lz4, librttopo, QScintilla, PyQt5, FreeXL, psycopg, CA bundle) | tarballs do GitHub/PyPI, poucos MB cada | ≈ 50 MB (não medido) |
| **Total estimado por release** | | **≈ 1,1 GB** |

**O Qt sozinho é 57 % do volume.** Qualquer decisão de custo passa por ele.

### 3.2 Opções

| # | Mecanismo | Como funciona | Custo | Avaliação |
|---|---|---|---|---|
| **A** | **Asset de GitHub Release** | um `.zip`/`.tar` com os fontes correspondentes, anexado à mesma release que publica o `.exe`, na mesma tag | **R$ 0** — a documentação do GitHub declara **limite de 2 GiB por arquivo** e **"no limit on the total size of a release, nor bandwidth usage"** ([about-releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases), consultado 2026-09-07) | **Recomendado.** ≈1,1 GB cabe. Fica amarrado à release, que já é identificada pelo `BUILD_INFO`. Se estourar 2 GiB, dividir em assets por componente |
| **B** | Repositório espelho | um repo `iman-terra-sources` com um branch/tag por release | R$ 0, mas o Git armazena tarballs binários muito mal; o repo cresce sem limite a cada release | Não recomendado para binários |
| **C** | Bucket S3/R2 + link | pasta por `ProductVersion` | ≈ US$ 0,015/GB/mês de armazenamento; **banda** é o risco (R2 tem egress zero, S3 não) | Viável; introduz conta e fatura a administrar |
| **D** | Oferta escrita + mídia sob demanda | o que a §2.3 já faz hoje | ≈ R$ 0 até alguém pedir | Aceitável como ponte, frágil como regime permanente |

**Recomendação técnica: opção A**, com D permanecendo como garantia. A automação seria: ao publicar
uma release, um passo do build baixa os tarballs upstream listados em `inventario.csv` (coluna
`url_da_fonte`, filtrando por `categoria` copyleft), confere-os e os anexa como asset — e grava no
`BUILD_INFO.txt` o link do asset e o SHA-256 de cada fonte.

**Números que faltam para decidir:** quantas releases por ano o produto terá, e por quanto tempo cada
uma precisa permanecer disponível. Na opção A isso é irrelevante (custo zero); nas opções B e C é o
que define a fatura.

### 3.3 Prazo

Independentemente do mecanismo, a oferta de fonte precisa permanecer válida enquanto o binário
correspondente estiver em uso pelas prefeituras — na prática, enquanto a versão estiver instalada.
A opção A satisfaz isso naturalmente, porque a release não é removida.

---

## 4. Escopo — o que esta versão é e o que não é

Esta versão do IMAN Terra **embarca e redistribui** o QGIS (via A1, `D-IMAN-028`), extraído sem
modificação do instalador oficial da QGIS.ORG. **Não recompilamos e não modificamos o núcleo do
QGIS** — o que a árvore contém é a cópia oficial, e o `Payload SHA-256` no `BUILD_INFO.txt` permite
provar isso.

Um eventual fork do QGIS (Opção 2, futuro), que **modificaria** o núcleo, tornaria o binário obra
derivada e traria a obrigação adicional de publicar as fontes modificadas. **Está fora do escopo
desta versão.**
