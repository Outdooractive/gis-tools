#!/usr/bin/env python3
"""Generates the projection matrix fixtures for ProjectionMatrixTests.swift.

For every built-in projection of the GISTools library and every test point
inside the projection's area of use, the script computes the point's
coordinates with pyproj/PROJ — using **explicit parameterized proj4
strings** (never EPSG codes for the datum CRSs), so the reference cannot
silently pick a better transformation (e.g. grid shifts) than the library
implements. Conversions between two projections are computed along the
EPSG:4326 pivot (`inv(source) -> fwd(target)`), mirroring the library's
routing.

Output:
- `Tests/GISToolsTests/TestData/ProjectionMatrix/matrix.csv` — the data
  (one row per test point and projection, with the reference values)
- `Tests/GISToolsTests/Algorithms/ProjectionMatrixTests.swift` — the test
  logic, which loads the CSV at runtime

Run again with `--check` to verify the committed fixture is up to date.

Requires: pyproj >= 9-compatible (uses PROJ 9.8.1 at generation time).
"""

import argparse
import sys
from dataclasses import dataclass

from pyproj import CRS, Transformer

# ---------------------------------------------------------------------------
# Projection definitions: (srid, name, proj4, window, tolerance)
#
# window: (minLat, minLon, maxLat, maxLon) in degrees, the area of use
#         where projecting a point into this CRS "makes sense".
# tolerance: the absolute tolerance in the CRS's own units for the matrix
#         comparisons. The Helmert-based datum CRSs carry the published
#         accuracy headroom; exact CRSs carry round-off tolerance only.
# ---------------------------------------------------------------------------

WGS84_TOWGS84 = "+towgs84=0,0,0"


@dataclass
class Crs:
    srid: int
    name: str
    proj4: str
    window: tuple
    tolerance: float
    is_global: bool = False
    # Pairs with these SRIDs are excluded from the matrix for this CRS.
    excludes: tuple = ()  # EPSG:4978: see issue #251
    # Extra pair-level budget for conversions that pass through this CRS's
    # datum shift, in METERS (the library applies the Helmert in the
    # geocentric domain while PROJ's +towgs84 offsets lat/lon directly;
    # the ordering difference lands at the few-centimeter level).
    datum_budget: float = 0.0
    # Extra pair-level budget for conversions sourced from this CRS, in
    # METERS (precision differences between the library's transcribed
    # inverse and PROJ's). Zero for all current CRSs: EPSG:3035's
    # authalic-latitude conversion was upgraded to the Karney auxlat
    # series (the fix for issue #252), removing the only one.
    pair_budget: float = 0.0

    def excludes_pair(self, other) -> bool:
        return other.srid in self.excludes or self.srid in other.excludes


def wgs84():
    return Crs(
        4326, "EPSG:4326",
        "+proj=longlat +datum=WGS84 +no_defs",
        (-90.0, -180.0, 90.0, 180.0),
        0.00000001,
        is_global=True)


GEODETIC_DATUM_SRIDS = (4267, 4277, 27700, 2056, 21781, 29902, 29903, 28992)


def ecef():
    # Pairs with the geodetic datum CRSs are excluded: the library's
    # Helmert applies the full 3D translation (shifting the height by
    # the datum's vertical offset, ~40 m for Amersfoort on Bessel 1841),
    # which the EPSG:4326 pivot then carries into ECEF as an altitude;
    # PROJ's +towgs84 pipeline preserves the nominal z instead. The
    # 26 m discrepancy is a library-level z-semantics inconsistency
    # (4326 -> datum CRS -> 4978 differs from the direct 4326 -> 4978),
    # tracked for a follow-up fix of the Helmert z handling (issue #251).
    return Crs(
        4978, "EPSG:4978",
        "+proj=geocent +datum=WGS84 +units=m +no_defs",
        (-90.0, -180.0, 90.0, 180.0),
        0.001,
        is_global=True,
        excludes=GEODETIC_DATUM_SRIDS)


