# `#036` - O `CHECKLIST.md` do BL-7 volta a medir o produto que existe

**Executado em:** 2026-09-20 · branch **`feat/036-checklist-bl7-volta-a-medir-o-produto`**
**Base:** `develop` = `28e1f8b` · **Bancada:** Windows 11 Pro 10.0.26200 · Windows PowerShell 5.1
**Tipo:** fatia de verificação e evidência. **Nenhum arquivo de aplicação mudou.**

**Esta fatia não rodou a VM.** Ela reescreve o roteiro que a VM vai executar.

---

## 0. Legenda (`E.6`)

| marca | significa |
|---|---|
| **medido** | número obtido nesta bancada, nesta sessão, com evidência |
| **relatado** | veio de outra sessão ou de outro observador, identificado como tal |
| **`N/E`** | não medido, nomeado, com o motivo |

---

## VEREDITO

> ### O roteiro não estava desatualizado em seis pontos. Ele estava descrevendo outro produto
>
> O briefing listou seis problemas, e os seis existem. **A varredura `E.3` achou um sétimo, maior
> que os outros seis somados:** o checklist inteiro descrevia a **via A2a**, em que o instalador
> **encadeava o MSI oficial do QGIS**, exigia **elevação**, punha o produto em
> `C:\Program Files\IMAN Terra` e o QGIS em `C:\Program Files\QGIS 3.44.13`.
>
> **Nada disso é verdade desde a fatia `#019`** (via A1, 2026-09-07). O próprio `.iss` registra a
> ruptura na linha 17: *"a premissa violada do CHECKLIST 0.2: PrivilegesRequired volta a 'lowest'"*.
>
> **Placar da varredura: `21 de 21` passos com veredito declarado.**
> **`6` valem como estavam · `11` reescritos · `4` removidos por perda de objeto.**
> **`5` passos novos entraram.** O roteiro passou de 21 passos em 4 rodadas para **21 passos em 4
> rodadas**, com **12 dos 21 medindo coisa diferente** do que mediam antes.
>
> As duas dívidas que o briefing já tinha corrigido na emissão (`D1` e `D3`) continuam pagas, e o
> laudo não as reabre.

---

## 1. STOP-AND-FLAG: o tamanho do dano era maior que o diagnóstico

O briefing pediu, na entrega 1, confrontar os passos *"contra tudo que entrou de `#019` a `#033`"*.
É exatamente onde estava o problema, mas a lista de sintomas do briefing (os seis itens) não o
alcança. Registro a diferença, porque ela muda a forma da entrega:

| o briefing diz | a varredura mediu |
|---|---|
| "o `§15` está STALE" | **verdade**, e continua sendo o `§20` reescrito |
| "a superfície de `#029`, `#030` e `#033` está ausente" | **verdade** |
| "nenhum passo pergunta de que build o produto é" | **verdade**, virou o `§7` |
| "`5.3` e `5.4` são RELATADO e a diferença entre `/qb` e `/qb!-` não foi medida" | **perdeu objeto**: não há mais `msiexec` para receber flag nenhuma |
| "`6.3` é insensível ao defeito" | **verdade**, virou smoke declarado |
| "o `RESULT.md` é da rodada invalidada" | **verdade**, e era ainda mais velho: listava 14 passos de antes da `#011` |
| (não listado) | **a rodada M2a inteira perdeu objeto**: o `DB-16` (o ramo "já instalado: PULANDO") não existe mais |
| (não listado) | **a rodada M2b inteira perdeu objeto**: a detecção do QGIS e o teste dela morreram no commit `a1b0c37` |
| (não listado) | **a rodada M4 perdeu o mecanismo**: ela forçava a falha do MSI encadeado |
| (não listado) | **`§3` (elevação) estava invertido**: esperava `1` prompt de UAC; o esperado hoje é `0` |
| (não listado) | **`§4` e `§5` apontavam para `C:\Program Files`**: hoje é `%LOCALAPPDATA%\Programs` |
| (não listado) | **`§12` trazia um aviso vencido**: o `THIRD_PARTY_NOTICES.md` foi corrigido na `#020` |

