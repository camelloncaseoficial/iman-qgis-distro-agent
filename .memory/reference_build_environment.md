# Referência — Ambiente de build/smoke local (máquina do dev)

Fatos não óbvios do ambiente onde a distro é montada/verificada. Complementa
`reference_qgis_profile_and_packaging.md`.

> **Re-verificado em 2026-07-22 (fatia #007).** Os caminhos anteriores (fatia 1, 2026-07-05)
> estavam **STALE nos três**: OSGeo4W foi REMOVIDO desta máquina e o usuário do Windows tem
> espaço no nome. Os caminhos abaixo foram conferidos no disco nesta data — se algum falhar,
> re-verificar e atualizar aqui, **não** "restaurar" a instrução velha.

## QGIS LTR (runtime)

- **`C:\OSGeo4W` NÃO EXISTE MAIS nesta máquina** (removido; confirmado 2026-07-22). Qualquer
  receita que comece por `C:\OSGeo4W\...` está morta aqui.
- O QGIS vivo é **standalone**: `C:\Program Files\QGIS 3.44.9\`
  - GUI: `C:\Program Files\QGIS 3.44.9\bin\qgis-ltr-bin.exe`
  - **PyQGIS headless**: `C:\Program Files\QGIS 3.44.9\bin\python-qgis-ltr.bat <script.py>`
    (a receita headless sobreviveu — só mudou de casa). Usado para gerar `welcome.qgz` e o
    smoke estático.
- **Baseline suportada declarada: QGIS LTR 3.44.x** (testada: 3.44.9) — ver
  `docs/distro-architecture.md`. O launcher aceita qualquer `QGIS *` que encontrar; isso é
  detecção permissiva, **não** promessa de compatibilidade.
- Smoke GUI sem tocar o perfil do usuário: `qgis-ltr-bin.exe --profiles-path <TEMP>
  --profile iman-distro --code ... --project ...` e ler o título via
  PowerShell `(Get-Process qgis-ltr-bin).MainWindowTitle` (esperar ~12s p/ carregar).

## Instalador

- **Inno Setup 6.7.3** — reinstalado em 2026-07-22 via
  `winget install --id JRSoftware.InnoSetup -e`.
- Compilador (caminho REAL, conferido):
  `C:\Users\Francisco Camello\AppData\Local\Programs\Inno Setup 6\ISCC.exe`
  — **com espaço** em "Francisco Camello" (a nota antiga dizia `C:\Users\Francisco\...` e
  estava errada) e **NÃO** em Program Files / Program Files (x86).
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
