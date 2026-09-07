# Escopo do pacote — proposta de exclusão de componentes proprietários

**Fatia:** `qgis-distro #020` · **Materializa:** `D-IMAN-028`/`DB-6` · **Data da medição:** 2026-09-07
**Árvore medida:** `installer/stage/qgis/QGIS 3.44.13` — **37.337 arquivos · 2.276,14 MB (2,224 GB)**
**Payload de origem:** `QGIS-OSGeo4W-3.44.13-1.msi`, SHA-256 `42E2F1A6…44EB4` (ver `BUILD_INFO.txt`)

> **`S.5` — esta fatia MEDE e RELATA. Não arbitra.**
> Excluir capacidade do produto é **decisão do sponsor**. O que segue é a medição e uma
> recomendação fundamentada; **nada foi excluído**, e a árvore não foi tocada. Quem aplica a
> exclusão é o `#019`, depois da decisão.

> **Fora de escopo:** parecer jurídico. Este documento **não** conclui que podemos ou não podemos
> redistribuir. Ele produz o material que torna essa análise possível (`§26` do plano do sponsor).

---

## 1. Por que a pergunta mudou

Na via A2 o QGIS era instalado ao lado, pela QGIS.ORG, e o IMAN Terra apenas o usava. Na **via A1**
nós **montamos a árvore** — logo, **podemos não embarcar** o que não queremos assumir.

Nos componentes abaixo a pergunta **não** é *"publicamos o fonte?"*. É **"temos permissão para
redistribuir?"** — e cada um tem EULA de redistribuidor próprio. **A QGIS.ORG distribuí-los não nos
autoriza a distribuí-los:** a nossa entrega é um **novo ato de distribuição, por uma nova parte**,
para ~35 prefeituras.

A documentação do próprio GDAL registra o ponto de forma explícita:

> *"the use of a GDAL binary can be subject to less permissive licensing terms than MIT"*
> — <https://gdal.org/en/stable/license.html> (consultado 2026-09-07)

---

## 2. Método da medição — o que é medido e o que é presumido

| Pergunta | Como foi respondida |
|---|---|
| O binário está fisicamente na árvore? | `os.path.getsize` em cada caminho — **18/18 confirmados** |
| Quanto ocupa? | soma dos tamanhos declarados em `etc/setup/<pacote>.lst.gz`, conferida contra o disco |
| **Quem depende dele?** | **tabela de importação PE lida de 1.604 binários** (`.dll`/`.exe`/`.pyd`) da árvore |
| Dependência declarada pelo upstream | `requires:` do `setup.ini` oficial do OSGeo4W |
| O QGIS sobe sem ele? | inferido da tabela de importação (ver §3), **não executado** — ver §7 |

A distinção que decide tudo:

- **IMPORT** (tabela de importação normal) — o Windows resolve **no carregamento**. Se o arquivo
  faltar, **o módulo não carrega**. Remover = quebrar.
- **Plugin carregado sob demanda** (`gdalplugins/`, `qtplugins/sqldrivers/`) — só é aberto quando o
  formato/conexão é usado. Ausente, o GDAL/Qt simplesmente não oferece aquele driver.

Foi essa leitura que derrubou uma das exclusões que pareciam óbvias (§4).

---

## 3. Grafo de dependência medido (tabela de importação PE)

```
NCSEcw.dll         <- apps/gdal/lib/gdalplugins/gdal_ECW_JP2ECW.dll     (plugin, sob demanda)
lti_dsdk_9.5.dll   <- apps/gdal/lib/gdalplugins/gdal_MrSID.dll          (plugin, sob demanda)
tbb.dll            <- bin/lti_dsdk_9.5.dll, lti_dsdk_cdll_9.5.dll,
                      lti_lidar_dsdk_1.1.dll                            (só o SDK MrSID)
OCI.dll            <- apps/gdal/lib/gdalplugins/gdal_GEOR.dll           (plugin, sob demanda)
                      apps/gdal/lib/gdalplugins/ogr_OCI.dll             (plugin, sob demanda)
                      apps/qgis-ltr/qtplugins/sqldrivers/qsqlocispatial.dll (plugin, sob demanda)
msodbcsql18.dll    <- apps/gdal/lib/gdalplugins/ogr_MSSQLSpatial.dll    (plugin, sob demanda)
libmysql.dll       <- apps/qt5/plugins/sqldrivers/qsqlmysql.dll         (plugin, sob demanda)
                      bin/gdal313.dll                       <<< IMPORT DO NÚCLEO DO GDAL
gsdll64.dll        <- (ninguém — nos 1.604 binários analisados)
```

