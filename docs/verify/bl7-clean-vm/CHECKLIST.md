# BL-7 — Checklist de verificação em VM limpa

**Para quem executa:** este roteiro **não** exige conhecer o código. Cada passo tem o que fazer,
**o que você deve ver** (asserção), um campo `PASS/FAIL` e o nome do screenshot a salvar.
Se o que você viu não bate com a asserção, marque `FAIL` e **descreva literalmente o que apareceu** —
descrição fiel vale mais do que diagnóstico.

**O que está sendo verificado:** que a distro **IMAN Terra** instala, abre com a cara certa, credita
o QGIS e **não encosta nos dados do usuário** — numa máquina que nunca viu este projeto. Enquanto
este checklist não roda numa VM de verdade, tudo que a crew entregou é verdade só na máquina do dev.

> **Regra de ouro:** anote o que **aconteceu**, não o que deveria acontecer.

---

## 0. Preparação (antes de começar)

### 0.1 As duas VMs

| | **VM-A** | **VM-B** |
|---|---|---|
| Papel | máquina **sem QGIS nenhum** | máquina com **QGIS LTR** instalado |
| Testa | a mensagem de "QGIS não encontrado" | o produto de verdade |
| Passos | 1 | 2 a 12 |

**VM-B — o perfil do usuário precisa estar SUJO antes de instalar.** Abra o QGIS uma vez, mude
alguma configuração (ex.: um tema ou um painel), crie e **salve um projeto**, feche. Sem isso o
BL-3 não é testável: comparar uma pasta vazia com outra vazia não prova nada.

### 0.2 Configuração das duas VMs

- Windows 11 **pt-BR**
- usuário **NÃO administrador** (é assim que a TI de prefeitura entrega a máquina)
- **snapshot LIMPA** tirada antes de qualquer passo (para poder repetir o teste do zero)
- resolução **1366×768** com escala de exibição **125%**
  → é a realidade de prefeitura **e** o pior caso do dashboard da HOME. Testar em 1920×1080
  esconde exatamente os defeitos que interessam.

### 0.3 O instalador chega por DOWNLOAD HTTP

Publique o `.exe` num link (release privada, drive com link direto, servidor local) e **baixe pelo
navegador dentro da VM**.

> **Não copie por pasta compartilhada nem por área de transferência.** Só o download por HTTP marca
> o arquivo com o *Mark-of-the-Web*, que é o que faz o **SmartScreen real** aparecer. Copiando por
> pasta compartilhada você testaria um caminho que nenhum usuário vai percorrer.

Confira o arquivo baixado contra o `BUILD_INFO.txt` que veio com o build:

```powershell
Get-FileHash .\Instituto-IMAN-IMAN-Terra-Setup-<versao>.exe -Algorithm SHA256
```

- [ ] O SHA-256 bate com o do `BUILD_INFO.txt` → **se não bater, PARE**: o arquivo não é o que você
      acha que é, e todo o resto do teste seria sobre outro artefato.

### 0.4 Helpers

Copie a pasta `tools\bl7\` para a VM (ex.: `Desktop\bl7`). São três scripts de **PowerShell 5.1**:
não precisam de Python, git, internet, módulos nem administrador.

Se o PowerShell recusar rodar os scripts, use nesta sessão (não altera a máquina permanentemente):

```powershell
Set-ExecutionPolicy -Scope Process -Bypass
```

Todas as evidências caem em `Desktop\bl7-evidence\`.

---

## 1. VM-A — sem QGIS, a mensagem tem que ser humana

**Faça:** instale o IMAN Terra na **VM-A** e abra pelo atalho do Menu Iniciar.

**Deve acontecer:** uma janela de console com a mensagem `QGIS LTR nao foi encontrado`, explicando
que o IMAN Terra é uma camada sobre o QGIS LTR oficial, com o endereço para baixá-lo, e esperando
você apertar uma tecla.

**NÃO pode acontecer:** stacktrace de Python, mensagem em inglês, erro do Windows, nem janela que
**pisca e some** antes de dar para ler.

- Fica na tela até você fechar? `PASS / FAIL`
- Explica o que fazer? `PASS / FAIL`
- Screenshot: `01-vma-qgis-ausente.png`
- Invariante: **BL-5 / UX**

---

## 2. VM-B — fotografar o perfil do usuário ANTES de instalar

**Faça (antes de rodar o instalador, com o QGIS fechado):**

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\snapshot-user-profile.ps1 -Rotulo antes
```

**Deve acontecer:** o script lista a raiz `%APPDATA%\QGIS\QGIS3\profiles`, informa um número de
arquivos **maior que zero** e grava `Desktop\bl7-evidence\perfil-usuario-antes.json`.