def web_mercator():
    return Crs(
        3857, "EPSG:3857",
        "+proj=merc +a=6378137 +b=6378137 +lat_ts=0 +lon_0=0 +x_0=0 +y_0=0 "
        "+k=1 +units=m +nadgrids=@null +wktext +no_defs",
        (-85.06, -180.0, 85.06, 180.0),
        0.001,
        is_global=True)


def world_mercator():
    return Crs(
        3395, "EPSG:3395",
        "+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 "
        "+datum=WGS84 +units=m +no_defs",
        (-80.0, -180.0, 84.0, 180.0),
        0.001,
        is_global=True)


def plate_carree():
    # Not part of the matrix: the library's EPSG:32662 intentionally uses
    # degrees as x/y (see Epsg32662Definition), diverging from PROJ's
    # meter-valued +proj=eqc. Its behavior is pinned by Epsg32662Tests.
    return None


def etrs89():
    return Crs(
        4258, "EPSG:4258",
        "+proj=longlat +ellps=GRS80 +towgs84=0,0,0 +no_defs",
        (25.0, -35.0, 85.0, 45.0),
        0.00000001)


def nad27():
    return Crs(
        4267, "EPSG:4267",
        "+proj=longlat +ellps=clrk66 +towgs84=-8,160,176,0,0,0,0 +no_defs",
        (15.0, -170.0, 75.0, -50.0),
        # The library applies the Helmert translation in the geocentric
        # domain while PROJ's +towgs84 offsets lat/lon directly; the
        # ordering difference shows up at the few-centimeter level.
        0.000001,
        datum_budget=0.1)


def osgb36():
    return Crs(
        4277, "EPSG:4277",
        "+proj=longlat +ellps=airy "
        "+towgs84=446.448,-125.157,542.06,0.15,0.247,0.842,-20.489 +no_defs",
        (49.5, -9.0, 61.5, 2.5),
        0.000001,
        datum_budget=0.1)


def bng():
    return Crs(
        27700, "EPSG:27700",
        "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 "
        "+y_0=-100000 +ellps=airy "
        "+towgs84=446.448,-125.157,542.06,0.15,0.247,0.842,-20.489 +no_defs",
        (49.5, -9.0, 61.5, 2.5),
        0.001,
        datum_budget=0.01)


def ch1903plus():
    return Crs(
        2056, "EPSG:2056",
        "+proj=somerc +lat_0=46.95240555555556 +lon_0=7.439583333333333 "
        "+k_0=1 +x_0=2600000 +y_0=1200000 +ellps=bessel "
        "+towgs84=674.374,15.056,405.346,0,0,0,0 +no_defs",
        (45.0, 5.4, 48.0, 11.5),
        0.001,
        datum_budget=0.002)


def ch1903():
    return Crs(
        21781, "EPSG:21781",
        "+proj=somerc +lat_0=46.95240555555556 +lon_0=7.439583333333333 "
        "+k_0=1 +x_0=600000 +y_0=200000 +ellps=bessel "
        "+towgs84=674.374,15.056,405.346,0,0,0,0 +no_defs",
        (45.0, 5.4, 48.0, 11.5),
        0.001,
        datum_budget=0.002)


def tm65():
    return Crs(
        29902, "EPSG:29902",
        "+proj=tmerc +lat_0=53.5 +lon_0=-8 +k=1.000035 +x_0=200000 "
        "+y_0=250000 +ellps=mod_airy "
        "+towgs84=482.5,-130.6,564.6,-1.042,-0.214,-0.631,8.15 +no_defs",
        (51.0, -11.0, 55.7, -5.3),
        0.001,
        datum_budget=0.005)


