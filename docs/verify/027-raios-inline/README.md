# `#027` — O tema volta a ser um lugar só: os seis raios inline saem do Python

**Executado em:** 2026-09-09 · branch `feat/027-raios-inline-para-o-qss` (de `develop` = `508290c`)
**Bancada:** Windows 11 Pro 10.0.26200 · PowerShell 5.1 · **sem QGIS de sistema**
**Artefato usado na prova:** `Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe`, commit `33ac0ff` — ver §6.

---

## 0. Legenda (`E.6`)

| marca | significa |
|---|---|
| **medido** | número obtido nesta bancada, nesta sessão, com evidência em `evidencia/` |
| **relatado** | veio de outra sessão ou de outro observador, identificado como tal |
| **`N/E`** | não medido — nomeado, com o motivo |

---

## VEREDITO

> ### O tema é um lugar só, e agora a guarda defende essa propriedade
>
> Os **seis** raios inline saíram do Python e viraram regra do `style.qss`, a **2px**. A guarda
> estática deixou de ser guarda de um **arquivo** e passou a ser guarda do **tema**: ela agora exige
> **zero `border-radius` inline** em `app/profile-template/**/*.py` e `app/startup`.
>
> **Só o raio moveu.** Como consequência direta, **nenhum literal de cor entrou no `.qss`** — a
> ressalva do briefing sobre cor interpolada não chegou a se materializar, e está medida: **zero
> token órfão** (`V.5`).
>
> **Dois nomes de objeto nasceram**, e nome de objeto é contrato: `QLabel#ImanHomeVersao` e
> `QLabel#ImanSobreCreditos`.
>
> **`13 PASS · 0 FAIL · 1 N/E`** na condição do `#025` — instalação limpa de 257 s e o aceite
> **imediatamente** depois, com a rodada de **93,2 s**, a mais lenta já registrada nesta bancada.

---

## 1. Os seis, e o que aconteceu com cada um

| arquivo | antes | depois | seletor no `.qss` | tinha nome? |
|---|---|---|---|---|
| `dashboard.py` — cartão de ação rápida | **14px** | **2px** | `QFrame#qa` | ✅ já tinha |
| `dashboard.py` — tile dentro do cartão | **11px** | **2px** | `QLabel#qatile` | ✅ já tinha |
| `dashboard.py` — item de projeto recente | **10px** | **2px** | `QFrame#rec` | ✅ já tinha |
| `dashboard.py` — **badge de versão** | **9px** | **2px** | `QLabel#ImanHomeVersao` | ⚠ **nasceu aqui** |
| `sobre.py` — créditos do QGIS | **10px** | **2px** | `QLabel#ImanSobreCreditos` | ⚠ **nasceu aqui** |
| `iman_brand.py` — botão de marca | **8px** | **2px** | `QToolButton#ImanTerraMenuBtn` | ✅ já tinha |

Quatro dos seis já eram regra QSS com seletor de ID — por isso a fatia é **recolocação, não
reescrita**, como o briefing previu.

### 1.1 Os dois nomes que nasceram — e por que precisavam nascer

| widget | o que havia antes | por que o nome era obrigatório |
|---|---|---|
| badge de versão da home | uma **lista de propriedades solta**, sem seletor nenhum (`"font-size:12px;color:…;border-radius:9px;…"`) | sem nome, o `.qss` não tem como alcançar **só** este `QLabel` |
| bloco de créditos do *Sobre* | seletor **`QLabel` NU** | inline isso atinge só o widget; **no `.qss` pegaria TODO `QLabel` do produto** |

Ambos estão declarados no comentário do `style.qss` e no código, porque **nome de objeto é
contrato**: o `.qss` passou a depender deles.

---

## 2. O que moveu, o que **não** moveu, e por quê

**Moveu:** exclusivamente o `border-radius`.

**Não moveu** — e é deliberado:

| propriedade | onde ficou | por quê |
|---|---|---|
| cor do tile (`color`) e borda de `:hover` do cartão | Python | são interpoladas **por papel**: `accent_key` muda a cada cartão da home (`brand_2`, `accent`, `moss`). Trazê-las exigiria **uma regra por papel** — deixaria de ser recolocação |
| fundo, borda, `padding`, `font-size` dos seis | Python | mesma razão, ou porque o movimento não é trivial sem mexer em layout — e layout está fora de escopo |

### 2.1 ⚠ A ressalva de cor interpolada (`V.5`) — medida, e ela não se materializou

O briefing avisou: ao mover para o `.qss`, um `%s` de `brand.COLOR_*` vira **literal**, e o literal
pode divergir do token.

**Como só o raio veio, nenhum literal de cor entrou.** Medido:

```
hex nas 6 regras novas          : NENHUM
hex distintos no .qss inteiro   : 18
ORFAOS (nao sao token de brand.py): nenhum
```

A regra do cabeçalho do `style.qss` — *"todo hex daqui existe como token em `brand.py`"* — continua
valendo, e continua valendo **trivialmente** para o bloco novo.

---

## 3. A guarda cresce junto

| # | asserção | estado |
|---|---|---|
| 1 | `border-radius` no `.qss`: **12 → 18** declarações, todas `2px` | ampliada |
| 2 | `QMenuBar::item` com padding `3px 4px` | intacta |
| 3 | `QStatusBar` sem declaração de padding (`D2`) | intacta |
| 4 | `QDockWidget::title` sem padding vertical (`D4`) | intacta |
| 5 | os 2 cantos específicos da aba em `2px` | intacta |
| **6** | **ZERO `border-radius` inline** em `app/profile-template/**/*.py` e `app/startup` | **nova** |

```
  [1] border-radius : 18 declaracoes, 0 fora de 2px
  [2] QMenuBar::item : padding '3px 4px'
  [3] QStatusBar     : 0 declaracao(oes) de padding
  [4] QDockWidget::title : 0 declaracao(oes) de padding vertical
  [5] cantos da aba  : 2 declaracoes, 0 fora de 2px
  [6] raio inline em Python : 0 ocorrencia(s)

  6 de 6 asse rcoes passaram. O tema esta como o sponsor arbitrou, e num lugar so.
```

**Não somamos um segundo verificador** — mudamos o **alcance** deste, que era a observação de desenho
que o `#025` propôs e o briefing adotou.

### 3.1 Prova de que a asserção 6 reprova — com arquivo e linha

```
CASO A - devolve um border-radius:9px INLINE no dashboard.py (o badge de versao)
  [6] raio inline em Python : 1 ocorrencia(s)
  GUARDA REPROVOU - 1 problema(s):
    app\profile-template\iman-distro\python\plugins\iman_brand\dashboard.py:259
      [6] border-radius INLINE em Python (9px). O tema e o style.qss - mova a regra para la.
  exit=1

CASO B - devolve um raio do .qss para 6px
  [1] border-radius : 18 declaracoes, 1 fora de 2px
  GUARDA REPROVOU - 1 problema(s):
    app\profile-template\iman-distro\themes\IMAN Terra\style.qss:171
      [1] border-radius: 6px  (esperado 2px)
  exit=1
```

Saída bruta: `evidencia/guarda-reprova.log`.

> ### ⚠ Um defeito da própria guarda, achado ao demonstrá-la
>
> A primeira execução do `CASO A` reprovou **certo, mas anunciou o arquivo errado**: o veredito
> prefixava toda linha com o caminho do `.qss`, então um problema do `dashboard.py` aparecia como
> problema do `style.qss`. É a mesma classe do `DB-20` e do `DB-22` — **a mensagem desviando o
> diagnóstico**, num instrumento cuja razão de existir é apontar o lugar.
>
> Consertado em commit próprio: `Reprova` passa a carregar o **próprio arquivo**, com o `.qss` como
> default. A saída acima já é a do instrumento corrigido.

---

## 4. Evidência visual (`V.1`, `V.4`) — as duas telas do vídeo

`grab()` do Qt, mesmo enquadramento, antes e depois.

