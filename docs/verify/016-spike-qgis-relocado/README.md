# SPIKE #016 — o QGIS roda relocado? (de-risk da via A1)

**Decisão que materializa:** `D-IMAN-028`, emenda de 2026-09-06 (via **A2 → A1**, cópia privada).
**Executado em:** 2026-09-06 · branch `spike/016-qgis-relocado` (de `develop` = `e312a2d`).
**Tipo:** spike de de-risk timeboxed (1 dia). **Não é fatia de produto.**
**Paga a dívida do STOP-AND-FLAG nunca medido do `D-IMAN-028`:** *"ninguém provou que o QGIS roda
relocado sob `%LOCALAPPDATA%`"*.

> **Regra de ouro (BL-7):** aqui está o que **aconteceu**, não o que deveria acontecer.
> Onde não houve medição, está escrito **N/E (não medido)** — nunca `PASS`.

---

## VEREDITO

> ### `A1 VIÁVEL COM RESSALVA`
>
> **O QGIS 3.44.13 roda a partir de `%LOCALAPPDATA%`, fora de `C:\Program Files`, sem estar
> instalado no Windows** — sem `ProductCode`, sem entrada na ARP, sem chave de registro, sem
> `PATH` de sistema, sem elevação em nenhum passo. Janela principal, canvas com vetor e raster,
> PROJ, GDAL, PyQGIS, Processing e o plugin `iman_brand` no perfil isolado: **8 de 8 medidos com
> evidência, 8 PASS.** Os números batem **dígito a dígito** com o QGIS instalado usado como
> oráculo. O processo relocado carregou **355 módulos, 0 deles da instalação de terceiro**.
>
> **A ressalva é uma só, e não é sobre rodar — é sobre falhar:** a árvore relocada **não se
> autodiagnostica de forma uniforme**. Medido em §6: com `apps\qt5\plugins` ausente a falha é alta
> e visível (caixa de diálogo Win32, nunca chega à janela principal); mas com
> **`apps\qgis-ltr\resources` ausente o QGIS abre normalmente, sem uma linha em `stderr`** — é
> exatamente o "canvas em branco silencioso" que o briefing manda evitar. **A via A1 exige que o
> instalador verifique a integridade da árvore; o QGIS não vai avisar por nós.**
>
> **O estado A (máquina sem QGIS nenhum) NÃO foi medido** — esta bancada não o tem e obtê-lo
> exigiria desinstalar o QGIS do sponsor, proibido por `S.5`. Ver §7 para o que foi medido em
> lugar dele e o que continua em aberto.

**Placar: 8 de 8 asserções de produto com evidência (M1…M8).** Matriz de estados do mundo:
**B, C e D medidos; A não medido.**

---

## 0. Legenda (E.6)

| marca | significa |
|---|---|
| **PASS** / **FAIL** | **medido** nesta bancada, com comando e saída no repositório |
| **N/E** | **não medido** — nomeado, com o motivo, nunca inferido |
| RELATADO | vem de log/documento de terceiro, não de execução nossa (não há nenhum neste laudo) |

Toda evidência citada está em `evidencia/`. Os scripts que a produzem estão em `tools/spike016/`.

---

## 1. A descoberta central: o QGIS já é relocável por construção

O briefing proíbe presumir contrato de terceiro. As três perguntas foram respondidas lendo a árvore
**instalada** e a árvore **extraída**, e comparando as duas.

### 1.1 `OSGEO4W_ROOT` não é gravado no install — é derivado do próprio caminho

`bin\o4w_env.bat`, íntegra (idêntico byte a byte na árvore instalada e na extraída):

```bat
pushd %~dp0
cd ..
for %%i in ("%CD%") do set OSGEO4W_ROOT=%%~fsi
set path=%OSGEO4W_ROOT%\bin;%WINDIR%\system32;%WINDIR%;%WINDIR%\system32\WBem
for %%f in ("%OSGEO4W_ROOT%\etc\ini\*.bat") do call "%%f"
popd
```

`%~dp0` é o diretório do próprio `.bat`. **O root vem de onde o arquivo está, não de onde ele foi
instalado.** E `set path=` **zera** o `PATH` herdado antes de montar o seu — a defesa contra
contaminação já é do fornecedor, não nossa.

### 1.2 Todas as variáveis do briefing são relativas a `%OSGEO4W_ROOT%`

`etc\ini\*.bat`, na íntegra (9 arquivos):

| arquivo | define |
|---|---|
| `gdal.bat` | `GDAL_DATA=%OSGEO4W_ROOT%\apps\gdal\share\gdal` · `GDAL_DRIVER_PATH=%OSGEO4W_ROOT%\apps\gdal\lib\gdalplugins` |
| `proj-runtime-data.bat` | `PROJ_DATA=%OSGEO4W_ROOT%\share\proj` |
| `python3.bat` | `PYTHONHOME=%OSGEO4W_ROOT%\apps\Python312` · `PYTHONPATH=` (vazia!) · `PYTHONEXECUTABLE=%OSGEO4W_ROOT%\bin\python3.exe` |
| `qt5.bat` | `QT_PLUGIN_PATH=%OSGEO4W_ROOT%\apps\Qt5\plugins` + `O4W_QT_*` |
| `curl-ca-bundle.bat`, `openssl.bat`, `gs.bat`, `pdal-libs.bat` | idem, todas com `%OSGEO4W_ROOT%` |
| `base.bat` | dummy (só garante que o `for` tenha o que iterar) |

