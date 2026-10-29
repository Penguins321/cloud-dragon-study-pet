"""Build a locally signed Mac ZIP on Windows; no Apple credentials required."""
import hashlib
import os
from pathlib import Path
import plistlib
import runpy
import shutil
import struct
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE_SHA = "88df5e2e6fee99088699be66e6d42e4da4fb0c5619d054297d755a49558a4792"


def validate(archive):
    """Check bundle metadata, executable mode, universal slices and signatures."""
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None, "Corrupt ZIP"
        info_name = next(n for n in z.namelist() if n.endswith("/Contents/Info.plist"))
        bundle = info_name.split("/", 1)[0]
        info = plistlib.loads(z.read(info_name))
        binary_name = bundle + "/Contents/MacOS/" + info["CFBundleExecutable"]
        assert (z.getinfo(binary_name).external_attr >> 16) & 0o111, "Missing executable permission"
        assert bundle + "/Contents/_CodeSignature/CodeResources" in z.namelist()
        data = z.read(binary_name)
        magic, count = struct.unpack_from(">II", data)
        assert magic == 0xCAFEBABE and count == 2, "Expected Universal 2 binary"
        cpus = set()
        for i in range(count):
            cpu, _, offset, size, _ = struct.unpack_from(">IIIII", data, 8 + i * 20)
            cpus.add(cpu)
            assert offset + size <= len(data)
            assert struct.unpack_from("<I", data, offset)[0] == 0xFEEDFACF
            ncmds = struct.unpack_from("<I", data, offset + 16)[0]
            cursor, signed = offset + 32, False
            for _ in range(ncmds):
                cmd, length = struct.unpack_from("<II", data, cursor)
                if cmd == 0x1D:  # LC_CODE_SIGNATURE
                    start, length_sig = struct.unpack_from("<II", data, cursor + 8)
                    signed = length_sig > 0 and start + length_sig <= size
                assert length >= 8
                cursor += length
            assert signed, "Missing architecture code signature"
        assert cpus == {0x01000007, 0x0100000C}
        return bundle


def run_checked(command, env):
    # Godot can exit 0 after a script/shader failure; logs are part of the gate.
    result = subprocess.run(command, env=env, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, encoding="utf-8",
                            errors="replace", check=True)
    print(result.stdout, end="", flush=True)
    if "SCRIPT ERROR:" in result.stdout or any(line.startswith("ERROR:") for line in result.stdout.splitlines()):
        raise RuntimeError("Godot reported an error; package verification stopped")


