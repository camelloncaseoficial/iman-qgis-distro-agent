# Referência — Ambiente de build/smoke local (máquina do dev)

Fatos não óbvios do ambiente onde a distro é montada/verificada. Complementa
`reference_qgis_profile_and_packaging.md`.

> **Re-verificado de novo em 2026-09-01 (fatia #013).** Três fatos mudaram desde 2026-07-22:
> o **Inno Setup 6 não existe mais** nesta máquina (só o **7.1.0**), o QGIS da bancada agora é
> **3.44.13** (e virou a baseline embarcada), e o usuário do Windows é `Francisco` — **sem**
> espaço. A nota de 2026-07-22 dizia `C:\Users\Francisco Camello\...` e estava errada.

> **Re-verificado em 2026-07-22 (fatia #007).** Os caminhos anteriores (fatia 1, 2026-07-05)
> estavam **STALE nos três**: OSGeo4W foi REMOVIDO desta máquina e o usuário do Windows tem
> espaço no nome. Os caminhos abaixo foram conferidos no disco nesta data — se algum falhar,
> re-verificar e atualizar aqui, **não** "restaurar" a instrução velha.

## QGIS LTR (runtime)

> **Re-verificado em 2026-09-09 (fatia #021): NÃO HÁ MAIS QGIS DE SISTEMA nesta bancada.**
> `C:\Program Files\QGIS *` não existe e não há entrada na ARP. O QGIS que a bancada usa é o
> **do produto instalado** — `%LOCALAPPDATA%\Programs\IMAN Terra\qgis\`. **Isso é a condição
> normal agora, não uma pane**: a `#021/Entrega 2` repontou o teste de aceite justamente para
> que a bancada **não precise voltar a ter** um QGIS instalado. Não "conserte" reinstalando.

- **`C:\OSGeo4W` NÃO EXISTE MAIS nesta máquina** (removido; confirmado 2026-07-22). Qualquer
  receita que comece por `C:\OSGeo4W\...` está morta aqui.
- ~~O QGIS vivo é standalone em `C:\Program Files\QGIS 3.44.13\`~~ — **sumiu na sessão do #019**
  (laudo em `docs/verify/019-a1-qgis-embarcado/README.md`, seção 6). Toda receita que comece por
  `C:\Program Files\QGIS ...` está **morta aqui**.
- **O QGIS de trabalho é o do produto**, e ele é relocável por construção:
  - GUI (o caminho REAL, o mesmo que o launcher usa):
    `%LOCALAPPDATA%\Programs\IMAN Terra\qgis\bin\qgis-ltr.bat`
    — **chamar o `.bat`, nunca o `.exe` direto**: é ele que roda o `o4w_env.bat`, que monta
    `PROJ_DATA`/`GDAL_DATA`/`PYTHONHOME`/`QT_PLUGIN_PATH` e **zera o `PATH` herdado**.
  - **PyQGIS headless**: `%LOCALAPPDATA%\Programs\IMAN Terra\qgis\bin\python-qgis-ltr.bat`.
  - `OSGEO4W_ROOT` sai em **forma 8.3** (`IMANTE~1`) — comparar caminhos por string sem
    normalizar dá falso negativo. Na sonda: `GetLongPathNameW`; no PowerShell:
    `Scripting.FileSystemObject.ShortPath` nos **dois** lados.
- **Teste de aceite:** `tools\branding-acceptance\Invoke-Aceite.ps1` sobe essa árvore e **recusa**
  qualquer raiz sob `%ProgramFiles%`. Ele exige o produto **instalado** — sem produto, aborta.
- **Build:** `installer\New-ArvoreQgis.ps1` exige o oposto — **nenhum** QGIS 3.44.13 instalado na
  máquina (a extração abre transação do Windows Installer contra o mesmo ProductCode). Hoje as
  duas exigências convivem porque nenhuma delas depende mais de um QGIS de sistema.
- **Baseline EMBARCADA: QGIS LTR 3.44.13** desde a fatia #013 (decisão do sponsor, 2026-09-01);
  a `3.44.13` **ainda não passou pela VM limpa** — a versão certificada é a que rodou o BL-7. Ver
  `docs/distro-architecture.md`. O launcher aceita qualquer `QGIS *` que encontrar; isso é
  detecção permissiva, **não** promessa de compatibilidade.
- Smoke GUI sem tocar o perfil do usuário: `qgis-ltr-bin.exe --profiles-path <TEMP>
  --profile iman-distro --code ... --project ...` e ler o título via
  PowerShell `(Get-Process qgis-ltr-bin).MainWindowTitle` (esperar ~12s p/ carregar).

## Instalador

- **Inno Setup 7.1.0**, e **NENHUM Inno 6** — conferido em 2026-09-01 nos três caminhos padrão,
  nas chaves ARP e no PATH. A nota anterior (6.7.3 em `C:\Users\Francisco Camello\...`) está
  **morta nos dois pontos**: a major e o caminho.
- Compilador (caminho REAL, conferido): `C:\Program Files\Inno Setup 7\ISCC.exe`
  — em **Program Files**, não em `LOCALAPPDATA\Programs`, e **o ISCC NÃO está no PATH**.
- O `build.ps1` aceita as majores **7 e 6**, com o **7 vencendo** quando as duas existem
  (`D-IMAN-030`). Major desconhecida é **recusa**, não aviso.
- **A versão do ISCC 7 não sai de `VersionInfo` (é `0.0.0.0`) nem do banner (só a major).**
  Sai da linha `Compiler engine version: Inno Setup 7.1.0`, que o ISCC imprime ao compilar
  **sem `/Q`**. Detalhe medido em `docs/verify/013-inno7-toolchain/README.md`.
- O ISCC 7 imprime **`Non-commercial use only`** em todo build. STOP-AND-FLAG de licenciamento
  aberto com o sponsor — não é decisão da crew.
- Build: **não chamar o ISCC na mão.** Usar `installer\build.ps1`, que localiza o ISCC,
  recusa árvore suja/branch errada e emite `installer/dist/BUILD_INFO.txt` amarrando
  artefato ↔ commit ↔ versão ↔ SHA-256.

## PowerShell

- Bancada do dev: **PowerShell 5.1** (`5.1.26100.x`).
- Alvo da VM limpa do BL-7: **PowerShell 5.1 e nada mais** — sem Python, sem Git, sem
  OSGeo4W, sem admin, sem módulos de terceiros. Helpers em `tools/bl7/` respeitam isso.

## Marca oficial do IMAN (drop do sponsor 2026-07-06, ingerido na fatia 002)

- Fonte única de asset em **`app/assets/`** (não mais solta em `docs/`): masters
  `splash-iman-terra.svg` (vetor, fonte da paleta), `iman-symbol.png` (símbolo),
  `logo-iman.png`, `backgrounds/bg-iman-{branco,verde}.jpeg`. Proveniência e receita de
  regeneração em `app/assets/README.md`. (`docs/icons/` = favicons web, fora de escopo.)
- **Paleta OFICIAL travada** (fatia 002), extraída do SVG e reconciliada — `design-system.md`
  == `brand.py`: `primary #00A85A`, `primary-deep #0D5138`, `ink/text #041C16`,
  `accent #2CA8E0`, `mint #5FE0A0`, `warm #C56A2F`, `surface #F2F8F3`. Placeholders `#1F6F5C…`
  e a amostra de JPEG `#00A858` foram eliminados. STOP-AND-FLAG: o manual `IMAN.cdr`, se
  chegar, prevalece sobre o SVG (arte derivada).
- Ícones (`.ico` 16–256, `icon-iman-terra.png`, `resources/icon.png`) **regerados do símbolo
  oficial**, transparentes; wizard do instalador (`wizard-large/small.png`) idem. PIL
  (Pillow) disponível no `python` do sistema. Sem rasterizador de SVG (cairosvg/inkscape/
  rsvg/magick ausentes) — o PNG do splash veio do raster oficial hi-res, não do SVG.

## Git / GitHub

- Remote `origin`: `git@github.com:camelloncaseoficial/iman-qgis-distro-agent.git` (SSH).
- **`gh` CLI**: a conta com acesso ao repo é **`franciscocamellon`** (não `camello-stellar`).
  Se `gh` falhar com "Could not resolve to a Repository", rodar
  `gh auth switch --user franciscocamellon`.
