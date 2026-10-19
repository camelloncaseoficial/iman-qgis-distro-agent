# IMAN QGIS Distro (IMAN Terra) - Crew distro

Este arquivo e um INDICE curto, nao um manual: o que muda o codigo fica aqui; historico e detalhe ficam em
`.memory/` e em `docs/`, lidos sob demanda. Formato do template PPSA `docs/crews` (2026-10-15), migrado em 2026-10-19.

Distribuicao QGIS com a marca do **Instituto IMAN** (produto **IMAN Terra**), gratuita, peca de marketing
tecnico/institucional, "powered by QGIS", **nunca** apresentada como QGIS oficial. Nasce de **D-IMAN-025**.

## Papel: executor

A Crew recebe um briefing do arquiteto (`../iman-product-architect`), implementa, escreve os testes, roda o gate e
abre o PR. Ela NAO decide produto, NAO mergeia, NAO publica release, NAO guarda credencial e NAO altera o proprio gate.
Ciclo de uma fatia: `/start-session` -> ler o briefing -> implementar -> gate -> `/ship` -> abrir PR -> `/deliver`.
**Ship = ABRIR PR, NAO mergear.** O merge e do sponsor.

## Stack

@.memory/project_stack.md

## Regras fixas (toda fatia, mesmo que o briefing nao repita)

- **Teste contra spec = STOP.** Se um teste ou checklist que ja existe contradiz o briefing, PARE e reporte qual,
  qual item do briefing e por que. Nunca edite, afrouxe, pule nem apague teste pre-existente para passar o gate,
  e nao molde o codigo para o caso do teste. Teste novo pode; teste existente alterado vai listado no `/deliver` com o motivo.
- **Duvida de produto ou escopo: perguntar, nunca assumir.** Pergunta sem resposta e STOP, nao licenca.
  A Crew nao cunha decisao (D-ID) nem escreve no repo do arquiteto.
- **Alem do escopo = declarado.** Melhoria fora do briefing vai na secao "Beyond scope" do `/deliver`, nunca escondida.
- **Gate:** o comando de `.memory/project_stack.md`, rodado com a arvore commitada. Teto de 2 rodadas falhas
  por branch; na 3a, pare e reporte. Nunca escrever em `crew_gate/` (pass_, rounds_). **Push e PR da branch
  da fatia nao esperam o gate:** publique e abra o PR assim que os commits estiverem prontos; o gate roda depois.
- **Excecao do BUILD CANONICO (preflight P0.6 do arquiteto):** o build canonico roda na `develop` e commita direto,
  sem PR, SO `installer/canonico/<versao>-<commit>/BUILD_INFO.txt`, `installer/canonico/VIGENTE.txt` e a evidencia
  em `docs/verify/<fatia>/**`. Nunca o `.exe`. O guard deixa passar esse push e nenhum outro em `develop`.
- **Segredo fica fora do alcance:** nao ler `.env`, `*.local`, `~/.aws`, `~/.ssh` nem credencial de CLI.
- **`.github/` e `CODEOWNERS` nao sao da Crew** (CI e protecao sao autoridade do sponsor).
- **NUNCA `Co-Authored-By` nem credito de IA** em commit, titulo/corpo de PR, issue ou comentario.
- **NUNCA travessao nem meia-risca** em codigo, comentario, string de UI, documento embarcado ou commit
  (D-IMAN-034). Excecao unica: texto de terceiro reproduzido literalmente (licenca upstream, nome oficial).
- **Identificador novo em EN**, mesmo ao lado de legado em PT. Texto de marca e de UI em PT.
- **Repos irmaos por path RELATIVO** (`../<repo>`), nunca com letra de drive.
- Sem icones em texto (excecao: glyph funcional de UI).

## Regras do dominio distro

- **Verdade na VM limpa (BL-7):** a entrega e validada instalando numa maquina Windows limpa; smoke que nao rodou
  na VM e lacuna declarada, nunca "pronto".
- **Branding vem antes de fork:** perfil + tema + plugin + launcher + instalador resolvem o MVP; o que e impossivel
  sem recompilar (splash nativo, icone do `qgis-bin.exe`, About, nome interno) e documentado como limite, nao hackeado.
- **Creditos do QGIS sao inegociaveis** (BL-1/BL-2): "powered by QGIS", aviso de independencia,
  `THIRD_PARTY_NOTICES.md` + `LICENSE` no pacote.
- **Perfil isolado sempre** (BL-3): customizacao em `%APPDATA%\InstitutoIMAN\...`; nunca tocar a config/perfil/
  instalacao do QGIS do usuario; uninstall nao apaga dados do usuario.
- **Marca em fonte unica** (BL-4): nome e todo texto de marca vem de um unico lugar (design system), para o rename ser find-replace.
- **Plugin de marca != REURB:** nao reimplementar nem copiar o plugin REURB; o embarque dele segue o briefing do arquiteto.
- Mudanca em token de marca, nome visivel, estrutura de perfil ou notices exige atualizacao de docs.

## Onde esta o resto

- `.memory/MEMORY.md` - indice das memorias (uma linha por arquivo).
- `.memory/feedback_*.md` e `.memory/reference_build_environment.md` - guardrails de marca/licenca e a bancada de
  build; lidos pelo `/start-session`.
- `.memory/project_*.md` e os outros `reference_*.md` - **sob demanda** (`Grep` pelo ID da fatia), nunca inteiros na abertura.
- `docs/distro-architecture.md`, `docs/BRANDING_AND_LICENSE.md`, `docs/branding-contract.md`, `docs/design-system.md`,
  `.claude/prompts/prompt_agente_qgis_distro.xml` - sob demanda.
- Briefing ativo: `../iman-product-architect/.memory/briefings/<YYYY-MM-DD>_qgis-distro_<NNN>_<slug>.md`.
  D-IDs: `../iman-product-architect/.memory/reference_decisions.md` (D-IMAN-025 e seguintes; ler a secao inteira).
