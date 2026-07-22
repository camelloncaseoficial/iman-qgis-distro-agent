# BL-7 — Resultado da verificação em VM limpa

> **STATUS: MODELO NÃO PREENCHIDO — a verificação em VM limpa AINDA NÃO FOI EXECUTADA.**
> Enquanto esta linha estiver aqui, o BL-7 continua **aberto** e nenhum release pode alegar
> "validado em máquina limpa". Quem executar: preencha, apague esta citação e commite.

Execução do roteiro `CHECKLIST.md`. Preencher **durante** o teste, não de memória.

---

## 1. Artefato testado

| Campo | Valor |
|---|---|
| Arquivo | `Instituto-IMAN-IMAN-Terra-Setup-______.exe` |
| ProductVersion | |
| Commit | |
| Branch / build canônico | |
| SHA-256 do `BUILD_INFO.txt` | |
| SHA-256 conferido na VM | |
| **Os dois SHA-256 batem?** | `SIM / NÃO` |
| Data do teste | |
| Executado por | |

> Se os SHA-256 **não** batem, o teste é inválido: não se sabe qual artefato foi exercitado.

## 2. Ambiente

*(cole aqui a saída de `tools\bl7\collect-evidence.ps1` — `RESULT-esqueleto.md`)*

| Campo | Valor |
|---|---|
| Windows (edição, versão, build) | |
| Idioma | |
| Sessão de administrador | `SIM / NÃO` |
| Resolução | |
| Escala de exibição | |
| **Versão do QGIS testada** | |
| VM-A (sem QGIS) usada? | `SIM / NÃO` |
| VM-B: perfil do usuário estava sujo antes? | `SIM / NÃO` |
| `.exe` chegou por download HTTP? | `SIM / NÃO` |

> **Perfil do usuário sujo** e **download HTTP** não são detalhe: sem o primeiro o BL-3 não é
> testável; sem o segundo o SmartScreen real não aparece.

## 3. Resultado por passo do checklist

| Passo | Assunto | PASS/FAIL | Observação |
|---|---|---|---|
| 1 | VM-A: mensagem de QGIS ausente | | |
| 2 | Baseline do perfil do usuário | | |
| 3 | SmartScreen, wizard pt-BR, licença | | |
| 4 | Instalação sem elevação | | |
| 5 | Primeiro run (splash/título/ícone/HOME/tema/toolbar) | | |
| 6 | Perfil carregou: plugin + CRS + QSS | | |
| 7 | BL-3: perfil do usuário intacto + perfil isolado criado | | |
| 8 | Ciclo HOME ↔ canvas 3× | | |
| 9 | Segundo run: idempotência | | |
| 10 | Créditos (LICENSE / NOTICES / README / Sobre) | | |
| 11 | Uninstall: remove `{app}`, **preserva** `%APPDATA%\InstitutoIMAN` | | |
| 12 | Reinstalação sobre o perfil sobrevivente | | |

## 4. Veredito por invariante de marca/licença

| Invariante | O que exige | PASS/FAIL | Evidência |
|---|---|---|---|
| **BL-1** | Créditos do QGIS presentes (LICENSE, THIRD_PARTY_NOTICES, "powered by QGIS", Sobre credita o QGIS) | | passo 10 |
| **BL-2** | Nada se apresenta como QGIS oficial ou endossado pela QGIS.ORG | | passo 3 |
| **BL-3** | Perfil/instalação do QGIS do usuário **intactos**; perfil isolado próprio; uninstall não apaga dados do usuário | | passos 7 e 11 |
| **BL-4** | Marca visível consistente (nome, ícones, artes) vindo da fonte única | | passos 3, 5 |
| **BL-5** | Ausência do QGIS é tratada com mensagem humana, sem stacktrace | | passo 1 |
| **BL-7** | O ciclo completo foi exercitado **em máquina limpa** | | este documento |

*(BL-6, se aplicável ao release, é preenchido aqui do mesmo jeito.)*

## 5. Regra de corte — vale como escrita, não como opinião

> **FAIL em BL-1, BL-2 ou BL-3 → BLOQUEIA o release. Sem discussão, sem "corrige depois".**
> São crédito de terceiros, autoria e dado do usuário: os três criam dano que um patch posterior
> não desfaz (o usuário já perdeu o arquivo; a QGIS.ORG já foi mal-representada).
>
> **FAIL visual (fatia #006 — layout, tema, HOME, tela-fantasma) → NÃO bloqueia por si.**
> É bug de fatia: vira briefing para o arquiteto e entra na fila normal.
>
> **A versão do QGIS efetivamente testada VIRA a versão suportada declarada do release.**
> Não se infere compatibilidade com outras versões. Suportar mais uma versão = rodar este
> checklist nela. Ver `docs/distro-architecture.md`.

**Veredito final:** `LIBERADO / BLOQUEADO` — justificativa: `____________________`

## 6. SmartScreen (instalador NÃO assinado)

O instalador **não é assinado por certificado de código**. Consequência esperada: o SmartScreen
exibe um aviso na primeira execução do `.exe` baixado.

| Campo | Valor |
|---|---|
| Apareceu? | `SIM / NÃO` |
| Título da janela | |
| **Texto literal exibido** | |
| Existe o link "Mais informações"? | `SIM / NÃO` |
| Após "Mais informações → Executar assim mesmo", instalou? | `SIM / NÃO` |

**Encaminhamento (decidido nesta fatia):**

- Documentar no guia de instalação o caminho **"Mais informações → Executar assim mesmo"**, com o
  texto literal capturado acima e o SHA-256 do artefato para o usuário conferir. Aviso do
  SmartScreen sem explicação prévia é a principal causa de desistência na instalação.
- **NÃO comprar certificado de assinatura de código nesta fatia.** É decisão do sponsor (custo
  recorrente + validação de identidade da entidade), e a reputação do certificado só se acumula com
  volume de downloads — comprar antes de existir distribuição não resolve o aviso no curto prazo.

## 7. Achados

Um item por linha: o que aconteceu, em que passo, e o que se esperava. **Não corrigir aqui** —
corrigir o que o BL-7 achar é fatia própria.

| # | Passo | O que aconteceu | O que se esperava | Gravidade |
|---|---|---|---|---|
| 1 | | | | bloqueia / bug de fatia / cosmético |

## 8. Anexos

Screenshots conforme os nomes do `CHECKLIST.md`, mais os JSON gerados pelos helpers:

- `perfil-usuario-antes.json` — baseline do perfil do usuário (passo 2)
- `assert-bl3.json` — resultado da asserção BL-3 (passo 7)
- `RESULT-esqueleto.md` — coleta de ambiente (passo 13)
