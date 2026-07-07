# IMAN QGIS Distro Agent

Agente único (crew) para a **distribuição QGIS customizada com branding do Instituto IMAN** —
uma experiência geoespacial desktop *powered by QGIS*, distribuída gratuitamente como peça de
marketing técnico/institucional.

Consolida, no mesmo repositório: perfil QGIS isolado, tema visual, plugin de marca leve (PyQGIS),
startup script, launcher Windows, instalador Inno Setup e notices/licença.

> **Produto: `IMAN Terra`** — *powered by QGIS* (nome definido pelo sponsor 2026-07-05). A marca
> visível vem de fonte única no design system; rename futuro é find-replace. *(Este repo/crew é a
> fábrica da distro — "IMAN QGIS Distro Agent"; o produto que ela entrega é o **IMAN Terra**.)*

## Fases

- **Opção 1 (no-fork, MVP):** camada de branding sobre o QGIS LTR oficial + instalador `.exe`.
- **Opção 2 (fork/build, futuro):** fork do QGIS para o que só o core resolve (splash nativo,
  ícone do executável, About, nome interno) — só depois da Opção 1 validada.

Governada pelo PPSA (arquiteto) via briefings. Nasce de **D-IMAN-025**.

## Comandos principais

- `/start-session`
- `/status`
- `/branding`
- `/profile`
- `/packaging`
- `/license-check`
- `/plan`
- `/debug`
- `/refactor`
- `/memory`
- `/reset-memory`
- `/ship`

## Estrutura entregue (fatia 1 — fundação)

```text
app/
├── launcher/IMAN-Terra.bat          # detecta QGIS LTR, cria perfil isolado no 1º run, abre com startup+demo
├── startup/iman_startup.py          # título da janela + aplica tema; leve
├── profile-template/iman-distro/    # perfil QGIS ISOLADO versionado
│   ├── QGIS/QGIS3.ini               # pt-BR, CRS SIRGAS 2000 (EPSG:4674), autoload do plugin
│   ├── QGIS/iman-theme.qss          # tema institucional (QSS)
│   └── python/plugins/iman_brand/   # plugin de marca (menu/toolbar/dock de boas-vindas/Sobre)
├── demo/welcome.qgz                 # projeto demo (CRS 4674 + basemap OSM)
├── assets/                          # identidade oficial: símbolo/splash SVG/.ico/wizard (ver assets/README.md)
└── notices/                         # LICENSE, THIRD_PARTY_NOTICES.md, SOURCE_CODE.md
installer/iman-terra.iss             # Inno Setup (saída: installer/dist/*.exe)
```

## Build & execução

**Pré-requisito de runtime:** QGIS LTR instalado (OSGeo4W ou standalone). O instalador é *leve* —
não empacota o QGIS; o launcher orienta se o QGIS estiver ausente.

- **Rodar sem instalar:** dê duplo clique em `app/launcher/IMAN-Terra.bat` (cria o perfil isolado em
  `%APPDATA%\InstitutoIMAN\IMAN Terra\profiles\` no 1º uso e abre o QGIS com o branding).
- **Compilar o instalador:** `ISCC.exe installer\iman-terra.iss` → gera
  `installer/dist/Instituto-IMAN-IMAN-Terra-Setup-0.1.0.exe`.

## Smoke (verificação)

**Executado neste ambiente (dev, QGIS LTR via OSGeo4W):**

1. `py_compile` do plugin + startup — OK.
2. Smoke estático headless (PyQGIS): constantes de marca, import do plugin, `welcome.qgz` lê com
   **CRS EPSG:4674**, `QGIS3.ini` com autoload + pt-BR + CRS — **ALL PASS**.
3. Smoke GUI **verificado por screenshot** (perfil isolado em `--profiles-path` **temporário**,
   perfil do usuário intacto): título `IMAN Terra — powered by QGIS`, **ícone da janela = emblema
   IMAN**, **barra de menus e títulos de painel verdes** (tema), **plugin de marca ativo** (dock de
   boas-vindas com logo), **CRS EPSG:4674**, interface **pt-BR**, camada OSM do demo.
   > Convenção crítica do `--profiles-path`: o QGIS lê de `<root>\profiles\<perfil>`; passar o valor
   > já com `\profiles` no fim causa perfil vazio (bug encontrado e corrigido no launcher).
4. Instalador compila com sucesso (`.exe` em `installer/dist/`).

**Lacuna declarada (BL-7 — verdade em VM limpa):** o ciclo **instalar → abrir → perfil/branding/
plugin/demo → desinstalar limpo** numa **máquina Windows limpa** ainda não foi executado (sem VM
disponível). Passos numerados para reproduzir:

1. Copiar `installer/dist/Instituto-IMAN-IMAN-Terra-Setup-0.1.0.exe` para uma VM Windows 10/11 limpa
   **com QGIS LTR instalado**.
2. Instalar (usuário comum, sem admin) → conferir atalho no Menu Iniciar com o ícone IMAN.
3. Abrir pelo atalho → janela `IMAN Terra — powered by QGIS`, painel de boas-vindas, plugin ativo,
   "Sobre" com créditos do QGIS, `welcome.qgz` aberto.
4. Conferir que o **perfil/instalação do QGIS do usuário não foi tocado** (BL-3).
5. Desinstalar → `{app}` removido; **`%APPDATA%\InstitutoIMAN` preservado**; QGIS intacto.

## Limites conhecidos do no-fork (Opção 2, futuro — declarados, não hackeados)

| Alcançado nesta fatia (sem fork, verificado por screenshot) | Só com fork (Opção 2) |
|---|---|
| Título da janela (startup + plugin) | **Splash nativo de boot** ("QGIS x.y Bratislava LTR") |
| **Ícone da janela/taskbar** (emblema IMAN) | **Ícones de ação da toolbar** do QGIS |
| Tema/cores da UI (menubar/menus/status/docks/abas) | Ícone do executável `qgis-bin.exe` |
| Plugin de marca (menu/toolbar/painel/Sobre) | About dialog nativo |
| Ícone + nome do atalho e do instalador; CRS/idioma | Nome interno da aplicação |

> O ícone da janela e o tema são aplicados em runtime pelo startup/plugin. O **splash nativo** e os
> **ícones de ação** da toolbar são do core do QGIS (C++) e permanecem — trocá-los exige fork (Opção 2),
> documentado como limite, **não** contornado por hack frágil (ex.: um 2º splash sobreposto).

## Créditos

Esta é uma distribuição **independente** *powered by QGIS*. O QGIS é um sistema de informação
geográfica livre e de código aberto, desenvolvido por **QGIS.ORG** e contribuidores. Este projeto
**não** é um produto oficial do QGIS e **não** é endossado pela QGIS.ORG.
