import os, json
from qgis.utils import iface
from qgis.PyQt.QtCore import QTimer, QCoreApplication
d = os.path.join(os.environ.get("SPIKE_DIR", os.getcwd()), "evidence")
os.makedirs(d, exist_ok=True)
def go():
    win = iface.mainWindow()
    try:
        win.grab().save(os.path.join(d, "control.png"))
    except Exception:
        pass
    with open(os.path.join(d, "control.json"), "w", encoding="utf-8") as f:
        json.dump({"control": "plain QGIS, no window manipulation",
                   "title": win.windowTitle()}, f, ensure_ascii=False, indent=2)
    QTimer.singleShot(1500, QCoreApplication.quit)
QTimer.singleShot(4000, go)
