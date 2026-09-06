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

## Executáveis do QGIS (detecção **na máquina do usuário**)

> Esta seção descreve o que o **launcher procura no PC de quem instala** — não é descrição da
> bancada do dev. Para a bancada, ver `reference_build_environment.md` (OSGeo4W foi removido
> dela em 2026-07-22; o QGIS local é standalone).

- Instalação standalone (caso comum hoje): `%ProgramFiles%\QGIS <versão>\bin\qgis-ltr-bin.exe`.
- Instalação via OSGeo4W (ainda possível no PC do usuário): `C:\OSGeo4W\bin\qgis-ltr-bin.exe`.
- O launcher detecta o primeiro disponível; se nenhum, orienta a instalar o QGIS LTR.
- **Baseline suportada: QGIS LTR 3.44.x** (ver `docs/distro-architecture.md`). A detecção é
  permissiva por glob `QGIS *` — versões fora da baseline abrem, mas não são verificadas.

## Instalador (Inno Setup)

- Script `.iss` em `installer/`; saída em `installer/dist/` (ex.: `Instituto-IMAN-<Produto>-Setup-<versão>.exe`).
- Empacotar `app/*` (launcher, startup, profile-template, demo, assets, notices).
- Atalhos (menu iniciar + opção desktop) com `.ico` de marca; incluir `LICENSE`, `THIRD_PARTY_NOTICES.md`, `README.md`.
- **Instalador leve:** exige QGIS LTR já instalado (orienta se ausente).
- **Instalador full:** embute o instalador oficial do QGIS LTR como dependência — usar só parâmetros
  silenciosos **testados** para a versão alvo.
- Uninstall limpo; perfil isolado não removido à toa; nunca mexer na instalação do QGIS.

## QGIS RELOCADO — cópia privada fora de Program Files (via A1)

> Medido no **spike #016** (2026-09-06, `docs/verify/016-spike-qgis-relocado/`). Veredito:
> **A1 VIÁVEL COM RESSALVA**, 8 de 8 asserções de produto com evidência.

- **A árvore do OSGeo4W já é relocável por construção.** `bin\o4w_env.bat` deriva
  `OSGEO4W_ROOT` de **`%~dp0`** (onde o arquivo *está*, não onde foi instalado) e **zera o
  `PATH` herdado** antes de montar o seu. Todo o `etc\ini\*.bat` (`PROJ_DATA`, `GDAL_DATA`,
  `GDAL_DRIVER_PATH`, `PYTHONHOME`, `PYTHONPATH`, `QT_PLUGIN_PATH`) e o `GISBASE` do GRASS são
  relativos a `%OSGEO4W_ROOT%`. **Nenhum carrega caminho gravado no install.**
- **`msiexec /a <msi> /qn TARGETDIR=<dir>` produz árvore EXECUTÁVEL e NÃO exige elevação**
  (log: `MSI_LUA: Credential prompt not required, administrative installation creation`).
  Exit `0`, ~300 s, **37.338 arquivos / 2,23 GB** para o `3.44.13`. A raiz do OSGeo4W fica em
  `TARGETDIR\QGIS <versão>\` — **um nível abaixo** do `TARGETDIR`. Sobra uma cópia do MSI sem
  os cabs (~8,6 MB) na raiz.
- **O caminho absoluto do install existe, mas está fora do caminho do QGIS Desktop.** São
  **85 arquivos `.tmpl`** em que o `textreplace` do `postinstall.bat` troca o token
  **`@osgeo4w@`** pela raiz absoluta: 80 entry points em `apps\Python312\Scripts\`, mais
  `qgis.reg`, `bin\setup.bat`, `bin\nc-config` e 2 templates do setuptools. **Nada disso é
  usado por GUI, canvas, PROJ, GDAL, PyQGIS, Processing ou plugins.**
- **Corolário: a instalação OFICIAL é que NÃO é relocável** — os 85 arquivos dela têm
  `C:\PROGRA~1\QGIS34~1.13` cravado. **Copiar `C:\Program Files\QGIS ...` é a via errada;
  extrair do MSI é a certa.**
- **Não é preciso rodar o `postinstall.bat`.** Ele escreve FORA da árvore (`regedit /s qgis.reg`
  em `HKCR`, `dllupdate -copy` no diretório do Windows, `xxmklink` no Menu Iniciar). Sem ele o
  QGIS abre e funciona — medido.
- **`PROJ_LIB` não é definida por nenhum `.bat` do OSGeo4W** (o QGIS 3.44 usa `PROJ_DATA`). É a
  **única** variável que sobrevive a um ambiente contaminado por outra instalação. Hoje é
  inerte (o `PROJ_DATA` vence no PROJ 9.8.1) — mas por conta do PROJ, não nossa. Limpar
  explicitamente antes de subir custa uma linha.
- **`OSGEO4W_ROOT` sai em forma 8.3** (`%%~fsi`). Caminho com espaço funciona. **Volume com
  geração 8.3 desligada: NÃO testado.**
- **⚠ RESSALVA — a árvore não se autodiagnostica.** Medido: sem `apps\qt5\plugins` a falha é
  alta e visível (diálogo Win32 `#32770`, não chega à janela principal); sem `share\proj` grita
  em `stderr` mas abre; **sem `apps\qgis-ltr\resources` o QGIS abre com cara de saudável e não
  diz nada.** Quem empacotar A1 precisa de **verificação de integridade própria** — o QGIS não
  avisa. STOP-AND-FLAG aberto com o arquiteto.
- **Estado A (máquina sem QGIS nenhum) continua NÃO MEDIDO** — a bancada tem QGIS instalado e
  desinstalá-lo é proibido. O que foi medido no lugar: o processo relocado carregou **355
  módulos, 0 da instalação de terceiro**. Não substitui o estado A.

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
