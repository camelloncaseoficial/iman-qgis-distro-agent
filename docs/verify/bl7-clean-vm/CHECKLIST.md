# BL-7 - Checklist de verificação em VM limpa

**Para quem executa:** este roteiro **não** exige conhecer o código. Cada passo tem o que fazer,
**o que você deve ver** (asserção), um campo de resultado e o nome do screenshot a salvar.
Se o que você viu não bate com a asserção, marque `FAIL` e **descreva literalmente o que apareceu**.
Descrição fiel vale mais do que diagnóstico.

**O que está sendo verificado:** que a distro **IMAN Terra** instala **sem elevação**, **carrega o
QGIS dentro dela**, abre com a cara certa, credita o QGIS e **não encosta nos dados do usuário** -
numa máquina que nunca viu este projeto.

> **Regra de ouro:** anote o que **aconteceu**, não o que deveria acontecer.

> ### ⚠ Este checklist foi REESCRITO na fatia `#036`, contra o produto que existe hoje
>
> A reescrita anterior (fatia `#011`) descrevia a **via A2a**: um instalador que **encadeava o MSI
> oficial do QGIS**, exigia **elevação**, punha o produto em `C:\Program Files\IMAN Terra` e o QGIS
> em `C:\Program Files\QGIS 3.44.13`.
>
> **Nada disso é verdade desde a fatia `#019` (via A1).** Hoje o QGIS **não é instalado ao lado**:
> ele **vive dentro do produto**, em `{app}\qgis`. Um instalador, sem `msiexec` encadeado, **sem
> elevação**, tudo no perfil do usuário. O que **saiu** deste checklist saiu por isso, e está
> listado passo a passo no laudo da `#036`.
>
> **O que foi REMOVIDO, e por quê:** a contagem de prompts de UAC esperando `1` (hoje o esperado é
> `0`), a asserção de que o QGIS aparece em Configurações -> Aplicativos (ele não é instalado), o
> caso "o instalador **pula** o QGIS já instalado" (não há o que pular: o `DB-16` perdeu objeto), a
> leitura do log do Inno atrás das linhas `PULANDO` / `Encadeando` (o código que as escrevia foi
> removido), a rodada de coexistência `3.44.12` contra `3.44.13` (a **detecção** do QGIS morreu no
> commit `a1b0c37`, junto com o teste dela) e o passo "desinstalar o IMAN Terra não remove o QGIS"
> (o `DB-11` perdeu objeto: o QGIS é nosso e sai junto).
>
> **O que ENTROU:** procedência do produto instalado (`§7`), a reconciliação do perfil nos três
> estados (`§11`, `§14`, `§20`), a guarda de integridade da árvore exercitada de verdade (`§16`) e
> a não interferência com um QGIS de sistema (`§19`).

---

## 0. Preparação

### 0.1 Legenda dos resultados - leia antes de preencher (`E.6`)

| Marca | Significa | Quando usar |
|---|---|---|
| `PASS` | **medido**, e bateu com a asserção | você executou e viu |
| `FAIL` | **medido**, e não bateu | você executou e viu outra coisa. **Transcreva o que apareceu** |
| `RELATADO` | você observou algo relevante, mas **não é asserção com veredito** | ex.: transcrever o texto do SmartScreen |
| `N/E` | **não executado** | faltou tempo, faltou ambiente, travou antes |

> **`N/E` não é `PASS`.** Um passo não executado **nunca** vira "deve estar bom". Foi assim que a
> rodada de 2026-07-30 se perdeu. No fim, preencha o **placar**: `___ de ___ passos com evidência`.

### 0.2 O build desta rodada - preencha ANTES de começar (`A7`)

Uma rodada que não sabe qual artefato exercitou não é evidência, é anedota.

| Campo | Valor |
|---|---|
| Artefato | `Instituto-IMAN-IMAN-Terra-Setup-______-_______.exe` |
| ProductVersion | `__________` |
| Commit (curto) | `__________` |
| Build canônico | `SIM / NÃO` |
| SHA-256 do `BUILD_INFO.txt` | `__________` |

> **O candidato vigente é o que o `installer/canonico/VIGENTE.txt` da `develop` aponta.** Na emissão
> desta reescrita ele é o **`0.3.0-5f7a1cb`**, com
> `sha256=949A960F36811327A21C250F5889E50E4A3DCD647BCAEF3F5C8DA35D86F2EFF5`, registrado em
> `installer/canonico/0.3.0-5f7a1cb/BUILD_INFO.txt`.
>
> **Não presuma que ainda é esse.** Abra o `VIGENTE.txt` da `develop` na hora e copie de lá. Uma
> rodada contra um `.exe` que não é o vigente continua valendo, **desde que o `§7` registre qual foi**.

### 0.3 As rodadas

Cada rodada parte de um **snapshot limpo**. Só a **M1** roda o checklist inteiro; as demais são
curtas e focadas.

| Rodada | Estado inicial da máquina | O que prova | Passos |
|---|---|---|---|
| **M1** | **sem QGIS nenhum**, sem IMAN Terra | o caminho feliz inteiro: um arquivo, sem elevar, e o produto abre | 1 a 18 |
| **M2** | **QGIS oficial 3.44.13 instalado à mão** | o produto **ignora** o QGIS da máquina e abre o **dele**; o do usuário fica intacto | 19 |
| **M3** | **versão ANTERIOR do IMAN Terra instalada e aberta ao menos uma vez** | a atualização chega a quem já tinha perfil (`DB-26`) | 20 |
| **M4** | sem QGIS, sem IMAN Terra | instalação **cancelada no meio** deixa a máquina como estava | 21 |

> **A M1 é o caminho feliz principal**: a máquina do técnico de prefeitura que recebeu um arquivo e
> mais nada. Ele **não é administrador**, e agora isso deixou de ser um obstáculo.

> **A M2 substitui as antigas M2a e M2b.** As duas mediam a **detecção** do QGIS: qual instalação a
> máquina tinha, qual o instalador pulava, qual o launcher escolhia. **Não há mais detecção** (a
> rotina e o teste dela morreram no commit `a1b0c37`, fatia `#019`). A pergunta que sobrou, e que
> ficou mais importante, é a oposta: **com um QGIS de sistema presente, o produto continua abrindo o
> dele e deixa o do usuário em paz?**

> **A M3 é nova.** Uma VM limpa é **cega** para o caminho de atualização, porque o perfil isolado
> nasce novo e o defeito não existe por construção. Era o ponto cego declarado no `RESULT.md`
> desde julho. Ele deixa de ser ponto cego aqui.

### 0.4 Configuração das VMs (`E.7`)

- Windows 11 **pt-BR**
- **usuário comum, SEM direito de administrador** (é a configuração que o produto agora suporta)
- **snapshot LIMPA** antes de cada rodada
- resolução **1366x768** com escala de exibição **125 %**
- ao menos **6 GB livres** em disco (a árvore do QGIS ocupa ~2,2 GB instalada, e o `.exe` tem ~490 MB)

> **Sobre os 125 %.** Não é capricho: o 125 % existe para **provocar** estresse de DPI, e é o pior
> caso do dashboard da HOME. Na rodada de 2026-07-30 a VM saiu em **1024x768 @ 100 %**, e isso virou
> achado: testar em outra escala **esconde** exatamente os defeitos que interessam. Se não conseguir
> 1366x768 @ 125 %, **anote a configuração real** e marque os passos visuais como `RELATADO`, não
> `PASS`. **Desvio de ambiente é achado, não nota de rodapé.**