`GISBASE` idem, em `apps\grass\grass85\etc\env.bat`: `set GISBASE=%OSGEO4W_ROOT%\apps\grass\grass85`.

**Nenhuma das variáveis nomeadas no briefing carrega caminho absoluto gravado em tempo de
instalação.** Duas observações que só aparecem lendo:

- **`PROJ_LIB` não é definida em lugar nenhum** — o QGIS 3.44.13 usa `PROJ_DATA` (PROJ ≥ 9.1).
  Isso importa no estado C (§5.2).
- `python3.bat` **zera** `PYTHONPATH` antes de qualquer coisa.

### 1.3 O que **é** gravado no install: 85 arquivos, e nenhum deles no caminho do QGIS

Aqui está o caminho absoluto que o briefing procurava — e ele existe. O `postinstall.bat` roda
`textreplace -std -t <arquivo>`, que consome um `<arquivo>.tmpl` e substitui o token `@osgeo4w@`
pela raiz **absoluta**. Comparação direta do mesmo arquivo nas duas árvores:

```
$ head -1 <extraída>/apps/Python312/Scripts/gdal_calc.py.tmpl
#! @osgeo4w@\apps\Python312\python3.exe

$ head -1 "/c/Program Files/QGIS 3.44.13/apps/Python312/Scripts/gdal_calc.py"
#! C:\PROGRA~1\QGIS34~1.13\apps\Python312\python3.exe
```

São **85 `.tmpl`** na árvore extraída: 80 em `apps\Python312\Scripts\` (entry points de console),
mais `apps\qgis-ltr\bin\qgis.reg.tmpl`, `bin\setup.bat.tmpl`, `bin\nc-config.tmpl` e 2 templates do
`setuptools`.

> **A consequência que decide o spike:** essa lista **não intersecta** o caminho de execução do
> QGIS Desktop. Nenhum de `qgis-ltr-bin.exe`, canvas, PROJ, GDAL, PyQGIS, Processing ou plugins
> depende de um `Scripts\*.exe`, do `qgis.reg` ou do `setup.bat`. São ferramentas de linha de
> comando auxiliares. **A camada que precisa funcionar já é 100 % relativa.**
>
> O corolário incômodo é o inverso: a instalação **oficial**, essa sim, **não é relocável** —
> os 85 arquivos dela têm `C:\PROGRA~1\QGIS34~1.13` cravado. Copiar `C:\Program Files\QGIS 3.44.13`
> para outro lugar seria a via errada; extrair do MSI é a certa.

### 1.4 O `postinstall.bat` escreve FORA da árvore — e nós não precisamos dele

Lendo `etc\postinstall\*.bat` da árvore extraída, três ações saem da árvore:

| ação | onde escreve | precisamos? |
|---|---|---|
| `regedit /s ...\qgis.reg` (em `qgis-ltr.bat`) | `HKCR` — associação de extensão `.qgs`/`.qgz` | **não** |
| `dllupdate -copy -reboot` (`opencl.bat`, `openssl.bat`) | copia DLL para o diretório do Windows | **não** |
| `xxmklink` (`base/grass/qgis-ltr/saga/setup.bat`) | atalhos em Menu Iniciar / Área de trabalho | **não** — só rodam se `OSGEO4W_MENU_LINKS`/`DESKTOP_LINKS` ≠ 0 |

**Este spike NÃO rodou o `postinstall.bat`.** Todas as medições abaixo são sobre a **árvore crua do
`msiexec /a`**, sem nenhuma escrita fora dela — e ela passou em tudo. Isso é resultado, não atalho:
significa que a via A1 **não precisa** tocar registro, `system32` nem Menu Iniciar do sistema para o
QGIS funcionar. (`tools/spike016/Build-QgisRelocado.ps1` sabe rodar o `postinstall` com `0 0`, para
quem quiser a árvore fiel ao install; não foi necessário.)

---

## 2. Como se extrai a árvore sem instalar — `msiexec /a`

**Sim, `msiexec /a` produz árvore executável.** Medido:

```
> msiexec.exe /a "installer\payload\QGIS-OSGeo4W-3.44.13-1.msi" /qn
    TARGETDIR="C:\Users\Francisco\AppData\Local\InstitutoIMAN\_spike016\IMAN Terra\qgis"
    /L*v "evidencia\msiexec-admin-install.log"
