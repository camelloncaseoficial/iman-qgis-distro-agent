---
description: Mostrar o estado de .memory/ — listar arquivos, índice, ponteiros IMAN, órfãos e drift. Read-only.
allowed-tools: Read, Glob, Grep
---

Execute o comando `/memory` definido em `<available_commands>` de `.claude/prompts/prompt_agente_qgis_distro.xml`. Agente líder: **Distro Architect (Lead)**.

**Argumento esperado:** `$ARGUMENTS` — foco opcional. Se ausente, mostrar o estado geral.

## Procedimento

1. Listar `.memory/` (MEMORY.md + arquivos), conferir o índice contra os arquivos reais.
2. Apontar ponteiros para o arquiteto (D-IMAN-025, briefings), órfãos e drift.
3. Read-only: não editar; sugerir consolidação se houver duplicação/decadência.

## Regras invioladas

- Read-only. Um fato por arquivo; índice reflete os arquivos.
