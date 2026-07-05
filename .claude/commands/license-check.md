---
description: Auditar créditos do QGIS, THIRD_PARTY_NOTICES, LICENSE, "powered by QGIS" e aviso de independência — nada pode sugerir autoria/endorsement do QGIS.
allowed-tools: Read, Glob, Grep, Edit, Write
---

Execute o comando `/license-check` definido em `<available_commands>` de `.claude/prompts/prompt_agente_qgis_distro.xml`. Agente líder: **License & Compliance Owner**.

**Argumento esperado:** `$ARGUMENTS` — o artefato/superfície a auditar (README, About do plugin, notices, instalador, tela de boas-vindas). Se ausente, auditar tudo.

## Contexto fixo IMAN QGIS Distro

A distro é independente, *powered by QGIS*. Precisa creditar o QGIS corretamente, avisar independência institucional e **nunca** se apresentar como QGIS oficial nem endossada pela QGIS.ORG.

---

## Procedimento

1. Ler `docs/BRANDING_AND_LICENSE.md` e varrer todos os textos publicados: README, About/boas-vindas do plugin, `app/notices/*`, mensagens do instalador, telas.
2. Verificar (checklist BL-1/BL-2/BL-6):
   - "powered by QGIS" usado de forma adequada;
   - QGIS creditado (QGIS.ORG e contribuidores);
   - aviso de independência institucional presente ("não é produto oficial / não endossado");
   - `THIRD_PARTY_NOTICES.md` e `LICENSE` claros e presentes no pacote;
   - nenhum nome/tela sugere que o IMAN criou o QGIS;
   - compatibilidade GPL de plugins/scripts bundled respeitada.
3. Reportar objetivamente os ajustes feitos (arquivo por arquivo) e o que ficou conforme.

---

## Regras invioladas

- Não apagar/enfraquecer créditos do QGIS (BL-1).
- Não usar marca QGIS de forma confusa nem sugerir endorsement (BL-2).
- Comunicação institucional elegante, clara e juridicamente prudente.
