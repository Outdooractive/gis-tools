#!/usr/bin/env bash
#
# Downloads OSM navigation road tiles for graph benchmarks.
#
# Usage:
#   scripts/download_osm_navigation_tiles.sh \
#       --url-template URL [options]
#
# The URL template is required. It may contain {z}, {x} and {y}.
#
# Presets (--preset):
#   munich-100k  Munich, prefix "munich_", x 8717...8719, y 5684...5685
#   paris-1m     Paris,  prefix "paris_",  x 8295...8301, y 5632...5639
#   allgaeu      Allgäu, prefix "allgaeu_", x 8647...8657, y 5723...5725
#
# Options:
#   --url-template URL  Tile URL template (required)
#   --output-dir DIR    Output directory
#   --preset NAME       Tile preset (default: munich-100k)
#   --prefix PREFIX     Filename prefix override
#   --zoom N            Zoom level (default: 14)
#   --x-start N         First x tile
#   --x-end N           Last x tile (inclusive)
#   --y-start N         First y tile
#   --y-end N           Last y tile (inclusive)
#   --no-gzip           Keep raw .geojson files
#   --force             Redownload existing files
#
# Environment overrides:
#   MVT_BIN             mvt executable (default: mvt)
#   MVT_LAYER           layer to export (default: road_l)

set -euo pipefail

usage() {
    sed -n '3,32p' "$0" | sed 's/^# \{0,1\}//'
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT/Tests/GISToolsTests/TestData/Graph"
MVT_BIN="${MVT_BIN:-mvt}"
MVT_LAYER="${MVT_LAYER:-road_l}"
MVT_ZOOM="${MVT_ZOOM:-14}"
MVT_GZIP="${MVT_GZIP:-1}"
MVT_FORCE="${MVT_FORCE:-0}"
MVT_PRESET="${MVT_PRESET:-munich-100k}"
URL_TEMPLATE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --url-template)
            URL_TEMPLATE="${2:-}"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="${2:-}"
            shift 2
            ;;
        --preset)
            MVT_PRESET="${2:-}"
            shift 2
            ;;
        --prefix)
            MVT_PREFIX="${2:-}"
            shift 2
            ;;
        --zoom)
            MVT_ZOOM="${2:-}"
            shift 2
            ;;
        --x-start)
            MVT_X_START="${2:-}"
            shift 2
            ;;
        --x-end)
            MVT_X_END="${2:-}"
            shift 2
            ;;
        --y-start)
            MVT_Y_START="${2:-}"
            shift 2
            ;;
        --y-end)
            MVT_Y_END="${2:-}"
            shift 2
            ;;
        --no-gzip)
            MVT_GZIP=0
            shift
            ;;
        --force)
            MVT_FORCE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "error: unknown argument '$1'" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ -z "$URL_TEMPLATE" ]]; then
    echo "error: --url-template is required" >&2
    usage >&2
    exit 2
fi

case "$MVT_PRESET" in
    munich-100k)
        DEFAULT_PREFIX="munich_"
        DEFAULT_X_START=8717
        DEFAULT_X_END=8719
        DEFAULT_Y_START=5684
        DEFAULT_Y_END=5685
        ;;
    paris-1m)
        DEFAULT_PREFIX="paris_"
        DEFAULT_X_START=8295
        DEFAULT_X_END=8301
        DEFAULT_Y_START=5632
        DEFAULT_Y_END=5639
        ;;
    allgaeu)
        DEFAULT_PREFIX="allgaeu_"
        DEFAULT_X_START=8647
        DEFAULT_X_END=8657
        DEFAULT_Y_START=5723
        DEFAULT_Y_END=5725
        ;;
    *)
        echo "error: unknown preset '$MVT_PRESET'" >&2
        exit 1
        ;;
esac

MVT_PREFIX="${MVT_PREFIX:-$DEFAULT_PREFIX}"
MVT_X_START="${MVT_X_START:-$DEFAULT_X_START}"
MVT_X_END="${MVT_X_END:-$DEFAULT_X_END}"
MVT_Y_START="${MVT_Y_START:-$DEFAULT_Y_START}"
MVT_Y_END="${MVT_Y_END:-$DEFAULT_Y_END}"

if ! command -v "$MVT_BIN" >/dev/null 2>&1; then
    echo "error: '$MVT_BIN' is not installed or not on PATH" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

count=0
for ((x = MVT_X_START; x <= MVT_X_END; x++)); do
    for ((y = MVT_Y_START; y <= MVT_Y_END; y++)); do
        url="${URL_TEMPLATE//\{z\}/$MVT_ZOOM}"
        url="${url//\{x\}/$x}"
        url="${url//\{y\}/$y}"
        output="$OUTPUT_DIR/${MVT_PREFIX}${MVT_ZOOM}_${x}_${y}.geojson"

        if [[ -s "${output}.gz" && "$MVT_FORCE" != "1" ]]; then
            echo "Skipping existing ${output}.gz"
            continue
        fi
        if [[ -s "$output" && "$MVT_GZIP" != "1" && "$MVT_FORCE" != "1" ]]; then
            echo "Skipping existing $output"
            continue
        fi

        echo "Exporting x=$x y=$y -> $output"
        "$MVT_BIN" export -l "$MVT_LAYER" -o "$output" "$url"
        if [[ "$MVT_GZIP" == "1" ]]; then
            gzip -9 -f "$output"
            echo "Compressed -> ${output}.gz"
        fi
        count=$((count + 1))
    done
done

echo "Downloaded $count tiles to $OUTPUT_DIR"
