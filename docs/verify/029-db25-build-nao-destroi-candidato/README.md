# `#029`: um build de branch não pode destruir o candidato a release (`DB-25`)

**Executado em:** 2026-09-15 · branch `feat/029-db25-build-de-branch-nao-destroi-candidato` · base `develop` = `733e129`
**Bancada:** Windows 11 Pro 10.0.26200 · PowerShell 5.1 · Inno Setup 7.1.0 · sem QGIS de sistema
**Tipo:** higiene de build + guarda que sabe reprovar. **Nada que entra no `.exe` mudou**: `[Files]` do `.iss` e formato do `BUILD_ID.txt` intactos; o `.iss` inteiro não foi tocado.

> ### Declaração para o gate (`P0.6`)
>
> **O registro do canônico mudou de caminho.** A exceção do `P0.6` nomeia `installer/dist/BUILD_INFO.txt`.
> Com esta fatia, quem compila um canônico commita direto na `develop`:
>
> - `installer/canonico/<versao>-<commit>/BUILD_INFO.txt`
> - `installer/canonico/VIGENTE.txt`
> - a evidência daquele build em `docs/verify/<fatia>/**`
>
> A emenda é do arquiteto. Nesta fatia nada foi direto para a `develop`: o registro migrado do `327d9ee` entra pelo PR.

---

## 0. Legenda (`E.6`)

| marca | significa |
|---|---|
| **medido** | obtido nesta bancada, nesta sessão, com evidência em `evidencia/` |
| **relatado** | veio do briefing ou de outra sessão, identificado como tal |
| **`N/E`** | não exercitado, nomeado, com o motivo |

---

## 1. Passo 0: o candidato protegido antes de qualquer build (**medido**)

