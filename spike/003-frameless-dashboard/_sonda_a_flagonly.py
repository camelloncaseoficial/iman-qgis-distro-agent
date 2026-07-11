# Isolamento: SO o flag frameless (sem barra de marca / sem reparent do menuBar).
# Serve para atribuir o crash de unload: flag sozinho ou o reparent do menuBar?
import os, json
from qgis.utils import iface
from qgis.PyQt.QtCore import Qt, QTimer, QCoreApplication
d = os.path.join(os.environ.get("SPIKE_DIR", os.getcwd()), "evidence")
os.makedirs(d, exist_ok=True)
def go():
    win = iface.mainWindow()
    win.setWindowFlags(Qt.Window | Qt.FramelessWindowHint)
    win.show()
    def shot():
        try:
            win.grab().save(os.path.join(d, "flagonly.png"))
        except Exception:
            pass
        with open(os.path.join(d, "flagonly.json"), "w", encoding="utf-8") as f:
            json.dump({"variant": "frameless flag ONLY (no titlebar reparent)",
                       "flags_frameless": True}, f, ensure_ascii=False, indent=2)
        QTimer.singleShot(1500, QCoreApplication.quit)
    QTimer.singleShot(1500, shot)
QTimer.singleShot(3000, go)
