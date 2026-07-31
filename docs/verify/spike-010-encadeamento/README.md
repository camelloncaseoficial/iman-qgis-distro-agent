# SPIKE #010 — encadear o instalador oficial do QGIS dentro do IMAN Terra (via A2a)

**Decisão que materializa:** `D-IMAN-028` — via **A2** (instalador encadeado), payload **A2a**
(embarcado, offline, versão travada). Arbitrada pelo sponsor em 2026-07-30.
**Executado em:** 2026-07-31 · branch `spike/010-encadeamento` (de `origin/develop` = `1566b85`).
**Tipo:** spike de de-risk timeboxed. **Não é fatia de produto.**

> **Regra de ouro (BL-7):** o que está escrito aqui é o que **aconteceu**, não o que deveria
> acontecer. Onde não houve medição, está escrito **NÃO MEDIDO** — não `PASS`.

---

## VEREDITO

> ### `A2a VIÁVEL COM RESSALVA`
>
> **O contrato de encadeamento existe, é simples e é mais favorável do que se supunha:** o
> artefato oficial é um **MSI WiX**, instala com `/qn`, aceita destino fixo por `INSTALLDIR`,
> **não pede elevação própria** (herda a nossa — uma única elevação) e **não encosta em nenhuma
> outra versão do QGIS nem em `%APPDATA%\QGIS`**.
>
> **Ressalva bloqueante (achado novo, não previsto no briefing):** como o MSI **coexiste** em vez
> de atualizar, M2b e M3 produzem duas instalações lado a lado — e nessa situação o
> **launcher do IMAN Terra abre a versão ERRADA** (a mais antiga). Medido. Ver §4.
>
> **Cobertura honesta: 2 dos 5 casos medidos.** M1, M2a-sob-elevação e M4 **não foram medidos** —
> esta bancada não tem elevação disponível nem VM, e a única máquina com QGIS é a do sponsor,
> que o protocolo proíbe alterar. Ver §7 (o que travou).

---

## 1. Fase 0 — o contrato do instalador oficial do QGIS

### 1.1 Qual artefato, e por quê

| | |
|---|---|
| **Artefato** | `QGIS-OSGeo4W-3.44.9-1.msi` — **MSI**, não `.exe`, não OSGeo4W network installer |
| **URL** | `https://download.qgis.org/downloads/QGIS-OSGeo4W-3.44.9-1.msi` (espelhado em `https://qgis.org/downloads/…`) |
| **Disponível em 2026-07-31?** | **SIM** — HTTP 200. A baseline `3.44.9` do `.iss:16` **continua publicada** |
| **Tamanho** | **541,14 MB** (567.431.168 bytes) |
| **SHA-256** | `711D6DF99F450522A1E22755FCBFED65D5190C1E4C241793BC2F80FF1A2C24BA` |
| **Tempo de download** | 42,9 s nesta bancada |
| **Construído com** | Windows Installer XML Toolset (**WiX**) **3.11.1.2318** |
| **Plataforma / idioma** | `x64;1033` (só x64, só inglês) |

**Por que o MSI e não outra coisa:** é o que a própria máquina do dev consumiu. O registro de
desinstalação do QGIS instalado aqui é `MsiExec.exe /X{8397FA4A-…}` — ou seja, a instalação
existente **veio deste mesmo MSI**. O MSI baixado hoje tem `ProductCode`, `UpgradeCode` e
`PackageCode` **idênticos** aos do pacote em cache (`C:\Windows\Installer\519890c.msi`),
confirmando que o artefato oficial é estável e reproduzível.

O OSGeo4W network installer foi descartado sem teste: depende de download em tempo de instalação,
o que **A2a existe justamente para evitar** (rede de prefeitura restrita).

### 1.2 Identidade do pacote (é isto que governa M2a/M2b/M3)