| | valor |
|---|---|
| original, antes de tudo | `installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe` · SHA-256 `38DA4709FB121C89C6A52FD96A107C5502316FBDD1BFEC07CE8B2809F68B73E7` · 512.808.129 bytes |
| registro | working tree idêntica ao blob de `af2eef5` (`git hash-object` `7ad4079a…`) |
| **cópia fora do repo** | **`D:\_iman-terra-candidatos-protegidos\0.3.0-327d9ee\`** (`.exe` + `BUILD_INFO.txt`) |
| SHA na cópia | `38DA4709…B73E7` · 512.808.129 bytes; registro com o mesmo `hash-object --no-filters` do original |
| reconferência antes da migração | original e cópia, os dois `38DA4709…B73E7` |

**Pré-condição de extração, conferida antes do primeiro build:** nenhum `QGIS*` em Program Files,
nenhuma entrada QGIS na ARP (HKLM 64, HKLM 32, HKCU), `ProductState({740D7A65-…})` = `-1`, nenhum
processo `qgis` nem `msiexec`. Todo build desta fatia rodou com `-ReusarArvore -SemRede`, e a guarda
confere que a árvore está visível antes de cada um (sem ela o extrator cairia no `msiexec /a`).

Números e comandos: `evidencia/passo0-e-migracao.txt`.

---

## 2. O desenho

| # | requisito | como ficou |
|---|---|---|
| **R1** | nome com identidade; canônico e branch se distinguem | canônico `Instituto-IMAN-IMAN-Terra-Setup-<versao>-<commit>.exe`; branch `...-<versao>-<commit>-nao-canonico.exe`. A base continua vindo do `OutputBaseFilename` do `.iss`; a identidade entra pelo `/O` e `/F` do ISCC (testados nesta bancada antes de usar) |
| **R2** | falha não remove nada que não seja dela | o alvo passou a ser **a pasta desta identidade**. Canônico: a pasta não pode existir (recusa `exit 3`, conferida de novo antes de compilar); a execução a cria e, se o ISCC falhar, é ela que sai. Branch: a pasta é a do build anterior da mesma versão, commit e branch; sai antes de compilar. **A intenção antiga fica garantida pelo nome:** falha nunca deixa nada com o nome desta identidade, e um artefato velho de outro commit não tem como passar por este, porque o commit está no nome |
| **R3** | registro do canônico fora do alcance de branch; "qual é o candidato?" num lugar só | canônico em `installer/canonico/<versao>-<commit>/`, rastreado; branch em `installer/dist/nao-canonico/<versao>-<commit>-<branch>/`, fora do git. Build de branch não calcula caminho sob `installer/canonico/`, e se um dia calcular recusa (`exit 3`). **O candidato vigente se lê em `installer/canonico/VIGENTE.txt`**, que só um canônico que terminou reescreve |
| **R4** | dois canônicos da mesma versão coexistem | o commit está na pasta e no nome; e canônico **recusa** sobrescrever canônico da mesma identidade (rebuild do mesmo commit dá outro SHA, `D-IMAN-032`) |
| **R5** | `327d9ee` migrado sem rebuild | §4 |
| **R6** | o registro viaja com o `.exe` | cada pasta de identidade carrega o `.exe` **e** o `BUILD_INFO.txt` dele. Entregar o candidato é entregar a pasta |

**Uma consequência deliberada:** a guarda de árvore limpa perdeu a exceção do `BUILD_INFO.txt`. O registro
de branch não suja nada (está fora do git). O de canônico suja **de propósito**: enquanto quem compilou não
o commitar, nenhum outro build roda. Era essa exceção que deixava o registro sujo viajar no próximo commit de
laudo de qualquer fatia (mecanismo 3 do briefing, `72595c0`).

**Recusa de identidade existente, medida** (smoke sem compilação, clone descartável em `18d2534`, pasta
`installer/canonico/0.3.0-18d2534/` com um `.exe` ignorado e árvore limpa): `exit 3` em 2,0 s, nomeando a
pasta e o conteúdo, antes de estagiar o payload; o arquivo pré-existente saiu byte a byte igual.
Log cru: `evidencia/smoke-canonico-recusa-identidade-existente.log`.

---

## 3. A guarda e a matriz (`C.2`, `S.4`)

`tools/test-build-preserva-canonico.ps1 -Ref <commit>` põe à prova o `build.ps1` **daquele commit**.

- **Asserção:** SHA-256 do `.exe` canônico e SHA-256 dos **bytes** do registro, antes e depois. Não "existe".
- **Onde está o canônico (`P0.8`):** a guarda não presume caminho. Lê as linhas `Artefato :` e `Info :` que o
  `build.ps1` publica ao terminar. É por isso que a mesma guarda roda contra o `733e129` e contra o conserto.
- **Isolamento:** clones descartáveis em `D:\_iman-terra-guarda-db25\`, fora do repo; cópia própria da
  árvore do QGIS por rodada (o teste do launcher renomeia pastas da árvore que recebe, e o extrator remove o
  destino quando não reaproveita: a árvore da bancada nunca fica ao alcance); payload por hardlink.
- **Estado 4 é a semente:** o primeiro build do repo, num clone sem `.exe` e sem registro canônico rastreado.
  Os estados 1 a 3 partem dele, restaurado de um cofre, com **`E.1` antes de cada rodada** (SHA do `.exe` ==
  cofre == declarado no registro; bytes do registro == cofre). Estado não exercitado é `ABORTADO`, `exit 2`.
- **Indução do estado 2:** `-IsccPath` aponta para um `.cmd` gerado pela guarda em tempo de execução. Ele
  repassa a sonda de versão ao ISCC real e, na chamada de compilação (a que começa por `/Q`, depois do ponto de
  remoção), grava um marcador e sai com 1. A guarda só aceita o estado se o marcador existir **e** o build sair
  `4`. Nada no `build.ps1` nem no `.iss` foi tocado para induzir.

As duas rodadas usaram a mesma guarda, SHA-256 `899DBF106F005D1E241AF88F0567A3ED56881061AC326AD49D9164D27D32982B`
(o do arquivo commitado em `521d610`), cada uma com sua cópia da árvore (37.337 arquivos = manifesto).
Saída crua integral: `evidencia/guarda-733e129.out` e `evidencia/guarda-18d2534.out`.

### 3.0 A matriz (**medido**)

| # | estado | antes (`733e129`) | depois (`18d2534`) |
|---|---|---|---|
| 1 | há canônico, build de branch **com sucesso** | **`FAIL`** | **`PASS`** |
| 2 | há canônico, build de branch que **falha no ISCC** | **`FAIL`** | **`PASS`** |
| 3 | há canônico, **segundo canônico da mesma versão** | **`FAIL`** | **`PASS`** |
| 4 | **não há canônico nenhum** | `PASS` | `PASS` |
| | **exit da guarda** | **`1`** (15:16:26) | **`0`** (15:16:03) |

Seis compilações reais, as duas rodadas em paralelo: estado 4 em 1.848,6 s e 1.757 s, estado 1 em 1.249,4 s e
1.170,6 s, estado 3 em 714,9 s e 680,6 s. O estado 2 não compila (11,9 s e 12,2 s).

### 3.1 Antes: `build.ps1` de `733e129` (saída crua, recortada)

```
  [PASS] estado 4 - nao ha canonico: o primeiro build do repo passa sem falso positivo
    build [e4-primeiro-build-canonico]: exit 0 em 1848,6 s
      Artefato publicado: ...\e4-semente\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe
      Info publicado    : ...\e4-semente\installer\dist\BUILD_INFO.txt
         ok   o registro descreve o artefato ao lado (SHA-256 declarado == calculado)
              antes : EC035335FF4D097883FC0C35BD929F637843E43A96948C6345480F2B07257F91
              depois: EC035335FF4D097883FC0C35BD929F637843E43A96948C6345480F2B07257F91

  -- estado 1: ha canonico; build de branch com sucesso --
    E.1 ok: o canonico de referencia confere antes da rodada
            exe EC035335FF4D097883FC0C35BD929F637843E43A96948C6345480F2B07257F91 == cofre == declarado no registro
            reg 74F7199E818D15DB81ED4D1449A6FF11492919272F5B8D2430BB0AB0B44A6073 == cofre
    build [e1-build-de-branch]: exit 0 em 1249,4 s
      Artefato publicado: ...\e1-branch-sucesso\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe
  [FAIL] estado 1 - ha canonico; build de branch com sucesso
         FAIL SHA-256 do .exe canonico inalterado
              antes : EC035335FF4D097883FC0C35BD929F637843E43A96948C6345480F2B07257F91
              depois: C9B5D0FB3B365DF8E2C38113E114E4B947308162C487B1DEBFDD577BC955B3B3
         FAIL SHA-256 dos bytes do registro canonico inalterado
              antes : 74F7199E818D15DB81ED4D1449A6FF11492919272F5B8D2430BB0AB0B44A6073
              depois: 7337568EDA8F3A2699295CAABF272EF4AF4104206B7CEB6746ED1483D2944260
         FAIL R1: o artefato de branch sai em OUTRO caminho
         FAIL R1: canonico e branch se distinguem pelo NOME
              antes : Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe
              depois: Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe
         FAIL R1: o nome do artefato de branch carrega versao e commit curto

  -- estado 2: ha canonico; build de branch que falha no ISCC --
    E.1 ok: o canonico de referencia confere antes da rodada
    build [e2-build-de-branch-iscc-falha]: exit 4 em 11,9 s
    inducao confirmada: marcador presente, build exit 4
  [FAIL] estado 2 - ha canonico; build de branch que falha no ISCC
         FAIL SHA-256 do .exe canonico inalterado
              antes : EC035335FF4D097883FC0C35BD929F637843E43A96948C6345480F2B07257F91
              depois: <ausente>
         ok   SHA-256 dos bytes do registro canonico inalterado
