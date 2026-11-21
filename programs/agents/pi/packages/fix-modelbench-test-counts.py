#!/usr/bin/env python3
"""Teach pi-modelbench to count Node's default TAP test summaries."""

import json
import sys
from pathlib import Path

EXPECTED_VERSION = "0.1.2"
OLD_PARSER = '''export function parseTestCounts(output: string): { testsPassed: number | null; testsTotal: number | null } {
  const nodeTotal = output.match(/(?:^|\\n)\\s*ℹ\\s+tests\\s+(\\d+)/i);
  const nodePassed = output.match(/(?:^|\\n)\\s*ℹ\\s+pass\\s+(\\d+)/i);
  if (nodeTotal || nodePassed) return { testsTotal: nodeTotal ? Number(nodeTotal[1]) : null, testsPassed: nodePassed ? Number(nodePassed[1]) : null };
'''
NEW_PARSER = '''export function parseTestCounts(output: string): { testsPassed: number | null; testsTotal: number | null } {
  const nodeTotal = output.match(/(?:^|\\n)\\s*(?:ℹ|#)\\s+tests\\s+(\\d+)/i);
  const nodePassed = output.match(/(?:^|\\n)\\s*(?:ℹ|#)\\s+pass\\s+(\\d+)/i);
  if (nodeTotal || nodePassed) return { testsTotal: nodeTotal ? Number(nodeTotal[1]) : null, testsPassed: nodePassed ? Number(nodePassed[1]) : null };
'''


def patch_package(package_dir: Path) -> None:
    manifest = json.loads((package_dir / "package.json").read_text())
    if manifest.get("name") != "pi-modelbench" or manifest.get("version") != EXPECTED_VERSION:
        raise RuntimeError(
            f"Unsupported pi-modelbench version: {manifest.get('name')}@{manifest.get('version')}"
        )

    source = package_dir / "src" / "core" / "coding-workspace.ts"
    text = source.read_text()
    if NEW_PARSER in text:
        return
    if OLD_PARSER not in text:
        raise RuntimeError(f"Unexpected pi-modelbench parser source: {source}")
    source.write_text(text.replace(OLD_PARSER, NEW_PARSER, 1))


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} <pi-modelbench package directory>", file=sys.stderr)
        return 2

    patch_package(Path(sys.argv[1]))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, json.JSONDecodeError, RuntimeError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
