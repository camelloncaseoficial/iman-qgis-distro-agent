# BL-7 — Checklist de verificação em VM limpa

**Para quem executa:** este roteiro **não** exige conhecer o código. Cada passo tem o que fazer,
**o que você deve ver** (asserção), um campo de resultado e o nome do screenshot a salvar.
Se o que você viu não bate com a asserção, marque `FAIL` e **descreva literalmente o que apareceu** —
descrição fiel vale mais do que diagnóstico.

**O que está sendo verificado:** que a distro **IMAN Terra** instala **o QGIS junto com ela**, abre
com a cara certa, credita o QGIS e **não encosta nos dados do usuário** — numa máquina que nunca viu
este projeto.

> **Regra de ouro:** anote o que **aconteceu**, não o que deveria acontecer.

> ### ⚠ Este checklist foi REESCRITO na fatia #011 (`D-IMAN-028`)
>
> O produto **inverteu de premissa**: o instalador deixou de ser uma camada leve que **exige** o
> QGIS e passou a **embarcar e instalar** o QGIS (via **A2a**, MSI oficial encadeado, offline).
>
> As asserções antigas **"instalar sem elevar"** e **"na máquina sem QGIS aparece a mensagem de
> QGIS ausente"** foram **REMOVIDAS** — não porque falhavam, mas porque **testavam o produto
> anterior**. Rodá-las hoje produziria `FAIL` correto sobre asserção errada, em escala.

---

## 0. Preparação

### 0.1 Legenda dos resultados — leia antes de preencher

| Marca | Significa | Quando usar |
|---|---|---|
| `PASS` | **medido**, e bateu com a asserção | você executou e viu |
| `FAIL` | **medido**, e não bateu | você executou e viu outra coisa — **transcreva o que apareceu** |
| `RELATADO` | você observou algo relevante, mas **não é uma asserção com veredito** | ex.: transcrever o texto do SmartScreen |
| `N/E` | **não executado** | faltou tempo, faltou ambiente, travou antes |

> **`N/E` não é `PASS`.** Um passo não executado **nunca** vira "deve estar bom". Foi assim que a
> rodada de 2026-07-30 se perdeu. No fim, preencha o **placar**: `___ de ___ passos com evidência`.

### 0.2 As quatro rodadas

Cada rodada parte de um **snapshot limpo**. Só a **Rodada M1** roda o checklist inteiro; as demais
são curtas e focadas.

| Rodada | Estado inicial da máquina | O que prova | Passos |
|---|---|---|---|
| **M1** | **sem QGIS nenhum** | **o caminho feliz principal** — instalar um arquivo e abrir | 1 a 15 |
| **M2a** | QGIS **exatamente 3.44.13** já instalado | o instalador **pula** o QGIS (e prova que pulou) | 16 |
| **M2b** | QGIS **3.44.12** já instalado | **coexistência** + o launcher abre o **nosso** QGIS | 17 |
| **M4** | falha forçada no meio da instalação do QGIS | **aborta** deixando a máquina como estava | 18 |

> **A rodada M1 é a que mudou de sentido.** Antes, "máquina sem QGIS" servia para testar uma
> **mensagem de erro**. Agora é o **caminho feliz**: é a máquina do técnico de prefeitura que
> recebeu um arquivo e mais nada.

### 0.3 Configuração das VMs

- Windows 11 **pt-BR**
- **usuário com direito de elevação** (administrador, ou senha de admin disponível)
- **snapshot LIMPA** antes de cada rodada
- resolução **1366×768** com escala de exibição **125 %**

> **Sobre a elevação (`D-IMAN-028`/DB-7).** A premissa antiga — "usuário NÃO administrador, é assim
> que a TI de prefeitura entrega a máquina" — **caiu**. O MSI oficial do QGIS é `ALLUSERS=1`
> (per-machine) e **exige** elevação; não há como instalá-lo sem ela. **Isso é consequência aceita
> da via A2**, decidida pelo sponsor com o risco de adoção na mesa. O que este checklist mede é que
> a elevação seja **uma só** (passo 4).

> **Sobre os 125 %.** Não é capricho: o 125 % existe para **provocar** estresse de DPI, e é o pior
> caso do dashboard da HOME. Na rodada de 2026-07-30 a VM saiu em **1024×768 @ 100 %** e isso virou
> achado — testar em outra escala **esconde** exatamente os defeitos que interessam. Se não
> conseguir 1366×768 @ 125 %, **anote a configuração real** e marque os passos visuais como
> `RELATADO`, não `PASS`.

### 0.4 O instalador chega por DOWNLOAD HTTP

Publique o `.exe` num link (release privada, drive com link direto, servidor local) e **baixe pelo
navegador dentro da VM**.

> **Não copie por pasta compartilhada nem por área de transferência.** Só o download por HTTP marca
> o arquivo com o *Mark-of-the-Web*, que é o que faz o **SmartScreen real** aparecer.

> ⚠ **O arquivo agora tem ~558 MB** (o QGIS vai dentro). Um download interrompido é muito mais
> provável que antes — por isso a conferência abaixo deixou de ser formalidade.

```powershell
Get-FileHash .\Instituto-IMAN-IMAN-Terra-Setup-<versao>.exe -Algorithm SHA256
```

