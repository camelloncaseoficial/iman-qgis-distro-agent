# `#018` — BASELINE VERDE: o conserto dos doze, contra a régua do `#017`

**Executado em:** 2026-09-07 · branch `feat/018-conserto-dos-doze` (de `develop` = `a0d995c`)
**Bancada:** Windows 11 Pro 10.0.26200 · QGIS **3.44.13-Solothurn** · perfil `iman-distro`
reconstruído do zero a cada rodada.

> **Os números do "antes" não foram remedidos.** Todos vêm de
> `docs/verify/017-aceite-marca/evidencia/aceite.json`, o arquivo da baseline vermelha.

---

## VEREDITO

> ### `12 asserções PASS · 0 FAIL · 1 N/E` — e o verde é **auditado**
>
> **Onze dos doze defeitos consertados.** O `D11` continua `N/E`, **BLOQUEADO EM A1** — não existe
> conserto honesto enquanto o `.exe` não for nosso, e um `N/E` honesto vale mais que um verde
> comprado.
>
> **Nenhuma asserção foi enfraquecida para isso.** O gate de adulteração inversa
> (`tools/Assert-AdulteracaoInversa.ps1`) reverte cada conserto, um a um, e exige que a asserção
> correspondente **volte a vermelho** — e só ela. Resultado: **12 de 12 reversões acenderam a
> asserção certa.** Asserção que não acende quando o defeito volta é asserção morta, e reprovaria a
> fatia mesmo com tudo verde.
>
> **Achado do caminho:** o `D7`, que o `#017` não conseguiu reproduzir em 7 estados, **foi
> reproduzido** — e só apareceu depois que a política do miolo virou explícita. Ver §3.

---

## 0. Legenda (`E.6`)

| marca | significa |
|---|---|
| **`PASS`** / **`FAIL`** | **medido** nesta bancada, com número no relatório e evidência em `evidencia/` |
| **`N/E`** | **não medido** — nomeado, com o motivo e o passo manual proposto |

**Placar em `n de N com evidência`: 14 de 14 asserções executadas** (13 na 1ª execução + `A07b` na
2ª). Saída bruta em `evidencia/aceite.json`, `evidencia/aceite-segunda.json` e
`evidencia/adulteracao-inversa.json`.

---

## 1. Uma linha por defeito

| # | asserção | antes (`#017`) | depois (`#018`) | evidência |
|---|---|---|---|---|
| **D1** botão de fechar apagado | `A01` | tinta **0** de 80 px · botão **4 px** contra 15 do irmão · proporção **0,267** · 2 de 2 docks ruins · **FAIL** | tinta **117** de 304 px · botão **15 px** · proporção **1,000** · 0 de 2 docks ruins · **PASS** | `shots/A01-dock-titulo.png` |
| **D2** coordenadas espremidas | `A02` | largura útil **6 px** para 104 necessários · cabia **1** caractere de 19 · widget 24 px (`min == max`) · **FAIL** | largura útil **106 px** · cabem **19 de 19** · widget **122 px** · **PASS** | `shots/A02-zoom-coordenadas.png` |
| **D3** campo estoura, rodapé some | `A03` | campo **24 → 7 464 px** · janela **1 020 → 8 334 px** numa tela de 1 536 · **FAIL** | campo **122 → 236 px** · janela **1 164 → 1 164 px** (não muda) · **PASS** | `shots/A03-rodape-{antes,depois}.png` |
| **D4** título de painel cortado | `A04` | tinta **7 px** · piso da ascendente 9 px · 2 de 2 docks ruins · **FAIL** | tinta **11 e 12 px** · piso 9 px · 0 de 2 docks ruins · **PASS** | `shots/A04-zoom-titulo-integro.png` |
| **D5** título estático, duas fontes | `A05` | `IMAN Terra — powered by QGIS` em todo estado · contém o nome do projeto: **não** · muda ao criar novo: **não** · **FAIL** | `spike017-projeto-alfa — IMAN Terra` → `Projeto sem título — IMAN Terra` · contém: **sim** · muda: **sim** · **PASS** | `shots/A05-apos-abrir-projeto.png` |
| **D6** "Novo projeto" inerte | `A06` | página no miolo após criar projeto = **`ImanHome`** · **FAIL** | página = **canvas** · **PASS** | `shots/A06-apos-novo-projeto.png` |
| **D7** a home some após o 1º uso | `A07` · `A07b` | **PASS por ausência de defeito** — a asserção só perguntava se a welcome nativa não tinha aparecido | **6 de 6 estados dentro da política** · 2ª execução pousa em `ImanHome`, welcome nativa **não visível** · **PASS** | `shots/A07-{caminhada-final,segunda-execucao}.png` |
| **D8** home é maquete | `A08` | **20 de 20** strings inventadas na tela · **10** widgets com falso afordance · **FAIL** | **0** strings inventadas (as constantes deixaram de existir) · **0** falsos afordances · 4 clicáveis de verdade · **PASS** | `shots/A08-home.png` |
| **D9** a versão mente | `A09` | home `0.1.0` · `brand.py` `0.1.0` · `metadata.txt` `0.1.0` · `.iss` **`0.3.0`** → **2** valores · **FAIL** | as quatro em **`0.3.0`** → **1** valor · **PASS** | `shots/A08-home.png` (banner "versão 0.3.0") |
| **D10** Sobre escondido | `A10` | **nenhuma** ocorrência no menu `Ajuda`; a ação vivia em `Complementos > IMAN Terra >` · **FAIL** | `Ajuda` contém **`Sobre o IMAN Terra`**, e o `Sobre` **nativo do QGIS continua lá** · **PASS** | `shots/A10-menubar.png` |
| **D11** ícone do QGIS na taskbar | `A11` · `M-D11` | `A11` **PASS (parcial)** · `M-D11` **N/E** | **inalterado — BLOQUEADO EM A1.** Ver §4 | — |
| **D12** ícones do QGIS na UI | `A12` | tema em uso **`default`** · **nenhum** tema no perfil · **FAIL** | tema em uso **`IMAN Terra`** · instalado em `<perfil>/themes` · **PASS** | `evidencia/aceite.json` |

