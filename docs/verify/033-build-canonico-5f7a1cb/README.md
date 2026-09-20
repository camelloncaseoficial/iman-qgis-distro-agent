# `#033` — O build canônico `5f7a1cb`, e a primeira prova do instalador novo

**Laudo fechado em:** 2026-09-20 · branch **`develop`** · commit do artefato **`5f7a1cb`**
**Bancada:** Windows 11 Pro 10.0.26200 · Windows PowerShell 5.1.26100.9444 · Inno Setup 7.1.0 · **sem QGIS de sistema**
**Tipo:** operacional — **nenhum arquivo de aplicação mudou.**

O despacho foi executado em três datas, na **mesma bancada**, e o laudo diz qual é qual:
o **build** em 2026-09-16, a **instalação** em 2026-09-19, e a **medição** em 2026-09-20.

---

## 0. Legenda (`E.6`)

| marca | significa |
|---|---|
| **medido** | número obtido nesta bancada, com evidência em `evidencia/` |
| **relatado** | veio de outra sessão ou de outro observador, identificado como tal — o log cru vai junto quando existe |
| **`N/E`** | não medido — nomeado, com o motivo |

---

## VEREDITO

> ### O ponto cego do `#030` fechou: o instalador entrega o `DB-26`, e o `DB-26` roda a partir do instalado
>
> ```
> Artefato        : Instituto-IMAN-IMAN-Terra-Setup-0.3.0-5f7a1cb.exe   (489,06 MB)
> SHA-256         : 949A960F36811327A21C250F5889E50E4A3DCD647BCAEF3F5C8DA35D86F2EFF5
> Tamanho         : 512.818.809 bytes
> Commit          : 5f7a1cb7275ce4cfc1abc718f7b2a9619ebf4596   (== HEAD da develop no build)
> Build canonico  : SIM
> ```
>
> **`35 de 35`** arquivos de `app/` chegaram a `{app}` **idênticos por SHA-256** — entre eles o
> `Sync-Perfil.ps1` e o `PERFIL-DO-PRODUTO.json`, que nenhum artefato anterior carregava.
>
> Chamando **o launcher que o instalador colocou em `{app}\launcher`**, com `%APPDATA%`
> redirecionado: perfil ausente **nasce semeado** e perfil de `ba58d14` **é reconciliado** —
> raios `5–8px` → `0`, `2px` → `20`, `_RE_SUFIXO_DO_QGIS` `0` → `3`, e `11 de 11` arquivos do
> produto com o SHA-256 do **template instalado**.
>
> **`13 PASS · 0 FAIL · 1 N/E`** contra o artefato instalado, e **outra vez `13 PASS · 0 FAIL · 1 N/E`**
> sobre um perfil vindo de `ba58d14` e reconciliado. Guardas: **`11 de 11`** e **`6 de 6`**.
>
> **Placar do laudo: `13 de 13` verificações verdes.** O único `N/E` é o `M-D11`, de sempre.

---

## 1. Placar, em `n de N`

| # | verificação | resultado | marca |
|---|---|---|---|
| 1 | SHA-256 do artefato, recalculado aqui, == o gravado no `BUILD_INFO` | **igual** | medido |
| 2 | commit do `BUILD_INFO` == `HEAD` da `develop` no build | **`5f7a1cb`** | medido |
| 3 | `app/` inteiro chega a `{app}` byte a byte | **35 de 35** | medido |
| 4 | integridade da árvore instalada, pela guarda do próprio produto | **`INTEGRIDADE=OK`** | medido |
| 5 | reconciliação no produto instalado — **perfil ausente** | **PASS** | medido |
| 6 | reconciliação no produto instalado — **perfil velho de `ba58d14`** | **PASS** | medido |
| 7 | `BL-3` — o perfil REAL do sponsor não foi tocado | **PASS**, 0 de 27 MD5 mudaram | medido |
| 8 | aceite contra o artefato instalado, 1ª execução | **13 PASS · 0 FAIL · 1 N/E** | medido |
| 9 | aceite, 2ª execução (`A07b`, perfil reaproveitado) | **1 PASS · 0 FAIL** | medido |
| 10 | aceite **sobre perfil de `ba58d14` reconciliado** | **13 PASS · 0 FAIL · 1 N/E** | medido |
| 11 | guarda da reconciliação (`#030`), 11 estados | **11 de 11** | medido |
| 12 | guarda estática do tema (`#022`) | **6 de 6** | medido |
| 13 | `Passo 0` ao fim — as duas cópias do `327d9ee` intactas, e os dois registros na `develop` | **PASS** | medido |

