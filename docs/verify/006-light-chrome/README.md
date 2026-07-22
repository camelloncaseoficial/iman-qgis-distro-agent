# Evidência — fatia #008 (light-chrome)

Capturado em **2026-07-22** na bancada do dev: Windows 11 Pro, **QGIS LTR 3.44.9** standalone,
1920×1080 @ 100%, **perfil isolado RESETADO** (`%APPDATA%\InstitutoIMAN\IMAN Terra` apagado antes,
para o template novo ser copiado de fato).

| Arquivo | O quê |
|---|---|
| `00-antes-dark-chrome-006.png` | **ANTES** — QSS do `develop` (dark-chrome do #006) |
| `01-home-launcher-perfil-resetado.png` | **DEPOIS** — aberto pelo `app/launcher/IMAN-Terra.bat` |
| `02-ciclo-1-home.png` | ciclo, estado 1: HOME |
| `03-ciclo-2-canvas.png` | ciclo, estado 2: canvas (projeto demo aberto) |
| `04-ciclo-3-home-de-novo.png` | ciclo, estado 3: HOME de novo (Projeto → Novo) |
| `05-comp-TerraWindow-servido-http.jpg` | o comp `docs/TerraWindow.dc.html` **servido por HTTP** |

## Como foi capturado (e o que isso vale)

- **`01`** veio do **composition root real**: `IMAN-Terra.bat` → detecta o QGIS → cria o perfil
  isolado → `--profile/--profiles-path/--code`. É o que o usuário executa.
- **`02`–`04`** vieram de uma execução **instrumentada**: o mesmo `iman_startup.py` roda de
  verdade e, por timer, dispara as **mesmas ações do usuário** — `iface.addProject(welcome.qgz)`
  e `iface.newProject()`. Exercita o código real do #006 (`dashboard.py` / `iman_brand.py`,
  ambos **inalterados** por esta fatia). O script de instrumentação vive no scratchpad e **não**
  entra no repo.
- As imagens do QGIS usam `PrintWindow` / `QWidget.grab()`: fotografam **a própria janela**.
  Não leem a tela — não capturam nada de outra janela aberta na máquina.
- **`05`** foi servido por `python -m http.server` a partir de `docs/`, junto de `support.js` e
  `docs/assets/`. Aberto solto (`file://`) o comp carrega **sem estilo** e engana a comparação.

## Leitura do antes/depois

| Superfície | Antes (#006) | Depois (#008) |
|---|---|---|
| Barra de status | verde profundo `#103D29`, texto claro | clara `#F5F7F2`, texto `#5E6A61` |
| Título de dock ("Camadas") | verde profundo, texto claro | claro `#F5F7F2`, texto verde `#155F3D` |
| Seleção na árvore de camadas | `#1E7A4D` com texto branco | verde pastel `#E4F0E8` / `#155F3D` |
| Barra de menus | **já aparecia clara** — ver ressalva | clara `#FFFFFF` |

> **Ressalva honesta.** No `00-antes`, a barra de menus **já estava clara**: nesta combinação
> (QGIS 3.44.9 + Qt no Windows 11) o `QMenuBar { background-color: … }` do QSS **não pegou** nem
> na versão dark-chrome do #006. Ou seja, parte do "escurecimento" da Fase 2 do #006 nunca chegou
> a acontecer nesta plataforma. A regra light-chrome agora **concorda** com o que a plataforma já
> fazia, em vez de brigar com ela — mas o mérito visível do antes/depois está na **status bar**,
> nos **títulos de dock** e na **seleção**, não no menubar.

## Comparação com o comp

No comp (`05`), a **única** região escura é a **barra de título** — que é carve-out **fork-only**
(spikes #003/#004): no no-fork quem desenha a barra de título é o Windows. Menubar branco,
painéis claros, HOME no miolo, verde como acento. É o que o `01` mostra.
