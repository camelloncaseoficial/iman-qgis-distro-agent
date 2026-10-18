# `tools/bl7/` - helpers da verificação em VM limpa (BL-7)

Copie **esta pasta inteira** para a VM (ex.: `Desktop\bl7`) e siga
`docs/verify/bl7-clean-vm/CHECKLIST.md`. Estes scripts não fazem sentido sozinhos: eles produzem a
evidência que o checklist pede.

## Restrição que define o design

A VM limpa tem **Windows PowerShell 5.1 e nada mais**: sem Python, sem git, sem OSGeo4W, sem
módulos de terceiros, **sem administrador**, possivelmente sem internet. Todo helper aqui respeita
isso. Um helper que exigisse `pwsh 7` ou `pip install` seria entrega inútil: a VM não teria como
rodá-lo, e a verificação continuaria não acontecendo.

Os arquivos são **ASCII-only** de propósito: o PowerShell 5.1 lê `.ps1` sem BOM como ANSI, e acento
gravado em UTF-8 sem BOM apareceria corrompido nas mensagens.

## Os quatro scripts

| Script | Quando rodar | O que produz |
|---|---|---|
| `snapshot-user-profile.ps1` | **antes** de instalar (`§1`) | `perfil-usuario-antes.json`, com SHA-256 de cada arquivo do perfil QGIS do usuário |
| `assert-bl3.ps1` | depois de usar e **fechar** o app (`§12`, `§17`, `§19`) | `assert-bl3.json` mais PASS/FAIL no console |
| `assert-reconciliacao.ps1` | nos três estados do perfil (`§11`, `§14`, `§20`) | `reconciliacao-<rotulo>.json` mais os números no console |
| `collect-evidence.ps1` | no fim de cada rodada (Fechamento) | `RESULT-esqueleto.md`, com ambiente **e procedência** já formatados |

Tudo cai em `Desktop\bl7-evidence\`.

```powershell
Set-ExecutionPolicy -Scope Process -Bypass      # so se o PowerShell recusar rodar

.\snapshot-user-profile.ps1 -Rotulo antes
# ... instalar, abrir, usar, FECHAR o IMAN Terra ...
.\assert-reconciliacao.ps1 -Rotulo perfil-novo
.\assert-bl3.ps1 -Baseline "$env:USERPROFILE\Desktop\bl7-evidence\perfil-usuario-antes.json"
.\collect-evidence.ps1
```

## O que `assert-bl3.ps1` afirma

- **BL-3a** - o perfil do QGIS do **usuário** está byte-idêntico ao snapshot anterior.
  Qualquer arquivo alterado, adicionado ou removido é **FAIL**, e os divergentes são listados por
  nome. **FAIL aqui bloqueia o release** (regra de corte do `RESULT.md`).
- **BL-3b** - o perfil **isolado** da distro foi criado em
  `%APPDATA%\InstitutoIMAN\IMAN Terra\profiles\iman-distro` e não está vazio.

Sai `0` se as duas passam, `1` se qualquer uma falha, `2` em erro de uso.

> **Feche o QGIS antes de rodar o assert.** Arquivo aberto pode ficar travado; o script registra
> isso como `ERRO_LEITURA` em vez de omitir o arquivo, porque omitir viraria falso PASS.

## O que `assert-reconciliacao.ps1` afirma (`DB-26`)

Ele responde, em número: quantos raios de 5 a 8 px e de 2 px o tema do perfil tem, quantas
ocorrências de `_RE_SUFIXO_DO_QGIS` o plugin tem, quantos arquivos **do produto** batem por SHA-256
com o template **instalado**, que sobras e obsoletos ficaram, que chaves do `QGIS3.ini` divergem, o
CRS padrão e se a base do merge de 3 vias existe.

**Quem decide o que é do produto é o produto:** o script lê
`{app}\profile-template\PERFIL-DO-PRODUTO.json`, o **mesmo** arquivo que o `Sync-Perfil.ps1` lê. Não
há segunda cópia da fronteira aqui, porque uma cópia seria mais um lugar para divergir em silêncio.

**O `QGIS3.ini` não é comparado por hash**, e isso é deliberado: ele é compartilhado. O produto
declara **chaves** nele; o resto do arquivo é do usuário, e o próprio QGIS o reescreve a cada sessão.
Comparar o arquivo inteiro daria FAIL numa instalação perfeitamente sã, o que foi medido em
2026-09-20 no perfil real do sponsor.

Com `-Semear <arquivo.zip>` ele semeia o perfil a partir de um template **histórico**, por cópia
crua, que é como o launcher da época o criava. O `.zip` sai da bancada, que tem git:

```powershell
git archive --format=zip -o perfil-velho-ba58d14.zip ba58d14     app/profile-template/iman-distro
git archive --format=zip -o perfil-velho-pre0707.zip '8cc4d5e^'  app/profile-template/iman-distro
```

Ele **recusa** semear com o produto aberto, e **recusa** qualquer perfil fora de
`%APPDATA%\InstitutoIMAN` (BL-3).

O veredito final (`[OK]` e saída `0`) cobre arquivos, sobras, obsoletos, pastas e base. **As chaves
ficam de fora do veredito de propósito:** o merge de 3 vias pode, com razão, manter o valor do
**usuário** numa chave que o produto não mudou desde a base. Os valores esperados de cada estado
estão no `CHECKLIST.md`, e é lá que o veredito de cada um é dado.

## O que `collect-evidence.ps1` coleta

Ambiente da VM (Windows, idioma, sessão de administrador, resolução, escala), **procedência do
produto instalado** (`{app}\BUILD_ID.txt`: versão, commit, branch, `build_canonico`), o **QGIS
embarcado** (versão do manifesto, contagem da árvore contra o `TOTAL`, SHA-256 do payload de
origem), o QGIS de sistema porventura presente e o estado do perfil isolado, incluindo o
`template_digest` da base.

## Testar o próprio detector

Um detector que nunca falhou é um detector não testado. Para conferir que ele **acusa** de verdade,
use uma pasta de mentira, **nunca** o perfil real:

```powershell
$sb = "$env:TEMP\bl3-teste"
New-Item -ItemType Directory "$sb\profiles\default\QGIS" -Force | Out-Null
Set-Content "$sb\profiles\default\QGIS\QGIS3.ini" "[qgis]"
New-Item -ItemType Directory "$sb\isolado" -Force | Out-Null
Set-Content "$sb\isolado\marcador.txt" "x"

.\snapshot-user-profile.ps1 -Rotulo teste -Path "$sb\profiles" -OutDir "$sb\ev"
Add-Content "$sb\profiles\default\QGIS\QGIS3.ini" "adulterado=1"     # viola de proposito
.\assert-bl3.ps1 -Baseline "$sb\ev\perfil-usuario-teste.json" -PerfilIsolado "$sb\isolado" -OutDir "$sb\ev"
```

Esperado: `[BL-3a] FAIL`, com `ALTERADO default\QGIS\QGIS3.ini` na lista e saída `1`.

O `assert-reconciliacao.ps1` se testa do mesmo jeito, e sem pasta de mentira: o modo `-Semear` com
o `.zip` de `ba58d14` **tem** de devolver `RAIOS58 14`, `RAIOS2 0`, `SUFIXO 0` e `BASE AUSENTE`. Se
devolver os números do template novo, a semente não chegou ao perfil e a medição seguinte não
provaria nada. É a asserção `E.1` do `§20` do checklist.
