# RENAME_CHECKLIST — trocar o nome de produto (BL-4 literal)

**Fonte única do nome** = `PRODUCT_NAME` em `docs/design-system.md` **e** `brand.py`. Na teoria, tudo
deriva daí. Na prática, algumas superfícies (`.iss`, `.bat`, prosa dos notices e **nomes de arquivo**)
carregam **cópias independentes** da string — o compilador Inno, o `cmd.exe` e o sistema de arquivos
não leem `brand.py`. Este checklist enumera **toda** superfície que espelha o nome, para um rename
futuro ser **find-replace guiado**, não caça a strings. Referenciado por `/branding`.

> Produto atual: **`IMAN Terra`** (definido 2026-07-05, D-IMAN-025). Este doc é sobre *como trocar*, não
> sobre trocar agora. Ao renomear, atualizar este próprio doc.

## Distinguir 4 coisas (não confundir)

| Camada | Exemplo hoje | Muda no rename? |
|---|---|---|
| **Nome de produto visível** | `IMAN Terra` | **Sim** — é o rename. |
| **Nome do publisher** | `Instituto IMAN` / `InstitutoIMAN` | Só se o publisher mudar (independente). |
| **Slugs internos** | perfil `iman-distro`, plugin `iman_brand`, env `IMAN_TERRA_HOME`, `objectName`s Qt | **Opcional** — invisíveis; mudar só se quiser coerência total. |
| **Identidade de uninstall** | `AppId` GUID no `.iss` | **NÃO mudar nunca** (quebra o uninstall do que já foi instalado). |

---

## A. Nome de produto visível — `IMAN Terra` (obrigatório no rename)

### A1. Fonte única (editar PRIMEIRO)
- [ ] `docs/design-system.md` — tabela **Nome de produto** (`PRODUCT_NAME`, `PRODUCT_SUBTITLE`, `WINDOW_TITLE`).
- [ ] `app/profile-template/iman-distro/python/plugins/iman_brand/brand.py` — `PRODUCT_NAME`, `PRODUCT_SUBTITLE`,
      `WINDOW_TITLE` (o `CREDITS_QGIS` e o resto derivam via `.format`).

### A2. Cópias independentes em código/config (o compilador/cmd não lê `brand.py`)
- [ ] `installer/iman-terra.iss` — `#define ProductName "IMAN Terra"` (linha ~10). Tudo no `.iss` usa `{#ProductName}`.
- [ ] `app/launcher/IMAN-Terra.bat` — `set "PRODUCT_NAME=IMAN Terra"` (linha ~13).
- [ ] `app/.../iman_brand/metadata.txt` — `name=`, `description=`, `about=` (espelham `brand.py`).
- [ ] `app/startup/iman_startup.py` — string de **fallback** `"IMAN Terra — powered by QGIS"` (linha ~117,
      usada só se `brand.py` não importar).

### A3. Prosa de marca (verbatim — revisar à mão, não só find-replace)
- [ ] `docs/BRANDING_AND_LICENSE.md` — bloco de créditos + nomenclatura.
- [ ] `app/notices/THIRD_PARTY_NOTICES.md` — créditos, "Componentes próprios", "Marcas".
- [ ] `app/notices/SOURCE_CODE.md` — menções ao produto.
- [ ] `app/notices/LICENSE` — menções ao produto.
- [ ] `README.md` — título e prosa.
- [ ] `app/assets/README.md` — proveniência.

## B. Nomes de arquivo que embutem o nome (rename = `git mv` + atualizar quem referencia)

- [ ] `installer/iman-terra.iss` → renomear o arquivo (nenhum outro arquivo referencia o caminho por nome fixo;
      o build é `ISCC.exe installer\<novo>.iss`).
- [ ] `app/launcher/IMAN-Terra.bat` → renomear **e** atualizar quem aponta pra ele:
      `installer/iman-terra.iss` (`[Icons]` e `[Run]` usam `IMAN-Terra.bat` **3×**) e `README.md`.
- [ ] `app/assets/icon-iman-terra.ico` / `icon-iman-terra.png` → renomear **e** atualizar:
      `.iss` (`SetupIconFile`, `UninstallDisplayIcon`, `[Icons] IconFilename` 2×), `app/startup/iman_startup.py`
      (`_icon_path`), `docs/design-system.md`, `app/assets/README.md`.
- [ ] `app/assets/splash-iman-terra.svg` / `splash-iman-terra.png` → renomear **e** atualizar
      `docs/design-system.md` e `app/assets/README.md` (o dock/instalador usam as **cópias** `resources/splash.png`
      e `wizard-*.png`, cujos nomes não embutem o produto — não precisam mudar).
- [ ] `installer/iman-terra.iss` — `OutputBaseFilename=Instituto-IMAN-IMAN-Terra-Setup-...` (nome do `.exe` de saída).

## C. Slugs internos (OPCIONAL — invisíveis ao usuário; mudar só se quiser coerência)

Trocar aqui não é necessário para renomear o produto. Se decidir trocar, mude **todas** as pontas juntas:

- [ ] Perfil `iman-distro` → renomear a pasta `app/profile-template/iman-distro/` **e**
      `app/launcher/IMAN-Terra.bat` (`set "PROFILE_NAME=iman-distro"`) **e** referências em docs/README.
- [ ] Plugin `iman_brand` → renomear a pasta do plugin **e** `QGIS3.ini` (`[PythonPlugins] iman_brand=true`)
      **e** os imports (`from iman_brand import brand` em `iman_startup.py`; `from . import brand`) **e** `metadata.txt`.
- [ ] Env `IMAN_TERRA_HOME` → `IMAN-Terra.bat` (set) **e** `iman_startup.py` (`_app_home`) **e** `iman_brand.py`
      (`open_demo`) — os **3** juntos.
- [ ] `objectName`s Qt (`ImanTerraToolbar`, `ImanTerraWelcomeDock`, `ImanTerraWelcome`, `ImanTitle`,
      `ImanSubtitle`, `ImanPrimaryBtn`, `ImanCredits`) em `iman_brand.py` — cosméticos; o QSS do dock casa por
      esses nomes, então mudar um exige mudar o seletor correspondente.

## D. NÃO mudar (identidade estável)

- [ ] `installer/iman-terra.iss` — **`AppId` GUID** (`{{7B3A9E42-...}`). Muda a identidade de uninstall; renomear
      o produto **não** deve reutilizar o GUID em outro produto **nem** trocar o de um produto existente.
- [ ] `%APPDATA%\InstitutoIMAN\...` (`PUBLISHER_DIR` no `.bat`, `PublisherDir` no `.iss`) — atado ao **publisher**,
      não ao produto; só muda se o Instituto mudar de nome. Uninstall **preserva** esse diretório (BL-3).

## Procedimento sugerido

1. Editar **A1** (fonte única) e rodar o smoke — confirma o que deriva sozinho (título da janela, dock, About,
   `metadata` se sincronizado).
2. Aplicar **A2** e **A3** (cópias independentes + prosa) por find-replace, revisando a prosa à mão.
3. Aplicar **B** (`git mv` + atualizar referências). Recompilar o instalador e conferir o nome do `.exe`.
4. Deixar **C** como está, salvo decisão explícita de renomear slugs.
5. **Não tocar D.**
6. Atualizar este checklist e `docs/design-system.md` com o novo nome.
7. Rodar `/license-check` (BL-1/BL-2 intactos) e o smoke em VM limpa (BL-7).
