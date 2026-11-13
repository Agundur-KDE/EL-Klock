#!/usr/bin/env python3
"""Build pure-QML Plasma and Debian packages; RPMs come from OBS."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile


ROOT = Path(__file__).resolve().parents[1]


def run(*args):
    subprocess.run([str(arg) for arg in args], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "dist")
    parser.add_argument("--tag", help="Require a release tag matching metadata, e.g. v0.1.0")
    parser.add_argument("--source", type=Path, default=ROOT, help="Source checkout/archive")
    args = parser.parse_args()
    source = args.source.resolve()
    metadata = json.loads((source / "package/metadata.json").read_text())
    version = metadata["KPlugin"]["Version"]
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        parser.error("metadata version must have the form X.Y.Z")
    if args.tag and args.tag != f"v{version}":
        parser.error(f"tag {args.tag!r} does not match metadata version {version}")
    for tool in ("msgfmt", "dpkg-deb"):
        if not shutil.which(tool):
            parser.error(f"missing build tool: {tool}; see packaging/Dockerfile")
    run("python3", ROOT / "scripts/validate-metadata.py", source / "package/metadata.json")
    plugin = metadata["KPlugin"]["Id"]
    domain = f"plasma_applet_{plugin}.mo"
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="elklock-release-") as directory:
        work = Path(directory)
        applet = work / "applet"
        applet.mkdir()
        shutil.copy2(source / "package/metadata.json", applet)
        shutil.copytree(source / "package/contents", applet / "contents")
        for name in ("LICENSE", "NOTICE.md"):
            shutil.copy2(source / name, applet)
        shutil.copytree(source / "LICENSES", applet / "LICENSES")
        for po in sorted((source / "translate").glob("*/*.po")):
            catalog = applet / "contents/locale" / po.parent.name / "LC_MESSAGES" / domain
            catalog.parent.mkdir(parents=True, exist_ok=True)
            run("msgfmt", "--check-format", "-o", catalog, po)

        plasmoid = work / f"elklock-{version}.plasmoid"
        with zipfile.ZipFile(plasmoid, "w", zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(applet.rglob("*")):
                if path.is_file():
                    archive.write(path, path.relative_to(applet))

        # Debian shares the standalone widget payload.
        payload = work / f"elklock-{version}"
        share = payload / "usr/share"
        shutil.copytree(applet, share / "plasma/plasmoids" / plugin)
        shutil.copytree(applet / "contents/locale", share / "locale")
        docs = share / "doc/elklock"
        docs.mkdir(parents=True)
        shutil.copy2(source / "README.md", docs)

        debroot = work / "deb"
        shutil.copytree(payload, debroot)
        (debroot / "DEBIAN").mkdir()
        control = (ROOT / "packaging/debian-control.in").read_text().replace("@VERSION@", version)
        (debroot / "DEBIAN/control").write_text(control)
        deb = work / f"elklock_{version}-1_all.deb"
        run("dpkg-deb", "--root-owner-group", "--build", debroot, deb)

        artifacts = [plasmoid, deb]
        sums = []
        for artifact in artifacts:
            shutil.copy2(artifact, output / artifact.name)
            sums.append(f"{hashlib.sha256(artifact.read_bytes()).hexdigest()}  {artifact.name}\n")
        (output / "SHA256SUMS").write_text("".join(sums))
    print(f"Release packages written to {output}")


if __name__ == "__main__":
    main()