| Campo | QGIS **3.44.9** | QGIS **3.44.12** |
|---|---|---|
| `ProductName` | `QGIS 3.44.9 'Solothurn'` | `QGIS 3.44.12 'Solothurn'` |
| `ProductVersion` | `3.44.9` | `3.44.12` |
| **`ProductCode`** | `{8397FA4A-7089-1014-9008-9EE76A62B1BC}` | `{749E156D-B51C-1014-8549-FB4468777DEC}` |
| **`UpgradeCode`** | `{83985B08-7089-1014-9008-9EE76A62B1BC}` | `{749E75EA-B51C-1014-8549-FB4468777DEC}` |
| `PackageCode` | `{01DB9858-A6F2-455A-B1BC-2A216277571A}` | `{E21D4841-AB82-415A-B3B6-366640190B63}` |
| `INSTALLDIR` padrão | `[ProgramFiles64Folder]\QGIS 3.44.9` | `[ProgramFiles64Folder]\QGIS 3.44.12` |

> **O achado central do spike:** **até o `UpgradeCode` muda entre patches da mesma minor.** O
> `UpgradeCode` existe no MSI precisamente para ligar versões de um mesmo produto e permitir
> upgrade. O QGIS.org gera um novo a cada build. **Não existe família de produto** — para o
> Windows Installer, `3.44.9` e `3.44.12` são dois programas sem nenhuma relação.

### 1.3 O que o MSI **não** tem (verificado no `_Tables`, 30 tabelas)

| Tabela / ação | Presente? | Consequência |
|---|---|---|
| **`Upgrade`** | **AUSENTE** | não há regra de upgrade **nenhuma** |
| `FindRelatedProducts` | **AUSENTE** da sequência | **nunca procura** outra versão instalada |
| `RemoveExistingProducts` | **AUSENTE** da sequência | **nunca remove** nada de ninguém |
| `LaunchCondition` | **AUSENTE** | não recusa instalação por versão pré-existente |
| `Registry` | **AUSENTE** | o MSI não escreve registro além do ARP padrão |
| `Shortcut` | **AUSENTE** | atalhos são feitos pelo `postinstall.bat` |
| `ServiceInstall` | **AUSENTE** | não instala serviço |

**Sequência de execução completa** (`InstallExecuteSequence`) — 21 ações, sem nenhuma de upgrade
ou de reboot:

```
 700 ValidateProductID     1600 ProcessComponents     4000 InstallFiles
 800 CostInitialize        1800 UnpublishFeatures     4001 Setpostinstall
 900 FileCost              3500 RemoveFiles           4002 postinstall   [(NOT Installed) AND (NOT REMOVE)]
1000 CostFinalize          3600 RemoveFolders         6000 RegisterUser
1400 InstallValidate       3700 CreateFolders         6100 RegisterProduct
1500 InstallInitialize                                6300 PublishFeatures
1501 Setpreremove                                     6400 PublishProduct
1502 preremove  [(NOT UPGRADINGPRODUCTCODE) AND (REMOVE="ALL")]
                                                      6600 InstallFinalize
```

Não há `ScheduleReboot` nem `ForceReboot`. **O pacote não pede reboot por construção**
(o `3010` só poderia vir de arquivo em uso, via Restart Manager — não medido).

### 1.4 Flag silenciosa, destino e elevação

| Item | Contrato **medido** |
|---|---|
| **Silêncio** | **`/qn`** (semântica msiexec). **`/S` é sintaxe NSIS e não se aplica** — testá-la só produz o diálogo de uso do msiexec |
| **Destino** | propriedade **`INSTALLDIR`** (o pacote declara `WIXUI_INSTALLDIR=INSTALLDIR`). Passar `INSTALLDIR="C:\…"` na linha de comando. **Aspas obrigatórias**: caminho com espaço sem aspas é quebrado em dois argumentos e o msiexec trava |
| **Escopo** | **`ALLUSERS=1`** fixo no pacote → instalação **per-machine**, **exige elevação**, sempre |
| **Elevação** | **UMA só, herdada.** O log traz literalmente `MSI_LUA: Elevation prompt disabled for silent installs` — sob `/qn` o msiexec **não exibe UAC**: ou já está elevado, ou falha. Logo, se o nosso setup rodar elevado, **não há segundo prompt** |
| **Sem reboot** | `/norestart` recomendado por higiene (o pacote não agenda reboot) |
| **Log** | `/L*v "<arquivo>"` funciona e é onde o diagnóstico real aparece |

### 1.5 Exit codes — o que foi **MEDIDO** e o que **NÃO** foi

**Medidos nesta bancada (sem elevação, sem alterar a instalação existente):**

