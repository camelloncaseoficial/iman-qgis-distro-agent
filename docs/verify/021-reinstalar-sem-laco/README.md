# `#021` — O produto reinstala, e o aceite volta a rodar

**Executado em:** 2026-09-09 · branch `feat/021-reinstalar-sem-laco-e-aceite` (de `develop` = `ba58d14`)
**Bancada:** Windows 11 Pro 10.0.26200 · PowerShell 5.1 · Inno Setup 7.1.0 · **sem QGIS de sistema**
**Fecha:** `DB-22` e a dívida que a `A1` criou.

---

## 0. Legenda (`E.6`)

| marca | significa |
|---|---|
| **medido** | número obtido nesta bancada, nesta sessão, com evidência em `evidencia/` |
| **relatado** | veio de outra sessão ou de outro observador, e está identificado como tal |
| **`N/E`** | não medido — nomeado, com o motivo |

---

## VEREDITO

> ### A tensão da bancada está desfeita — e é a entrega que sustenta as outras
>
> O harness de aceite exigia `C:\Program Files\QGIS 3.44.13` instalado; `New-ArvoreQgis.ps1` exige
> que essa instalação **não** exista. Instalar para testar desarmava o build; desinstalar para
> buildar desarmava o teste. **O produto não precisa de nenhum dos dois — ele carrega o próprio
> QGIS.** O aceite passou a subir a árvore do produto, e a bancada rodou as duas coisas na mesma
> sessão, sem nenhum QGIS em `C:\Program Files`.
>
> **`12 PASS · 0 FAIL · 1 N/E`** contra a árvore do produto, e o aceite **ainda sabe reprovar**:
> revertido o `D1`, o `A01` volta a vermelho **e só ele**; revertido o `D8`, o `A08` volta a
> vermelho **e só ele** — agora pelo critério de **procedência**, não por lista de strings.
>
> O `DB-22` está consertado na causa: o instalador **limpa `{app}\qgis` antes de copiar**, então
> "reinstalar" virou instrução verdadeira — inclusive sobre uma árvore em que alguém acrescentou
> arquivos.
>
> **O que esta fatia NÃO entrega:** o **build canônico** (`Entrega 4`). Ele exige a branch
> `develop`, e o `P0.6` proíbe mergear. Ver §6 — está declarado, com o comando exato.
>
> **E o que ela ACHOU sem procurar:** o produto instalado escreve **`QGIS`** na própria barra de
> título assim que existe mais de um perfil na raiz — e o **`A05` diz `PASS`** enquanto isso
> acontece. Reproduzido duas vezes, com a causa isolada. **Fora de escopo, e por isso declarado e
> não consertado:** §7.

---

## 1. `DB-22` — "reinstale" passa a ser verdade

### 1.1 O que sobrevive da tabela do briefing, e o que não

O briefing já trazia a ressalva, e ela se confirma: da tabela do gate do `#23` sobrevive o **`exit 5`**
e a **árvore misturada de dois builds**. O **diagnóstico de contagem não sobrevive** — a mensagem de
guarda citada veio de um launcher sobrevivente da instalação anterior, que ainda usava **igualdade**;
a guarda atual usa **piso** desde `be0e3df` e não recusa aquela árvore.

**O alvo real:** o instalador **fundia** a árvore nova sobre a velha. "Reinstalar" fundia de novo —
laço fechado, a mesma classe do `DB-20`: a mensagem desviava o diagnóstico.

### 1.2 O conserto

Não é na mensagem. É uma seção `[InstallDelete]`, que o Inno executa **antes** da seção `[Files]`:

```
[InstallDelete]
Type: filesandordirs; Name: "{app}\qgis"
```

**`{app}\qgis`, e não `{app}`** — limpar a raiz apagaria o `unins000.exe` em uso.

| preservado de propósito | por quê |
|---|---|
| `unins000.exe` / `unins000.dat` | o desinstalador está **em uso** durante a reinstalação |
| a camada de marca em `{app}` (`assets`, `demo`, `launcher`, `notices`, `profile-template`, `startup`) | a seção `[Files]` a reescreve com `ignoreversion` |
| `%APPDATA%\InstitutoIMAN\...` — o **perfil isolado do usuário** | está fora de `{app}`; **BL-3**: nem aqui nem no uninstall |

