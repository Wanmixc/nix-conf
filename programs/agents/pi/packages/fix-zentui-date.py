#!/usr/bin/env python3
"""Add a calendar date segment to the installed pi-zentui footer."""

import json
import sys
from pathlib import Path

EXPECTED_VERSION = "0.18.1"
OLD_FOOTER = '''\tformatTimeLabel,
\tformatUsernameHostLabel,
'''
NEW_FOOTER = '''\tformatTimeLabel,
\tformatDateLabel,
\tformatUsernameHostLabel,
'''
OLD_FOOTER_CASE = '''\t\t\t\t\t\tcase "time":
\t\t\t\t\t\t\treturn renderStyleForSource(
\t\t\t\t\t\t\t\ttheme,
\t\t\t\t\t\t\t\tcolorSource,
\t\t\t\t\t\t\t\tconfig.colors.time,
\t\t\t\t\t\t\t\tformatTimeLabel(config.icons.time),
\t\t\t\t\t\t\t);
'''
DATE_FOOTER_CASE = '''\t\t\t\t\t\tcase "date":
\t\t\t\t\t\t\treturn renderStyleForSource(
\t\t\t\t\t\t\t\ttheme,
\t\t\t\t\t\t\t\tcolorSource,
\t\t\t\t\t\t\t\tconfig.colors.time,
\t\t\t\t\t\t\t\tformatDateLabel(""),
\t\t\t\t\t\t\t);
'''
OLD_EMOJI_DATE_CASE = DATE_FOOTER_CASE.replace('formatDateLabel("")', 'formatDateLabel("📅")')
OLD_FORMAT = '''export function formatTimeLabel(icon: string): string {
\tconst now = new Date();
\tconst hours = String(now.getHours()).padStart(2, "0");
\tconst minutes = String(now.getMinutes()).padStart(2, "0");
\tconst label = `${hours}:${minutes}`;
\treturn icon ? `${icon} ${label}` : label;
}
'''
NEW_FORMAT = OLD_FORMAT + '''
export function formatDateLabel(icon: string, now = new Date()): string {
\tconst day = String(now.getDate()).padStart(2, "0");
\tconst month = String(now.getMonth() + 1).padStart(2, "0");
\tconst label = `${day}/${month}`;
\treturn icon ? `${icon} ${label}` : label;
}
'''


def replace_once(source: str, old: str, new: str, description: str) -> str:
    if new in source:
        return source
    if old not in source:
        raise RuntimeError(f"Unexpected pi-zentui source while patching {description}")
    return source.replace(old, new, 1)


def patch_package(package_dir: Path) -> None:
    manifest = json.loads((package_dir / "package.json").read_text())
    if manifest.get("name") != "pi-zentui" or manifest.get("version") != EXPECTED_VERSION:
        raise RuntimeError(
            f"Unsupported pi-zentui version: {manifest.get('name')}@{manifest.get('version')}"
        )

    zentui_dir = package_dir / "extensions" / "zentui"
    footer_path = zentui_dir / "footer.ts"
    footer = footer_path.read_text()
    footer = replace_once(footer, OLD_FOOTER, NEW_FOOTER, "footer imports")
    footer = footer.replace(OLD_EMOJI_DATE_CASE, "")
    if DATE_FOOTER_CASE not in footer:
        footer = replace_once(
            footer, OLD_FOOTER_CASE, OLD_FOOTER_CASE + DATE_FOOTER_CASE, "date segment"
        )
    while footer.count(DATE_FOOTER_CASE) > 1:
        footer = footer.replace(DATE_FOOTER_CASE + DATE_FOOTER_CASE, DATE_FOOTER_CASE, 1)
    footer_path.write_text(footer)

    format_path = zentui_dir / "format.ts"
    formatting = format_path.read_text()
    formatting = replace_once(formatting, OLD_FORMAT, NEW_FORMAT, "date formatter")
    format_path.write_text(formatting)


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} <pi-zentui package directory>", file=sys.stderr)
        return 2
    patch_package(Path(sys.argv[1]))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, json.JSONDecodeError, RuntimeError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1)