```

| grandeza | valor medido |
|---|---|
| payload | `QGIS-OSGeo4W-3.44.13-1.msi`, 582.197.248 bytes (555,23 MB) |
| SHA-256 | `42E2F1A6047A827454BC991F8E8CAA069961B9CB4B877E1F5568A43D98844EB4` (confere com o briefing) |
| **exit code** | **`0`** |
| tempo | **300,1 s** nesta bancada |
| saída | **37.338 arquivos / 2,232 GB** |
| **elevação** | **nenhuma.** Log: `MSI_LUA: Credential prompt not required, administrative installation creation or servicing`. A sessão roda como usuário comum (`IsInRole(Administrator) = False`) |
| forma da árvore | `TARGETDIR\QGIS 3.44.13\` — o root do OSGeo4W fica **um nível abaixo** do `TARGETDIR` |
| resíduo | o `/a` deixa uma cópia do MSI **sem os cabs**, de 8,57 MB, na raiz do `TARGETDIR` |

O que o `/a` **não** faz, e por isso a árvore é "crua": ele executa a `AdminExecuteSequence`
(`CostInitialize → FileCost → CostFinalize → InstallValidate → InstallInitialize →
InstallAdminPackage → InstallFiles → InstallFinalize`), que **não inclui** a ação customizada
`postinstall`. É por isso que os 85 `.tmpl` continuam sem substituir — ver §1.3.

- Evidência: `evidencia/msiexec-admin-install.RESUMO.log` (110 linhas relevantes de 209.462; o log
  completo tem 86,7 MB e não é versionado, DB-5), `evidencia/build-relocado.json`,
  `evidencia/build-etapa1-crua.txt`.

### 2.1 O QGIS depende de registro / ProductCode / ARP / PATH para iniciar?

**Não.** Medido por construção e por execução:

- a árvore veio de um `/a`, que **não registra produto nenhum** — não há `ProductCode`, nem entrada
  na ARP para ela (o inventário de §5.4 confirma: 2 entradas na ARP antes, as **mesmas** 2 depois);
- o `PATH` do processo é montado do zero pelo `o4w_env.bat` (§1.1) — nada vem do `PATH` do sistema;
- o `qgis.reg` (única escrita de registro do pacote) **não foi aplicado**, e o QGIS abriu.

---

## 3. Ambiente do QGIS relocado, medido

`tools/spike016/Invoke-QgisRelocado.ps1` **não reimplementa** o ambiente: ele *chama* o
`bin\o4w_env.bat` da própria árvore e as linhas do `bin\qgis-ltr.bat`, e captura o `set` resultante.
Sem cópia divergente do contrato.

```
OSGEO4W_ROOT     = C:\Users\FRANCI~1\AppData\Local\INSTIT~1\_SPIKE~1\IMANTE~1\qgis\QGIS34~1.13
PROJ_DATA        = <RELOCADO>\share\proj
PROJ_LIB         = <não definida>
GDAL_DATA        = <RELOCADO>\apps\gdal\share\gdal
GDAL_DRIVER_PATH = <RELOCADO>\apps\gdal\lib\gdalplugins
PYTHONHOME       = <RELOCADO>\apps\Python312
PYTHONPATH       = <RELOCADO>\apps\qgis-ltr\python;<RELOCADO>\apps\grass\grass85\etc\python;
QT_PLUGIN_PATH   = <RELOCADO>\apps\qgis-ltr\qtplugins;<RELOCADO>\apps\qt5\plugins
QGIS_PREFIX_PATH = C:/Users/FRANCI~1/.../QGIS34~1.13/apps/qgis-ltr
GISBASE          = <RELOCADO>\apps\grass\grass85
```

Duas coisas para o instalador saber:

1. **O root sai em forma 8.3** (`FRANCI~1`, `IMANTE~1`), porque o `o4w_env.bat` usa `%%~fsi`. Nesta
   bancada a geração 8.3 está **ligada** em `C:`. Num volume onde ela esteja desligada, `%%~fsi`
   devolve o caminho longo — **não testado aqui** (§7).
2. O caminho de teste tem **espaço** (`IMAN Terra`) e **funcionou** — a citação nos `.bat` do
   fornecedor dá conta.

- Evidência: `evidencia/env-limpo.txt`, `evidencia/env-relocado-limpo.json`.

---

## 4. M1…M8 — asserções de PRODUTO

Todas rodaram sobre a **árvore crua** relocada em `%LOCALAPPDATA%`. A coluna **"se estivesse
quebrado"** é o requisito `C.2`: se a resposta fosse a mesma dos dois lados, não seria evidência —
e a §6 mostra as três asserções que **de fato viraram FAIL** quando a árvore foi quebrada.

| # | asserção | resultado | evidência | se estivesse quebrado, devolveria |
|---|---|---|---|---|
| **M1** | `qgis-ltr-bin.exe` relocado abre e chega na janela principal | **PASS** | janela em **4 s**; título `Proyecto sin título — QGIS`; com o perfil da marca, `IMAN Terra — powered by QGIS`; WorkingSet 321,6 MB · `shots/m1-janela-principal-relocado.png`, `evidencia/gui-m1.json`, `evidencia/estadoD-nenhum.json` | processo morre no boot, ou fica só na janela `QGIS3` (splash / caixa de erro) — foi o que aconteceu em §6 |
| **M2** | canvas renderiza vetor **e** raster | **PASS** | vetor 3 feições `EPSG:31984` válido, raster 200×200 3 bandas `EPSG:31984` provider `gdal`, `renderComplete` emitido, canvas **1545×953**, **8 cores distintas** · `shots/janela-cru.png`, `shots/canvas-cru.png` | `isValid()==False`, ou `renderComplete` nunca emitido (estoura por timeout), ou **1 cor distinta** = canvas em branco silencioso |
| **M3** | PROJ reprojeta para `EPSG:31984` **correto** | **PASS** | `EPSG:4674 (-38,5; -3,75) → (555519,856; 9585490,545)`; erro vs. oráculo **0,0003 m** (tolerância 1 m) · `evidencia/asserts-relocado-cru.json` | coordenada fora da tolerância, ou CRS inválido. **Limite declarado:** ver §4.1 |
| **M3b** | de qual diretório o PROJ leu os dados | **PASS** | `<RELOCADO>\share\proj` — dentro da árvore relocada. PROJ 9.8.1 | caminho apontando para fora da árvore, ou `DataDirError` |
| **M3c** | deslocamento de datum que **exige** `proj.db` | **PASS** | `SAD69 → SIRGAS2000` desloca **56,98 m** (dx −38,89 / dy −41,65) · idem oráculo | **0,00 m** — o PROJ cai em *ballpark* e devolve resultado **silenciosamente errado**. Foi medido em §6 |
| **M4** | GDAL abre GeoTIFF e lê o CRS | **PASS** | grava e reabre GeoTIFF: `authority=31984`, nome `SIRGAS 2000 / UTM zone 24S`, 16×16, min/max 42/42, **220 drivers**, GDAL 3.13.2 | `GetDriverByName('GTiff')` → `None`, ou `RuntimeError: Cannot find proj.db`. Medido em §6 |
| **M5** | PyQGIS importa `qgis.core` e instancia `QgsApplication` | **PASS** | `QGIS_VERSION=3.44.13-Solothurn`; `qgis.core` carregado de `<RELOCADO>\apps\qgis-ltr\python\qgis\core`; `python3.exe` da árvore relocada | `ImportError` / `DLL load failed` |
| **M6** | `iman_brand` carrega no perfil isolado | **PASS** | `iman_brand` em `qgis.utils.plugins`, instância `ImanBrandPlugin`; perfil em uso `...\_spike016\perfil\profiles\iman-distro`; título `[iman-distro]`; UI em pt-BR · `shots/janela-iman-distro.png` | ausente de `qgis.utils.plugins`. **Controle negativo medido:** no perfil `spike016-cru` (sem o plugin) o M6 deu **FAIL** — a asserção não é carimbo |
| **M7** | Processing roda um algoritmo nativo | **PASS** | `native:buffer(100 m)` → 1 feição, área **31.412,77 m²** (teórica 31.415,93; erro relativo 1×10⁻⁴); **747 algoritmos** registrados | `QgsProcessingException: algorithm not found`, ou área fora da tolerância |
| **M8** | não lê-para-escrita nem altera `%APPDATA%\QGIS` nem `C:\Program Files\QGIS*` | **PASS** | rodada limpa: `%APPDATA%\QGIS` **539 arquivos, +0 −0 ~0** (SHA-256 por arquivo); `C:\Program Files\QGIS 3.44.13` **38.238 arquivos, +0 −0 ~0**; ARP 2 → 2 · `evidencia/footprint-RESUMO.json` | qualquer arquivo adicionado, removido ou alterado; ou entrada nova na ARP |

**Placar: 8 de 8 com evidência** (M3b e M3c são reforços de M3, não asserções extras do briefing).

### 4.1 O oráculo, e por que M3 sozinho não bastava

O valor esperado de M3 **não foi inventado**. Ele foi medido no **QGIS 3.44.13 instalado** desta
bancada (`evidencia/asserts-instalado.json`) e conferido de forma independente contra a série de
Transverse Mercator (GRS80, k0=0,9996) — que dá E ≈ 555.519,4 / N ≈ 9.585.497, dentro de ~7 m da
série truncada à mão. Um erro de datum ou de zona erra por centenas de metros a quilômetros, ordens
de grandeza acima dessa folga.

**A primeira versão do M3 estava fraca, e o estado D provou isso.** Com `share\proj` renomeado, o
M3 **continuou PASSANDO** — `EPSG:4674 → EPSG:31984` é uma UTM simples que o QGIS resolve pelo
próprio `srs.db`, sem consultar o `proj.db`. Foi por isso que o **M3c** foi acrescentado: um
deslocamento de datum, que vive no `proj.db`, e cujo modo de falha é devolver **0,00 m** — resultado
errado e silencioso, exatamente o que o briefing manda caçar.

**Limite que fica declarado:** se o PROJ relocado lesse o `share\proj` de outra instalação da
**mesma** versão, o número sairia igual e o M3 passaria. Quem pega esse vazamento é o **M3b**, não o
M3.

### 4.2 Comparação lado a lado — relocado × instalado

| | instalado (oráculo) | **relocado cru** | relocado sob contaminação (estado C) |
|---|---|---|---|
| placar | 6 de 6 PASS | **6 de 6 PASS** | **6 de 6 PASS** |
| `EPSG:31984` E, N | 555519,856 · 9585490,545 | **idem** | **idem** |
| SAD69→SIRGAS2000 | 56,98 m | **56,98 m** | **56,98 m** |
| GDAL drivers | 220 | **220** | **220** |
| algoritmos Processing | 747 | **747** | **747** |
| diretório do PROJ | `C:\PROGRA~1\...\share\proj` | **`<RELOCADO>\share\proj`** | **`<RELOCADO>\share\proj`** |

---

## 5. Matriz de estados do mundo

| estado | resultado | como foi medido |
|---|---|---|
| **A** — máquina sem QGIS nenhum | **N/E — NÃO MEDIDO** | ver §5.1 |
| **B** — bancada com QGIS 3.44.13 instalado | **PASS** | §5.3 |
| **C** — versão divergente / ambiente contaminado | **PASS com nota** | §5.2 |
| **D** — árvore incompleta | **PARCIAL — falha alta em 1 de 3 casos** | §6 |

### 5.1 Estado A — não medido, e por quê

Esta bancada **tem** o QGIS 3.44.13 instalado, e é a máquina do sponsor. Obter o estado A exigiria
**desinstalá-lo** — destrutivo, e a decisão não é da crew (`S.5` do briefing, e `BL-3`). Não há VM
nem sandbox disponível aqui. **Declarado não medido. Não simulado.**

**O que foi medido no lugar, e é o mais próximo honesto:** com o processo relocado vivo, a
procedência de **todos** os módulos carregados (`tools/spike016/Assert-ProcedenciaModulos.ps1`):

```
total de modulos carregados      : 355
da ARVORE RELOCADA               : 239
do Windows (system32, drivers)   : 116
de OUTRO QGIS (Program Files)    : 0
de outro lugar qualquer          : 0
```

**Zero DLLs da instalação de terceiro.** Isso fecha a forma mais provável de o estado A falhar — o
relocado se apoiar nos binários do vizinho. **Não substitui o estado A:** uma dependência que só
apareça quando o outro QGIS some (uma chave de registro compartilhada, uma entrada no `PATH` de
sistema, um runtime redistribuível instalado pelo outro pacote) **não seria vista aqui**.

- Evidência: `evidencia/procedencia-modulos.json`.

### 5.2 Estado C — ambiente contaminado por outra instalação

Injetamos, **antes** de chamar os `.bat` da árvore, o ambiente completo de outro QGIS
(`OSGEO4W_ROOT`, `PROJ_DATA`, `PROJ_LIB`, `GDAL_DATA`, `PYTHONHOME`, `PYTHONPATH`, `QT_PLUGIN_PATH`,
`QGIS_PREFIX_PATH`, `GISBASE`, `PATH`), apontando para `C:\Program Files\QGIS 3.44.13`.

**Resultado: 6 de 6 PASS**, e todas as variáveis foram sobrescritas pela árvore relocada — **exceto
uma**:

```
PROJ_LIB = C:\Program Files\QGIS 3.44.13\share\proj     <-- SOBREVIVEU
```

`PROJ_LIB` sobrevive porque **nenhum `.bat` do OSGeo4W a define** (§1.2) — não há o que sobrescrever.
**Medido: o vazamento é inerte.** O M3b confirma que o PROJ 9.8.1 usou
`<RELOCADO>\share\proj`, porque `PROJ_DATA` (que a árvore define) tem precedência sobre a
`PROJ_LIB` legada. **Nota para o instalador:** é inerte *nesta versão do PROJ*. Limpar `PROJ_LIB`
explicitamente antes de subir o QGIS custa uma linha e remove a dependência dessa precedência.

- Evidência: `evidencia/env-contaminado.txt`, `evidencia/asserts-relocado-estadoC.json`.

### 5.3 Estado B — a instalação de terceiro não é usada nem alterada

| pergunta | resposta medida |
|---|---|
| o relocado usa o **dele**? | sim — 239 módulos da árvore relocada, **0** da instalada (§5.1); `qgis.core` carregado de `<RELOCADO>`; PROJ e GDAL de `<RELOCADO>` |
| o relocado **altera** o instalado? | **não** — `C:\Program Files\QGIS 3.44.13`: 38.238 arquivos, **+0 −0 ~0** (M8) |
| aparece produto novo na ARP? | **não** — 2 entradas antes, as **mesmas** 2 depois |

### 5.4 M8 — e o falso positivo que o próprio instrumento produziu

**A primeira rodada de M8 deu FAIL**, acusando 3 arquivos modificados em
`%APPDATA%\QGIS\QGIS3\profiles\default`: `qgis-auth.db`, `symbology-style.db`, `user-history.db`.

**Era defeito do instrumento, não do relocado.** Os três arquivos estão **byte a byte idênticos** —
mesmo tamanho, mesmo `LastWriteTimeUtc` (`2026-08-31T12:31`, **seis dias antes** deste spike). O que
mudou foi que, na captura "antes", eles estavam **abertos por outro processo**, o `Get-FileHash`
falhou, e o script gravava a string `'ERRO'` como se fosse um hash. Comparada contra o hash real da
captura seguinte, `'ERRO' ≠ <hash>` virava "modificado".

Corrigido em `Snapshot-Footprint.ps1`: hash indisponível agora é `$null` + `HashObtido=$false`, e a
comparação **só usa hash quando ele existe dos dois lados**, caindo para tamanho + mtime e
**reportando** quantos arquivos ficaram sem hash. Depois disso foi rodada uma **rodada limpa
completa** — baseline novo → GUI + headless sobre o relocado → captura final → comparação:

```
[PASS] AppDataQgis       baseline 539 arquivos    ->  +0 / -0 / ~0
[PASS] ProgramFilesQgis  baseline 38238 arquivos  ->  +0 / -0 / ~0
       nota: assercao por tamanho + data de modificacao (SHA-256 nao aplicado a 38238 arquivos por custo)