| arquivo | o que mostra |
|---|---|
| `evidencia/shots/comp-1-badge-de-versao.png` | o badge de versão: **9px → 2px** |
| `evidencia/shots/comp-2-cartoes-e-tiles.png` | cartão (**14px → 2px**) e tile (**11px → 2px**) |
| `evidencia/shots/comp-3-sobre-creditos.png` | créditos do QGIS no *Sobre*: **10px → 2px** |
| `evidencia/shots/{ANTES,DEPOIS}-home.png` | a home inteira |
| `evidencia/shots/{ANTES,DEPOIS}-sobre.png` | o diálogo *Sobre* inteiro |

> **A foto é `grab()` do Qt, não captura de tela** — pelo lado do Qt ela independe de quem está na
> frente. Foi a lição reaprendida no `#025`, quando a captura por tela pegou outra janela por cima do
> produto.

**O `comp-3` prova algo que valia verificar e não presumir:** o diálogo *Sobre* é **filho da janela
principal**, então **herda a folha do tema** — a regra `QLabel#ImanSobreCreditos` chega lá sem nada a
mais. Os créditos do QGIS seguem íntegros na foto (`BL-1`).

---

## 5. O aceite, na condição do `#025`

```
destino virgem            : True   (desinstalado e apagado)
instalar (limpo)          : exit 0 em 257,4 s
  -> aceite IMEDIATAMENTE depois, sem pausa:

  rodada 1   93,2 s   13 PASS / 0 FAIL / 1 N-E   A02=PASS  origem=evento-de-estilo
  rodada 2   44,7 s   13 PASS / 0 FAIL / 1 N-E   A02=PASS  origem=evento-de-estilo

  2a execucao (A07b)     :  1 PASS / 0 FAIL
```

```
A01=PASS A02=PASS A03=PASS A04=PASS A05=PASS A06=PASS A07=PASS
A08=PASS A09=PASS A10=PASS A11=PASS A12=PASS A13=PASS  M-D11=N/E   A07b=PASS
```

**A rodada de 93,2 s é a mais lenta já registrada nesta bancada** — mais lenta que os 84,8 s do
`#025` e que os 57 s que reprovavam antes do `DB-23`. O `A02` passou, e `origem=evento-de-estilo`
nas duas: o conserto do `#025` continua sendo o **evento**, não a rede.

O único `N/E` é o `M-D11`, bloqueado em A1 desde a `#018`.

---

## 6. Sobre qual artefato foi usado — declarado

A instalação limpa usou o artefato **`33ac0ff`**, do `#025`, e **não** um build desta branch.

**Por quê, e por que isso é suficiente:** esta fatia altera **só a camada de marca**
(`profile-template`), e o harness monta o perfil a partir do **repositório**, não do produto
instalado — é assim desde a `#021`. O que vem do artefato é a **árvore do QGIS**, que esta fatia não
toca. A instalação limpa aqui serve à condição de **carga** do `#025`, que é o que ela existe para
reproduzir.

**O que isso deixa de fora, dito claramente:** o `{app}\profile-template` do produto instalado ainda
carrega os raios antigos. Ele passa a carregar os novos **no próximo build** — que é o canônico de
onde o sponsor vai gravar o vídeo. Nenhuma asserção desta fatia depende disso.

---

## 7. O que esta fatia NÃO fez (`P0.7`)

- **a arte** — arbitrada, nada tocado;
- **travessão** (`#023`), **`CHECKLIST.md` do `BL-7`**, **`DA-3`**;
- **layout, espaçamento e cor** — só o raio mudou;
- **build canônico** — é do arquiteto.

---

## 8. Como reproduzir

```powershell
# a guarda estatica (agora 6 assercoes)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-tema-qss.ps1

# a evidencia visual (grab do Qt: home e Sobre)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\branding-acceptance\Invoke-Aceite.ps1 -Sonda vitrine.py

# o aceite na condicao do #025 (destino virgem, instalar, rodar em seguida)
.\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\branding-acceptance\Invoke-Aceite.ps1
```
