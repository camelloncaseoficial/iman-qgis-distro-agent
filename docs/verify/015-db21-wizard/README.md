# DB-21 — a chapa cinza do logo no wizard

**Fatia #015** (`D-IMAN-028`/DB-21) · medido em **2026-09-03** na bancada do dev
(Windows 11 pt-BR, Inno Setup 7.1.0, tema claro).

## O defeito

O logo do canto superior direito aparecia sobre um **retângulo cinza** diferente do resto da
página — em **toda página interna** do wizard. **Não era composição do Inno:** estava cravado no
arquivo.

| Medição | Antes |
|---|---|
| `app/assets/wizard-small.png` | `138×140`, mode **RGB**, **sem canal alfa** |
| pixels de borda (4 cantos + topo-centro) | todos `#EBEEE8` |
| página do wizard renderizada num build real | `#FFFFFF` |
| `installer/iman-terra.iss` | declarava as duas imagens, **sem** `WizardImageAlphaFormat` |

## A escolha, por medição

Duas vias eram plausíveis. A decisão **não** foi por preferência:

- **(a) re-exportar o PNG com o fundo da página — DESCARTADA.** A página do wizard é `clWindow`,
  a cor de janela do **tema do Windows**; a medição num build real deu `#FFFFFF`, e `#FFFFFF`
  **não é token** de `docs/design-system.md`. Cravar essa cor exigiria inventar um token órfão e
  só mudaria a chapa de lugar no primeiro tema diferente (escuro, alto contraste) ou noutra
  versão do Inno. O `#EBEEE8` que estava lá **é** token (`bg`) — o erro não foi a cor, foi
  **haver cor**.
- **(b) alfa real + `WizardImageAlphaFormat` — ADOTADA.** Sobrevive a qualquer cor de página,
  que era o critério. `defined` e não `premultiplied` porque o PIL grava alfa **reto**.

## Resultado medido

Mesmo ponto da tela, mesmo build real, antes e depois:

| Ponto amostrado | Antes | Depois |
|---|---|---|
| canto sup-dir da imagem `(600, 40)` | `#EBEEE8` | `#FFFFFF` |
| abaixo da imagem `(575, 84)` | `#EBEEE8` | `#FFFFFF` |
| página, à esquerda do logo `(492, 40)` | `#FFFFFF` | `#FFFFFF` |

## As imagens

| Arquivo | O que mostra |
|---|---|
| `wizard-antes-1-licenca.png` | página de **licença** — onde o sponsor viu — com a chapa |
| `wizard-antes-2-destino.png` | a chapa **não era da página de licença**: aparece na seguinte também |
| `wizard-depois-1-licenca.png` | mesma página, **sem chapa** |
| `wizard-depois-2-destino.png` | idem, página de destino |
| `wizard-depois-3-conclusao.png` | **controle do `wizard-large`** — ver abaixo |

Todas são captura do **wizard renderizado por um build real** (`Instituto-IMAN-IMAN-Terra-Setup-0.3.0.exe`),
não do PNG aberto num visualizador: o alvo só existe depois que o Inno compõe a página.

> **Por que a primeira página é a de licença, e não a de boas-vindas.** O Inno 6+ traz
> `DisableWelcomePage=yes` por padrão, então `WizardImageFile` (o painel grande) só aparece na
> página de **conclusão**. É por isso que o controle do `wizard-large` foi capturado lá.

## Controle: o `wizard-large` não foi afetado

`WizardImageAlphaFormat` vale para **as duas** imagens, e o `wizard-large.png` continua RGB sem
alfa — então "ele não quebrou" precisava ser **medido**, não suposto. Na página de conclusão do
mesmo build:

| Ponto | Cor |
|---|---|
| painel esquerdo, topo / meio / base | `#103D29` (token `brand`) — opaco, sem artefato |
| página, à direita | `#FFFFFF` |

O `wizard-large.png` **não foi tocado** nesta fatia. O gerador o reemite byte-idêntico
(conferido: não aparece no diff).

## Como reproduzir

```powershell
py app/assets/regenerate-brand-derivatives.py   # wizard-small sai RGBA transparente
.\installer\build.ps1 -SemRede
```

Depois abra o instalador e olhe o canto superior direito de qualquer página interna.