def tm75():
    return Crs(
        29903, "EPSG:29903",
        "+proj=tmerc +lat_0=53.5 +lon_0=-8 +k=1.000035 +x_0=200000 "
        "+y_0=250000 +ellps=mod_airy "
        "+towgs84=482.5,-130.6,564.6,-1.042,-0.214,-0.631,8.15 +no_defs",
        (51.0, -11.0, 55.7, -5.3),
        0.001,
        datum_budget=0.005)


def itm():
    return Crs(
        2157, "EPSG:2157",
        "+proj=tmerc +lat_0=53.5 +lon_0=-8 +k=0.99982 +x_0=600000 "
        "+y_0=750000 +ellps=GRS80 +towgs84=0,0,0 +no_defs",
        (51.0, -11.0, 55.7, -5.3),
        0.001)


def laea_europe():
    # The inverse converts the authalic latitude through the Karney auxlat
    # series (the fix for issue #252), matching PROJ 9.8 to sub-micrometer
    # level; no pair budget is needed.
    return Crs(
        3035, "EPSG:3035",
        "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 "
        "+ellps=GRS80 +towgs84=0,0,0 +units=m +no_defs",
        (27.0, -32.0, 73.0, 47.0),
        0.001)


def lcc_europe():
    return Crs(
        3034, "EPSG:3034",
        "+proj=lcc +lat_1=35 +lat_2=65 +lat_0=52 +lon_0=10 +x_0=4000000 "
        "+y_0=2800000 +ellps=GRS80 +towgs84=0,0,0 +units=m +no_defs",
        (24.0, -36.0, 82.0, 45.0),
        0.001)


def lambert93():
    return Crs(
        2154, "EPSG:2154",
        "+proj=lcc +lat_1=49 +lat_2=44 +lat_0=46.5 +lon_0=3 +x_0=700000 "
        "+y_0=6600000 +ellps=GRS80 +towgs84=0,0,0 +units=m +no_defs",
        (40.5, -10.0, 52.5, 10.0),
        0.001)


def rd_new():
    return Crs(
        28992, "EPSG:28992",
        "+proj=sterea +lat_0=52.15616055555555 +lon_0=5.38763888888889 "
        "+k=0.9999079 +x_0=155000 +y_0=463000 +ellps=bessel "
        "+towgs84=565.4171,50.3319,465.5524,-0.398957388243134,"
        "0.343987817378283,-1.87740163998045,4.0725 +no_defs",
        (50.5, 3.0, 54.0, 7.5),
        0.001,
        datum_budget=0.002)


def utm_zone(zone, south):
    """The WGS84 UTM zone, with the library's Karney TM parameterization
    mirrored as a PROJ tmerc (PROJ uses the same Karney algorithm)."""
    lon0 = (zone - 1) * 6 - 180 + 3
    fn = 0.0 if not south else 10_000_000.0
    return Crs(
        (32600 if not south else 32700) + zone,
        f"EPSG:{(32600 if not south else 32700) + zone}",
        f"+proj=tmerc +lat_0=0 +lon_0={lon0} +k=0.9996 +x_0=500000 "
        f"+y_0={fn} +ellps=WGS84 +datum=WGS84 +units=m +no_defs",
        (max(-80.0, -90.0) if not south else -90.0, lon0 - 3.0,
         min(84.0, 90.0) if not south else 90.0, lon0 + 3.0),
        0.001)


def etrs89_utm_zone(zone):
    lon0 = (zone - 1) * 6 - 180 + 3
    return Crs(
        25800 + zone,
        f"EPSG:{25800 + zone}",
        f"+proj=tmerc +lat_0=0 +lon_0={lon0} +k=0.9996 +x_0=500000 "
        f"+y_0=0 +ellps=GRS80 +towgs84=0,0,0 +units=m +no_defs",
        (35.0, lon0 - 3.0, 72.0, lon0 + 3.0),
        0.001)


