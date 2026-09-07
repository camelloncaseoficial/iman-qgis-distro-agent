# Inventário de componentes de terceiros — IMAN Terra

**Fatia:** `qgis-distro #020` · **Materializa:** `D-IMAN-028`/`DB-6` · **Levantado em:** 2026-09-07
**Arquivo máquina-legível:** [`inventario.csv`](inventario.csv) — 159 linhas, `;` como separador, UTF-8, sem aspas
**Proposta de escopo do pacote:** [`EXCLUSAO_PROPOSTA.md`](EXCLUSAO_PROPOSTA.md)

---

## O que este documento é

Em 30/07/2026 o IMAN Terra deixou de **usar** o QGIS e passou a **distribuí-lo**. A obrigação mudou
de natureza: quem entrega o binário responde pelos avisos e pelo fonte correspondente dos
componentes que entrega. Este é o inventário do que efetivamente sai no instalador.

**O que medimos, uma vez, sobre a árvore que o `#019` monta:**

| | |
|---|---|
| Pacotes OSGeo4W distintos | **159** |
| Arquivos na árvore extraída | **37.337** |
| Tamanho da árvore | **2.387.710.878 bytes — 2,224 GB** |
| Instalador resultante | **511.365.552 bytes — 487,7 MB** (`0.3.0`) |
| Payload de origem | `QGIS-OSGeo4W-3.44.13-1.msi`, SHA-256 `42E2F1A6…44EB4` |
| Pacotes que embarcam binário (`.dll`/`.exe`/`.pyd`) | **114** de 159 |

> Estes números vêm de `installer/dist/BUILD_INFO.txt` e de contagem direta no disco.
>
> **Reconciliação com as listas de pacote** (as listas e o disco batem, e vale mostrar por quê):
>
> | | Arquivos |
> |---|---:|
> | Entradas somadas em `etc/setup/*.lst.gz` | 38.001 |
> | − entradas que são **diretório**, não arquivo | −826 |
> | = arquivos efetivamente declarados pelos 159 pacotes | **37.175** |
> | + conteúdo de `etc/setup/` — os 159 `.lst.gz` e o `installed.db` | +160 |
> | **= esperado no disco** | **37.335** |
> | **Contado no disco** | **37.337** |
>
> O resíduo de 2 arquivos fica por conta de caminhos com espaço e diferenças de caixa
> (`Lib`/`lib`) na leitura das listas. **A contagem válida é a do disco: 37.337.** O próprio banco
> de pacotes (`etc/setup/`) não pertence a pacote nenhum — é o catálogo, não o conteúdo.
>
> **O mesmo vale para a coluna `bytes_no_pacote` do CSV**, que soma **2.387.187.843 B** — menos que
> os 2.387.710.878 B da árvore. A diferença são os **421.243 B** de `etc/setup/` (fora dos pacotes)
> mais ~102 KB do mesmo resíduo de parsing. Some a coluna esperando a soma dos **pacotes**, não a
> da árvore.

---

## A regra que governou este levantamento

> ### `DESCONHECIDA` é resultado válido e obrigatório.
> ### Licença inventada é pior que licença ausente.

Nenhuma licença aqui foi deduzida pelo **nome** do pacote, e nenhuma foi copiada de lista de
terceiros. Cada linha do CSV carrega a coluna **`origem_da_informacao`**, que diz **de onde** a
resposta veio, e **`url_da_fonte`**, que diz **onde conferir**.

### Legenda das origens (`E.6` — o que é medido e o que não é)

| Origem | O que significa | Força |
|---|---|---|
| **arquivo na árvore** | licença lida de um arquivo que **está dentro do produto que entregamos** (`COPYING`, `LICENSE`, `dist-info/METADATA`) | máxima — é o que o usuário recebe |
| **arquivo de fonte upstream** | licença lida do cabeçalho do tarball de fonte que o *recipe* do OSGeo4W baixa | alta |
| **repositório oficial do projeto** | `LICENSE`/`COPYING` do repositório do projeto, ou o SPDX que a API de licenças do GitHub detecta nesse arquivo | alta |
| **site oficial do projeto ou do detentor** | página de licenciamento publicada pelo próprio projeto/detentor | média-alta |
| **`NAO ENCONTRADO`** | **não foi consultada nesta fatia** — a licença **não** foi determinada | nenhuma → `DESCONHECIDA` |

---

## Resultado

### Por categoria

| Categoria | Pacotes |
|---|---:|
| Permissiva (MIT/BSD/Apache/PSF/Zlib/…) | **114** |
| **Copyleft forte** (GPL/AGPL) | **20** |
| **Copyleft fraco** (LGPL e variantes) | **14** |
| **Proprietária com redistribuição condicionada** | **6** |
| **`DESCONHECIDA`** | **5** |

