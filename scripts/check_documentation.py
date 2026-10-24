#!/usr/bin/env python3
"""Build the GISTools DocC catalog and reject documentation diagnostics.

The catalog is built with the default package traits, matching Swift Package
Index. Articles should therefore link to always-available symbols and use code
formatting for the optional Graph API.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Sources" / "GISTools" / "GISTools.docc"
SYMBOL_DIR = ROOT / ".build" / "documentation-symbols"
DIAGNOSTICS = ROOT / ".build" / "documentation-diagnostics.json"


def target_triple() -> str:
    output = subprocess.check_output(["swift", "-print-target-info"], cwd=ROOT, text=True)
    return json.loads(output)["target"]["triple"]


def build_symbol_graph() -> Path:
    subprocess.run(["swift", "build"], cwd=ROOT, check=True)
    bin_path = subprocess.check_output(
        ["swift", "build", "--show-bin-path"],
        cwd=ROOT,
        text=True,
    ).strip()

    if SYMBOL_DIR.exists():
        shutil.rmtree(SYMBOL_DIR)
    SYMBOL_DIR.mkdir(parents=True)
    subprocess.run(
        [
            "swift",
            "symbolgraph-extract",
            "-module-name",
            "GISTools",
            "-I",
            bin_path,
            "-I",
            "Sources/GISToolsCZlib",
            "-target",
            target_triple(),
            "-minimum-access-level",
            "public",
            "-output-dir",
            str(SYMBOL_DIR),
        ],
        cwd=ROOT,
        check=True,
    )
    return SYMBOL_DIR


def source_path(diagnostic: dict) -> Path | None:
    source = diagnostic.get("source")
    if not source:
        return None
    parsed = urlparse(source)
    if parsed.scheme != "file":
        return Path(source)
    return Path(unquote(parsed.path))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / ".build" / "documentation",
        help="DocC archive output directory",
    )
    args = parser.parse_args()

    if shutil.which("docc") is None:
        print("docc is not installed or not on PATH", file=sys.stderr)
        sys.exit(2)

    symbols = build_symbol_graph()
    if DIAGNOSTICS.exists():
        DIAGNOSTICS.unlink()

    process = subprocess.run(
        [
            "docc",
            "convert",
            str(CATALOG),
            "--additional-symbol-graph-dir",
            str(symbols),
            "--output-dir",
            str(args.output),
            "--diagnostics-file",
            str(DIAGNOSTICS),
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )

    diagnostics = []
    if DIAGNOSTICS.exists():
        diagnostics = json.loads(DIAGNOSTICS.read_text()).get("diagnostics", [])

    issues = [
        diagnostic
        for diagnostic in diagnostics
        if diagnostic.get("severity") in ("warning", "error")
    ]

    for diagnostic in issues:
        path = source_path(diagnostic)
        location = ""
        if path is not None and "range" in diagnostic:
            start = diagnostic["range"]["start"]
            location = f"{path}:{start['line']}:{start['column']}: "
        print(
            f"{location}{diagnostic.get('severity', 'warning')}: "
            f"{diagnostic.get('summary', 'documentation diagnostic')}",
            file=sys.stderr,
        )

    if process.returncode != 0:
        if process.stdout:
            print(process.stdout, end="")
        if process.stderr:
            print(process.stderr, end="", file=sys.stderr)
        sys.exit(process.returncode)
    if issues:
        sys.exit(1)

    print(f"Documentation built at {args.output} with no diagnostics.")


if __name__ == "__main__":
    main()
