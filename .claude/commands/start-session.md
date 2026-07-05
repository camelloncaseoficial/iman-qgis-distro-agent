---
description: Bootstrap de nova sessão — git sync + reload context: XML, docs (distro-architecture, branding/licença, design-system), .memory e briefing do arquiteto.
allowed-tools: Read, Glob, Grep, Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git fetch:*)
---

Execute o comando `/start-session` definido em `<available_commands>` de `.claude/prompts/prompt_agente_qgis_distro.xml`. Agente líder: **Distro Architect (Lead)**.

**Argumento esperado:** `$ARGUMENTS` — objetivo inicial da sessão, branch, tarefa, bug ou fatia. Se ausente, pedir o menor insumo necessário.

## Contexto fixo IMAN QGIS Distro

Distribuição QGIS customizada com branding do Instituto IMAN, *powered by QGIS*, distribuída gratuitamente como peça de marketing. Opção 1 (camada de branding sobre QGIS LTR + instalador Windows, sem recompilar) primeiro; fork/build (Opção 2) como norte futuro. Nunca se apresenta como QGIS oficial.

Componentes da Opção 1: perfil QGIS isolado + tema + plugin de marca leve + startup + launcher + instalador Inno Setup + notices/licença.

---

## Procedimento

1. Ler `.claude/prompts/prompt_agente_qgis_distro.xml`, `.memory/MEMORY.md`, `.memory/project_iman_qgis_distro.md`, `.memory/feedback_branding_license_guardrails.md`, `.memory/reference_qgis_profile_and_packaging.md`, `docs/distro-architecture.md`, `docs/BRANDING_AND_LICENSE.md`, `docs/design-system.md` quando existirem.
2. Ler o briefing ativo em `../iman-product-architect/.memory/briefings/` e as decisões relacionadas (D-IMAN-025) em `../iman-product-architect/.memory/reference_decisions.md`.
3. `git status`/`git log`: entender branch, drift e árvore de trabalho.
4. Aplicar o objetivo com a menor mudança segura, respeitando os invariantes de marca/licença (BL-1…BL-7).
5. Verificar com smoke pertinente (abrir com `--profile` isolado; instalador → VM/máquina limpa).
6. Atualizar docs e memória apenas quando houver decisão durável.

3. Aplicar o objetivo específico: Bootstrap de nova sessão — git sync + reload context.

---

## Regras invioladas

- Não remover/ocultar créditos do QGIS; nunca se apresentar como QGIS oficial (BL-1/BL-2).
- Não tocar/sobrescrever a config/perfil/instalação do QGIS do usuário; perfil sempre isolado (BL-3).
- Marca visível sempre de fonte única; nome de produto = **IMAN Terra** (definido; BL-4).
- Não iniciar fork/build (Opção 2) sem Opção 1 validada e briefing próprio (BL-5).
- Não bundlar/copiar o plugin REURB sem briefing explícito do arquiteto.
