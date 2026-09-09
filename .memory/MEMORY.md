# Memory Index — IMAN QGIS Distro

- [project_iman_qgis_distro.md](project_iman_qgis_distro.md) — tese, fases (Opção 1 → Opção 2), escopo e non-goals da distro.
- [feedback_branding_license_guardrails.md](feedback_branding_license_guardrails.md) — invariantes de marca/licença do QGIS (BL-1…BL-7); nunca remover créditos, perfil isolado, marca em fonte única.
- [reference_qgis_profile_and_packaging.md](reference_qgis_profile_and_packaging.md) — paths de perfil no Windows, launcher, Inno Setup (o Inno FUNDE: `[InstallDelete]` limpa `{app}\qgis` antes da cópia — DB-22), aceite x build com exigências opostas, limites do no-fork vs. fork.
- [reference_build_environment.md](reference_build_environment.md) — bancada local (re-verificada 2026-09-09): **sem QGIS de sistema** (condição normal, não pane) — o QGIS de trabalho é o do produto, chamado pelo `qgis-ltr.bat`, com `OSGEO4W_ROOT` em 8.3; Inno Setup 7.1.0 em Program Files (nenhum Inno 6), como a versão do ISCC 7 é medida, paleta oficial, conta gh franciscocamellon.
- [reference_inventario_licencas_arvore.md](reference_inventario_licencas_arvore.md) — inventário dos 159 componentes embarcados (#020/DB-6): os `-src` do OSGeo4W são receita e não fonte; `libmysql` não é excluível; onde ler licença/dependência; `strings`/`objdump` não existem nesta bancada.

> Decisões de produto vivem no arquiteto: `../iman-product-architect/.memory/reference_decisions.md` (nasce de **D-IMAN-025**). Briefings: `../iman-product-architect/.memory/briefings/`.
