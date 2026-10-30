"""Portable launcher tests; use system Bash or Git for Windows Bash."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "启动温玉灵核.command"
BASH = "/bin/bash" if os.name != "nt" else None
if os.name == "nt" and shutil.which("git"):
    git_bash = Path(shutil.which("git")).resolve().parents[1] / "bin/bash.exe"
    if git_bash.exists():
        BASH = str(git_bash)

@unittest.skipUnless(BASH, "Bash is required")
class LauncherTests(unittest.TestCase):
    def setUp(self):
        temp_root = Path(os.environ.get("MACOS_LAUNCHER_TEST_TMP", tempfile.gettempdir())).resolve()
        self.temp = tempfile.TemporaryDirectory(dir=temp_root)
        self.assertEqual(Path(self.temp.name).resolve().parent, temp_root)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "项目 with spaces"
        self.root.mkdir()
        self.launcher = self.root / SOURCE.name
        shutil.copyfile(SOURCE, self.launcher)
        (self.root / "desktop-pet").mkdir()
        (self.root / "desktop-pet/project.godot").write_text("config_version=5\n")
        self.engine = self.root / "Custom Godot.app/Contents/MacOS/Godot"
        self.engine.parent.mkdir(parents=True)
        self.engine.write_text("""#!/bin/bash
printf 'CALL\n' >> "$CALL_LOG"
printf '%s\n' "$@" >> "$CALL_LOG"
printf 'END\n' >> "$CALL_LOG"
if [[ "${1:-}" == '--version' ]]; then
  echo "${FAKE_GODOT_VERSION:-4.7.2.stable.official.test}"
  exit 0
fi
for arg in "$@"; do
  if [[ "$arg" == '--import' ]]; then exit "${FAKE_GODOT_IMPORT_EXIT:-0}"; fi
done
exit "${FAKE_GODOT_RUN_EXIT:-0}"
""", encoding="utf-8", newline="\n")
        self.engine.chmod(0o755)
        self.log = self.root / "calls.txt"
        self.env = dict(os.environ, GODOT=self.engine.as_posix(), CALL_LOG=self.log.as_posix())

    def run_launcher(self, *args, **updates):
        return subprocess.run([BASH, str(self.launcher), *args], cwd=self.temp.name,
                              env=dict(self.env, **updates), stdin=subprocess.DEVNULL,
                              capture_output=True, text=True, encoding="utf-8", timeout=20)

    def calls(self):
        return [part.splitlines() for part in self.log.read_text(encoding="utf-8").split("CALL\n")[1:]]

    def test_import_then_launch_from_arbitrary_directory(self):
        result = self.run_launcher("--", "--preview-settings", "value with spaces")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        calls = self.calls()
        self.assertEqual(len(calls), 3)
        self.assertEqual(calls[0], ["--version", "END"])
        self.assertIn("--import", calls[1])
        self.assertIn("--headless", calls[1])
        self.assertIn("--editor", calls[1])
        self.assertEqual(calls[2][-4:], ["--", "--preview-settings", "value with spaces", "END"])
        self.assertEqual(calls[1][calls[1].index("--path") + 1], calls[2][1])
        self.assertTrue(calls[2][1].endswith("项目 with spaces/desktop-pet"))

    def test_accepts_app_bundle_override(self):
        result = self.run_launcher(GODOT=self.engine.parents[2].as_posix())
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_missing_engine_explains_setup(self):
        result = self.run_launcher(GODOT=(self.root / "Missing.app").as_posix())
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Godot", result.stdout + result.stderr)
        self.assertIn("4.7.2", result.stdout + result.stderr)
        self.assertFalse(self.log.exists())

    def test_wrong_engine_version_does_not_import(self):
        result = self.run_launcher(FAKE_GODOT_VERSION="4.6.stable.official.test")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn("4.7.2", result.stdout + result.stderr)

    def test_import_failure_stops_before_game(self):
        result = self.run_launcher(FAKE_GODOT_IMPORT_EXIT="7")
        self.assertEqual(result.returncode, 7)
        self.assertEqual(len(self.calls()), 2)

    def test_game_failure_is_reported(self):
        result = self.run_launcher(FAKE_GODOT_RUN_EXIT="9")
        self.assertEqual(result.returncode, 9)
        self.assertIn("9", result.stdout + result.stderr)

    def test_missing_project_does_not_start_engine(self):
        (self.root / "desktop-pet/project.godot").unlink()
        result = self.run_launcher()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.log.exists())

if __name__ == "__main__":
    unittest.main()