[PASS] Arp               2 entradas antes / 2 depois
M8 = PASS
```

**Limite declarado:** em `C:\Program Files\QGIS*` a asserção é (tamanho, mtime), não SHA-256 — 38 mil
arquivos / 2,24 GB de hash a cada captura não cabia no timebox. Uma escrita que preservasse tamanho
**e** mtime passaria despercebida. Em `%APPDATA%\QGIS` (539 arquivos) o SHA-256 **é** calculado.

### 5.5 Validação de baseline (E.1) — feita antes de asserir

O `Snapshot-Footprint.ps1` **aborta com exit 2** e manda refazer se qualquer área declarada vier
vazia. Baseline desta rodada:

```
1) C:\Users\Francisco\AppData\Roaming\QGIS      539 arquivos / 7,61 MB
2) C:\Program Files\QGIS 3.44.13              38238 arquivos / 2,242 GB
3) ARP: QGIS 3.44.13 'Solothurn' [3.44.13] · IMAN Terra [0.3.0]
E.1 BASELINE VALIDO - todas as areas > 0
```

Critério numérico: `TotalArquivos > 0` nas duas árvores **e** `≥ 1` entrada na ARP. A guarda roda
**de novo** no `-Comparar`, sobre o JSON gravado — um baseline degenerado não consegue produzir um
`PASS` de M8 nem por acidente.

---

## 6. Estado D — árvore incompleta: a ressalva do veredito

Quebramos a árvore de propósito, de forma reversível (renomear diretório, com `try/finally` que
**sempre** restaura), e medimos o que o usuário veria. Sem screenshot: nesta bancada a captura por
tela pegou a janela de **outro instalador** que estava em primeiro plano, então a evidência aqui é
**processo e janela** (classe + título de todas as janelas visíveis do PID), que não depende de
z-order.

| o que foi removido | chega na janela principal? | o que aparece | `stderr` | veredito D |
|---|---|---|---|---|
| *(nada — controle)* | **sim** | `Qt51513QWindowIcon \| IMAN Terra — powered by QGIS` | vazio | referência |
| **`apps\qt5\plugins`** | **NÃO** | `#32770 \| QGIS3` — classe `#32770` é **caixa de diálogo Win32 nativa** (MessageBox) | vazio | **falha alta e visível** ✔ |
| **`share\proj`** | **sim** | janela principal **+** uma segunda janela `QGIS3` | `Cannot find proj.db` ×4 + `proj_crs_get_coordinate_system: Object is not a SingleCRS` | **parcial** — grita no `stderr` e abre diálogo, mas o app abre |
| **`apps\qgis-ltr\resources`** | **sim** | `IMAN Terra — powered by QGIS`, aparentemente normal | **vazio** | **SILENCIOSO** ✘ |

