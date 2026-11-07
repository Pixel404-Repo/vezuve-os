#!/usr/bin/env python3
# Vezuve Mood - change le Mood du bureau : couleurs, fond d'ecran, ambiance musicale et eclairage RGB.
# Signe Pixel 404.
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from PySide6.QtCore import QObject, Property, QProcess, QUrl, Signal, Slot
from PySide6.QtGui import QFontDatabase, QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

APP_DIR = Path(__file__).resolve().parent
SHARE = Path(os.environ.get("VEZUVE_SHARE", "/usr/share/vezuve"))
LIBEXEC = Path(os.environ.get("VEZUVE_LIBEXEC", "/usr/libexec"))
CFG_DIR = Path.home() / ".config" / "vezuve"
CFG = CFG_DIR / "mood.json"
LEGACY_CURRENT = Path.home() / ".config" / "vezuve-mood"

MOODS = [
    {"id": "lofi", "name": "Lofi", "l1": "#ffb48a", "l2": "#b794f6", "bg": "#1d1430",
     "wall": "lofi.png", "amb": "lofi.ogg", "track": "Lofi hip hop · Lofi"},
    {"id": "rain", "name": "Lofi Rain", "l1": "#7dd3fc", "l2": "#6366f1", "bg": "#111a33",
     "wall": "rain.png", "amb": "lofi_rain.ogg", "track": "Lofi hip hop · Lofi Rain"},
    {"id": "ninja", "name": "Anime Ninja", "l1": "#ff3b5c", "l2": "#ff9f43", "bg": "#1f1016",
     "wall": "ninja.png", "amb": "anime_ninja.ogg", "track": "Lofi hip hop · Anime Ninja"},
]
MOOD_BY_ID = {m["id"]: m for m in MOODS}

DEFAULTS = {
    "current": "lofi",
    "musicOnChange": True,
    "volume": 50,
    "brightness": 100,
    "rgbEnabled": True,
    "devicesOff": [],      # noms des appareils RGB qui ne suivent pas le Mood
    "customWall": {},      # mood -> chemin d'une image choisie par l'utilisateur
}


def kind_of(name):
    n = name.lower()
    if "dram" in n or "ram" in n or "memory" in n or "ddr" in n:
        return "ram"
    if "geforce" in n or "radeon" in n or "rtx" in n or "gtx" in n or "gpu" in n:
        return "gpu"
    if "keyboard" in n or "clavier" in n:
        return "keyboard"
    if "mouse" in n or "souris" in n:
        return "mouse"
    if "fan" in n or "cooler" in n or "argb" in n or "hub" in n:
        return "fan"
    return "cpu"


KIND_LABEL = {"ram": "Mémoire RAM", "gpu": "Carte graphique", "keyboard": "Clavier",
              "mouse": "Souris", "fan": "Ventilateurs", "cpu": "Carte mère / autre"}


def scale(hexcol, pct):
    """Applique la luminosite (0-100) a une couleur hexadecimale."""
    h = hexcol.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    f = max(0, min(100, pct)) / 100.0
    return "%02X%02X%02X" % (round(r * f), round(g * f), round(b * f))