- [ ] O SHA-256 bate com o do `BUILD_INFO.txt` → **se não bater, PARE.**

Confira também no `BUILD_INFO.txt`, e **anote aqui**:

- QGIS embarcado: `__________` · Payload SHA-256 confere com o site oficial? `PASS / FAIL / N/E`

### 0.5 Helpers

Copie `tools\bl7\` para a VM (ex.: `Desktop\bl7`). São scripts de **PowerShell 5.1**: não precisam
de Python, git, internet nem módulos.

```powershell
Set-ExecutionPolicy -Scope Process -Bypass
```

Evidências caem em `Desktop\bl7-evidence\`.

---

# RODADA M1 — máquina sem QGIS (caminho feliz)

## 1. Baseline do perfil do usuário — **o passo que já invalidou uma rodada inteira**

Nesta rodada a máquina **não tem QGIS**, então `%APPDATA%\QGIS` **não existe** — e é exatamente aí
que mora a armadilha.

> ### ⚠ PARE E LEIA
> Em 2026-07-30 o baseline foi capturado com `RaizExiste: false` / `TotalArquivos: 0`. Depois, o
> `assert-bl3` devolveu `BL3a: false` **sem conseguir distinguir** "o produto invadiu o perfil" de
> "alguém abriu o QGIS stock". **Comparar pasta vazia com pasta vazia não prova nada** — e não há
> conserto retroativo: a rodada inteira virou trabalho perdido.

**Faça, nesta ordem, ANTES de instalar o IMAN Terra:**

1. Instale o **QGIS oficial 3.44.13** na VM (é o mesmo payload; instale-o **à mão**, só para sujar o
   perfil).
2. **Abra o QGIS uma vez**, mude uma configuração visível (um tema, um painel), **crie e salve um
   projeto**, e **feche**.
3. **Desinstale o QGIS** pelo Painel de Controle. O perfil em `%APPDATA%\QGIS` **sobrevive** ao
   uninstall — é justamente o que queremos.
4. Só então:

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\snapshot-user-profile.ps1 -Rotulo antes
```

**Asserção numérica, sem interpretação:**

- `TotalArquivos` no `perfil-usuario-antes.json`: `______`
- [ ] **É maior que zero?** → **se for `0`, PARE e refaça do item 1.** `PASS / FAIL`
- Screenshot: `01-baseline-perfil-usuario.png`
- Invariante: **BL-3**

> **Por que dar esse trabalho todo:** o BL-3 diz que o produto não pode tocar o perfil do usuário.
> Para provar isso, o perfil **precisa existir e ter conteúdo** antes. Uma máquina sem QGIS nunca
> teria — então nós o criamos e depois removemos só o programa.

---

## 2. Rodar o instalador — SmartScreen, wizard e créditos

**Faça:** execute o `.exe` baixado.

1. O **SmartScreen** provavelmente aparece (o instalador **não é assinado**). **Transcreva
   LITERALMENTE** o texto e o título, e anote se há *"Mais informações"*.
2. O wizard abre em **português do Brasil**, com as artes de marca IMAN.
3. Aparece a **tela de licença** antes de instalar.
4. **Nenhuma tela** sugere que isto é o QGIS oficial ou endossado pela QGIS.ORG.

| # | Asserção | Resultado |
|---|---|---|
| 2.1 | Texto literal do SmartScreen: `________________________________` | `RELATADO / N/E` |
| 2.2 | Wizard em pt-BR, com arte IMAN | `PASS / FAIL / N/E` |
| 2.3 | Tela de licença apareceu | `PASS / FAIL / N/E` |
| 2.4 | Nenhuma tela se passa por QGIS oficial | `PASS / FAIL / N/E` |

- Screenshots: `02a-smartscreen.png`, `02b-wizard-boas-vindas.png`, `02c-licenca.png`
- Invariantes: **BL-1 / BL-2**

---

## 3. Elevação — **conte os prompts** (S3)

**Faça:** conclua a instalação, prestando atenção em **quantas vezes** o Windows pede elevação.

> **O que se espera e por quê.** O MSI do QGIS é `ALLUSERS=1` e a elevação deve vir do **nosso**
> instalador, **uma única vez**, e ser **herdada** pelo QGIS. **Dois prompts é ACHADO**, não detalhe.

> ### ⚠ Esta asserção NÃO pode ser herdada da fatia #010
> A evidência de "não há segundo UAC" veio da linha `MSI_LUA: Elevation prompt disabled for silent
> installs`, observada sob **`/qn`** — e ela é, literalmente, **uma regra de instalação
> silenciosa**. A fatia #011 trocou a flag para **`/qb!-`** (`DB-19`), que **não é** instalação
> silenciosa. **A medição antiga não vale mais.** Conte os prompts do zero; marcar `PASS` por
> herança aqui é exatamente o que o gate proíbe.

| # | Asserção | Resultado |
|---|---|---|
| 3.1 | **Quantos** prompts de UAC apareceram no percurso inteiro: `______` | `PASS` se **1** |
| 3.2 | Algum prompt apareceu **no meio** (depois de já ter começado a instalar)? `SIM / NÃO` | `PASS = NÃO` |

- Screenshot: `03-uac.png`
- Asserção: **S3**

