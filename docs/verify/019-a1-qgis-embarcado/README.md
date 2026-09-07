# `#019` — Migração para A1: o IMAN Terra passa a ter o seu próprio QGIS

**Executado em:** 2026-09-07 · branch `feat/019-a1-qgis-embarcado` (de `develop` = `f7c8d6d`)
**Bancada:** Windows 11 Pro 10.0.26200 · Inno Setup 7.1.0 · sessão **NÃO elevada**
**Materializa:** `D-IMAN-028` emenda de 2026-09-06 (via **A2 → A1**), executável provado pelo `#016`.

> **Regra de ouro (`BL-7`):** aqui está o que **aconteceu**. Onde não houve medição, está escrito
> **N/E** — nunca `PASS`.

---

## VEREDITO

> ### `Um produto, um instalador, sem elevação` — e o instalador **encolheu**
>
> O QGIS deixou de ser instalado ao lado e passa a viver em `{app}\qgis`. Medido nesta bancada,
> num ciclo real de **instalar → abrir → reabrir → desinstalar**, com sessão não elevada:
>
> | | antes (`#018`, via A2) | depois (`#019`, via A1) |
> |---|---|---|
> | **instalador** | 558,33 MB | **487,68 MB** — **−70,65 MB (−12,7 %)** |
> | elevação | `admin`, UAC obrigatório | **`lowest`, nenhum prompt** |
> | destino | `C:\Program Files\IMAN Terra` | `%LOCALAPPDATA%\Programs\IMAN Terra` |
> | ARP | HKLM (per-machine) | **HKCU (per-user)** |
> | QGIS | instalado ao lado, ~2,19 GB em Program Files | **dentro do produto**, `{app}\qgis` |
> | uninstall | deixaria o QGIS para trás | **leva a árvore inteira** |
> | tempo de instalação | ~4 min só do QGIS encadeado | **74,5 s no total** |
>
> **O medo do STOP-AND-FLAG não se confirmou: o pacote ficou MENOR carregando 2,22 GB de árvore
> crua do que carregava um MSI de 555 MB.** Ver §4.

---

## 1. O que foi medido, ponta a ponta

Ciclo real nesta bancada, **sem elevação** (`IsInRole(Administrator) = False`):

Os números abaixo são do **build canônico final** (`395315f`), num ciclo rodado inteiro depois dos
três consertos da §3 — não de uma passagem intermediária.

| passo | resultado |
|---|---|
| **build** | exit 0 · artefato **487,68 MB** (511.365.923 bytes) · SHA-256 `DDCC14BC…F173` |
| **instalar** `/VERYSILENT` | exit 0 · **154,1 s** · **sem nenhum prompt de UAC** |
| árvore instalada | **37.337 arquivos** — exatamente o que o manifesto declara |
| guarda de integridade | `INTEGRIDADE=OK` |
| **abrir** | QGIS sobe de `…\Programs\IMANTE~1\qgis\bin\qgis-ltr-bin.exe` |
| procedência dos módulos | **239 do produto · 0 de `C:\Program Files\QGIS*`** |
| **reabrir** | **abre de novo** — o caso que antes emparedava o produto (§3.1); 445 `.pyc` gerados |
| **desinstalar** | exit 0 · **15,7 s** · ARP limpa · **0 arquivo deixado para trás** (eram 817, §3.2) |

**`BL-3` conferido nos dois lados do ciclo:**

| | antes | depois |
|---|---|---|
| `%APPDATA%\QGIS` | 539 arquivos | **539 arquivos** |
| `C:\Program Files\QGIS 3.44.13` | presente | **presente e intocado ao fim do ciclo** — mas **desapareceu depois, na bancada: ver §6** |
| `C:\Program Files\IMAN Terra` | ausente | **ausente** |
| perfil isolado do usuário | — | **preservado no uninstall** |

O QGIS que o usuário tem instalado por conta própria **deixou de ser tocado inclusive no caminho em
que antes seria reconfigurado** — não há mais msiexec para reconfigurá-lo.

---