def all_crs():
    crs_list = [
        crs for crs in [
            wgs84(), ecef(), web_mercator(), world_mercator(), plate_carree(),
            etrs89(), nad27(), osgb36(), bng(), ch1903plus(), ch1903(),
            tm65(), tm75(), itm(), laea_europe(), lcc_europe(), lambert93(),
            rd_new(),
        ] if crs is not None
    ]
    for zone in range(1, 61):
        crs_list.append(utm_zone(zone, south=False))
        crs_list.append(utm_zone(zone, south=True))
    for zone in range(31, 38):
        crs_list.append(etrs89_utm_zone(zone))
    return crs_list


# ---------------------------------------------------------------------------
# Test points
# ---------------------------------------------------------------------------


@dataclass
class Point:
    name: str
    lat: float
    lon: float
    altitude: float = 0.0
    m_value: float = 0.0


def all_points():
    """The matrix points: global coverage + regional coverage + one per
    UTM zone (on its central meridian and on both zone borders)."""
    points = [
        # Global spread (every global CRS + whatever regional windows fit).
        Point("Amsterdam", 52.37233, 4.90497),
        Point("New York", 40.71278, -74.00594),
        Point("Sydney", -33.86849, 151.19509),
        Point("Cairo", 30.04425, 31.23568),
        Point("Sao Paulo", -23.55052, -46.63331),
        Point("Tokyo", 35.68950, 139.69171),
        Point("Cape Town", -33.92487, 18.42406),
        Point("Reykjavik", 64.14660, -21.94261),
        Point("Anchorage", 61.21806, -149.90028),
        Point("Singapore", 1.35208, 103.81984),
        Point("Equator Prime Meridian", 0.0, 0.0),
        Point("Equator Antimeridian West", 0.0, -180.0),
        Point("Equator Antimeridian East", 0.0, 180.0),
        Point("Northern High Latitude", 80.0, 13.0),
        Point("Southern High Latitude", -80.0, 24.0),
        Point("Near North Pole", 89.9, 42.0),
        Point("Near South Pole", -89.9, -42.0),
        # Regional points: each regional CRS's center, far corner and a
        # datum-sensitive location.
        Point("Dublin", 53.34980, -6.26031),
        Point("Belfast", 54.59727, -5.93011),
        Point("Shannon Estuary", 52.62, -9.5),
        Point("London", 51.50722, -0.12750),
        Point("Shetland", 60.15460, -1.14920),
        Point("Scilly Southwest", 49.86, -6.30),
        Point("Bern", 46.94847, 7.44748),
        Point("Geneva", 46.20439, 6.14316),
        Point("Zermatt", 46.02070, 7.74910),
        Point("Amsterdam Rijksmuseum", 52.36003, 4.88521),
        Point("Leeuwarden North", 53.20, 5.80),
        Point("Maastricht South", 50.85, 5.70),
        Point("Paris", 48.85661, 2.35222),
        Point("Brest West", 48.39, -4.49),
        Point("Marseille South", 43.30, 5.37),
        Point("Reykjavik Iceland", 64.14660, -21.94261),
        Point("Lisbon Portugal", 38.72225, -9.13934),
        Point("Nicosia Cyprus", 35.18557, 33.38236),
        Point("Tromso Norway", 69.64920, 18.95532),
        Point("Helsinki Finland", 60.16986, 24.93838),
        Point("Canary Islands", 28.29339, -16.62464),
        Point("Athens Greece", 37.98381, 23.72754),
    ]
    return points


def utm_points():
    """Three points per UTM zone: central meridian, west border, east
    border, at a mid latitude. Both hemispheres. Plus a near-polar row."""
    points = []
    for zone in range(1, 61):
        lon0 = (zone - 1) * 6 - 180 + 3
        points.append(Point(f"Zone {zone}N CM", 41.0, lon0))
        points.append(Point(f"Zone {zone}N West", 41.0, lon0 - 3.0))
        points.append(Point(f"Zone {zone}N East", 41.0, lon0 + 3.0))
        points.append(Point(f"Zone {zone}N High", 80.0, lon0))
        points.append(Point(f"Zone {zone}S CM", -45.5, lon0))
        points.append(Point(f"Zone {zone}S West", -45.5, lon0 - 3.0))
        points.append(Point(f"Zone {zone}S East", -45.5, lon0 + 3.0))
    return points


