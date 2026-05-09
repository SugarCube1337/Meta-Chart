#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

EXTENSIONS = {".yaml", ".yml"}


def count_lines(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    return sum(1 for line in text.splitlines() if line.strip() and not line.lstrip().startswith("#"))


def iter_yaml_files(path: Path):
    if path.is_file() and path.suffix.lower() in EXTENSIONS:
        yield path
    elif path.is_dir():
        for item in sorted(path.rglob("*")):
            if item.is_file() and item.suffix.lower() in EXTENSIONS:
                yield item


def main(argv: list[str]) -> int:
    if not argv:
        print("Usage: count_yaml_lines.py <file-or-directory> [...]")
        return 1

    rows: list[tuple[str, int]] = []
    for raw in argv:
        path = Path(raw)
        for file in iter_yaml_files(path):
            rows.append((str(file), count_lines(file)))

    if not rows:
        print("No YAML files found")
        return 1

    width = max(len(name) for name, _ in rows)
    total = 0
    for name, count in rows:
        total += count
        print(f"{name:<{width}}  {count:>6}")
    print("-" * (width + 8))
    print(f"{'TOTAL':<{width}}  {total:>6}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