---

## 2. O gate que separa "consertei" de "afrouxei"

Uma baseline verde, sozinha, não distingue *os defeitos saíram* de *as asserções morreram*.
`tools/Assert-AdulteracaoInversa.ps1` faz a distinção: para cada defeito, reverte o conserto **no
código de produto** (nunca no teste), roda o aceite, e exige que a asserção daquele defeito volte a
`FAIL` — e que nenhuma outra mude de status.

```
  referencia: 14 assercoes, 0 FAIL

  D1  -> A01 voltou a FAIL, e so ela
  D2  -> A02 voltou a FAIL; junto veio A03, acoplamento DECLARADO
  D3  -> A03 voltou a FAIL, e so ela
  D4  -> A04 voltou a FAIL, e so ela
  D5  -> A05 voltou a FAIL, e so ela
  D6  -> A06 voltou a FAIL; junto veio A07, acoplamento DECLARADO
  D7  -> A07b voltou a FAIL, e so ela
  D7-vivacidade -> A07b voltou a FAIL, e so ela
  D8  -> A08 voltou a FAIL, e so ela
  D9  -> A09 voltou a FAIL, e so ela
  D10 -> A10 voltou a FAIL, e so ela
  D12 -> A12 voltou a FAIL, e so ela

  12 de 12 reversoes acenderam a assercao certa, e so ela.
  GATE OK - nenhuma assercao morta, nenhum acoplamento.
```

### 2.1 Os dois acoplamentos, declarados e não escondidos

| reversão | arrasta | por quê é desenho, não acidente |
|---|---|---|
| `D2` | `A03` | o critério do `A03` é **relativo** — "o campo não passa de 3× a largura de antes" — e quem define essa largura de partida é justamente o **piso** que o `D2` instala. Tirar o piso muda o denominador |
| `D6` | `A07` | o `A07` assere a **política inteira**, e o estado `E4` ("criou um projeto → canvas") é exatamente o que o `D6` conserta. Os dois cobrirem o mesmo estado é cobertura, não redundância cega |

Acoplamento **inesperado** continua reprovando o gate.

### 2.2 O gate também reprovou a si mesmo — duas vezes

A primeira execução acusou quatro problemas. **Dois eram defeito do gate**, e valem registro porque
são a mesma classe de erro que a fatia inteira existe para combater:

1. **O revert do `D8` não revertia nada de visível.** Ele reintroduzia a constante `TEMPLATES` mas
   não a renderizava — e o `A08` mede **o que chega à tela**, não o que existe no código. O gate
   dizia "asserção morta" quando a asserção estava certa e o *estímulo* é que era falso.
2. **A 2ª execução media a versão anterior do código.** A fase `segunda` roda com `-ReusarPerfil`,
   que por desenho **não reconstrói o perfil** — e o gate adultera o repositório. Sem uma 1ª
   execução antes, o código adulterado nunca chegava ao perfil. O gate acusou o `A07b` de morto
   **três vezes seguidas** sem que ele jamais tivesse visto a adulteração.

Os dois estão consertados e commitados em separado. A lição é a mesma do `#017`: um instrumento que
não é ele próprio verificado produz laudo com a mesma confiança de um que é.

---

## 3. `D7` — reproduzido, e o que isso ensinou

O `#017` fechou com o `D7` **`RELATADO`, não reproduzido** em 7 estados observados. Ele apareceu
aqui, e não por caçada: **apareceu porque a política ficou explícita.**