Os pacotes `qgis-ltr-full`, `qgis-ltr-full-free`, `grass8` e `szip` são **metapacotes vazios**
(medido: um único registro de diretório, 0 byte). Quando o `setup.ini` diz que `qgis-ltr-full`
*requires* `gdal-ecw`, isso é **agregação de catálogo, não dependência funcional**: nenhum binário
executável depende deles.

---

## 4. ⚠ O achado que impede uma exclusão: `libmysql`

`bin/gdal313.dll` — **o núcleo do GDAL**, 43,93 MB, o que todo o produto usa para ler qualquer
formato — traz `libmysql.dll` na sua **tabela de importação normal**, não em delay-load
(`gdal313.dll` não possui seção de delay-load alguma).

**Consequência medida:** remover `libmysql.dll` faz `gdal313.dll` **não carregar**. Sem GDAL o QGIS
não abre. A economia de 6,99 MB custaria o produto inteiro.

> **`libmysql` NÃO é candidato a exclusão** — apesar de constar da lista do briefing. Se o sponsor
> decidir que não quer redistribuir o cliente MySQL, o caminho **não** é apagar o arquivo: é um GDAL
> compilado sem o driver MySQL, o que sai do no-fork e vira fatia própria.

---

## 5. Tabela de decisão — `pacote · o que se perde · tamanho · recomendação`

| # | Pacote(s) | Dono | O que deixa de funcionar | Arq. | Tamanho | Recomendação |
|---|---|---|---|---:|---:|---|
| 1 | `gdal-oracle` + `oci` + `qgis-ltr-oracle-provider` | Oracle | Conexão a **Oracle Spatial** e leitura de **GeoRaster** (`OCI`, `GeoRaster`, provider Oracle do QGIS) | 6 | **76,29 MB** | **Excluir** |
| 2 | `gdal-mrsid` (inclui `tbb.dll`) | Extensis / LizardTech | Leitura de raster **MrSID (`.sid`)** e LiDAR **MG4** | 5 | **27,72 MB** | **Excluir** |
| 3 | `msodbcsql` + `gdal-mss` | Microsoft | Conexão a **SQL Server / MSSQLSpatial** | 5 | **4,35 MB** | **Excluir** |
| 4 | `gs` (Ghostscript) | Artifex — **AGPL** | Compositor Cartográfico do **GRASS** (janela própria do GRASS). **Não** afeta o QGIS | 520 | **40,42 MB** | **Excluir** — ver §6.2 |
| 5 | `gdal-ecw` | Hexagon / ERDAS | Leitura de raster **ECW (`.ecw`)** e **ERDAS JPEG2000** | 2 | **7,55 MB** | ⚠ **Decisão do sponsor** — ver §6.1 |
| — | `libmysql` | Oracle / MySQL | *(não excluível — §4)* | 1 | 6,99 MB | **Manter** |

**Se o sponsor aprovar os itens 1 a 4:** **−148,78 MB** (536 arquivos), de 2.276,14 MB para
**2.127,36 MB** (−6,5 %).
**Se aprovar também o item 5 (ECW):** **−156,33 MB** (538 arquivos), para **2.119,81 MB** (−6,9 %).

O ganho de espaço é modesto e **não é o motivo**. O motivo é retirar da entrega seis componentes
cuja permissão de redistribuição por *nós* não está estabelecida.

---

