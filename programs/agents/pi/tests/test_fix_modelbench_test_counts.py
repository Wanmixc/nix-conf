import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "packages" / "fix-modelbench-test-counts.py"
SPEC = importlib.util.spec_from_file_location("fix_modelbench_test_counts", SCRIPT)
PATCHER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PATCHER)


class FixModelbenchTestCountsTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.package = Path(self.temp_dir.name) / "pi-modelbench"
        source_dir = self.package / "src" / "core"
        source_dir.mkdir(parents=True)
        self.source = source_dir / "coding-workspace.ts"
        self.source.write_text(PATCHER.OLD_PARSER)
        (self.package / "package.json").write_text('{"name":"pi-modelbench","version":"0.1.2"}')

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_patch_recognizes_node_tap_and_spec_summaries_and_is_idempotent(self):
        PATCHER.patch_package(self.package)
        patched = self.source.read_text()

        self.assertIn("(?:ℹ|#)", patched)
        result = subprocess.run(
            [
                "node",
                "--input-type=module",
                "-e",
                "const parseTestCounts = (output) => {\n"
                + PATCHER.NEW_PARSER.split(" {\n", 1)[1]
                + "}; console.log(JSON.stringify(["
                + "parseTestCounts('# tests 3\\n# pass 2'), "
                + "parseTestCounts('ℹ tests 4\\nℹ pass 4')]))",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            json.loads(result.stdout),
            [
                {"testsTotal": 3, "testsPassed": 2},
                {"testsTotal": 4, "testsPassed": 4},
            ],
        )
        PATCHER.patch_package(self.package)
        self.assertEqual(self.source.read_text(), patched)

    def test_patch_rejects_unexpected_package_version(self):
        manifest = self.package / "package.json"
        manifest.write_text('{"name":"pi-modelbench","version":"0.2.0"}')

        with self.assertRaisesRegex(RuntimeError, "Unsupported pi-modelbench version"):
            PATCHER.patch_package(self.package)


if __name__ == "__main__":
    unittest.main()