| Cenário executado | Exit code | Observação |
|---|---|---|
| `/a <msi> /qn TARGETDIR=<dir>` (instalação administrativa: extrai, **não instala**) | **`0`** | 142,3 s · 35.697 arquivos · **2,13 GB** extraídos |
| `/i <msi> /qn` **sem elevação**, com `3.44.9` já instalado | **`1625`** | `ERROR_INSTALL_PACKAGE_REJECTED`. Log: `MSI_LUA: Elevation prompt disabled for silent installs` |
| `/i <msi-inexistente> /qn` | **`1619`** | `ERROR_INSTALL_PACKAGE_OPEN_FAILED` |

**NÃO medidos** — exigem elevação e/ou máquina em estado específico. Listados como **contrato a
confirmar**, não como fato:

| Cenário | Código esperado (msiexec padrão) | Status |
|---|---|---|
| instalação bem-sucedida | `0` | **NÃO MEDIDO** |
| sucesso exigindo reboot | `3010` | **NÃO MEDIDO** |
| falha genérica no meio | `1603` | **NÃO MEDIDO** |
| outra instalação em curso | `1618` | **NÃO MEDIDO** |
| "outra versão deste produto já está instalada" | `1638` | **NÃO MEDIDO** — e provavelmente **inalcançável**, ver §3 |
| usuário cancelou | `1602` | **NÃO MEDIDO** |

> **Consequência direta:** o `1625` medido **não é** "já instalado" — é elevação negada. O
> encadeamento não pode tratar `1625` como caso benigno.

---

## 2. Fase 1 — a matriz

| # | Estado da máquina | O que foi **medido** | Veredito |
|---|---|---|---|
| **M1** | sem QGIS | — | **NÃO MEDIDO** (sem elevação/VM) |
| **M2a** | QGIS exatamente `3.44.9` | o MSI **NÃO pula**: entra em **reconfiguração** do produto existente. Log: *"O Windows Installer reconfigurou o produto… Status… 1625"*. Sob `/qn` sem elevação → `1625` | **MEDIDO PARCIAL** — comportamento identificado, exit code sob elevação NÃO medido |
| **M2b** | QGIS `3.44.12` | `ProductCode` **e** `UpgradeCode` diferentes + `Upgrade` table ausente → **coexistência lado a lado**, em `C:\Program Files\QGIS 3.44.12` e `…\QGIS 3.44.9`, com dois registros ARP. O instalador oficial **não faz nada** a respeito do outro | **MEDIDO** (por metadado do pacote) |
| **M3** | QGIS `3.34.x` / `3.40.x` | **mecanismo idêntico ao M2b** — coexistência. Nada é atualizado, nada é removido, nada é recusado | **MEDIDO** (por metadado do pacote) |
| **M4** | instalação falha no meio | — | **NÃO MEDIDO** (exige elevação para chegar a falhar de verdade) |

### 2.1 O que o instalador oficial faz sozinho ao encontrar outra versão

**Resposta medida: nada. Ele não olha.**

Não é "coexiste por decisão de design de convivência" — é que **não existe código de detecção no
pacote**. Sem `Upgrade` table, sem `FindRelatedProducts`, sem `RemoveExistingProducts` e sem
`LaunchCondition`, o Windows Installer não tem como saber que existe outro QGIS. Cada versão é um
produto autônomo, com `ProductCode` próprio, diretório próprio e entrada ARP própria.

**A boa notícia para o BL-3 e para o risco central do spike:** a instalação compartilhada de
terceiro **não é tocada, não é atualizada e não é removida** — nem em M2b nem em M3. O cenário
destrutivo que motivou o STOP-AND-FLAG **não ocorre por conta do instalador oficial.** Se algum dia
ocorrer, será porque **nós** o programamos.

---

## 3. M2a — atenção: "pular" é trabalho NOSSO, não do MSI

O briefing descreve o esperado de M2a como *"pula a instalação e segue"*. **O MSI não faz isso.**
Com o mesmo `ProductCode` já instalado, `msiexec /i` entra em **modo de manutenção/reconfiguração**
do produto existente — o log é explícito (*"reconfigurou o produto"*). Sob `/qn` e elevado, isso
tende a um recusteio/reparo, não a um no-op, e **não retorna `1638`** (o `1638` pressupõe
`UpgradeCode` compartilhado, que aqui não existe).

