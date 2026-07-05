---
description: Foco no instalador Windows (Inno Setup) — empacotar app/perfil/notices, atalhos, ícone, detecção de QGIS, uninstall limpo, release versionada.
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(git status:*), Bash(git diff:*)
---

Execute o comando `/packaging` definido em `<available_commands>` de `.claude/prompts/prompt_agente_qgis_distro.xml`. Agente líder: **Installer & Release Engineer**.

**Argumento esperado:** `$ARGUMENTS` — o aspecto do empacotamento a trabalhar (script .iss, atalhos, ícone, detecção de QGIS, uninstall, release). Se ausente, pedir o menor insumo necessário.

## Contexto fixo IMAN QGIS Distro

Instalador Windows via **Inno Setup** que instala a camada IMAN (app/perfil/notices), cria atalhos com ícone próprio, detecta/orienta sobre o QGIS LTR e desinstala limpo — sem sobrescrever dados do usuário. Saída: `Instituto-IMAN-*-Setup-<versão>.exe`.

---

## Procedimento

1. Ler `docs/distro-architecture.md`, `.memory/reference_qgis_profile_and_packaging.md` e o briefing ativo.
2. Empacotar `app/*` (launcher, startup, profile-template, demo, assets, notices) e o `installer/*.iss`.
3. Atalhos (menu iniciar + opção desktop) com o `.ico` de marca; incluir `LICENSE`, `THIRD_PARTY_NOTICES.md`, `README.md`.
4. Detectar QGIS LTR instalado quando possível; se ausente, orientar o usuário com clareza (instalador leve) ou embutir a dependência (instalador full) conforme a fatia.
5. Uninstall limpo; perfil isolado em `%APPDATA%\InstitutoIMAN\...` **não** apagado à toa; jamais mexer na instalação do QGIS.
6. Smoke em **VM/máquina Windows limpa** antes de release (BL-7); release versionada (GitHub Releases).

---

## Regras invioladas

- Nunca modificar destrutivamente a instalação oficial do QGIS nem a config do usuário (BL-3).
- Créditos/notices/LICENSE sempre no pacote; instalador não confunde sobre a origem do QGIS (BL-1/BL-2).
- Instalação silenciosa/embutida do QGIS só com parâmetros **testados** para a versão alvo.
- Verdade da entrega = VM limpa (BL-7): não declarar "pronto" sem esse smoke.
