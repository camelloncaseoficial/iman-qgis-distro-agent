# `tools/bl7/` — helpers da verificação em VM limpa (BL-7)

Copie **esta pasta inteira** para a VM (ex.: `Desktop\bl7`) e siga
`docs/verify/bl7-clean-vm/CHECKLIST.md`. Estes scripts não fazem sentido sozinhos: eles produzem a
evidência que o checklist pede.

## Restrição que define o design

A VM limpa tem **Windows PowerShell 5.1 e nada mais**: sem Python, sem git, sem OSGeo4W, sem
módulos de terceiros, **sem administrador**, possivelmente sem internet. Todo helper aqui respeita
isso. Um helper que exigisse `pwsh 7` ou `pip install` seria entrega inútil — a VM não teria como
rodá-lo, e a verificação continuaria não acontecendo.

Os arquivos são **ASCII-only** de propósito: o PowerShell 5.1 lê `.ps1` sem BOM como ANSI, e acento
gravado em UTF-8 sem BOM apareceria corrompido nas mensagens.

## Os três scripts

| Script | Quando rodar | O que produz |
|---|---|---|
| `snapshot-user-profile.ps1` | **antes** de instalar (passo 2) | `perfil-usuario-antes.json` — hash SHA-256 de cada arquivo do perfil QGIS do usuário |
| `assert-bl3.ps1` | depois de usar e **fechar** o app (passos 7 e 11) | `assert-bl3.json` + PASS/FAIL no console |
| `collect-evidence.ps1` | no fim (passo 13) | `RESULT-esqueleto.md` — ambiente da VM já formatado |

Tudo cai em `Desktop\bl7-evidence\`.

```powershell
Set-ExecutionPolicy -Scope Process -Bypass      # só se o PowerShell recusar rodar

.\snapshot-user-profile.ps1 -Rotulo antes
# ... instalar, abrir, usar, FECHAR o IMAN Terra ...
.\assert-bl3.ps1 -Baseline "$env:USERPROFILE\Desktop\bl7-evidence\perfil-usuario-antes.json"
.\collect-evidence.ps1
```

## O que `assert-bl3.ps1` afirma

- **BL-3a** — o perfil do QGIS do **usuário** está byte-idêntico ao snapshot anterior.
  Qualquer arquivo alterado, adicionado ou removido é **FAIL**, e os divergentes são listados por
  nome. **FAIL aqui bloqueia o release** (regra de corte do `RESULT.md`).
- **BL-3b** — o perfil **isolado** da distro foi criado em
  `%APPDATA%\InstitutoIMAN\IMAN Terra\profiles\iman-distro` e não está vazio.

Sai `0` se as duas passam, `1` se qualquer uma falha, `2` em erro de uso.

> **Feche o QGIS antes de rodar o assert.** Arquivo aberto pode ficar travado; o script registra
> isso como `ERRO_LEITURA` em vez de omitir o arquivo — omitir viraria falso PASS.

## Testar o próprio detector

Um detector que nunca falhou é um detector não testado. Para conferir que ele **acusa** de verdade,
use uma pasta de mentira — **nunca** o perfil real:

```powershell
$sb = "$env:TEMP\bl3-teste"
New-Item -ItemType Directory "$sb\profiles\default\QGIS" -Force | Out-Null
Set-Content "$sb\profiles\default\QGIS\QGIS3.ini" "[qgis]"
New-Item -ItemType Directory "$sb\isolado" -Force | Out-Null
Set-Content "$sb\isolado\marcador.txt" "x"

.\snapshot-user-profile.ps1 -Rotulo teste -Path "$sb\profiles" -OutDir "$sb\ev"
Add-Content "$sb\profiles\default\QGIS\QGIS3.ini" "adulterado=1"     # viola de propósito
.\assert-bl3.ps1 -Baseline "$sb\ev\perfil-usuario-teste.json" -PerfilIsolado "$sb\isolado" -OutDir "$sb\ev"
```

Esperado: `[BL-3a] FAIL`, com `ALTERADO default\QGIS\QGIS3.ini` na lista e saída `1`.
