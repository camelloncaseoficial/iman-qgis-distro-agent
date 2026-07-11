# Relatório de de-risk — spike #004: branding pós-build (escopo mínimo do source-fork)

**Materializa D-IMAN-027, sob D-IMAN-025/DA-2. Árbitro do escopo mínimo do source-fork.**
Antes de assinar o treadmill perpétuo de rebase de segurança de um source-fork, este spike
descobre — com evidência num QGIS LTR real — quanto de CADA item de "identidade premium"
(ícone do `.exe`, splash nativo, About, nome interno) se alcança SEM recompilar o fonte. O
que sobrar de irredutível seria o escopo mínimo do fork.

## TL;DR — a conclusão que decide

**O source-fork NÃO se justifica pela evidência.** O item que se supunha ser a justificativa
nº1 do fork — **o splash nativo de boot** — é **re-brandável no-fork por configuração do
perfil** (customização do QGIS). Os demais itens são runtime (no-fork) ou pós-build
determinístico; só o "nome interno" é irredutível, e seu payoff é ~zero.

### Matriz item × balde (com evidência de EXECUÇÃO real)

| Item | RUNTIME (no-fork) | PÓS-BUILD determinístico | IRREDUTÍVEL (source-fork) |
|---|---|---|---|
| **I. Ícone** | Janela/taskbar/título via `setWindowIcon`+AppUserModelID ✅ + atalho já IMAN (fatia #001) | Ícone do `.exe` via Win32 `UpdateResource` — **só num QGIS bundlado** (BL-3 barra o exe do usuário); baixo valor | — |
| **II. Splash nativo** | **Config do perfil: `QGISCUSTOMIZATION3.ini`→`splashpath` → o QSplashScreen NATIVO renderiza o splash IMAN** ✅✅ | (trocar o resource Qt compilado = frágil e **desnecessário**) | — |
| **III. About** | Diálogo próprio "Sobre o IMAN Terra" coexistindo com o About nativo ✅ | — | — |
| **IV. Nome interno** | `applicationDisplayName`+AppUserModelID settáveis (efeito visível ~nulo) | (renomear o exe **quebra o boot** — ver Sonda I) | `applicationName`/`organizationName`/crash reporter/classe de janela = C++-baked (**payoff ~zero**) |

**Escopo mínimo do source-fork que sobra: praticamente nada que valha recompilar.** Só a
coerência de "nome interno" (registry/crash dialog/classe de janela), invisível ao técnico
municipal. **Recomendação: NÃO source-forkar.** Entregar a identidade premium no-fork.

## Método (o gate: caminho REAL, execução — não inspeção estática)

- **Composition root real:** runtime via `run-spike.bat` → perfil ISOLADO do spike
  (`%APPDATA%\InstitutoIMAN\IMAN Terra Spike4\`, nunca o perfil/instalação do usuário — BL-3)
  → QGIS LTR de verdade; pós-build aplicado em CÓPIA e verificado por execução/extração.
- **Ambiente:** QGIS **3.40.8 'Bratislava' LTR**, Qt 5.15.13, Windows 10 (19045), 125% DPI.
- **Mecanismo confirmado na fonte** (não suposição): QGIS 3.40 `src/app/main.cpp` faz
  `QPixmap(QgsCustomization::instance()->splashPath() + "splash.png")`; `splashPath()` lê a
  chave `/Customization/splashpath` de `QGISCUSTOMIZATION3.ini` quando `isEnabled()`.
- **Nuance vs #003 (BL-5):** um patch pós-build **determinístico** (Win32 `UpdateResource`)
  **não** é o "hack frágil" do crash da Sonda A do #003 — é packaging legítimo. Este spike
  distingue os dois por execução + hash.

---

## Sonda II — splash nativo de boot → **RUNTIME/CONFIG (no-fork)** ⭐ o achado que decide

Previsto pelo briefing/D-IMAN-027 como "provável irredutível → o item que justifica o fork".
**A evidência refuta.**

- **Default:** o splash é `:/images/splash/splash.png` — **resource Qt COMPILADO** no binário,
  **sem cópia em disco** (`evidence/splash_mechanism.json`). Um swap de arquivo em disco não
  existe → daí a suposição de irredutível.
- **Mas** o QGIS resolve o path por **customização**. Config no perfil isolado:
  - `QGIS3.ini` → `[UI] Customization\enabled=true`
  - `QGISCUSTOMIZATION3.ini` → `[Customization] splashpath=<dir com splash.png IMAN>`
- **Resultado (execução real):** o **QSplashScreen NATIVO** (C++, antes do Python) renderiza
  o **splash IMAN Terra** — com o próprio texto de progresso do QGIS ("Setting up the GUI")
  sobreposto. Controle vs tratamento:
  - `evidence/sonda_ii_native_default_splash.png` — splash nativo QGIS 3.40 (sem customização)
  - `evidence/sonda_ii_native_iman_splash.png` — **splash IMAN no boot** (com customização)
- **Janela principal intacta** com customização ligada (sem regras de widget → nenhum efeito
  além do splash). **Não é hack** (não é 2º-splash-flash do #003): é o splash NATIVO apontado
  para o asset do perfil.

**Veredito II: no-fork por config.** Isto remove a justificativa nº1 do fork.

## Sonda I — ícone → **RUNTIME (no-fork) + PÓS-BUILD (só bundlado)**

- **Runtime (janela/taskbar/título):** `mainWindow().setWindowIcon(IMAN)` +
  `SetCurrentProcessExplicitAppUserModelID`, **reaplicado** (o QGIS reescreve título/ícone tarde
  no boot — mesmo motivo do #003). Evidência: `evidence/sonda_i_runtime_fullscreen.png` (barra de
  título "IMAN Terra — powered by QGIS" + ícone IMAN). O atalho já é IMAN desde a fatia #001.
- **Pós-build (ícone do arquivo `.exe`):** patch **determinístico** via Win32
  `Begin/Update/EndUpdateResource` numa **cópia** de `qgis-ltr-bin.exe` (grupo `IDI_ICON1`, 7
  imagens, idioma 1033). `evidence/sonda_i_postbuild.json`: hash muda
  `7c9a35…`→`a00229…`; o ícone **extraído do PE patchado** é o símbolo IMAN
  (`sonda_i_postbuild_extracted_icon.png`) vs o controle QGIS (`…_control_qgis_icon.png`).
- **Execução do binário patchado (atribuição honesta):** a cópia **renomeada** não inicia —
  **e a cópia UNPATCHED renomeada também não** → a falha é do **rename** (o bootstrap
  `qgis-ltr-bin.exe` resolve o ambiente pelo próprio nome/local), **não do patch** (o PE é
  íntegro: `UpdateResource` teve sucesso e o Windows leu o ícone dele). Logo o patch de ícone do
  `.exe` só é **executável num QGIS bundlado** que mantém o nome no seu `bin`; em no-fork puro,
  sobrescrever o exe do usuário fere **BL-3** → não se executa aqui. `sonda_i_execution_note.json`.
- **BL-3:** o `qgis-ltr-bin.exe` original ficou **intacto** (sha256 `7c9a35…` verificado
  antes/depois de todos os testes).

**Veredito I: window/taskbar/atalho = no-fork (coberto). Ícone do arquivo `.exe` = pós-build só
em distribuição bundlada, baixo valor.**

## Sonda III — About próprio → **RUNTIME (no-fork), PASSOU** (rede de segurança)

Diálogo próprio "Sobre o IMAN Terra" (versão, powered by QGIS, créditos QGIS.ORG,
independência) **coexistindo** com o About nativo (que segue presente —
`native_about_action_present=true`). Evidência: `evidence/sonda_iii_own_about.png`,
`sonda_runtime_observations.json`. Satisfaz BL-1/BL-2 sem tocar o core.

## Sonda IV — nome interno → **IRREDUTÍVEL, payoff ~zero**

Medido em runtime (`sonda_runtime_observations.json`):
- `applicationName='QGIS3'`, `organizationName='QGIS'` — **C++-baked**, imutáveis em runtime.
- `applicationDisplayName` **É** settável em runtime (→ "IMAN Terra"), mas de uso interno; e
  AppUserModelID dá identidade de taskbar/pin. Nada disso é o "nome interno" que o usuário vê.
- Irredutível de fato: crash reporter mostra "QGIS", classe de janela nativa, `applicationName`
  (base do path de QSettings — **já contornado pelo perfil isolado**). **Nenhum é visível ao
  técnico municipal.** Renomear o exe para mudar o nome do processo **quebra o boot** (Sonda I).

**Veredito IV: irredutível, mas sem valor prático — não justifica fork.**

## GPL / BL-1 / BL-2 / BL-3 (crítico)

- **Splash por customização (II) e ícone runtime (I):** **não modificam o binário do QGIS** →
  **nenhuma obrigação nova de GPL**; nada é redistribuído do QGIS. São config/asset do perfil.
- **BL-1/BL-2 no splash:** o splash IMAN mantém **"powered by QGIS"** e "versão institucional ·
  baseada em QGIS" → credita o QGIS e **não** se apresenta como QGIS oficial. Trocar a arte do
  splash não remove o crédito (permanece no splash, no About próprio e nos notices).
- **Patch pós-build do `.exe` (I, só bundlado):** um binário QGIS **modificado**, se
  redistribuído, aciona a GPL → exige disponibilidade da fonte correspondente
  (`app/notices/SOURCE_CODE.md`) + aviso de independência acompanhando, e **não** pode se
  apresentar como QGIS oficial (patchar o binário aproxima da linha do BL-2 — mitigado por
  About/splash/notices). **Hoje `SOURCE_CODE.md` diz que a distro NÃO redistribui o QGIS
  (verdadeiro no no-fork).** Se um dia se adotar distribuição **bundlada + patch**, esse notice
  **tem de ser atualizado** para declarar o binário modificado e a fonte. **O binário patchado
  NÃO foi versionado neste PR** (evitar redistribuir binário GPL modificado no repo; a evidência
  é hash + ícone extraído).
- **BL-3:** todos os patches/config em **cópia própria / perfil isolado**; a instalação do
  usuário nunca foi tocada (hash do exe verificado).

## Recomendação (crew → arquiteto) e escopo mínimo do fork

**Não source-forkar.** A identidade premium é entregável **no-fork**, em fatias leves:
1. **Splash nativo** → nova fatia: adicionar `QGISCUSTOMIZATION3.ini` + `splash.png` (arte
   re-derivada, D-IMAN-026) ao `profile-template`, com `UI/Customization/enabled=true`.
2. **Ícone janela/taskbar** → já na produção (startup reaplica). **About próprio** → adicionar
   ao plugin `iman_brand`. **Atalho** → já feito (fatia #001).
3. **Ícone do arquivo `.exe`** e **nome interno** → NÃO perseguir no no-fork (BL-3 / payoff
   ~zero). Só fariam sentido numa distribuição **bundlada** (installer-full) — e mesmo aí o
   ícone é **patch determinístico scriptável**, **não** um rebuild C++.

**Sobre os guardrails de D-IMAN-027:** como o source-fork **não** é recomendado, o "treadmill de
rebase de segurança C++" **não se materializa**. Se, ainda assim, o sponsor quiser uma
distribuição **bundlada** (para o ícone do `.exe` + nome interno), o treadmill vira **"re-baixar
o instalador oficial do LTR + reaplicar um patch de ícone determinístico (script)"** — sem
compilador, com **BL-7 (VM limpa) como gate de release** e **patches branding-only**. É uma
ordem de magnitude mais leve que um source-fork.

## Fora de escopo (declarado)

Iniciar o source-fork; re-derivar a arte na paleta nova (fatia D-IMAN-026 — o splash usado aqui
é o asset atual, paleta velha, stand-in); CI de rebase; bundle REURB; promover a home-dock C do
#003. BL-7 não é gate de spike (mas os itens pós-build **foram** executados/extraídos, não só
inspecionados).

## Índice de evidência (`evidence/`)

| Arquivo | Item | Mostra |
|---|---|---|
| `splash_mechanism.json` | II | splash = resource Qt compilado, sem cópia em disco |
| `sonda_ii_native_default_splash.png` | II | controle: splash nativo QGIS 3.40 |
| `sonda_ii_native_iman_splash.png` | II | **splash IMAN no QSplashScreen nativo (no-fork)** |
| `sonda_ii_observations.json` | II | mecanismo + config + veredito |
| `sonda_i_runtime_fullscreen.png` | I | ícone+título IMAN na janela (runtime) |
| `sonda_i_postbuild.json` | I | hash antes/depois do patch PE + idioma/imagens |
| `sonda_i_postbuild_extracted_icon.png` | I | ícone IMAN extraído do PE patchado |
| `sonda_i_postbuild_control_qgis_icon.png` | I | controle: ícone QGIS do exe original |
| `sonda_i_execution_note.json` | I | atribuição (rename quebra boot, não o patch) + BL-3 |
| `sonda_iii_own_about.png` | III | About próprio (powered by QGIS, independência) |
| `sonda_runtime_observations.json` | I/III/IV | AppUserModelID, About nativo presente, nome baked vs runtime |
