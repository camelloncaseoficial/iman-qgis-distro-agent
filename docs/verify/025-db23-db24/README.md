# `#025` — O produto honesto sobre si mesmo: `DB-23` por evento, `DB-24` por procedência

**Executado em:** 2026-09-09 · branch `feat/025-db23-evento-db24-procedencia` (de `develop` = `105a16a`)
**Artefato da prova:** `Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe`, commit **`33ac0ff`**,
SHA-256 `3E8C4681D8BCF3D2B516A9ED933597A477FD0E5B966083D138B7505A4242F3AA`
**Bancada:** Windows 11 Pro 10.0.26200 · PowerShell 5.1 · Inno Setup 7.1.0 · **sem QGIS de sistema**

---

## 0. Legenda (`E.6`)

| marca | significa |
|---|---|
| **medido** | número obtido nesta bancada, nesta sessão, com evidência em `evidencia/` |
| **relatado** | veio de outra sessão ou de outro observador, identificado como tal |
| **`N/E`** | não medido — nomeado, com o motivo |

---

## VEREDITO

> ### Os dois bloqueadores do `BL-7` caíram, e cada um foi provado na condição que o revelava
>
> **`DB-23`** — o piso do campo de coordenadas deixou de depender do relógio. O gatilho agora é o
> repolimento do widget. Provado **na coluna que reprovava**: destino virgem, instalação limpa de
> **226 s**, e o aceite rodando **imediatamente depois**, três vezes seguidas — **3 de 3 `PASS`**, e a
> primeira rodada foi a **mais lenta já medida nesta bancada** (84,8 s contra os 57 s que antes
> reprovavam).
>
> **`DB-24`** — o produto instalado sabe dizer qual build ele é: `● versão 0.3.0 · 33ac0ff`, na home e
> no Sobre, lido de `{app}\BUILD_ID.txt`, que casa com o `BUILD_INFO.txt` do repo daquele build.
>
> **`13 PASS · 0 FAIL · 1 N/E`** — são **14** asserções agora; a `A13` nasceu com o `DB-24`.
> **O `A09` não mudou de critério**, e isso foi conferido antes de escrever a primeira linha.
>
> **Um achado colateral, declarado e não consertado:** a arbitragem "2px em tudo" do `#022` não
> alcança **6 `border-radius` inline em Python** — a guarda estática só lê o `style.qss` (§5).

---

## 1. `DB-23` — o piso reage a evento, não a relógio

### 1.1 O que estava errado, e por que o `#022` não bastou

O piso sai do **cromo** (o que borda e tema comem do widget), e o cromo só vale se o QSS já estiver
aplicado quando se mede. O `iman_startup.py` reaplica o tema em **800/1500/2500/4000 ms**; o `#022`
mediu numa segunda passada de **4600 ms** e deu por resolvido. Sob carga, 600 ms depois da última
reaplicação **não bastam**.

| condição | `A02` | piso / útil |
|---|---|---|
| logo após build e instalação, rodada de 57 s | **`FAIL`** | 108 px / **92** para os 104 necessários |
| bancada quieta, 4 rodadas de ~40 s | `PASS` | 122 px / 106 |

### 1.2 O conserto — duas responsabilidades, dois gatilhos

`_ContemLargura` passou a separar o que sempre foram duas coisas:

| responsabilidade | gatilho |
|---|---|
| **CALCULAR** piso e teto | `StyleChange` · `Polish` · `PolishRequest` · `FontChange` · `ApplicationFontChange` |
| **REIMPOR** piso e teto | `Resize` · `LayoutRequest` · `Show` |

Não há mais instante a adivinhar: **quem avisa que o tema chegou é o Qt**.

### 1.3 O laço, e como foi fechado

`setMinimumWidth`/`setMaximumWidth` disparam `Resize` e `LayoutRequest` **no próprio widget**, que
voltam ao filtro. Duas travas, e **a de dentro é a que importa**:

1. **por desenho**, o caminho de **geometria só reimpõe** — nunca recalcula. Recalcular jamais
   acontece a partir de um evento que o próprio cálculo produziu;
2. `_reentrante` corta a volta enquanto o cálculo aplica; e as comparações tornam a reimposição um
   **no-op** quando o valor já está certo.

### 1.4 O piso só cresce — a defesa contra a medição transitória

O widget **despolido** mede cromo **menor** (2 px) que o polido (16 px). Um evento que chegue no meio
de um repolimento, portanto, **nunca rebaixa** um piso já correto. Não há caminho em que o tema
encolha de verdade: o QSS do produto só acrescenta borda e recuo.

### 1.5 A rede de segurança — declarada como rede, e verificável

Sobra **um** temporizador, em 6000 ms, que chama `recalcula`. Ele **não é o mecanismo**: existe para
o caso de o Qt não entregar evento de estilo nenhum depois da última reaplicação — situação que
**não foi observada nesta bancada**. Como o piso só cresce, ele é inofensivo quando o evento já fez
o trabalho.

**E dá para saber, de fora, qual dos dois fechou a conta.** O filtro publica
`origem_do_valor_vigente`, e o `A02` o imprime:

```json
{"piso": 122, "teto": 236, "cromo": 16,
 "origem_do_valor_vigente": "evento-de-estilo",
 "recalculos_que_mudaram_o_valor": 2}
```

**Foi o evento.** A rede não precisou agir em nenhuma das rodadas.

> O temporizador de **1800 ms** continua, e também está declarado: ele **não decide valor nenhum** —
> só espera o QGIS criar o widget da status bar para haver em que instalar o filtro.

### 1.6 A prova, na condição que reprova

Sequência **medida**, sem pausa entre as etapas:

```
destino virgem            : True   (desinstalado e apagado)
instalar (limpo)          : exit 0 em 226,0 s
  -> e o aceite IMEDIATAMENTE depois, tres vezes seguidas:

  rodada 1   84,8 s   13 PASS / 0 FAIL / 1 N-E   A02=PASS piso=122 util=106/104  origem=evento-de-estilo
  rodada 2   46,6 s   13 PASS / 0 FAIL / 1 N-E   A02=PASS piso=122 util=106/104  origem=evento-de-estilo
  rodada 3   48,5 s   13 PASS / 0 FAIL / 1 N-E   A02=PASS piso=122 util=106/104  origem=evento-de-estilo
```

**A rodada 1, de 84,8 s, é a mais lenta já registrada nesta bancada** — mais lenta que os 57 s que
antes reprovavam. É a coluna do `FAIL`, e ela passou.

---

## 2. `DB-24` — o produto sabe de que build ele é

### 2.1 O que estava errado

O próprio `BUILD_INFO.txt` declara que a identidade de um artefato é o par
**(ProductVersion, Commit)** — o SHA-256 muda com o `mtime` que o Inno grava e o git não preserva.
Só que **o Commit não chegava ao usuário**: o produto declarava só `VERSION = "0.3.0"`. O artefato
de branch e o canônico eram **ambos 0.3.0 e indistinguíveis de dentro do produto**. A procedência
que o `D-IMAN-032` construiu morria na fronteira do instalador.

### 2.2 A cadeia, em três peças

| peça | o que faz |
|---|---|
| `installer\build.ps1` | grava `installer\stage\BUILD_ID.txt` **antes** de compilar |
| `installer\iman-terra.iss` | embarca o arquivo em **`{app}\BUILD_ID.txt`** |
| `brand.py` | **lê dali**; a home, o Sobre e o banner exibem |

**O valor nunca é digitado.** `brand.py` não tem constante de commit. Sem o arquivo (árvore de
desenvolvimento), a identidade é **desconhecida** e o produto mostra só a versão — **não inventa
commit**.

### 2.3 ⚠ A armadilha de ordem, e por que o `SHA` do `.exe` não está lá

