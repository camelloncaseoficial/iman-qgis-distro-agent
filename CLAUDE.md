# IMAN QGIS Distro — Claude Code Instructions

## Project scope

Distribuição QGIS customizada com branding do **Instituto IMAN** (ícones, cores, nome, interface),
distribuída **gratuitamente** como peça de **marketing técnico/institucional** — "powered by QGIS",
independente, **nunca** apresentada como QGIS oficial. Responsável por: perfil QGIS isolado, tema
visual, plugin de marca leve (PyQGIS), startup script, launcher Windows, **instalador Inno Setup**,
notices/licença. Caminho: **Opção 1 (no-fork) primeiro**; **fork/build (Opção 2)** como norte futuro.

Esta é uma **crew de execução** governada pelo PPSA (arquiteto) via briefings. Nasce de
**D-IMAN-025**. Não cunha decisão de produto: consome D-IDs do arquiteto.

## Initialization

On every new conversation, ALWAYS read before acting:
1. `.claude/prompts/prompt_agente_qgis_distro.xml`
2. `.memory/MEMORY.md`
3. `.memory/project_iman_qgis_distro.md`
4. `.memory/feedback_branding_license_guardrails.md`
5. `.memory/reference_qgis_profile_and_packaging.md`
6. `docs/distro-architecture.md`
7. `docs/BRANDING_AND_LICENSE.md`
8. `docs/design-system.md`
9. Briefing ativo em `../iman-product-architect/.memory/briefings/`, se existir
10. Decisões do programa em `../iman-product-architect/.memory/reference_decisions.md` (D-IMAN-025 e relacionadas)

## Stack

- QGIS LTR oficial (base — não recompilada na Opção 1)
- Python 3.12 / PyQGIS (plugin de marca leve, startup script)
- Perfil QGIS isolado + tema QSS / design tokens
- Inno Setup (instalador Windows)
- Assets de marca: `.ico`, `.svg`, `.png`, logo, splash-preview
- GitHub Releases para distribuição versionada
- [Opção 2, futuro] CMake / C++ / OSGeo4W para fork/build do QGIS

## Directory conventions (Opção 1 — no-fork)

- `app/launcher/` — launcher Windows (`.bat`/exe) que abre o QGIS com o perfil IMAN.
- `app/startup/` — startup script PyQGIS (título da janela, painel inicial, demo).
- `app/profile-template/<perfil>/` — perfil QGIS isolado versionado (QGIS/, python/plugins/, processing/, project_templates/, symbology-style.db).
- `app/profile-template/<perfil>/python/plugins/<plugin_de_marca>/` — plugin de marca leve.
- `app/demo/` — projeto demo de boas-vindas (`.qgz`).
- `app/assets/` — logo, ícones, `.ico`, splash-preview (fonte única de marca).
- `app/notices/` — `LICENSE`, `THIRD_PARTY_NOTICES.md`, `SOURCE_CODE.md`.
- `installer/` — `*.iss` (Inno Setup) + saída `dist/`.
- `docs/` — arquitetura, branding/licença, design system, guias de build/instalação.
- `packaging/` — [Opção 2, futuro] patches de fork, docs de build.

## Golden rules

- **Branding vem antes de fork:** perfil + tema + plugin + launcher + instalador resolvem o MVP;
  só o que é impossível sem recompilar (splash nativo, ícone do `qgis-bin.exe`, About, nome interno)
  espera a Opção 2 — e é documentado como limite, não hackeado.
- **Créditos do QGIS são inegociáveis** (BL-1/BL-2): "powered by QGIS", aviso de independência,
  `THIRD_PARTY_NOTICES.md` + `LICENSE` no pacote; nunca se apresenta como QGIS oficial.
- **Perfil isolado sempre** (BL-3): customização em `%APPDATA%\InstitutoIMAN\...`; nunca tocar a
  config/perfil/instalação do QGIS do usuário; uninstall não apaga dados do usuário.
- **Marca em fonte única** (BL-4): o produto é **IMAN Terra** (definido 2026-07-05); nome e todo
  texto de marca vêm de um único lugar (design system) para o rename ser find-replace.
- **Verdade na VM limpa** (BL-7): a entrega é validada instalando numa máquina Windows limpa.
- **Plugin de marca ≠ REURB:** não reimplementar nem copiar o plugin REURB; bundlá-lo é decisão
  faseada do arquiteto (STOP-AND-FLAG de D-IMAN-025).
- Mudança em token de marca, nome visível, estrutura de perfil ou notices exige atualização de docs.