### Por origem da informação

| Origem | Pacotes |
|---|---:|
| Arquivo na árvore (ou no tarball de fonte upstream) | **69** |
| Repositório oficial do projeto | **55** |
| Site oficial do projeto ou do detentor | **31** |
| `NAO ENCONTRADO` | **4** |

> **Correção de uma premissa do briefing.** O briefing informava que **3** pacotes carregam arquivo
> de licença próprio na árvore (`grass/COPYING`, `Python312/LICENSE.txt`, `qgis-ltr/doc/LICENSE`).
> Varrendo os 159 `etc/setup/*.lst.gz` por `COPYING`/`LICENSE`/`LICENCE`/`NOTICE`/`COPYRIGHT`,
> encontramos **68** — a diferença são os `*.dist-info/licenses/` dos pacotes Python, que ficam
> aninhados em `site-packages` e não aparecem numa varredura de topo. **A árvore prova mais do que
> se supunha**, e 69 das 159 licenças puderam ser lidas de dentro do próprio produto.

---

## Os 20 componentes de **copyleft forte** — os que geram obrigação de fonte

| Pacote | Licença | Origem |
|---|---|---|
| `qgis-ltr`, `qgis-ltr-common`, `qgis-ltr-full`, `qgis-ltr-full-free`, `qgis-ltr-grass-plugin`, `qgis-ltr-oracle-provider` | GPL-2.0-or-later | repo oficial `qgis/QGIS` |
| `grass`, `grass8` | GPL-2.0-or-later | site oficial + `apps/grass/grass85/COPYING` na árvore |
| `gs` (Ghostscript) | **AGPL** (fontes/CMap com exceção) | `LICENSE` de `ArtifexSoftware/ghostpdl` |
| `poppler` | GPL-2.0 | `COPYING` no GitLab do freedesktop |
| `librttopo` | GPL-2.0 | `COPYING` no Gitea da OSGeo |
| `exiv2` | GPL-2.0-or-later | `COPYING` de `exiv2/exiv2` |
| `gpsbabel` | GPL-2.0 | repo oficial |
| `gsl` | GPL-3.0 | repo oficial (port do GNU GSL) |
| `lz4` | BSD-2 em `lib/`, **GPL-2.0-or-later** no resto | `LICENSE` de `lz4/lz4` |
| `libmysql` | GPL-2.0 com *FOSS License Exception*, **ou** comercial | site oficial MySQL |
| `qscintilla`, `python3-qscintilla` | GPL-3.0 **ou** comercial | site oficial Riverbank |
| `python3-pyqt5` | GPL v3 | `dist-info/METADATA` na árvore |
| `python3-remotior-sensus` | GPL-3.0-or-later | `dist-info/METADATA` na árvore |

**Consequência direta:** para estes, quem recebeu o binário **de nós** tem direito de obter o fonte
correspondente **de nós**. Ver `app/notices/SOURCE_CODE.md`, §"Espelho de fonte".

## Os 14 de **copyleft fraco** (LGPL)

`qt5-libs` · `qt5-qml` · `qt5-tools` · `geos` · `cairo` · `qca` · `qwt-libs` · `wxwidgets` ·
`libiconv` · `libspatialite` · `freexl` · `curl-ca-bundle` · `python3-psycopg` · `python3-psycopg2`

O caso do **Qt** é tratado à parte em `app/notices/THIRD_PARTY_NOTICES.md`, porque a LGPL exige que o
usuário possa **substituir** a biblioteca — isso se cumpre com **forma de empacotar**, não com
documento.

## Os 6 **proprietários com redistribuição condicionada**

| Pacote | Dono | Situação |
|---|---|---|
| `gdal-ecw` | Hexagon / ERDAS | SDK ECW/JP2 — EULA de redistribuidor próprio |
| `gdal-mrsid` | Extensis / LizardTech | MrSID DSDK — EULA de redistribuidor próprio |
| `gdal-oracle` | Oracle | plugins GDAL que ligam em `OCI.dll` |
| `oci` | Oracle | **Oracle Instant Client — 77,7 MB**, o maior componente proprietário |
| `msodbcsql` | Microsoft | ODBC Driver 18 for SQL Server |
| `msvcrt2019` | Microsoft | Visual C++ Redistributable |

> Nestes, a pergunta **não** é "publicamos o fonte?" — é **"temos permissão para redistribuir?"**.
> **Os EULA não foram obtidos nesta fatia**, e esta crew **não emite parecer**. O material para essa
> análise (`§26`) está em [`EXCLUSAO_PROPOSTA.md`](EXCLUSAO_PROPOSTA.md).
>
> `msvcrt2019` é o runtime da Microsoft, cuja redistribuição segue termos próprios — ele não é
> candidato a exclusão (sem ele nada roda), mas **é** um componente proprietário que entregamos.