Portanto **o "pulo" tem de ser implementado por nós**, antes de chamar o msiexec — testando a
presença do `ProductCode` exato do payload. No protótipo (§6) isso é a função `PrecisaInstalarQgis`.

---

## 4. ⚠ RESSALVA BLOQUEANTE — com coexistência, o launcher abre o QGIS ERRADO

Este achado **não estava previsto no briefing** e é consequência direta de §2: se M2b/M3 produzem
coexistência, alguém precisa decidir **qual** QGIS o IMAN Terra abre. Quem decide hoje é a rotina
`:find_in_root` do `app/launcher/IMAN-Terra.bat`, que aceita **o primeiro** que o `for /d` enumerar.

Medição feita com diretórios simulados (`QGIS 3.34.15`, `QGIS 3.40.3`, `QGIS 3.44.9`,
`QGIS 3.44.12`), rodando a rotina **real** copiada do launcher:

```
ORDEM ENUMERADA POR "for /d":
   QGIS 3.34.15
   QGIS 3.40.3
   QGIS 3.44.12
   QGIS 3.44.9

ESCOLHIDO PELO LAUNCHER: ...\QGIS 3.34.15\bin\qgis-ltr-bin.exe
```

**O launcher escolheu a versão mais ANTIGA.** A enumeração é alfabética, e:

- **M3:** `"QGIS 3.34.15"` < `"QGIS 3.44.9"` → abre o **3.34.15** do usuário, ignorando o 3.44.9 que
  acabamos de instalar e validar.
- **M2b:** `"QGIS 3.44.12"` < `"QGIS 3.44.9"` — porque a comparação é de **texto**, e `'1' < '9'`.
  Abre o **3.44.12**, não o nosso payload.

**Efeito prático:** nas duas situações que o briefing aponta como as mais prováveis no campo, o
A2a instalaria 541 MB de QGIS e **não os usaria**. O produto entregaria a camada de marca rodando
sobre um runtime que nunca foi testado — que é exatamente o que a baseline travada existe para
evitar. Some-se o desperdício de **~2,2 GB** de disco por instalação ignorada.

**Isto é defeito da nossa camada, não do MSI, e é corrigível** (o launcher passa a preferir o
caminho exato do payload; a detecção permissiva vira fallback). **Não corrigido nesta fatia** — a
correção depende de M2b/M3 serem arbitrados, e o briefing proíbe arbitrar.

---

## 5. Fase 2 — asserções S1–S7

| # | Asserção | Resultado | Como foi medido |
|---|---|---|---|
| **S1** | 5 casos medidos, M2b/M3 relatados e não arbitrados | **PARCIAL — 2 de 5** | M2b e M3 **medidos e não arbitrados** (§2, §8). M2a parcial. M1 e M4 **NÃO MEDIDOS** |
| **S2** | contrato documentado (flag, destino, exit codes) | **ATENDIDA para flag/destino/elevação; PARCIAL para exit codes** | §1.4 e §1.5 — 3 códigos medidos, 6 declarados como não medidos |
| **S3** | uma única elevação no percurso | **EVIDÊNCIA FORTE, NÃO CONFIRMADA EM RUN** | `MSI_LUA: Elevation prompt disabled for silent installs` no log: sob `/qn` o msiexec **não pode** prompt. Contagem real de UAC **NÃO MEDIDA** |
| **S4** | perfil `iman-distro` carrega (3 sinais do passo 6) | **NÃO MEDIDO** | exige instalar e abrir o QGIS |
| **S5** | `%APPDATA%\QGIS` intocado (BL-3) | **EVIDÊNCIA ESTÁTICA FORTE, RUNTIME NÃO MEDIDO** | ver §5.1 |
| **S6** | local de instalação sob elevação (`{autopf}`) | **NÃO MEDIDO** | exige rodar o setup elevado |
| **S7** | tamanho e tempo | **MEDIDA** | ver §5.2 |

### 5.1 S5 — o que dá para afirmar hoje, e o que não dá

**Evidência estática (medida, e vale bastante):**

