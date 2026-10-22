---
name: Stack do projeto
description: Stack da distro IMAN Terra. Carregada pelo CLAUDE.md (@import). Migrada em 2026-10-19 das secoes Stack e Directory conventions do CLAUDE.md anterior e dos D-IDs vigentes; itens "a confirmar" sao perguntados pelo proximo /start-session.
type: project
captured_at: 2026-10-19
---

| Item | Escolha | Fonte |
|---|---|---|
| Base | QGIS LTR oficial, nao recompilado (Opcao 1, no-fork); baseline 3.44.13 | D-IMAN-025, D-IMAN-031 |
| Via | QGIS embarcado como copia privada (A1) | D-IMAN-028, emenda 2026-09-06 |
| Camada de marca | perfil isolado + tema QSS + plugin de marca PyQGIS + startup + launcher | CLAUDE.md anterior |
| Linguagem | Python 3.12 / PyQGIS; PowerShell no build e nos testes | CLAUDE.md anterior, `installer/build.ps1` |
| Instalador | Inno Setup 7 | D-IMAN-030 |
| Testes | `tools/test-*.ps1`, aceite da marca (`tools/branding-acceptance`), checklist do BL-7 na VM (`tools/bl7`) | `tools/` |
| Smoke | VM Windows limpa (BL-7) | CLAUDE.md anterior |
| Gate | `tools/test-*.ps1` em sequencia | sponsor 2026-10-22 |
| Branching | develop-based (base de PR = `develop`); build canonico commita direto na `develop` (P0.6) | D-IMAN-012, preflight P0.6 |
| Distribuicao | GitHub Releases, candidato registrado em `installer/canonico/VIGENTE.txt` | CLAUDE.md anterior, D-IMAN-032 |
| Arquiteto | `../iman-product-architect` (briefings em `.memory/briefings/`) | CLAUDE.md anterior |

- Prefixo dos briefings desta Crew: `qgis-distro` (`<YYYY-MM-DD>_qgis-distro_<NNN>_<slug>.md`, convencao IMAN).
- Gate: **o gate oficial e registrado pelo arquiteto no harness dele (`crew_gate.sh`, kind `qgis-distro`), nao por
  esta Crew** - quem e verificado nao define o proprio oraculo. Push e PR da branch da fatia NAO esperam o gate:
  rode o comando depois do PR aberto e cole o resultado no `/deliver`.

## Stack (detalhe)

- QGIS LTR oficial (base, nao recompilada na Opcao 1).
- Python 3.12 / PyQGIS (plugin de marca leve, startup script).
- Perfil QGIS isolado + tema QSS / design tokens.
- Inno Setup (instalador Windows).
- Assets de marca: `.ico`, `.svg`, `.png`, logo, splash.
- GitHub Releases para distribuicao versionada.
- [Opcao 2, futuro] CMake / C++ / OSGeo4W para fork/build do QGIS.

## Directory conventions (Opcao 1, no-fork)

- `app/launcher/` - launcher Windows que abre o QGIS com o perfil IMAN (e semeia/reconcilia o perfil).
- `app/startup/` - startup script PyQGIS (titulo da janela, painel inicial, demo).
- `app/profile-template/<perfil>/` - perfil QGIS isolado versionado (QGIS/, python/plugins/, processing/, project_templates/).
- `app/profile-template/<perfil>/python/plugins/<plugin_de_marca>/` - plugin de marca leve.
- `app/demo/` - projeto demo de boas-vindas (`.qgz`).
- `app/assets/` - logo, icones, `.ico`, splash (fonte unica de marca).
- `app/notices/` - `LICENSE`, `THIRD_PARTY_NOTICES.md`, `SOURCE_CODE.md`.
- `installer/` - `*.iss` (Inno Setup) + `build.ps1`; saida por identidade: `canonico/<versao>-<commit>/` (registro
  rastreado + `VIGENTE.txt`) e `dist/nao-canonico/` (build de branch, fora do git). `payload/` fica fora do git.
- `tools/` - testes e guardas em PowerShell, aceite da marca, kit do BL-7.
- `docs/` - arquitetura, branding/licenca, design system, laudos de verificacao (`docs/verify/`).
- `packaging/` - [Opcao 2, futuro] patches de fork, docs de build.
