# Projeto — IMAN QGIS Distro (estado do produto)

Criado: 2026-07-05 (nasce de D-IMAN-025, direção do sponsor via arquiteto).

## Tese

Distribuição QGIS customizada com branding do **Instituto IMAN**, distribuída **gratuitamente**
como peça de **marketing técnico/institucional**. Não é software proprietário fechado nem promessa
comercial: é demonstração de domínio técnico (GIS, PyQGIS, empacotamento desktop, uso profissional
de open-source) e fortalecimento de marca. Independente, mas claramente *powered by QGIS* — **nunca**
apresentada como QGIS oficial nem endossada pela QGIS.ORG.

> **Nome de produto: `IMAN Terra`** (definido pelo sponsor 2026-07-05, após `/critique` +
> `/signature-experience` — venceu `IMAN GIS`). Marca visível de fonte única no design system
> (BL-4); qualquer rename futuro é find-replace. Subtítulo: "powered by QGIS".

## Fases

- **Opção 1 — no-fork (MVP):** QGIS LTR oficial + perfil isolado (tema/cores/UI) + plugin de marca
  leve + startup (título da janela) + launcher Windows + **instalador Inno Setup** (ícone/nome/
  atalhos próprios) + notices/licença. Não recompila o QGIS; não toca a config do usuário.
- **Opção 2 — fork/build (norte, futuro):** fork do QGIS sobre release LTR para o que só o core
  resolve — splash nativo, ícone do `qgis-bin.exe`, About dialog, nome interno da aplicação. Só
  depois da Opção 1 validada; patches por branding/splash/icons/about + docs de build.

## Branding possível SEM fork (o que a fatia 1 alcança)

Título da janela (startup), tema/cores (QSS do perfil), plugin de marca (menu/toolbar/painel de
boas-vindas), ícone + nome do atalho e do instalador, projeto demo, notices. **Limites conhecidos**
(só a Opção 2 resolve): splash nativo, ícone do executável do QGIS, About dialog, nome interno.

## Plugin da distro (decisão de moat — faseada)

MVP embute um **plugin de marca leve** (institucional: menu/toolbar/painel, links, demo). Bundlar o
**plugin REURB** (completo ou limitado) na distro fica para **fatia futura**, após avaliar moat/
monetização — o REURB é a capacidade-core do mercado das ~35 prefeituras (STOP-AND-FLAG de D-IMAN-025).

## Non-goals iniciais

- Fork/compilação do QGIS na fatia 1.
- Alterar o core do QGIS ou remover créditos.
- Login/licença/telemetria/backend remoto obrigatório.
- Suporte multiplataforma completo (foco Windows primeiro).
- Instalação silenciosa não testada; atualizador automático complexo.

## STOP-AND-FLAGs

- ~~Nome de produto pendente~~ → **RESOLVIDO: `IMAN Terra`** (2026-07-05). Marca em fonte única.
- **QGIS LTR instalado** é pré-requisito de runtime para testar/empacotar (VM/máquina Windows limpa).
- **Bundle do REURB** = decisão de moat adiada para fatia futura.
