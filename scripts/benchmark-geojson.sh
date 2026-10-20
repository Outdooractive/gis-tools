#!/usr/bin/env bash
#
# GeoJSON loading benchmark and peak-memory report.
#
# Usage: scripts/benchmark-geojson.sh
#
# Builds the GeoJsonBenchmark executable in release mode, generates the
# synthetic 400 x 1600-vertex fixture, then runs every parsing variant in a
# separate process. Timing is the median of five runs; peak memory comes from
# /usr/bin/time (peak memory footprint on macOS, maximum RSS on Linux).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "Building release benchmark..."
swift build -c release --product GeoJsonBenchmark >/dev/null

BIN="$(swift build -c release --show-bin-path)/GeoJsonBenchmark"
if [[ ! -x "$BIN" ]]; then
    echo "Benchmark binary not found at $BIN" >&2
    exit 1
fi

echo "Generating fixture..."
"$BIN" gen

time_seconds() {
    "$BIN" "$1" 5 | sed -n 's/.*seconds=\([^ ]*\).*/\1/p'
}

peak_megabytes() {
    local mode="$1"
    local output
    local os
    os="$(uname -s)"

    if [[ -x /usr/bin/time ]]; then
        if [[ "$os" == "Darwin" ]]; then
            output="$(/usr/bin/time -l "$BIN" "$mode" 1 2>&1)"
            local bytes
            bytes="$(printf '%s\n' "$output" | sed -n 's/.*peak memory footprint: \([0-9]*\) bytes.*/\1/p' | head -1)"
            if [[ -z "$bytes" ]]; then
                bytes="$(printf '%s\n' "$output" | sed -n 's/.*maximum resident set size: \([0-9]*\).*/\1/p' | head -1)"
            fi
            awk -v bytes="$bytes" 'BEGIN { printf "%.1f", bytes / 1048576.0 }'
        else
            output="$(/usr/bin/time -v "$BIN" "$mode" 1 2>&1)"
            local kilobytes
            kilobytes="$(printf '%s\n' "$output" | sed -n 's/.*Maximum resident set size (kbytes): \([0-9]*\).*/\1/p' | head -1)"
            awk -v kb="$kilobytes" 'BEGIN { printf "%.1f", kb / 1024.0 }'
        fi
    else
        # The executable reports getrusage(RUSAGE_SELF).ru_maxrss itself.
        "$BIN" "$mode" 1 | sed -n 's/.*peak_rss_mb=\([^ ]*\).*/\1/p'
    fi
}

printf '\n| Variant | Seconds (median of 5) | Peak memory (MB) |\n'
printf '| --- | ---: | ---: |\n'
for mode in native codable typed; do
    seconds="$(time_seconds "$mode")"
    memory="$(peak_megabytes "$mode")"
    printf '| `%s` | %s | %s |\n' "$mode" "$seconds" "$memory"
done

printf '\nBounding-box miss, `Polygon.contains` outside the bbox:\n\n'
"$BIN" bboxmiss

printf '\nMemory layout:\n\n'
"$BIN" native 1 | grep '^stride='

printf '\nFixture: /tmp/gis-tools-benchmark.geojson\n'
