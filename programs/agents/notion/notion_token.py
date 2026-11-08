#!/usr/bin/env python3
import json
import os
import sys
import tempfile
from pathlib import Path


ERROR = "notion_token must be a non-empty string"


def read_token(secrets_path: Path) -> str:
    try:
        data = json.loads(secrets_path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError) as error:
        raise ValueError(ERROR) from error

    token = data.get("notion_token")
    if not isinstance(token, str) or not token.strip():
        raise ValueError(ERROR)
    return token.strip()


def write_token(token: str, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        dir=output_path.parent,
        prefix=f".{output_path.name}.",
    )
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as output:
            output.write(token)
        os.replace(temporary_name, output_path)
        output_path.chmod(0o600)
    except BaseException:
        try:
            os.close(descriptor)
        except OSError:
            pass
        Path(temporary_name).unlink(missing_ok=True)
        raise


def main(arguments: list[str]) -> int:
    if len(arguments) not in (2, 3) or arguments[0] not in {"check", "write"}:
        print(
            "usage: notion_token.py check SECRETS_JSON | "
            "notion_token.py write SECRETS_JSON OUTPUT",
            file=sys.stderr,
        )
        return 2

    try:
        token = read_token(Path(arguments[1]))
        if arguments[0] == "write":
            if len(arguments) != 3:
                return 2
            write_token(token, Path(arguments[2]))
    except ValueError as error:
        print(error, file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