```

**O estado 2 reproduz o mecanismo 2 do briefing, isolado:** o registro sobrevive byte a byte e o `.exe`
canônico some. Foi a remoção prévia, e o ISCC que falhou depois não devolveu nada.

### 3.2 Depois: `build.ps1` desta fatia (saída crua, recortada)

```
  [PASS] estado 4 - nao ha canonico: o primeiro build do repo passa sem falso positivo
    build [e4-primeiro-build-canonico]: exit 0 em 1757 s
      Artefato publicado: ...\e4-semente\installer\canonico\0.3.0-ee54672\Instituto-IMAN-IMAN-Terra-Setup-0.3.0-ee54672.exe
      Info publicado    : ...\e4-semente\installer\canonico\0.3.0-ee54672\BUILD_INFO.txt
         ok   o registro descreve o artefato ao lado (SHA-256 declarado == calculado)
              antes : BD0515F2B92C72CDC55FCB7AFDFE6DE0606BF939888BB9C7B72B000A40A0F3DE
              depois: BD0515F2B92C72CDC55FCB7AFDFE6DE0606BF939888BB9C7B72B000A40A0F3DE

  -- estado 1: ha canonico; build de branch com sucesso --
    E.1 ok: o canonico de referencia confere antes da rodada
            exe BD0515F2B92C72CDC55FCB7AFDFE6DE0606BF939888BB9C7B72B000A40A0F3DE == cofre == declarado no registro
            reg 7BDE6005DD4859B6EE248E40C5594D16DF6AF8BA94936539AA05DD16C875E0FA == cofre
    build [e1-build-de-branch]: exit 0 em 1170,6 s
      Artefato publicado: ...\e1-branch-sucesso\installer\dist\nao-canonico\0.3.0-6657bba-guarda-db25-branch\Instituto-IMAN-IMAN-Terra-Setup-0.3.0-6657bba-nao-canonico.exe
  [PASS] estado 1 - ha canonico; build de branch com sucesso
         ok   SHA-256 do .exe canonico inalterado
              antes : BD0515F2B92C72CDC55FCB7AFDFE6DE0606BF939888BB9C7B72B000A40A0F3DE
              depois: BD0515F2B92C72CDC55FCB7AFDFE6DE0606BF939888BB9C7B72B000A40A0F3DE
         ok   SHA-256 dos bytes do registro canonico inalterado
              antes : 7BDE6005DD4859B6EE248E40C5594D16DF6AF8BA94936539AA05DD16C875E0FA
              depois: 7BDE6005DD4859B6EE248E40C5594D16DF6AF8BA94936539AA05DD16C875E0FA
         ok   R1: o artefato de branch sai em OUTRO caminho
         ok   R1: canonico e branch se distinguem pelo NOME
              antes : Instituto-IMAN-IMAN-Terra-Setup-0.3.0-ee54672.exe
              depois: Instituto-IMAN-IMAN-Terra-Setup-0.3.0-6657bba-nao-canonico.exe
         ok   R1: o nome do artefato de branch carrega versao e commit curto

  -- estado 2: ha canonico; build de branch que falha no ISCC --
    E.1 ok: o canonico de referencia confere antes da rodada
    build [e2-build-de-branch-iscc-falha]: exit 4 em 12,2 s
    inducao confirmada: marcador presente, build exit 4
  [PASS] estado 2 - ha canonico; build de branch que falha no ISCC
         ok   SHA-256 do .exe canonico inalterado
              antes : BD0515F2B92C72CDC55FCB7AFDFE6DE0606BF939888BB9C7B72B000A40A0F3DE
              depois: BD0515F2B92C72CDC55FCB7AFDFE6DE0606BF939888BB9C7B72B000A40A0F3DE
         ok   SHA-256 dos bytes do registro canonico inalterado
