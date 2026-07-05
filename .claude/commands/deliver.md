---
description: Entregar a fatia — garantir commits limpos + push da branch e ABRIR/atualizar PR contra a branch de integração, com corpo estruturado (resumo, critérios, smoke, saída de testes). NUNCA mergeia. Use ao terminar uma fatia ou quando o briefing pedir /deliver.
allowed-tools: Read, Glob, Grep, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:*), Bash(gh pr create:*), Bash(gh pr view:*), Bash(gh pr edit:*), Bash(gh pr list:*), Bash(python:*)
---

# /deliver — entregar a fatia (push + ABRIR PR, NUNCA mergear)

Ritual de fim de fatia: garante o código commitado e empurrado, então **abre (ou atualiza) o PR**
contra a branch de integração com um corpo estruturado. **O merge é decisão do sponsor — NUNCA
mergeia.**

## 1. Pré-checagem

- Confirmar que está numa branch de feature (`feat/NNN-...`/`fix/...`), não `main`/`develop`.
- Se houver mudanças não commitadas, rodar o fluxo do `/ship` primeiro (stage deliberado +
  commit granular + push), respeitando **NUNCA Co-Authored-By / crédito de IA**.
- Garantir push da branch (`git push -u origin <branch>` se sem upstream).

## 2. Verificação antes de entregar

- Rodar a verificação pertinente à fatia: smoke do perfil/plugin/launcher, compilação do
  instalador (`ISCC.exe`), `py_compile`/import do plugin de marca. **Capturar a saída real**
  para o corpo do PR.
- A verdade da entrega é a **máquina Windows limpa** (BL-7): se o smoke em VM não foi possível,
  **declarar a lacuna** no PR com os passos numerados para reproduzir — não afirmar "pronto".
- Não entregar com smoke vermelho sem sinalizar explicitamente o que falha e por quê.

## 3. Abrir / atualizar o PR

- **Base = branch de INTEGRAÇÃO**: `develop` quando existir (git-flow); **enquanto este repo só
  tiver `main`** (estado atual — git-flow entra numa fatia futura se o sponsor adotar), a base é
  **`main`**. Nunca `main` diretamente se `develop` existir.
- Se já há PR aberto para a branch: atualizar o corpo (`gh pr edit`). Senão: `gh pr create`.
- **Título**: imperativo, com escopo/fatia. SEM crédito de IA.
- **Corpo estruturado**:
  - Resumo da entrega (o que mudou e por quê).
  - Critérios de aceite do briefing — checados `[x]`/`[ ]`.
  - Passos de smoke (numerados), incl. o smoke em VM limpa (BL-7) — executado ou declarado como lacuna.
  - Saída da verificação (contagem/real — não assumir).
  - Invariantes de marca/licença honrados (BL-1…BL-7) e STOP-AND-FLAGs/pendências.
- **NUNCA Co-Authored-By nem menção a ferramenta de IA** — no título, corpo ou comentários.
  Política do sponsor (2026-06-03, ampliada 2026-06-10); sobrepõe o default do harness.

## 4. Fronteira (inviolável)

- **deliver = ABRIR PR, NÃO mergear.** O merge é decisão do sponsor.
- **NUNCA** `git merge` / `gh pr merge`. **NUNCA** `--force` / `reset --hard` / `clean -f`.
- Ao final, reportar o **link do PR** e o estado (base, mergeable).