**Nada disso foi consertado no produto**, e nada precisava ser: o produto está certo, o roteiro é
que descrevia o anterior. A fatia ficou dentro do escopo declarado (*"checklist não é lugar de
consertar produto"*).

---

## 2. Varredura `E.3` - os 21 passos antigos, um a um (`A1`)

Legenda: **vale** = o passo continua medindo o que se propõe · **reescrito** = mesma pergunta, outra
asserção ou outro motivo · **removido** = a pergunta perdeu objeto.

| # antigo | assunto | veredito | motivo | onde está hoje |
|---|---|---|---|---|
| **1** | baseline do perfil do usuário | **vale** | o procedimento (instalar QGIS, sujar, desinstalar, medir) continua sendo a única forma de ter baseline com conteúdo | `§1` |
| **2** | SmartScreen, wizard, créditos | **reescrito** | ganhou `3.5` (nenhuma UI de terceiro no meio, que é a via A1 visível na tela) e `3.6` (a chapa cinza do `DB-21`, que nunca teve passo) | `§3` |
| **3** | elevação, conte os prompts, `PASS` se **1** | **reescrito** | **invertido**: sem `msiexec` encadeado nada pede elevação. `PASS` se **0**, e qualquer prompt é achado | `§4` |
| **4** | onde o produto foi parar (`C:\Program Files`, atalhos all-users, QGIS em Program Files) | **reescrito** | destino mudou para `%LOCALAPPDATA%\Programs`, atalho por usuário, ARP em `HKCU`. Ganhou "e onde ele **não** foi" | `§5` |
| **5** | o QGIS entrou junto, progresso, `/qb!-`, `3010` | **reescrito** | o `DB-19` perdeu objeto (não há espera bloqueante de terceiro). `5.3`/`5.4` (flags do msiexec) e `5.7`/`5.8` (Program Files, Aplicativos) **saíram**. Entrou a contagem da árvore contra o manifesto, como **piso** | `§6` |
| **5b** | checkbox final, `DB-20` | **vale**, motivo reescrito | a raiz do `DB-20` (sondar `%ProgramFiles%`) morreu na `#019`. O que continua diferente entre os dois caminhos é a **redireção de `%SystemRoot%\System32`** sob pai de 32 bits, e o launcher chama três utilitários por lá | `§8` |
| **6** | primeiro run: splash, título, ícone, HOME, chrome, toolbar | **reescrito** | `6.3` (ícone) virou **smoke declarado**; o título ganhou o critério por região do `#022` (termina em ` - IMAN Terra`, sem `QGIS`, sem colchete de perfil) | `§9` |
| **7** | ícone em 16x16 (`D1`) | **vale** | é a medição de que o smoke do `§9` não dá conta. Já estava pago, e continua | `§10` |
| **8** | os três sinais do perfil (`S4`) | **reescrito** | "o plugin está lá" passa com plugin **velho**. Ganhou comparação por SHA-256 contra o template **instalado** e a `base.json`. Virou o estado (a) da reconciliação | `§11` |
| **9** | BL-3, perfil do usuário intacto | **vale**, motivo reescrito | o risco mudou de dono: era um instalador **de terceiro** rodando elevado; hoje é a **nossa** rotina de reconciliação escrevendo num perfil a cada abertura | `§12` |
| **10** | ciclo HOME e canvas, 3 vezes | **vale** | inalterado | `§13` |
| **11** | segundo run, idempotência | **reescrito** | virou o estado (b) da reconciliação, com hash e `template_digest`. O `QGISCUSTOMIZATION3.ini` continua, e agora com o motivo escrito (o `splashpath` saiu do launcher na `#030`) | `§14` |
| **12** | créditos do QGIS | **reescrito** | entraram `SOURCE_CODE.md` e "o Sobre **nativo** do QGIS continua no menu". **Saiu** o aviso de que o `THIRD_PARTY_NOTICES.md` não cobria obrigação de redistribuidor: foi pago na `#020` | `§15` |
| **13** | desinstalar | **reescrito** | `13.4` ("o QGIS continua instalado e abre") **removido**: o `DB-11` perdeu objeto. Entrou `17.2` (nenhum `.pyc` sobrando, dos 817 medidos em 2026-09-07) | `§17` |
| **14** | reinstalar por cima | **reescrito** | virou a asserção do `DB-22`, com **contagem de arquivos**, e não "instalou sem erro". `14.2` ("pula o QGIS") saiu junto com o encadeamento | `§18` |
| **15** | atualizar de versão anterior, **espera-se FAIL** | **reescrito por inteiro** | o defeito foi consertado na `#030`. O esperado agora é **PASS**, e o passo virou dois sub-passos com baseline `E.1` numérico | `§20A`, `§20B` |
| **16** | M2a: o instalador **pula** o QGIS, log `PULANDO` / `Encadeando` | **removido** | `DB-16` perdeu objeto. O código que escrevia aquelas duas linhas saiu na `#019`. Procurar a linha num log que ninguém mais escreve daria `N/E` para sempre | - |
| **16b** | M2a: checkbox final na rodada com QGIS presente | **removido** | o que a tornava um percurso distinto era ter **pulado o encadeamento**. Sem encadeamento, é o mesmo percurso do `§8` | - |
| **17** | M2b: coexistência `3.44.12` x `3.44.13` | **removido e substituído** | media a **detecção**, que morreu com o teste dela em `a1b0c37`. A pergunta que sobrou, e que ficou mais importante, é se o produto **se mete** com o QGIS da máquina | `§19` (novo) |
| **18** | M4: forçar falha do MSI do QGIS | **reescrito** | os três métodos (encher disco, matar `msiexec`, provocar `1618`) eram do encadeamento. Sobrou a pergunta boa: **cancelar no meio da cópia deixa a máquina como estava?** | `§21` |
| **19** | fechamento e placar | **reescrito** | ganhou a procedência e a tabela dos três estados da reconciliação | Fechamento |

### Passos NOVOS

| # | assunto | por que ele nasce |
|---|---|---|
| `§2` | SHA-256 e `BUILD_INFO` do artefato | era preparação sem veredito (`0.4`). Virou passo numerado, porque "o arquivo chegou quebrado" e "o produto está quebrado" são conclusões diferentes |
| `§7` | **procedência** do produto instalado | `A3`. Sem ele o laudo é relatório sobre binário anônimo: `versão 0.3.0` é string idêntica em todo artefato `0.3.0` já compilado |
| `§16` | a guarda de integridade **recusa** abrir sobre árvore quebrada | a promessa central da via A1 nunca foi exercitada numa VM. Uma cópia truncada do QGIS não dá erro: devolve coordenada errada em silêncio |
| `§19` | o produto ignora o QGIS da máquina | substitui a M2a e a M2b por uma pergunta que ainda tem objeto |
| `§20B` | semente `8cc4d5e^`: obsoletos saem, CRS corrige | é o único sub-passo em que o `CRS` e os `obsoletos` **discriminam**. Com a semente `ba58d14` o CRS já sai certo |

---

## 3. Varredura `E.2` - "o que este passo devolve com o defeito presente?" (`A5`)

**Todos os 21 passos do roteiro novo carregam a resposta escrita**, num bloco `Com o defeito
presente:` logo abaixo da tabela de asserções. Os casos que a varredura mudou de forma:

| passo | com o defeito presente, o passo antigo devolvia | o que mudou |
|---|---|---|
| `§9.7` (era `6.3`) | **o mesmo**: "é o ícone IMAN" passa com ícone edge-to-edge, cortado ou desproporcional | fica, **declarado como smoke**. Não foi apagado por reflexo: ele ainda pega a troca grosseira (o logo do QGIS reaparecendo), e a medição é o `§10` |
| `§4` (era `3`) | um instalador que voltasse a elevar **instalaria com sucesso** | a asserção passou a ser o **número** de prompts, não o resultado da instalação |
| `§6.3` (era `5.7`) | "o executável existe" passa com árvore pela metade | a asserção passou a ser a **contagem** contra o `TOTAL` do manifesto, como piso |
| `§11.4` (era `8.1`) | "o plugin está ativo" passa com plugin **velho** | comparação por SHA-256 contra o template instalado |
| `§16` | não existia | é o único passo que **quebra** a instalação de propósito. Sem quebrar, a guarda passaria nos dois mundos |
| `§18.2` (era `14.1`) | "instala normalmente" passa com a árvore **fundida** de dois builds | virou contagem de arquivos |
| `§19` (era `17.4`) | com o produto abrindo um QGIS de sistema do **mesmo** 3.44.13, tudo pareceria certo | a asserção é o **caminho do processo**, e o `19.2` nomeia o que não pode aparecer |
| `§21` | a falha era provocada num mecanismo que não existe | virou cancelamento da cópia, com quatro asserções de "não sobrou nada" |

**Os antigos `5.3` e `5.4` não viraram medição nem continuaram `RELATADO`: eles saíram.** A pergunta
que faziam (`/qb` contra `/qb!-`) era sobre a UI do `msiexec` encadeado, e não há mais `msiexec`
nenhum no percurso. Mantê-los como `RELATADO` seria carregar para sempre um campo que ninguém pode
preencher.

---

## 4. `A4` - reconciliação nos três estados, com baseline numérico

| estado | passo | baseline exigido antes de asserir | esperado depois |
|---|---|---|---|
| **(a)** perfil ausente | `§11` | o perfil **não existe** antes da primeira abertura | `ARQUIVOS 10 de 10`, `SOBRAS 0`, `BASE` gravada |
| **(b)** perfil igual | `§14` | os números do `§11` | idênticos, `[Customization] x1`, `splashpath x1` |
| **(c)** perfil velho, `ba58d14` | `§20A` | `RAIOS58 14` · `RAIOS2 0` · `SUFIXO 0` · `ARQUIVOS 3 de 10` · `BASE AUSENTE` | `RAIOS58 0` · `RAIOS2 20` · `SUFIXO 3` · `ARQUIVOS 10 de 10` |
| **(c)** perfil velho, `8cc4d5e^` | `§20B` | `OBSOLETOS 2` · `CRS EPSG:4674` · `CHAVES 1 ausente, 2 diferentes` · `ARQUIVOS 2 de 10` | `OBSOLETOS 0` · `CRS EPSG:31984` · `CHAVES 0 e 0` · `ARQUIVOS 10 de 10` |

**Os baselines das duas sementes foram MEDIDOS nesta bancada**, não estimados: saíram do helper novo
rodando contra o produto `0.3.0-5f7a1cb` instalado, em 2026-09-20. É o que o `E.1` exige: se o
perfil semeado já sair igual ao template novo, a rodada não prova nada e ainda alarma, e a ordem
escrita no passo é **parar e refazer**.

---

## 5. O que foi medido nesta bancada (a fatia não é só texto)

O roteiro novo depende de um helper que não existia. Ele foi escrito, **rodado** e corrigido aqui.

### 5.1 `assert-reconciliacao.ps1`, contra o perfil REAL do sponsor

```
ARQUIVOS  : 10 de 10 arquivos DO PRODUTO com SHA-256 do template instalado
SOBRAS    : 0     OBSOLETOS : 0     PASTAS : 0 faltando de 2
CHAVES    : 0 do template ausentes, 0 com outro valor (de 8)
CRS       : projeto=EPSG:31984   camada=EPSG:31984
BASE      : existe   template_digest=05DE72FB...BBC0   chaves=8
[OK]  o que e do produto esta como este build instalou, e a base esta registrada.
```

**Modo somente leitura, sem escrever no perfil.** O `template_digest` bate com o que a `#033`
mediu, e com o que o perfil real registrou sozinho em 2026-09-19.

### 5.2 As duas sementes, num perfil descartável

Semeadas em `%APPDATA%\InstitutoIMAN\_bl7-smoke\...` (nunca o perfil real), e **removidas ao fim**.
O perfil do sponsor tinha 26 arquivos antes e 26 depois.

```
ba58d14  : RAIOS58 14 · RAIOS2 0 · SUFIXO 0 · ARQUIVOS 3 de 10 · BASE AUSENTE
8cc4d5e^ : OBSOLETOS 2 · CRS EPSG:4674 · CHAVES 1 ausente + 2 diferentes · ARQUIVOS 2 de 10
```

### 5.3 Dois defeitos no meu próprio helper, achados por rodá-lo

Ambos teriam produzido **FAIL falso numa VM**, que é exatamente o que esta fatia existe para evitar.

| defeito | como apareceu | conserto |
|---|---|---|
| comparar o `QGIS3.ini` **por hash** | o perfil real do sponsor, perfeitamente são, saiu `NAO CONFERE` com `DIVERGE QGIS/QGIS3.ini (hash)` | o arquivo é **compartilhado**: o produto declara **chaves** nele, e o próprio QGIS o reescreve a cada sessão. Passou a ser comparado **por chave**, e a fronteira é lida do `PERFIL-DO-PRODUTO.json`, que é o mesmo arquivo que o `Sync-Perfil.ps1` lê |
| `RelativosDe` devolvendo `ArrayList` como **um objeto** | `-notcontains` comparava a lista inteira com uma string, e **todo** arquivo do plugin virava "sobra" | tipo de retorno declarado `[string[]]`, e o comentário do porquê ficou no código |

### 5.4 `collect-evidence.ps1`

Rodado aqui, com a procedência nova saindo certa: `commit_curto=5f7a1cb`, `build_canonico=sim`,
`prefixo coerente: True`, árvore `38156` contra `TOTAL 37337` (piso, não igualdade), escopo
`por usuario (HKCU, sem elevacao)`.

Um terceiro defeito foi achado e corrigido aqui: a chave `payload_sha256` **nunca casava**, porque o
padrão de leitura era `^([a-z_]+)=` e o nome tem dígitos. Saía `nao detectado` num arquivo que a
trazia.

---

## 6. `A6` - a spec de ambiente continua, e a justificativa também

O `§0.4` mantém 1366x768 a 125 %, Windows 11 pt-BR e snapshot limpa por rodada, com a nota do
porquê: **o 125 % existe para provocar estresse de DPI**, e em 2026-07-30 a VM saiu em 1024x768 a
100 %, o que virou achado. **Desvio de ambiente é achado, não nota de rodapé**, e o `RESULT.md` tem
uma linha própria para os três desvios que invalidam parte da rodada.

**Um item da spec mudou, e mudou de sentido:** era *"usuário com direito de elevação (administrador,
ou senha de admin disponível)"*; passou a ser **"usuário comum, SEM direito de administrador"**. A
premissa antiga entrou na `#011` porque o MSI do QGIS é `ALLUSERS=1`; ela voltou ao normal na `#019`.

