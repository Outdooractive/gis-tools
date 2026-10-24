#!/usr/bin/env python3
"""Run representative benchmark suites and compare them to a stored baseline.

Each platform/architecture has its own baseline:

    Benchmarks/Baselines/<system>-<machine>.json

Run ``--update`` intentionally after a performance change and commit the
result. Run without ``--update`` to compare and fail on large regressions.
"""

from __future__ import annotations

import argparse
import json
import platform
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BIN_DIR = "release"
DEFAULT_SUITES = (
    "loading",
    "projection",
    "overlay",
    "rtree",
    "buffer",
    "simplify",
    "graph",
    "memory",
)
FIXTURE = Path("/tmp/gis-tools-benchmark.geojson")
TIME_FLOOR_SECONDS = 0.0005
RSS_FLOOR_MB = 1.0


def swift_version() -> str:
    output = subprocess.check_output(["swift", "--version"], cwd=ROOT, text=True)
    return output.splitlines()[0].strip()


def build_benchmark() -> Path:
    subprocess.run(
        ["swift", "build", "-c", BIN_DIR, "--product", "Benchmarks", "--traits", "EnableGraphAPI"],
        cwd=ROOT,
        check=True,
    )
    bin_path = subprocess.check_output(
        ["swift", "build", "-c", BIN_DIR, "--show-bin-path", "--traits", "EnableGraphAPI"],
        cwd=ROOT,
        text=True,
    ).strip()
    binary = Path(bin_path) / "Benchmarks"
    if not binary.is_file():
        raise FileNotFoundError(f"Benchmark binary not found at {binary}")
    return binary


def run_suites(binary: Path, suites: list[str]) -> dict:
    if not FIXTURE.exists():
        print("Generating benchmark fixture...")
        subprocess.run([str(binary), "gen"], cwd=ROOT, check=True)

    results = {}
    for suite in suites:
        print(f"Running {suite}...", flush=True)
        start = time.perf_counter()
        process = subprocess.run(
            [str(binary), suite],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=True,
        )
        wall_seconds = time.perf_counter() - start
        output = process.stdout + process.stderr
        benchmarks = {}
        metrics = {}
        peak_rss_mb = None
        for line in output.splitlines():
            match = re.match(r"^bench=(\S+)\s+seconds=([0-9.]+)$", line)
            if match:
                benchmarks[match.group(1)] = float(match.group(2))
                continue
            rss_match = re.match(r"^peak_rss_mb=([0-9.]+)", line)
            if rss_match:
                peak_rss_mb = float(rss_match.group(1))
                continue
            metric_match = re.match(r"^([^=\s]+)=([0-9.]+)$", line)
            if metric_match:
                metrics[metric_match.group(1)] = float(metric_match.group(2))

        results[suite] = {
            "wall_seconds": round(wall_seconds, 6),
            "peak_rss_mb": peak_rss_mb,
            "benchmarks": benchmarks,
            "metrics": metrics,
        }
    return results


def baseline_path() -> Path:
    system = platform.system().lower()
    machine = platform.machine().lower()
    return ROOT / "Benchmarks" / "Baselines" / f"{system}-{machine}.json"


def load_baseline(path: Path) -> dict | None:
    if not path.is_file():
        return None
    return json.loads(path.read_text())