def main():
    b = runpy.run_path(str(ROOT / "scripts/bootstrap-godot.py"))
    engine_dir = ROOT / ".tools" / ("godot-" + b["VERSION"])
    engine = engine_dir / ("Godot_v" + b["VERSION"] + "-stable_win64_console.exe")
    if not engine.is_file():
        raise SystemExit("Run setup-dev.ps1 first")
    template = ROOT / ".tools/templates/macos.zip"
    if not b["verified"](template, TEMPLATE_SHA):
        print("Downloading official Mac export template...", flush=True)
        with zipfile.ZipFile(b["RemoteZip"](b["BASE"] + "Godot_v" + b["VERSION"] + "-stable_export_templates.tpz")) as z:
            data = z.read("templates/macos.zip")
        if hashlib.sha256(data).hexdigest() != TEMPLATE_SHA:
            raise SystemExit("Template checksum mismatch")
        template.parent.mkdir(parents=True, exist_ok=True)
        template.write_bytes(data)
    installed = engine_dir / "editor_data/export_templates" / (b["VERSION"] + ".stable")
    installed.mkdir(parents=True, exist_ok=True)
    shutil.copy2(template, installed / "macos.zip")
    out = ROOT / "desktop-pet/build/macos"
    out.mkdir(parents=True, exist_ok=True)
    raw = out / "WarmJade-export.zip"
    env = dict(os.environ, APPDATA=str(ROOT / ".tools/appdata"))
    command = [str(engine), "--headless", "--path", str(ROOT / "desktop-pet")]
    run_checked(command + ["--script", "res://tests/write_notices.gd"], env)
    run_checked(command + ["--export-release", "macOS", str(raw)], env)
    bundle = validate(raw)
    with zipfile.ZipFile(raw) as z:
        info = plistlib.loads(z.read(bundle + "/Contents/Info.plist"))
    version = info["CFBundleShortVersionString"]
    if not all(part.isdigit() for part in version.split(".")):
        raise SystemExit("Invalid package version")
    final = out / ("WarmJade-Friends-macOS-" + version + ".zip")
    # Rename only the outer directory; signed bundle contents remain byte-for-byte unchanged.
    with zipfile.ZipFile(raw) as source, zipfile.ZipFile(final, "w", zipfile.ZIP_DEFLATED) as dest:
        for info in source.infolist():
            data = source.read(info)
            info.filename = "WarmJade.app" + info.filename[len(bundle):]
            dest.writestr(info, data)
        dest.write(ROOT / "desktop-pet/packaging/朋友安装说明-macOS.txt", "安装说明.txt")
        for name in ("GODOT-LICENSE.txt", "GODOT-THIRD-PARTY.json", "GOBKIT-ASSETS.txt"):
            dest.write(ROOT / "desktop-pet/build" / name, name)
    validate(final)
    # Verify actual exported scripts, not the source checkout or strings in a ZIP.
    with tempfile.TemporaryDirectory(prefix="mac-font-inspect-", dir=ROOT / ".tools") as scratch:
        scratch = Path(scratch)
        (scratch / "project.godot").write_text("config_version=5\n", encoding="utf-8")
        shutil.copy2(ROOT / "scripts/verify-macos-fonts.gd", scratch / "verify.gd")
        with zipfile.ZipFile(final) as z:
            pck = next(n for n in z.namelist() if n.endswith(".pck"))
            (scratch / "package.pck").write_bytes(z.read(pck))
        inspect_env = dict(env, INSPECT_PCK=str(scratch / "package.pck"), CLOUD_DRAGON_DATA_DIR=str(scratch / "user-data"))
        run_checked([str(engine), "--headless", "--path", str(scratch), "--script", "res://verify.gd"], inspect_env)
    # Verify the Mac PCK's actual 3D assets with the local GPU as well. This
    # is a Windows-host check and does not claim native macOS acceptance.
    with tempfile.TemporaryDirectory(prefix="mac-render-inspect-", dir=ROOT / ".tools") as scratch:
        scratch = Path(scratch)
        (scratch / "project.godot").write_text("config_version=5\n", encoding="utf-8")
        shutil.copy2(ROOT / "scripts/verify-macos-fonts.gd", scratch / "verify.gd")
        with zipfile.ZipFile(final) as z:
            (scratch / "package.pck").write_bytes(z.read(next(n for n in z.namelist() if n.endswith(".pck"))))
        inspect_env = dict(env, INSPECT_PCK=str(scratch / "package.pck"), CLOUD_DRAGON_DATA_DIR=str(scratch / "user-data"))
        run_checked([str(engine), "--rendering-method", "gl_compatibility", "--path", str(scratch), "--script", "res://verify.gd", "--", "--render-check"], inspect_env)
    digest = hashlib.sha256(final.read_bytes()).hexdigest()
    final.with_suffix(".sha256").write_text(digest + "  " + final.name + "\n", encoding="ascii")
    alias = out / "WarmJade-Friends-macOS.zip"
    shutil.copy2(final, alias)
    alias.with_suffix(".sha256").write_text(digest + "  " + alias.name + "\n", encoding="ascii")
    print("VERIFIED ZIP: " + str(final))
    print("SHA256: " + digest)


if __name__ == "__main__":
    main()
