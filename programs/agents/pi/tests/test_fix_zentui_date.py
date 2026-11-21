import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "packages" / "fix-zentui-date.py"
SPEC = importlib.util.spec_from_file_location("fix_zentui_date", SCRIPT)
PATCHER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PATCHER)


class FixZentuiDateTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.package = Path(self.temp_dir.name) / "pi-zentui"
        source_dir = self.package / "extensions" / "zentui"
        source_dir.mkdir(parents=True)
        (self.package / "package.json").write_text('{"name":"pi-zentui","version":"0.18.1"}')
        (source_dir / "footer.ts").write_text(
            PATCHER.OLD_FOOTER + "\n" + PATCHER.OLD_FOOTER_CASE
        )
        (source_dir / "format.ts").write_text(PATCHER.OLD_FORMAT)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_patch_adds_date_segment_and_is_idempotent(self):
        PATCHER.patch_package(self.package)
        footer = (self.package / "extensions/zentui/footer.ts").read_text()
        formatting = (self.package / "extensions/zentui/format.ts").read_text()

        self.assertIn('case "date":', footer)
        self.assertIn('formatDateLabel("")', footer)
        self.assertIn('export function formatDateLabel(icon: string, now = new Date())', formatting)
        self.assertIn("${day}/${month}", formatting)
        PATCHER.patch_package(self.package)
        self.assertEqual((self.package / "extensions/zentui/footer.ts").read_text(), footer)
        self.assertEqual((self.package / "extensions/zentui/format.ts").read_text(), formatting)

    def test_patch_rejects_unexpected_package_version(self):
        manifest = self.package / "package.json"
        manifest.write_text('{"name":"pi-zentui","version":"0.19.0"}')

        with self.assertRaisesRegex(RuntimeError, "Unsupported pi-zentui version"):
            PATCHER.patch_package(self.package)


if __name__ == "__main__":
    unittest.main()