def write_baseline(path: Path, results: dict) -> None:
    payload = {
        "schema": 1,
        "platform": platform.system().lower(),
        "machine": platform.machine().lower(),
        "swift": swift_version(),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "suites": results,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    print(f"Wrote baseline {path}")


def percent_delta(current: float, baseline: float) -> float | None:
    guard = 0.000000001
    if abs(baseline) <= guard:
        return None
    return (current - baseline) / baseline


def format_metric(value: float) -> str:
    if value.is_integer():
        return str(int(value))
    return f"{value:g}"


def compare(results: dict, baseline: dict, threshold: float, metric_threshold: float) -> bool:
    failures = []
    print("\n| Suite | Benchmark | Current | Baseline | Delta | Status |")
    print("| --- | --- | ---: | ---: | ---: | --- |")

    for suite, current_suite in results.items():
        baseline_suite = baseline.get("suites", {}).get(suite)
        if baseline_suite is None:
            print(f"| `{suite}` | — | — | — | — | no baseline |")
            continue

        for name, current_seconds in current_suite["benchmarks"].items():
            baseline_seconds = baseline_suite.get("benchmarks", {}).get(name)
            if baseline_seconds is None:
                print(f"| `{suite}` | `{name}` | {current_seconds:.6f}s | — | — | new |")
                continue
            if baseline_seconds < TIME_FLOOR_SECONDS:
                print(
                    f"| `{suite}` | `{name}` | {current_seconds:.6f}s | "
                    f"{baseline_seconds:.6f}s | — | below timing floor |")
                continue
            delta = percent_delta(current_seconds, baseline_seconds)
            status = "ok"
            if delta is not None and delta > threshold:
                status = "**regression**"
                failures.append(f"{suite}/{name}: {delta:+.1%}")
            print(
                f"| `{suite}` | `{name}` | {current_seconds:.6f}s | "
                f"{baseline_seconds:.6f}s | {delta:+.1%} | {status} |")

        current_rss = current_suite.get("peak_rss_mb")
        baseline_rss = baseline_suite.get("peak_rss_mb")
        if current_rss is not None and baseline_rss is not None:
            if baseline_rss < RSS_FLOOR_MB:
                status = "below RSS floor"
                delta = None
            else:
                delta = percent_delta(current_rss, baseline_rss)
                status = "ok"
                if delta is not None and delta > threshold:
                    status = "**regression**"
                    failures.append(f"{suite}/peak_rss: {delta:+.1%}")
            print(
                f"| `{suite}` | `peak_rss_mb` | {current_rss:.1f} | "
                f"{baseline_rss:.1f} | "
                f"{'—' if delta is None else f'{delta:+.1%}'} | {status} |")

        for name, current_value in current_suite.get("metrics", {}).items():
            baseline_value = baseline_suite.get("metrics", {}).get(name)
            if baseline_value is None:
                print(
                    f"| `{suite}` | `{name}` | {format_metric(current_value)} | — | — | new |")
                continue
            delta = percent_delta(current_value, baseline_value)
            status = "ok"
            if delta is not None and delta > metric_threshold:
                status = "**regression**"
                failures.append(f"{suite}/{name}: {delta:+.1%}")
            print(
                f"| `{suite}` | `{name}` | {format_metric(current_value)} | "
                f"{format_metric(baseline_value)} | "
                f"{'—' if delta is None else f'{delta:+.1%}'} | {status} |")

    print()
    if failures:
        print(
            f"Benchmark regressions above {threshold:.0%} "
            f"(memory metrics above {metric_threshold:.0%}):")
        for failure in failures:
            print(f"- {failure}")
        return False

    print(
        f"No benchmark regressions above {threshold:.0%} "
        f"(memory metrics above {metric_threshold:.0%}).")
    return True


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("suites", nargs="*", default=list(DEFAULT_SUITES))
    parser.add_argument("--baseline", type=Path, help="baseline JSON path")
    parser.add_argument("--update", action="store_true", help="write a new baseline")
    parser.add_argument("--threshold", type=float, default=0.20, help="time/RSS regression threshold (default 0.20)")
    parser.add_argument(
        "--metric-threshold",
        type=float,
        default=0.50,
        help="memory metric regression threshold (default 0.50)")
    parser.add_argument("--report-only", action="store_true", help="never fail on regressions")
    args = parser.parse_args()

    suites = args.suites or list(DEFAULT_SUITES)
    path = args.baseline or baseline_path()
    baseline = None if args.update else load_baseline(path)
    if not args.update and baseline is None:
        print(
            f"No benchmark baseline at {path}.\n"
            "Generate one intentionally with:\n"
            f"  python3 scripts/benchmark_compare.py --update {' '.join(suites)}",
            file=sys.stderr,
        )
        return

    binary = build_benchmark()
    results = run_suites(binary, suites)

    if args.update:
        existing = load_baseline(path)
        if existing is not None:
            merged = dict(existing.get("suites", {}))
            merged.update(results)
            results = merged
        write_baseline(path, results)
        return

    passed = compare(results, baseline, args.threshold, args.metric_threshold)
    if not passed and not args.report_only:
        sys.exit(1)


if __name__ == "__main__":
    main()