```

### 3.3 Estado 3, as duas rodadas (saída crua, recortada)

Antes (`733e129`):

```
  -- estado 3: ha canonico; segundo canonico da mesma versao --
    E.1 ok: o canonico de referencia confere antes da rodada
    build [e3-segundo-build-canonico]: exit 0 em 714,9 s
      Artefato publicado: ...\e3-segundo-canonico\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe
  [FAIL] estado 3 - ha canonico; segundo canonico da mesma versao
         FAIL SHA-256 do .exe canonico inalterado
              antes : EC035335FF4D097883FC0C35BD929F637843E43A96948C6345480F2B07257F91
              depois: C004167C9E3EFB01A5CB6B2781FDD2B9ADF0C912190584EDE35D3F58C9A8CACD
         FAIL SHA-256 dos bytes do registro canonico inalterado
              antes : 74F7199E818D15DB81ED4D1449A6FF11492919272F5B8D2430BB0AB0B44A6073
              depois: 4B21E59C21759F3D814B660EDD33FCF561677ADB5A08956824A2A0298BD34FB3
         ok   R4: o registro do segundo canonico descreve o .exe dele
         ok   R4: o segundo diz 'Build canonico: SIM'
         FAIL R4: os dois canonicos coexistem (caminhos distintos, os dois no disco)
              antes : ...\e3-segundo-canonico\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe
              depois: ...\e3-segundo-canonico\installer\dist\Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe
EXIT=1  fim=2026-09-15T15:16:26.6451811-03:00
```

Depois (`18d2534`):

```
  -- estado 3: ha canonico; segundo canonico da mesma versao --
    E.1 ok: o canonico de referencia confere antes da rodada
    build [e3-segundo-build-canonico]: exit 0 em 680,6 s
      Artefato publicado: ...\e3-segundo-canonico\installer\canonico\0.3.0-42469cb\Instituto-IMAN-IMAN-Terra-Setup-0.3.0-42469cb.exe
  [PASS] estado 3 - ha canonico; segundo canonico da mesma versao
         ok   SHA-256 do .exe canonico inalterado
              antes : BD0515F2B92C72CDC55FCB7AFDFE6DE0606BF939888BB9C7B72B000A40A0F3DE
              depois: BD0515F2B92C72CDC55FCB7AFDFE6DE0606BF939888BB9C7B72B000A40A0F3DE
         ok   SHA-256 dos bytes do registro canonico inalterado
              antes : 7BDE6005DD4859B6EE248E40C5594D16DF6AF8BA94936539AA05DD16C875E0FA
              depois: 7BDE6005DD4859B6EE248E40C5594D16DF6AF8BA94936539AA05DD16C875E0FA
         ok   R4: o registro do segundo canonico descreve o .exe dele
              antes : 9C4CBE17C30BA2B202D3C28F2A9CD8DB045B9AB5F266D91D92BCDE978DF52998
              depois: 9C4CBE17C30BA2B202D3C28F2A9CD8DB045B9AB5F266D91D92BCDE978DF52998
         ok   R4: o segundo diz 'Build canonico: SIM'
         ok   R4: os dois canonicos coexistem (caminhos distintos, os dois no disco)
              antes : ...\e3-segundo-canonico\installer\canonico\0.3.0-ee54672\Instituto-IMAN-IMAN-Terra-Setup-0.3.0-ee54672.exe
              depois: ...\e3-segundo-canonico\installer\canonico\0.3.0-42469cb\Instituto-IMAN-IMAN-Terra-Setup-0.3.0-42469cb.exe