> **Sobre a elevação.** A premissa "usuário NÃO administrador" esteve **violada** entre as fatias
> `#011` e `#018`, porque o MSI oficial do QGIS é `ALLUSERS=1` e exige elevação. Com a via A1 não há
> mais `msiexec` no caminho: `PrivilegesRequired=lowest`, e **nada nesta instalação pede elevação**.
> Se a sua VM estiver logada como administrador, o `§4` deixa de testar o que existe para testar.
> **Rode como usuário comum.**

### 0.5 O instalador chega por DOWNLOAD HTTP

Publique o `.exe` num link (release privada, drive com link direto, servidor local) e **baixe pelo
navegador dentro da VM**.

> **Não copie por pasta compartilhada nem por área de transferência.** Só o download por HTTP marca
> o arquivo com o *Mark-of-the-Web*, que é o que faz o **SmartScreen real** aparecer.

### 0.6 Helpers, e o pacote que a bancada prepara

Copie `tools\bl7\` para a VM (ex.: `Desktop\bl7`). São scripts de **PowerShell 5.1**: não precisam
de Python, git, internet nem módulos de terceiros.

```powershell
Set-ExecutionPolicy -Scope Process -Bypass
```

Evidências caem em `Desktop\bl7-evidence\`.

**Para a rodada M3 (passo 20)**, a VM precisa de **perfis de versões anteriores**. A VM não tem git,
então os templates históricos saem da bancada, **antes** da rodada:

```powershell
# NA BANCADA (tem git), a partir da raiz do repositorio:
git archive --format=zip -o perfil-velho-ba58d14.zip ba58d14     app/profile-template/iman-distro
git archive --format=zip -o perfil-velho-pre0707.zip '8cc4d5e^'  app/profile-template/iman-distro
```

Leve os dois `.zip` junto com `tools\bl7\`.

> **Por que templates REAIS da história, e por que dois.** Um perfil editado à mão não prova a
> mesma coisa: não é assim que o perfil de um usuário nasce. E os dois commits divergem em coisas
> **diferentes**, então cada um exercita um ramo distinto da reconciliação:
>
> | semente | o que ela tem de diferente | o que ela exercita |
> |---|---|---|
> | `ba58d14` (2026-09-07, merge do PR #22, anterior à `#022`) | 14 raios de 5 a 8 px, `iman_brand.py` sem `_RE_SUFIXO_DO_QGIS` | tema e plugin novos **chegando** |
> | `8cc4d5e^` (2026-07-05, anterior a 07-07) | carrega `QGIS/iman-theme.qss` e `resources/logo.png`, e tem **CRS padrão `EPSG:4674`** | obsoletos **saindo** e chave **corrigida** |
>
> **O segundo é o que cobre o defeito mais caro.** Um perfil com `EPSG:4674` cravado não dá erro:
> o QGIS só desenha, e a medição sai errada sem aviso. Com a semente `ba58d14` o CRS **já sai
> certo**, então ali a asserção de CRS é guarda de regressão, não discriminador.

---

# RODADA M1 - máquina sem QGIS (caminho feliz)

## 1. Baseline do perfil do QGIS do usuário - o passo que já invalidou uma rodada inteira

Nesta rodada a máquina **não tem QGIS**, então `%APPDATA%\QGIS` **não existe**. É exatamente aí que
mora a armadilha.

> ### ⚠ PARE E LEIA
> Em 2026-07-30 o baseline foi capturado com `RaizExiste: false` / `TotalArquivos: 0`. Depois, o
> `assert-bl3` devolveu `BL3a: false` **sem conseguir distinguir** "o produto invadiu o perfil" de
> "alguém abriu o QGIS stock". **Comparar pasta vazia com pasta vazia não prova nada**, e não há
> conserto retroativo: a rodada inteira virou trabalho perdido.

**Faça, nesta ordem, ANTES de instalar o IMAN Terra:**

1. Instale o **QGIS oficial 3.44.13** na VM (é o mesmo payload; instale-o **à mão**, só para sujar
   o perfil). Esta instalação **pede elevação**, e isso é do instalador do QGIS, não do nosso.
2. **Abra o QGIS uma vez**, mude uma configuração visível (um tema, um painel), **crie e salve um
   projeto**, e **feche**.
3. **Desinstale o QGIS** pelo Painel de Controle. O perfil em `%APPDATA%\QGIS` **sobrevive** ao
   uninstall, e é justamente o que queremos.
4. Só então:

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\snapshot-user-profile.ps1 -Rotulo antes
```

**Asserção numérica, sem interpretação (`E.1`):**

- `TotalArquivos` no `perfil-usuario-antes.json`: `______`
- [ ] **É maior que zero?** -> **se for `0`, PARE e refaça do item 1.** `PASS / FAIL`
- Screenshot: `01-baseline-perfil-usuario.png`
- Invariante: **BL-3**

> **Com o defeito presente:** se o produto invadir `%APPDATA%\QGIS`, o `§12` acusa por nome de
> arquivo. Sem este baseline com conteúdo, o `§12` passa **igual** nos dois mundos, e é isso que o
> torna a peça mais frágil do roteiro.

---

## 2. O artefato chegou inteiro - SHA-256 e `BUILD_INFO`

**Faça:** com o `.exe` já baixado na VM:

```powershell
Get-FileHash .\Instituto-IMAN-IMAN-Terra-Setup-<versao>-<commit>.exe -Algorithm SHA256
```

| # | Asserção | Resultado |
|---|---|---|
| 2.1 | O SHA-256 bate com o do `BUILD_INFO.txt` do `§0.2` | `PASS / FAIL / N/E` |
| 2.2 | Tamanho em bytes bate com o do `BUILD_INFO.txt`: `__________` | `PASS / FAIL / N/E` |
| 2.3 | QGIS embarcado declarado no `BUILD_INFO.txt`: `__________` | `RELATADO` |
| 2.4 | `Payload SHA-256` do `BUILD_INFO.txt` confere com o publicado pela QGIS.ORG | `PASS / FAIL / N/E` |

> **Se o `2.1` falhar, PARE.** O arquivo que chegou não é o que foi gerado, e tudo o que vier depois
> mede outra coisa.

> ⚠ **O arquivo tem ~490 MB.** Download interrompido é bem mais provável que num instalador leve, e
> por isso esta conferência deixou de ser formalidade.

> **Com o defeito presente:** um download truncado produz um `.exe` que **abre** e falha adiante, em
> lugar nenhum óbvio. É este passo, e só ele, que separa "o produto está quebrado" de "o arquivo
> chegou quebrado".

- Screenshot: `02-sha256.png`

---

## 3. Rodar o instalador - SmartScreen, wizard e créditos

**Faça:** execute o `.exe` baixado, com **duplo clique**.

| # | Asserção | Resultado |
|---|---|---|
| 3.1 | Texto literal do SmartScreen: `________________________________` | `RELATADO / N/E` |
| 3.2 | Wizard em pt-BR, com a arte de marca IMAN | `PASS / FAIL / N/E` |
| 3.3 | A tela de licença aparece **antes** de instalar | `PASS / FAIL / N/E` |
| 3.4 | **Nenhuma** tela se apresenta como QGIS oficial ou endossado pela QGIS.ORG | `PASS / FAIL / N/E` |
| 3.5 | **Nenhuma** janela de instalador de terceiro aparece no meio do percurso | `PASS / FAIL / N/E` |
| 3.6 | O logo do wizard assenta **sem chapa cinza** atrás dele, em toda página interna | `PASS / FAIL / N/E` |

> **O `3.5` é novo e é a prova da via A1 na tela.** A queixa do sponsor que originou a troca de via
> foi literalmente *"a sensação de instalação de um produto que na metade aparece outro produto
> sendo instalado"*. Hoje não há `msiexec` encadeado: se aparecer UI de terceiro, é achado grave.

> **O `3.6` cobre o `DB-21`.** O `wizard-small.png` já foi RGB sem canal alfa, com `#EBEEE8` cravado
> nos pixels, e o resultado era um retângulo cinza atrás do símbolo no canto superior direito. O
> conserto foi alfa real no PNG mais `WizardImageAlphaFormat=defined`. Evidência do antes e depois
> em `docs/verify/015-db21-wizard/`.