`{app}\qgis` é 100% nosso: nasce deste instalador e não há nada do usuário lá dentro.

### 1.3 O ciclo, medido

| # | passo | `exit` | tempo | árvore | manifesto | dif | `INTEGRIDADE` |
|---|---|---|---|---|---|---|---|
| 0 | destino **virgem** | — | — | — | — | — | — |
| 1 | instalar em destino virgem *(o caminho que já funcionava)* | **0** | 90,7 s | **37 337** | 37 337 | **0** | **OK** |
| 2 | abrir → fechar → reabrir → fechar | — | — | **38 154** *(+817)* | 37 337 | +817 | — |
| 3 | **instalar SOBRE a instalação existente** *(o `DB-22`)* | **0** | 134,0 s | **37 337** | 37 337 | **0** | **OK** |
| 4a | injetar **25 arquivos** na árvore | — | — | 37 362 | 37 337 | +25 | — |
| 4b | instalar sobre a árvore corrompida | **0** | 176,3 s | **37 337** | 37 337 | **0** | **OK** — **0 dos 25 sobreviveram** |
| 5 | abrir → fechar → reabrir → fechar | — | — | 38 154 | 37 337 | +817 | — |
| 6 | **desinstalar** | **0** | 10,4 s | — | — | — | **0 arquivos / 0,00 MB deixados** |

Instrumento: `tools/test-reinstalacao.ps1`. Saída bruta: `evidencia/reinstalacao.json`.
Artefato: `Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe`, SHA-256
`EB9108C574C5DEDC03A102E19CB38AAFDC310236D7ED57B08C40ECECCED05350`, commit `3ecea9c`.

**As três asserções do briefing, uma a uma:**

| pedido | resultado |
|---|---|
| instalar sobre instalação existente → `exit 0`, contagem **igual** ao manifesto, `INTEGRIDADE=OK` | ✅ passo 3 — `exit 0`, **37 337 = 37 337**, `OK` |
| instalar sobre árvore **deliberadamente corrompida** → o ciclo se recupera **sozinho** | ✅ passo 4 — os 25 arquivos injetados sumiram **sem intervenção manual** |
| o ciclo limpo continua `exit 0` — **não regredir** o que já funcionava | ✅ passo 1 — `exit 0`, contagem exata |

### 1.4 A resposta sobre os `.pyc` órfãos — e por que ela é diferente da relatada

O briefing pediu o número do **ciclo limpo**, e ele é:

> **`0` arquivos, `0,00 MB`.** O uninstall não deixa nada.

Os **817 `.pyc`** existem — o passo 2 os mede: a árvore vai de **37 337 para 38 154** na primeira
abertura, e **para de crescer** na segunda (38 154 de novo). São bytecode que o Python grava em
`__pycache__` ao importar, exatamente como o desenho previa. **O que não acontece é eles sobrarem:**
o `[UninstallDelete] Type: filesandordirs; Name: "{app}\qgis"`, que a `#019` já tinha instalado,
remove a árvore inteira — inclusive o que o Inno não instalou.

Os `817` arquivos do `IMAN Terra.SOBRAS-GATE` que o arquiteto mediu vieram de um destino **sujo**
(instalação sobre instalação), não do ciclo limpo. **A hipótese de desenho estava certa quanto à
origem dos `.pyc`; o que ela não previa é que o uninstall já os levava junto.**

> ⚠ **Um número errado pela razão errada, corrigido antes de virar laudo.** A 1ª rodada desta
> medição encerrava o QGIS assim que **qualquer** janela aparecia — e a primeira que aparece é o
> **splash**, cujo título é `QGIS3`. O processo morria antes de importar os plugins, nenhum `.pyc`
> era escrito, e o ciclo devolvia *"a árvore não cresce"* e *"0 sobras"* — a conclusão certa pela
> razão errada. O instrumento passou a esperar a **janela principal** e a manter o produto aberto
> por 25 s depois disso. Foi essa correção que revelou o `+817` — e o achado da §7.

---

## 2. O aceite roda contra a árvore do produto

### 2.1 O que mudou

`tools/branding-acceptance/Invoke-Aceite.ps1` subia `C:\Program Files\QGIS <versão>`. Passou a subir

```
%LOCALAPPDATA%\Programs\IMAN Terra\qgis\bin\qgis-ltr.bat
```