> Se disser que a raiz não existe, o preparo do item 0.1 não foi feito: abra o QGIS uma vez, mexa
> na configuração, salve um projeto e repita este passo.

- Arquivos contados: `______` (> 0) `PASS / FAIL`
- Screenshot: `02-baseline-perfil-usuario.png`
- Invariante: **BL-3**

---

## 3. Rodar o instalador — SmartScreen, wizard e créditos

**Faça:** execute o `.exe` baixado.

**Deve acontecer:**

1. O **SmartScreen** provavelmente aparece (o instalador **não é assinado** — isto é esperado nesta
   fase). **Transcreva LITERALMENTE** o texto e o título da janela, e anote se há o link
   *"Mais informações"*.
2. O wizard abre em **português do Brasil**, com as artes de marca IMAN (imagem lateral e ícone).
3. Aparece a **tela de licença** antes de instalar.
4. **Nenhuma tela** sugere que isto é o QGIS oficial ou um produto endossado pela QGIS.ORG.

- Texto literal do SmartScreen: `________________________________`
- Wizard em pt-BR, com arte IMAN? `PASS / FAIL`
- Tela de licença apareceu? `PASS / FAIL`
- Nenhuma tela se passa por QGIS oficial? `PASS / FAIL`
- Screenshots: `03a-smartscreen.png`, `03b-wizard-boas-vindas.png`, `03c-licenca.png`
- Invariantes: **BL-1 / BL-2**

---

## 4. Instalar SEM elevar

**Faça:** conclua a instalação **sem** informar senha de administrador.

**Deve acontecer:** o Windows **não pede** credencial de administrador, e a instalação termina numa
pasta do próprio usuário (algo como `C:\Users\<você>\AppData\Local\Programs\IMAN Terra`).

> Por que importa: se exigir admin, a TI municipal precisa abrir chamado para cada máquina — na
> prática, a distro não é adotada.

- Pediu elevação? `SIM / NÃO` → **PASS = NÃO**
- Diretório final: `________________________________`
- Screenshot: `04-instalacao-concluida.png`
- Critério: adoção (TI municipal)

---

## 5. Primeiro run — cronometrado, na ordem

**Faça:** abra pelo atalho do Menu Iniciar. **Marque o tempo** até a janela ficar utilizável.

**Deve acontecer, nesta ordem:**

| # | O que deve aparecer | Viu? |
|---|---|---|
| 5.1 | **Splash com a arte IMAN** (não o splash padrão do QGIS) | `PASS / FAIL` |
| 5.2 | Título da janela contendo **IMAN Terra** | `PASS / FAIL` |
| 5.3 | Ícone **IMAN** na barra de tarefas (não o ícone do QGIS) | `PASS / FAIL` |
| 5.4 | A **HOME de boas-vindas NO MIOLO** da janela (área central, não um painel lateral) | `PASS / FAIL` |
| 5.5 | Chrome escura (tema aplicado, não o cinza padrão do QGIS) | `PASS / FAIL` |
| 5.6 | Toolbar de marca presente e enxuta | `PASS / FAIL` |

- Tempo até ficar utilizável: `______ s`
- Screenshots: `05a-splash.png`, `05b-primeira-tela.png`
- Fatias verificadas: **#005 + #006**

> Se o splash IMAN não aparecer mas o resto sim, marque só o 5.1 como FAIL — os itens são
> independentes.

---

## 6. O perfil carregou de verdade — os TRÊS sinais

