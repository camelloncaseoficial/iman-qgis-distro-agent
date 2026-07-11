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

## Marca real do IMAN (arte já no repo — feed da fatia /branding)

- Logo/arte institucional real em `docs/IMAN_fundo_branco.jpeg`,
  `docs/IMAN_fundo_verde.jpeg`, `docs/Splash.png` (já credita QGIS), `docs/icons/`.
- **Verde IMAN amostrado do logo = `#00A858`** (bem mais vivo que o placeholder antigo
  `#1F6F5C`). Paleta provisória em `docs/design-system.md` / `brand.py` (`COLOR_*`).
  STOP-AND-FLAG: hex exato e paleta completa oficiais aguardam o manual (`IMAN.cdr`).
- Assets do produto gerados dessa arte em `app/assets/` (logo, `.ico` 16–256 do
  emblema folha+globo). PIL disponível no `python` do sistema para gerar `.ico`.

## Git / GitHub

- Remote `origin`: `git@github.com:camelloncaseoficial/iman-qgis-distro-agent.git` (SSH).
- **`gh` CLI**: a conta com acesso ao repo é **`franciscocamellon`** (não `camello-stellar`).
  Se `gh` falhar com "Could not resolve to a Repository", rodar
  `gh auth switch --user franciscocamellon`.