**Sem QGIS de sistema em lugar nenhum do caminho** — e isso é **guarda**, não default: o orquestrador
**recusa** qualquer raiz sob `%ProgramFiles%`. Sem a recusa, um dia alguém passa `-Qgis` apontando
para lá "só para destravar", e o laço volta sem ninguém perceber.

**O `.bat`, não o `.exe`.** É o `qgis-ltr.bat` que chama o `o4w_env.bat`, que deriva `OSGEO4W_ROOT`
de `%~dp0`, **zera o `PATH` herdado** e monta `PROJ_DATA` / `GDAL_DATA` / `PYTHONHOME` /
`QT_PLUGIN_PATH`. É o **mesmo caminho que o launcher do produto usa**. Como a última linha do `.bat`
é `start /B`, o processo que interessa é localizado depois, pelo nome, e **conferido pelo caminho do
executável**.

### 2.2 A procedência é conferida de DENTRO do processo

Sem isso, "o aceite roda contra o produto" seria afirmação do orquestrador sobre si mesmo. O `E.1`
ganhou `procedencia_do_qgis`, e o baseline **aborta** se algo não bater. **Medido:**

| fonte | valor |
|---|---|
| `sys.executable` | `…\Programs\IMAN Terra\qgis\bin\python3.exe` |
| `QgsApplication.prefixPath` | `…\Programs\IMAN Terra\qgis\apps\qgis-ltr` |
| `QgsApplication.pkgDataPath` | `…\Programs\IMAN Terra\qgis\apps\qgis-ltr` |
| `OSGEO4W_ROOT` | `…\Programs\IMAN Terra\qgis` |
| `QGIS_PREFIX_PATH` · `PROJ_DATA` · `GDAL_DATA` | todos dentro da árvore do produto |
| **`caminhos_em_program_files`** | **`[]`** — nenhum, nem no ambiente nem no `sys.path` |
| `tudo_dentro` | **`True`** |

> **Armadilha que custou uma rodada:** o `o4w_env.bat` entrega `OSGEO4W_ROOT` em **forma 8.3**
> (`%~fsi`), então o executável do processo chega como `…\IMANTE~1\qgis\bin\qgis-ltr-bin.exe`.
> Comparar com o caminho longo por string acusaria "não é o do produto" **numa árvore correta**. A
> normalização é feita nos dois lados: `GetLongPathNameW` na sonda, `FileSystemObject.ShortPath` no
> orquestrador.

### 2.3 As 13 asserções, sem mudar de critério

**`12 PASS · 0 FAIL · 1 N/E`** — `evidencia/aceite.json` e `evidencia/aceite-segunda.json`.

```
A01=PASS A02=PASS A03=PASS A04=PASS A05=PASS A06=PASS A07=PASS
A08=PASS A09=PASS A10=PASS A11=PASS A12=PASS   M-D11=N/E
```

Nenhuma âncora se perdeu na troca de árvore — **zero asserções viraram `N/E`** por objeto não
encontrado, e o `discover.py` não precisou ser rodado. O único `N/E` continua sendo o `M-D11`, que já
era `N/E` na `#018` e continua **bloqueado em A1** por outro motivo (o `.exe` não é nosso).

### 2.4 Um aceite repontado que não sabe reprovar foi desligado, não repontado

`tools/Assert-AdulteracaoInversa.ps1`, com o código de produto revertido um defeito por vez:

```
  referencia: 14 assercoes, 0 FAIL

  D1  -> A01 voltou a FAIL, e so ela
  D8  -> A08 voltou a FAIL, e so ela

  2 de 2 reversoes acenderam a assercao certa, e so ela.
  GATE OK - nenhuma assercao morta, nenhum acoplamento.
```

Evidência: `evidencia/adulteracao-inversa.json`.

---

## 3. `A08` — de lista de strings para **procedência**

### 3.1 A ressalva que a própria crew declarou no `#018`, agora fechada

A metade do `A08` que caçava dado inventado lia `getattr(dash, 'RECENTS', [])`. Com as constantes
**removidas** pelo conserto do `D8`, o conjunto é vazio e **a metade passava por tautologia**.

Ela **servia** como guarda de regressão daquele conserto — o revert do `D8` a acendia — mas era
**cega a um dataset fabricado novo, com outras strings**: foi escrita contra a **instância** do
defeito, não contra a **classe**.

