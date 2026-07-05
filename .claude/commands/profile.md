---
description: Foco no perfil QGIS isolado — interface simplificada, menus/toolbars, tema, CRS default, projeto demo, templates/estilos; reprodutível via --profile/--profiles-path.
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(git status:*), Bash(git diff:*)
---

Execute o comando `/profile` definido em `<available_commands>` de `.claude/prompts/prompt_agente_qgis_distro.xml`. Agente líder: **QGIS Profile Engineer**.

**Argumento esperado:** `$ARGUMENTS` — o aspecto do perfil a trabalhar (UI, tema, CRS, demo, templates, estilos). Se ausente, pedir o menor insumo necessário.

## Contexto fixo IMAN QGIS Distro

Perfil QGIS **isolado** carregado via `--profile <perfil> --profiles-path %APPDATA%\InstitutoIMAN\...`, versionado em `app/profile-template/<perfil>/`. Nunca toca a config/perfil do usuário.

---

## Procedimento

1. Ler `docs/distro-architecture.md`, `.memory/reference_qgis_profile_and_packaging.md` e o briefing ativo.
2. Customizar no perfil isolado: interface simplificada, menus/toolbars reorganizados, tema institucional, CRS default (SIRGAS 2000 / UTM da zona), idioma, projeto demo (`welcome.qgz`), templates/estilos.
3. Manter o perfil **reprodutível**: o que está em `app/profile-template/` deve gerar a mesma experiência ao ser copiado para o profiles-path no primeiro run (via launcher/instalador).
4. Smoke: abrir o QGIS LTR com o perfil isolado e confirmar a experiência.
5. Atualizar `docs/distro-architecture.md` se a estrutura do perfil divergir.

---

## Regras invioladas

- Perfil isolado sempre (BL-3): jamais sobrescrever config/perfil/instalação do QGIS do usuário.
- Não embutir dependência externa obrigatória nem serviço remoto no MVP.
- Créditos e "powered by QGIS" presentes na experiência de boas-vindas (BL-1).
