# `tools/branding-acceptance` — teste de aceite da camada de marca

Sobe o **produto real** — a **árvore privada do QGIS que o produto carrega**, mais o perfil
`iman-distro` montado do `profile-template` e o `iman_startup.py` de verdade — e mede **widget vivo
e pixel**. Nasce da fatia `#017` (`D-IMAN-033`).

**O contrato que ele verifica:** `docs/branding-contract.md`.
**A primeira execução:** `docs/verify/017-aceite-marca/BASELINE-VERMELHA.md`.
**A baseline verde:** `docs/verify/018-conserto/BASELINE-VERDE.md`.
**O repontamento para a árvore do produto:** `docs/verify/021-reinstalar-sem-laco/README.md`.

## Pré-requisito: o produto INSTALADO

Desde a `#021` este harness **não sobe nenhum QGIS de sistema**. Ele sobe

```
%LOCALAPPDATA%\Programs\IMAN Terra\qgis\bin\qgis-ltr.bat
```

e **recusa** qualquer raiz sob `%ProgramFiles%`. Se o IMAN Terra não estiver instalado, o
orquestrador **aborta** — não existe aceite sem produto.

**Por que isso importa, e não é detalhe de caminho.** Até a `#020` o harness exigia
`C:\Program Files\QGIS 3.44.13` instalado, e `installer\New-ArvoreQgis.ps1` exige que essa mesma
instalação **não** exista. Instalar para testar desarmava o build; desinstalar para buildar
desarmava o teste. O produto não precisa de nenhum dos dois — ele carrega o próprio QGIS.

**O `.bat`, não o `.exe`:** é o `qgis-ltr.bat` que chama o `o4w_env.bat`, que deriva
`OSGEO4W_ROOT` de `%~dp0`, zera o `PATH` herdado e monta `PROJ_DATA`/`GDAL_DATA`/`PYTHONHOME`/
`QT_PLUGIN_PATH`. É o **mesmo caminho que o launcher do produto usa**.

**A procedência é conferida de dentro do processo.** O `E.1` valida que `sys.executable`,
`prefixPath`, `pkgDataPath` e `OSGEO4W_ROOT` caem dentro da árvore do produto, e que **nenhum**
caminho do ambiente está sob `%ProgramFiles%`. Sem isso, "rodou contra o produto" seria afirmação
do orquestrador sobre si mesmo.

## Rodar

```powershell
cd tools\branding-acceptance

# 1a execucao - perfil NOVO, suite completa
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1

# 2a execucao - perfil REAPROVEITADO (o unico caminho que veria o D7)
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1 -ReusarPerfil -Fase segunda

# descoberta: despeja os nomes de objeto do QGIS (nao e o aceite)
powershell -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Aceite.ps1 -Sonda discover.py
```

Saída em `%LOCALAPPDATA%\InstitutoIMAN\_aceite017\saida\`: `aceite.json`, `aceite-segunda.json` e
`shots\`.

## Arquivos

| arquivo | papel |
|---|---|
| `Invoke-Aceite.ps1` | orquestrador: monta o perfil novo, **semeia um recente real**, sobe o QGIS **do produto** com `--code`, confere a procedência do processo, espera a saída, encerra |
| `acceptance_probe.py` | as asserções `A01…A12` + `M-D11`, rodando dentro do QGIS |
| `discover.py` | passada de descoberta — nomes de objeto, docks, status bar, menus |

## As três regras que este teste segue

1. **Asserção sobre widget vivo e pixel, nunca sobre string de stylesheet.**
   Não vale `"titlebar-close-icon: none" not in qss`. Vale: o botão de fechar **desenha pixel**.

2. **`C.2` — toda asserção responde *"o que ela devolve COM o defeito presente?"***
   O campo `se_quebrado` de cada resultado carrega essa resposta. Se ela não muda entre produto são
   e produto quebrado, a asserção não é evidência. **Quatro asserções foram reescritas** por isso
   (`A04`, `A08`, `A07` na `#018`; `A08` de novo na `#021`) — o histórico está em comentário no
   código, com o número que a versão anterior devolvia.

   > **`A08`, `#021`:** a metade que procurava as strings das constantes `RECENTS`/`TEMPLATES`/
   > `CHIPS` passava por **tautologia** depois que as constantes foram removidas — ela era cega a
   > um dataset fabricado **novo**, porque foi escrita contra a *instância* do defeito, não contra
   > a *classe*. O critério agora é **procedência**: todo item exibido em "Projetos recentes" tem
   > caminho que **existe em disco** e está na **lista de recentes do próprio QGIS**, com o mesmo
   > título. A contagem de strings continua medida e relatada, sob `HISTORICO_fora_do_criterio`,
   > mas **não decide mais nada**.
   >
   > Para a asserção não passar por **lista vazia**, o orquestrador semeia — antes do arranque, no
   > `QGIS3.ini` do perfil novo — um recente **real**: `app\demo\welcome.qgz`. A asserção então
   > exige **presença** ("o semeado chegou à tela"), e não só ausência de invenção. A semente entra
   > antes do arranque porque a home é construída **uma única vez**, no load do plugin.

3. **`E.1` — baseline validado antes de asserir.**
   Perfil certo, plugin vivo, QSS anexado, home instalada. Se qualquer um falhar, o teste **aborta**
   e não emite asserção. Um aceite verde sobre um build onde a marca nunca subiu não é aprovação.

## `BL-3` — onde ele escreve

Só em `%LOCALAPPDATA%\InstitutoIMAN\_aceite017\`. O orquestrador **recusa rodar** se o destino cair
em `%ProgramFiles%` ou `%APPDATA%\QGIS`.

## Quando o QGIS mudar de versão

Os nomes de objeto (`mCoordsLabel`, `qt_dockwidget_closebutton`, `QgsWelcomePage`) foram **medidos**
com o `discover.py` na `3.44.13`, não adivinhados. Se uma asserção virar `N/E` com
`'... nao encontrado'`, rode o `discover.py` de novo e reancore.

O `A08` ancora também num nome **nosso**: o `objectName` `rec` dos cartões de recente
(`dashboard._item_recente`). Se ele mudar, nenhum item é encontrado — e a exigência de **presença**
do recente semeado **reprova alto**, em vez de passar em silêncio. É o comportamento desejado.

## Instrumento se altera em commit separado

Regra da `#018`, ainda valendo: mudança no harness vai em **commit próprio**, e mudança de
**critério** é **declarada** no laudo com o número antes e depois. Um aceite que passou a caber no
build é um aceite desligado.
