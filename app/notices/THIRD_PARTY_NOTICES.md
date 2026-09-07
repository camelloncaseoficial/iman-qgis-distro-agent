# Avisos de terceiros — IMAN Terra (powered by QGIS)

> **IMAN Terra é uma experiência geoespacial desktop independente, powered by QGIS.**
> **O QGIS é um sistema de informação geográfica livre e de código aberto, desenvolvido**
> **por QGIS.ORG e contribuidores.**
> **Este projeto NÃO é um produto oficial do QGIS e NÃO é endossado pela QGIS.ORG.**

---

## 1. O que o IMAN Terra distribui

O IMAN Terra **embarca e redistribui** o QGIS e todo o seu ecossistema. Não é uma camada de marca
sobre uma instalação que o usuário faça separadamente: o instalador carrega uma **cópia privada
completa**, que vive dentro da pasta do produto e é removida no desinstalador.

| | |
|---|---|
| Componentes de terceiros redistribuídos | **159** |
| Arquivos | **37.337** |
| Tamanho da árvore embarcada | **2.387.710.878 bytes (2,224 GB)** |
| QGIS embarcado | **3.44.13** (LTR) |

**O Instituto IMAN é redistribuidor** desses componentes. Eles não são obra do Instituto IMAN,
pertencem aos seus autores e permanecem sob as suas próprias licenças.

### Procedência — verificável, não afirmada

O QGIS embarcado é **a cópia oficial da QGIS.ORG, extraída sem modificação**. A árvore é montada com
`msiexec /a` (instalação administrativa: extrai sem instalar) a partir do instalador oficial:

```
Payload de origem : QGIS-OSGeo4W-3.44.13-1.msi
SHA-256           : 42E2F1A6047A827454BC991F8E8CAA069961B9CB4B877E1F5568A43D98844EB4
Origem oficial    : https://download.qgis.org/downloads/QGIS-OSGeo4W-3.44.13-1.msi
```

Esses valores são registrados em `BUILD_INFO.txt`, entregue junto com o produto. Qualquer pessoa
pode baixar o payload oficial, conferir o SHA-256 e verificar que **não há modificação** do QGIS
nesta distribuição. Não recompilamos, não alteramos e não aplicamos patches ao núcleo do QGIS.

Todos os créditos, marcas e telas nativas do QGIS permanecem intactos.

---

## 2. QGIS

- **Projeto:** QGIS — A Free and Open Source Geographic Information System
- **Autoria:** QGIS.ORG e contribuidores
- **Site:** https://qgis.org · **Código-fonte:** https://github.com/qgis/QGIS
- **Licença:** GNU General Public License, versão 2 ou posterior (**GPL-2.0-or-later**)
- **Versão redistribuída:** 3.44.13

Pacotes do QGIS presentes: `qgis-ltr`, `qgis-ltr-common`, `qgis-ltr-grass-plugin`,
`qgis-ltr-oracle-provider`, `qgis-ltr-full`, `qgis-ltr-full-free`, `python3-gdal`.

---

## 3. Inventário completo

O inventário componente a componente — **nome · versão · licença · categoria · origem da informação ·
URL da fonte · embarca binário** — está publicado em formato máquina-legível no repositório do
projeto:

- `docs/licencas/inventario.csv` — 159 linhas, uma por componente
- `docs/licencas/INVENTARIO.md` — método, legendas e resumo

### Resumo por categoria

| Categoria | Componentes |
|---|---:|
| Permissiva (MIT / BSD / Apache / PSF / Zlib / …) | 114 |
| **Copyleft forte** (GPL / AGPL) | 20 |
| **Copyleft fraco** (LGPL e variantes) | 14 |
| **Proprietária com redistribuição condicionada** | 6 |
| **`DESCONHECIDA`** | 5 |

### Sobre a coluna "origem da informação"

Cada licença listada foi **consultada numa fonte identificada**, e a fonte está registrada linha a
linha. Nenhuma licença foi deduzida pelo nome do componente.

| Origem | Componentes |
|---|---:|
| Arquivo de licença dentro da própria árvore entregue | 69 |
| Repositório oficial do projeto | 55 |
| Site oficial do projeto ou do detentor | 31 |
| **`NAO ENCONTRADO`** → declarado `DESCONHECIDA` | 4 |

> **`DESCONHECIDA` é uma resposta honesta, não uma omissão.** Onde a licença não pôde ser
> determinada a partir de uma fonte confiável, ela está assim declarada, com o registro do que foi
> consultado. Licença inventada seria pior que licença ausente.

Os 5 componentes com licença ainda não determinada são `saga`, `qtwebkit-libs`, `base`, `setup` e
`proj-runtime-data` (neste último, o código do PROJ é MIT, mas os termos de cada grade de datum não
foram verificados individualmente).

---

## 4. Principais componentes

### Copyleft forte (GPL / AGPL) — geram direito ao código-fonte

| Componente | Licença |
|---|---|
| QGIS (`qgis-ltr` e pacotes irmãos) | GPL-2.0-or-later |
| GRASS GIS | GPL-2.0-or-later |
| Ghostscript (`gs`) | **AGPL** |
| poppler | GPL-2.0 |
| librttopo | GPL-2.0 |
| exiv2 | GPL-2.0-or-later |
| GPSBabel | GPL-2.0 |
| GNU GSL | GPL-3.0 |
| lz4 | BSD-2 em `lib/`, GPL-2.0-or-later no restante |
| MySQL Client Library (`libmysql`) | GPL-2.0 com FOSS License Exception, ou comercial |
| QScintilla e bindings | GPL-3.0 ou comercial |
| PyQt5 | GPL v3 |
| Remotior Sensus | GPL-3.0-or-later |

