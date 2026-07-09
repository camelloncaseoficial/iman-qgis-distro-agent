---
description: Foco em identidade visual — cores, ícones, logo, splash (onde possível), tema QSS, tokens de marca em fonte única, .ico e nomenclatura visível.
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(git status:*), Bash(git diff:*)
---

Execute o comando `/branding` definido em `<available_commands>` de `.claude/prompts/prompt_agente_qgis_distro.xml`. Agente líder: **Branding & Visual Identity Designer**.

**Argumento esperado:** `$ARGUMENTS` — a superfície de marca a trabalhar (tema/cores, ícone, logo, splash, tokens, nome visível). Se ausente, pedir o menor insumo necessário.

## Contexto fixo IMAN QGIS Distro

Branding institucional IMAN sobre o QGIS LTR, *powered by QGIS*, o mais fundo que o caminho no-fork permite. Limites que só o fork (Opção 2) resolve: splash nativo, ícone do `qgis-bin.exe`, About dialog, nome interno da aplicação.

---

## Procedimento

1. Ler `docs/design-system.md` (tokens), `docs/BRANDING_AND_LICENSE.md` e o briefing ativo.
2. Trabalhar a marca a partir de **fonte única** (design system + constantes): cores, tipografia, ícone/logo, nome de produto (**IMAN Terra**, definido), subtítulo.
3. Aplicar via tema QSS do perfil, assets em `app/assets/`, e o plugin de marca — sem tocar o core do QGIS.
4. Onde a marca esbarra em limite do no-fork, **documentar o limite** (não hackear); marcar como candidato à Opção 2.
5. Garantir "powered by QGIS" e aviso de independência onde a marca aparece (BL-1/BL-2).
6. Atualizar `docs/design-system.md` quando um token novo ou nome visível mudar.

---

## Regras invioladas

- Nome de produto e todo texto de marca vêm de fonte única (BL-4) — nada de string de marca espalhada.
  Ao mexer no nome visível, seguir **`docs/RENAME_CHECKLIST.md`** (enumera toda superfície que espelha
  `PRODUCT_NAME`: código, `.iss`, `.bat`, prosa dos notices e nomes de arquivo).
- Nunca remover créditos do QGIS nem sugerir autoria/endorsement (BL-1/BL-2).
- Não recompilar o QGIS para efeito visual: o que exige fork fica documentado para a Opção 2 (BL-5).