**`13 de 13`.** Fora da tabela, e declarado como tal: o **build** em si é **relatado** (§2), e o
`M-D11` do aceite é **`N/E`** (§7).

---

## 2. O build — **relatado**, com o log cru junto

`installer\build.ps1` **sem argumentos** rodou em **2026-09-16**, nesta bancada, **noutra sessão**.
**Não o repetimos, e é deliberado:** recompilar o mesmo commit dá outro SHA-256 (`D-IMAN-032` — o
Inno grava `mtime` e o git não o preserva), e o candidato instalado deixaria de ser o registrado.

Log cru: `evidencia/entrega1-build-2026-09-16.out`. Passo 0 de antes: `evidencia/passo0-antes-2026-09-16.txt`.

```
    OK  branch 'develop', arvore limpa
    OK  ProductVersion 0.3.0 / QGIS embarcado 3.44.13
    OK  identidade 0.3.0-5f7a1cb -> Instituto-IMAN-IMAN-Terra-Setup-0.3.0-5f7a1cb.exe
    OK  versao do produto 0.3.0 concorda nas tres fontes            (D9)
    OK  payload conferido (42E2F1A6...44EB4)
    OK  extracao concluida em 287,0 s (exit 0)
    OK  arvore: 37337 arquivos / 2,224 GB

  #019 - guarda de integridade do launcher       6 de 6 casos passaram
  #022 - guarda estatica do tema                 6 de 6 assercoes passaram

    OK  BUILD_ID.txt: 0.3.0 / 5f7a1cb / develop (canonico: sim)
    OK  Instituto-IMAN-IMAN-Terra-Setup-0.3.0-5f7a1cb.exe (489.06 MB)
  exit=0  duracao=2142 s
```

Os dois placares saem **contados pela própria guarda**, e a linha de resumo do `build.ps1` agora
imprime `6 de 6` — a imprecisão nomeada no `#028` (§6 daquele laudo) **não aparece mais**.

A instalação do artefato na bancada — o `STOP-AND-FLAG` `S.5` do despacho — é **relatada**: ocorreu
em **2026-09-19**, com o sponsor. O que este laudo mede é o **resultado** dela, e o resultado carrega
a data: `{app}\unins000.exe` de `19/09 03:19` e as pastas de `{app}` de `19/09 03:21`.

---

## 3. `E.5` — o SHA-256, recalculado nesta máquina

```powershell
Get-FileHash .\installer\canonico\0.3.0-5f7a1cb\Instituto-IMAN-IMAN-Terra-Setup-0.3.0-5f7a1cb.exe -Algorithm SHA256
```

| | |
|---|---|
| calculado agora (2026-09-20) | `949A960F36811327A21C250F5889E50E4A3DCD647BCAEF3F5C8DA35D86F2EFF5` |
| gravado no `BUILD_INFO` | `949A960F36811327A21C250F5889E50E4A3DCD647BCAEF3F5C8DA35D86F2EFF5` |
| **batem** | **sim** |
| tamanho | **512.818.809 bytes** (489,06 MB), igual ao registrado |
| commit do `BUILD_INFO` | `5f7a1cb7275ce4cfc1abc718f7b2a9619ebf4596` |
| `HEAD` da `develop` no build | **o mesmo** |

Essa conferência foi feita **antes** de commitar o registro, e é o que autorizou o commit.

Evidência: `evidencia/procedencia.txt`, `evidencia/BUILD_INFO-5f7a1cb.txt`.

---

## 4. O registro, commitado direto na `develop` (`P0.6`)

Commit **`fc2a7cc`** — `build(0.3.0): o candidato vigente passa a ser o canonico 5f7a1cb`:

```
 installer/canonico/0.3.0-5f7a1cb/BUILD_INFO.txt | 64 ++++++++++++
 installer/canonico/VIGENTE.txt                  | 10 +++-----
 2 files changed, 69 insertions(+), 5 deletions(-)
```

**Dois arquivos, e nada mais.** O `.exe` ao lado **não entrou** — `git check-ignore` responde
`.gitignore:38:*.exe`. Quem compilou é quem commitou, na mesma máquina (`D-IMAN-032`).