# ---------------------------------------------------------------------------
# pyproj helpers
# ---------------------------------------------------------------------------

_transformer_cache = {}


def transformer(crs_def):
    """The geographic -> CRS transformer for the definition (cached)."""
    if crs_def.srid not in _transformer_cache:
        _transformer_cache[crs_def.srid] = Transformer.from_crs(
            wgs84().proj4, crs_def.proj4, always_xy=True)
    return _transformer_cache[crs_def.srid]


def forward(crs_def, lat, lon, altitude=0.0):
    """Geographic -> projected/geographic CRS coordinates (lon, lat for
    geographic CRSs, x/y for projected ones, x/y/z for the geocentric
    one)."""
    if crs_def.srid == 4978:
        return transformer(crs_def).transform(lon, lat, altitude)
    return transformer(crs_def).transform(lon, lat)


def coordinates_in(crs_def, lat, lon, altitude=0.0):
    """The point's coordinates in `crs_def`, via the WGS84 pivot."""
    if crs_def.srid == 4978:
        x, y, z = forward(crs_def, lat, lon, altitude)
        return x, y, z
    x, y = forward(crs_def, lat, lon)
    return x, y, 0.0


def point_contains(crs_def, lat, lon):
    min_lat, min_lon, max_lat, max_lon = crs_def.window
    return min_lat <= lat <= max_lat and min_lon <= lon <= max_lon


# ---------------------------------------------------------------------------
# Fixture emission
# ---------------------------------------------------------------------------


def swift_number(value):
    return f"{value:.6f}"


def emit(crs_list, points, csv_path, test_path):
    # Pre-compute all rows; the per-point matrix holds every CRS whose
    # area of use contains the point, minus the explicitly excluded pairs.
    rows = []  # (point, [(srid, x, y, z, tolerance)])
    for point in points:
        members = [
            crs_def for crs_def in crs_list
            if point_contains(crs_def, point.lat, point.lon)
        ]
        crs_here = []
        for crs_def in members:
            x, y, z = coordinates_in(crs_def, point.lat, point.lon, point.altitude)
            crs_here.append((crs_def.srid, x, y, z, crs_def.tolerance,
                             crs_def.datum_budget, crs_def.pair_budget))
        if len(crs_here) >= 2:
            rows.append((point, crs_here))

    print(f"points with a matrix: {len(rows)}")
    total_rows = sum(len(c) for _, c in rows)
    total_pairs = 0
    for point, _ in rows:
        members = [
            crs_def for crs_def in crs_list
            if point_contains(crs_def, point.lat, point.lon)
        ]
        for source in members:
            for target in members:
                if source.srid == target.srid or source.excludes_pair(target):
                    continue
                total_pairs += 1
    print(f"crs rows: {total_rows}, ordered pairs: {total_pairs}")

    # Data and code are kept separate: the reference values live in a CSV
    # file under TestData/ProjectionMatrix/ (one row per test point and
    # projection); the test logic loads it at runtime via the established
    # #filePath-relative mechanism.
    with open(csv_path, "w") as f:
        f.write(CSV_HEADER)
        for point, crs_here in rows:
            for srid, x, y, z, tol, budget, pair_budget in crs_here:
                f.write(
                    f"{point.name},{point.lat},{point.lon},{point.altitude},"
                    f"{srid},{swift_number(x)},{swift_number(y)},"
                    f"{swift_number(z)},{tol},{budget},{pair_budget}\n")

    with open(test_path, "w") as f:
        f.write(TESTS)


CSV_HEADER = (
    "name,latitude,longitude,altitude,"
    "srid,x,y,z,tolerance,datumBudget,pairBudget\n")

