# `tools/branding-acceptance` — teste de aceite da camada de marca

Sobe o **produto real** (QGIS instalado + perfil `iman-distro` + `iman_startup.py` de verdade) e
mede **widget vivo e pixel**. Nasce da fatia `#017` (`D-IMAN-033`).

**O contrato que ele verifica:** `docs/branding-contract.md`.
**A primeira execução:** `docs/verify/017-aceite-marca/BASELINE-VERMELHA.md`.

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
| `Invoke-Aceite.ps1` | orquestrador: monta o perfil novo, sobe o QGIS com `--code`, espera a saída, encerra |
| `acceptance_probe.py` | as asserções `A01…A12` + `M-D11`, rodando dentro do QGIS |
| `discover.py` | passada de descoberta — nomes de objeto, docks, status bar, menus |

## As três regras que este teste segue

1. **Asserção sobre widget vivo e pixel, nunca sobre string de stylesheet.**
   Não vale `"titlebar-close-icon: none" not in qss`. Vale: o botão de fechar **desenha pixel**.

2. **`C.2` — toda asserção responde *"o que ela devolve COM o defeito presente?"***
   O campo `se_quebrado` de cada resultado carrega essa resposta. Se ela não muda entre produto são
   e produto quebrado, a asserção não é evidência. **Três asserções foram reescritas** por isso
   (`A04`, `A08`, `A07`) — o histórico está em comentário no código, com o número que a versão
   anterior devolvia.

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
