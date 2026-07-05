# Arquitetura da distro — IMAN QGIS Distro

Nasce de **D-IMAN-025**. Opção 1 (no-fork) primeiro; Opção 2 (fork) como norte futuro.
Referência de contexto: `../iman-product-architect/docs/instituto_iman_qgis_customizacao_contexto_claude.md`.

## Opção 1 — camada de branding sobre o QGIS LTR (MVP)

Entrega uma experiência muito customizada **sem recompilar** o QGIS: perfil isolado + tema + plugin
de marca + startup + launcher + instalador. Menor custo de manutenção, mais seguro juridicamente,
ideal para peça institucional.

### Árvore de pastas (alvo)

```text
iman-qgis-distro-agent/
├── app/
│   ├── launcher/            # abre o QGIS com o perfil isolado (.bat/exe)
│   ├── startup/             # startup PyQGIS (título da janela, painel inicial, demo)
│   ├── profile-template/
│   │   └── <perfil>/        # perfil QGIS isolado versionado
│   │       ├── QGIS/
│   │       ├── python/plugins/<plugin_de_marca>/
│   │       ├── processing/
│   │       ├── project_templates/
│   │       └── symbology-style.db
│   ├── demo/                # welcome.qgz
│   ├── assets/              # logo, ícone .ico, splash-preview (fonte única de marca)
│   └── notices/             # LICENSE, THIRD_PARTY_NOTICES.md, SOURCE_CODE.md
├── installer/               # *.iss (Inno Setup) + dist/
├── docs/                    # esta doc, branding/licença, design system, guias
└── packaging/               # [Opção 2, futuro] patches de fork, docs de build
```

### Componentes

1. **Perfil isolado** — interface simplificada, menus/toolbars, tema institucional, CRS default
   (SIRGAS 2000 / UTM da zona), idioma, projeto demo, templates/estilos. Carrega via
   `--profile/--profiles-path` em `%APPDATA%\InstitutoIMAN\<Produto>\...`. Nunca toca o perfil do usuário.
2. **Plugin de marca leve** (PyQGIS) — menu próprio, toolbar, painel de boas-vindas, botões para
   demo/docs/site, validador simples. APIs públicas do QGIS, sem dependência externa obrigatória.
   **Não** é o plugin REURB (bundle do REURB = fatia futura, D-IMAN-025).
3. **Startup script** — ajusta o título da janela ("<Produto> — powered by QGIS"), abre painel
   inicial, carrega demo. Leve; customização maior mora no plugin.
4. **Launcher** — detecta o QGIS LTR instalado, cria o perfil isolado no primeiro run, abre com o
   perfil/startup/demo. Se o QGIS não existe, orienta a instalar.
5. **Instalador Inno Setup** — empacota `app/*`, cria atalhos com `.ico` de marca, inclui notices;
   uninstall limpo. Ver `docs/design-system.md` para os tokens de marca.

## Opção 2 — fork/build do QGIS (futuro, só após Opção 1 validada)

Fork sobre release LTR, branch própria, patches por área (`packaging/patches/{branding,splash,icons,
about,startup-behavior}`), build CMake/OSGeo4W, instalador próprio, publicação de fonte e processo de
merge com upstream. Resolve o que o no-fork não alcança (splash nativo, ícone do executável, About,
nome interno). Documentado em `docs/BUILD_WINDOWS.md`/`RELEASE_PROCESS.md` quando a fatia entrar.

## Limites do no-fork (declarados, não hackeados)

| Alcançável sem fork | Só com fork (Opção 2) |
|---|---|
| Título da janela (startup) | Splash screen nativo |
| Tema/cores (QSS do perfil) | Ícone do `qgis-bin.exe` |
| Plugin de marca (menu/toolbar/painel) | About dialog nativo |
| Ícone + nome do atalho e do instalador | Nome interno da aplicação |
| Projeto demo, templates, notices | Remoção/alteração de core |