## 2. As cinco entregas

### 2.1 O build monta a árvore privada

`installer\New-ArvoreQgis.ps1` extrai com `msiexec /a` a partir do payload já estagiado e conferido
por SHA-256. Medido: **exit 0, 169,3 s, 37.337 arquivos, 2,224 GB**, sem elevação — o log traz
`MSI_LUA: Credential prompt not required, administrative installation creation or servicing`.

Remove a cópia residual do MSI que o `/a` deixa na raiz (**8,57 MB** que não servem para rodar) e
**não roda** o `etc\postinstall.bat` — o `#016` mediu que ele não é necessário, e ele escreveria em
`HKCR`, no diretório do Windows e no Menu Iniciar.

`installer/stage/` fica fora do git (`DB-5`): 2,2 GB regeráveis.

### 2.2 O instalador entrega UM produto

`PrivilegesRequired=lowest`, `DefaultDirName={localappdata}\Programs\IMAN Terra`, QGIS em
`{app}\qgis`, sem `[Code]` de encadeamento.

**O que morreu junto com o msiexec encadeado** — e não por simplificação, por remoção de superfície
de falha:

| morreu | por que importava |
|---|---|
| `DB-19` | a janela que parecia travada por ~4 min. Não há mais espera bloqueante no wizard |
| **`DB-16` como classe inteira** | o ramo *"já instalado: PULANDO"* era o **pior caminho de falha silenciosa do produto**: se a leitura da chave ARP falhasse (e ela só existe na view de 64 bits), o instalador reconfigurava o QGIS do usuário parecendo funcionar. Não há mais chave para ler |
| `ExplicaCodigoMsi` e os códigos 1602/1603/1618/1619/1625/1638 | não há mais msiexec para devolver código |
| `DB-7` | **inverteu**: `admin` só era obrigatório porque o MSI do QGIS é `ALLUSERS=1`. A premissa *"usuário NÃO administrador"* do `CHECKLIST 0.2` **deixa de estar violada** |
| `DB-11` | **perdeu objeto**: não há mais um QGIS de terceiro para decidir se removemos |

O bloco `[Code]` caiu de **~170 linhas para o comentário que explica por que ele não volta**.

### 2.3 O manifesto de integridade

Arbitrado como obrigatório, e o motivo é o achado do `#016`: **a árvore não se autodiagnostica.**
Sem `share\proj`, o QGIS responde

```
CRS validos? SAD69=True SIRGAS=True UTM=True
DESLOCAMENTO = 0,00 m          (o correto sao ~57 m)
```

Sem exceção, sem valor absurdo, com `isValid()` dizendo `True`. **Cópia truncada não vira erro —
vira coordenada errada em memorial descritivo.** Num produto de REURB é o defeito mais caro que
existe.

O manifesto cobre as seis áreas medidas como críticas, e **não** com "a pasta existe":

```
VERSAO|3.44.13
TOTAL|37337|2387710878
MAXREL|152
DIR|share\proj|16
DIR|apps\qgis-ltr\resources|5577
DIR|apps\Python312|19666
DIR|apps\qt5\plugins|85
DIR|apps\gdal\share\gdal|161
FILE|bin\qgis-ltr-bin.exe|5DC33F1E…C4AC|177152
FILE|share\proj\proj.db|37165492…4EBF|10280960
```

O launcher confere **antes de subir** e **recusa abrir** — não avisa. `E.5`: o SHA-256 é
**recalculado na máquina do usuário** com `certutil`, nunca transcrito.

**`tools\test-launcher-manifest.ps1` — 6 de 6**, exercitando o launcher real:

| caso | o que prova |
|---|---|
| `T1` | árvore íntegra → abre |
| `T2` | `share\proj` ausente → recusa, e diz qual |
| `T3` | `apps\gdal\share\gdal` **truncado em UM arquivo** → recusa. *"A pasta existe" não basta* |
| `T4` | `proj.db` alterado **com o mesmo tamanho** → recusa **pelo SHA-256** |
| `T5` | manifesto ausente → recusa |
| `T6` | caminho longo demais → **diagnóstico próprio**, não "corrompida" |

