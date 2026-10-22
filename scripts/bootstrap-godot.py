"""Prepare pinned, project-local Godot tools; Python 3.10+, standard library only."""
import hashlib
import io
import os
from pathlib import Path, PurePosixPath
import subprocess
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / ".tools"
VERSION = "4.7.2"
BASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/"
EDITOR_ZIP = f"Godot_v{VERSION}-stable_win64.exe.zip"
EDITOR_SHA = "731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953"
TEMPLATE_SHA = "51498b72b3a237f882ebd7d1787f06a4bc1eaf0572daab93837adcfd3cfdc107"


def verified(path, expected):
    return path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == expected


class RemoteZip(io.RawIOBase):
    """Read the ZIP index and selected member, avoiding the full multiplatform TPZ."""

    def __init__(self, url):
        with urllib.request.urlopen(urllib.request.Request(url, method="HEAD"), timeout=40) as response:
            self.url = response.geturl()
            self.length = int(response.headers["Content-Length"])
        self.position = 0

    def seekable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.length + offset
        return self.position

    def read(self, size=-1):
        end = self.length if size < 0 else min(self.length, self.position + size)
        if end <= self.position:
            return b""
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={self.position}-{end - 1}"})
        with urllib.request.urlopen(request, timeout=180) as response:
            if response.status != 206:
                raise RuntimeError("Server ignored Range; refusing the full template archive download")
            data = response.read()
        if len(data) != end - self.position:
            raise RuntimeError("Incomplete HTTP range response; run setup again")
        self.position = end
        return data


def main():
    if os.name != "nt":
        raise SystemExit("This bootstrap prepares Windows x64 tools only.")
    TOOLS.mkdir(exist_ok=True)
    archive_path = TOOLS / f"godot-{VERSION}.zip"
    if not verified(archive_path, EDITOR_SHA):
        print("Downloading pinned Godot Windows standard editor...", flush=True)
        temporary = archive_path.with_suffix(".zip.tmp")
        urllib.request.urlretrieve(BASE + EDITOR_ZIP, temporary)
        if not verified(temporary, EDITOR_SHA):
            raise SystemExit("Editor SHA256 mismatch; refusing extraction.")
        temporary.replace(archive_path)
    editor_dir = TOOLS / f"godot-{VERSION}"
    editor_dir.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive_path) as archive:
        for name in archive.namelist():
            # Only known flat executables, never extract archive-provided paths.
            if PurePosixPath(name).name == name and name.endswith(".exe"):
                (editor_dir / name).write_bytes(archive.read(name))
    (editor_dir / "_sc_").touch()
    template = TOOLS / "templates" / "windows_debug_x86_64.exe"
    if not verified(template, TEMPLATE_SHA):
        print("Downloading only the Windows x64 debug export template...", flush=True)
        with zipfile.ZipFile(RemoteZip(BASE + f"Godot_v{VERSION}-stable_export_templates.tpz")) as archive:
            member = next(n for n in archive.namelist() if n.endswith("/windows_debug_x86_64.exe"))
            data = archive.read(member)  # CRC checked by ZipFile.
        if hashlib.sha256(data).hexdigest() != TEMPLATE_SHA:
            raise SystemExit("Template SHA256 mismatch; refusing installation.")
        template.parent.mkdir(exist_ok=True)
        temporary = template.with_suffix(".exe.tmp")
        temporary.write_bytes(data)
        temporary.replace(template)
    engine = editor_dir / f"Godot_v{VERSION}-stable_win64_console.exe"
    env = dict(os.environ, APPDATA=str(TOOLS / "appdata"))
    Path(env["APPDATA"]).mkdir(exist_ok=True)
    subprocess.run([str(engine), "--version"], check=True, env=env)
    # A fresh checkout needs its import cache before headless script tests.
    subprocess.run([str(engine), "--headless", "--editor", "--path", str(ROOT / "desktop-pet"), "--import"], check=True, env=env)
    print("Ready. Run ./test-prototype.ps1, then ./build-prototype.ps1", flush=True)


if __name__ == "__main__":
    main()
