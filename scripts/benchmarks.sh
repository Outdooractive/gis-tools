#!/usr/bin/env bash
#
# Runs every benchmark suite in its own process and prints a Markdown report.
#
# Usage: scripts/benchmarks.sh [suite ...]
#
# With no arguments, runs all suites. Timing is reported by the executable
# (median of its iterations); peak RSS is getrusage(RUSAGE_SELF).ru_maxrss for
# the suite process.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "Building release benchmarks..."
swift build -c release --product Benchmarks >/dev/null

BIN="$(swift build -c release --show-bin-path)/Benchmarks"
if [[ ! -x "$BIN" ]]; then
    echo "Benchmark binary not found at $BIN" >&2
    exit 1
fi

if [[ ! -f /tmp/gis-tools-benchmark.geojson ]]; then
    echo "Generating fixture..."
    "$BIN" gen
fi

SUITES=("$@")
if [[ ${#SUITES[@]} -eq 0 ]]; then
    SUITES=(loading projection predicates overlay rtree coders buffer simplify hulls line tile clip graph realworld query clusters memory inlining)
fi

printf '\n| Suite | Wall seconds | Peak RSS (MB) |\n'
printf '| --- | ---: | ---: |\n'

for suite in "${SUITES[@]}"; do
    start="$(date +%s.%N)"
    output="$("$BIN" "$suite")"
    end="$(date +%s.%N)"

    seconds="$(awk -v start="$start" -v end="$end" 'BEGIN { printf "%.3f", end - start }')"
    memory="$(printf '%s\n' "$output" | sed -n 's/^peak_rss_mb=\([^ ]*\).*/\1/p' | tail -1)"
    printf '| `%s` | %s | %s |\n' "$suite" "$seconds" "$memory"

    printf '%s\n' "$output" | grep '^bench='
done

printf '\nFixture: /tmp/gis-tools-benchmark.geojson\n'
