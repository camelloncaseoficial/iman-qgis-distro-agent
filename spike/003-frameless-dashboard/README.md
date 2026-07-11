# Spike #003 — de-risk: title bar frameless + welcome dashboard

Spike **timeboxed de de-risk** (D-IMAN-026, sob D-IMAN-025/DA-2). **Não shippa hack:**
PRODUZ EVIDÊNCIA e arbitra **fork (Opção 2) vs no-fork (Opção 1)** para as duas peças "uau"
do redesign do sponsor — (A) title bar frameless de marca e (B) dashboard no lugar do
canvas-vazio — mais (C) a home como dock (rede de segurança).

➡️ **O veredito e a evidência estão em [`REPORT.md`](REPORT.md)** (é ele que arbitra o BL-5).

## Como reproduzir (caminho REAL: launcher → perfil isolado → QGIS LTR de verdade)

```bat
run-spike.bat a   REM Sonda A — title bar frameless (crasha; FRÁGIL → Opção 2)
run-spike.bat b   REM Sonda B — dashboard central (QStackedWidget; viável no-fork c/ ressalvas)
run-spike.bat c   REM Sonda C — home como dock (robusto no-fork; rede de segurança)
```

Cada run: detecta o QGIS LTR, constrói um **perfil ISOLADO do spike** em
`%APPDATA%\InstitutoIMAN\IMAN Terra Spike\` (publisher-dir próprio — nunca toca o perfil do
usuário nem o de produção, BL-3), abre o QGIS com a sonda em **foreground**, cada sonda
auto-coleta evidência em [`evidence/`](evidence/) e fecha sozinha. O **exit code** do
processo faz parte da evidência (0 = teardown limpo; `-1073741819`/0xC0000005 = crash).

## Arquivos

| Arquivo | Papel |
|---|---|
| `run-spike.bat` | composition root — perfil isolado + launch por sonda |
| `tokens.py` | paleta NOVA (D-IMAN-026), espelho de código do design-system |
| `dashboard.py` | home re-materializada (paleta nova, REURB/cadastral CE), usada por B e C |
| `sonda_a_frameless.py` | Sonda A (frameless + title bar de marca + matrix) |
| `sonda_b_central.py` | Sonda B (`takeCentralWidget` + `QStackedWidget`) |
| `sonda_c_dock/` | Sonda C — plugin de marca que hospeda a home como dock |
| `sonda_c_probe.py` | instrumentação da Sonda C |
| `probe_common.py` | helpers de evidência (screenshot, observação de janela, quit) |
| `_control.py`, `_sonda_a_flagonly.py`, `_sonda_a_reparentonly.py` | controles de isolamento (atribuição do crash da Sonda A) |
| `evidence/` | screenshots + `*_observations.json` gerados pelos runs |

Ambiente da evidência: **QGIS 3.40.8 'Bratislava' LTR**, Qt 5.15.13, Windows 10 19045,
tela única @ **125% DPI**. Multi-monitor e DPI-misto não foram testáveis nesta máquina
(declarado no relatório).