> **É esta linha que rebaixa o veredito de `VIÁVEL` para `VIÁVEL COM RESSALVA`.** Com
> `apps\qgis-ltr\resources` faltando, o QGIS relocado **abre com cara de saudável e não diz nada**.
> Uma extração truncada, um antivírus que come um diretório, um disco cheio no meio da instalação —
> e o produto entrega uma janela bonita sobre um runtime incompleto.
>
> **Consequência para a via A1 (a crew relata, não arbitra):** o instalador precisa de uma
> verificação de integridade própria da árvore extraída — contagem de arquivos, ou manifesto com
> hash dos diretórios críticos — porque **o QGIS não vai avisar por nós**. Isso não estava previsto
> no briefing e não é decisão da crew.

E, no headless, o mesmo `share\proj` ausente produz a queda de placar que prova a sensibilidade das
asserções (§4):

```
árvore íntegra   : PLACAR 6 de 6 PASS
share\proj ausente: PLACAR 3 de 6 PASS
   M3b FAIL  pyproj.exceptions.DataDirError: Valid PROJ data directory not found
   M3c FAIL  deslocamento 0.00 m  (era 56,98 m)   <-- resultado errado e SILENCIOSO
   M4  FAIL  RuntimeError: PROJ: proj_create_from_database: Cannot find proj.db
   M3  PASS  <-- insensível a este defeito; ver §4.1
```