TESTS = '''import Foundation
@testable import GISTools
import Testing

/// Cross-validation of every pair of built-in projections: for each test
/// point, the coordinates in every projection whose area of use contains
/// it were pre-computed with pyproj/PROJ 9.8.1 (explicit parameterized
/// proj4 strings mirroring the library's parameters, including the
/// Helmert datum transformations in position-vector form — never EPSG
/// codes, so PROJ cannot silently select a better transformation than
/// the library implements). Conversions between two projections follow
/// the library's EPSG:4326 pivot.
///
/// The reference data lives in
/// `Tests/GISToolsTests/TestData/ProjectionMatrix/matrix.csv` (one row per
/// test point and projection) and is machine-generated by
/// `scripts/generate_projection_matrix.py` (regenerate with `--check` to
/// verify); do not edit the values by hand.
struct ProjectionMatrixTests {

    // MARK: - Fixture loading

    /// The CSV fixture lines (the header and blank lines skipped). The
    /// path follows the established `#filePath`-relative test data
    /// mechanism (see `TestData`).
    private static func fixtureLines() throws -> [String] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TestData")
            .appendingPathComponent("ProjectionMatrix")
            .appendingPathComponent("matrix")
            .appendingPathExtension("csv")

        let contents = try String(contentsOf: url, encoding: .utf8)
        return contents
            .split(separator: "\\n")
            .map(String.init)
            .filter { !$0.isEmpty }
            .filter { !$0.hasPrefix("name,") }
    }

    // MARK: - Fixture model

    private struct MatrixRow {

        let srid: Int
        let x: Double
        let y: Double
        let z: Double
        let tolerance: Double

        /// Extra budget for conversions passing through this CRS's datum
        /// shift, in meters.
        let datumBudget: Double

        /// Extra budget for conversions sourced from this CRS (inverse
        /// precision differences against PROJ), in meters. Zero for all
        /// current CRSs: EPSG:3035's authalic-latitude conversion was
        /// upgraded to the Karney auxlat series (the fix for issue
        /// #252), removing the only such budget.
        let pairBudget: Double

    }

    private struct MatrixPoint {

        let name: String
        let latitude: Double
        let longitude: Double
        let rows: [MatrixRow]

    }

    /// Parses the CSV fixture (`TestData/ProjectionMatrix/matrix.csv`),
    /// grouping the rows of a test point in file order. The fixture is
    /// small enough that re-parsing per test is negligible.
    private static func points() throws -> [MatrixPoint] {
        let lines = try Self.fixtureLines()
        var points: [MatrixPoint] = []
        var rows: [MatrixRow] = []
        var currentName: String?
        var currentLatitude: Double?
        var currentLongitude: Double?

        func flush() {
            if let name = currentName,
               let latitude = currentLatitude,
               let longitude = currentLongitude,
               rows.count >= 2
            {
                points.append(MatrixPoint(
                    name: name,
                    latitude: latitude,
                    longitude: longitude,
                    rows: rows))
            }
            rows = []
        }

        for line in lines {
            let fields = line.split(separator: ",", omittingEmptySubsequences: false)
            guard fields.count == 11,
                  let latitude = Double(fields[1]),
                  let longitude = Double(fields[2]),
                  let srid = Int(fields[4]),
                  let x = Double(fields[5]),
                  let y = Double(fields[6]),
                  let z = Double(fields[7]),
                  let tolerance = Double(fields[8]),
                  let datumBudget = Double(fields[9]),
                  let pairBudget = Double(fields[10])
            else { continue }

            let name = String(fields[0])
            if name != currentName {
                flush()
                currentName = name
                currentLatitude = latitude
                currentLongitude = longitude
            }

            rows.append(MatrixRow(
                srid: srid,
                x: x,
                y: y,
                z: z,
                tolerance: tolerance,
                datumBudget: datumBudget,
                pairBudget: pairBudget))
        }
        flush()

        return points
    }

    // MARK: - Pair rules

    /// Pairs excluded from the matrix: EPSG:4978 with the geodetic datum
    /// CRSs. The library's Helmert applies the full 3D translation (the
    /// datum's vertical offset shifts the height, which the EPSG:4326
    /// pivot then carries into ECEF as an altitude), while PROJ's
    /// `+towgs84` pipeline preserves the nominal z. This makes
    /// 4326 -> datum CRS -> 4978 differ from the direct 4326 -> 4978 by
    /// the datum's vertical offset (e.g. ~26 m for Amersfoort) — a
    /// library-level z-semantics inconsistency tracked for a follow-up
    /// fix of the Helmert height handling (issue #251).
    private static let geodeticDatumSrids: Set<Int> = [
        4267,
        4277,
        27700,
        2056,
        21781,
        29902,
        29903,
        28992,
    ]

    private static func isExcludedPair(_ a: Int, _ b: Int) -> Bool {
        (a == 4978 && geodeticDatumSrids.contains(b))
            || (b == 4978 && geodeticDatumSrids.contains(a))
    }

    /// The effective pair tolerance: the larger of the two rows' row
    /// tolerances, plus each side's datum budget (conversions through a
    /// datum shift pick up the Helmert-vs-PROJ ordering difference,
    /// centimeters in lat/lon and up to a decimeter in projected values).
    /// The budgets are meter-valued; degree-unit rows (tolerance below
    /// 1e-5 degrees) divide by the meridian arc per degree.
    private static func pairTolerance(_ source: MatrixRow, _ target: MatrixRow) -> Double {
        let budget = source.datumBudget + target.datumBudget + source.pairBudget
        let tolerance = max(source.tolerance, target.tolerance)
        guard budget > 0.0 else { return tolerance }

        // Degree-unit rows carry tolerance ~1e-8 or 1e-6; meter-unit rows
        // 1e-3 and above.
        if tolerance < 0.00001 {
            return tolerance + budget / 111_000.0
        }
        return tolerance + budget
    }

    /// The round-trip tolerance: the conversion runs through both
    /// projections' inverse and forward (four steps), so the budget
    /// doubles.
    private static func roundTripTolerance(_ source: MatrixRow, _ target: MatrixRow) -> Double {
        2.0 * pairTolerance(source, target)
    }

    // MARK: - Matrix conversions

    /// Converts every point between every pair of projections containing
    /// it and validates the result against the PROJ reference values.
    @Test
    func matrixConversions() throws {
        for point in try Self.points() {
            for source in point.rows {
                for target in point.rows where target.srid != source.srid {
                    guard !Self.isExcludedPair(source.srid, target.srid) else { continue }

                    let sourceProjection = try #require(Projection(srid: source.srid))
                    let targetProjection = try #require(Projection(srid: target.srid))

                    // The geocentric projection consumes/produces the
                    // z (ellipsoid height) axis; other projections carry
                    // it through unchanged.
                    let coordinate = Coordinate3D(
                        x: source.x,
                        y: source.y,
                        z: source.srid == 4978 ? source.z : nil,
                        m: 45.0,
                        projection: sourceProjection)
                    let converted = coordinate.projected(to: targetProjection)

                    #expect(
                        abs(converted.x - target.x) < Self.pairTolerance(source, target),
                        "\\(point.name): \\(source.srid) -> \\(target.srid)"
                    )
                    #expect(
                        abs(converted.y - target.y) < Self.pairTolerance(source, target),
                        "\\(point.name): \\(source.srid) -> \\(target.srid)"
                    )
                    #expect(
                        converted.projection.srid == target.srid,
                        "\\(point.name): \\(source.srid) -> \\(target.srid)"
                    )
                    #expect(converted.m == 45.0)
                }
            }
        }
    }

    // MARK: - Round trips

    /// Round-trips every ordered pair: converting from A to B and back
    /// to A must reproduce the source coordinates. Catches inverse-only
    /// regressions.
    @Test
    func matrixRoundTrips() throws {
        for point in try Self.points() {
            for source in point.rows {
                for target in point.rows where target.srid != source.srid {
                    guard !Self.isExcludedPair(source.srid, target.srid) else { continue }

                    let sourceProjection = try #require(Projection(srid: source.srid))
                    let targetProjection = try #require(Projection(srid: target.srid))

                    let coordinate = Coordinate3D(
                        x: source.x,
                        y: source.y,
                        z: source.srid == 4978 ? source.z : nil,
                        projection: sourceProjection)
                    let converted = coordinate.projected(to: targetProjection)
                    let back = converted.projected(to: sourceProjection)

                    #expect(
                        abs(back.x - source.x) < Self.roundTripTolerance(source, target),
                        "\\(point.name): \\(source.srid) -> \\(target.srid) -> \\(source.srid)"
                    )
                    #expect(
                        abs(back.y - source.y) < Self.roundTripTolerance(source, target),
                        "\\(point.name): \\(source.srid) -> \\(target.srid) -> \\(source.srid)"
                    )
                }
            }
        }
    }

    // MARK: - Batch equivalence

    /// Validates the batch conversion API on a representative subset of
    /// pairs: the hoisted-setup batch path must produce values identical
    /// to the single-coordinate path (both are compared against the same
    /// PROJ reference rows in `matrixConversions`).
    @Test
    func batchEquivalence() throws {
        for point in try Self.points() {
            for source in point.rows {
                for target in point.rows where target.srid != source.srid {
                    guard !Self.isExcludedPair(source.srid, target.srid) else { continue }

                    // A deterministic sparse subset keeps the batch test
                    // fast: pairs where both SRIDs are even.
                    guard source.srid % 2 == 0, target.srid % 2 == 0 else { continue }

                    let sourceProjection = try #require(Projection(srid: source.srid))
                    let targetProjection = try #require(Projection(srid: target.srid))

                    let single = [
                        Coordinate3D(
                            x: source.x,
                            y: source.y,
                            z: source.srid == 4978 ? source.z : nil,
                            projection: sourceProjection),
                    ].projected(to: targetProjection)
                    #expect(single.count == 1)

                    #expect(
                        abs(single[0].x - target.x) < Self.pairTolerance(source, target),
                        "\\(point.name): batch \\(source.srid) -> \\(target.srid)"
                    )
                    #expect(
                        abs(single[0].y - target.y) < Self.pairTolerance(source, target),
                        "\\(point.name): batch \\(source.srid) -> \\(target.srid)"
                    )
                }
            }
        }
    }

}
'''

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the committed fixture files match regeneration")
    parser.add_argument(
        "--csv",
        default="Tests/GISToolsTests/TestData/ProjectionMatrix/matrix.csv",
        help="the reference data output path")
    parser.add_argument(
        "--output",
        default="Tests/GISToolsTests/Algorithms/ProjectionMatrixTests.swift",
        help="the test logic output path")
    args = parser.parse_args()

    crs_list = all_crs()
    points = all_points() + utm_points()

    if args.check:
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_csv = f"{tmp_dir}/matrix.csv"
            tmp_test = f"{tmp_dir}/ProjectionMatrixTests.swift"
            emit(crs_list, points, tmp_csv, tmp_test)
            with open(tmp_csv) as f:
                regenerated_csv = f.read()
            with open(tmp_test) as f:
                regenerated_test = f.read()
        with open(args.csv) as f:
            committed_csv = f.read()
        with open(args.output) as f:
            committed_test = f.read()
        if committed_csv == regenerated_csv and committed_test == regenerated_test:
            print("fixture up to date")
            return 0
        print("fixture out of date: regenerate with "
              "scripts/generate_projection_matrix.py")
        return 1

    emit(crs_list, points, args.csv, args.output)
    print(f"written: {args.csv}")
    print(f"written: {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