O `BUILD_ID` entra **na** compilação, então só pode conter o que já se sabe **antes** de compilar:
versão, commit, data do commit, branch e o SHA-256 do **payload**. O SHA-256 do próprio `.exe` só
existe **depois** — e embarcá-lo mudaria o hash do arquivo que o contém. Ele continua vivendo só no
`BUILD_INFO.txt` do repo, que é onde se confere o arquivo que chegou na VM.

**Verificado:** o SHA do artefato **não** aparece no `BUILD_ID.txt`.

### 2.4 `C.3` fail-loud, em duas camadas

- `build.ps1` **aborta** se não conseguir gravar o arquivo;
- o `.iss` tem **`#error` de tempo de compilação** se ele não existir — chamar o ISCC na mão pula a
  geração, e o produto sairia mudo sobre si.

### 2.5 A prova — a cadeia inteira, ponta a ponta

```
BUILD_INFO (repo)  : versao=0.3.0  commit=33ac0ff803feb7fd7c6cdc7e821730903c3b9f05  curto=33ac0ff
BUILD_ID   ({app}) : versao=0.3.0  commit=33ac0ff803feb7fd7c6cdc7e821730903c3b9f05  curto=33ac0ff
TELA               : 0.3.0 · 33ac0ff

commit repo == {app}                        : True
curto  repo == {app}                        : True
tela contem o curto                         : True
SHA do .exe NAO esta no BUILD_ID            : True
```

**Na tela:** `evidencia/shots/db24-1-home-badge.png` (badge da home) e
`evidencia/shots/db24-2-sobre.png` (o diálogo *Sobre o IMAN Terra* real, não uma imitação — mesma
`brand.versao_exibida()`).

> As fotos são **`grab()` do Qt**, não captura de tela. A primeira tentativa por tela pegou **outra
> janela na frente** do produto — o mesmo erro que o `#016` já tinha registrado. Pelo lado do Qt, a
> foto independe de quem está na frente.

### 2.6 `A13` — a asserção que nasceu com o defeito

Mede a **cadeia**, não um pedaço dela: o arquivo entregue, o valor que o produto **lê** dele, e o que
chega à **tela**.

| | |
|---|---|
| campos obrigatórios presentes | ✅ |
| commit curto é prefixo do completo | ✅ |
| commit da tela bate com o arquivo | ✅ |
| versão da tela bate com o arquivo | ✅ |

**`se_quebrado` (`C.2`):** sem o conserto o produto exibe `versão 0.3.0` e nada mais — uma string
válida, bonita, e **idêntica em todo artefato 0.3.0 já compilado**. *"A home mostra uma versão"*
passaria com o defeito presente; o que não estaria lá é a resposta a **"qual build é este?"**.

Contra árvore de desenvolvimento o `A13` é **`N/E` com o motivo dito** (o arquivo nasce no build);
contra produto instalado, ausência é **`FAIL`**.

### 2.7 O `A09` não mudou de critério

Conferido **antes** de escrever a mudança: o `A09` procura o padrão
`<maior>.<menor>.<correção>` na string exibida, e `versão 0.3.0 · 33ac0ff` continua casando `0.3.0`.
**Nenhuma linha do `A09` foi tocada**, e ele segue `PASS` com as quatro fontes em acordo:

```
{'exibida_na_home': '0.3.0', 'brand.py': '0.3.0',
 'metadata.txt': '0.3.0', 'iss ProductVersion': '0.3.0'}
```

---

## 3. Uma mudança de ambiente do harness, declarada

`IMAN_TERRA_HOME` passou a apontar para o **`{app}` do produto instalado**, e não para o `app\` do
repo — que é o que o launcher faz na máquina do usuário. Sem isso o `A13` mediria uma árvore de
desenvolvimento, onde a identidade do build **não existe por construção**.

**Efeito colateral declarado:** `demo\welcome.qgz` e `notices\THIRD_PARTY_NOTICES.md` passam a vir do
produto instalado. São os mesmos arquivos que o build empacotou daquele commit — se divergirem, é
porque a árvore de trabalho tem alteração não compilada, e isso é informação, não ruído.

---

## 4. O placar

```
A01=PASS A02=PASS A03=PASS A04=PASS A05=PASS A06=PASS A07=PASS
A08=PASS A09=PASS A10=PASS A11=PASS A12=PASS A13=PASS  M-D11=N/E   A07b=PASS

