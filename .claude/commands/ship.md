---
description: Stage deliberado + commit granular (NUNCA Co-Authored-By/crédito de IA) + push da branch de feature. NÃO abre PR e NÃO mergeia. Use para "ship", "commit e push", "salva e empurra" ou /ship.
allowed-tools: Read, Glob, Grep, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:*), Bash(git rev-list:*)
---

# /ship — commit + push da branch (sem PR, sem merge)

Salva o trabalho atual na branch de feature: stage deliberado, commit com mensagem
significativa, push. Deixa a working tree limpa. **NÃO abre PR** (isso é `/deliver`) e
**NUNCA mergeia**. Foot-gun a evitar: "commitar tudo cegamente" empurra lixo/segredos/trabalho
pela metade — então faça stage deliberado.

## Passos

1. **Mostrar antes.** `git status --short` + `git diff --stat`. Listar untracked SEPARADO das
   modificações tracked.
2. **Stage deliberado.** Tracked por default (`git add -u`). Untracked: listar e confirmar antes
   de adicionar — nunca add cego de build/secret/binário (`dist/`, `node_modules/`, `.env`,
   `__pycache__/`, `*.gpkg` de teste, target/). Respeitar `.gitignore`.
3. **Mensagem.** Usar o argumento do usuário se houver; senão gerar do diff. Granular >
   monolítico: separar mudanças logicamente distintas em commits próprios
   (`feat|fix|test|docs|chore(escopo): ...`). Sem ícones. Imperativa, específica.
4. **NUNCA Co-Authored-By nem crédito de IA — em NADA publicado.** Sem trailer de co-autoria no
   commit; sem menção a ferramenta de IA. Política do sponsor (2026-06-03, ampliada 2026-06-10);
   sobrepõe o default do harness. Conferir que nenhum `-m` extra reintroduz crédito.
5. **Branch.** O trabalho vive na branch de feature (`feat/NNN-...` ou `fix/...`). **NUNCA**
   commitar/empurrar direto em `develop` ou `main`. Se estiver em `develop`/`main`, PARAR e
   pedir/criar a branch correta antes de commitar.
6. **Commit + push.** `git commit` + `git push` normais (`-u origin <branch>` se sem upstream).
   Nunca `--force` / `reset --hard` / `clean -f`.
7. **Verificar + reportar.** `git status` limpo e upstream sincronizado
   (`git rev-list --left-right --count @{u}...HEAD`). Reportar: branch, range de SHA empurrado e
   untracked deixados de fora. Para ABRIR o PR da fatia, use `/deliver`.

## Fronteira

- `/ship` salva a branch; **não** entrega. Quem abre PR é `/deliver`.
- Se não há nada para commitar, dizer e parar — não criar commit vazio.