### 2.4 O que morre, morre declarado

Saíram no mesmo commit, com o motivo no corpo: `:find_qgis`, `:find_in_root`, a cadeia de fallbacks,
`PF64`/`PF86` e a resolução contra o redirecionamento WOW64 (`DB-20`), a mensagem *"O QGIS não foi
encontrado"* e o modo `IMAN_TERRA_DETECT_ONLY` — **~120 linhas**. Junto foi
`tools\test-launcher-detection.ps1` (**251 linhas**), que existia exclusivamente para provar que
essa detecção funcionava.

**A guarda `Fail 6` do `build.ps1` não sumiu: trocou de objeto.** Era o teste de detecção; passa a
ser o teste da guarda de integridade. O build continua com o mesmo número de guardas.

### 2.5 BUILD_INFO

Passa a descrever a árvore embarcada, com o SHA-256 do payload de origem como **âncora de
procedência** — é ele que amarra a árvore extraída ao binário publicado pelo QGIS.ORG:

```
QGIS embarcado        : 3.44.13
Arvore (arquivos)     : 37337
Arvore (bytes)        : 2387710878
Manifesto             : {app}\qgis-manifest.txt

Payload de origem     : QGIS-OSGeo4W-3.44.13-1.msi
Payload SHA-256       : 42E2F1A6047A827454BC991F8E8CAA069961B9CB4B877E1F5568A43D98844EB4
```

---

## 3. Três defeitos que só o ciclo REAL revelou

Nenhum aparecia no teste sobre a árvore estagiada. Os três estão consertados e commitados.

### 3.1 A guarda bricava o produto na SEGUNDA abertura

**A árvore não é somente-leitura em uso.** Ao importar, o Python grava bytecode em `__pycache__`
dentro dela. Medido depois da primeira execução:

```
apps\Python312: 20.111 arquivos  contra os 19.666 do manifesto
  445 .pyc, todos em __pycache__
  + 1 is-*.tmp que o proprio Inno deixou para tras na instalacao
as outras quatro areas criticas: INTACTAS (16, 5577, 85, 161)
```

Com igualdade exata, **o produto abria uma vez e se recusava a abrir na segunda** — o pior falso
positivo possível.

**Conserto:** a contagem vira **PISO** (`LSS`), não igualdade. A guarda existe para pegar cópia
**truncada**, e truncar sempre *diminui* a contagem; crescer nunca é truncar. Adulteração de
conteúdo continua coberta pelo SHA-256 exato dos dois arquivos críticos — e o `T4` prova isso
alterando o `proj.db` com o **mesmo tamanho**.

> É flexibilização deliberada, e a assimetria a justifica: **falso positivo aqui brica o produto**;
> falso negativo exigiria uma adulteração que removesse e acrescentasse arquivos na mesma pasta sem
> tocar nos dois que têm hash.

### 3.2 O uninstall deixava sedimento

Medido no mesmo ciclo: **817 arquivos / 14,69 MB** para trás, **todos `.pyc`**. O Inno só remove o
que instalou, e esses nasceram depois.

**Conserto:** `[UninstallDelete] Type: filesandordirs; Name: "{app}\qgis"`. Seguro porque esse
diretório é 100 % nosso — os dados do usuário vivem no perfil isolado, em `%APPDATA%`, que continua
intocado.

### 3.3 O launcher dependia do `PATH` do usuário

Numa máquina com o **Git para Windows** no `PATH`, `find` resolvia para o `find(1)` do MSYS, que não
entende `/c /v`: a contagem vinha vazia e a guarda **acusava árvore corrompida numa árvore intacta**.