> **Com o defeito presente:** o `3.4` e o `3.5` passam por **ausência**, então olhe as telas uma a
> uma em vez de concluir do fim. O `3.6` é o oposto: é visível e só some se alguém regravar o PNG.

- Screenshots: `03a-smartscreen.png`, `03b-wizard-boas-vindas.png`, `03c-licenca.png`
- Invariantes: **BL-1 / BL-2**

---

## 4. Elevação - o esperado agora é ZERO

**Faça:** conclua a instalação prestando atenção em **quantas vezes** o Windows pede elevação.

| # | Asserção | Resultado |
|---|---|---|
| 4.1 | **Quantos** prompts de UAC apareceram no percurso inteiro: `______` | `PASS` se **0** |
| 4.2 | A instalação terminou **sem** pedir reinício | `PASS / FAIL / N/E` |
| 4.3 | A sessão do Windows **não** é de administrador (`collect-evidence.ps1` confirma) | `PASS / FAIL / N/E` |

> ### ⚠ Esta asserção INVERTEU na fatia `#019`
> Até a `#018` o esperado era **exatamente 1** prompt, e dois eram achado: a elevação vinha do
> `ALLUSERS=1` do MSI do QGIS. **Sem MSI encadeado, nada nesta instalação precisa elevar.**
> **Qualquer prompt de UAC aqui é achado**, e provavelmente significa que o `PrivilegesRequired`
> voltou a `admin` por engano, o que arrastaria `{app}` para área de sistema e desfaria o `BL-3`.

> **Com o defeito presente:** um instalador que voltasse a elevar **ainda instalaria com sucesso**.
> O sucesso não distingue os dois mundos; a contagem de prompts distingue. Por isso o número, e não
> o resultado final, é a asserção.

- Screenshot: `04-sem-uac.png` (ou o prompt que apareceu, se apareceu)

---

## 5. Onde o produto foi parar, e onde ele NÃO foi

```powershell
$app = Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'
Test-Path $app
Get-ChildItem $env:ProgramFiles -Filter 'QGIS *' -Directory -ErrorAction SilentlyContinue
Get-ChildItem $env:ProgramFiles -Filter 'IMAN*'  -Directory -ErrorAction SilentlyContinue
Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' |
    Where-Object DisplayName -like 'IMAN Terra*' | Select-Object DisplayName, DisplayVersion, InstallLocation
```

| # | Asserção | Resultado |
|---|---|---|
| 5.1 | Diretório de instalação: `________________________________` | `PASS` se `%LOCALAPPDATA%\Programs\IMAN Terra` |
| 5.2 | **Nada** foi criado em `C:\Program Files` nem em `C:\Program Files (x86)` | `PASS / FAIL / N/E` |
| 5.3 | O atalho do Menu Iniciar existe **para este usuário** | `PASS / FAIL / N/E` |
| 5.4 | A entrada de desinstalação está em **`HKCU`**, não em `HKLM` | `PASS / FAIL / N/E` |
| 5.5 | Em Configurações -> Aplicativos aparece **IMAN Terra**, e **nenhum QGIS** | `PASS / FAIL / N/E` |

> **O `5.5` é a inversão mais fácil de errar ao preencher.** Até a `#018` o QGIS **tinha** de
> aparecer em Aplicativos, porque era instalado. Hoje ele **não é instalado**: é extraído do MSI
> oficial em tempo de build e viaja dentro do produto. **Se um QGIS aparecer aqui nesta rodada, é
> achado**, porque esta VM não deveria ter nenhum.

> **Com o defeito presente:** um instalador que voltasse a `{autopf}` **funcionaria**, e o produto
> abriria. O que muda é onde ele mora e o que ele exige do usuário. Só o caminho literal distingue.

- Screenshot: `05-local-instalacao.png`

---

## 6. O QGIS veio DENTRO do produto

```powershell
$app = Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'
Test-Path "$app\qgis\bin\qgis-ltr-bin.exe"
Get-Content "$app\qgis-manifest.txt" | Select-String '^VERSAO\||^TOTAL\|'
(Get-ChildItem "$app\qgis" -Recurse -File -Force).Count
```

| # | Asserção | Resultado |
|---|---|---|
| 6.1 | `{app}\qgis\bin\qgis-ltr-bin.exe` existe | `PASS / FAIL / N/E` |
| 6.2 | `{app}\qgis-manifest.txt` existe, e a linha `VERSAO` bate com o `BUILD_INFO.txt` | `PASS / FAIL / N/E` |
| 6.3 | Contagem de arquivos em `{app}\qgis`: `______` , contra o `TOTAL` do manifesto: `______` | `PASS` se **igual ou maior** |
| 6.4 | **Tempo total** da instalação, do duplo clique ao fim: `______ min` | `RELATADO` |
| 6.5 | O wizard mostrou **progresso que anda** durante a cópia da árvore | `PASS / FAIL / N/E` |

> **Por que o `6.3` é PISO e não igualdade.** A árvore **não** é somente leitura em uso: o Python do
> próprio produto grava bytecode em `__pycache__` ao importar. Medido em 2026-09-20, numa instalação
> aberta uma vez: **38.154** arquivos contra os **37.337** do manifesto, e os **817** de diferença
> eram **todos** `.pyc`. Truncar sempre **diminui** a contagem; crescer nunca é truncar. É a mesma
> regra que o launcher aplica na guarda de integridade.

> **O `6.5` substitui o antigo `DB-19`**, que media a janela do msiexec parecendo travada por ~4
> minutos. Aquela espera não existe mais: não há processo de terceiro bloqueando o wizard. O que
> resta é a cópia de ~2,2 GB pelo próprio Inno, que tem barra de progresso nativa.

> **Com o defeito presente:** uma árvore parcialmente copiada deixa o `6.1` passando (o `.exe` do
> QGIS pode estar lá) e derruba o `6.3`. E é o `§16` que prova que o produto **se recusa a abrir**
> nesse estado, em vez de abrir e devolver coordenada errada.

- Screenshot: `06-arvore-do-qgis.png`

---

## 7. PROCEDÊNCIA - de que build é este produto instalado (`A3`)

> ### Por que este passo existe
> O `§2` confere o SHA-256 **antes** de instalar. Depois de instalar, a procedência sumia: o produto
> instalado não sabia dizer de que build era, e o laudo virava relatório sobre binário anônimo. O
> `DB-24` (fatia `#025`) pôs a identidade **dentro** do produto, e a fatia `#033` mediu que ela
> chega ao `{app}`. **Este passo é onde a rodada de VM passa a poder dizer o que testou.**

```powershell
$app = Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'
Get-Content "$app\BUILD_ID.txt"
```

| # | Asserção | Resultado |
|---|---|---|
| 7.1 | `{app}\BUILD_ID.txt` existe | `PASS / FAIL / N/E` |
| 7.2 | `commit_curto` = `__________` , igual ao do `§0.2` | `PASS / FAIL / N/E` |
| 7.3 | `build_canonico` = `__________` | `PASS` se `sim` |
| 7.4 | `versao` e `qgis_embarcado` conferem com o `BUILD_INFO.txt` | `PASS / FAIL / N/E` |
| 7.5 | O `commit_curto` é **prefixo** do `commit` completo do mesmo arquivo | `PASS / FAIL / N/E` |
| 7.6 | Na HOME do produto, o rodapé mostra `versão <versao> · <commit_curto>` igual ao arquivo | `PASS / FAIL / N/E` (confira no `§9`) |

