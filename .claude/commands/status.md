---
description: Resumir progresso da distro a partir de .memory/ + git state — read-only, sem mutações.
allowed-tools: Read, Glob, Grep, Bash(git status:*), Bash(git log:*), Bash(git diff:*)
---

Execute o comando `/status` definido em `<available_commands>` de `.claude/prompts/prompt_agente_qgis_distro.xml`. Agente líder: **Distro Architect (Lead)**.

**Argumento esperado:** `$ARGUMENTS` — pedido de estado atual, progresso, pendências, drift, riscos ou próximos passos. Se ausente, pedir o menor insumo necessário.

## Contexto fixo IMAN QGIS Distro

Distribuição QGIS customizada, *powered by QGIS*. Opção 1 (branding sobre QGIS LTR + instalador) primeiro; fork (Opção 2) futuro. Componentes: perfil isolado + tema + plugin de marca + startup + launcher + Inno Setup + notices.

---

## Procedimento

1. Ler `.memory/` (MEMORY.md, project, feedback, reference), docs e o briefing ativo do arquiteto.
2. Inspecionar `git status`/`git log` — branch, drift, últimos commits.
3. Reportar, read-only: o que está feito (perfil/tema/plugin/launcher/instalador/notices), o que falta na Opção 1, STOP-AND-FLAGs (nome de produto, QGIS LTR de teste, bundle REURB), riscos e próximo passo natural.
4. Não mutar nada.

---

## Regras invioladas

- Read-only: sem edição, sem commit, sem mutação de estado.
- Não inventar progresso: distinguir "feito e verificado" de "planejado".
