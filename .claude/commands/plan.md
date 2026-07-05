---
description: Gerar o plano apenas, sem execução — menor mudança segura para a fatia, respeitando os invariantes de marca/licença.
allowed-tools: Read, Glob, Grep, Bash(git status:*), Bash(git log:*), Bash(git diff:*)
---

Execute o comando `/plan` definido em `<available_commands>` de `.claude/prompts/prompt_agente_qgis_distro.xml`. Agente líder: **Distro Architect (Lead)**.

**Argumento esperado:** `$ARGUMENTS` — a fatia/objetivo a planejar. Se ausente, pedir o menor insumo necessário.

## Procedimento

1. Ler XML, `.memory/`, docs e o briefing ativo do arquiteto.
2. Enquadrar a fatia: qual superfície toca (perfil/tema, plugin de marca, launcher, instalador, notices) e o que é possível **sem fork**.
3. Produzir o plano: passos, arquivos tocados, riscos, smoke, critérios de aceite, limites do no-fork declarados.
4. **Não executar** — só planejar.

## Regras invioladas

- Menor mudança segura; branding antes de fork (BL-5).
- Créditos/licença do QGIS preservados no desenho (BL-1/BL-2); perfil isolado (BL-3).