O `VIGENTE.txt` passou a apontar para o candidato novo, e **as duas pastas coexistem** (`R4`):

```
identidade=0.3.0-5f7a1cb
commit=5f7a1cb7275ce4cfc1abc718f7b2a9619ebf4596
artefato=Instituto-IMAN-IMAN-Terra-Setup-0.3.0-5f7a1cb.exe
sha256=949A960F36811327A21C250F5889E50E4A3DCD647BCAEF3F5C8DA35D86F2EFF5
registro=installer/canonico/0.3.0-5f7a1cb/BUILD_INFO.txt
```

```
$ git ls-files installer/canonico/
installer/canonico/0.3.0-327d9ee/BUILD_INFO.txt
installer/canonico/0.3.0-5f7a1cb/BUILD_INFO.txt
installer/canonico/VIGENTE.txt
```

### `Passo 0`, repetido ao fim do despacho

| cópia do `327d9ee` | SHA-256 **medido agora** | |
|---|---|---|
| `installer\canonico\0.3.0-327d9ee\...-0.3.0-327d9ee.exe` | `38DA4709...B73E7` | **igual ao esperado** |
| `D:\_iman-terra-candidatos-protegidos\0.3.0-327d9ee\...` | `38DA4709...B73E7` | **igual ao esperado** |

Ambas com `512.808.129` bytes. **Um build canônico não destruiu canônico nenhum** — a promessa do
`#029` continua medida, agora nas duas pontas do despacho.

---

## 5. O ponto cego, fechado: o instalador entrega os arquivos novos

O gate do `#030` foi explícito — *ninguém instalou um build que contenha `Sync-Perfil.ps1` e
`PERFIL-DO-PRODUTO.json`*. **O arquiteto já gateou esta entrega, com execução**, e nós a
**re-medimos mais larga**: não os dois arquivos, mas **`app/` inteiro**.

| arquivo | `{app}` | SHA-256 |
|---|---|---|
| `Sync-Perfil.ps1` | `{app}\launcher\` | `0313A399...6E11` (29.639 bytes) |
| `PERFIL-DO-PRODUTO.json` | `{app}\profile-template\` | `5C5EA99D...6DF7` (5.020 bytes) |
| `IMAN-Terra.bat` | `{app}\launcher\` | `78F2DF3E...5A3C` (19.573 bytes) |

```
arquivos em app\ (sem pyc/__pycache__/.gitkeep) = 35
identicos em {app} por SHA-256                  = 35
divergentes                                     = 0
ausentes em {app}                               = 0
```

E o `BUILD_ID.txt` em `{app}`:

```
versao=0.3.0   commit=5f7a1cb7275ce4cfc1abc718f7b2a9619ebf4596
commit_curto=5f7a1cb   branch=develop   build_canonico=sim
```

Esse `35 de 35` não é enfeite: ele é o que permite ler o aceite (§7) sem asterisco, porque o
harness do `#017` semeia o perfil e o `--code` a partir da **árvore de trabalho** — e a árvore de
trabalho e o `{app}` são, **medidamente**, o mesmo conjunto de bytes.

Evidência: `evidencia/entrega4-app-vs-instalado.txt`.

---

## 6. A outra metade: a reconciliação roda **a partir da instalação**

Até aqui o `DB-26` só tinha sido provado com o launcher **do repositório**, dentro de um `APP_HOME`
sintético. Este laudo chama **`{app}\launcher\IMAN-Terra.bat`**, com o template, a declaração e a
árvore do QGIS **que o instalador entregou**, e com `%APPDATA%` **redirecionado** para o sandbox —
nunca o perfil real (`BL-3` / `Passo 0`).

Script: `evidencia/Medir-Reconciliacao-Instalada.ps1` · saída: `evidencia/entrega5-reconciliacao-instalada.out`

### (a) perfil ausente — o primeiro uso de quem acabou de instalar

```
exit=0  RECONCILIACAO=SEMEADO  arq+11 arq~0 arq-0 chave+0 chave~0 chave-0 pasta+2 splash+1 base+1
perfil existia antes da abertura: False
11 de 11 arquivos do template INSTALADO com SHA-256 identico no perfil
base registrada em .iman-terra\base.json: True
  template_digest=05DE72FB4FED54B2ED9A9CCE8C4C967DFE844AAF5F428E3551CC9B5EBECEBBC0  chaves=8
```