> **O `7.3` não é decoração.** `build_canonico=nao` significa build de branch: legítimo para
> experimentar, **inválido como evidência de release**. Uma rodada de BL-7 contra artefato
> não canônico vale como ensaio, e o `RESULT.md` tem de dizer isso em voz alta.

> **Com o defeito presente:** sem este passo, o produto exibe "versão 0.3.0" e nada mais. Essa
> string é **idêntica em todo artefato 0.3.0 já compilado**, canônico ou não, e portanto não
> responde "qual build é este?". Uma asserção do tipo "a home mostra uma versão" passa com o defeito
> presente.

- Screenshot: `07-build-id.png`
- Origem: **`DB-24`** (`#025`), medido em `{app}` pela `#033`

---

## 8. O CHECKBOX FINAL do instalador

> ### ⚠ Dois caminhos com PAIS DIFERENTES, e a diferença continua viva
>
> O checkbox **"Abrir o IMAN Terra agora"** nasce filho do `Setup.exe` do Inno, que é um binário de
> **32 bits**. O atalho do `§9` nasce do **Explorer**, que é de **64 bits**.
>
> **O `DB-20` original morreu na fatia `#019`**: ele era a sondagem de `%ProgramFiles%` pelo
> launcher, que sob a visão WOW64 caía toda em `Program Files (x86)`. Não há mais sondagem: o
> launcher deriva a raiz de `%~dp0..`, que é indiferente a bitness.
>
> **O que continua diferente é a redireção de `%SystemRoot%\System32`.** Debaixo de um pai de 32
> bits, ela aponta para `SysWOW64`, e o launcher chama `find.exe`, `certutil.exe` e `powershell.exe`
> por caminho absoluto sob `System32`. Enquanto essa diferença existir, os dois caminhos são
> percursos distintos, e **um passo NÃO substitui o outro**. Quem "otimizar" juntando os dois
> reabre a classe de buraco por onde o `DB-20` entrou.

**Faça:** na última página do wizard, **DEIXE o checkbox "Abrir o IMAN Terra agora" TICADO** e
clique em **Concluir**. Não abra nada pelo atalho ainda: isso é o `§9`.

| # | Asserção | Resultado |
|---|---|---|
| 8.1 | O checkbox **"Abrir o IMAN Terra agora"** aparece **já ticado** | `PASS / FAIL / N/E` |
| 8.2 | Depois do `Concluir`, **o IMAN Terra abre** (splash e janela do produto) | `PASS / FAIL / N/E` |
| 8.3 | **NÃO** apareceu janela preta de console com mensagem de erro | `PASS / FAIL / N/E` |
| 8.4 | Se apareceu console: o texto **literal** transcrito abaixo | `RELATADO` |

> **`8.2` e `8.3` são asserções separadas de propósito.** Uma janela de console que pisca e some
> **não é** "abriu"; e um produto que abre **depois** de uma tela de erro também **não é** `PASS`.
> Foi a ausência dessa distinção que deixou o `DB-20` passar por "o QGIS não deve estar instalado".

- **Texto LITERAL do console, se ele apareceu:**

  `______________________________________________________________________________`

  `______________________________________________________________________________`

  `______________________________________________________________________________`

> **O que procurar nesse texto.** As telas de recusa do launcher se identificam pela linha
> `IMAN Terra NAO PODE ABRIR` seguida do motivo: árvore **incompleta ou alterada** (`§16`) ou perfil
> que **não pôde ser atualizado**. As duas trazem o caminho conferido. Transcreva o bloco inteiro.

- Screenshot: `08-checkbox-final.png`

---

## 9. Primeiro run pelo atalho - cronometrado

**Faça:** feche o produto, abra pelo **atalho do Menu Iniciar**. Marque o tempo até a janela ficar
utilizável.

| # | O que deve aparecer | Resultado |
|---|---|---|
| 9.1 | **Splash com a arte IMAN**, não o splash padrão do QGIS | `PASS / FAIL / N/E` |
| 9.2 | Título da janela terminando em **` - IMAN Terra`**, com hífen | `PASS / FAIL / N/E` |
| 9.3 | O título **não** contém `QGIS` como autodesignação nem `[iman-distro]` | `PASS / FAIL / N/E` |
| 9.4 | A **HOME de boas-vindas NO MIOLO** (área central, não painel lateral) | `PASS / FAIL / N/E` |
| 9.5 | Chrome **clara**, com o verde só de acento | `PASS / FAIL / N/E` |
| 9.6 | Toolbar de marca presente e enxuta | `PASS / FAIL / N/E` |
| 9.7 | Ícone IMAN na barra de tarefas, e não o do QGIS | `SMOKE: PASS / FAIL / N/E` |
| 9.8 | Tempo até ficar utilizável: `______ s` | `RELATADO` |

> **O `9.7` é SMOKE declarado, não medição.** Ele passa **igual** com um ícone bem proporcionado e
> com um ícone edge-to-edge ou cortado: é insensível ao defeito que interessa. A medição é o `§10`,
> e é lá que o veredito do ícone vale. Ele fica aqui porque continua pegando a troca grosseira
> (o logo do QGIS reaparecendo), e isso vale o segundo que custa.

> **O que é "chrome clara" no `9.5`.** Barra de menus, barra de status, títulos de painel e headers
> de tabela são **claros, com texto escuro**. O verde institucional aparece só como **acento**: item
> de menu ativo, seleção, sublinhado da aba ativa, botão default, foco. **Chrome verde-escura
> pintando essas superfícies é FAIL.** Ver "Chrome CLARA" em `docs/design-system.md`.

> **Com o defeito presente:** o `9.3` é o que separa este passo do roteiro antigo. O critério
> anterior era "o título contém o nome do projeto e mudou", e ele continuava **verdadeiro** com
> `QGIS [iman-distro]` na tela: foi assim que o `D5` passou despercebido até a `#021`.

- Screenshots: `09a-splash.png`, `09b-primeira-tela.png`
- Itens são independentes: se só o splash falhar, marque só o `9.1`.

---

## 10. O ícone na barra de tarefas, em 16x16

**Faça:** com o IMAN Terra aberto, olhe o ícone **na barra de tarefas**, ao lado dos vizinhos
(Explorer, navegador). Se ajudar, aumente o zoom numa captura.

| # | Asserção | Resultado |
|---|---|---|
| 10.1 | O **globo aparece INTEIRO**, não cortado nas bordas | `PASS / FAIL / N/E` |
| 10.2 | O ícone **não é desproporcional** ao lado dos vizinhos: nem "gordo" preenchendo tudo, nem miúdo perdido no meio do quadro | `PASS / FAIL / N/E` |

> **Com o defeito presente:** é este passo, e não o `9.7`, que muda de resposta. Um ícone
> edge-to-edge continua sendo "o ícone IMAN"; ele só deixa de ser aceitável quando alguém compara a
> caixa dele com a dos vizinhos, no tamanho em que o defeito aparece.

- Screenshot **obrigatório**: `10-icone-taskbar-16px.png`. Enquadre o IMAN Terra **junto** de pelo
  menos dois ícones vizinhos, senão não dá para julgar proporção.
- Origem: **`D1`**

---

## 11. O perfil nasceu semeado - RECONCILIAÇÃO, estado (a) "perfil ausente"

> Este é o **primeiro** dos três estados de reconciliação que esta rodada cobre. Os outros dois são
> o `§14` (perfil igual) e o `§20` (perfil velho divergente).