Sequência do que aconteceu:

1. O contrato passou a exigir `E4` — *criar um projeto leva ao canvas* (o conserto do `D6`).
2. Com isso, a **2ª execução** com o perfil já usado passou a mostrar:
   ```
   pagina no miolo ao abrir : centralwidget (indice 0)
   home visivel             : nao
   welcome NATIVA do QGIS   : VISIVEL
   ```
   Que é literalmente *"a home some depois do 1º uso, caindo na welcome nativa do QGIS"*.
3. **Causa:** no arranque o QGIS emite `newProjectCreated` para o projeto vazio inicial **depois**
   que a home já foi instalada. Tratado como ação do usuário, ele tirava a home do miolo e deixava
   a página 0 — que, sem projeto, mostra a welcome nativa.
4. **Conserto:** o pouso deixou de ser reação a **evento** e passou a ser decisão por **estado**.
   Assentado o arranque, olha-se se há projeto carregado: se há, canvas (`E7`); se não há, home
   (`E1`). Só depois disso os eventos passam a valer, porque só aí eles são mesmo do usuário.

> **A lição, e ela vale além do `D7`:** reagir a evento é frágil por construção — o resultado
> depende de quem chega primeiro. "Depende" é como o `D7` nasceu, e é por isso que ele era
> intermitente o bastante para o `#017` não o alcançar em 7 tentativas.

O gate confirma nos dois sentidos: reverter o pouso-por-estado acende o `A07b`, e forçar um pouso
errado também.

---

## 4. `D11` — BLOQUEADO EM A1

**Não foi consertado, e não deveria ter sido.** O shell do Windows lê o `AppUserModelID` no instante
em que a janela nasce; o `iman_startup.py` roda via `--code`, depois. Medir a variável mais tarde
diz que a chamada aconteceu (`InstitutoIMAN.IMANTerra.Distro.1`, medido) — não diz o que o shell
usou.

Não existe conserto honesto no modelo atual. Ele vem junto com a via **A1**, quando o `.exe` for
nosso e a identidade puder ser declarada antes da primeira janela.

`A11` continua medindo só o **ícone da janela** (9 % de semelhança com o do QGIS — é o emblema IMAN)
e continua **rotulado como não cobrindo o `D11`**. `M-D11` continua **`N/E`**, com o passo manual e
o critério inalterados:

> abrir pelo atalho do Menu Iniciar, esperar a janela, olhar o ícone **na barra de tarefas**.
> **PASSA** se for o emblema IMAN, **FALHA** se for o logo do QGIS. Foto da barra de tarefas, não da
> janela.

---

## 5. O que mudou no instrumento, e por quê

`tools/branding-acceptance/` é congelado por default. Duas asserções mudaram, **cada uma em commit
separado do conserto**, com o número de antes e de depois:

### 5.1 `A04` — o oráculo estava errado, e reprovava produto são

| | tinta na tela | referência | razão |
|---|---|---|---|
| título **cortado** (`0.3.0`) | 7 px | 8 px | 0,875 |
| título **íntegro** (após `D4`) | 11 px | 8 px | 1,375 |

A referência dava **8 px nos dois casos** — ela era menor que o texto íntegro. Quem reprovava era
uma heurística secundária ("a última linha com tinta ainda está densa = corte reto"), e essa
heurística tem **falso positivo**: num texto de 11 px sem descendentes, como *"Camadas"*, a linha de
base é legitimamente a mais densa. Ela reprovava o título consertado.

Duas tentativas de consertar o oráculo falharam e ficam registradas no código para não serem
refeitas: redesenhar com `d.font()` calibrando o peso pela largura deu **42 px contra 60 px na
tela** (era outro texto, mais magro); pedir ao próprio `QStyle` um `CE_DockWidgetTitle` num `QRect`
alto deu **37 px**, também sem reproduzir a fonte do tema.

**Critério novo, sem oráculo:** a tinta do título tem de ser pelo menos tão alta quanto a
**ascendente da fonte do widget**. Como a fonte real do tema é maior, a ascendente é um **piso
conservador** — produto são a supera com folga, e não há falso positivo. Verificado por adulteração
inversa: **com o `D4` aplicado, 11 e 12 px contra piso 9 → PASS; com o `D4` revertido, 7 e 7 px →
FAIL**, e nenhuma outra asserção mudou.

### 5.2 `A07` — passava por ausência de defeito

Perguntava se a welcome nativa **não** tinha aparecido e se "Início" ainda funcionava. Qualquer
estado em que nada de ruim fosse observado contava como correto — foi por isso que ela deu `PASS` no
`#017` **com o `D7` presente no produto**.

Agora cada estado carrega a página **esperada** pela política do contrato, e a asserção compara a
observada com ela. Passa por **presença de comportamento**, e reprova nomeando o estado:

```
E2 abriu um projeto          esperado=canvas observado=canvas ok=True
E4 criou um projeto          esperado=canvas observado=canvas ok=True
E6 acionou "Inicio"          esperado=home   observado=home   ok=True
E5 abriu o projeto demo      esperado=canvas observado=canvas ok=True
E6 acionou "Inicio" de novo  esperado=home   observado=home   ok=True
E4 criou outro projeto       esperado=canvas observado=canvas ok=True
```

### 5.3 O que **não** mudou

`A01`, `A02`, `A03`, `A05`, `A06`, `A08`, `A09`, `A10`, `A11`, `A12`, `M-D11` e a validação de
baseline (`E.1`) estão **byte a byte como saíram do `#017`**. Nenhum limiar foi afrouxado.

---

## 6. Nota honesta sobre o `A08`

Com as constantes `RECENTS`/`TEMPLATES`/`CHIPS` removidas do módulo, o conjunto que a primeira
metade do `A08` procura fica **vazio** — e essa metade passa a ser trivialmente satisfeita. Ela
continua valendo como **guarda de regressão**: se alguém reintroduzir as listas *e as renderizar*, a
asserção volta a achar — foi exatamente assim que o gate a acendeu (§2.2).

Quem carrega o peso hoje é a **segunda metade**, que mede widgets com regra `:hover` própria sem
clique real: **10 antes, 0 depois**, e ela acende no gate.

---

## 7. `C.3` — a guarda de versão grita

O `D9` não se resolve alinhando três arquivos: se divergirem de novo, ninguém percebe até o sponsor
instalar. `installer/build.ps1` ganhou uma guarda que **recusa compilar**. Provada com divergência
deliberada e commitada:

```
==> conferindo a versao do produto nas tres fontes (D9)

  BUILD RECUSADO: versao do produto divergente entre as tres fontes

    installer\iman-terra.iss   #define ProductVersion : 0.3.0   (FONTE UNICA)
    ...\iman_brand\brand.py      VERSION                : 0.1.0
    ...\iman_brand\metadata.txt  version                : 0.3.0
    ...
    A fonte unica e o .iss. Corrija brand.py e metadata.txt para 0.3.0.

EXIT=3
```

---

## 8. `V.5` — zero hex órfão, reconferido

O QSS de marca mudou de lugar (`QGIS/iman-theme.qss` → `themes/IMAN Terra/style.qss`). Reconferido
no novo caminho: **12 cores no corpo, todas as 12 em `brand.py` e em `docs/design-system.md`. Zero
órfãos.** São **49 regras** agora — era 50; saiu a do `titlebar-close-icon`.

---

## 9. O que esta fatia NÃO fez

1. **Não consertou o `D11`** — bloqueado em A1, por decisão do briefing e por falta de conserto
   honesto. `N/E` mantido.
2. **Não populou o `icons/` do tema.** O tema próprio existe e está ativo, mas o diretório que
   sobrescreveria a iconografia de chrome (setas, fechar, olho, alças) está **vazio**. Um
   `close.svg` malfeito reabriria o `D1`.
3. **Não tocou** o `.iss` além da guarda de versão do `D9`, nem a via A1, nem o manifesto de
   integridade da árvore.
4. **Não ampliou** o aceite com asserções novas — ele é a régua, não o objeto.
5. **Não abriu diálogos** (Opções, Gerenciador de Complementos, Propriedades de Camada). O QSS os
   estiliza via `QPushButton` e `QLineEdit`, marcados como risco **médio** no inventário do
   contrato, e nenhum foi exercitado aqui — mesma lacuna do `#017`.
6. **Não cobriu** modo escuro, DPI diferente de 100 %, nem outra versão de Windows. Uma bancada, um
   QGIS, uma resolução.
7. **Não rodou a VM limpa** (`BL-7`). O produto foi exercitado com o QGIS instalado nesta máquina.

---

## 10. Como reproduzir

```powershell
# a baseline verde
cd tools\branding-acceptance
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1 -ReusarPerfil -Fase segunda

# o gate que a audita (arvore precisa estar limpa; ele reverte e restaura)
cd ..\..
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Assert-AdulteracaoInversa.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Assert-AdulteracaoInversa.ps1 -Somente D1,D4

# a guarda de versao (C.3)
powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\build.ps1 -ExpectedBranch <branch>
```

**Limpeza:** `Remove-Item -Recurse -Force "$env:LOCALAPPDATA\InstitutoIMAN\_aceite017"`.

---

**Nada foi instalado, alterado ou removido nesta máquina.** `C:\Program Files\QGIS 3.44.13` e
`%APPDATA%\QGIS` intocados — o orquestrador recusa destino nessas áreas por construção. Nenhum
processo `qgis-ltr-bin` órfão ao final.
