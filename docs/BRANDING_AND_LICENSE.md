# Branding & Licença — IMAN QGIS Distro

Fonte canônica de conduta de marca/licença. Invariantes executáveis BL-1…BL-7 em
`.claude/prompts/prompt_agente_qgis_distro.xml`; feedback durável em
`.memory/feedback_branding_license_guardrails.md`. Nasce de **D-IMAN-025**.

## Princípio

A distro é **independente**, *powered by QGIS*. Comunica domínio técnico e prudência jurídica.
Nunca se apresenta como QGIS oficial nem endossada pela QGIS.ORG.

## Textos institucionais (fonte única — usar verbatim onde a marca aparece)

Créditos (README, About do plugin, notices, boas-vindas, instalador):

```text
IMAN Terra é uma experiência geoespacial desktop independente, powered by QGIS.
O QGIS é um sistema de informação geográfica livre e de código aberto, desenvolvido
por QGIS.ORG e contribuidores.
Este projeto não é um produto oficial do QGIS e não é endossado pela QGIS.ORG.
```

> O nome `IMAN Terra` vem da fonte única `PRODUCT_NAME` no design system (BL-4). Trocar num só lugar.

## Checklist de conformidade (rodar via `/license-check`)

- [ ] "powered by QGIS" usado de forma adequada em cada superfície publicada.
- [ ] QGIS creditado (QGIS.ORG e contribuidores).
- [ ] Aviso de independência institucional presente ("não é produto oficial / não endossado").
- [ ] `THIRD_PARTY_NOTICES.md` e `LICENSE` claros e presentes no pacote.
- [ ] Nenhum nome/tela sugere que o Instituto IMAN criou o QGIS.
- [ ] Nomes proibidos evitados: "QGIS Instituto IMAN", "IMAN QGIS Official", "QGIS by Instituto IMAN".
- [ ] Perfil isolado; instalador não confunde sobre a origem do QGIS; não mexe na instalação do usuário.
- [ ] Plugins/scripts bundled compatíveis com GPL; sem vendorizar código de terceiros sem checar licença.

## Nomenclatura

- Nome próprio + "powered by QGIS".
- Nome de produto: **`IMAN Terra`** (definido pelo sponsor 2026-07-05, após `/critique` +
  `/signature-experience`; venceu `IMAN GIS`). Ver D-IMAN-025.
- Qualquer texto de marca vem de fonte única — `PRODUCT_NAME` no design system (BL-4).