- **`Directory` table: 3.050 entradas, todas enraizadas em `ProgramFiles64Folder` / `TARGETDIR`.**
  **Não existe** `AppDataFolder`, `LocalAppDataFolder`, `PersonalFolder` nem qualquer raiz de perfil
  roaming no pacote. As únicas entradas de usuário são `DesktopFolder` /
  `ApplicationDesktopFolder` (atalho).
- **Tabela `Registry` ausente** → o MSI não escreve `HKCU`.
- **Os dois únicos scripts executáveis do pacote** (`etc\postinstall.bat`, `etc\preremove.bat`,
  extraídos via `/a`) **não contêm nenhuma referência** a `%APPDATA%`, `%USERPROFILE%`,
  `%LOCALAPPDATA%`, `profiles`, `QGIS3.ini` ou `HKCU` — verificado por busca literal. Eles mexem em
  `%OSGEO4W_ROOT%` e nas pastas de atalho passadas como argumento.

**Conclusão parcial:** pelo pacote, **o instalador oficial do QGIS não tem por onde escrever em
`%APPDATA%\QGIS`**. A preocupação do briefing ("quem escreve não é só o nosso código") é
legítima e foi investigada — e o pacote **não** a confirma.

**O que continua NÃO MEDIDO:** o par snapshot antes/depois com `tools/bl7/snapshot-user-profile.ps1`
+ `assert-bl3.ps1` em torno de uma instalação real. **Sem isso o S5 não é PASS.**

> **Preparo do baseline, para a rodada que vier:** o alerta do briefing é real e continua valendo.
> Nesta bancada, `%APPDATA%\QGIS\QGIS3\profiles` tem **12 arquivos** (perfil `default`) — baseline
> seria válido aqui. **Numa VM limpa seria 0**, e é exatamente aí que a rodada de 30/07 queimou:
> abrir o QGIS uma vez, mudar uma configuração, salvar um projeto e fechar **antes** do snapshot
> "antes". Se vier `TotalArquivos: 0`, **parar e refazer**.

### 5.2 S7 — tamanho e tempo (medidos)

Protótipo descartável compilado com o payload embarcado (Inno Setup 6.7.3, ISCC):

| Variante | `Compression` | payload | **tempo de compilação** | **`.exe` final** |
|---|---|---|---|---|
| **A** | `lzma2` + `SolidCompression=yes` | recomprimido | **90,9 s** | **534,44 MB** |
| **B** | `lzma2`, sólido off | `nocompression` | **11,1 s** | **544,13 MB** |

Outras grandezas medidas:

| Grandeza | Valor |
|---|---|
| Payload MSI `3.44.9` | **541,14 MB** |
| Camada de marca `app/` | **1,13 MB** |
| Pegada extraída do MSI | **2,13 GB** · 35.697 arquivos |
| QGIS instalado (ARP `EstimatedSize`) | **≈ 2,19 GB** |
| Download do payload | 42,9 s (3.44.9) · 117 s (3.44.12) |

**Observação útil:** recomprimir o MSI custa **+80 s de build** e economiza **~9,7 MB (1,8 %)**.
Ambas as variantes são baratas — o build **não** vira gargalo. A estimativa de **~1,1–1,2 GB** que
circula no `D-IMAN-028`/DB-5 está **superestimada por ~2×** para o instalador: o `.exe` fica em
**~534 MB**. (Os ~2,2 GB são o **disco ocupado depois de instalado**, não o download.)

---

## 6. O encadeamento, como protótipo (medido só na compilação)

Trecho efetivamente compilado. **Não foi aplicado a `installer/iman-terra.iss`** — montar o
instalador definitivo é a fatia seguinte, após o veredito.

```ini
[Setup]
; A2 exige elevacao (ALLUSERS=1 no MSI do QGIS). UMA elevacao, herdada.
PrivilegesRequired=admin          ; hoje o .iss traz "lowest" — MUDA (D-IMAN-028/DB-7)

[Files]
Source: "{#PayloadMsi}"; DestDir: "{tmp}"; DestName: "qgis-payload.msi"; \
  Flags: deleteafterinstall ignoreversion

[Run]
Filename: "msiexec.exe"; \
  Parameters: "/i ""{tmp}\qgis-payload.msi"" /qn /norestart /L*v ""{tmp}\qgis-install.log"""; \
  StatusMsg: "Instalando o QGIS 3.44.9 (powered by QGIS)..."; \
  Flags: waituntilterminated; \
  Check: PrecisaInstalarQgis

[Code]
// O MSI do QGIS nao tem Upgrade table: ele NAO procura outra versao.
// Quem decide pular somos NOS, pelo ProductCode exato do payload.
const
  QGIS_3_44_9_PRODUCTCODE = '{8397FA4A-7089-1014-9008-9EE76A62B1BC}';

function PrecisaInstalarQgis(): Boolean;
begin
  Result := not RegKeyExists(HKEY_LOCAL_MACHINE,
    'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' + QGIS_3_44_9_PRODUCTCODE);
end;
```

