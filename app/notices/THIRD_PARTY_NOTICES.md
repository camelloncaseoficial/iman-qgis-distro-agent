# Avisos de terceiros — IMAN Terra (powered by QGIS)

O **IMAN Terra** é uma experiência geoespacial desktop **independente**, *powered by
QGIS*. Ele **não** modifica nem redistribui o binário do QGIS: é uma camada de marca
(perfil isolado, tema, plugin institucional, launcher) que roda **sobre** uma
instalação do **QGIS LTR oficial** feita separadamente pelo usuário.

> **IMAN Terra é uma experiência geoespacial desktop independente, powered by QGIS.
> O QGIS é um sistema de informação geográfica livre e de código aberto, desenvolvido
> por QGIS.ORG e contribuidores.
> Este projeto não é um produto oficial do QGIS e não é endossado pela QGIS.ORG.**

## QGIS

- **Projeto:** QGIS — A Free and Open Source Geographic Information System
- **Autoria:** QGIS.ORG e contribuidores
- **Site:** https://qgis.org
- **Código-fonte:** https://github.com/qgis/QGIS
- **Licença:** GNU General Public License, versão 2 ou posterior (GPL-2.0-or-later)

O QGIS é distribuído pelo próprio usuário a partir das fontes oficiais. O IMAN Terra
não recompila, não altera e não empacota o núcleo do QGIS nesta versão (Opção 1,
no-fork). Todos os créditos, marcas e telas nativas do QGIS permanecem intactos.

## Bibliotecas do ecossistema QGIS (via instalação oficial do QGIS)

Estas dependências acompanham a instalação oficial do QGIS feita pelo usuário e são
listadas aqui apenas para transparência (o IMAN Terra não as redistribui):

| Componente | Autoria | Licença |
|---|---|---|
| Qt | The Qt Company e contribuidores | LGPL-3.0 / GPL |
| GDAL/OGR | OSGeo e contribuidores | MIT / X11 |
| PROJ | OSGeo e contribuidores | MIT |
| GEOS | OSGeo e contribuidores | LGPL-2.1 |
| Python | Python Software Foundation | PSF License |

## Componentes próprios do IMAN Terra

- Plugin de marca `iman_brand`, startup script, launcher e perfil isolado: código
  próprio do **Instituto IMAN**, sob **GPL-3.0-or-later** (compatível com o QGIS).
  Ver `LICENSE`.
- Assets de marca (logo, ícone, cores) do **Instituto IMAN** — marca registrada,
  **não** licenciados para reuso. Ver `LICENSE`.

## Marcas

"QGIS" e o logotipo do QGIS são marcas do QGIS.ORG. Seu uso aqui é **nominativo**
("powered by QGIS") e não implica endosso. "IMAN" e "IMAN Terra" são marcas do
Instituto IMAN.
