# BL-7 - Resultado da verificação em VM limpa

> **STATUS: MODELO NÃO PREENCHIDO. A verificação em VM limpa AINDA NÃO FOI EXECUTADA.**
> Enquanto esta linha estiver aqui, o BL-7 continua **aberto** e nenhum release pode alegar
> "validado em máquina limpa". Quem executar: preencha, apague esta citação e commite.

Execução do roteiro `CHECKLIST.md`. Preencher **durante** o teste, não de memória.

> **Este modelo foi refeito na fatia `#036`, junto com o checklist.** O anterior era de 2026-07-22 e
> listava 14 passos de um roteiro que não existe mais: ele ainda tinha "VM-A: mensagem de QGIS
> ausente", que descrevia o produto de antes da fatia `#011`. Um modelo que pede campos de outro
> roteiro não é formulário, é armadilha.

---

## 0. Legenda (`E.6`)

| Marca | Significa |
|---|---|
| `PASS` | **medido**, e bateu com a asserção |
| `FAIL` | **medido**, e não bateu. O que apareceu está transcrito |
| `RELATADO` | observado e registrado, mas **não é asserção com veredito** |
| `N/E` | **não executado**, com o motivo nomeado |

**`N/E` não é `PASS`.** Um passo não executado nunca vira "deve estar bom".

---

## 1. Artefato testado

| Campo | Valor |
|---|---|
| Arquivo | `Instituto-IMAN-IMAN-Terra-Setup-______-_______.exe` | 
| ProductVersion | |
| Commit (completo) | |
| Commit (curto) | |
| Branch | |
| **Build canônico** | `SIM / NÃO` |
| SHA-256 no `BUILD_INFO.txt` | |
| SHA-256 conferido **na VM** | |
| **Os dois SHA-256 batem?** | `SIM / NÃO` |
| Tamanho em bytes, conferido na VM | |
| `VIGENTE.txt` da `develop` apontava para | |
| **O artefato testado é o candidato vigente?** | `SIM / NÃO` |
| Data do teste | |
| Executado por | |

> **Se os SHA-256 não batem, o teste é inválido**: não se sabe qual artefato foi exercitado.

> **Se `Build canônico` for `NÃO`**, esta rodada vale como **ensaio**, não como evidência de
> release. Diga isso no veredito final, em voz alta.

## 2. Procedência do produto INSTALADO (`§7` do checklist)

*(cole aqui a seção correspondente do `RESULT-esqueleto.md` gerado por `tools\bl7\collect-evidence.ps1`)*

| Campo | Valor lido de `{app}\BUILD_ID.txt` |
|---|---|
| Produto / versão | |
| Commit / commit curto | |
| Commit curto é prefixo do completo | `SIM / NÃO` |
| Branch | |
| `build_canonico` | |
| QGIS embarcado (manifesto) | |
| Arquivos na árvore x `TOTAL` do manifesto | `______ / ______` |
| Payload SHA-256 de origem | |

| Campo | Valor |
|---|---|
| O `commit_curto` bate com o do `§1`? | `SIM / NÃO` |
| Na tela, o rodapé da HOME exibia | `versão ______ · ________` |

## 3. Ambiente

*(cole aqui a saída de `tools\bl7\collect-evidence.ps1`)*

| Campo | Valor |
|---|---|
| Windows (edição, versão, build) | |
| Idioma | |
| **Sessão de administrador** | `SIM / NÃO` |
| Resolução | |
| Escala de exibição | |
| Escopo da instalação (HKCU ou HKLM) | |
| QGIS de sistema presente | |
| Perfil do usuário estava **sujo** antes? | `SIM / NÃO` |
| `.exe` chegou por **download HTTP**? | `SIM / NÃO` |

> **Três desvios de ambiente que invalidam parte da rodada, e não são detalhe:**
> sessão de administrador (o `§4` deixa de testar o que existe para testar), perfil do usuário
> vazio no baseline (o `§12` passa nos dois mundos) e `.exe` copiado em vez de baixado (o
> SmartScreen real não aparece). **Desvio de ambiente é achado**, e entra no `§7` deste documento.

