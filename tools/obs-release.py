#!/usr/bin/env python3
"""Submit an exact release source to OBS and retrieve its signed noarch RPM."""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "home:Agundur"
PACKAGE = "elklock"
REPOSITORY = "openSUSE_Tumbleweed"
ARCHES = {"x86_64", "i586"}


def run(*args, cwd=None):
    return subprocess.check_output([str(a) for a in args], cwd=cwd, text=True)


def builds_ready(xml):
    results = ET.fromstring(xml).findall("result")
    seen = set()
    for result in results:
        arch = result.get("arch")
        if arch not in ARCHES:
            continue
        if result.get("dirty", "false") != "false":
            return False
        status = result.find("status[@package='elklock']")
        code = status.get("code") if status is not None else "unknown"
        if code in {"failed", "broken", "unresolvable", "disabled", "excluded"}:
            raise RuntimeError(f"OBS {arch}: {code}")
        if code != "succeeded" or result.get("state") != "published":
            return False
        seen.add(arch)
    return seen == ARCHES


def validate_rpm_info(info, version, source_md5):
    name, actual_version, arch, vendor, signature, disturl = info.strip().split("\t")
    if (name != PACKAGE or actual_version != version or arch != "noarch"
            or vendor != "obs://build.opensuse.org/home:Agundur"
            or signature in {"", "(none)"}
            or disturl != f"obs://build.opensuse.org/{PROJECT}/{REPOSITORY}/{source_md5}-{PACKAGE}"):
        raise ValueError(f"Unexpected RPM provenance/version/signature: {info.strip()}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--output", type=Path, default=ROOT / "obs-rpms")
    parser.add_argument("--timeout", type=int, default=1800)
    args = parser.parse_args()
    if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", args.tag):
        parser.error("tag must have the form vX.Y.Z")
    version = args.tag[1:]
    metadata = json.loads(run("git", "show", f"{args.tag}:package/metadata.json", cwd=ROOT))
    if metadata["KPlugin"]["Version"] != version:
        parser.error("tag does not match widget metadata")
    commit = run("git", "rev-parse", f"{args.tag}^{{commit}}", cwd=ROOT).strip()
    with tempfile.TemporaryDirectory(prefix="elklock-obs-") as directory:
        checkout = Path(directory) / "package"
        print(run("osc", "checkout", f"{PROJECT}/{PACKAGE}", "-o", checkout), flush=True)
        for old in checkout.glob("elklock-*.tar.gz"):
            if old.name != f"elklock-{version}.tar.gz":
                print(run("osc", "delete", old.name, cwd=checkout), flush=True)
        spec = (ROOT / "packaging/elklock.spec").read_text()
        (checkout / "elklock.spec").write_text(re.sub(r"^Version:.*$", f"Version:        {version}", spec, flags=re.M))
        shutil.copy2(ROOT / "packaging/elklock.changes", checkout)
        run("git", "archive", "--format=tar.gz", f"--prefix=elklock-{version}/",
            "--output", checkout / f"elklock-{version}.tar.gz", commit, cwd=ROOT)
        print(run("osc", "addremove", cwd=checkout), flush=True)
        if run("osc", "status", cwd=checkout).strip():
            print(run("osc", "commit", "-m", f"Release {args.tag} from {commit}", cwd=checkout), flush=True)
        source = ET.fromstring(run("osc", "api", f"/source/{PROJECT}/{PACKAGE}"))
        expected_md5 = source.get("srcmd5")
        if not expected_md5:
            raise RuntimeError("OBS did not return a source checksum")
        print(f"Waiting for OBS source {expected_md5} ({commit})", flush=True)
        deadline = time.monotonic() + args.timeout
        while time.monotonic() < deadline:
            xml = run("osc", "api", f"/build/{PROJECT}/_result?package={PACKAGE}&repository={REPOSITORY}")
            print(xml, flush=True)
            if builds_ready(xml):
                matching = True
                for arch in sorted(ARCHES):
                    info = ET.fromstring(run("osc", "api", f"/build/{PROJECT}/{REPOSITORY}/{arch}/{PACKAGE}/_buildinfo"))
                    matching &= info.findtext("srcmd5") == expected_md5
                if matching:
                    break
            time.sleep(20)
        else:
            raise TimeoutError("OBS has not published the requested source on all architectures")
        output = args.output.resolve()
        output.mkdir(parents=True, exist_ok=True)
        print(run("osc", "getbinaries", PROJECT, PACKAGE, REPOSITORY, "x86_64", "-d", output), flush=True)
        rpms = list(output.glob("elklock-*.noarch.rpm"))
        if len(rpms) != 1:
            raise RuntimeError(f"Expected one noarch RPM, got {rpms}")
        info = run("rpm", "-qp", "--qf", "%{NAME}\t%{VERSION}\t%{ARCH}\t%{VENDOR}\t%{RSAHEADER:pgpsig}\t%{DISTURL}", rpms[0])
        validate_rpm_info(info, version, expected_md5)
        print(f"Verified OBS RPM: {rpms[0].name}", flush=True)


if __name__ == "__main__":
    main()