### 3.2 O critério novo, declarado

> Todo item exibido em "Projetos recentes" corresponde a uma **entrada real**: o caminho **existe em
> disco** **e** está na **lista de recentes do próprio QGIS**, com o mesmo título.

É o `C.2` — asserir **propriedade**, nunca representação — um nível acima. Dado fabricado com
**qualquer** string é pego.

A metade do **falso afordance** continua igual e continua no critério. A contagem de strings das
constantes continua **medida e relatada**, sob `HISTORICO_fora_do_criterio`, mas **não decide mais
nada**: observação histórica não é evidência.

### 3.3 O que tira a asserção da vacuidade

Num perfil recém-criado a lista de recentes do QGIS está **vazia**, a seção se mostra vazia, e
"nenhum item sem procedência" passaria por **lista vazia** — a mesma tautologia, um nível acima.

O orquestrador **semeia**, antes do arranque, um recente **real** na lista do próprio QGIS:
`app\demo\welcome.qgz`, o projeto demo que o produto instala. A semente entra no `QGIS3.ini` **antes**
de o QGIS subir, porque a home é construída **uma única vez**, no load do plugin — semear com o QGIS
aberto não apareceria. Daí a asserção pode exigir **presença**, e não só ausência de invenção.

### 3.4 Os dois lados, medidos

| | produto são | com o `D8` revertido |
|---|---|---|
| itens exibidos em "Projetos recentes" | **1** | **2** |
| itens **sem procedência** | **0** | **2** — `EPSG:31984` e `Vertices - Azimutes` |
| recente real semeado chegou à tela | **`True`** | **`False`** (deslocado pelo dado fabricado) |
| caminhos de projeto pintados fora do cartão | `[]` | `[]` |
| `A08` | **`PASS`** | **`FAIL`** |
| *(fora do critério)* strings das constantes na tela | 0 | 2 |

**Quem acendeu foi a procedência**, não a contagem de strings — a linha de baixo é a prova de que a
troca de critério não foi cosmética.

> **Um falso positivo medido e consertado na 1ª rodada desta versão:** a varredura larga por
> `.qgz`/`.qgs` no fim do texto casava com o subtítulo do cartão *"Abrir projeto / Arquivos .qgz /
> .qgs"*, que não é caminho nenhum. O padrão passou a exigir **raiz** (letra de unidade ou UNC).

---

## 4. O `IMAN.cdr` chegou no meio da fatia

**Não estava no briefing.** Durante a compilação, três arquivos de marca mudaram no disco: o
`splash-iman-terra.svg` virou um export do **CorelDRAW 2021**, e o `splash-iman-terra.png` e o
`profile-template/.../QGIS/splash.png` saltaram de 85 KB para 1,03 MB. É exatamente o
`IMAN.cdr` que o `STOP-AND-FLAG` da fatia `#002` esperava, com a regra *"chegando, prevalece"*.

**Ingerido por decisão do sponsor**, e não em silêncio — o que ele custou está em
`app/assets/README.md` e `docs/design-system.md`.

### 4.1 A paleta não mudou, e isso foi medido

| | |
|---|---|
| cores distintas na arte oficial | **18** |
| **token exato** de `brand.py` | **8** — `ink #0E1A14` · `mint #82D3A6` · `bg #EBEEE8` · `warm/earth #8A7A55` · `accent #2B8FD6` · `active-bg #E4F0E8` · `primary #1E7A4D` · `primary-deep #103D29` |
| as outras 10 | emblema (folha+globo), faixa e degradê de fundo — **nunca foram token de UI** |
| `COLOR_*` alterados · QSS alterado · ícones regerados | **nenhum · nenhum · nenhum** |

Os ícones e os dois `wizard-*.png` derivam do `iman-symbol.png`, que **não mudou**.

### 4.2 ⚠ O `QtSvg` não rasteriza este master — e apaga o crédito do QGIS

O export do Corel embute a fonte como **SVG font** (`<font>` + `<glyph>`) e quebra o texto em **164
elementos `<text>` de um caractere**. O `QSvgRenderer` **não implementa SVG fonts** — e **não falha**:
omite os glifos e devolve uma imagem que continua bonita. **Medido:**