## 6. As duas decisões que são de produto, não de licença

### 6.1 ⚠ ECW — o único com risco real de uso em campo

**ECW é formato de raster, e ortofoto de drone e de órgão estadual frequentemente vem em `.ecw`.**
Num produto de REURB para ~35 prefeituras, esse é um formato que pode aparecer no dia a dia — ao
contrário de Oracle Spatial, SQL Server e MrSID.

- **O que medimos:** `gdal_ECW_JP2ECW.dll` é plugin carregado sob demanda; removê-lo **não impede o
  QGIS de abrir**. O efeito é que um `.ecw` arrastado para o mapa **não abre** — o QGIS reporta
  formato não suportado.
- **O que NÃO medimos:** quantas prefeituras efetivamente recebem ortofoto em ECW. Isso é
  levantamento de campo, não de árvore.
- **Contrapartida:** manter significa redistribuir o SDK da Hexagon sob o EULA dela.

**Não recomendamos por conta própria.** Se a decisão for excluir, sugerimos que venha acompanhada de
uma orientação ao usuário ("converta o ECW para GeoTIFF/COG na origem"), porque o modo de falha —
arquivo que simplesmente não abre — é confuso sem aviso.

### 6.2 Ghostscript (`gs`) — o alarme do briefing não se confirmou

O briefing alertou que excluir `gs` (AGPL) poderia quebrar exportação/impressão. **Medimos, e não
quebra:**

| Verificação | Resultado |
|---|---|
| Binários que importam `gsdll64.dll` (tabela de importação de 1.604 PEs) | **nenhum** |
| Busca literal por `ghostscript`/`gswin64c`/`gswin32c`/`gsdll64`/`gsdll32` (byte a byte) em `qgis_core.dll`, `qgis_gui.dll`, `qgis_app.dll`, `qgis_analysis.dll`, `qgis_process.exe` e `gdal313.dll` — 114 MB de binários | **zero ocorrências** |
| Único consumidor na árvore inteira | `apps/grass/grass85/gui/wxpython/psmap/frame.py` |
| Como o QGIS exporta PDF/PS | `Qt5PrintSupport.dll` + `windowsprintersupport.dll` (**Qt**, não `gs`) |

O único uso é o **Compositor Cartográfico do GRASS** (`psmap`), que invoca `gswin64c` como processo
externo. E o próprio GRASS trata o Ghostscript como programa externo **opcional**: quando não o
encontra, exibe um link para <https://www.ghostscript.com/releases/gsdnld.html> em vez de falhar
(`frame.py:490`).

> **Exportar layout em PDF no QGIS — o caminho que a prefeitura usa — não passa por Ghostscript.**
> Excluir `gs` remove 40,42 MB e o componente **AGPL** mais pesado da árvore, ao custo de uma janela
> do GRASS que o produto não expõe.

---

## 7. Limites desta medição — o que NÃO foi feito

`E.6` — separando o medido do não medido:

- **Não houve execução.** Nenhuma árvore reduzida foi montada e aberta. A afirmação "o QGIS sobe sem
  o pacote" vem da **tabela de importação**, que é forte para carga estática mas **não cobre**
  `LoadLibrary` em tempo de execução dentro de código Python ou C++. **Antes de aplicar, o `#019`
  deve montar a árvore reduzida e rodar o aceite do `#018`** — é a rede que existe para isto.
- **Os EULA não foram obtidos.** Sabemos quem é o dono e que os componentes não são software livre.
  **Não** lemos os termos de redistribuidor da Hexagon, Extensis, Oracle ou Microsoft. Concluir sobre
  permissão é o `§26`, não esta fatia.
- **O manifesto de integridade muda.** `TOTAL`, `MAXREL` e a contagem de `apps/gdal/...` do
  `qgis-manifest.txt` são função da árvore. Excluir pacotes **invalida o manifesto atual** — ele é
  regerado pelo `New-ArvoreQgis.ps1` no mesmo build, mas isso precisa ser consciente, não surpresa.