EXIT=0  fim=2026-09-15T15:16:03.6937631-03:00
```

### 3.4 Depois de todos os builds da fatia (**medido**, 2026-09-15 15:17)

| | |
|---|---|
| **`E.1` final do candidato** | migrado `installer\canonico\0.3.0-327d9ee\...-0.3.0-327d9ee.exe` e cópia do Passo 0: os dois `38DA4709FB121C89C6A52FD96A107C5502316FBDD1BFEC07CE8B2809F68B73E7`, 512.808.129 bytes |
| árvore do QGIS da bancada | 37.337 arquivos = manifesto; `share\proj\proj.db` presente |
| limpeza das guardas | clones, cópia da árvore e cofre removidos nas duas; sobram `logs\`, o marcador e o `.cmd` da indução (43 KB); zero junctions |
| guarda que rodou == guarda entregue | SHA do arquivo `899DBF10…` == blob de `521d610`, sem modificação desde 14:10:38, antes das duas rodadas |

---

## 4. O candidato migrado (`R5`, **medido**)

| | |
|---|---|
| caminho novo | `installer/canonico/0.3.0-327d9ee/Instituto-IMAN-IMAN-Terra-Setup-0.3.0-327d9ee.exe` |
| operação | rename no mesmo volume (`Move-Item`), sem rebuild; a origem deixou de existir |
| SHA-256 recalculado **no destino** | `38DA4709FB121C89C6A52FD96A107C5502316FBDD1BFEC07CE8B2809F68B73E7` |
| bytes · mtime | 512.808.129 · `2026-09-09T19:32:20` (inalterados) |
| registro | `git mv` para `installer/canonico/0.3.0-327d9ee/BUILD_INFO.txt` (o `git log --follow` chega a `af2eef5`) |
| campos iguais a `af2eef5` | SHA-256, Tamanho, ProductVersion, Commit, Commit (curto), Branch, **Build canonico: SIM**, Payload SHA-256, Data/hora do build |
| linhas alteradas | `Artefato` (nome novo) e a de `COMO CONFERIR NA VM`; mais uma nota de migração ao fim |
| `VIGENTE.txt` | aponta para `0.3.0-327d9ee`, SHA `38DA4709…B73E7` |

---

## 5. Consumidores do nome e do caminho (`H.1`, `P0.8`)

**De onde saiu a lista.** Primeiro, os pontos onde o `build.ps1` publica `$ArtifactName`, `$ArtifactPath`,
`$DistDir` e `$BuildInfo`: o arquivo que o ISCC grava, o `BUILD_INFO.txt` (linhas `Artefato` e
`COMO CONFERIR`), as linhas `Artefato :` e `Info :` do resumo, a mensagem do `Fail 4`, a varredura de
`.exe` antigos e a exceção da guarda de árvore limpa. Depois, para cada coisa publicada, quem a lê: busca
no repo pelo nome do artefato, pelo caminho `installer/dist`, por `BUILD_INFO` e por quem interpreta o
resumo do build, **com cada ocorrência lida**. Declaro o limite: não há manifesto de consumidores que o
sistema publique; a lista final é essa leitura, não um `grep` tomado como fato.

| consumidor | o que consome | mudou? |
|---|---|---|
| `installer/build.ps1`, guarda 3 | exceção `installer/dist/BUILD_INFO.txt` | **removida** (§2) |
| `installer/build.ps1`, fim | aviso de "instalador(es) antigo(s)" | **reescrito**: lista o legado solto em `installer\dist\` e manda levar a pasta do artefato |
| `.gitignore` | `installer/dist/*` + negação do `BUILD_INFO.txt` | **reescrito**: `installer/dist/` inteiro fora; `installer/canonico/**/*.exe` fora; registro canônico dentro |
| `tools/test-build-preserva-canonico.ps1` (novo) | linhas `Artefato :` e `Info :` | nasce lendo esse contrato; o `build.ps1` diz isso num comentário ao lado das linhas |
| `docs/verify/bl7-clean-vm/CHECKLIST.md:86` e `:521` | nome do `.exe` com `<versao>` | **mudou**: o placeholder ficou errado, virou `<versao>-<commit>`. Nada mais no checklist |
| `docs/verify/bl7-clean-vm/CHECKLIST.md:89`, `:91` | "o `BUILD_INFO.txt`" que chega junto | não mudou: continua certo, é o R6 |
| `docs/verify/bl7-clean-vm/RESULT.md:15` | `Setup-______.exe` | não mudou: a lacuna livre comporta o nome novo |
| `tools/test-reinstalacao.ps1:30` | exemplo de caminho | **mudou** para o candidato migrado |
| `tools/branding-acceptance/Invoke-Aceite.ps1:129` | mensagem `installer\dist\*.exe` | **mudou** para `installer\canonico\<versao>-<commit>\*.exe` |
| `README.md:50`, `:64-69` | caminho de saída e do registro | **mudou** |
| `README.md:84` | "`.exe` em `installer/dist/`" | não mudou: é o registro do smoke da fatia 1, numa seção datada ("QGIS LTR 3.44.9 standalone") que já é histórica inteira |
| `.memory/reference_qgis_profile_and_packaging.md:32` | saída em `installer/dist/` | **mudou** |
| `.memory/reference_build_environment.md:66` | emite `installer/dist/BUILD_INFO.txt` | **mudou** |
| `docs/RENAME_CHECKLIST.md:57` | `OutputBaseFilename` como nome do `.exe` | **mudou**: é a base; o build acrescenta a identidade; registros commitados não se renomeiam |
| `docs/distro-architecture.md:29` | árvore de `installer/` | **mudou** |
| `CLAUDE.md:47` | "saída `dist/`" | **mudou** |
| `.claude/commands/packaging.md:12` | `Setup-<versão>.exe` | **mudou** |
| `installer/iman-terra.iss:97` | `OutputBaseFilename` | não mudou: continua a base, lida pelo build |
| `docs/licencas/INVENTARIO.md:26` | "números vêm de `installer/dist/BUILD_INFO.txt`" | não mudou: citação de origem do `#020`, de um canônico anterior (instalador de 511.365.552 bytes, não o `327d9ee`). Está no histórico do git |
| `app/notices/SOURCE_CODE.md:27`, `LICENSE:25`, `THIRD_PARTY_NOTICES.md:37` | promessa de que o `BUILD_INFO.txt` acompanha o instalador | **não editados, por ordem do briefing** (`DB-6`). O R6 é o que torna a promessa cumprível |
| `app/.../iman_brand/brand.py:26,41` | prosa "o `BUILD_INFO.txt` do repo" | não mudou: entra no `.exe` (proibido), e continua verdadeira |
| `tools/branding-acceptance/acceptance_probe.py:948,1031` | a mesma prosa | não mudou: continua verdadeira |
| `docs/BRANDING_AND_LICENSE.md:46,48`, `tools/bl7/collect-evidence.ps1:270` | prosa sem caminho | não mudou |
| `docs/verify/0*/` | laudos anteriores | não mudam: são histórico |