### (b) perfil velho de `ba58d14`, semeado por **cópia crua** — onde o 3-way pode errar

`E.1` conferido antes de abrir: o perfil semeado **de fato** tem 14 raios de 5–8 px, zero raio de
2 px, `QMenuBar::item 6px 12px`, **zero** `_RE_SUFIXO_DO_QGIS`, e só **4 de 11** arquivos batendo
com o template instalado. Se já saísse igual, a rodada não provaria nada.

```
exit=0  RECONCILIACAO=APLICADA  arq+0 arq~7 arq-0 chave+0 chave~0 chave-0 pasta+0 splash+1 base+1
raios: 5-8px 14 -> 0   2px 0 -> 20  (o template instalado tem 20)
QMenuBar::item: 6px 12px -> 3px 4px? True
_RE_SUFIXO_DO_QGIS em iman_brand.py: 0 -> 3  (o template instalado tem 3)
arquivos do produto com SHA-256 do template INSTALADO: 11 de 11 (antes: 4 de 11)
base registrada: True  template_digest=05DE72FB...BBC0
```

### O título, medido **na tela**, sobre esse mesmo perfil velho

Os itens acima são do arquivo. *"Título sem `QGIS`"* é da tela, então foi medido na tela: o aceite
do `#017` rodou contra o **produto instalado**, com o perfil semeado de `ba58d14` e reconciliado
pela rotina do produto. **`13 PASS · 0 FAIL · 1 N/E`**, e o `A05` nos cinco estados:

```
Projeto sem título - IMAN Terra        b_sem_QGIS=True  d_sem_travessao=True   [sem projeto]
spike017-projeto-alfa - IMAN Terra     b_sem_QGIS=True  d_sem_travessao=True   [projeto aberto]
Projeto sem título - IMAN Terra        b_sem_QGIS=True  d_sem_travessao=True   [projeto novo]
*Projeto sem título - IMAN Terra       b_sem_QGIS=True  d_sem_travessao=True   [modificado sem salvar]
Caucaia — Setor 3 (QGIS) - IMAN Terra  b_sem_QGIS=True  d_sem_travessao=True   [CONTROLE, nome hostil]
```

Evidência: `evidencia/entrega5-aceite-perfil-velho-reconciliado.{out,json}`.

### `BL-3` — o perfil do sponsor não foi tocado

```
27 arquivo(s) sob %APPDATA%\QGIS e %APPDATA%\InstitutoIMAN, MD5 antes x depois: 0 diferenca(s)
```

### O caminho feliz já tinha acontecido sozinho, no mundo

O perfil **real** do sponsor reconciliou na primeira abertura do produto novo, em **2026-09-19
03:21:53**, e ganhou `.iman-terra\base.json` com
`template_digest=05DE72FB4FED54B2ED9A9CCE8C4C967DFE844AAF5F428E3551CC9B5EBECEBBC0` — **o mesmo
digest** que as duas rodadas acima produziram contra o template instalado. É uma conferência
cruzada gratuita: a rodada em sandbox e o perfil real convergiram para a mesma base.

---

## 7. Aceite e guardas, contra o artefato instalado

**Condição declarada** (`DB-23`: placar sem condição não vale): bancada **quieta** — zero processos
`qgis-ltr-bin`/`qgis-bin` vivos antes e depois de cada rodada, nenhum build em curso, sem QGIS de
sistema, e o perfil do aceite **reconstruído do zero** em `%LOCALAPPDATA%\InstitutoIMAN\_aceite017`.

| | **medido** |
|---|---|
| guarda de integridade do próprio produto (`IMAN_TERRA_CHECK_ONLY=1`) | `exit 0`, **`INTEGRIDADE=OK`**, 1,5 s |
| **aceite, 1ª execução** | **`13 PASS · 0 FAIL · 1 N/E`** — 50,6 s |
| **aceite, 2ª execução** (`A07b`) | **`1 PASS · 0 FAIL`** — 18,1 s |
| **aceite sobre perfil velho reconciliado** | **`13 PASS · 0 FAIL · 1 N/E`** — 42,1 s |
| guarda da reconciliação (`#030`) | **11 de 11** — 77,5 s |
| guarda estática do tema (`#022`) | **6 de 6** |

