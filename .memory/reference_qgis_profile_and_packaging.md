# Referência — Perfil QGIS, launcher e empacotamento (Windows)

## Perfil QGIS no Windows

- Perfis do usuário ficam em `%AppData%\Roaming\QGIS\QGIS3\profiles\`.
- A distro usa perfil **isolado** (não o do usuário): carregar via
  `qgis-ltr-bin.exe --profile <perfil> --profiles-path "%APPDATA%\InstitutoIMAN\<Produto>"`.
- **ATENÇÃO (bug real na fatia 1, corrigido):** o QGIS **acrescenta `profiles\`** ao valor de
  `--profiles-path`. Ou seja, `--profiles-path X --profile Y` lê de **`X\profiles\Y`**. Passar
  `...\<Produto>\profiles` faz o QGIS procurar em `...\profiles\profiles\Y` → **perfil vazio**
  (plugin não carrega, tema/CRS não aplicam). Correto: `--profiles-path "...\<Produto>"` e o perfil
  copiado para `...\<Produto>\profiles\<perfil>`.
- O perfil-template versionado vive em `app/profile-template/<perfil>/` e é copiado para
  `<profiles-root>\profiles\<perfil>` no primeiro run (launcher/instalador) — `xcopy /E /I /Y`.
- Startup script via `--code <script.py>`; projeto demo via `--project welcome.qgz`;
  `--noversioncheck` para não poluir a primeira abertura.

## Executáveis do QGIS (detecção)

- OSGeo4W: `C:\OSGeo4W\bin\qgis-ltr-bin.exe` (ou `qgis-bin.exe`).
- Instalação standalone: `%ProgramFiles%\QGIS <versão>\bin\qgis-ltr-bin.exe`.
- O launcher detecta o primeiro disponível; se nenhum, orienta a instalar o QGIS LTR.

## Instalador (Inno Setup)

- Script `.iss` em `installer/`; saída em `installer/dist/` (ex.: `Instituto-IMAN-<Produto>-Setup-<versão>.exe`).
- Empacotar `app/*` (launcher, startup, profile-template, demo, assets, notices).
- Atalhos (menu iniciar + opção desktop) com `.ico` de marca; incluir `LICENSE`, `THIRD_PARTY_NOTICES.md`, `README.md`.
- **Instalador leve:** exige QGIS LTR já instalado (orienta se ausente).
- **Instalador full:** embute o instalador oficial do QGIS LTR como dependência — usar só parâmetros
  silenciosos **testados** para a versão alvo.
- Uninstall limpo; perfil isolado não removido à toa; nunca mexer na instalação do QGIS.

## Limites do no-fork (só a Opção 2 / fork resolve)

- ~~Splash screen nativo de boot — só com fork~~ **CORRIGIDO pelo spike #004 (D-IMAN-027):**
  o splash nativo **É re-brandável no-fork** via customização do perfil. O QGIS lê
  `QgsCustomization::splashPath()` + `"splash.png"` de `<perfil>/QGIS/QGISCUSTOMIZATION3.ini`
  (`[Customization] splashpath=<dir>/`) com `UI/Customization/enabled=true` no `QGIS3.ini`.
  O QSplashScreen **nativo** renderiza a imagem IMAN (comprovado por screenshot de boot).
  Não é hack/2º-splash: é o próprio splash nativo apontado para o asset do perfil isolado.
  Ver `spike/004-branding-posbuild/REPORT.md`.
- **Ícones de ação da toolbar** do QGIS (baked no core).
- Ícone real do executável (`qgis-bin.exe`).
- About dialog nativo.
- Nome interno da aplicação.

Alcançável **sem** fork (verificado por screenshot na fatia 1): título da janela (startup),
**ícone da janela/taskbar** (`mainWindow().setWindowIcon`, no startup), tema/cores da UI Qt
(QSS anexado ao stylesheet do QGIS: menubar/menus/status/títulos de dock/abas), plugin de marca
(menu/toolbar/painel), ícone+nome do atalho e do instalador, demo, CRS/idioma, notices.

## Referência de contexto

Doc do arquiteto: `../iman-product-architect/docs/instituto_iman_qgis_customizacao_contexto_claude.md`
(Opção 1 vs. Opção 2, árvore de pastas, exemplos de `.bat`/`.iss`/plugin mínimo). Adaptado à nossa
realidade em D-IMAN-025.