**O que este protótipo prova:** que o `.iss` **compila** com o payload embarcado, nos tempos e
tamanhos de §5.2. **O que ele NÃO prova:** que instala. Ele nunca foi executado.

---

## 7. O que travou (por que 3 dos 5 casos não foram medidos)

A parte empírica da matriz precisa de **(a)** elevação e **(b)** máquinas em estados específicos.
Nenhuma das duas existe nesta bancada:

1. **Sem elevação.** A sessão roda como usuário comum
   (`IsInRole(Administrator)` = `False`). O MSI é `ALLUSERS=1` e, sob `/qn`, o msiexec **não exibe
   UAC** — devolve `1625` e para. Não há como instalar sem um prompt interativo de elevação.
2. **Sem VM.** `HypervisorPresent = True`, mas não há `VBoxManage`, `vmrun`, `vagrant`,
   `qemu`, nem `WindowsSandbox.exe`; consultar/ativar features do Hyper-V exige admin.
3. **A única máquina com QGIS é a do sponsor.** Medir M1 exigiria **desinstalar** o QGIS 3.44.9
   daqui; M2a/M4 exigiriam **instalar por cima** dele. Ambos alteram destrutivamente a instalação
   oficial do usuário — proibido pelo protocolo da crew e pelo BL-3.

**Nada foi instalado, alterado ou removido nesta máquina.** Após todas as medições, verificado:
ARP intacto (`QGIS 3.44.9 'Solothurn' v3.44.9`), `C:\Program Files\QGIS 3.44.9\bin\qgis-ltr-bin.exe`
presente, `C:\Program Files\QGIS*` = apenas `QGIS 3.44.9`, nenhuma pasta de teste criada, nenhum
processo `msiexec` órfão.

**Para fechar S1/S3/S4/S5/S6 é preciso uma rodada em VM Windows limpa, com direito de elevação** —
a mesma VM que o BL-7 já exige. Estimativa: M1, M2a, M4 + as asserções cabem numa sessão.

---

## 8. Recomendações — opções com consequência, **não decisões**

> `D-IMAN-028`/DB-10 e o briefing colocam M2b, M3 e M4 como **STOP-AND-FLAG**. O que segue são
> opções medidas e suas consequências. **A crew não escolheu nenhuma.**

### 8.1 M2b — QGIS `3.44.x` com patch diferente (ex.: `3.44.12`)

O risco aqui é **irritação e desperdício**, não destruição. O usuário tem um QGIS que funciona e
que é **mais novo** que o nosso payload.

| Opção | Consequência medida / esperada |
|---|---|
| **(a) Instalar assim mesmo** (coexistir) | É o comportamento **default** do MSI. Não destrói nada. Custa **~2,2 GB** duplicados. **Exige corrigir o launcher (§4)**, senão abrimos o `3.44.12` e o payload vira lixo |
| **(b) Pular e usar o QGIS existente** | Zero disco, zero risco ao usuário. Mas o produto passa a rodar num runtime **não testado** (`3.44.12` ≠ baseline declarada) — enfraquece a procedência `(ProductVersion, Commit)` do `D-IMAN-028`/DB-8 |
| **(c) Perguntar ao usuário** | Honesto, mas quebra a instalação silenciosa e joga uma decisão técnica no colo do técnico de prefeitura |

**Ponto de atenção factual:** o site oficial serve **sempre o patch mais recente** do LTR. `3.44.12`
já existe e é maior que a nossa baseline. Máquina de campo com patch diferente **é o caso comum,
não a exceção** — e o `3.44.9` tende a ficar cada vez mais atrás.