14 assercoes: 13 PASS - 0 FAIL - 1 N/E
guarda estatica do tema: 5 de 5
```

O único `N/E` é o `M-D11`, bloqueado em A1 desde a `#018`.

---

## 5. ⚠ ACHADO COLATERAL — "2px em tudo" não alcança o Python

A arbitragem do `#022` foi *"coloque 2px para tudo, já é muito"*, e a guarda estática assere as
**12** declarações de `border-radius` do `style.qss` mais os 2 cantos da aba. **Ela só lê o
`style.qss`.**

Há **6 declarações de `border-radius` inline no Python** da camada de marca, fora do alcance da
guarda — e elas aparecem na foto desta fatia (o badge arredondado de `● versão 0.3.0 · 33ac0ff`):

| arquivo | linha | valor | alvo |
|---|---|---|---|
| `dashboard.py` | 108 | **11px** | `QLabel#qatile` (ícone do cartão) |
| `dashboard.py` | 116 | **14px** | `QFrame#qa` (cartão de ação rápida) |
| `dashboard.py` | 177 | **10px** | item de projeto recente |
| `dashboard.py` | 248 | **9px** | **o badge de versão** |
| `iman_brand.py` | 279 | **8px** | botão de marca da toolbar |
| `sobre.py` | 108 | **10px** | bloco do diálogo Sobre |

**Não consertei**, e é deliberado: esta fatia é `DB-23` + `DB-24`, e o `P0.7` dela não inclui raio.
Fica nomeado, com arquivo e linha, para virar decisão do arquiteto — e com uma observação de
desenho: **enquanto houver estilo inline em Python, a guarda estática do `style.qss` não é uma
guarda do tema, é uma guarda de um arquivo.** O conserto honesto é mover esses seis para o `.qss`
(onde a guarda os alcança), não acrescentar um segundo verificador para o Python.

---

## 6. O que esta fatia NÃO fez (`P0.7`)

- **a arte** — arbitrada; nenhum master ou derivado foi tocado;
- **a varredura de travessão** — é o `#023`;
- **embarcar o plugin REURB** (`DA-3`) — não é desta fatia;
- **reescrever o `CHECKLIST.md` do `BL-7`** — é a fatia seguinte, e depende desta;
- **o raio inline em Python** — §5, achado nomeado, não consertado.

---

## 7. Evidência

| arquivo | o que é |
|---|---|
| `evidencia/aceite.json` · `aceite-segunda.json` | `13 PASS · 0 FAIL · 1 N/E`, com `A13` e o diagnóstico do `DB-23` |
| `evidencia/BUILD_ID-33ac0ff.txt` | a identidade que viajou dentro do produto |
| `evidencia/BUILD_INFO-33ac0ff.txt` | o `BUILD_INFO` do repo daquele build, para o cruzamento |
| `evidencia/shots/db24-1-home-badge.png` | o commit curto na home |
| `evidencia/shots/db24-2-sobre.png` | o commit curto no *Sobre* real |
| `evidencia/shots/vitrine-*.png` | os `grab()` de origem |

---

## 8. Como reproduzir

```powershell
# 1. build do artefato desta branch
.\installer\build.ps1 -ExpectedBranch feat/025-db23-evento-db24-procedencia -ReusarArvore

# 2. a condicao que reprova: destino virgem, instalacao limpa, aceite EM SEGUIDA
#    (desinstale e apague %LOCALAPPDATA%\Programs\IMAN Terra antes)
.\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\branding-acceptance\Invoke-Aceite.ps1   # x3, sem pausa

# 3. a identidade na tela
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\branding-acceptance\Invoke-Aceite.ps1 -Sonda vitrine.py
```