---

## 7. `A7` - o checklist diz qual build a rodada usa

O `§0.2` é a primeira coisa a preencher, antes de qualquer passo, e cita o candidato vigente na
emissão (**`0.3.0-5f7a1cb`**, `sha256=949A960F...EFF5`) com a instrução de **não presumir que ainda
é esse**: abrir o `installer/canonico/VIGENTE.txt` da `develop` na hora. O `§7` fecha o par, lendo a
identidade **de dentro do produto instalado** e confrontando com ela.

---

## 8. `A2` - nenhum passo STALE sobrou

O único passo marcado STALE era o `§15`, e ele foi reescrito nos `§20A` e `§20B`. Varri o arquivo
novo atrás de marcas de dívida: as palavras "STALE" e "FAIL" como expectativa aparecem em **duas
linhas**, as duas dentro do aviso que **narra o passo antigo** (*"substitui o antigo `§15`, que
estava STALE"*, *"Ele mandava esperar FAIL"*). **Nenhuma instrução ativa** manda esperar FAIL ou
avisa para não executar um passo. O aviso histórico fica de propósito: quem conhecia o roteiro
antigo precisa saber por que o número mudou de sentido.

---

## 9. `#6` - as dívidas, e onde elas foram registradas

Oito laudos, de `#007` a `#033`, dizem que reescrever o `CHECKLIST.md` é fatia própria. **Esta é a
fatia.**

### Fecham aqui

| dívida | onde estava registrada | o que fecha |
|---|---|---|
| "reescrever o `CHECKLIST.md` é fatia própria" | `#019` §11, `#021`, `#022`, `#025`, `#027`, `#028`, `#030`, `#033` | o roteiro passa a descrever a via A1 |
| `§15` STALE desde o `DB-26` | `#030` §7.1, com o procedimento e a matriz de estados | `§20A` e `§20B`, com os números do `#030` e a medição de `{app}` do `#033` |
| a superfície do `#029`, `#030` e `#033` ausente do roteiro | briefing `#036` | `§7` (procedência), `§11`, `§14`, `§20` (reconciliação), `§0.2` (candidato vigente) |
| o placeholder `<versao>` no nome do `.exe` | `#029`, citando `CHECKLIST.md:86` e `:521` | o nome aparece como `<versao>-<commit>` em todas as ocorrências |
| a premissa de elevação violada | `#019`, na tabela *"o que morreu junto com o msiexec encadeado"* (`DB-7` **inverteu**), e o comentário do `.iss` linha 17 | `§0.4` e `§4` |
| o `RESULT.md` da rodada invalidada | briefing `#036` | modelo refeito, com legenda `E.6`, placar em `n de N` e procedência |
| o aviso vencido sobre o `THIRD_PARTY_NOTICES.md` | `CHECKLIST.md` §12 | removido; o `#020` pagou, e o `SOURCE_CODE.md` entrou como asserção |

### Sobrevivem, e continuam nomeadas

| dívida | por que não fecha aqui |
|---|---|
| **rodar o BL-7 de verdade** | esta fatia entrega o roteiro, não a rodada. O `RESULT.md` continua com o aviso de não preenchido |
| **`M-D11`** (ícone na barra de tarefas, agrupamento) | não é observável de dentro do processo; é passo manual, e continua `N/E` no aceite |
| **assinatura de código** | decisão do sponsor, com custo recorrente. O `RESULT.md` §7 mantém o encaminhamento já decidido |
| **servir de fato o fonte correspondente** (item do `DB-6`) | é do sponsor, e é pré-condição de release. O checklist **cita** como asserção de pacote (`§15.4`), não resolve |
| **`D2`** (reconciliação splash x símbolo) | dívida separada, fatia própria, fora de escopo declarado |
| **`#023`** (travessão na distro) e **`DA-3`** (plugin REURB) | fatias próprias |
| **o perfil de um usuário de verdade** | a `M3` mede o **mecanismo** da reconciliação, com sementes da história. Ela não substitui um piloto com meses de uso. Está escrito no `RESULT.md` §6 |

---

## 10. O que esta fatia NÃO fez, de propósito

- **Não rodou a VM.** Fora de escopo declarado.
- **Não mudou comportamento do produto.** A varredura achou o roteiro errado, não o produto. Nenhum
  arquivo de `app/` ou `installer/` foi tocado.
- **Não apagou o `§9.7` por reflexo.** O briefing avisou, e o passo insensível virou smoke
  declarado, com a medição ao lado.
- **Não inventou número.** Todo valor esperado nos passos novos ou saiu de laudo anterior (`#019`,
  `#020`, `#021`, `#030`, `#033`) ou foi medido nesta sessão, e a §5 diz qual é qual.

## 11. Ship

Fatia de documento e ferramenta: **branch e PR normal**. A exceção do build canônico não se aplica
aqui, porque esta fatia não compila nada.