---

## 4. Onde o produto foi parar (S6)

**Faça:** anote o diretório final e confira os atalhos.

> Com elevação, `{autopf}` deve resolver para `C:\Program Files` (não mais
> `%LOCALAPPDATA%\Programs`), e os atalhos viram **all-users** (`D-IMAN-028`/DB-9). **O caminho
> medido em 30/07 deixou de valer.**

| # | Asserção | Resultado |
|---|---|---|
| 4.1 | Diretório de instalação: `________________________________` | `PASS` se `C:\Program Files\IMAN Terra` |
| 4.2 | Atalho do Menu Iniciar existe para **todos os usuários** | `PASS / FAIL / N/E` |
| 4.3 | O QGIS foi instalado em `C:\Program Files\QGIS 3.44.13` | `PASS / FAIL / N/E` |

- Screenshot: `04-local-instalacao.png`
- Asserção: **S6**

---

## 5. O QGIS entrou junto — progresso visível e cronometrado (`DB-19`)

> **O defeito que este passo existe para pegar.** Teste com usuário (2026-07-31): *"o instalador não
> tem nenhum indicativo de instalação em andamento quando está instalando o qgis, o usuário fica
> perdido achando que está travado."* Medido: a instalação do QGIS leva **~4 min 09 s**, e com a
> flag antiga (`/qn`) o msiexec mostrava **zero janelas** — silêncio total. O usuário não estava
> interpretando mal: com o message pump bloqueado, **o Windows marca a janela como "Não
> Respondendo"**.

**Faça:** durante a etapa do QGIS, **não toque em nada** e observe.

| # | Asserção | Resultado |
|---|---|---|
| 5.1 | Aparece uma **janela de progresso do QGIS** (barra que **anda**, não texto parado) | `PASS / FAIL / N/E` |
| 5.2 | O texto do nosso wizard diz que está instalando **o QGIS** e **quanto tempo leva** | `PASS / FAIL / N/E` |
| 5.3 | A janela de progresso do QGIS tem botão **Cancelar**? `SIM / NÃO` | `RELATADO` — esperado `NÃO` (`/qb!-`), mas **não medido** |
| 5.4 | No fim da etapa do QGIS, apareceu algum **modal exigindo clique**? `SIM / NÃO` | `RELATADO` — esperado `NÃO`; se `SIM`, é achado |
| 5.5 | A janela do IMAN Terra ficou "Não Respondendo" em algum momento? `SIM / NÃO` | `RELATADO` — o texto **avisa** que pode |
| 5.6 | **Tempo total** da instalação (do duplo-clique ao fim): `______ min` | `RELATADO` |
| 5.7 | `C:\Program Files\QGIS 3.44.13\bin\qgis-ltr-bin.exe` existe | `PASS / FAIL / N/E` |
| 5.8 | O QGIS aparece em Configurações → Aplicativos | `PASS / FAIL / N/E` |
| 5.9 | A instalação terminou **sem pedir reinício** | `PASS / FAIL / N/E` |

- Screenshot **obrigatório**: `05-progresso-qgis.png` — tire **durante** a etapa do QGIS, com a
  janela de progresso e o texto do wizard **na mesma imagem**.
- Screenshot: `05b-qgis-instalado.png` · Caso: **M1** · Asserção: **DB-19**

> **5.3 e 5.4 são `RELATADO`, não `PASS`, de propósito.** A escolha da flag `/qb!-` foi medida só
> via instalação administrativa (`/a`), e nela os modificadores `!` e `-` **não fizeram diferença
> observável** — o `Cancelar` apareceu nas quatro variantes. **A diferença entre `/qb`, `/qb!`,
> `/qb-` e `/qb!-` continua NÃO MEDIDA.** Este passo é onde ela finalmente se mede, sob `/i`.