**Por que os três:** na fatia 1 houve um bug em que o QGIS abria **bonito mas com perfil vazio**
(o caminho virava `profiles\profiles\`). Um sinal isolado pode enganar; os três juntos, não.

**Faça e confira:**

| # | Onde olhar | O que deve estar lá | Viu? |
|---|---|---|---|
| 6.1 | Complementos → Gerenciar e Instalar Complementos → Instalados | **`iman_brand` ativo** (marcado) | `PASS / FAIL` |
| 6.2 | Projeto → Propriedades → SRC (ou o SRC na barra de status) | o **CRS padrão do projeto novo** conforme a distro | `PASS / FAIL` |
| 6.3 | A janela | **QSS aplicado** (cores IMAN em menus/painéis, não o tema padrão) | `PASS / FAIL` |

- Screenshot: `06-plugin-crs-tema.png` (pode ser mais de um)
- **Os três precisam passar.** Dois em três = FAIL do passo.
- Regressão coberta: **fatia 1** (armadilha `profiles\profiles\`)

---

## 7. O perfil do usuário continua intacto — a asserção que bloqueia release

**Faça: FECHE o IMAN Terra e o QGIS** (arquivo aberto vira ruído), depois:

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\assert-bl3.ps1 -Baseline "$env:USERPROFILE\Desktop\bl7-evidence\perfil-usuario-antes.json"
```

**Deve acontecer:** `RESULTADO: PASS`, com as duas asserções verdes:

- `[BL-3a] PASS` — o perfil do usuário está **byte-idêntico** ao passo 2 (0 divergências)
- `[BL-3b] PASS` — o perfil **isolado** foi criado em
  `%APPDATA%\InstitutoIMAN\IMAN Terra\profiles\iman-distro`

- `[BL-3a]` `PASS / FAIL` — se FAIL, **copie a lista de DIVERGENTES inteira** para o RESULT
- `[BL-3b]` `PASS / FAIL`
- Screenshot: `07-assert-bl3.png`
- Evidência automática: `Desktop\bl7-evidence\assert-bl3.json`
- Invariante: **BL-3 — inegociável. FAIL aqui BLOQUEIA o release.**

---

## 8. Ciclo HOME ↔ canvas, 3 vezes

**Faça, três vezes seguidas:**

1. na HOME, abra o **projeto demo** → deve ir para o **canvas** do mapa
2. **Projeto → Novo** → deve voltar para a **HOME**

**Deve acontecer:** a troca é limpa nas três voltas. **Não pode** sobrar "tela-fantasma" (resto da
HOME por cima do mapa, ou do mapa por cima da HOME), nem área cinza vazia.

- Volta 1 `PASS / FAIL` · Volta 2 `PASS / FAIL` · Volta 3 `PASS / FAIL`
- Screenshots: `08a-demo-canvas.png`, `08b-novo-home.png`
- Guardrail: **#006**

---

## 9. Segundo run — idempotência

**Faça:** feche tudo e abra o IMAN Terra **de novo** pelo atalho.

**Deve acontecer:**

| # | Asserção | Viu? |
|---|---|---|
| 9.1 | Abre **mais rápido** que o primeiro run — não recopia o template do perfil | `PASS / FAIL` |
| 9.2 | O splash IMAN aparece de novo | `PASS / FAIL` |
| 9.3 | A HOME aparece de novo | `PASS / FAIL` |
| 9.4 | Suas alterações do run anterior continuam lá (o perfil não foi sobrescrito) | `PASS / FAIL` |

**Confira o arquivo de customização** — ele é reescrito a cada abertura e **não pode duplicar**:

```powershell
Get-Content "$env:APPDATA\InstitutoIMAN\IMAN Terra\profiles\iman-distro\QGIS\QGISCUSTOMIZATION3.ini"
```

Deve ter **exatamente um** `[Customization]` e **uma** linha `splashpath=`.

- Linhas duplicadas? `SIM / NÃO` → **PASS = NÃO**
- Screenshot: `09-segundo-run-customization.png`
- Critério: **idempotência**

---

## 10. Créditos do QGIS

**Faça:** abra a pasta de instalação (a do passo 4) e depois, no aplicativo, `Ajuda → Sobre`.

**Deve acontecer:**

| # | Onde | O que deve estar lá | Viu? |
|---|---|---|---|
| 10.1 | pasta instalada | arquivo **`LICENSE`** | `PASS / FAIL` |
| 10.2 | pasta instalada | arquivo **`THIRD_PARTY_NOTICES.md`** | `PASS / FAIL` |
| 10.3 | pasta instalada | arquivo **`README.md`** | `PASS / FAIL` |
| 10.4 | `Ajuda → Sobre` | credita o **QGIS** | `PASS / FAIL` |
| 10.5 | em algum lugar visível | a expressão **"powered by QGIS"** | `PASS / FAIL` |
| 10.6 | em algum lugar visível | o aviso de **independência** (não é produto oficial nem endossado pela QGIS.ORG) | `PASS / FAIL` |

- Screenshots: `10a-pasta-instalada.png`, `10b-sobre.png`
- Invariante: **BL-1**

---

## 11. Desinstalar — e o que tem que SOBRAR

**Faça:** Configurações → Aplicativos → IMAN Terra → Desinstalar.

**Deve acontecer:**

| # | Asserção | Viu? |
|---|---|---|
| 11.1 | A pasta de instalação (passo 4) foi **removida** | `PASS / FAIL` |
| 11.2 | Os atalhos (Menu Iniciar / Área de Trabalho) foram **removidos** | `PASS / FAIL` |
| 11.3 | `%APPDATA%\InstitutoIMAN` **CONTINUA LÁ** | `PASS / FAIL` |
| 11.4 | O QGIS do usuário continua instalado e funcionando (abra-o) | `PASS / FAIL` |

> **11.3 não é bug — é proposital.** O instalador **não** tem seção `[UninstallDelete]` para
> `%APPDATA%\InstitutoIMAN`. Desinstalar o programa **não pode** apagar os dados do usuário (BL-3).
> Se a pasta sumir, é **FAIL**.

Confirme que o perfil do usuário continua intacto **depois** de desinstalar:

```powershell
.\assert-bl3.ps1 -Baseline "$env:USERPROFILE\Desktop\bl7-evidence\perfil-usuario-antes.json"
```

- `[BL-3a]` depois do uninstall: `PASS / FAIL`
- Screenshot: `11-pos-uninstall.png`
- Invariante: **BL-3**

---

## 12. Reinstalar por cima do perfil sobrevivente

**Faça:** instale de novo o mesmo `.exe`, sem apagar nada, e abra.

**Deve acontecer:**

| # | Asserção | Viu? |
|---|---|---|
| 12.1 | Instala normalmente | `PASS / FAIL` |
| 12.2 | Abre normalmente, com splash + HOME | `PASS / FAIL` |
| 12.3 | **Não** aparece um segundo perfil `iman-distro` duplicado | `PASS / FAIL` |
| 12.4 | Nada quebra por causa do perfil que sobreviveu ao uninstall | `PASS / FAIL` |

- Screenshot: `12-reinstalacao.png`
- Critério: **upgrade**

---

## 13. Atualizar de uma versão anterior — **espera-se FAIL**

> **Leia antes de executar.** Este passo existe para **medir e documentar um defeito conhecido**,
> não para passar. Se ele der FAIL, o checklist está funcionando. Registre a evidência e siga.

**Por que os passos 1–12 não pegam isto:** numa VM limpa o perfil isolado **nasce novo**, então o
caminho de atualização **não existe por construção**. E o passo 12 reinstala a **mesma** versão
sobre um perfil criado pela **mesma** versão — passa trivialmente. Ou seja: um BL-7 todo verde
diria nada sobre atualizar, que é justamente o que acontece com quem já usa o produto.

**O defeito:** o launcher só copia o `profile-template` no **primeiro** run:

```bat
if not exist "%PROFILE_DIR%\QGIS\QGIS3.ini" ( xcopy /E /I /Y "%TEMPLATE%" "%PROFILE_DIR%" )
```

Perfil que **já existe nunca recebe template novo** — nem CRS, nem QSS, nem splash.

**Faça (na VM-B, depois do passo 12):**

1. Crie um perfil "de versão anterior". Dois caminhos, use o que der:
   - **preferido:** instale a **0.1.0** (o `.exe` de 05/jul, se disponível), abra uma vez, feche; ou
   - **simulação:** abra o app uma vez para o perfil nascer, feche, e **edite à mão**
     `%APPDATA%\InstitutoIMAN\IMAN Terra\profiles\iman-distro\QGIS\QGIS3.ini`, colocando um valor
     reconhecível — por exemplo trocando o CRS padrão para `EPSG:4674`.
2. Instale a **0.2.0** por cima, sem apagar nada.
3. Abra o app.

**Asserção:** o app reflete o **template NOVO**? — CRS `EPSG:31984` na barra de status, QSS novo,
splash novo.

| Sinal | Esperado se o update-path funcionasse | Observado |
|---|---|---|
| CRS na barra de status | `EPSG:31984` | `__________` |
| QSS novo aplicado | sim | `SIM / NÃO` |
| Splash novo | sim | `SIM / NÃO` |

- Resultado: `PASS / FAIL` — **hoje o esperado é FAIL**
- Screenshot: `13-update-path.png`
- Origem: achado (B) do gate do #006 — foi exatamente isto que fotografou `EPSG:4674` na evidência
  daquela fatia, com o template já em `EPSG:31984`. É o NIT-B da fatia 1 reincidindo, agora com prova.

> **O conserto NÃO é desta fatia.** Versionar o template e re-sincronizar no upgrade **preservando
> o que é do usuário** (BL-3) exige desenhar o que se sobrescreve e o que se preserva — é fatia
> própria. Aqui só se **mede e declara**.

---

## 14. Fechamento — coletar o ambiente

**Faça:**

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\collect-evidence.ps1
```

Gera `Desktop\bl7-evidence\RESULT-esqueleto.md` com Windows, **versão exata do QGIS**, resolução,
escala, diretório de instalação e presença do perfil isolado.

**Depois:** preencha o `RESULT.md` (modelo em `docs/verify/bl7-clean-vm/RESULT.md`) colando esses
dados, os `PASS/FAIL` deste checklist e os screenshots.

> **A versão do QGIS que você testou vira a versão suportada declarada do release.** Se você testou
> em 3.44.9, o release suporta 3.44.x — e mais nada, até alguém rodar este checklist noutra versão.

- Screenshot: `14-collect-evidence.png`