**Como obter o fonte correspondente: ver `SOURCE_CODE.md`.**

### Copyleft fraco (LGPL)

Qt (`qt5-libs`, `qt5-qml`, `qt5-tools`) · GEOS · cairo · QCA · Qwt · wxWidgets · GNU libiconv ·
libspatialite · FreeXL · CA bundle da Mozilla · psycopg / psycopg2

### Permissivos de maior peso

GDAL/OGR (MIT) · PROJ (MIT) · Python (PSF) · SQLite (domínio público) · libpq/PostgreSQL
(PostgreSQL License) · Apache Arrow, Thrift, Xerces-C (Apache-2.0) · NumPy, SciPy, pandas, Shapely
(BSD-3) · ICU (Unicode License v3) · OpenSSL (Apache-2.0) · zlib, libpng, libtiff, libwebp, libjxl,
OpenJPEG, HDF4/HDF5, netCDF, PDAL, libLAS, LASzip

### Componentes proprietários redistribuídos

| Componente | Detentor |
|---|---|
| `gdal-ecw` — SDK ECW/JP2 | Hexagon / ERDAS |
| `gdal-mrsid` — MrSID DSDK | Extensis / LizardTech |
| `gdal-oracle` — plugins OCI/GeoRaster | Oracle |
| `oci` — Oracle Instant Client | Oracle |
| `msodbcsql` — ODBC Driver 18 for SQL Server | Microsoft |
| `msvcrt2019` — Visual C++ Redistributable | Microsoft |

Estes **não** são software livre e são redistribuídos sob os termos dos seus respectivos donos.
Consulte-os antes de redistribuir o IMAN Terra por conta própria — a autorização que a QGIS.ORG
tenha para distribuí-los não se estende automaticamente a terceiros.

---

## 5. Qt e a LGPL — o direito de substituir a biblioteca

A LGPL exige que quem recebe um programa ligado à biblioteca possa **substituí-la** por outra versão
e continuar usando o programa. Isso não se cumpre com documento: cumpre-se com a **forma de
empacotar**. Registramos aqui como a nossa árvore satisfaz esse requisito.

**Verificado nesta distribuição:**

- O Qt é distribuído como **83 DLLs separadas** em `qgis\apps\qt5\bin\` (`Qt5Core.dll`, `Qt5Gui.dll`,
  `Qt5Widgets.dll`, …). **Não há build estático** — nenhum `.lib` de Qt na árvore.
- O QGIS liga ao Qt por **vínculo dinâmico**: `qgis_core.dll` traz `Qt5Core.dll`, `Qt5Gui.dll`,
  `Qt5Widgets.dll`, `Qt5Sql.dll`, `Qt5Xml.dll`, `Qt5Svg.dll`, `Qt5PrintSupport.dll` e outras na sua
  tabela de importação, resolvidas em tempo de carga a partir dos arquivos acima.

**Como substituir o Qt (instruções para o usuário):**

1. Obtenha ou compile o Qt 5.15.x para Windows x64, MSVC, mesma ABI (o fonte oficial está em
   <https://download.qt.io/archive/qt/5.15/>).
2. Feche o IMAN Terra.
3. Substitua os arquivos `Qt5*.dll` em `<pasta de instalação>\qgis\apps\qt5\bin\` pelos seus.
   Os plugins de plataforma e de imagem ficam em `<...>\qgis\apps\qt5\plugins\` e devem vir do
   **mesmo** build do Qt que você instalar.
4. Abra o IMAN Terra normalmente.

> ⚠ **O produto verifica a integridade da árvore antes de abrir.** Substituir DLLs faz a verificação
> acusar divergência, porque ela existe para detectar cópia truncada — um defeito que, no QGIS,
> aparece como *coordenada errada* e não como mensagem de erro. Isso **não** impede a substituição:
> regenere `qgis-manifest.txt` com `installer\New-ArvoreQgis.ps1` a partir da árvore modificada, ou
> ajuste as linhas correspondentes. As instruções e o script fazem parte do fonte publicado
> (ver `SOURCE_CODE.md`).

O mesmo vale para os demais componentes LGPL da árvore (GEOS, cairo, QCA, Qwt, wxWidgets, libiconv,
libspatialite, FreeXL): todos são DLLs separadas, substituíveis pelo mesmo procedimento.

---

## 6. Componentes próprios do IMAN Terra

- Plugin de marca `iman_brand`, startup script, launcher, scripts de build e configuração de perfil:
  código próprio do **Instituto IMAN**, sob **GPL-3.0-or-later** (compatível com o QGIS). Ver
  `LICENSE`.
- Assets de marca (logo, ícone, cores) do **Instituto IMAN** — marca, **não** licenciados para
  reuso. Ver `LICENSE`.

---

## 7. Marcas

"QGIS" e o logotipo do QGIS são marcas da QGIS.ORG. O uso aqui é **nominativo** ("powered by QGIS") e
não implica endosso. "IMAN" e "IMAN Terra" são marcas do Instituto IMAN. As demais marcas citadas
pertencem aos seus respectivos titulares.

---

## 8. Validade deste documento

Este aviso descreve a árvore construída a partir do payload `QGIS-OSGeo4W-3.44.13-1.msi`
(SHA-256 `42E2F1A6…44EB4`). **Trocar a versão do QGIS embarcado invalida a lista de componentes e
exige refazer o inventário** — o procedimento está em `docs/licencas/INVENTARIO.md`.

Erros ou omissões neste documento: por favor, reporte ao Instituto IMAN pelo canal indicado em
`SOURCE_CODE.md`. Créditos e licenças de terceiros são corrigidos com prioridade.
