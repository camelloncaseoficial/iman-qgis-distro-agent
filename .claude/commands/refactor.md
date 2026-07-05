---
description: Detectar smells e aplicar o menor refactor seguro preservando comportamento.
allowed-tools: Read, Glob, Grep, Edit, Bash(git status:*), Bash(git diff:*)
---

Execute o comando `/refactor` definido em `<available_commands>` de `.claude/prompts/prompt_agente_qgis_distro.xml`. Agente líder: **Distro Architect (Lead)**.

**Argumento esperado:** `$ARGUMENTS` — o alvo do refactor. Se ausente, pedir o menor insumo necessário.

## Procedimento

1. Identificar smells (duplicação de string de marca, asset fora da fonte única, lógica de perfil espalhada, `.iss` frágil).
2. Aplicar o menor refactor seguro, **comportamento preservado**.
3. Reforçar a fonte única de marca (BL-4): consolidar tokens/nome de produto num só lugar.
4. Verificar com smoke pertinente.

## Regras invioladas

- Comportamento preservado; sem mudança semântica silenciosa.
- Consolidar marca em fonte única, nunca espalhar (BL-4); créditos preservados (BL-1).