### 8.2 M3 — QGIS em minor diferente (ex.: `3.34`, `3.40`)

Risco **de outra natureza**: o QGIS `3.34`/`3.40` do usuário pode sustentar projeto, plugin e fluxo
de trabalho de terceiro. **Mexer nele pode quebrar o trabalho dele.**

**A boa notícia medida:** com o instalador oficial, isso **não acontece por acidente**. Sem
`Upgrade` table, sem `RemoveExistingProducts`, sem `LaunchCondition`, o MSI **não tem como**
atualizar ou remover a instalação existente. A coexistência é o default, e ela é **não destrutiva**.

| Opção | Consequência |
|---|---|
| **(a) Coexistir** (default do MSI) | Instalação de terceiro **intacta** — coerente com o espírito do BL-3. Custo: ~2,2 GB + **launcher precisa preferir o nosso** (§4), senão abrimos o `3.34` e nada funciona como testado |
| **(b) Pular e usar o existente** | Rodar a camada de marca sobre `3.34`/`3.40` **não foi testado** e é a minor errada. Alto risco de quebra funcional silenciosa |
| **(c) Atualizar/substituir** | **Destrutivo.** Exigiria código nosso deliberado (o MSI não faz sozinho). **Não recomendado por medição nenhuma** — só o sponsor pode querer isso |

### 8.3 M4 — falha no meio da instalação do QGIS

**NÃO MEDIDO.** Sem elevação não se chega a uma falha real de instalação. O que se pode afirmar
pelo desenho:

- O Inno **não faz rollback automático** de uma `[Run]` que falha. Com `waituntilterminated`, o
  exit code fica disponível, mas **por padrão é ignorado** — o setup segue e conclui.
- Sem tratamento explícito, o estado que sobra é **"IMAN Terra instalado, QGIS ausente ou
  parcial"** — o pior dos três, porque parece sucesso.

| Opção | Consequência |
|---|---|
| **(a) Abortar antes de tocar em qualquer coisa** | Encadear o MSI **antes** de instalar a camada de marca e abortar em erro. Deixa a máquina como estava. Mais previsível para quem está na frente da máquina |
| **(b) Seguir instalado, avisando** | Camada de marca fica no disco, launcher exibe a mensagem de "QGIS não encontrado" que já existe. Recuperável reinstalando o QGIS à mão |
| **(c) Rollback total** | Mais limpo conceitualmente; mais código, e desinstalar um MSI meio-instalado tem risco próprio |

**Pré-requisito comum às três:** ler o exit code do msiexec e ramificar — hoje o `[Run]` do
protótipo não ramifica. E o contrato de códigos de instalação (§1.5) **ainda não foi medido**.

### 8.4 Consequências já certas, independentes de M2b/M3/M4

- **`PrivilegesRequired=lowest` → `admin`** no `.iss` (`ALLUSERS=1` não deixa alternativa). Confirma
  `D-IMAN-028`/DB-7: a premissa "usuário NÃO administrador" **cai de fato**.
- **`{autopf}` passa a resolver `C:\Program Files`** e os atalhos viram all-users (DB-9). **A
  confirmação empírica é o S6 — NÃO MEDIDA.**
- **O "pulo" do M2a é código nosso** (§3), nunca do MSI.
- **DB-5 folga:** o `.exe` fica em **~534 MB**, não ~1,2 GB.
- **DB-6 continua integral e obrigatório:** embarcar o MSI é **redistribuição** — GPL-2.0-or-later
  do QGIS + Qt (LGPL) + GDAL/PROJ/GEOS/Python. Fatia própria, **antes de qualquer distribuição**.

---

## 9. O que este spike **NÃO** testou

- **M1, M2a sob elevação e M4** — os três exigem elevação/VM (§7).
- **Qualquer instalação de verdade.** Nada foi instalado. O protótipo só foi **compilado**.
- **Desinstalação** (`D-IMAN-028`/DB-11): se o IMAN Terra remove ou não o QGIS que instalou. Não
  tocado — é decisão de produto.