| a arte diz | o `QtSvg` desenhou |
|---|---|
| `IMAN Terra` | `IMA Terra` |
| `VERSÃO INSTITUCIONAL` | `ERS O I STITUCIO AL` |
| `REGULARIZAÇÃO FUNDIÁRIA` | `REGULARI A   O U DIÁRIA` |
| **`POWERED BY QGIS`** | **`POWERED BY GIS`** |

A última linha é **`BL-1`**: rasterizar o SVG com QtSvg **apaga o crédito do QGIS** do splash de boot,
em silêncio. Por isso `rasterize-splash.py` passou a **reduzir** o PNG que o próprio Corel exportou
(`splash-iman-terra-master.png`, 3128×1504 → 1000×480, Pillow/LANCZOS). O SVG continua versionado
como proveniência e fonte legível da paleta.

Lado a lado: `evidencia/shots/splash-QTSVG-QUEBRADO-perde-o-Q-de-QGIS.png` contra
`evidencia/shots/splash-OFICIAL-1000x480.png`.

### 4.3 ⚠ Dois `STOP-AND-FLAG` que a arte trouxe — do sponsor, não da crew

1. O rodapé do splash diz **`v1.0 · LTR`**, e o produto está em **`0.3.0`**. É uma versão que **não
   existe**, cravada na arte — a mesma classe do `D9`, só que **fora do código**, onde o `A09` não
   alcança. A crew não edita a arte do sponsor.
2. A faixa diz **`VERSÃO INSTITUCIONAL · CAUCAIA LTR`** — nomeia um município específico dentro do
   splash de um produto distribuído para além dele. É decisão de escopo de produto.

---

## 5. O que esta fatia NÃO fez

- **Reescrever o `CHECKLIST.md` do `BL-7`** — fatia própria, e continua pré-requisito da VM.
- **Aplicar a exclusão de pacotes do `#020`** — aguarda o sponsor (o ECW é o item aberto).
- **`D11`** / patch de ícone e nome do `.exe` — continua bloqueado em A1.
- **Espelho de fonte** — aguarda decisão de hospedagem.
- **`BL-7` em VM limpa** — esta é bancada de dev, não substitui a VM.

---

## 6. ⚠ `Entrega 4` — o build canônico está BLOQUEADO NO MERGE

O `build.ps1` **recusa** compilar fora da `develop` (`exit 3`), e o `P0.6` proíbe mergear. A
`develop` de hoje (`ba58d14`) **não contém** as Entregas 1–3: um candidato a release tirado dela
sairia **sem o conserto do `DB-22`**, sem o aceite repontado e sem a arte oficial. Compilá-lo assim
seria produzir um artefato canônico e errado.

**O que existe:** o build **NÃO-CANÔNICO** desta branch, que é o que sustenta todos os números da §1.

```
Artefato   : Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe   (489,05 MB)
SHA-256    : EB9108C574C5DEDC03A102E19CB38AAFDC310236D7ED57B08C40ECECCED05350
Commit     : 3ecea9c   Branch: feat/021-reinstalar-sem-laco-e-aceite
Build canonico : NAO
```

**O que falta, e como fechar** — depois do merge desta fatia na `develop`:

```powershell
git checkout develop && git pull
.\installeruild.ps1                     # exige develop e arvore limpa
git add installer/dist/BUILD_INFO.txt      # D-IMAN-032: quem compila, commita
git commit -m "build(0.3.0): BUILD_INFO do canonico"
```

`D-IMAN-032` vale integral: **quem compila é quem commita o `BUILD_INFO`**, porque o Inno grava
`mtime` e o git não o preserva — o `SHA-256` não é função apenas do commit.

Vale também o cabeçalho do `New-ArvoreQgis.ps1`: **não extrair a árvore numa máquina que tenha a
mesma versão do QGIS instalada.** Hoje a bancada não tem — e a Entrega 2 é justamente o que garante
que ela **não precise voltar a ter**.

> Este build carregará, pela primeira vez, os avisos de licença corrigidos do `#020` **e** a arte
> oficial do `IMAN.cdr`.

---

## 7. ⚠ ACHADO COLATERAL, FORA DE ESCOPO, QUE PRECISA DE DONO

### O produto instalado escreve **QGIS** na própria barra de título — e o `A05` diz `PASS`

**Medido**, ao abrir o produto recém-instalado no ciclo da §1:

```
Projeto sem título — QGIS [iman-distro]
```

Não é `IMAN Terra`. **É o `D5` de volta, por uma porta que o aceite não cobre.**

### A causa, isolada

`iman_brand.compoe_titulo` troca o sufixo com uma âncora de **fim de string**:

```python
re.sub(r'QGIS(\s*)$', brand.PRODUCT_NAME + r'', titulo)
```

O QGIS acrescenta ` [<perfil>]` ao título **quando há mais de um perfil** na `--profiles-path`. Com o
sufixo, `QGIS` deixa de estar no fim, a substituição **não casa**, e o produto exibe o nome do QGIS
como se fosse o seu.

**Na bancada isso já acontece hoje**, e sem ninguém ter feito nada de estranho:

| raiz de perfis | perfis presentes | título |
|---|---|---|
| `%APPDATA%\InstitutoIMAN\IMAN Terra` (o **produto**) | `iman-distro`, `iman-distro.ANTES-DO-019` | `Projeto sem título — **QGIS** [iman-distro]` |
| `%LOCALAPPDATA%\InstitutoIMAN\_aceite017\perfil` (o **harness**) | `iman-distro` | `spike017-projeto-alfa — **IMAN Terra**` |

### O ponto cego, reproduzido de propósito

Criei um **segundo perfil vazio** na raiz do harness e rodei o aceite. **Duas vezes:**

```
placar: 12 PASS · 0 FAIL · 1 N/E
A05 = PASS
A05.titulo_apos_abrir_projeto = "spike017-projeto-alfa — QGIS [iman-distro]"
```

**O `A05` passa com a marca ausente do título.** O critério dele é *"o título contém o nome do projeto
e muda ao criar um novo"* — as duas coisas continuam verdadeiras com `QGIS` no lugar de `IMAN Terra`.
A asserção não está morta; ela **nunca cobriu a marca**, e o ambiente do harness (sempre um único
perfil) escondeu isso desde o `#017`. Evidência: `evidencia/aceite-com-dois-perfis.json`.

É a mesma classe do que esta fatia consertou no `A08`: **uma asserção escrita contra a instância do
defeito, num ambiente mais estreito que o do produto.**

### Por que NÃO foi consertado aqui

O briefing é explícito: *"as 13 asserções não mudam de critério"*, e conserto do `D5` não está nas
quatro entregas. Consertar direito custa **duas** mudanças acopladas — uma no produto (a âncora) e
uma no instrumento (o harness passar a rodar com mais de um perfil, e o `A05` a exigir a marca) — e a
segunda **muda o critério de uma das treze**. Isso é decisão do arquiteto, não carona nesta fatia.

**A forma do conserto, para quando houver briefing:** ancorar a substituição em `QGIS` seguido do
sufixo opcional de perfil, em vez de fim de string — e só declarar o `D5` fechado quando o `A05`
exigir a **marca** no título, rodando num perfil-raiz com mais de um perfil.

### Um segundo achado, menor, registrado por honestidade

Numa das rodadas com dois perfis o `A02` deu **`FAIL`** (`min=108`, `max=24`, `util=92` para `104`
necessários) — o piso/teto do campo de coordenadas ainda não tinha sido aplicado quando a sonda
mediu, 8 s após o arranque. **Não reproduziu:** a rodada seguinte, nas mesmas condições, deu `PASS`
com `min=122`, `max=236`. Fica como **flake de temporização sob máquina carregada**, com os dois
números no papel — não como causa do achado acima, que é independente e reproduziu duas vezes.

---

## 8. Como reproduzir

```powershell
# 1. o ciclo de reinstalacao (DB-22) - APAGA e reinstala o produto
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\test-reinstalacao.ps1 `
    -Instalador .\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe

# 2. o aceite, contra a arvore do produto (exige o produto INSTALADO)
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\branding-acceptance\Invoke-Aceite.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\branding-acceptance\Invoke-Aceite.ps1 -ReusarPerfil -Fase segunda

# 3. o gate: o aceite ainda sabe reprovar? (exige arvore git limpa)
powershell -NoProfile -ExecutionPolicy Bypass -Command `
    "& .\tools\Assert-AdulteracaoInversa.ps1 -Somente D1,D8"

# 4. os rasters do splash, a partir do master oficial do Corel
python app\assets\rasterize-splash.py
```