```
A01=PASS A02=PASS A03=PASS A04=PASS A05=PASS A06=PASS A07=PASS
A08=PASS A09=PASS A10=PASS A11=PASS A12=PASS A13=PASS   M-D11=N/E   A07b=PASS
```

O `A13` leu a identidade **do artefato instalado** e a comparou com a tela:

```
BUILD_ID ({app}) : versao=0.3.0  commit=5f7a1cb7275ce4cfc1abc718f7b2a9619ebf4596  canonico=sim
TELA             : ● versão 0.3.0 · 5f7a1cb
TITULO           : Projeto sem título - IMAN Terra
```

O `A02` continua com `origem_do_valor_vigente=evento-de-estilo` — o conserto do `DB-23` é o
**evento**, não o relógio. O único `N/E` é o `M-D11` (agrupamento na barra de tarefas), que não é
observável de dentro do processo; ele está bloqueado desde a `#018` e continua nomeado, nunca `PASS`.

Os 11 estados da guarda da reconciliação, todos verdes, incluem os que o despacho chamou de
"onde o 3-way pode errar": chave que o usuário mudou e o produto não (fica a do usuário), chave que
os dois mudaram (vence o produto), plugin do usuário intacto byte a byte, chave nova do template
chegando a perfil velho, falha no meio com `INCOMPLETO.txt` e sem `base.json`, instância viva
recusando com `exit=2`, e downgrade.

Evidência: `evidencia/entrega6-*.{out,json}`, `evidencia/entrega6-integridade-check-only.out`.

### Um limite deste enquadramento, nomeado

O aceite do `#017` sobe o **QGIS do produto instalado** e lê o **`BUILD_ID.txt` do produto
instalado**, mas semeia o perfil e o `--code` a partir da **árvore de trabalho** — é o desenho dele
desde a `#021`. O mesmo vale para o `-Reconciliar`, que chama o `Sync-Perfil.ps1` **do repositório**.
Isso só não é um asterisco porque o `35 de 35` da §5 mede que os dois lados são os mesmos bytes.
**A entrega 5 é que não tem esse limite:** lá quem roda é o launcher de `{app}`, e o template
comparado é o de `{app}`.

---

## 8. A deriva da árvore morreu — e o que cresceu na instalada não é deriva

O despacho previu que este build, por **remontar a árvore e regenerar o manifesto na mesma
execução**, consertaria de graça a deriva declarada no `#030` (37.318 contra 37.337, com 401 `.pyc`
em `apps\grass`). **Consertou:**

| | **medido em 2026-09-20** |
|---|---|
| `TOTAL` do manifesto | **37.337** |
| árvore estagiada (`installer\stage`, a que o build empacotou) | **37.337** — diferença **0** |
| árvore instalada (`{app}\qgis`), depois de o produto ter sido aberto | **38.154** |
| só na estagiada | **0** |
| só na instalada | **817** — e **817 são `.pyc`** |
| comuns com `mtime` diferente | **19** — e **19 são `.pyc`** |

Ou seja: **nenhum arquivo do manifesto falta na instalação, e nenhum arquivo não-`.pyc` difere.** O
que cresceu é bytecode que o Python do próprio produto grava em `__pycache__` ao importar. É
exatamente o caso que o launcher já prevê: a contagem de `DIR` é conferida como **piso**, não como
igualdade — *truncar sempre diminui a contagem; crescer nunca é truncar*. `apps\Python312` está com
20.111 contra os 19.666 do manifesto, e `INTEGRIDADE=OK`, como o desenho manda.

Evidência: `evidencia/deriva-da-arvore.txt`.

---

## 9. O que continua pendente

- **`BL-7` em VM limpa** — esta é a bancada do dev. O artefato a levar é o da §3, e o `SHA-256` de
  lá é o que se confere na VM.
- **Reescrever o `CHECKLIST.md` do `BL-7`** — fatia própria, e vai citar este build.
- **`M-D11`** — o passo manual do ícone na barra de tarefas, bloqueado em A1 desde a `#018`.
- **`#023`** (travessão na distro) · **`DA-3`** (plugin REURB) · exclusão de pacotes do `#020`.
- Assinatura de código.

## 10. Como este laudo entrou

Sem PR, pela mesma exceção `P0.6` do registro: **o laudo é gateado retroativamente pelo arquiteto**,
e correção vira commit de seguimento sob a mesma exceção.
