#!/usr/bin/env python3
"""Fail when a pull request adds SwiftFormat violations.

The repository has legacy formatting differences in many files. This gate
compares the violation count for every Swift file changed by the PR against
the same file at the base ref, so existing debt is tolerated but new
violations are not.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / ".swiftformat"


def changed_files(base: str) -> list[Path]:
    output = subprocess.check_output(
        ["git", "diff", "--name-only", "--diff-filter=ACMRT", f"{base}...HEAD", "--", "*.swift"],
        cwd=ROOT,
        text=True,
    )
    return [ROOT / line for line in output.splitlines() if line.strip()]


def violation_count(path: Path, swiftformat: str) -> tuple[int, str]:
    result = subprocess.run(
        [swiftformat, "--lint", "--config", str(CONFIG), str(path)],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    output = result.stdout + result.stderr
    errors = [line for line in output.splitlines() if ": error:" in line]
    if result.returncode not in (0, 1, 70) and not errors:
        raise RuntimeError(f"SwiftFormat failed for {path}:\n{output}")
    return len(errors), output


def base_violation_count(base: str, relative: Path, swiftformat: str) -> int:
    try:
        source = subprocess.check_output(
            ["git", "show", f"{base}:{relative.as_posix()}"],
            cwd=ROOT,
            text=True,
        )
    except subprocess.CalledProcessError:
        return 0

    with tempfile.TemporaryDirectory(prefix="gis-tools-swiftformat-") as temp:
        path = Path(temp) / relative.name
        path.write_text(source)
        count, _ = violation_count(path, swiftformat)
        return count


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="origin/main")
    parser.add_argument("--swiftformat", default="swiftformat")
    args = parser.parse_args()

    files = changed_files(args.base)
    if not files:
        print("No Swift files changed.")
        return

    regressions = []
    for path in files:
        if not path.exists():
            continue
        relative = path.relative_to(ROOT)
        head_count, head_output = violation_count(path, args.swiftformat)
        base_count = base_violation_count(args.base, relative, args.swiftformat)
        print(f"{relative}: base={base_count} head={head_count}")
        if head_count > base_count:
            regressions.append((relative, base_count, head_count, head_output))

    if regressions:
        for relative, base_count, head_count, output in regressions:
            print(
                f"\n{relative}: formatting violations increased "
                f"from {base_count} to {head_count}",
                file=sys.stderr,
            )
            print(output, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
