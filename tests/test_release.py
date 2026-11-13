"""Exercise the real release builder and inspect its installable payloads."""

import gettext
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[1]
PLUGIN = "de.agundur.elklock"
DOMAIN = f"plasma_applet_{PLUGIN}.mo"


class ReleaseTests(unittest.TestCase):
    def test_build_installable_packages(self):
        version = json.loads((ROOT / "package/metadata.json").read_text())["KPlugin"]["Version"]
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            subprocess.run(["python3", str(ROOT / "tools/build-release.py"),
                            "--output", directory, "--tag", f"v{version}"], check=True)
            plasmoid = output / f"elklock-{version}.plasmoid"
            deb = output / f"elklock_{version}-1_all.deb"
            self.assertEqual({p.name for p in output.iterdir()},
                             {plasmoid.name, deb.name, "SHA256SUMS"})
            with zipfile.ZipFile(plasmoid) as archive:
                names = set(archive.namelist())
                self.assertIn("metadata.json", names)
                self.assertIn("contents/ui/ElData.js", names)
                self.assertIn("contents/sounds/invasion-horn.mp3", names)
                self.assertIn("LICENSE", names)
                self.assertFalse(any("plugin/" in name or "CMakeLists" in name for name in names))
                catalog = archive.read(f"contents/locale/de/LC_MESSAGES/{DOMAIN}")
                self.assertEqual(gettext.GNUTranslations(io.BytesIO(catalog)).gettext("Show seconds"),
                                 "Sekunden anzeigen")
            self.assertEqual(subprocess.check_output(["dpkg-deb", "-f", str(deb), "Architecture"],
                                                     text=True).strip(), "all")
            extracted = output / "extracted"
            subprocess.run(["dpkg-deb", "-x", str(deb), str(extracted)], check=True)
            base = extracted / f"usr/share/plasma/plasmoids/{PLUGIN}"
            self.assertEqual((base / "contents/ui/main.qml").read_bytes(),
                             (ROOT / "package/contents/ui/main.qml").read_bytes())
            self.assertEqual((extracted / f"usr/share/locale/de/LC_MESSAGES/{DOMAIN}").read_bytes(), catalog)
            self.assertFalse((base / "plugin").exists())
            for line in (output / "SHA256SUMS").read_text().splitlines():
                checksum, name = line.split("  ")
                self.assertEqual(hashlib.sha256((output / name).read_bytes()).hexdigest(), checksum)

    def test_tag_mismatch_stops_before_build(self):
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(["python3", str(ROOT / "tools/build-release.py"),
                                     "--output", directory, "--tag", "v999.0.0"],
                                    capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("does not match", result.stderr)
            self.assertEqual(list(Path(directory).iterdir()), [])


if __name__ == "__main__":
    unittest.main()
