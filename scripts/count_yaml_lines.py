#!/usr/bin/env python3
"""Count non-empty and non-comment YAML/template lines for VKR comparison."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Iterable

SUPPORTED_SUFFIXES = {".yaml", ".yml", ".tpl", ".txt"}


def iter_files(paths: Iterable[str]) -> Iterable[Path]:
    for raw_path in paths:
        path = Path(raw_path)
        if path.is_dir():
            for child in sorted(path.rglob("*")):
                if child.is_file() and child.suffix in SUPPORTED_SUFFIXES:
                    yield child
        elif path.is_file():
            yield path


def count_effective_lines(path: Path) -> int:
    count = 0
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("#"):
            continue
        count += 1
    return count


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: count_yaml_lines.py <file-or-directory> [...]")
        return 2

    total = 0
    rows: list[tuple[str, int]] = []
    for file_path in iter_files(sys.argv[1:]):
        line_count = count_effective_lines(file_path)
        rows.append((str(file_path), line_count))
        total += line_count

    width = max((len(name) for name, _ in rows), default=10)
    for name, line_count in rows:
        print(f"{name:<{width}}  {line_count:>5}")
    print("-" * (width + 8))
    print(f"{'TOTAL':<{width}}  {total:>5}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
