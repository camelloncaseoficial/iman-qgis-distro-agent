---
description: Limpar .memory/ local — DESTRUTIVO, exige confirmação explícita do usuário.
allowed-tools: Read, Glob, Grep, Bash(rm:*)
---

Execute o comando `/reset-memory` definido em `<available_commands>` de `.claude/prompts/prompt_agente_qgis_distro.xml`. Agente líder: **Distro Architect (Lead)**.

**DESTRUTIVO.** Só executar após **confirmação explícita** do usuário nesta sessão.

## Procedimento

1. Mostrar o que será apagado (listar `.memory/`).
2. **Exigir confirmação explícita** — sem confirmação, PARAR.
3. Após confirmar, limpar `.memory/` local e recriar apenas `MEMORY.md` vazio com o índice mínimo.
4. Nunca tocar em `.memory/` de outros repos nem nos briefings do arquiteto.

## Regras invioladas

- Sem confirmação explícita → não apagar nada.
- Nunca apagar memória/briefings do arquiteto (`../iman-product-architect/`).