## 4. Resultado por passo

| Passo | Rodada | Assunto | Resultado | Observação |
|---|---|---|---|---|
| 1 | M1 | Baseline do perfil do usuário (`TotalArquivos` > 0) | | |
| 2 | M1 | SHA-256 e `BUILD_INFO` do artefato | | |
| 3 | M1 | SmartScreen, wizard pt-BR, licença, sem UI de terceiro | | |
| 4 | M1 | **Elevação: zero prompts de UAC** | | |
| 5 | M1 | Onde instalou, e onde NÃO instalou | | |
| 6 | M1 | O QGIS veio dentro do produto | | |
| 7 | M1 | **Procedência: `BUILD_ID.txt`** | | |
| 8 | M1 | Checkbox final do instalador | | |
| 9 | M1 | Primeiro run pelo atalho | | |
| 10 | M1 | Ícone na barra de tarefas em 16x16 | | |
| 11 | M1 | **Reconciliação (a): perfil ausente** | | |
| 12 | M1 | BL-3: perfil do usuário intacto | | |
| 13 | M1 | Ciclo HOME e canvas, 3 vezes | | |
| 14 | M1 | **Reconciliação (b): perfil igual, nada escrito** | | |
| 15 | M1 | Créditos do QGIS no produto instalado | | |
| 16 | M1 | **A guarda recusa abrir sobre árvore quebrada** | | |
| 17 | M1 | Desinstalar: o que sai e o que fica | | |
| 18 | M1 | Reinstalar por cima: a árvore não se funde | | |
| 19 | M2 | O produto ignora o QGIS da máquina | | |
| 20 | M3 | **Reconciliação (c): perfil velho divergente** | | |
| 21 | M4 | Cancelar no meio: a máquina fica como estava | | |

### Placar

| | |
|---|---|
| Passos **com evidência** (`PASS` + `FAIL`) | `______ de 21` |
| Passos `N/E` | `______` - liste quais e por quê: |
| Rodadas concluídas | `M1 ☐ · M2 ☐ · M3 ☐ · M4 ☐` |

### Os três estados da reconciliação (`DB-26`)

| estado | passo | esperado | resultado |
|---|---|---|---|
| (a) perfil ausente | `§11` | `SEMEADO`, base gravada | |
| (b) perfil igual | `§14` | `NADA_A_FAZER`, nada escrito | |
| (c) perfil velho divergente | `§20A` e `§20B` | `APLICADA`, obsoletos saem, CRS corrige | |

> **O (c) é o único que pode errar**, porque é o único com merge de 3 vias. Se ele ficar `N/E`, o
> veredito final **não pode** afirmar que atualizar de uma versão anterior funciona.

## 5. Veredito por invariante de marca e licença

| Invariante | O que exige | Resultado | Evidência |
|---|---|---|---|
| **BL-1** | Créditos do QGIS presentes: `LICENSE`, `THIRD_PARTY_NOTICES.md`, `SOURCE_CODE.md`, "powered by QGIS", o Sobre credita o QGIS e o Sobre nativo continua no menu | | passo 15 |
| **BL-2** | Nada se apresenta como QGIS oficial ou endossado pela QGIS.ORG | | passos 3 e 9 |
| **BL-3** | Perfil e instalação do QGIS do usuário **intactos**; perfil isolado próprio; uninstall não apaga dados do usuário | | passos 12, 17, 19 |
| **BL-4** | Marca visível consistente (nome, ícones, artes, título) vindo da fonte única | | passos 3, 9, 10 |
| **BL-5** | O no-fork se comporta: o produto carrega o próprio QGIS e recusa abrir com árvore quebrada, com mensagem humana e sem stacktrace | | passos 6 e 16 |
| **BL-7** | O ciclo completo foi exercitado **em máquina limpa** | | este documento |

*(BL-6, se aplicável ao release, é preenchido aqui do mesmo jeito.)*