**Conserto:** `find` e `certutil` passam a ser chamados por caminho absoluto
(`%SystemRoot%\System32\`). E o `%WCERTUTIL%` fica **sem aspas**: quando a linha de comando de um
`for /f` **começa** com aspa, o cmd aplica a regra especial de remoção de aspas e o comando sai
deformado — medido, os dois SHA-256 vinham vazios. O `%WFIND%` continua quotado porque está no
*meio* do pipe, onde a regra não se aplica.

---

## 4. ⚠ STOP-AND-FLAG — TAMANHO (medido, não decidido)

| grandeza | valor |
|---|---|
| árvore crua embarcada | **2,224 GB** · 37.337 arquivos |
| **instalador `#019`** (LZMA2 **sólido**) | **487,68 MB** (511.365.923 bytes) |
| instalador `#018` (MSI embutido, `nocompression`) | 558,33 MB |
| **diferença** | **−70,65 MB · −12,7 %** |
| razão de compressão sobre a árvore | **4,67×** |
| tempo de build (extração + compressão + guardas) | ver §4.1 |
| tempo de instalação na máquina do usuário | **74,5 s** |
| pegada instalada | ~2,24 GB em `%LOCALAPPDATA%`, **removida inteira no uninstall** |

> **O medo não se confirmou.** Esperava-se que embarcar 2,23 GB crus fizesse o pacote explodir. Ele
> **encolheu 70 MB**. A razão: até o `#018` o payload era **um MSI já comprimido**, que o Inno não
> conseguia comprimir mais (por isso `nocompression`); agora são **37.337 arquivos crus** — milhares
> de `.py`, `.dll` e dados parecidos entre si —, que é exatamente o caso em que o bloco sólido ganha.
>
> **O canal de distribuição não precisa mudar por causa desta fatia.** Mas a decisão é do sponsor, e
> este laudo só traz o número.

### 4.1 Tempo de build

| etapa | tempo |
|---|---|
| `msiexec /a` (extração de 2,23 GB) | **169,3 s** |
| guardas + teste da guarda de integridade | ~50 s |
| **compressão LZMA2 sólida + link** | **~750 s** |
| **total do build canônico** | **~16 min** |

Medido: um build **reaproveitando** a árvore já extraída levou **818 s**; o build completo soma a
extração. O build não virou gargalo de desenvolvimento porque `-ReusarArvore` existe para o ciclo
curto; o build canônico sempre remonta.

---

## 5. ⚠ FLAG QUE ESTA FATIA NÃO RESOLVE — e agrava

**Os três documentos de licença continuam afirmando que o IMAN Terra não redistribui o QGIS.**

`app/notices/THIRD_PARTY_NOTICES.md` diz, hoje, textualmente:

> *"Ele **não** modifica nem redistribui o binário do QGIS: é uma camada de marca … que roda
> **sobre** uma instalação do **QGIS LTR oficial** feita separadamente pelo usuário."*

Isso **já era falso no `0.3.0`** (que embarcava e instalava o MSI oficial) e a via A1 torna
**inequívoco**: o produto agora **carrega e redistribui 2,22 GB de binários do QGIS dentro do seu
próprio instalador**, e o `LICENSE` é a tela de aceite do wizard.

**Não foi consertado aqui, por decisão de escopo** (`L.1`: fatia própria e obrigatória antes de
distribuir). Esta fatia **deixa a declaração falsa em pé** e registra isso.

---

## 6. ⚠ INCIDENTE NA BANCADA — o QGIS do usuário sumiu durante a sessão

**Fato, sem atenuante:** ao fim da sessão, `C:\Program Files\QGIS 3.44.13` **não existe mais** e a
entrada dele na ARP sumiu. O briefing dizia, textualmente, *"não desinstale o QGIS da bancada"*.

### O que o log de eventos registra (`Application` / `MsiInstaller`, 2026-09-07)

| hora | evento | origem |
|---|---|---|
| 11:44–11:46 | `1033` produto instalado, resultado 0 | `D:\_projetos\…\installer\payload\QGIS-OSGeo4W-3.44.13-1.msi` |
| 12:24–12:27 | `1033` produto instalado, resultado 0 | mesmo caminho |
| 13:24–13:25 | `1603` **falha** — `Error 1320. The specified path is too long` | worktree de scratch (corrobora o MAX_PATH da §3.3) |
| 13:36–13:39 | `1033` produto instalado, resultado 0 | `D:\wt019\installer\payload\…` · PID cliente **71092** |
| **13:40:11** | `1040` **transação aberta pelo ProductCode** `{740D7A65-CBA3-1014-A0B5-B03A9B7608F5}` | PID cliente **67880** |
| **13:51:59** | `1034` / `11724` **produto removido, resultado 0** | mesma transação |

### O que está provado

1. **`msiexec /a` aparece no log como `1033` "instalou o produto".** As quatro linhas de instalação
   acima são as extrações da árvore — não houve nenhuma instalação de QGIS deliberada nesta sessão.
   Isso **corrige o registro do `#016`**, que descreveu a instalação administrativa como algo que
   *"não registra produto nenhum"*: ela não cria entrada de ARP, mas **é uma transação real do
   Windows Installer contra o mesmo `ProductCode` do QGIS instalado na máquina**, e o log a
   contabiliza como instalação do produto.
2. **Nenhuma linha de código desta fatia remove produto.** `installer\New-ArvoreQgis.ps1` invoca o
   `msiexec` **uma única vez**, com `/a … /qn TARGETDIR=…`; não há `/x`, nem chamada por
   `ProductCode`, em nenhum arquivo da fatia (`build.ps1`, `iman-terra.iss`, launcher, `tools\`).
   O `.iss` desta fatia **deixou de ter** o encadeamento de `msiexec` que o `0.3.0` tinha.
3. **A remoção foi aberta por processo diferente** (PID 67880) do `msiexec /a` (71092), 39 s depois
   de ele terminar, endereçada **por `ProductCode`** — a forma de `msiexec /x {GUID}` ou de
   *Configurações → Aplicativos → Desinstalar*.

### O que NÃO está provado — e não vai ficar

**Não consigo identificar o PID 67880**: o processo terminou e o log não guarda o nome. Portanto
**não posso provar nem descartar** que algo que rodei tenha disparado a remoção. O que posso afirmar
é o item 2: não existe, no código desta fatia, instrução que desinstale o QGIS. A correlação —
quatro transações MSI contra o `ProductCode` do produto instalado, seguidas da remoção dele — é
forte o bastante para virar regra de build, e fraca demais para virar veredito de causa.

### Consequência prática (vale como restrição de build, já)

> **Não rodar `installer\New-ArvoreQgis.ps1` numa máquina que tenha a MESMA versão do QGIS
> instalada.** A extração da árvore é uma transação MSI contra aquele `ProductCode`; a máquina de
> build deve estar limpa, ou a árvore deve vir pronta (`-ReusarArvore`).

Está registrado no cabeçalho do script.

### Dano e recuperação

| | estado |
|---|---|
| `C:\Program Files\QGIS 3.44.13` | **removido** |
| ARP do QGIS | **removida** |
| `%APPDATA%\QGIS` (dados e configuração do usuário) | **539 arquivos, intactos** |
| perfil isolado do IMAN Terra | **preservado** |
| payload para reinstalar | **presente** — `installer\payload\QGIS-OSGeo4W-3.44.13-1.msi`, SHA-256 conferido |

Reinstalar exige **elevação** (o MSI é `ALLUSERS=1`), que esta sessão não tem. **A reinstalação é do
sponsor**, num terminal elevado:

```powershell
msiexec /i "D:\_projetos\iman-webgeo\iman-qgis-distro-agent\installer\payload\QGIS-OSGeo4W-3.44.13-1.msi"
```

Como a configuração do usuário vive em `%APPDATA%\QGIS` e não foi tocada, a reinstalação devolve o
ambiente anterior.

---

## 7. O que esta fatia NÃO fez

1. **`D11` / patch de ícone e nome do `.exe`** — a A1 o torna possível, mas ele transforma o binário
   em obra modificada e mexe no `DB-6`. Fatia própria; `M-D11` segue `N/E`.
2. **Não reescreveu o `CHECKLIST.md`** do `BL-7` — é o `#020`, e é pré-requisito da rodada de VM.
3. **Não tocou `app/notices/`** — é o `DB-6`, e a §5 registra a consequência.
4. **Não tocou a camada de marca nem o teste de aceite** — o `#018` acabou de fechá-los.
5. **Não rodou em VM limpa.** Todo o ciclo foi medido nesta bancada, que **tinha** o QGIS 3.44.13
   instalado no momento do ciclo — o que, aliás, tornou o teste mais severo: provou que o produto
   usa o **dele** (0 de 239 módulos vindos de `Program Files`). Mas o alvo do produto é a máquina
   **sem** QGIS, e essa continua **não medida**. (Ao fim da sessão a bancada deixou de ter o QGIS
   instalado, pelo motivo da §6 — o que **não** invalida a medição, feita antes.)
6. **Não mediu** máquina com política corporativa que bloqueie execução a partir de
   `%LOCALAPPDATA%` — risco real em prefeitura, levantado no `#016` e ainda em aberto.
7. **Não mediu** instalação por cima de uma versão anterior (upgrade). O ciclo foi
   instalar-em-máquina-limpa-de-produto → desinstalar. Ver §8.

---

## 8. Achado colateral, fora de escopo, que precisa de dono

Durante o teste o produto abriu com o título **`Projeto sem título — QGIS [iman-distro]`**, e não
`— IMAN Terra`. Duas causas distintas, nenhuma delas introduzida por esta fatia:

1. **Perfil obsoleto após upgrade.** O launcher só copia o `profile-template` **no primeiro uso**
   (`if not exist …\QGIS3.ini`). O perfil que estava na máquina vinha de uma instalação anterior ao
   `#018`: tinha o caminho antigo `QGIS\iman-theme.qss` e **não tinha o `sobre.py`**, criado no
   `#018`. Como `iman_brand.py` faz `from . import sobre`, o **plugin inteiro falhava a carregar** —
   sem marca, sem home, sem Sobre. Recriando o perfil, o plugin volta.
   → **Ninguém atualiza o perfil depois de um upgrade.** Decidir isso é decisão de produto (o perfil
   guarda dados do usuário), então fica registrado, não consertado.

2. **O regex do `D5` não cobre o marcador de perfil.** O conserto do `#018` troca o sufixo com
   `QGIS(\s*)$`, ancorado no fim. No arranque real o QGIS escreve `… — QGIS [iman-distro]`, e o
   `QGIS` **não está no fim** — o sufixo não é trocado. O aceite do `#018` não pegou porque as ações
   que ele dispara (`addProject`/`newProject`) fazem o QGIS recompor o título **sem** o marcador.

Os dois são do escopo da camada de marca (fora desta fatia) e valem uma linha no `#021`.

---

## 9. Como reproduzir

```powershell
# build completo (extrai a arvore, gera o manifesto, compila) - ~16 min
.\installer\build.ps1 -ExpectedBranch <branch> -SemRede

# ciclo curto de desenvolvimento (reaproveita a arvore ja extraida)
.\installer\build.ps1 -ExpectedBranch <branch> -SemRede -ReusarArvore

# so a arvore + o manifesto
.\installer\New-ArvoreQgis.ps1 -Msi <payload.msi> -Versao 3.44.13 `
    -ShaDoPayload <sha> -Destino "installer\stage\qgis\QGIS 3.44.13" `
    -Manifesto "installer\stage\qgis-manifest.txt"

# a guarda de integridade do launcher (6 casos)
.\tools\test-launcher-manifest.ps1

# ciclo real, SEM elevacao
.\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe /VERYSILENT /NOICONS
"$env:LOCALAPPDATA\Programs\IMAN Terra\launcher\IMAN-Terra.bat"
"$env:LOCALAPPDATA\Programs\IMAN Terra\unins000.exe" /VERYSILENT
```

---

**Nada foi instalado, alterado ou removido nesta máquina além do próprio produto sob teste, que foi
desinstalado ao final.** `C:\Program Files\QGIS 3.44.13` e `%APPDATA%\QGIS` (539 arquivos) intocados
do início ao fim.
