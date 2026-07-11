# Isolamento 2: SO o reparent do menuBar (setMenuWidget), SEM flag frameless.
# Se crashar no unload => a instabilidade vem de comandar a barra de menu do QGIS
# para hospedar a title bar de marca (nao do FramelessWindowHint).
import os, json
from qgis.utils import iface
from qgis.PyQt.QtCore import Qt, QTimer, QCoreApplication
from qgis.PyQt.QtWidgets import QWidget, QVBoxLayout, QLabel
d = os.path.join(os.environ.get("SPIKE_DIR", os.getcwd()), "evidence")
os.makedirs(d, exist_ok=True)
def go():
    win = iface.mainWindow()
    strip = QLabel("IMAN TERRA")
    strip.setStyleSheet("background:#103D29;color:#EAF3EC;padding:10px;font-weight:700;")
    wrapper = QWidget()
    v = QVBoxLayout(wrapper); v.setContentsMargins(0,0,0,0); v.setSpacing(0)
    v.addWidget(strip); v.addWidget(win.menuBar())
    win.setMenuWidget(wrapper)
    def shot():
        try: win.grab().save(os.path.join(d, "reparentonly.png"))
        except Exception: pass
        with open(os.path.join(d, "reparentonly.json"), "w", encoding="utf-8") as f:
            json.dump({"variant": "setMenuWidget reparent ONLY (no frameless flag)"},
                      f, ensure_ascii=False, indent=2)
        QTimer.singleShot(1500, QCoreApplication.quit)
    QTimer.singleShot(1500, shot)
QTimer.singleShot(3000, go)
