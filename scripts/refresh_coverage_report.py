#!/usr/bin/env python3
"""Refresh Tests/TEST_COVERAGE.md from SwiftPM's code-coverage JSON.

Run after generating coverage data:

    swift test --traits EnableGraphAPI --enable-code-coverage
    python3 scripts/refresh_coverage_report.py

Use ``--minimum 87.5`` to fail when weighted line coverage drops below the
documented floor. Pass ``--check`` to print the summary without rewriting the
report.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPORT = ROOT / "Tests" / "TEST_COVERAGE.md"
SOURCE_PREFIX = "/Sources/GISTools/"
FIXTURE_HEADER = "## Fixture inventory"


def coverage_json_path() -> Path:
    output = subprocess.check_output(
        ["swift", "test", "--show-codecov-path"],
        cwd=ROOT,
        text=True,
    ).strip()
    return Path(output)


def load_rows(path: Path) -> list[dict]:
    data = json.loads(path.read_text())
    files = data["data"][0]["files"]
    rows = []
    for file in files:
        filename = file["filename"]
        if SOURCE_PREFIX not in filename:
            continue
        relative = filename.split(SOURCE_PREFIX, 1)[1]
        lines = file["summary"]["lines"]
        count = int(lines["count"])
        covered = int(lines["covered"])
        percent = 100.0 * covered / count if count else 0.0
        rows.append({
            "relative": relative,
            "count": count,
            "covered": covered,
            "percent": percent,
        })
    rows.sort(key=lambda row: row["relative"])
    return rows


def existing_metadata(report: str) -> dict[str, tuple[str, str]]:
    metadata = {}
    for line in report.splitlines():
        if not line.startswith("| `Sources/GISTools/"):
            continue
        parts = line.split("|")
        if len(parts) < 8:
            continue
        source = parts[1].strip().strip("`")
        relative = source.removeprefix("Sources/GISTools/")
        metadata[relative] = (parts[5].strip(), parts[6].strip())
    return metadata


def status_for(percent: float, count: int) -> str:
    if count == 0 or percent <= 0.0:
        return "Untested"
    if percent >= 90.0:
        return "Covered"
    if percent >= 50.0:
        return "Partial"
    return "Low"


def build_report(rows: list[dict], metadata: dict[str, tuple[str, str]], old: str) -> str:
    total_lines = sum(row["count"] for row in rows)
    covered_lines = sum(row["covered"] for row in rows)
    total_percent = 100.0 * covered_lines / total_lines if total_lines else 0.0
    statuses = [status_for(row["percent"], row["count"]) for row in rows]
    counts = {status: statuses.count(status) for status in ("Covered", "Partial", "Low", "Untested")}

    preamble = """# Test coverage and fixture audit

Generated from `swift test --traits EnableGraphAPI --enable-code-coverage`
with SwiftPM's code-coverage JSON. The figures are line coverage for
`Sources/GISTools`; test sources are excluded from the per-file table.

## Summary

- Source files: **{files}**
- Weighted source line coverage: **{percent:.2f}%**
- Status: **{covered} covered** (≥90%), **{partial} partial** (50–90%),
  **{low} low** (1–50%), **{untested} untested** (0%).
- Every source file below has an explicit status and its direct (or indirect)
  test file.
- The remaining low-coverage algorithms are covered by the open follow-up
  issues listed in the `Gap` column; they are not silently ignored.
- The CI coverage floor is **87.5%** weighted line coverage.

## Per-file test status

| Source | Lines | Coverage | Status | Direct tests | Gap |
| --- | ---: | ---: | --- | --- | --- |
""".format(
        files=len(rows),
        percent=total_percent,
        covered=counts["Covered"],
        partial=counts["Partial"],
        low=counts["Low"],
        untested=counts["Untested"],
    )

    table = []
    for row in rows:
        direct, gap = metadata.get(row["relative"], ("—", ""))
        status = status_for(row["percent"], row["count"])
        table.append(
            f"| `Sources/GISTools/{row['relative']}` | {row['count']} | "
            f"{row['percent']:.2f}% | {status} | {direct} | {gap} |"
        )

    refresh = """
## Refresh

```bash
swift test --traits EnableGraphAPI --enable-code-coverage
python3 scripts/refresh_coverage_report.py
```

The CI gate runs the same data through
`python3 scripts/refresh_coverage_report.py --minimum 87.5 --check`.
Formatting is checked for Swift files changed by a pull request with
`swiftformat --lint --config .swiftformat <files>`.

"""

    fixture_start = old.find(FIXTURE_HEADER)
    fixture_tail = old[fixture_start:] if fixture_start >= 0 else ""
    return preamble + "\n".join(table) + "\n" + refresh + fixture_tail


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", type=Path, help="SwiftPM code-coverage JSON path")
    parser.add_argument("--minimum", type=float, help="fail below this weighted line coverage")
    parser.add_argument("--check", action="store_true", help="print summary without rewriting the report")
    args = parser.parse_args()

    path = args.json or coverage_json_path()
    rows = load_rows(path)
    old = REPORT.read_text()
    metadata = existing_metadata(old)

    total_lines = sum(row["count"] for row in rows)
    covered_lines = sum(row["covered"] for row in rows)
    percent = 100.0 * covered_lines / total_lines if total_lines else 0.0
    print(f"coverage={percent:.2f}% lines={total_lines} files={len(rows)}")

    if not args.check:
        REPORT.write_text(build_report(rows, metadata, old))

    if args.minimum is not None and percent < args.minimum:
        print(
            f"coverage {percent:.2f}% is below the {args.minimum:.2f}% floor",
            file=sys.stderr,
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