> **O `BL-5` mudou de asserção na fatia `#036`.** Ele media "a ausência do QGIS é tratada com
> mensagem humana", e essa mensagem não existe mais: o QGIS nunca está ausente, porque vem dentro do
> produto. A mensagem humana que sobrou, e que importa mais, é a da **árvore quebrada**.

## 6. Regra de corte - vale como escrita, não como opinião

> **FAIL em BL-1, BL-2 ou BL-3 bloqueia o release. Sem discussão, sem "corrige depois".**
> São crédito de terceiros, autoria e dado do usuário: os três criam dano que um patch posterior
> não desfaz (o usuário já perdeu o arquivo; a QGIS.ORG já foi mal-representada).
>
> **FAIL no `§16` (a guarda de integridade) também bloqueia.** Uma árvore truncada não dá erro:
> devolve **coordenada errada em silêncio**. Se o produto abrir nesse estado, ele entrega o defeito
> mais caro que existe num trabalho de REURB, e com o nosso nome.
>
> **FAIL no `§20` (reconciliação) bloqueia para quem já tem o produto instalado.** Um perfil que não
> reconcilia pode seguir com o **CRS antigo**, e o QGIS não reclama de CRS errado: ele desenha.
>
> **FAIL visual (layout, tema, HOME, tela-fantasma) não bloqueia por si.** É bug de fatia: vira
> briefing para o arquiteto e entra na fila normal.
>
> **A versão do QGIS efetivamente testada vira a versão suportada declarada do release.**
> Não se infere compatibilidade com outras versões. Suportar mais uma versão é rodar este checklist
> nela. Ver `docs/distro-architecture.md`.

> **O PONTO CEGO DE ATUALIZAÇÃO FOI FECHADO na fatia `#036`, e o que sobrou está nomeado.**
> Até aqui este documento declarava que uma rodada em VM limpa **não exercita** o caminho de
> atualização, porque o perfil isolado nasce novo e o defeito não existe por construção. A rodada
> **M3** passou a exercitar exatamente isso, semeando o perfil de um commit real da história.
> **O que continua fora de alcance** é o perfil de um usuário **de verdade**, com meses de uso e
> personalizações que ninguém previu. A rodada M3 mede o mecanismo; ela não substitui um piloto.

**Veredito final:** `LIBERADO / BLOQUEADO` - justificativa: `____________________`

## 7. SmartScreen (o instalador NÃO é assinado)

| Campo | Valor |
|---|---|
| Apareceu? | `SIM / NÃO` |
| Título da janela | |
| **Texto literal exibido** | |
| Existe o link "Mais informações"? | `SIM / NÃO` |
| Após "Mais informações -> Executar assim mesmo", instalou? | `SIM / NÃO` |

**Encaminhamento (já decidido, não reabrir aqui):**

- Documentar no guia de instalação o caminho **"Mais informações -> Executar assim mesmo"**, com o
  texto literal capturado acima e o SHA-256 do artefato para o usuário conferir. Aviso do
  SmartScreen sem explicação prévia é a principal causa de desistência na instalação.
- **Não comprar certificado de assinatura de código nesta fatia.** É decisão do sponsor (custo
  recorrente mais validação de identidade da entidade), e a reputação do certificado só se acumula
  com volume de downloads: comprar antes de existir distribuição não resolve o aviso no curto prazo.

## 8. Achados

Um item por linha: o que aconteceu, em que passo, e o que se esperava. **Não corrigir aqui.**
Corrigir o que o BL-7 achar é fatia própria.

| # | Passo | O que aconteceu | O que se esperava | Gravidade |
|---|---|---|---|---|
| 1 | | | | bloqueia / bug de fatia / cosmético |

## 9. Anexos

Screenshots conforme os nomes do `CHECKLIST.md`, mais os JSON gerados pelos helpers:

- `perfil-usuario-antes.json` - baseline do perfil do usuário (`§1`)
- `assert-bl3.json` - resultado da asserção BL-3 (`§12`, `§17`, `§19`)
- `reconciliacao-*.json` - um por medição de perfil (`§11`, `§14`, `§20A`, `§20B`)
- `RESULT-esqueleto.md` - ambiente e procedência (Fechamento)