- Evidência: `evidencia/estadoD-*.json`, `evidencia/estadoD-proj-stderr.txt`,
  `evidencia/asserts-relocado-estadoD.json`.

---

## 7. O que este spike NÃO testou

1. **O estado A — máquina sem QGIS nenhum.** O mais importante, e o que esta bancada não tem.
   Obtê-lo exigiria desinstalar o QGIS do sponsor (`S.5` proíbe). §5.1 mede a aproximação mais
   próxima (0 módulos do vizinho), que **não** é substituto.
2. **Versões de Windows.** Só **Windows 11 Pro 10.0.26200**, uma máquina, um usuário
   (`Francisco`, sem espaço no nome), locale misto (UI do sistema em espanhol). Windows 10, contas
   com espaço no nome, perfis roaming, contas sem privilégio de escrita em `%LOCALAPPDATA%`:
   nada disso foi tocado.
3. **Geração de nomes 8.3 desligada.** O `o4w_env.bat` depende de `%%~fsi`. Aqui a geração 8.3 está
   ligada em `C:`. Num volume com `fsutil 8dot3name` desabilitado, `%%~fsi` devolve o caminho longo
   — e caminho longo com espaço, em componente nativo, é justamente onde isso costuma quebrar.
   **Não medido.**
4. **GRASS.** `GISBASE` foi conferido como relativo e o bloco GRASS do `qgis-ltr.bat` foi executado,
   mas **nenhum algoritmo do GRASS rodou**. O `postinstall\grass.bat` roda `g.mkfontcap` e um
   `textreplace` no `fontcap` — não executados. Provider GRASS no Processing: **não medido**.