> Se o instalador **pediu reinício**, isso é o código `3010` — **não é falha**, mas **anote**: é a
> primeira vez que ele seria observado (na fatia #010 ficou `NÃO MEDIDO`).

---

## 6. Primeiro run — cronometrado, na ordem

**Faça:** abra pelo atalho do Menu Iniciar. **Marque o tempo** até a janela ficar utilizável.

| # | O que deve aparecer | Resultado |
|---|---|---|
| 6.1 | **Splash com a arte IMAN** (não o splash padrão do QGIS) | `PASS / FAIL / N/E` |
| 6.2 | Título da janela contendo **IMAN Terra** | `PASS / FAIL / N/E` |
| 6.3 | Ícone **IMAN** na barra de tarefas (não o do QGIS) | `PASS / FAIL / N/E` |
| 6.4 | A **HOME de boas-vindas NO MIOLO** (área central, não painel lateral) | `PASS / FAIL / N/E` |
| 6.5 | Chrome **clara**, com o verde só de acento | `PASS / FAIL / N/E` |
| 6.6 | Toolbar de marca presente e enxuta | `PASS / FAIL / N/E` |

- Tempo até ficar utilizável: `______ s`
- Screenshots: `06a-splash.png`, `06b-primeira-tela.png`
- Fatias verificadas: **#005 + #006**

> Itens são independentes: se só o splash falhar, marque só o 6.1.

> **O que é "chrome clara" no 6.5.** Barra de menus, barra de status, títulos de painel (dock) e
> headers de tabela são **claros, com texto escuro**. O verde institucional aparece só como
> **acento**: item de menu ativo, seleção, sublinhado da aba ativa, botão default, foco.
> **Chrome verde-escura pintando essas superfícies é FAIL** — é a passada antiga, revertida pela
> suavização de 2026-07-15 a pedido do sponsor. Ver "Chrome CLARA" em `docs/design-system.md`.

---

## 7. O ícone na barra de tarefas, em 16×16 — **passo `D1`**

> **Por que este passo existe separado do 6.3.** O 6.3 pergunta "é o ícone IMAN e não o do QGIS?" —
> e passa **igual** com um ícone edge-to-edge, cortado ou desproporcional. Ou seja: **o 6.3 é
> insensível ao defeito**. Este passo olha o tamanho onde o defeito aparece: **16×16**.
>
> **Esta é a terceira tentativa de este passo entrar em `develop`** (órfão desde 2026-07-28).

**Faça:** com o IMAN Terra aberto, olhe o ícone **na barra de tarefas** e ao lado dos vizinhos
(Explorer, navegador). Se ajudar, aumente o zoom da tela numa captura.

| # | Asserção | Resultado |
|---|---|---|
| 7.1 | O **globo aparece INTEIRO** — não cortado nas bordas | `PASS / FAIL / N/E` |
| 7.2 | O ícone **não é desproporcional** ao lado dos vizinhos — nem "gordo" preenchendo tudo, nem miúdo perdido no meio do quadro | `PASS / FAIL / N/E` |

- Screenshot **obrigatório**: `07-icone-taskbar-16px.png` — enquadre o IMAN Terra **junto** de pelo
  menos dois ícones vizinhos, senão não dá para julgar proporção.
- Origem: **`D1`**

---

## 8. O perfil carregou de verdade — os TRÊS sinais (S4)

**Por que os três:** na fatia 1 houve um bug em que o QGIS abria **bonito mas com perfil vazio**
(o caminho virava `profiles\profiles\`). Um sinal isolado engana; os três juntos, não.

| # | Onde olhar | O que deve estar lá | Resultado |
|---|---|---|---|
| 8.1 | Complementos → Gerenciar e Instalar Complementos → Instalados | **`iman_brand` ativo** (marcado) | `PASS / FAIL / N/E` |
| 8.2 | Projeto → Propriedades → SRC (ou o SRC na barra de status) | o **CRS padrão** da distro | `PASS / FAIL / N/E` |
| 8.3 | A janela | **QSS aplicado** (cores IMAN, não o tema padrão) | `PASS / FAIL / N/E` |

- Screenshot: `08-plugin-crs-tema.png`
- **Os três precisam passar.** Dois em três = FAIL do passo.
- Asserção: **S4** · Regressão coberta: **fatia 1**

---

## 9. O perfil do usuário continua intacto (S5) — bloqueia release

**Faça: FECHE o IMAN Terra e o QGIS**, depois:

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\assert-bl3.ps1 -Baseline "$env:USERPROFILE\Desktop\bl7-evidence\perfil-usuario-antes.json"
```

| # | Asserção | Resultado |
|---|---|---|
| 9.1 | `[BL-3a]` — perfil do usuário **byte-idêntico** ao passo 1 (0 divergências) | `PASS / FAIL / N/E` |
| 9.2 | `[BL-3b]` — perfil isolado criado em `%APPDATA%\InstitutoIMAN\IMAN Terra\profiles\iman-distro` | `PASS / FAIL / N/E` |

- Se `FAIL`, **copie a lista de DIVERGENTES inteira** para o `RESULT.md`.
- Screenshot: `09-assert-bl3.png` · Evidência: `Desktop\bl7-evidence\assert-bl3.json`
- Invariante: **BL-3 — inegociável. FAIL aqui BLOQUEIA o release.**

> **O BL-3 ficou MAIS crítico com A2, não menos.** Agora um instalador **de terceiro** (o MSI do
> QGIS) roda **elevado** dentro do nosso percurso. A análise estática da fatia #010 diz que ele não
> tem por onde escrever em `%APPDATA%\QGIS` (nenhuma pasta de perfil no pacote, sem tabela
> `Registry`, e os scripts `postinstall.bat`/`preremove.bat` não citam `%APPDATA%`). **Isso é
> evidência estática — este passo é o que a confirma na prática.**

---

## 10. Ciclo HOME ↔ canvas, 3 vezes

**Faça, três vezes:** na HOME abra o **projeto demo** → vai para o **canvas**; **Projeto → Novo** →
volta para a **HOME**.

**Não pode** sobrar "tela-fantasma" nem área cinza vazia.

- Volta 1 `PASS / FAIL / N/E` · Volta 2 `PASS / FAIL / N/E` · Volta 3 `PASS / FAIL / N/E`
- Screenshots: `10a-demo-canvas.png`, `10b-novo-home.png` · Guardrail: **#006**

---

## 11. Segundo run — idempotência

| # | Asserção | Resultado |
|---|---|---|
| 11.1 | Abre **mais rápido** que o primeiro run | `PASS / FAIL / N/E` |
| 11.2 | O splash IMAN aparece de novo | `PASS / FAIL / N/E` |
| 11.3 | A HOME aparece de novo | `PASS / FAIL / N/E` |
| 11.4 | Suas alterações do run anterior continuam lá | `PASS / FAIL / N/E` |

```powershell
Get-Content "$env:APPDATA\InstitutoIMAN\IMAN Terra\profiles\iman-distro\QGIS\QGISCUSTOMIZATION3.ini"
```

Deve ter **exatamente um** `[Customization]` e **uma** linha `splashpath=`.

- Linhas duplicadas? `SIM / NÃO` → **PASS = NÃO** · Screenshot: `11-segundo-run-customization.png`

---

## 12. Créditos do QGIS

| # | Onde | O que deve estar lá | Resultado |
|---|---|---|---|
| 12.1 | pasta instalada | **`LICENSE`** | `PASS / FAIL / N/E` |
| 12.2 | pasta instalada | **`THIRD_PARTY_NOTICES.md`** | `PASS / FAIL / N/E` |
| 12.3 | pasta instalada | **`README.md`** | `PASS / FAIL / N/E` |
| 12.4 | `Ajuda → Sobre` | credita o **QGIS** | `PASS / FAIL / N/E` |
| 12.5 | visível | **"powered by QGIS"** | `PASS / FAIL / N/E` |
| 12.6 | visível | aviso de **independência** | `PASS / FAIL / N/E` |

- Screenshots: `12a-pasta-instalada.png`, `12b-sobre.png` · Invariante: **BL-1**

> ⚠ **Achado esperado, e é para registrar como tal:** o `THIRD_PARTY_NOTICES.md` **ainda não cobre**
> as obrigações de **redistribuidor** (`D-IMAN-028`/DB-6) — QGIS GPL-2.0-or-later com oferta de
> fonte, Qt (LGPL), GDAL, PROJ, GEOS, Python. **É fatia própria, obrigatória antes de distribuir.**
> Aqui só se **constata**. Esta rodada **constrói e testa; não distribui.**

---

## 13. Desinstalar — e o que tem que SOBRAR

**Faça:** Configurações → Aplicativos → IMAN Terra → Desinstalar.

| # | Asserção | Resultado |
|---|---|---|
| 13.1 | A pasta de instalação foi **removida** | `PASS / FAIL / N/E` |
| 13.2 | Os atalhos foram **removidos** | `PASS / FAIL / N/E` |
| 13.3 | `%APPDATA%\InstitutoIMAN` **CONTINUA LÁ** | `PASS / FAIL / N/E` |
| 13.4 | **O QGIS CONTINUA INSTALADO e abre** | `PASS / FAIL / N/E` |

> **13.3 e 13.4 não são bugs — são propositais.**
> **13.3:** não há `[UninstallDelete]` para `%APPDATA%\InstitutoIMAN` (BL-3).
> **13.4:** desinstalar o IMAN Terra **não remove o QGIS**. Remover quebraria o trabalho GIS de quem
> passou a usá-lo para outra coisa. `D-IMAN-028`/**DB-11 está ABERTA** — até o sponsor arbitrar, a
> opção não-destrutiva é a única aceitável. **Se o QGIS sumir, é FAIL.**

```powershell
.\assert-bl3.ps1 -Baseline "$env:USERPROFILE\Desktop\bl7-evidence\perfil-usuario-antes.json"
```

- `[BL-3a]` depois do uninstall: `PASS / FAIL / N/E` · Screenshot: `13-pos-uninstall.png`

---

## 14. Reinstalar por cima do perfil sobrevivente

| # | Asserção | Resultado |
|---|---|---|
| 14.1 | Instala normalmente | `PASS / FAIL / N/E` |
| 14.2 | **Pula o QGIS** (ele já está lá) — a instalação é bem mais rápida | `PASS / FAIL / N/E` |
| 14.3 | Abre normalmente, com splash + HOME | `PASS / FAIL / N/E` |
| 14.4 | **Não** aparece um segundo perfil `iman-distro` duplicado | `PASS / FAIL / N/E` |

- Screenshot: `14-reinstalacao.png` · Critério: **upgrade**

---

## 15. Atualizar de uma versão anterior — **espera-se FAIL**

> **Leia antes de executar.** Este passo existe para **medir e documentar um defeito conhecido**,
> não para passar. Se der FAIL, o checklist está funcionando.

**O defeito:** o launcher só copia o `profile-template` no **primeiro** run — perfil que já existe
nunca recebe template novo (nem CRS, nem QSS, nem splash).

**Faça:** crie um perfil "de versão anterior" (instale a 0.2.0 e abra uma vez; ou edite à mão
`...\profiles\iman-distro\QGIS\QGIS3.ini` pondo `EPSG:4674`), instale a versão nova por cima e abra.

| Sinal | Esperado se o update-path funcionasse | Observado |
|---|---|---|
| CRS na barra de status | `EPSG:31984` | `__________` |
| QSS novo aplicado | sim | `SIM / NÃO` |
| Splash novo | sim | `SIM / NÃO` |

- Resultado: `PASS / FAIL / N/E` — **hoje o esperado é FAIL** · Screenshot: `15-update-path.png`

> **O conserto NÃO é desta fatia.** Versionar o template e re-sincronizar preservando o que é do
> usuário (BL-3) é fatia própria. Aqui só se **mede e declara**.

---

# RODADA M2a — QGIS 3.44.13 já instalado

**Prepare:** snapshot limpa + instale **à mão** o **QGIS oficial 3.44.13**. Não instale o IMAN Terra
ainda.

> ### ⚠ Só nesta rodada o instalador é lançado pela linha de comando
>
> O passo **16.4** precisa do **log do Inno Setup**, e esse log só existe se o instalador for
> lançado com a flag `/LOG`. Crie a pasta e lance assim:
>
> ```powershell
> New-Item -ItemType Directory -Force C:\bl7 | Out-Null
> Start-Process .\Instituto-IMAN-IMAN-Terra-Setup-<versao>.exe -ArgumentList '/LOG=C:\bl7\m2a-setup.log' -Verb RunAs
> ```
>
> O UAC aparece normalmente — clique **Sim** — e daí em diante o wizard é o mesmo, com os mesmos
> cliques.
>
> **O caminho `C:\bl7\` é curto de propósito.** O Inno 7 passou a gravar os caminhos **dentro do
> log** em forma *extended-length* (`\\?\C:\...`); um caminho curto e sem espaços elimina a dúvida
> de "é esse arquivo mesmo?" na hora de abrir. **Não presuma a forma: anote o caminho literal.**
>
> - Caminho do log **literalmente como apareceu**: `________________________________`
>
> ⚠ **Isto NÃO vale para as outras rodadas.** O **§2** depende do **duplo clique** (o SmartScreen
> real só aparece com o *Mark-of-the-Web*, e lançar por linha de comando pode não disparar) e o
> **§3 conta prompts de UAC**. A M2a não afere nenhum dos dois — por isso a mudança de lançamento
> fica presa aqui. **Se ao executar você perceber que ela vazou para outra rodada, PARE e relate.**

## 16. O instalador **pula** o QGIS — e prova que pulou

> **Por que "funcionou no fim" não basta.** O MSI oficial **não pula sozinho**: ele não tem `Upgrade`
> table nem `FindRelatedProducts` (medido na fatia #010). Chamado com o mesmo `ProductCode` já
> instalado, ele entra em **reconfiguração** do produto existente. O "pulo" é **código nosso**
> (`PrepareToInstall` testando o `ProductCode` em `HKLM64`). Se esse código falhar, a instalação
> **ainda termina bem** — só que tendo reconfigurado o QGIS do usuário. **Por isso o teste é de
> tempo e de log, não de resultado final.**

**Faça:** anote a hora, instale o IMAN Terra (com `/LOG`, como acima), anote a hora do fim.

| # | Asserção | Resultado |
|---|---|---|
| 16.1 | **Tempo total**: `______` — deve ser **muito menor** que o da rodada M1 (passo 5.1) | `PASS / FAIL / N/E` |
| 16.2 | **Não** apareceu a etapa demorada de instalação do QGIS | `PASS / FAIL / N/E` |
| 16.3 | O QGIS **continua na mesma versão** (3.44.13) e a **data de modificação** de `C:\Program Files\QGIS 3.44.13` **não mudou** | `PASS / FAIL / N/E` |
| 16.4 | **Qual das duas linhas** do instalador apareceu no log — ver o quadro logo abaixo | `PASS / FAIL / N/E` |
| 16.5 | O IMAN Terra abre normalmente | `PASS / FAIL / N/E` |

```powershell
(Get-Item 'C:\Program Files\QGIS 3.44.13').LastWriteTime
```

### 16.4 — asserção **enumerada**: qual das duas linhas o log trouxe

> #### ⚠ Por que este passo deixou de procurar arquivo em `%TEMP%`
>
> A versão anterior mandava conferir que **não existe** `%TEMP%\qgis-install.log`. Isso **nunca
> provou nada**. O log do MSI é escrito em `{tmp}` do Inno (`installer\iman-terra.iss`, linha 295:
> `CaminhoLog := ExpandConstant('{tmp}\qgis-install.log')`), e `{tmp}` é um subdiretório **por
> execução** debaixo de `%TEMP%` (`...\is-XXXXXXX.tmp\`) que o **Inno apaga ao sair**.
>
> Resultado: a busca volta **vazia nos dois mundos** — com o pulo funcionando **e** com ele
> quebrado. E **`-Recurse` não conserta**: o diretório já não existe quando o comando roda.
> Medido nesta bancada em 2026-09-02, na rodada com o pulo **funcionando**: `{tmp}` era
> `...\Temp\is-4RYMAKQ43I.tmp`, sumiu ao fim, a busca original devolveu `0` e a busca com
> `-Recurse` devolveu `0` também. Um `PASS` ali seria **falso**, e falso **exatamente** no
> caminho de falha silenciosa que o §16 existe para pegar.
>
> O conserto não é buscar melhor: é trocar **ausência de arquivo** (que os dois mundos produzem)
> por **presença de um valor que discrimina**.

As duas linhas abaixo são ramos **mutuamente exclusivos** do mesmo trecho do instalador
(`installer\iman-terra.iss`, linhas **220** e **231**): **uma delas sai sempre**.

```powershell
Select-String -Path C:\bl7\m2a-setup.log -Pattern 'PULANDO|Encadeando'
```

- **Trecho LITERAL da linha encontrada** — copie do log, com o carimbo de hora:

  `______________________________________________________________________________`

| Se a linha encontrada for… | O que significa | Veredito de 16.4 |
|---|---|---|
| `QGIS 3.44.13 ({740D7A65-CBA3-1014-A0B5-B03A9B7608F5}) ja instalado: PULANDO o encadeamento.` | o instalador **pulou** o encadeamento — é o comportamento que esta rodada existe para provar | `PASS` |
| `Encadeando o instalador oficial do QGIS 3.44.13...` | o instalador **encadeou** o MSI mesmo com o QGIS já instalado: o `DB-16` **falhou** e o QGIS do usuário foi **reconfigurado** | `FAIL` — achado grave, transcreva tudo |
| **nenhuma das duas** | o log não foi gerado, ou o instalador não chegou ao `PrepareToInstall` | `N/E` — conserte o lançamento e refaça. **Não** marque `PASS` |

> **Um `SIM` não serve aqui.** É o trecho literal que distingue os dois mundos; um veredito sem
> ele volta a ser a asserção cega que este passo acabou de substituir.

> #### Estado da validação deste passo (bancada do dev, 2026-09-02)
>
> A asserção nova foi **exercitada**, não só escrita:
>
> - **Flag de log confirmada:** `/LOG=<caminho>` no **Inno Setup 7.1.0** cria o arquivo. O próprio
>   log se identifica na 2ª linha: `Setup version: Inno Setup version 7.1.0 (32-bit)`.
> - **As chamadas `Log()` do bloco `[Code]` chegam nesse arquivo**, com carimbo de hora na frente.
> - **Texto já expandido** (o `.iss` usa `{#QgisBaselineVersion}`; no arquivo sai `3.44.13`), como
>   saiu de verdade:
>   `2026-09-02 10:16:50.490   QGIS 3.44.13 ({740D7A65-CBA3-1014-A0B5-B03A9B7608F5}) ja instalado: PULANDO o encadeamento.`
> - **O ramo `PULANDO` foi observado de verdade**, rodando o instalador canônico `0.3.0` nesta
>   bancada — que já tem o QGIS 3.44.13 e o `ProductCode` na ARP (`HKLM64`). Saída `exit 0`, e
>   **só** a linha do pulo apareceu: a linha `Encadeando` **não** está no mesmo log.
> - **Limite honesto 1:** a bancada rodou com `/VERYSILENT`; este passo roda o **wizard
>   interativo**. `/LOG` e `Log()` não dependem do nível de UI, mas essa **equivalência não foi
>   medida** aqui.
> - **Limite honesto 2 — o ramo `Encadeando` NÃO é testável nesta bancada:** o `ProductCode` do
>   QGIS 3.44.13 está presente e o instalador sempre pula. Esse ramo só se observa na **rodada
>   M1** (máquina sem QGIS nenhum) — **é lá que ele tem de ser conferido**, e é lá que a segunda
>   linha da tabela acima deixa de ser hipótese.

- Screenshot: `16-m2a-pulou.png` · Caso: **M2a** · Asserção: **DB-16**

---

# RODADA M2b — QGIS 3.44.12 já instalado

**Prepare:** snapshot limpa + instale **à mão** o **QGIS oficial 3.44.12**
(`QGIS-OSGeo4W-3.44.12-1.msi`). Não instale o IMAN Terra ainda.

## 17. Coexistência — e o launcher abre o **nosso** QGIS

> **É aqui que o fix do `DB-14` se prova no produto.** `3.44.13` e `3.44.12` têm `ProductCode` **e**
> `UpgradeCode` diferentes: o MSI oficial os trata como produtos sem relação e instala **lado a
> lado** (`D-IMAN-028`/**DB-13**). Isso é **não destrutivo** — mas cria a ambiguidade "qual QGIS
> abrir?", e a rotina antiga do launcher escolhia **`3.44.12`**: ela pegava o **primeiro**
> diretório `QGIS *` na ordem em que o `for /d` do `cmd` enumera, que é **ordem de texto**, e
> `"QGIS 3.44.12"` vem **antes** de `"QGIS 3.44.13"` porque `'2' < '3'`.

> ### A rival `3.44.12` não é resíduo — ela é a rival **por desenho**
>
> Repare que a **razão** mudou junto com a baseline: com o payload anterior, o que
> ordenava a rival antes dele era `'1' < '9'`; com o payload `3.44.13`, é `'2' < '3'`. A conclusão
> sobreviveu, a explicação não — e é a explicação que faz alguém saber o que conferir da próxima
> vez. O que o §17 depende não é de nenhum desses dois pares, e sim da **propriedade**:
>
> > **A rival de mesma minor só serve enquanto ordenar ANTES do payload por texto.** Se ordenar
> > **depois**, a rotina **antiga** também acertaria: o §17 passaria **por acaso**, deixaria de
> > testar o `DB-14` e viraria ruído — um `PASS` que não prova nada.
>
> **Se uma baseline futura inverter isso, TROQUE A RIVAL — não silencie o passo.** Escolha um
> `3.44.x` que ordene antes do payload por texto e atualize os passos 17.1–17.4 junto.
>
> Essa mesma propriedade **já é guardada em código**: `tools/test-launcher-detection.ps1` (bloco
> logo acima de `$casos`) deriva a rival do payload, compara com `CompareOrdinal` e **aborta com
> `exit 1`** — `TESTE INVALIDO para o payload <versao>` — se a premissa cair. Roteiro manual e
> guarda automatizada protegem a mesma coisa **de propósito**: quem mexer numa encontra a outra.

| # | Asserção | Resultado |
|---|---|---|
| 17.1 | A instalação **prossegue** e instala o `3.44.13` | `PASS / FAIL / N/E` |
| 17.2 | **As DUAS pastas existem**: `C:\Program Files\QGIS 3.44.13` **e** `QGIS 3.44.12` | `PASS / FAIL / N/E` |
| 17.3 | O `3.44.12` do usuário **continua funcionando** (abra-o pelo atalho dele) | `PASS / FAIL / N/E` |
| 17.4 | **O IMAN Terra abre o `3.44.13`** — não o `3.44.12` | `PASS / FAIL / N/E` |

**Como provar o 17.4 sem depender de olho:** com o IMAN Terra aberto, rode

```powershell
Get-Process qgis-ltr-bin, qgis-bin -ErrorAction SilentlyContinue | Select-Object Id, Path
```

- Caminho observado: `________________________________` → **PASS só se contiver `QGIS 3.44.13`**
- Screenshot: `17-m2b-coexistencia.png` · Caso: **M2b**

> **`D-IMAN-028`/DB-13 e DB-11 permanecem decisões do sponsor.** Este passo **mede** a coexistência;
> não a endossa como resposta final.

---

# RODADA M4 — a instalação do QGIS falha no meio

**Prepare:** snapshot limpa, **sem QGIS**.

## 18. Falhar é permitido; mentir não

**Faça — force a falha por um destes caminhos** (anote qual usou):

- **(a)** encha o disco antes de instalar, deixando menos de ~3 GB livres; ou
- **(b)** com o instalador rodando na etapa do QGIS, mate o processo `msiexec.exe` pelo
  Gerenciador de Tarefas; ou
- **(c)** inicie outra instalação MSI qualquer em paralelo (provoca o `1618`).

| # | Asserção | Resultado |
|---|---|---|
| 18.1 | Apareceu uma **mensagem em português** dizendo que a instalação do QGIS falhou | `PASS / FAIL / N/E` |
| 18.2 | A mensagem traz o **código** do Windows Installer | `PASS / FAIL / N/E` — código: `______` |
| 18.3 | A mensagem diz que **nada foi alterado** na máquina | `PASS / FAIL / N/E` |
| 18.4 | **O IMAN Terra NÃO ficou instalado** — sem pasta em `C:\Program Files\IMAN Terra`, sem atalhos, sem entrada em Aplicativos | `PASS / FAIL / N/E` |
| 18.5 | `%APPDATA%\InstitutoIMAN` **não** foi criado | `PASS / FAIL / N/E` |
| 18.6 | O **próprio msiexec** exibiu um diálogo de erro (além da nossa mensagem)? `SIM / NÃO` | `RELATADO` |
| 18.7 | Se exibiu: o instalador ficou **parado esperando clique**? `SIM / NÃO` | `RELATADO` — se `SIM`, é achado |

> ### ⚠ Este caso também NÃO pode ser herdado da fatia #010
> A troca de `/qn` para **`/qb!-`** (`DB-19`) muda o que o usuário vê quando falha: sob UI básica o
> msiexec **pode exibir diálogo de erro próprio** onde antes não exibia — e, se exibir, pode
> **bloquear esperando clique**. É o que 18.6 e 18.7 medem. **Nada aqui é `PASS` por herança.**

- Método de falha usado: `______` · Texto literal da mensagem: `________________________________`
- Screenshot: `18-m4-falha.png` · Caso: **M4**

> **O que se está provando (`D-IMAN-028`/DB-15):** que a falha do QGIS **aborta antes de tocar em
> qualquer coisa**, em vez de deixar o IMAN Terra instalado e inutilizável. O encadeamento roda em
> `PrepareToInstall`, que é **anterior** à cópia de qualquer arquivo.
> **18.4 é a asserção central deste caso.**

---

## 19. Fechamento — coletar o ambiente e fechar o placar

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\collect-evidence.ps1
```

Gera `Desktop\bl7-evidence\RESULT-esqueleto.md` com Windows, versão do QGIS, resolução, escala,
diretório de instalação e presença do perfil isolado.

**Depois:** preencha o `RESULT.md` colando esses dados, os resultados deste checklist e os
screenshots.

### Placar obrigatório

| | |
|---|---|
| Passos **com evidência** (`PASS` + `FAIL`) | `______ de ______` |
| Passos `N/E` | `______` — **liste quais e por quê** |
| Rodadas concluídas | `M1 ☐ · M2a ☐ · M2b ☐ · M4 ☐` |

> **Um checklist com muitos `N/E` não é um checklist reprovado — é um checklist incompleto**, e
> precisa dizer isso em voz alta. O que **não** pode acontecer é `N/E` virar silêncio, e silêncio
> virar "deve estar bom".

- Screenshot: `19-collect-evidence.png`
