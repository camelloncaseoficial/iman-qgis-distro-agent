# DB-20 — o checkbox final do instalador abria o launcher e ele não achava o QGIS

**Fatia #015** (`D-IMAN-028`/DB-20) · medido em **2026-09-03** na bancada do dev.
**Bloqueava o release do 0.3.0.**

## Estado da bancada no momento da medição

Conferido antes de medir, não presumido do checkpoint (o sponsor desinstalou e reinstalou o
`0.3.0` em 2026-09-02):

```
ARP  QGIS 3.44.13 'Solothurn'   3.44.13   {740D7A65-CBA3-1014-A0B5-B03A9B7608F5}
ARP  IMAN Terra                 0.3.0     {7B3A9E42-1C6D-4E9F-9A21-6F2E5A1D8B34}_is1
     C:\Program Files\QGIS 3.44.13     (mtime 2026-09-03 08:59)
     C:\Program Files\IMAN Terra       (mtime 2026-09-03 09:00)
     nenhum QGIS em C:\Program Files (x86)
```

## A raiz, medida com controle

O que muda entre "funciona" e "não funciona" é **só a bitness do processo pai**:

```
%ProgramFiles%      num processo 32-bit ....... C:\Program Files (x86)
%ProgramFiles(x86)% num processo 32-bit ....... C:\Program Files (x86)   (o MESMO)
%ProgramW6432%      num processo 32-bit ....... C:\Program Files
%ProgramW6432%      num processo 64-bit ....... C:\Program Files         (definido nos dois)
```

Launcher **instalado**, `IMAN_TERRA_DETECT_ONLY=1`, o mesmo comando nos dois pais:

| Pai | Antes do conserto | Depois do conserto |
|---|---|---|
| `System32\cmd.exe` (64-bit) | `QGIS_EXE=C:\Program Files\QGIS 3.44.13\bin\qgis-ltr-bin.exe` · `exit 0` | igual · `exit 0` |
| `SysWOW64\cmd.exe` (32-bit) | `[IMAN Terra] O QGIS nao foi encontrado nesta maquina.` · `exit 1` | `QGIS_EXE=C:\Program Files\QGIS 3.44.13\bin\qgis-ltr-bin.exe` · `exit 0` |

O `.bat` sondava **exclusivamente** `%ProgramFiles%` (passos 2, 3 e 5) e `%ProgramFiles(x86)%`
(último recurso). Sob a visão WOW64 **todos** os caminhos sondados caem em `Program Files (x86)`.

**Por que atingia justamente o checkbox final:** o `Setup.exe` do Inno é um binário de **32 bits**
(o log do próprio build declara `Setup version: Inno Setup version 7.1.0 (32-bit)`) e a entrada
`[Run]` usa `shellexec` — o `.bat` nasce **filho** desse processo e herda a visão redirecionada.
O atalho do Menu Iniciar nasce do Explorer, que é de 64 bits, e por isso funcionava. **Os dois
caminhos têm pais diferentes**, e é essa diferença que o defeito explora.

> ⚠ **Por que reinstalar não resolveu, e não podia.** A mensagem antiga mandava *"reinstale o
> IMAN Terra — ele reinstala o QGIS"*. O QGIS **estava** instalado. A mensagem **afirmava uma
> causa** em vez de mostrar o que tinha olhado, e desviou o diagnóstico. Por isso a tela nova
> **lista as raízes efetivamente sondadas** e a versão procurada.

## A prova no produto, não só no teste

`checkbox-final-abriu-o-produto.png` — instalação pelo **wizard**, com o checkbox
**"Abrir o IMAN Terra agora" TICADO** (é o padrão), do artefato desta branch. Depois do
`Concluir`, o processo em execução é:

```
5044  qgis-ltr-bin    IMAN Terra — powered by QGIS
```

Isto é a reprodução **exata** do relato do sponsor, invertida: mesmo checkbox, mesma máquina,
mesmo caminho de código — e agora o produto abre.

## Onde a guarda automatizada mora

`tools/test-launcher-detection.ps1`, caso **WOW64**. Sensibilidade provada por reversão:

| Launcher | Placar |
|---|---|
| desta branch | **6 de 6**, `exit 0` |
| de `b34c44d` (pré-conserto) | **5 de 6**, `exit 1` — falha exatamente o caso WOW64 |

Os cinco casos antigos passam **nos dois** estados: eles medem a **ordem** das sondagens (DB-14),
nunca a **origem** das raízes. Era por isso que o DB-20 atravessou quatro fatias sem ser visto.