5. **SAGA, PDAL, OpenCL, GDAL com drivers proprietários** (ECW, MrSID, Oracle, MSSQL): não medidos.
6. **Plugins de terceiros** instalados pelo gerenciador de plugins, e o repositório de plugins
   (rede). Só o `iman_brand` bundlado foi exercitado.
7. **O `postinstall.bat` completo.** Deliberadamente não executado (§1.4). Os 85 arquivos `.tmpl`
   continuam sem substituição na árvore medida; as ferramentas de linha de comando do Python
   (`pip`, `gdal_calc`, `pyproj`, …) **não existem** na árvore crua e **não foram testadas**.
8. **`qgis_process` como CLI.** O Processing foi exercitado por `processing.run` dentro do PyQGIS
   (M7); o executável `qgis_process` **não** foi chamado.
9. **Atualização e desinstalação.** Substituir a árvore relocada por uma versão nova, e remover a
   árvore com o QGIS em uso (arquivos travados): não medidos.
10. **Perfil do usuário com QGIS aberto ao mesmo tempo.** O M8 mediu com o QGIS instalado **fechado**.
    Os dois rodando em paralelo — que é o caso real do estado B — não foi medido.
11. **Tempo de primeira abertura em disco frio** e impacto de antivírus sobre 37 mil arquivos em
    `%LOCALAPPDATA%`: não medidos.
12. **Assinatura de código.** Se a árvore relocada dispara SmartScreen/AppLocker ao rodar
    `qgis-ltr-bin.exe` de `%LOCALAPPDATA%` (onde políticas corporativas costumam bloquear execução):
    **não medido**, e é risco real em prefeitura.

---

## 8. Custo medido da via A1

| grandeza | valor |
|---|---|
| payload MSI | 555,23 MB |
| árvore extraída | **2,232 GB · 37.338 arquivos** |
| tempo do `msiexec /a` | **300,1 s** nesta bancada |
| elevação exigida para extrair | **nenhuma** |
| escrita fora da árvore para rodar | **nenhuma** (§1.4, M8) |
| entrada na ARP criada pelo QGIS | **nenhuma** |

Comparação com a via A2, medida no `#010`: A2 instala **2,19 GB** em `C:\Program Files` **com
elevação**, cria entrada própria na ARP, e é o que produz a "sensação de outro produto sendo
instalado" que o sponsor relatou. **A1 custa aproximadamente o mesmo disco (2,23 GB), sem elevação e
sem segundo produto visível.**

---

## 9. Como reproduzir