class Backend(QObject):
    changed = Signal()
    devicesChanged = Signal()
    statusChanged = Signal()

    def __init__(self):
        super().__init__()
        self.cfg = dict(DEFAULTS)
        saved = {}
        try:
            saved = json.loads(CFG.read_text())
            self.cfg.update(saved)
        except Exception:
            pass
        if "current" not in saved:
            try:
                legacy = LEGACY_CURRENT.read_text().strip()
                if legacy in MOOD_BY_ID:
                    self.cfg["current"] = legacy
            except Exception:
                pass
        if self.cfg.get("current") not in MOOD_BY_ID:
            self.cfg["current"] = "lofi"
        self._devices = []
        self._status = ""
        self._playing = False
        self._orgb = self._find_openrgb()
        self.refreshDevices()

    # ---------- utilitaires ----------
    def _save(self):
        try:
            CFG_DIR.mkdir(parents=True, exist_ok=True)
            CFG.write_text(json.dumps(self.cfg, indent=2, ensure_ascii=False))
        except Exception as e:
            print("Vezuve Mood : sauvegarde impossible", e, file=sys.stderr)

    def _set_status(self, text):
        self._status = text
        self.statusChanged.emit()

    @staticmethod
    def _find_openrgb():
        if shutil.which("openrgb"):
            return ["openrgb"]
        if shutil.which("flatpak"):
            r = subprocess.run(["flatpak", "info", "org.openrgb.OpenRGB"],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if r.returncode == 0:
                return ["flatpak", "run", "org.openrgb.OpenRGB"]
        return None

    def _wall_path(self, mid):
        custom = self.cfg.get("customWall", {}).get(mid)
        if custom and Path(custom).is_file():
            return custom
        return str(SHARE / "wallpapers" / MOOD_BY_ID[mid]["wall"])

    # ---------- proprietes exposees a l'interface ----------
    @Property("QVariantList", constant=True)
    def moods(self):
        return [dict(m, wallUrl=QUrl.fromLocalFile(self._wall_path(m["id"])).toString()) for m in MOODS]

    @Property(str, notify=changed)
    def current(self):
        return self.cfg["current"]

    @Property(bool, notify=changed)
    def musicOnChange(self):
        return bool(self.cfg["musicOnChange"])

    @Property(int, notify=changed)
    def volume(self):
        return int(self.cfg["volume"])

    @Property(int, notify=changed)
    def brightness(self):
        return int(self.cfg["brightness"])

    @Property(bool, notify=changed)
    def rgbEnabled(self):
        return bool(self.cfg["rgbEnabled"])

    @Property(bool, notify=changed)
    def playing(self):
        return self._playing

    @Property(bool, constant=True)
    def rgbAvailable(self):
        return self._orgb is not None

    @Property("QVariantList", notify=devicesChanged)
    def devices(self):
        off = set(self.cfg.get("devicesOff", []))
        return [{"index": i, "name": n, "kind": kind_of(n), "label": KIND_LABEL[kind_of(n)],
                 "follow": n not in off} for i, n in self._devices]

    @Property(str, notify=statusChanged)
    def status(self):
        return self._status

    @Slot(str, result=str)
    def wallUrl(self, mid):
        return QUrl.fromLocalFile(self._wall_path(mid)).toString()

    # ---------- reglages ----------
    @Slot(bool)
    def setMusicOnChange(self, v):
        self.cfg["musicOnChange"] = bool(v); self._save(); self.changed.emit()

    @Slot(int)
    def setVolume(self, v):
        self.cfg["volume"] = int(v); self._save(); self.changed.emit()

    @Slot(int)
    def setBrightness(self, v):
        self.cfg["brightness"] = int(v); self._save(); self.changed.emit()

    @Slot(bool)
    def setRgbEnabled(self, v):
        self.cfg["rgbEnabled"] = bool(v); self._save(); self.changed.emit()

    @Slot(str, bool)
    def setDeviceFollow(self, name, follow):
        off = set(self.cfg.get("devicesOff", []))
        (off.discard if follow else off.add)(name)
        self.cfg["devicesOff"] = sorted(off); self._save(); self.devicesChanged.emit()

    @Slot(str, str)
    def setCustomWall(self, mid, url):
        path = QUrl(url).toLocalFile() if url.startswith("file:") else url
        self.cfg.setdefault("customWall", {})[mid] = path
        self._save(); self.changed.emit()

    @Slot(str)
    def resetWall(self, mid):
        self.cfg.setdefault("customWall", {}).pop(mid, None)
        self._save(); self.changed.emit()

    # ---------- actions ----------
    @Slot()
    def refreshDevices(self):
        if not self._orgb:
            self._set_status("OpenRGB n'est pas installé : l'éclairage RGB est désactivé.")
            return
        self._set_status("Recherche des appareils RGB…")
        p = QProcess(self)
        p.setProgram(self._orgb[0])
        p.setArguments(self._orgb[1:] + ["--noautoconnect", "--list-devices"])

        def done(*_):
            out = bytes(p.readAllStandardOutput()).decode(errors="ignore")
            found = []
            for line in out.splitlines():
                m = re.match(r"^\s*(\d+):\s+(.+?)\s*$", line)
                if m:
                    found.append((int(m.group(1)), m.group(2)))
            self._devices = found
            self.devicesChanged.emit()
            self._set_status("%d appareil(s) RGB détecté(s)" % len(found) if found
                             else "Aucun appareil RGB détecté")
            p.deleteLater()

        p.finished.connect(done)
        p.start()

    def _apply_rgb(self, mood):
        if not (self._orgb and self.cfg["rgbEnabled"] and self._devices):
            return
        off = set(self.cfg.get("devicesOff", []))
        args = list(self._orgb[1:]) + ["--noautoconnect"]
        k = 0
        for idx, name in self._devices:
            if name in off:
                continue
            col = mood["l1"] if k % 2 == 0 else mood["l2"]
            args += ["-d", str(idx), "-m", "direct", "-c", scale(col, self.cfg["brightness"])]
            k += 1
        if k:
            QProcess.startDetached(self._orgb[0], args)

    @Slot()
    def stopAmbiance(self):
        subprocess.run(["pkill", "-f", "vezuve-ambiance-loop"], stderr=subprocess.DEVNULL)
        subprocess.run(["pkill", "-f", str(SHARE / "ambiances") + "/"], stderr=subprocess.DEVNULL)
        self._playing = False
        self.changed.emit()

    @Slot()
    def playAmbiance(self):
        self.stopAmbiance()
        mood = MOOD_BY_ID[self.cfg["current"]]
        f = SHARE / "ambiances" / mood["amb"]
        vol = "%.2f" % (self.cfg["volume"] / 100.0)
        QProcess.startDetached("sh", [str(LIBEXEC / "vezuve-ambiance-loop.sh"), str(f), vol])
        self._playing = True
        self.changed.emit()

    @Slot()
    def toggleAmbiance(self):
        self.stopAmbiance() if self._playing else self.playAmbiance()

    @Slot(str)
    def apply(self, mid):
        if mid not in MOOD_BY_ID:
            return
        mood = MOOD_BY_ID[mid]
        self.cfg["current"] = mid
        self._save()
        try:
            LEGACY_CURRENT.write_text(mid + "\n")
        except Exception:
            pass
        # Couleurs KDE + fond d'ecran (via le script systeme), puis image perso si choisie
        script = "sh %s %s --silence" % (LIBEXEC / "vezuve-mood.sh", mid)
        custom = self.cfg.get("customWall", {}).get(mid)
        if custom and Path(custom).is_file():
            script += " ; plasma-apply-wallpaperimage '%s'" % custom.replace("'", "'\\''")
        QProcess.startDetached("sh", ["-c", script])
        self._apply_rgb(mood)
        if self.cfg["musicOnChange"]:
            self.playAmbiance()
        else:
            self.stopAmbiance()
        self._set_status("Mood %s appliqué" % mood["name"])
        self.changed.emit()


def main():
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    app = QGuiApplication(sys.argv)
    app.setApplicationName("Vezuve Mood")
    app.setOrganizationName("Pixel 404")
    app.setDesktopFileName("vezuve-mood")
    app.setWindowIcon(QIcon(str(APP_DIR / "icons" / "palette.svg")))
    if "Plus Jakarta Sans" in QFontDatabase.families():
        f = app.font(); f.setFamily("Plus Jakarta Sans"); app.setFont(f)
    backend = Backend()
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("iconDir", QUrl.fromLocalFile(str(APP_DIR / "icons") + "/").toString())
    engine.load(QUrl.fromLocalFile(str(APP_DIR / "Main.qml")))
    if not engine.rootObjects():
        sys.exit(1)
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