- **Update-path**: instalar `0.3` sobre `0.2` com payload novo; e o que fazer com o QGIS antigo.
- **VM limpa de verdade** (BL-7): Windows 11 pt-BR, não-admin, 1366×768 @125 %.
- **S4** — os três sinais do perfil `iman-distro` (`iman_brand` ativo, CRS padrão, QSS aplicado).
- **S5 em runtime** — o par snapshot antes/depois. Só há evidência **estática** (§5.1).
- **Máquina sem runtime C++** (VC++ redistributable) e outros pré-requisitos do QGIS.
- **Rede corporativa com proxy** — irrelevante para o A2a offline, mas relevante para baixar o
  próprio `.exe` de 534 MB.
- **Restart Manager / arquivo em uso** — o `3010` e o cenário "QGIS aberto durante a instalação".
- **`3.44.12` como payload.** Foi baixado **só para comparar metadados**; trocar a baseline é
  decisão de produto.
- **Assinatura de código** do `.exe` e reação do SmartScreen a um binário novo de 534 MB.

---

## 10. Como reproduzir as medições

Nenhum passo abaixo instala, altera ou remove coisa alguma.

```powershell
# 1. Identidade do pacote (ProductCode/UpgradeCode/tabelas) — sem baixar nada:
#    o MSI em cache da instalacao existente ja serve.
#    Registro: HKLM\...\Uninstall\{8397FA4A-7089-1014-9008-9EE76A62B1BC} -> UninstallString
#    LocalPackage: HKLM\...\Installer\UserData\S-1-5-18\Products\...\InstallProperties
#    Ler tabelas via COM WindowsInstaller.Installer -> OpenDatabase(<msi>, 0)
#    Consultar: Property, Directory, InstallExecuteSequence, CustomAction, _Tables

# 2. Baixar os payloads (541 MB / 550 MB)
$u='https://download.qgis.org/downloads/QGIS-OSGeo4W-3.44.9-1.msi'
(New-Object Net.WebClient).DownloadFile($u,'E:\scratch\qgis-payload\QGIS-OSGeo4W-3.44.9-1.msi')
Get-FileHash 'E:\scratch\qgis-payload\QGIS-OSGeo4W-3.44.9-1.msi' -Algorithm SHA256
# esperado: 711D6DF99F450522A1E22755FCBFED65D5190C1E4C241793BC2F80FF1A2C24BA

# 3. Extrair sem instalar (instalacao administrativa) — exit 0, ~2,13 GB
msiexec /a "<msi>" /qn TARGETDIR="E:\scratch\qgis-payload\adm"
#    e entao inspecionar "QGIS 3.44.9\etc\postinstall.bat" e "preremove.bat"

# 4. Ordem de escolha do launcher (§4): criar "QGIS 3.34.15", "QGIS 3.40.3",
#    "QGIS 3.44.9", "QGIS 3.44.12" com bin\qgis-ltr-bin.exe stub e rodar a
#    rotina :find_in_root copiada de app/launcher/IMAN-Terra.bat
```

---

## 11. Gate do arquiteto — autoavaliação honesta

| Critério do gate | Situação |
|---|---|
| Veredito explícito | **SIM** — `A2a VIÁVEL COM RESSALVA`, com a ressalva nomeada (§4) |
| Cinco casos medidos | **NÃO — 2 de 5.** M2b e M3 medidos; M2a parcial; M1 e M4 não medidos, com o motivo em §7 |
| M2b e M3 relatados e **não arbitrados** | **SIM** — §8.1 e §8.2, em parágrafos separados, como opções |
| M2b tratado como M2a? | **NÃO** — §1.2 mostra `ProductCode` **e** `UpgradeCode` distintos |
| Contrato de exit codes documentado | **PARCIAL** — 3 medidos, 6 declarados **NÃO MEDIDOS** (§1.5) |
| Baseline do S5 com `TotalArquivos > 0` | **N/A nesta rodada** — não houve instalação, logo não houve par antes/depois. Evidência **estática** em §5.1; alerta de preparo preservado |

**Leitura honesta:** o gate, como escrito, **não passa** — faltam três casos e o S5 em runtime. O
que este spike entrega é a **Fase 0 fechada e favorável** (o entregável que o próprio briefing
chama de "mais valioso"), M2b/M3 respondidos de forma decisiva e não destrutiva, e **um achado
bloqueante que nenhuma rodada de VM teria encontrado sozinha** (§4). O que falta é
**execução em máquina elevada**, não análise.
