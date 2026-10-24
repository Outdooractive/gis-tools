#!/usr/bin/env python3
"""Generate differential fixtures for the property-based geometry tests.

Requires Shapely (fixture generation only; the Swift test target has no
third-party dependency):

    python3 -m pip install --target /tmp/shapely shapely
    PYTHONPATH=/tmp/shapely python3 scripts/generate_property_fixtures.py

The generated JSON is consumed by
``Tests/GISToolsTests/Algorithms/PropertyDifferentialTests.swift``.

All coordinates are EPSG:3857 values near the equator so the library's spherical
area is effectively equal to Shapely's planar area at the fixture scale.
"""

from __future__ import annotations

import json
import math
import random
from pathlib import Path

from shapely.geometry import LineString, Polygon
from shapely.ops import polygonize, unary_union

SEED = 381
OUTPUT = Path(__file__).resolve().parent.parent / "Tests/GISToolsTests/TestData/Property/DifferentialOperations.geojson"


def random_polygon(rng: random.Random) -> Polygon:
    center_x = rng.uniform(200.0, 1800.0)
    center_y = rng.uniform(200.0, 1800.0)
    vertex_count = rng.randint(4, 8)
    points = []
    for index in range(vertex_count):
        angle = 2.0 * math.pi * index / vertex_count + rng.uniform(-0.2, 0.2)
        radius = rng.uniform(80.0, 450.0)
        points.append((
            center_x + radius * math.cos(angle),
            center_y + radius * math.sin(angle),
        ))
    return Polygon(points).convex_hull


def ring_coordinates(polygon: Polygon) -> list[list[float]]:
    return [[round(x, 6), round(y, 6)] for x, y in polygon.exterior.coords]


def area(geometry) -> float:
    return round(float(geometry.area), 6)


def overlay_cases() -> list[dict]:
    rng = random.Random(SEED)
    cases = []
    while len(cases) < 12:
        a = random_polygon(rng)
        b = random_polygon(rng)
        if not a.is_valid or not b.is_valid or a.area <= 0.0 or b.area <= 0.0:
            continue
        intersection = a.intersection(b)
        difference = a.difference(b)
        union = a.union(b)
        symmetric_difference = a.symmetric_difference(b)
        cases.append({
            "a": ring_coordinates(a),
            "b": ring_coordinates(b),
            "intersectionArea": area(intersection),
            "differenceArea": area(difference),
            "unionArea": area(union),
            "symmetricDifferenceArea": area(symmetric_difference),
        })
    return cases


def buffer_cases() -> list[dict]:
    rng = random.Random(SEED + 1)
    cases = []
    for distance in (50.0, 100.0, 200.0):
        for _ in range(2):
            polygon = random_polygon(rng)
            buffered = polygon.buffer(distance, quad_segs=64)
            cases.append({
                "polygon": ring_coordinates(polygon),
                "distance": distance,
                "area": area(buffered),
            })
    return cases


def polygonize_case(rng: random.Random) -> dict:
    columns = 3
    rows = 3
    xs = [0.0]
    ys = [0.0]
    for _ in range(columns):
        xs.append(xs[-1] + rng.uniform(100.0, 300.0))
    for _ in range(rows):
        ys.append(ys[-1] + rng.uniform(100.0, 300.0))

    lines = []
    for y in ys:
        lines.append([[xs[0], y], [xs[-1], y]])
    for x in xs:
        lines.append([[x, ys[0]], [x, ys[-1]]])

    noded = unary_union([LineString(line) for line in lines])
    expected = list(polygonize(noded))
    return {
        "lines": [[[round(x, 6), round(y, 6)] for x, y in line] for line in lines],
        "areas": sorted(area(polygon) for polygon in expected),
    }


def polygonize_cases() -> list[dict]:
    rng = random.Random(SEED + 2)
    return [polygonize_case(rng) for _ in range(3)]


def main() -> None:
    payload = {
        "overlay": overlay_cases(),
        "buffer": buffer_cases(),
        "polygonize": polygonize_cases(),
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    main()