```powershell
cd tools\spike016

# 1) monta a arvore relocada a partir do payload (nao instala, nao eleva)
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-QgisRelocado.ps1 -PularPostInstall -Limpar

# 2) linha de base ANTES (aborta com exit 2 se degenerar - E.1)
powershell -NoProfile -ExecutionPolicy Bypass -File .\Snapshot-Footprint.ps1 -Rotulo antes

# 3) ambiente montado pelos .bat da propria arvore
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-QgisRelocado.ps1 -Modo Env
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-QgisRelocado.ps1 -Modo Env -Contaminar

# 4) M3 M3b M3c M4 M5 M7 (headless) - no relocado e no instalado, para comparar
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-QgisRelocado.ps1 -Modo Python `
    -Script .\asserts_pyqgis.py -Perfil spike016-cru -Rotulo relocado-cru `
    -SaidaJson evidencia\asserts-relocado-cru.json
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-QgisRelocado.ps1 -Modo Python `
    -Raiz "C:\Program Files\QGIS 3.44.13" -Script .\asserts_pyqgis.py `
    -Perfil spike016-oraculo -Rotulo instalado-oraculo -SaidaJson evidencia\asserts-instalado.json

# 5) M1 M2 M6 (GUI) - gera os dados com o GDAL da propria arvore, depois abre
$env:SPIKE016_DADOS = "$env:LOCALAPPDATA\InstitutoIMAN\_spike016\dados"
$env:SPIKE016_SAIDA = "$env:SPIKE016_DADOS\m2-m6.json"
$env:SPIKE016_TAG   = 'cru'
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-QgisRelocado.ps1 -Modo Python -Script .\gera_dados.py
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-QgisRelocado.ps1 -Modo Gui `
    -Perfil spike016-cru -Codigo (Resolve-Path .\m2_m6_canvas.py).Path

# 6) procedencia dos modulos (aproximacao do estado A), com o QGIS relocado vivo
powershell -NoProfile -ExecutionPolicy Bypass -File .\Assert-ProcedenciaModulos.ps1 -ProcId <PID>

# 7) estado D - quebra reversivel; o try/finally SEMPRE restaura
foreach ($q in 'nenhum','qt-plugins','qgis-resources','proj') {
  powershell -NoProfile -ExecutionPolicy Bypass -File .\Assert-EstadoD.ps1 -Quebrar $q
}

# 8) linha de base DEPOIS e o veredito do M8
powershell -NoProfile -ExecutionPolicy Bypass -File .\Snapshot-Footprint.ps1 -Rotulo depois
powershell -NoProfile -ExecutionPolicy Bypass -File .\Snapshot-Footprint.ps1 -Comparar
```

**Limpeza** — a árvore de teste ocupa 2,23 GB e ficou no disco de propósito, para inspeção:

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\InstitutoIMAN\_spike016"
```

### Evidência versionada, e o que ficou de fora

`evidencia/` traz os JSON/TXT das medições e 4 PNGs (551 KB no total). **Não versionados** (DB-5),
com a receita para regerar em §9:

- `msiexec-admin-install.log` — 86,7 MB / 209.462 linhas. Versionado como
  `msiexec-admin-install.RESUMO.log` (110 linhas relevantes).
- `footprint-antes.json` / `footprint-depois.json` — ~6 MB cada (manifesto de 38.777 arquivos).
  Versionado como `footprint-RESUMO.json`.
- `tools/spike016/evidencia/` inteiro está no `.gitignore`; `docs/verify/016-.../evidencia/` é a
  cópia curada.

**Duas capturas de tela foram descartadas de propósito:** ambas retrataram a janela de **outro
instalador** que estava em primeiro plano na bancada, não o QGIS. Guardá-las seria evidência
enganosa. Os PNGs que ficaram são todos capturados **pelo lado do Qt**
(`iface.mainWindow().grab()`), que não depende de quem está na frente.

---

## 10. O que fica para o arquiteto decidir (a crew não arbitra)

1. **Verificação de integridade da árvore** — §6 mostra que uma árvore incompleta pode abrir
   silenciosamente. Manifesto com hash? Contagem de arquivos? Qual o custo aceitável no
   instalador? **Não decidido aqui.**
2. **A rodada do estado A** continua devendo. Ela precisa de VM ou de outra máquina — é a mesma VM
   que o `BL-7` já exige.
3. **`PROJ_LIB`** — limpar explicitamente antes de subir o QGIS, ou confiar na precedência de
   `PROJ_DATA`? Hoje é inerte (§5.2), mas por conta do PROJ, não por conta nossa.
4. **O resíduo de 8,57 MB** que o `/a` deixa (cópia do MSI sem cabs) — apagar depois de extrair?
5. **`find_in_root` / DB-14 / DB-20 no launcher** — com A1 o caminho do QGIS passa a ser conhecido e
   próprio. O código de detecção vira fallback ou código morto. **Fora do escopo deste spike, e
   deliberadamente não tocado.**
6. **Execução a partir de `%LOCALAPPDATA%`** em máquina com política corporativa de bloqueio
   (item 12 da §7) — risco real no público-alvo, não medido.

---

**Nada foi instalado, alterado ou removido nesta máquina.** Após todas as medições:
`C:\Program Files\QGIS 3.44.13` intacto (38.238 arquivos, +0 −0 ~0), `%APPDATA%\QGIS` intacto
(539 arquivos, +0 −0 ~0), ARP com as mesmas 2 entradas, nenhum processo `qgis-ltr-bin` órfão.
A árvore relocada de teste vive em `%LOCALAPPDATA%\InstitutoIMAN\_spike016\` e pode ser apagada.
