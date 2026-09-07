# Referência — Inventário de licenças e escopo do pacote (árvore embarcada)

Fatos **medidos** na fatia `#020` (`D-IMAN-028`/`DB-6`, 2026-09-07) sobre a árvore que o `#019`
monta. Caros de redescobrir, e dois deles derrubam planos que parecem óbvios.

Entregáveis: `docs/licencas/INVENTARIO.md` · `docs/licencas/inventario.csv` ·
`docs/licencas/EXCLUSAO_PROPOSTA.md` · `app/notices/` (os três documentos).

---

## 1. Os tarballs `-src` do OSGeo4W NÃO são código-fonte

**São a receita de build.** Medido: os 155 `-src.tar.bz2` correspondentes à nossa árvore somam
**271.074 bytes (0,26 MB)** — *todos* abaixo de 100 KB. O do QGIS
(`qgis-ltr-3.44.13-1-src.tar.bz2`, **7.723 bytes**) contém apenas `osgeo4w/package.sh` e alguns
`.bat`; **zero linha de código do QGIS**.

> **Consequência:** espelhar os `-src` do OSGeo4W **não cumpre** a GPL. O fonte correspondente vem
> dos tarballs upstream que o `package.sh` nomeia — registrados na coluna `url_da_fonte` do
> `inventario.csv`.

Bônus: `osgeo4w/patch` na receita do QGIS tem **0 byte** → o OSGeo4W **não aplica patch** ao QGIS.

## 2. `libmysql` NÃO pode ser excluído da árvore

`bin/gdal313.dll` (o núcleo do GDAL) traz **`libmysql.dll` na tabela de importação normal**, não em
delay-load — `gdal313.dll` não tem seção de delay-load alguma. Remover o arquivo faz o GDAL **não
carregar**, e sem GDAL o QGIS não abre.

Isso contraria a lista de candidatos do briefing `#020`, que o incluía. **Não apagar.**

## 3. Onde está a fonte da verdade do inventário

- **Universo de pacotes:** `etc/setup/installed.db` na árvore extraída → 159 pacotes, nome + versão.
- **Conteúdo/tamanho por pacote:** `etc/setup/<pacote>.lst.gz` (listagem `tar -tv`). **Descontar as
  entradas de diretório** (826 no total) — senão a contagem de arquivos sai inflada.
- **Dependências + URL do fonte upstream:** `setup.ini` oficial do OSGeo4W
  (`https://download.osgeo.org/osgeo4w/v2/x86_64/setup.ini`, ~513 KB) — cobre **159/159**.
- **Licença lida de dentro do produto:** **68** pacotes carregam arquivo de licença próprio (não 3,
  como se supunha) — a maioria em `*.dist-info/licenses/` dos pacotes Python.

## 4. Duas armadilhas de classificação (já custaram retrabalho)

- **Arquivo de licença agregado ≠ licença do pacote.** `scipy-*.dist-info/LICENSE.txt` tem 45 KB e
  reúne dezenas de licenças embutidas, algumas GPL. Classificar pelo *primeiro texto reconhecido*
  daria "GPL" para o SciPy, que é BSD-3. Textos acima de ~12 KB devem ser tratados como agregados.
- **A primeira URL da receita nem sempre é o fonte.** As receitas de `qt5-libs`/`qt5-qml`/`qt5-tools`
  começam baixando um instalador do **python.org** — ferramenta de build, não fonte do Qt.

## 5. Ferramentas: o que existe e o que não existe nesta bancada

- **`strings`, `objdump` e `dumpbin` NÃO existem** no Git Bash desta máquina. `strings x | grep -c`
  devolve **0** silenciosamente — resultado que parece um achado ("nenhuma referência") e não é.
  Já produziu uma conclusão errada nesta fatia, corrigida antes de entrar no documento.
- **Python 3.13 existe** em `C:\Program Files\Python313\python`. Para ler tabela de importação PE
  (import normal + delay-load) e fazer busca byte a byte, usar Python — é o caminho confiável aqui.
- **`gh` (2.98.0) existe** e a API de licenças do GitHub (`gh api repos/<owner>/<repo>/license`)
  resolve licença com fonte citável. `NOASSERTION` = licenciamento múltiplo/custom → ler o arquivo.

## 6. Números de referência da árvore 3.44.13

| | |
|---|---|
| Pacotes / arquivos / tamanho | **159 · 37.337 · 2.387.710.878 B (2,224 GB)** |
| Instalador `0.3.0` | 511.365.552 B (487,7 MB) |
| Categorias | 114 permissiva · 20 copyleft forte · 14 copyleft fraco · 6 proprietária · 5 `DESCONHECIDA` |
| Maior componente proprietário | **`oci` (Oracle Instant Client) — 77,7 MB**, pacote próprio, fora da lista do briefing |
| Fonte correspondente copyleft (1 release) | **≈ 1,1 GB** — o Qt sozinho é 630 MB (57 %) |

> O inventário vale **para o payload `QGIS-OSGeo4W-3.44.13-1.msi`** (SHA-256 `42E2F1A6…44EB4`).
> **Trocar a baseline do QGIS invalida o inventário** — refazer o método do `INVENTARIO.md`.