## Os 5 `DESCONHECIDA` — declarados, não escondidos

| Pacote | Por que | O que falta |
|---|---|---|
| `saga` | consulta ao site oficial não retornou a licença | ler o `COPYING` do fonte no SourceForge |
| `qtwebkit-libs` | repositório do *fork* não expõe arquivo de licença via API | ler o `LICENSE` do tarball que o *recipe* baixa |
| `base` | pacote do próprio OSGeo4W; o *recipe* não nomeia fonte upstream | perguntar ao OSGeo4W |
| `setup` | idem `base` | perguntar ao OSGeo4W |
| `proj-runtime-data` | o **código** do PROJ é MIT, mas **cada grade de datum tem termos próprios** | verificar grade a grade (19 arquivos) |

`proj-runtime-data` é o mais relevante dos cinco: são as grades que produzem o deslocamento de datum
correto (~57 m) que o `#016` mediu. **Não** é candidata a exclusão — é dívida de inventário.

---

## Método — reprodutível, e reprodutível por outra pessoa

1. **Universo:** `etc/setup/installed.db` da árvore extraída → 159 pacotes com nome e versão exatos.
2. **Conteúdo e tamanho:** `etc/setup/<pacote>.lst.gz` (listagem `tar -tv` do pacote instalado),
   descontadas as entradas de diretório; conferido contra o disco.
3. **Embarca binário?** presença de `.dll`/`.exe`/`.pyd`/`.lib` na listagem do pacote.
4. **Licença — em ordem de precedência:**
   1. arquivo de licença dentro da árvore (68 pacotes o têm);
   2. declaração do próprio pacote em `*.dist-info/METADATA` (campo `License:` ou `Classifier`);
   3. `LICENSE`/`COPYING` do repositório oficial (API de licenças do GitHub, ou o arquivo bruto);
   4. página de licenciamento do projeto/detentor;
   5. **`DESCONHECIDA`**, com a origem consultada registrada.
5. **URL do fonte:** extraída do *recipe* de build oficial do OSGeo4W
   (`<pacote>-<versao>-src.tar.bz2` → `osgeo4w/package.sh`), que nomeia o tarball upstream de onde o
   binário foi construído.

### Duas armadilhas que este método evitou — e vale registrar

- **Arquivo de licença agregado ≠ licença do pacote.** `scipy-1.18.0.dist-info/LICENSE.txt` tem
  45 KB e reúne as licenças de dezenas de componentes embutidos, algumas GPL. Classificar o SciPy
  pelo *primeiro texto reconhecido* daria "GPL" — e o SciPy é BSD-3. Textos acima de 12 KB são
  marcados como agregados e **não** classificam o pacote; vale a declaração do próprio pacote.
- **A primeira URL do *recipe* nem sempre é o fonte.** Os *recipes* do `qt5-libs`/`qt5-qml`/
  `qt5-tools` começam baixando um instalador do **python.org** — ferramenta de build, não fonte do
  Qt. Essas URLs foram **descartadas**, não publicadas como origem.

---

## Achado que muda o plano de conformidade

**Os tarballs `-src` do OSGeo4W não são o fonte correspondente.** São o *recipe* de build.

Medido: os 155 `-src.tar.bz2` correspondentes à nossa árvore somam **271.074 bytes (0,26 MB)**;
**todos** têm menos de 100 KB. O do QGIS —
`qgis-ltr-3.44.13-1-src.tar.bz2`, **7.723 bytes** — contém apenas `osgeo4w/package.sh` e um punhado
de `.bat`; **nenhuma linha de código do QGIS**.

> Espelhar os `-src` do OSGeo4W **não cumpre** a GPL. O fonte correspondente tem de vir dos tarballs
> upstream que o `package.sh` nomeia. O mecanismo proposto está em `app/notices/SOURCE_CODE.md`.

*(Efeito colateral útil: o arquivo `osgeo4w/patch` do recipe do QGIS tem **0 byte** — o OSGeo4W não
aplica patch ao QGIS. O fonte correspondente é o tarball upstream sem modificação.)*

---

## Como manter isto vivo

Este inventário descreve o **payload `QGIS-OSGeo4W-3.44.13-1.msi`**, identificado pelo SHA-256 em
`BUILD_INFO.txt`. **Trocar a versão do QGIS invalida o inventário**: muda a lista de pacotes, as
versões e possivelmente as licenças.

Ao subir a baseline do QGIS (`$QgisBaseline` em `installer/build.ps1`), refazer os passos 1–3 do
método sobre a árvore nova e conferir o *diff* de pacotes contra `inventario.csv`.
