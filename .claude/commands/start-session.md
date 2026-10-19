---
description: Bootstrap da sessao. Com item "a confirmar" na stack (ou o argumento stack) entrevista o sponsor e grava em .memory/project_stack.md; depois, git sync + contexto enxuto + briefing ativo do arquiteto.
allowed-tools: Bash(git status:*), Bash(git fetch:*), Bash(git pull:*), Bash(git rev-parse:*), Bash(git log:*), Bash(git merge-base:*), Bash(gh pr list:*), Read, Glob, Grep, AskUserQuestion, Write, Edit
---

Bootstrap da Crew distro (IMAN Terra). Rode as fases em ordem.

**Phase 0 - STACK (so se `.memory/project_stack.md` tem item `a confirmar`, nao existe, ou com o argumento `stack`)**

Caso contrario, pule para a Phase 1.

1. Anuncie em uma linha: "a stack desta Crew tem item a confirmar: vou registrar antes de tudo".
2. Detecte, sem escrever nada, o que o repo ja declara (`installer/*.iss`, `installer/build.ps1`, `tools/test-*.ps1`,
   `.memory/reference_build_environment.md`). Use o achado so como CONTEXTO no texto da pergunta ("detectei X -
   confirma?"). **Quem decide e o sponsor; nao pule pergunta por ter detectado.**
3. Sem o argumento `stack`, pergunte SO os itens `a confirmar`; com ele, todas. Use `AskUserQuestion` (4 por
   chamada, `multiSelect: false`), com estes textos e opcoes (o sponsor sempre pode responder "Other"):
   - [Gate] Comando UNICO de verificacao (o gate)? Opcoes: `tools/test-*.ps1 em sequencia` (testes de launcher, perfil, tema, reinstalacao); `build.ps1 + tools/test-*.ps1` (compila o instalador de branch e testa); `aceite da marca (tools/branding-acceptance)` (contrato da camada de marca); `checklist do BL-7 na VM` (so com VM disponivel).
   - [Smoke] Onde a entrega e provada? Opcoes: `VM Windows limpa (BL-7)` (instalacao do zero); `Maquina do sponsor` (instalacao por cima); `Os dois` (VM para o aceite, maquina para o uso).
   - [Branching] Modelo de branch? Opcoes: `develop-based` (feature -> develop -> main; D-IMAN-012; build canonico direto na develop pela P0.6); `trunk-based` (feature -> main).
   - [Arquiteto] Repo do arquiteto (path RELATIVO, de onde vem o briefing)? Opcoes: `../iman-product-architect` (briefings em .memory/briefings/); `Sem arquiteto` (o sponsor da as tarefas direto).
   Item sem pergunta acima (Base, Via, Camada de marca, Linguagem, Instalador, Testes, Distribuicao) so muda com o
   argumento `stack`, por pergunta aberta.
4. Troque cada `a confirmar` pela resposta (coluna Fonte = `sponsor <YYYY-MM-DD>`), mantendo o resto do arquivo.
   Com o argumento `stack`, mostre antes o diff contra o arquivo atual e peca confirmacao para sobrescrever.
5. Se o `project_stack.md` nao existia: acrescente ao `.memory/MEMORY.md` a linha
   `- [Stack do projeto](project_stack.md) - stack escolhida pelo sponsor; carregada pelo CLAUDE.md`.
6. Diga ao sponsor, em uma linha, o que falta fora desta Crew: registrar o gate no harness do arquiteto (kind
   `qgis-distro` no `crew_gate.sh`) e copiar `.claude/settings.local.json.example` para `.claude/settings.local.json`
   se ainda nao houver.

A Phase 0 escreve SO o `project_stack.md` e, se preciso, a linha do `MEMORY.md`. Nao instala dependencia, nao compila, nao commita.

**Phase 1 - INSPECT** (sempre, so leitura)
- `git status --porcelain`; `git rev-parse --abbrev-ref --symbolic-full-name @{u}` (tolerar falha);
  `git fetch --all --prune`; `git status -sb`. Anuncie o estado em uma linha.

**Phase 2 - PULL** (so com arvore limpa, atras, nao a frente, com upstream)
- `git pull --ff-only`. Senao, pule e diga o motivo (sujo / divergente / sem upstream).
- Branch de fatia ja mergeada em `origin/develop` (`git merge-base --is-ancestor HEAD origin/develop`): diga que o
  checkout esta parado numa fatia entregue e que a proxima nasce de `origin/develop`.

**Phase 3 - CONTEXTO ENXUTO** (sempre)
- O `CLAUDE.md` ja esta carregado e importa o `project_stack.md`. Leia `.memory/MEMORY.md`, todos os
  `.memory/feedback_*.md` e o `.memory/reference_build_environment.md` (a bancada de build desta maquina).
- **Nao** leia `.memory/project_*.md` inteiros, os outros `reference_*.md`, o prompt XML nem documento grande
  (`docs/distro-architecture.md`, `docs/BRANDING_AND_LICENSE.md`, `docs/design-system.md`). Sob demanda: `Grep`
  pelo ID da fatia do briefing ativo e leia so o trecho encontrado.

**Phase 3b - BRIEFING ATIVO** (sempre, so leitura; pule se o `project_stack.md` disser "Sem arquiteto")
- `Glob` em `../iman-product-architect/.memory/briefings/*_qgis-distro_*.md`; escolha o de data mais alta no NOME
  (`YYYY-MM-DD`) e, no empate, o `NNN` mais alto. Nao pelo mtime.
- Leia-o inteiro e extraia: base (branch + SHA), o que fazer, testes, STOP, fora de escopo, como entregar.
- Compare HEAD com a base: bate -> `pronto`; avancou N -> `ja aplicou N commits, conferir com o briefing`; outra
  branch -> `divergente`; sujo -> listar.
- **Confira o briefing contra o CODIGO antes de confiar no status** do cabecalho: procure os artefatos que ele
  prescreve; existindo, classifique `ja aterrado`.
- `gh pr list --author @me --state open`: PR aberto para a branch -> `fase de smoke/review, nao de aplicacao`.

**Phase 4 - RESUMO**
- Uma linha por fase. Comece pelo sinal mais relevante (briefing novo, drift, PR aberto). Feche com uma linha de prontidao.

**Invariantes:** idempotente, le antes, transparente, tolerante a falha. Fora da Phase 0: sem edits, sem commits,
sem PR, sem mutacao de memoria. Nunca escrever no repo do arquiteto. Nada de travessao no que escrever (D-IMAN-034).