- **`proj-runtime-data`** ficou `DESCONHECIDA` no inventário: o código do PROJ é MIT, mas **cada
  grade de datum tem termos próprios**, e elas não foram verificadas uma a uma. Não é candidata a
  exclusão (é o que dá os ~57 m de deslocamento correto), mas é dívida de inventário.

---

## 8. O que o `#019` precisa saber agora

1. **Nada a fazer até a decisão do sponsor.** Esta é proposta, não ordem.
2. **`libmysql` sai da lista.** Se já estava previsto excluí-lo, **não exclua** — §4.
3. **Se aprovado**, a exclusão é de **pacote inteiro**, apagando os arquivos que o respectivo
   `etc/setup/<pacote>.lst.gz` lista, **depois** do `msiexec /a` e **antes** do manifesto:

   ```
   gdal-oracle · oci · qgis-ltr-oracle-provider · gdal-mrsid · msodbcsql · gdal-mss · gs
   [+ gdal-ecw, se o sponsor decidir]
   ```

4. **Não remover** os metapacotes vazios (`qgis-ltr-full` etc.): são 0 byte e servem de rastro do
   que o payload original continha.
5. **Rodar o aceite do `#018`** sobre a árvore reduzida antes de considerar o build válido.
6. `SOURCE_CODE.md` **não é instalado** hoje (`iman-terra.iss` copia apenas `LICENSE` e
   `THIRD_PARTY_NOTICES.md`). Com o produto passando a ser redistribuidor de copyleft, ele precisa
   viajar junto — **o `.iss` é do `#019`; esta fatia não o tocou.**

---

## 9. Anexo — os 18 arquivos, conferidos um a um no disco

| Pacote | Arquivo na árvore | Bytes |
|---|---|---:|
| `gdal-ecw` | `apps/gdal/lib/gdalplugins/gdal_ECW_JP2ECW.dll` | 786.432 |
| `gdal-ecw` | `bin/NCSEcw.dll` | 7.133.472 |
| `gdal-mrsid` | `apps/gdal/lib/gdalplugins/gdal_MrSID.dll` | 433.152 |
| `gdal-mrsid` | `bin/lti_dsdk_cdll_9.5.dll` | 13.798.400 |
| `gdal-mrsid` | `bin/lti_dsdk_9.5.dll` | 14.397.952 |
| `gdal-mrsid` | `bin/lti_lidar_dsdk_1.1.dll` | 256.000 |
| `gdal-mrsid` | `bin/tbb.dll` | 176.128 |
| `gdal-oracle` | `apps/gdal/lib/gdalplugins/gdal_GEOR.dll` | 826.880 |
| `gdal-oracle` | `apps/gdal/lib/gdalplugins/ogr_OCI.dll` | 508.416 |
| `oci` | `bin/oci.dll` | 817.152 |
| `oci` | `bin/oraociicus.dll` | **76.917.760** |
| `qgis-ltr-oracle-provider` | `apps/qgis-ltr/plugins/provider_oracle.dll` | 774.656 |
| `qgis-ltr-oracle-provider` | `apps/qgis-ltr/qtplugins/sqldrivers/qsqlocispatial.dll` | 145.920 |
| `msodbcsql` | `bin/msodbcsql18.dll` | 1.976.240 |
| `msodbcsql` | `bin/adal.dll` | 1.758.640 |
| `msodbcsql` | `bin/msodbcdiag18.dll` | 112.560 |
| `msodbcsql` | `bin/1033/msodbcsqlr18.rll` | 210.864 |
| `libmysql` *(não excluível)* | `bin/libmysql.dll` | 7.334.400 |

> **Nota sobre o briefing.** Ele listou `gdal-oracle/oci.dll` como **1 arquivo**. A medição mostra
> que o cliente Oracle é um **pacote separado (`oci`), com 77,7 MB** — `oraociicus.dll` sozinho tem
> 76,9 MB. É de longe o maior componente proprietário da árvore, e não estava dimensionado.