**Por que três sinais e não um:** na fatia 1 houve um bug em que o QGIS abria **bonito mas com
perfil vazio** (o caminho virava `profiles\profiles\`). Um sinal isolado engana; os três juntos, não.

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\assert-reconciliacao.ps1 -Rotulo perfil-novo
```

| # | Onde olhar | O que deve estar lá | Resultado |
|---|---|---|---|
| 11.1 | Complementos -> Gerenciar e Instalar Complementos -> Instalados | **`iman_brand` ativo** (marcado) | `PASS / FAIL / N/E` |
| 11.2 | Projeto -> Propriedades -> SRC (ou o SRC na barra de status) | **`EPSG:31984`** | `PASS / FAIL / N/E` |
| 11.3 | A janela | QSS aplicado (cores IMAN, não o tema padrão do QGIS) | `PASS / FAIL / N/E` |
| 11.4 | saída do helper | `ARQUIVOS` = `__ de __`, com **todos** batendo, e `SOBRAS` = `0` | `PASS / FAIL / N/E` |
| 11.5 | saída do helper | `BASE : existe   template_digest=________` | `PASS / FAIL / N/E` |
| 11.6 | saída do helper | veredito final `[OK]` e saída `0` | `PASS / FAIL / N/E` |

> **O `11.4` é a asserção nova, e é por hash.** "O plugin está lá" passa com um plugin **velho** no
> lugar. O que o `DB-26` promete é que o perfil fica **igual ao template que este build instalou**,
> arquivo por arquivo, e é isso que o helper compara contra `{app}\profile-template\iman-distro`.

> **O `11.5` é a base do 3-way.** Sem `base.json` gravada, a próxima abertura não sabe o que era do
> produto e o que é do usuário, e a reconciliação do `§20` não teria como preservar escolha nenhuma.

> **Com o defeito presente:** um perfil semeado pela rotina **antiga** (`xcopy` no primeiro uso)
> passaria em `11.1`, `11.2` e `11.3` e **falharia** em `11.5`, porque a base não existiria.

- Screenshot: `11-plugin-crs-tema.png`
- **Os seis precisam passar.** Cinco em seis é FAIL do passo.
- Origem: **`S4`** (fatia 1) + **`DB-26`** (`#030`)

---

## 12. O perfil do QGIS do usuário continua intacto (BL-3) - bloqueia release

**Faça: FECHE o IMAN Terra**, depois:

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\assert-bl3.ps1 -Baseline "$env:USERPROFILE\Desktop\bl7-evidence\perfil-usuario-antes.json"
```

| # | Asserção | Resultado |
|---|---|---|
| 12.1 | `[BL-3a]` perfil do usuário **byte-idêntico** ao do `§1` (0 divergências) | `PASS / FAIL / N/E` |
| 12.2 | `[BL-3b]` perfil isolado criado em `%APPDATA%\InstitutoIMAN\IMAN Terra\profiles\iman-distro` | `PASS / FAIL / N/E` |

- Se `FAIL`, **copie a lista de DIVERGENTES inteira** para o `RESULT.md`.
- Screenshot: `12-assert-bl3.png` · Evidência: `Desktop\bl7-evidence\assert-bl3.json`
- Invariante: **BL-3. Inegociável. FAIL aqui BLOQUEIA o release.**

> **O que mudou na natureza deste passo com a via A1.** Antes, o risco vinha de um instalador **de
> terceiro** rodando elevado dentro do nosso percurso. Esse risco sumiu: não há mais `msiexec`. O
> risco que sobrou é **nosso**, e é maior em superfície: a rotina de reconciliação (`Sync-Perfil.ps1`)
> escreve dentro de um perfil a cada abertura. Ela tem fronteira declarada em
> `profile-template\PERFIL-DO-PRODUTO.json`, e este passo é quem confirma que a fronteira foi
> respeitada **na máquina**, não no teste.

> **Com o defeito presente:** um erro de caminho na reconciliação escreveria em `%APPDATA%\QGIS` e
> o produto **continuaria abrindo normalmente**. Nada na tela mudaria. Só a comparação por hash acusa.

---

## 13. Ciclo HOME e canvas, 3 vezes

**Faça, três vezes:** na HOME abra o **projeto demo**, vá para o **canvas**; **Projeto -> Novo**,
volte para a **HOME**.

**Não pode** sobrar "tela-fantasma" nem área cinza vazia.

- Volta 1 `PASS / FAIL / N/E` · Volta 2 `PASS / FAIL / N/E` · Volta 3 `PASS / FAIL / N/E`

> **Com o defeito presente:** a HOME continua desenhando normalmente e nenhuma exceção aparece. O
> defeito é a página **errada** no miolo, e por isso o critério é a página observada em cada estado,
> não "a home aparece".

- Screenshots: `13a-demo-canvas.png`, `13b-novo-home.png` · Guardrail: **`#006`**

---

## 14. Segundo run - RECONCILIAÇÃO, estado (b) "perfil igual, nada escrito"

> Segundo dos três estados. Aqui o perfil **já é** o desta versão, e a promessa é que a abertura
> **não escreve nada**.

**Faça:** abra o produto de novo pelo atalho, use por alguns segundos, **feche**, e rode:

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\assert-reconciliacao.ps1 -Rotulo segunda-abertura
Get-Content "$env:APPDATA\InstitutoIMAN\IMAN Terra\profiles\iman-distro\QGIS\QGISCUSTOMIZATION3.ini"
```

| # | Asserção | Resultado |
|---|---|---|
| 14.1 | Abre **mais rápido** que o primeiro run | `PASS / FAIL / N/E` |
| 14.2 | O splash IMAN aparece de novo, e a HOME também | `PASS / FAIL / N/E` |
| 14.3 | Suas alterações do run anterior continuam lá | `PASS / FAIL / N/E` |
| 14.4 | `QGISCUSTOMIZATION3.ini` tem **exatamente um** `[Customization]` e **uma** linha `splashpath=` | `PASS / FAIL / N/E` |
| 14.5 | `template_digest` do `base.json` é **o mesmo** do `§11.5` | `PASS / FAIL / N/E` |
| 14.6 | Nenhum arquivo do perfil mudou de SHA-256 entre o `§11` e agora, tirando o que o usuário mexeu | `PASS / FAIL / N/E` |

> **Por que o `14.4` existe.** O `splashpath` já foi reescrito **a cada execução** pelo launcher, e
> isso sozinho fazia toda segunda abertura escrever no perfil. Ele saiu de lá na `#030` e passou
> para a rotina de reconciliação, justamente para que "a segunda abertura não escreve nada" fosse
> possível de cumprir. Linha duplicada aqui é o sintoma clássico do defeito antigo voltando.

> **Com o defeito presente:** uma reconciliação que reescreve o perfil toda vez **não quebra nada
> visível**. O produto abre igual. O que ela destrói é a capacidade de o usuário manter qualquer
> personalização, e isso só aparece comparando hashes entre duas aberturas.

- Screenshot: `14-segundo-run.png`

---

## 15. Créditos do QGIS no produto instalado

| # | Onde | O que deve estar lá | Resultado |
|---|---|---|---|
| 15.1 | `{app}` | **`LICENSE`** | `PASS / FAIL / N/E` |
| 15.2 | `{app}` | **`THIRD_PARTY_NOTICES.md`** | `PASS / FAIL / N/E` |
| 15.3 | `{app}` | **`README.md`** | `PASS / FAIL / N/E` |
| 15.4 | `{app}\notices` | **`SOURCE_CODE.md`** | `PASS / FAIL / N/E` |
| 15.5 | `Ajuda -> Sobre o IMAN Terra` | credita o **QGIS** | `PASS / FAIL / N/E` |
| 15.6 | `Ajuda` | o **Sobre nativo do QGIS** continua no menu | `PASS / FAIL / N/E` |
| 15.7 | visível | **"powered by QGIS"** | `PASS / FAIL / N/E` |
| 15.8 | visível | aviso de **independência** | `PASS / FAIL / N/E` |

> **O `15.4` e o `15.6` são novos.** O `SOURCE_CODE.md` é a **oferta de fonte** exigida de quem
> redistribui binário sob GPL: apontar para `qgis.org` é cortesia, não cumprimento. O `15.6` guarda o
> `BL-1` pelo outro lado: o produto **acrescenta** um "Sobre o IMAN Terra"; ele não pode **remover**
> o Sobre do QGIS.

> **O aviso do `#020` sobre o `THIRD_PARTY_NOTICES.md` SAIU daqui.** Ele dizia que o arquivo ainda
> não cobria as obrigações de redistribuidor. Isso foi **pago** na fatia `#020`: o arquivo hoje
> inventaria 159 componentes, nomeia os 20 sob copyleft forte e os 14 sob LGPL, e remete ao
> `SOURCE_CODE.md`. **O que continua pendente é do sponsor**, não do pacote: servir de fato o fonte
> correspondente é pré-condição de release, e não se resolve neste checklist.

- Screenshots: `15a-pasta-instalada.png`, `15b-sobre.png` · Invariante: **BL-1**

---

## 16. A guarda de integridade RECUSA abrir sobre árvore quebrada

> ### Por que este passo existe, e por que ele vale o incômodo
> O spike `#016` mediu que a árvore do QGIS **não se autodiagnostica**. Com `share\proj` ausente, o
> QGIS responde `CRS válidos? True` e devolve deslocamento de datum de **0,00 m** onde o correto são
> **~57 m**. Não há exceção, não há valor absurdo. **Uma cópia truncada não aparece como erro:
> aparece como coordenada errada num memorial descritivo.**
>
> Por isso o launcher confere um manifesto antes de subir e **recusa abrir** se algo divergir. Essa
> promessa nunca foi exercitada numa VM. Aqui ela é.

**Faça** (a alteração é reversível, e o passo `§18` reinstala de qualquer forma):

```powershell
$app = Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'
Rename-Item "$app\qgis\share\proj\proj.db" 'proj.db.bak'      # quebra de proposito
# abra o IMAN Terra pelo atalho e observe
```

| # | Asserção | Resultado |
|---|---|---|
| 16.1 | O produto **NÃO abre** | `PASS / FAIL / N/E` |
| 16.2 | Aparece a tela `IMAN Terra NAO PODE ABRIR`, em português e sem stacktrace | `PASS / FAIL / N/E` |
| 16.3 | A tela **nomeia o que foi encontrado** (o arquivo ausente) e o caminho da árvore | `PASS / FAIL / N/E` |
| 16.4 | A tela diz **o que fazer** (reinstalar) | `PASS / FAIL / N/E` |

**Desfaça e confirme que voltou:**

```powershell
Rename-Item "$app\qgis\share\proj\proj.db.bak" 'proj.db'
# abra de novo: tem de abrir normalmente
```

| # | Asserção | Resultado |
|---|---|---|
| 16.5 | Depois de restaurar, o produto abre normalmente | `PASS / FAIL / N/E` |

> **Com o defeito presente:** se a guarda estiver desligada, o `16.1` vira "abriu" e **tudo parece
> bem**. É o pior resultado possível deste passo, e o único jeito de vê-lo é quebrar a árvore de
> propósito. Um passo que só observasse a instalação intacta passaria nos dois mundos.

- Screenshot **obrigatório**: `16-recusa-integridade.png` · Origem: spike **`#016`**, guarda da **`#019`**

---

## 17. Desinstalar - o que sai e o que fica

**Faça:** Configurações -> Aplicativos -> IMAN Terra -> Desinstalar.

| # | Asserção | Resultado |
|---|---|---|
| 17.1 | A pasta `%LOCALAPPDATA%\Programs\IMAN Terra` foi **removida por inteiro** | `PASS / FAIL / N/E` |
| 17.2 | **Não sobrou** nada em `{app}\qgis` (nem `.pyc` em `__pycache__`) | `PASS / FAIL / N/E` |
| 17.3 | Os atalhos foram removidos | `PASS / FAIL / N/E` |
| 17.4 | A entrada em `HKCU` de desinstalação sumiu | `PASS / FAIL / N/E` |
| 17.5 | `%APPDATA%\InstitutoIMAN` **CONTINUA LÁ**, com o perfil do usuário | `PASS / FAIL / N/E` |
| 17.6 | `%APPDATA%\QGIS` continua byte-idêntico ao `§1` (rode o `assert-bl3.ps1` de novo) | `PASS / FAIL / N/E` |

```powershell
Test-Path (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra')
Test-Path (Join-Path $env:APPDATA 'InstitutoIMAN')
cd $env:USERPROFILE\Desktop\bl7
.\assert-bl3.ps1 -Baseline "$env:USERPROFILE\Desktop\bl7-evidence\perfil-usuario-antes.json"
```

> **O `17.2` nasceu de uma medição.** Em 2026-09-07, num ciclo real de instalar, abrir e desinstalar,
> o uninstall deixou **817 arquivos / 14,69 MB** para trás, **todos** `.pyc`: o Inno só remove o que
> ele mesmo instalou, e aquele bytecode nasceu depois. A seção `[UninstallDelete]` passou a apagar
> `{app}\qgis` inteiro. Sem isso, cada ciclo deixaria sedimento crescendo no perfil do usuário.

> **O antigo "o QGIS continua instalado e abre" SAIU.** Ele media o `DB-11`, que **perdeu objeto**:
> não há mais um QGIS de terceiro instalado por nós para decidir se removemos. O QGIS é nosso, vive
> em `{app}\qgis` e sai junto. **O QGIS que o usuário porventura tenha instalado por conta própria
> nunca é tocado**, e é isso que o `§19` mede, na rodada onde ele existe.

> **Com o defeito presente:** um `[UninstallDelete]` que apagasse `%APPDATA%\InstitutoIMAN` também
> deixaria a máquina "limpa", e um observador desatento chamaria isso de sucesso. O `17.5` é o que
> distingue desinstalar de destruir dado do usuário.

- Screenshot: `17-pos-uninstall.png` · Invariante: **BL-3**

---

## 18. Reinstalar por cima - a árvore não se funde

> ### O defeito que este passo existe para pegar (`DB-22`)
> Instalando **sobre** uma instalação anterior, o instalador **fundia** a árvore nova sobre a velha
> em vez de limpá-la. Resultado medido: `exit 5` e uma árvore **misturada de dois builds**, com
> **38.154** arquivos contra os **37.337** do manifesto. A guarda do launcher então mandava
> "reinstalar o IMAN Terra", e reinstalar fundia de novo: **laço fechado**, a mesma classe do
> `DB-20`, em que a mensagem desviava o diagnóstico.

**Faça:** instale o mesmo `.exe` de novo, sobre a instalação que o `§17` removeu **e também** sobre
uma instalação existente. Para o segundo caso, instale, abra uma vez (para nascerem os `.pyc`) e
instale de novo por cima.

| # | Asserção | Resultado |
|---|---|---|
| 18.1 | Instala normalmente, sem erro | `PASS / FAIL / N/E` |
| 18.2 | Depois da reinstalação por cima, a contagem de `{app}\qgis` voltou a **bater com o manifesto** (igual ou maior por `.pyc`, nunca "muito maior") | `PASS / FAIL / N/E` |
| 18.3 | O produto **abre**, sem a tela de integridade do `§16` | `PASS / FAIL / N/E` |
| 18.4 | **Não** apareceu um segundo perfil `iman-distro` duplicado | `PASS / FAIL / N/E` |
| 18.5 | O perfil do usuário em `%APPDATA%\InstitutoIMAN` sobreviveu à reinstalação | `PASS / FAIL / N/E` |

```powershell
$app = Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra'
(Get-ChildItem "$app\qgis" -Recurse -File -Force).Count
Get-Content "$app\qgis-manifest.txt" | Select-String '^TOTAL\|'
```

> **Com o defeito presente:** a instalação **termina bem** nos dois mundos. O que muda é a contagem
> de arquivos e, na sequência, a recusa do launcher. Por isso o `18.2` é um número, e não "instalou
> sem erro".

- Screenshot: `18-reinstalacao.png` · Origem: **`DB-22`** (`#021`)

---

# RODADA M2 - máquina COM QGIS de sistema

**Prepare:** snapshot limpa, instale **à mão** o **QGIS oficial 3.44.13**, abra-o uma vez, feche.
Só então instale o IMAN Terra.

> ### O que esta rodada substituiu, e por quê
> As antigas **M2a** e **M2b** mediam a **detecção**: qual QGIS o instalador pulava e qual o
> launcher escolhia entre duas instalações rivais. **A detecção não existe mais** (commit `a1b0c37`,
> fatia `#019`), e com ela morreram o `DB-16` (o ramo "já instalado: PULANDO"), a leitura do log do
> Inno atrás dessa linha e a necessidade de uma rival `3.44.12` que ordenasse antes por texto.
>
> A pergunta que sobrou é a que realmente importa para quem já usa QGIS: **o produto se mete com o
> QGIS da máquina?** A resposta tem de ser não, nos dois sentidos, e é isso que se mede aqui.

## 19. O produto ignora o QGIS da máquina e abre o dele

**Faça:** com o IMAN Terra instalado e **aberto**, rode:

```powershell
Get-Process qgis-ltr-bin, qgis-bin -ErrorAction SilentlyContinue | Select-Object Id, Path
```

| # | Asserção | Resultado |
|---|---|---|
| 19.1 | O processo do QGIS que subiu está **dentro de `{app}\qgis`**: `________________________________` | `PASS / FAIL / N/E` |
| 19.2 | **Nenhum** processo aponta para `C:\Program Files\QGIS 3.44.13` | `PASS / FAIL / N/E` |
| 19.3 | O QGIS do usuário **continua abrindo** pelo atalho dele, com o perfil dele | `PASS / FAIL / N/E` |
| 19.4 | `%APPDATA%\QGIS` continua byte-idêntico ao baseline (`assert-bl3.ps1`) | `PASS / FAIL / N/E` |
| 19.5 | Desinstalar o IMAN Terra **não** remove nem altera `C:\Program Files\QGIS 3.44.13` | `PASS / FAIL / N/E` |

> **O caminho aparece encurtado, e isso é normal.** O `o4w_env.bat` deriva a raiz em forma 8.3, então
> o executável costuma sair como `C:\Users\FRANCI~1\AppData\Local\Programs\IMANTE~1\qgis\bin\...`.
> **Compare pela forma que apareceu**, não presuma a longa. Se ficar em dúvida, o `19.2` decide: o
> que não pode é o caminho conter `Program Files`.

> **Com o defeito presente:** se o produto voltasse a procurar QGIS na máquina, ele **abriria**, e
> abriria bem: o QGIS de sistema é o mesmo 3.44.13. Tudo pareceria certo, e o produto teria deixado
> de ser autocontido sem nenhum sinal na tela. Só o caminho do processo distingue os dois mundos.

- Screenshot: `19-m2-processo.png` · Caso: **M2** · Invariante: **BL-3**

---

# RODADA M3 - atualizar de uma versão anterior

**Prepare:** snapshot limpa. Instale uma **versão anterior** do IMAN Terra, abra uma vez para o
perfil nascer, e feche. Se não houver instalador anterior à mão, semeie o perfil velho pelo helper,
com o `perfil-velho-ba58d14.zip` preparado no `§0.6`.

## 20. A reconciliação do perfil velho - estado (c), o único que pode errar

> ### ⚠ Este passo substitui o antigo `§15`, que estava STALE desde a `#030`
> O passo antigo media um defeito: *"o launcher só copia o `profile-template` no primeiro run, então
> perfil que já existe nunca recebe template novo"*. Ele mandava esperar **FAIL**.
>
> **O defeito foi consertado** (`DB-26`, fatia `#030`): o launcher **reconcilia** o perfil a cada
> abertura, com fronteira declarada em `profile-template\PERFIL-DO-PRODUTO.json` e merge de 3 vias
> contra a base registrada em `.iman-terra\base.json`. **O esperado agora é PASS**, e quem seguisse a
> instrução antiga registraria um FAIL falso.

### 20A. Semente `ba58d14` - tema e plugin novos CHEGAM

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\assert-reconciliacao.ps1 -Semear "$env:USERPROFILE\Desktop\perfil-velho-ba58d14.zip" -Rotulo 20A-antes
```

**`E.1` - confira o baseline ANTES de abrir o produto.** O helper imprime estes números. Se algum
não bater, **PARE E REFAÇA**: um perfil que já sai igual ao template novo não prova nada e ainda
alarma.

| # | Baseline exigido | Medido | Resultado |
|---|---|---|---|
| 20.1 | `RAIOS58` = **14** | `______` | `PASS / FAIL` |
| 20.2 | `RAIOS2` = **0** | `______` | `PASS / FAIL` |
| 20.3 | `SUFIXO` = **0** | `______` | `PASS / FAIL` |
| 20.4 | `ARQUIVOS` = **3 de 10** (menos que o total) | `__ de __` | `PASS / FAIL` |
| 20.5 | `BASE` = **AUSENTE** | `__________` | `PASS / FAIL` |

**Agora abra o IMAN Terra pelo atalho**, deixe carregar, **feche**, e confira:

```powershell
.\assert-reconciliacao.ps1 -Rotulo 20A-depois
```

| # | Asserção | Medido | Resultado |
|---|---|---|---|
| 20.6 | `RAIOS58` = **0** | `______` | `PASS / FAIL / N/E` |
| 20.7 | `RAIOS2` = **20** | `______` | `PASS / FAIL / N/E` |
| 20.8 | `SUFIXO` = **3** | `______` | `PASS / FAIL / N/E` |
| 20.9 | `ARQUIVOS` = **10 de 10**, `SOBRAS` = **0** | `__ de __` | `PASS / FAIL / N/E` |
| 20.10 | `BASE` existe, com `template_digest` | `__________` | `PASS / FAIL / N/E` |
| 20.11 | Na tela: o título termina em ` - IMAN Terra` e **não** contém `QGIS` como autodesignação | | `PASS / FAIL / N/E` |
| 20.12 | Abra e feche **outra vez**: os números não mudam (idempotência) | | `PASS / FAIL / N/E` |

> **O `20.12` é parte do passo, não um extra.** É ele que mostra que a reconciliação não fica
> reescrevendo o perfil a cada abertura. Sem ele, um conserto que reaplicasse tudo sempre passaria.

### 20B. Semente `8cc4d5e^` - obsoletos SAEM e o CRS se corrige

> **Este é o sub-passo que cobre o defeito mais caro do produto.** Um perfil de julho tem
> `EPSG:4674` cravado como CRS padrão. O QGIS **não reclama** de CRS errado: ele desenha. Se a
> reconciliação não corrigir essa chave, a medição sai errada sem aviso nenhum, e vai para dentro
> de um memorial descritivo.

```powershell
.\assert-reconciliacao.ps1 -Semear "$env:USERPROFILE\Desktop\perfil-velho-pre0707.zip" -Rotulo 20B-antes
```

| # | Baseline exigido (`E.1`) | Medido | Resultado |
|---|---|---|---|
| 20.13 | `OBSOLETOS` = **2** (`QGIS/iman-theme.qss` e `resources/logo.png`) | `______` | `PASS / FAIL` |
| 20.14 | `CRS` = **`EPSG:4674`** nos dois campos | `__________` | `PASS / FAIL` |
| 20.15 | `CHAVES` = **1 ausente, 2 com outro valor** | `______` | `PASS / FAIL` |
| 20.16 | `ARQUIVOS` = **2 de 10** | `__ de __` | `PASS / FAIL` |

**Abra o IMAN Terra, feche, e confira:**

```powershell
.\assert-reconciliacao.ps1 -Rotulo 20B-depois
```

| # | Asserção | Medido | Resultado |
|---|---|---|---|
| 20.17 | `OBSOLETOS` = **0**: os dois arquivos **sumiram** do perfil | `______` | `PASS / FAIL / N/E` |
| 20.18 | `CRS` = **`EPSG:31984`** nos dois campos | `__________` | `PASS / FAIL / N/E` |
| 20.19 | `CHAVES` = **0 ausentes, 0 com outro valor** (a `[UI] Customization\enabled` chegou) | `______` | `PASS / FAIL / N/E` |
| 20.20 | `ARQUIVOS` = **10 de 10**, `SOBRAS` = **0** | `__ de __` | `PASS / FAIL / N/E` |
| 20.21 | Na barra de status, o SRC exibido é **`EPSG:31984`** | `__________` | `PASS / FAIL / N/E` |

> **Os valores dos baselines `20.1` a `20.5` e `20.13` a `20.16` foram MEDIDOS**, não estimados:
> saíram deste mesmo helper rodando na bancada em 2026-09-20, contra o produto `0.3.0-5f7a1cb`
> instalado. Se a sua rodada usar outro build, os números do **depois** seguem o template daquele
> build; os do **antes** são propriedade do commit semeado e não mudam.

> **Com o defeito presente:** com o launcher de antes da `#030`, o produto **abre normalmente** e
> nada na tela grita. O usuário segue com o tema velho, o plugin velho e, no caso do `20B`, com o
> **CRS errado**. É nos números do "depois" que os dois mundos diferem, e em lugar nenhum mais.

> **Se a versão anterior foi instalada de verdade** (em vez de semeada pelo helper), acrescente:
> a instalação nova **não** pode criar um segundo perfil, e o `%APPDATA%\InstitutoIMAN` tem de ser
> o **mesmo** diretório de antes.

- Screenshots: `20a-perfil-velho-antes.png`, `20b-perfil-velho-depois.png`, `20c-crs-corrigido.png`
- Caso: **M3** · Origem: **`DB-26`** (`#030`), medido a partir de `{app}` pela **`#033`**

---

# RODADA M4 - a instalação é cancelada no meio

**Prepare:** snapshot limpa, sem QGIS, sem IMAN Terra.

## 21. Cancelar é permitido; deixar sujeira não

> ### O que mudou desde a versão anterior deste caso
> O caso antigo forçava a falha **do MSI encadeado do QGIS** (encher o disco, matar o `msiexec`,
> provocar o `1618`) e media se o nosso instalador abortava antes de tocar em qualquer coisa. **Não
> há mais MSI encadeado**, então esses três caminhos deixaram de existir.
>
> O que sobrou, e continua valendo, é a pergunta: **uma instalação interrompida no meio da cópia
> deixa a máquina como estava?** A cópia agora dura o suficiente para o cancelamento ser realista:
> são ~2,2 GB escritos pelo próprio Inno.

**Faça:** inicie a instalação e, **durante a barra de progresso da cópia**, clique em **Cancelar**
e confirme. Anote em que ponto (percentual aproximado) você cancelou.

| # | Asserção | Resultado |
|---|---|---|
| 21.1 | Apareceu uma mensagem **em português** dizendo que a instalação foi cancelada ou não foi concluída | `PASS / FAIL / N/E` |
| 21.2 | `%LOCALAPPDATA%\Programs\IMAN Terra` **não existe** (ou está vazia) | `PASS / FAIL / N/E` |
| 21.3 | **Nenhum** atalho no Menu Iniciar | `PASS / FAIL / N/E` |
| 21.4 | **Nenhuma** entrada em Configurações -> Aplicativos | `PASS / FAIL / N/E` |
| 21.5 | `%APPDATA%\InstitutoIMAN` **não** foi criado | `PASS / FAIL / N/E` |
| 21.6 | Espaço em disco voltou ao que era (tolerância de alguns MB) | `RELATADO` |
| 21.7 | Ponto em que cancelou: `______ %` | `RELATADO` |

```powershell
Test-Path (Join-Path $env:LOCALAPPDATA 'Programs\IMAN Terra')
Test-Path (Join-Path $env:APPDATA 'InstitutoIMAN')
Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' |
    Where-Object DisplayName -like 'IMAN Terra*'
```

> **O `21.5` é o que não pode falhar.** O perfil isolado só nasce quando o **launcher** roda, e o
> launcher só roda depois de instalar. Se `%APPDATA%\InstitutoIMAN` existir depois de um
> cancelamento, alguma coisa rodou fora de hora.

> **Com o defeito presente:** uma instalação que deixasse `{app}` pela metade **não avisaria nada**.
> O usuário veria o atalho, clicaria, e cairia na tela de integridade do `§16`, que é a recusa certa
> pelo motivo errado. `21.2` a `21.4` são o que separa "abortou limpo" de "abortou e mentiu".

- Screenshot: `21-m4-cancelado.png` · Caso: **M4**

---

# Fechamento

## Coletar o ambiente e a procedência

```powershell
cd $env:USERPROFILE\Desktop\bl7
.\collect-evidence.ps1
```

Gera `Desktop\bl7-evidence\RESULT-esqueleto.md` com Windows, resolução, escala, sessão de
administrador, diretório de instalação, **procedência do build instalado** (`BUILD_ID.txt`), QGIS
embarcado, QGIS de sistema porventura presente e estado do perfil isolado.

**Depois:** preencha o `RESULT.md` colando esses dados, os resultados deste checklist e os
screenshots.

## Placar obrigatório

| | |
|---|---|
| Passos **com evidência** (`PASS` + `FAIL`) | `______ de 21` |
| Passos `N/E` | `______` - **liste quais e por quê** |
| Rodadas concluídas | `M1 ☐ · M2 ☐ · M3 ☐ · M4 ☐` |

> **Um checklist com muitos `N/E` não é um checklist reprovado: é um checklist incompleto**, e
> precisa dizer isso em voz alta. O que **não** pode acontecer é `N/E` virar silêncio, e silêncio
> virar "deve estar bom".

## Os três estados da reconciliação, num lugar só

Para não se perder entre as rodadas, o `DB-26` é coberto assim:

| estado | onde | esperado |
|---|---|---|
| **(a) perfil ausente** | `§11`, rodada M1 | `SEMEADO`: perfil igual ao template instalado, `base.json` gravada |
| **(b) perfil igual** | `§14`, rodada M1 | `NADA_A_FAZER`: a abertura não escreve no perfil |
| **(c) perfil velho divergente** | `§20A` e `§20B`, rodada M3 | `APLICADA`: o que é do produto chega, o obsoleto sai, o que é do usuário fica |

**O (c) é o único que pode errar**, porque é o único em que há merge de 3 vias. Se faltar tempo,
é ele que não pode ficar `N/E`.

- Screenshot: `22-collect-evidence.png`
