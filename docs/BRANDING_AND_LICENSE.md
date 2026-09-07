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

## Conduta de REDISTRIBUIDOR (desde 30/07/2026 — via A1, `D-IMAN-028`/`DB-6`)

O produto deixou de **usar** o QGIS e passou a **distribuí-lo**: o instalador embarca 159
componentes de terceiros. Obrigação de distribuidor é de outra natureza, e estes itens entram no
`/license-check`:

- [ ] Os três documentos descrevem o produto que existe — **bundlado, redistribuidor**. Nenhum deles
      afirma "não redistribui o QGIS".
- [ ] `LICENSE` (tela de aceite do wizard) é **curto e verdadeiro**, e aponta para o
      `THIRD_PARTY_NOTICES.md` instalado junto. **Não** vira paredão de 159 licenças.
- [ ] `THIRD_PARTY_NOTICES.md`, `SOURCE_CODE.md` e `BUILD_INFO.txt` **viajam no pacote instalado**.
- [ ] Inventário (`docs/licencas/inventario.csv`) corresponde à versão do QGIS embarcada — conferir
      contra o `Payload SHA-256` do `BUILD_INFO.txt`. **Trocar a baseline do QGIS invalida o
      inventário.**
- [ ] Toda licença no inventário tem **origem consultada e citada**. `DESCONHECIDA` é resultado
      válido; **licença deduzida por nome não é**.
- [ ] Oferta de código-fonte correspondente **do Instituto IMAN** viva para os componentes copyleft
      (apontar para `qgis.org` é cortesia, não cumprimento).
- [ ] Componentes LGPL entregues como **DLLs substituíveis** (vínculo dinâmico) + instrução de
      substituição — Qt inclusive.
- [ ] Componentes proprietários embarcados: revisados a cada mudança de escopo do pacote
      (`docs/licencas/EXCLUSAO_PROPOSTA.md`).

> Referências: `docs/licencas/INVENTARIO.md` (método e inventário) ·
> `docs/licencas/EXCLUSAO_PROPOSTA.md` (escopo do pacote) · `app/notices/` (os três documentos).

## Nomenclatura

- Nome próprio + "powered by QGIS".
- Nome de produto: **`IMAN Terra`** (definido pelo sponsor 2026-07-05, após `/critique` +
  `/signature-experience`; venceu `IMAN GIS`). Ver D-IMAN-025.
- Qualquer texto de marca vem de fonte única — `PRODUCT_NAME` no design system (BL-4).
