# Spike #004 — de-risk: branding pós-build (escopo mínimo do source-fork)

Spike **timeboxed de de-risk** (D-IMAN-027, sob D-IMAN-025/DA-2). **Não shippa hack:** PRODUZ
EVIDÊNCIA por EXECUÇÃO real e arbitra quanto de cada item de "identidade premium" (ícone do
`.exe`, splash nativo, About, nome interno) se alcança **sem recompilar o fonte**, classificando
cada um em **RUNTIME / PÓS-BUILD determinístico / IRREDUTÍVEL**.

➡️ **Veredito e evidência em [`REPORT.md`](REPORT.md).** Headline: **o splash nativo é
re-brandável no-fork por config do perfil → o source-fork não se justifica pela evidência.**

## Como reproduzir (caminho REAL: launcher → perfil isolado → QGIS LTR de verdade)

```bat
run-spike.bat runtime   REM Sondas I(runtime)/III/IV — ícone/About/nome via --code
run-spike.bat ii        REM Sonda II — splash NATIVO IMAN via customização do perfil
```

```bat
REM Sonda I (pós-build) — patch determinístico do ícone PE numa CÓPIA (nunca o exe do usuário):
python patch_exe_icon.py           REM gera dist\iman-terra-bin.exe + hash antes/depois
```

Perfil isolado do spike: `%APPDATA%\InstitutoIMAN\IMAN Terra Spike4\` (publisher-dir próprio;
nunca toca o perfil/instalação do usuário — BL-3). Evidência (screenshots + `*.json`) em
[`evidence/`](evidence/).

## Arquivos

| Arquivo | Papel |
|---|---|
| `run-spike.bat` | composition root — perfil isolado + launch (`runtime`\|`ii`) |
| `splash_investigate.py` | headless: prova que o splash default é resource Qt compilado |
| `custom_splash/splash.png` | splash IMAN apontado pela customização (stand-in, paleta velha — arte nova = fatia D-IMAN-026) |
| `sonda_runtime.py` | sondas I(runtime)/III/IV via `--code` (ícone, AppUserModelID, About próprio, nome) |
| `patch_exe_icon.py` | sonda I pós-build: reescreve o ícone PE via Win32 `UpdateResource` numa cópia |
| `evidence/` | screenshots de boot/janela/About + `*_observations.json` + hashes |

> O binário patchado (`dist/`) **não** é versionado — evitar redistribuir binário GPL modificado
> no repo; a evidência é hash + ícone extraído. Ambiente: QGIS 3.40.8 'Bratislava' LTR / Qt 5.15.13.
