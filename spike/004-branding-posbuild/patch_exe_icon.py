# -*- coding: utf-8 -*-
"""Sonda I (PÓS-BUILD) — reescreve o ícone PE de uma CÓPIA de qgis-ltr-bin.exe.

Patch DETERMINÍSTICO (não frágil): usa as APIs oficiais do Windows
(Begin/Update/EndUpdateResource) para trocar o grupo de ícones `IDI_ICON1` e as
imagens RT_ICON por `app/assets/icon-iman-terra.ico`. Opera SÓ numa cópia própria
distribuível (renomeada p/ a marca) — NUNCA a instalação do usuário (BL-3). Grava
hash antes/depois e o resultado é executado + o ícone extraído como evidência.

GPL/BL-2: uma cópia MODIFICADA do binário do QGIS, se redistribuída, exige
disponibilidade de fonte (notices/SOURCE_CODE.md) + aviso de independência; e não
pode se apresentar como QGIS oficial. Ver REPORT.md.
"""
import ctypes
import hashlib
import json
import os
import shutil
import struct
from ctypes import wintypes

_DIR = os.environ.get("SPIKE_DIR", os.path.dirname(os.path.abspath(__file__)))
SRC_EXE = r"C:\OSGeo4W\bin\qgis-ltr-bin.exe"
ICO = os.path.join(_DIR, "..", "..", "app", "assets", "icon-iman-terra.ico")
DIST = os.path.join(_DIR, "dist")
OUT_EXE = os.path.join(DIST, "iman-terra-bin.exe")
EVID = os.path.join(_DIR, "evidence")

RT_ICON = 3
RT_GROUP_ICON = 14

k = ctypes.WinDLL("kernel32", use_last_error=True)
k.BeginUpdateResourceW.restype = wintypes.HANDLE
k.BeginUpdateResourceW.argtypes = [wintypes.LPCWSTR, wintypes.BOOL]
k.UpdateResourceW.restype = wintypes.BOOL
k.UpdateResourceW.argtypes = [wintypes.HANDLE, ctypes.c_void_p, ctypes.c_void_p,
                              wintypes.WORD, ctypes.c_void_p, wintypes.DWORD]
k.EndUpdateResourceW.restype = wintypes.BOOL
k.EndUpdateResourceW.argtypes = [wintypes.HANDLE, wintypes.BOOL]
k.LoadLibraryExW.restype = wintypes.HMODULE
k.LoadLibraryExW.argtypes = [wintypes.LPCWSTR, wintypes.HANDLE, wintypes.DWORD]


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_ico(path):
    with open(path, "rb") as f:
        data = f.read()
    reserved, itype, count = struct.unpack_from("<HHH", data, 0)
    if reserved != 0 or itype != 1:
        raise ValueError("não é um .ico válido")
    entries = []
    off = 6
    for _ in range(count):
        (bW, bH, bColor, bRes, wPlanes, wBits, bytesInRes, imgOff) = \
            struct.unpack_from("<BBBBHHII", data, off)
        img = data[imgOff:imgOff + bytesInRes]
        entries.append(dict(bW=bW, bH=bH, bColor=bColor, wPlanes=wPlanes,
                            wBits=wBits, bytesInRes=bytesInRes, img=img))
        off += 16
    return entries


def build_group(entries):
    # GRPICONDIR header + GRPICONDIRENTRY (14 bytes) referenciando ids 1..N
    out = struct.pack("<HHH", 0, 1, len(entries))
    for i, e in enumerate(entries, start=1):
        out += struct.pack("<BBBBHHIH", e["bW"] & 0xFF, e["bH"] & 0xFF, e["bColor"],
                           0, e["wPlanes"], e["wBits"], e["bytesInRes"], i)
    return out


def find_group_language():
    """Idioma do recurso IDI_ICON1 (para SUBSTITUIR e não duplicar)."""
    LOAD_LIBRARY_AS_DATAFILE = 0x0002
    h = k.LoadLibraryExW(SRC_EXE, None, LOAD_LIBRARY_AS_DATAFILE)
    langs = []
    ENUMLANG = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HMODULE, ctypes.c_void_p,
                                  ctypes.c_void_p, wintypes.WORD, ctypes.c_void_p)
    k.EnumResourceLanguagesW.argtypes = [wintypes.HMODULE, ctypes.c_void_p,
                                         ctypes.c_void_p, ENUMLANG, ctypes.c_void_p]

    def cb(hm, t, n, lang, p):
        langs.append(lang)
        return True
    name = ctypes.create_unicode_buffer("IDI_ICON1")
    k.EnumResourceLanguagesW(h, ctypes.c_void_p(RT_GROUP_ICON),
                             ctypes.cast(name, ctypes.c_void_p), ENUMLANG(cb), None)
    return langs[0] if langs else 0


def main():
    os.makedirs(DIST, exist_ok=True)
    os.makedirs(EVID, exist_ok=True)
    result = {"sonda": "I - post-build PE icon patch", "src_exe": SRC_EXE, "out_exe": OUT_EXE}

    result["src_sha256"] = sha256(SRC_EXE)
    shutil.copy2(SRC_EXE, OUT_EXE)
    result["copy_sha256_before_patch"] = sha256(OUT_EXE)

    lang = find_group_language()
    result["group_language"] = lang
    entries = parse_ico(ICO)
    result["ico_images"] = [(e["bW"] or 256, e["bH"] or 256, e["wBits"]) for e in entries]

    h = k.BeginUpdateResourceW(OUT_EXE, False)
    if not h:
        raise ctypes.WinError(ctypes.get_last_error())

    # escreve/─substitui RT_ICON ids 1..N
    for i, e in enumerate(entries, start=1):
        buf = ctypes.create_string_buffer(e["img"], len(e["img"]))
        ok = k.UpdateResourceW(h, ctypes.c_void_p(RT_ICON), ctypes.c_void_p(i),
                               lang, ctypes.cast(buf, ctypes.c_void_p), len(e["img"]))
        if not ok:
            raise ctypes.WinError(ctypes.get_last_error())
    # remove RT_ICON antigos que sobraram (o exe tinha 7)
    for i in range(len(entries) + 1, 8):
        k.UpdateResourceW(h, ctypes.c_void_p(RT_ICON), ctypes.c_void_p(i), lang, None, 0)

    # substitui o grupo IDI_ICON1
    grp = build_group(entries)
    gbuf = ctypes.create_string_buffer(grp, len(grp))
    name = ctypes.create_unicode_buffer("IDI_ICON1")
    ok = k.UpdateResourceW(h, ctypes.c_void_p(RT_GROUP_ICON),
                           ctypes.cast(name, ctypes.c_void_p), lang,
                           ctypes.cast(gbuf, ctypes.c_void_p), len(grp))
    if not ok:
        raise ctypes.WinError(ctypes.get_last_error())

    if not k.EndUpdateResourceW(h, False):
        raise ctypes.WinError(ctypes.get_last_error())

    result["copy_sha256_after_patch"] = sha256(OUT_EXE)
    result["patched_changed_hash"] = result["copy_sha256_before_patch"] != result["copy_sha256_after_patch"]
    result["bucket"] = "POST-BUILD deterministico (packaging legitimo, nao-fragil)"

    with open(os.path.join(EVID, "sonda_i_postbuild.json"), "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
