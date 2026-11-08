#!/usr/bin/env python3
import os
import sys
import tempfile
from pathlib import Path


NOTION_HEADER = "[mcp_servers.notion-api]"


def remove_notion_table(content: str) -> list[str]:
    retained: list[str] = []
    skipping = False

    for line in content.splitlines():
        stripped = line.strip()
        if stripped == NOTION_HEADER:
            skipping = True
            continue
        if skipping and stripped.startswith("["):
            skipping = False
        if not skipping:
            retained.append(line)

    while retained and retained[-1] == "":
        retained.pop()
    return retained


def render_config(content: str, command: str) -> str:
    escaped_command = command.replace("\\", "\\\\").replace('"', '\\"')
    retained = remove_notion_table(content)
    if retained:
        retained.append("")
    retained.extend(
        [
            NOTION_HEADER,
            f'command = "{escaped_command}"',
        ]
    )
    return "\n".join(retained) + "\n"


def write_config(config_path: Path, content: str) -> None:
    config_path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        dir=config_path.parent,
        prefix=f".{config_path.name}.",
    )
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as output:
            output.write(content)
        os.replace(temporary_name, config_path)
        config_path.chmod(0o600)
    except BaseException:
        try:
            os.close(descriptor)
        except OSError:
            pass
        Path(temporary_name).unlink(missing_ok=True)
        raise


def main(arguments: list[str]) -> int:
    if len(arguments) != 2:
        print(
            "usage: reconcile_notion_config.py CONFIG COMMAND",
            file=sys.stderr,
        )
        return 2

    config_path = Path(arguments[0])
    current = config_path.read_text(encoding="utf-8") if config_path.exists() else ""
    write_config(config_path, render_config(current, arguments[1]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