---

## 6. Carona: o placar do tema vem da guarda

O `build.ps1` imprimia `(5 de 5 asse rcoes)` num literal, e a guarda roda 6 desde o `#027`. Mais: a própria
guarda escrevia `6 de 6` **noutro literal**. Trocar só o do build moveria o número de um literal para outro.

- `tools/test-tema-qss.ps1`: cada asserção se registra ao terminar; o veredito diz "N de M" contado.
- `installer/build.ps1`: lê "N de M" da saída da guarda. Exit 0 sem placar, ou com N ≠ M, é `Fail 7`.
- **Sensibilidade, medida:** adulterando um raio de 2px para 5px numa cópia do `style.qss`, a guarda sai `1`
  com `5 de 6 asse rcoes passaram.`; sem adulteração, `0` com `6 de 6`.
- **Nos builds reais da matriz:** o `build.ps1` de `733e129` imprime `(5 de 5 asse rcoes)`; o desta fatia,
  `(6 de 6 asse rcoes, placar da guarda)`.

---

## 7. STOP-AND-FLAG (`S.5`): onde o canônico mora fisicamente

**Não arbitro. Proponho e meço.**

**O que esta fatia resolve, dentro da bancada:** nenhum build, de branch ou canônico, escreve ou remove o
candidato. Isso é o requisito, e a matriz do §3 é a prova.

**O que ela não resolve, e é medido:**

