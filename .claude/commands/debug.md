---
description: Investigar erros Python/PyQGIS/perfil/launcher/instalador — diagnosticar causa raiz antes de corrigir.
allowed-tools: Read, Glob, Grep, Edit, Bash(git status:*), Bash(git diff:*), Bash(git log:*)
---

Execute o comando `/debug` definido em `<available_commands>` de `.claude/prompts/prompt_agente_qgis_distro.xml`. Agente líder: **Distro Architect (Lead)**.

**Argumento esperado:** `$ARGUMENTS` — o erro/sintoma a investigar. Se ausente, pedir o menor insumo necessário.

## Procedimento

1. Reproduzir e isolar o sintoma (plugin de marca, startup, launcher `.bat`/exe, perfil não carregando, instalador falhando, QGIS não detectado).
2. Diagnosticar a **causa raiz** antes de corrigir — não tratar sintoma.
3. Aplicar a menor correção segura; verificar com smoke (perfil isolado / VM limpa quando instalador).
4. Registrar aprendizado durável em `.memory/` só se genuíno.

## Regras invioladas

- Não mascarar erro; causa raiz primeiro.
- Correção não pode tocar a config/instalação do QGIS do usuário (BL-3) nem remover créditos (BL-1).
