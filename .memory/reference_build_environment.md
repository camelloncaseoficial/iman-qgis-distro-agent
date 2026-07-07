# Referência — Ambiente de build/smoke local (máquina do dev)

Fatos não óbvios do ambiente onde a distro é montada/verificada. Confirmados na fatia 1
(2026-07-05). Complementa `reference_qgis_profile_and_packaging.md`.

## QGIS LTR (runtime)

- Instalado via **OSGeo4W**: `C:\OSGeo4W\bin\qgis-ltr-bin.exe` (e `qgis-bin.exe`).
  Prefix: `C:\OSGeo4W\apps\qgis-ltr`.
- **PyQGIS headless**: rodar scripts com `C:\OSGeo4W\bin\python-qgis-ltr.bat <script.py>`
  (seta o ambiente PyQGIS). Usado para gerar `welcome.qgz` e o smoke estático.
- Smoke GUI sem tocar o perfil do usuário: `qgis-ltr-bin.exe --profiles-path <TEMP>
  --profile iman-distro --code ... --project ...` e ler o título via
  PowerShell `(Get-Process qgis-ltr-bin).MainWindowTitle` (esperar ~12s p/ carregar).

## Instalador

- **Inno Setup 6.7.3** instalado via `winget install JRSoftware.InnoSetup`.
- Compilador: `C:\Users\Francisco\AppData\Local\Programs\Inno Setup 6\ISCC.exe`
  (NÃO em Program Files — winget instalou em AppData\Local\Programs).
- Build: `ISCC.exe installer\iman-terra.iss` → `installer/dist/*.exe`.

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