| medido | valor |
|---|---|
| onde o candidato mora | `installer\canonico\0.3.0-327d9ee\`, **dentro do repo**, `.exe` ignorado pelo git |
| onde está a cópia do Passo 0 | `D:\_iman-terra-candidatos-protegidos\0.3.0-327d9ee\`, fora do repo |
| `C:` e `D:` | **o mesmo disco físico**: disco 0, NVMe `WD PC SN5000S`, 954 GB, mesmo número de série |
| cópias do candidato hoje | 2, **no mesmo disco, na mesma máquina** |

Consequência: as duas cópias caem juntas com uma falha do disco, com a perda da máquina, ou com uma limpeza
de `D:\_*`. Dentro do repo, o `.exe` também cai com um `git clean -fdx` (operação proibida nesta crew, mas
possível). E o `.exe` não é recuperável por rebuild: `D-IMAN-032`.

**Propostas, para quem decide operação:**

1. **Uma cópia fora desta máquina**, da **pasta** do candidato (`.exe` + `BUILD_INFO.txt`), assim que um
   canônico vira candidato. O destino (drive do Instituto, release privada, mídia externa) é decisão de
   operação e, no caso de release, de publicação: fora do escopo desta fatia.
2. **Quem faz a cópia e quem confere o SHA na cópia** precisa de dono nomeado. A conferência é a mesma do
   Passo 0: `Get-FileHash` no destino contra o `sha256=` do `VIGENTE.txt`.
3. **A cópia do Passo 0 fica onde está** até essa decisão. Não a movo nem a apago.

---

## 8. `origin/chore/build-info-canonico`

Um commit (`3803095`, 22/07) que só reescreve `installer/dist/BUILD_INFO.txt` com o registro do canônico
`0.2.0` de `5fee5e1`. Não é desenho, é um registro, e o `845d09e` já o substituiu na `develop`.
**O desenho novo a torna obsoleta:** o arquivo que ela edita deixou de existir. **Não foi apagada.**

---

## 9. O que esta fatia NÃO testou

| não testado | por quê |
|---|---|
| **VM limpa (BL-7)** | fora de escopo; esta fatia só dá ao BL-7 um candidato que sobrevive |
| **Build canônico do desenho novo na `develop` real** | por ordem do briefing não há build canônico pós-merge. O desenho novo compilou canônicos só em clones descartáveis (estados 4 e 3) |
| **Instalar a partir do candidato migrado** | não reinstalei: renomear não muda bytes, e o SHA no destino é o de `af2eef5` |
| **A recusa "branch calculou destino sob `installer/canonico/`"** | inalcançável por construção (raízes diferentes); nunca disparou, e não adulterei o cálculo para vê-la disparar. `N/E` |
| **Build interrompido no meio do ISCC** (Ctrl+C, queda de energia) | o que sobra é uma pasta de identidade sem `BUILD_INFO.txt`; a recusa que ela provoca foi medida só com um `.exe` de mentira (§2) |
| **Dois builds ao mesmo tempo no mesmo repo** | não medido |
| **Nome de branch longo ou com caracteres fora de ASCII** | o slug troca por `-`, mas o limite de 260 caracteres da pasta `nao-canonico` não foi medido |
| **Abreviação do commit maior que 7** | o nome usa o mesmo `commit_curto` do `BUILD_ID.txt`; se o git passar a abreviar com 8, o nome acompanha. Não exercitado |
| **`VIGENTE.txt` depois de um segundo canônico** | no estado 3 o ponteiro troca, e a guarda não assere sobre ele: assere que o primeiro canônico continua intacto |
| **A pasta do candidato viajando por download** | publicação e nome público de download estão fora de escopo |
| **A guarda noutro volume** | o payload entraria por cópia e não por hardlink: caminho não exercitado |

---

## 10. Dívidas com dono (`H.2`)

| dívida | dono proposto |
|---|---|
| Emendar a exceção do `P0.6` para os dois caminhos novos (topo deste laudo) | arquiteto |
| Onde o candidato mora fisicamente e quem copia (§7) | operação, via arquiteto |
| `installer\dist\` ainda tem os `.exe` de `0.1.0` (`55775881…`) e `0.2.0` (`A32476BE…`, o canônico `845d09e`, confere) no layout antigo e sem registro ao lado; o do `0.2.0` só existe no histórico do git | crew, em fatia que o arquiteto emitir; esta não os tocou |
| Os notices prometem que o `BUILD_INFO.txt` acompanha o instalador, e o `.iss` não o embarca. O R6 torna a promessa cumprível, sem editá-los | `DB-6` |
| Reescrita do `CHECKLIST.md` do BL-7 (aqui mudaram só as duas linhas do placeholder) | fatia própria |
