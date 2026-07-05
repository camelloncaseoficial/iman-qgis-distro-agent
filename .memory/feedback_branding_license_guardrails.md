# Feedback durável — Guardrails de marca e licença do QGIS

**Contexto:** a distro é independente, *powered by QGIS*, distribuída gratuitamente. Respeitar a
licença, os créditos e a marca do QGIS é condição inegociável (fonte: D-IMAN-025; doc de referência
`instituto_iman_qgis_customizacao_contexto_claude.md`).

**Por que:** a distro é peça de marketing institucional — a credibilidade depende de comunicar
maturidade técnica e prudência jurídica. Confundir a autoria do QGIS ou apagar créditos destrói o
valor da peça e cria risco de marca/licença.

**Como aplicar (invariantes BL-1…BL-7, canônicos em `.claude/prompts/prompt_agente_qgis_distro.xml`):**

- **BL-1 CREDIT_QGIS** — nunca remover/ocultar créditos; "powered by QGIS" + QGIS.ORG e
  contribuidores em todo artefato publicado; `THIRD_PARTY_NOTICES.md` + `LICENSE` no pacote.
- **BL-2 NOT_OFFICIAL** — nunca se apresentar como QGIS oficial/endossado; aviso de independência
  sempre; nome próprio + "powered by QGIS" (proibido "QGIS Instituto IMAN" e similares).
- **BL-3 ISOLATED_PROFILE** — customização em perfil isolado (`%APPDATA%\InstitutoIMAN\...`); jamais
  tocar config/perfil/instalação do QGIS do usuário; uninstall não apaga dados do usuário.
- **BL-4 BRAND_TOKENS_SINGLE_SOURCE** — nome de produto (**IMAN Terra**, definido 2026-07-05) e todo
  texto de marca de fonte única (`PRODUCT_NAME` no design system); rename = find-replace.
- **BL-5 NO_FORK_FIRST** — perfil/plugin/startup/launcher antes de alterar o core; fork (Opção 2) só
  após Opção 1 validada e com briefing; limites do no-fork documentados, não hackeados.
- **BL-6 GPL_AWARENESS** — plugins/scripts bundled respeitam compatibilidade GPL; plugin de marca usa
  APIs públicas; não vendorizar código de terceiros sem checar licença.
- **BL-7 CLEAN_VM_TRUTH** — a verdade da entrega é a experiência numa máquina Windows limpa; smoke no
  ambiente do dev não substitui o teste em VM limpa antes de release.
