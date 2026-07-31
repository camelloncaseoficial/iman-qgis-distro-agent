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
│   ├── assets/              # símbolo/logo/.ico/splash oficial (fonte única de marca; ver assets/README.md)
│   └── notices/             # LICENSE, THIRD_PARTY_NOTICES.md, SOURCE_CODE.md
├── installer/               # *.iss (Inno Setup) + dist/ + payload/ (MSI do QGIS, fora do git)
├── docs/                    # esta doc, branding/licença, design system, guias
└── packaging/               # [Opção 2, futuro] patches de fork, docs de build
```

### Versão do QGIS: EMBARCADA, não mais "exigida" (`D-IMAN-028`)

> **Mudou na fatia #011.** Até a 0.2.0 o instalador era **leve**: exigia o QGIS LTR já instalado e
> o launcher orientava se não achasse. A partir da 0.3.0 o instalador **embarca o MSI oficial do
> QGIS e o instala** (via **A2a**, offline). **Não é fork** (`D-IMAN-028`/DB-1): o binário oficial
> é redistribuído **sem modificação**.

| | |
|---|---|
| **QGIS embarcado** | **3.44.9** (`QGIS-OSGeo4W-3.44.9-1.msi`, 541,14 MB) |
| Fonte única | `#define QgisBaselineVersion` em `installer/iman-terra.iss` |
| Espelhos que mudam **junto** | `QgisProductCode` (bloco `[Code]` do `.iss`) · `set QGIS_VERSION` (`app/launcher/IMAN-Terra.bat`) · `$PayloadHashes` (`installer/build.ps1`) |
| Versões **não verificadas** | 3.28 LTR, 3.34 LTR, 3.40 LTR, 3.44.x ≠ 3.44.9, e qualquer release não-LTR |

O `#define QgisBaselineVersion` **mudou de sentido** (`D-IMAN-028`/DB-12): era "versão suportada
declarada", agora é **a versão que o pacote instala**. O `build.ps1` recusa compilar se o `.iss` e o
launcher divergirem, e recusa uma versão cujo SHA-256 oficial não esteja registrado — trocar a
versão embarcada é **decisão de produto**, não do build.

**Coexistência, não atualização** (`D-IMAN-028`/DB-13). O MSI oficial **não tem `Upgrade` table nem
`FindRelatedProducts`** (medido no spike #010): ele **nunca procura** outra versão do QGIS. Cada
versão tem `ProductCode` **e** `UpgradeCode` próprios — até entre patches da mesma minor (3.44.9 ×
3.44.12). Consequência: numa máquina que já tem QGIS, o nosso payload **instala lado a lado** e a
instalação de terceiro fica **intacta**. Isso é bom para o BL-3 e é o comportamento do instalador
oficial, não uma escolha nossa.

**Quem resolve a ambiguidade é o launcher** (`D-IMAN-028`/DB-14). Com coexistência, "qual QGIS
abrir?" passa a ter mais de uma resposta. O launcher prefere, nesta ordem: (1) `%QGIS_BIN%`, se
definido; (2) o **caminho exato do payload** (`%ProgramFiles%\QGIS <versão embarcada>`); (3) mesma
minor (`QGIS 3.44*`); (4) OSGeo4W; (5) qualquer `QGIS *`, como último recurso.

> ⚠ Os níveis 3 a 5 são **detecção permissiva, não promessa de compatibilidade**: QSS e o dashboard
> da HOME podem **degradar em silêncio** noutra série (seletores Qt e nomes de objeto mudam entre
> séries). O nível 5 usa `for /d`, cuja ordem é **alfabética por texto** — `QGIS 3.44.12` vem antes
> de `QGIS 3.44.9` porque `'1' < '9'`. Foi exatamente esse detalhe que fez o launcher abrir a versão
> errada até a fatia #011; o teste `tools/test-launcher-detection.ps1` monta **≥ 2 QGIS** e asseria
> **qual** foi escolhido, justamente para isso não voltar sem ninguém ver.

Regra que **não** mudou: **a versão exercitada na VM limpa (BL-7) é a versão suportada declarada do
release.** Ver `docs/verify/bl7-clean-vm/RESULT.md`. Ampliar a baseline exige rodar o checklist
naquela versão — não se infere compatibilidade.

> **Obrigação de licença que cresce junto** (`D-IMAN-028`/DB-6): embarcar o MSI é **redistribuição**.
> O `THIRD_PARTY_NOTICES.md` atual **não cobre** isso (GPL-2.0-or-later do QGIS com oferta de fonte,
> Qt sob LGPL, GDAL, PROJ, GEOS, Python). **Fatia própria, obrigatória antes de qualquer
> distribuição.**

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
| Título da janela (startup) | Nome interno da app (applicationName/org, crash reporter, classe de janela) |
| Tema/cores (QSS do perfil) | Remoção/alteração de lógica de core |
| Plugin de marca (menu/toolbar/painel) | — |
| Ícone + nome do atalho e do instalador | — |
| Ícone da janela/taskbar (startup, runtime) | — |
| **Splash NATIVO de boot** (customização do perfil) | — |
| About próprio (plugin, coexiste com o nativo) | — |
| Projeto demo, templates, notices | — |

> **Atualização — spike #004 (D-IMAN-027), com evidência em
> `spike/004-branding-posbuild/REPORT.md`:** o **splash nativo de boot** SAIU da coluna
> "só com fork". O QGIS resolve o splash por `QgsCustomization::splashPath()` +
> `"splash.png"`, lido de `<perfil>/QGIS/QGISCUSTOMIZATION3.ini` (`[Customization]
> splashpath=…`) com `UI/Customization/enabled=true` — ou seja, **re-brandável por
> config do perfil isolado, no-fork** (comprovado: o QSplashScreen NATIVO renderiza o
> splash IMAN). O **ícone do arquivo `qgis-bin.exe`** é patch pós-build determinístico
> (Win32 `UpdateResource`) — mas só aplicável a um QGIS **bundlado** (BL-3 proíbe tocar o
> exe do usuário no no-fork) e de baixo valor (atalho + janela/taskbar já são IMAN). O
> **About** tem substituto no-fork (diálogo próprio). Resta irredutível só o **nome
> interno** (payoff ~zero). **Conclusão: o source-fork não se justifica pela evidência.**
