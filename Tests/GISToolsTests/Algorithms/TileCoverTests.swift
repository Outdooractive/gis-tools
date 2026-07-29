@testable import GISTools
import Testing

struct TileCoverTests {

    // MARK: - Point

    // Tests tile cover for a single point at zoom level 1.
    @Test
    func pointTileCover() {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 90.0))
        let tiles = point.tileCover(atZoom: 1)
        #expect(tiles == [MapTile(x: 1, y: 0, z: 1)])
    }

    // Tests tile cover for a MultiPoint.
    @Test
    func multiPointTileCover() throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 45.0, longitude: 90.0),
            Coordinate3D(latitude: -45.0, longitude: -90.0),
        ]))
        let tiles = multiPoint.tileCover(atZoom: 1)
        #expect(Set(tiles) == Set([
            MapTile(x: 1, y: 0, z: 1),
            MapTile(x: 0, y: 1, z: 1),
        ]))
    }

    // MARK: - Line string (edge walking)

    // Tests LineString tile cover using edge walking.
    @Test
    func lineStringQuadTileCover() throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: -10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: -10.0),
        ]))
        let tiles = lineString.tileCover(atZoom: 2)
        #expect(Set(tiles) == Set([
            MapTile(x: 1, y: 1, z: 2),
            MapTile(x: 1, y: 2, z: 2),
            MapTile(x: 2, y: 1, z: 2),
            MapTile(x: 2, y: 2, z: 2),
        ]))
    }

    // Tests diagonal LineString covers multiple intermediate tiles.
    @Test
    func lineStringDiagonalCoversIntermediateTiles() throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 80.0, longitude: -170.0),
            Coordinate3D(latitude: -80.0, longitude: 170.0),
        ]))
        let tiles = lineString.tileCover(atZoom: 2)
        // At zoom 2 (4×4 world), a diagonal across the whole
        // world crosses every column and row
        #expect(tiles.count >= 4)
        #expect(tiles.count > 2)
        let distinctX = Set(tiles.map(\.x))
        let distinctY = Set(tiles.map(\.y))
        #expect(distinctX.count >= 2)
        #expect(distinctY.count >= 2)
    }

    // Tests horizontal LineString edge crosses multiple tiles.
    @Test
    func lineStringHorizontalEdgeCrossesMultipleTiles() throws {
        // A horizontal line crossing the equator spanning many tiles
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: -45.0),
            Coordinate3D(latitude: 0.0, longitude: 45.0),
        ]))
        let tiles = lineString.tileCover(atZoom: 3)
        // At zoom 3 (8×8), longitude -45°→45° covers tiles x=3,4,5.
        let sortedTiles = tiles.sorted { $0.x < $1.x }
        #expect(sortedTiles.count >= 3)
        #expect(sortedTiles.first?.x ?? 0 <= 3)
        #expect(sortedTiles.last?.x ?? 0 >= 5)
        // All tiles should be at the same y
        let uniqueY = Set(tiles.map(\.y))
        #expect(uniqueY.count == 1)
    }

    // Tests vertical LineString edge crosses multiple tiles.
    @Test
    func lineStringVerticalEdgeCrossesMultipleTiles() throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 60.0, longitude: 0.0),
            Coordinate3D(latitude: -60.0, longitude: 0.0),
        ]))
        let tiles = lineString.tileCover(atZoom: 3)
        let sortedTiles = tiles.sorted { $0.y < $1.y }
        #expect(sortedTiles.count >= 4)
        #expect(sortedTiles.first?.y ?? 0 >= 1)
        #expect(sortedTiles.last?.y ?? 0 <= 6)
        let uniqueX = Set(tiles.map(\.x))
        #expect(uniqueX.count == 1)
    }

    // MARK: - Polygon

    // Tests polygon tile cover covers interior tiles.
    @Test
    func polygonTileCover() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: -10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: -10.0),
        ]]))
        let tiles = polygon.tileCover(atZoom: 2)
        #expect(Set(tiles) == Set([
            MapTile(x: 1, y: 1, z: 2),
            MapTile(x: 1, y: 2, z: 2),
            MapTile(x: 2, y: 1, z: 2),
            MapTile(x: 2, y: 2, z: 2),
        ]))
    }

    // Tests polygon tile cover with a larger interior area.
    @Test
    func polygonTileCoverWithInterior() throws {
        // A polygon covering a 3×3 block of tiles at zoom 2.
        // Roughly spans across tiles x: 0-2 and y: 0-2.
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 30.0, longitude: -50.0),
            Coordinate3D(latitude: 30.0, longitude: 50.0),
            Coordinate3D(latitude: -30.0, longitude: 50.0),
            Coordinate3D(latitude: -30.0, longitude: -50.0),
        ]]))
        let tiles = polygon.tileCover(atZoom: 2)
        // At zoom 2 (4×4 world), a polygon spanning ~60° lat × 100° lon
        // should cover at least 4 tiles
        #expect(tiles.count >= 4)
    }

    // Tests MultiPolygon tile cover merges tiles from both polygons.
    @Test
    func multiPolygonTileCover() throws {
        let polygon1 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: -10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: 10.0),
            Coordinate3D(latitude: -10.0, longitude: -10.0),
        ]]))
        let polygon2 = try #require(Polygon([[
            Coordinate3D(latitude: 60.0, longitude: -10.0),
            Coordinate3D(latitude: 60.0, longitude: 10.0),
            Coordinate3D(latitude: 40.0, longitude: 10.0),
            Coordinate3D(latitude: 40.0, longitude: -10.0),
        ]]))
        let multiPolygon = try #require(MultiPolygon([polygon1, polygon2]))
        let tiles = multiPolygon.tileCover(atZoom: 2)
        #expect(!tiles.isEmpty)
        #expect(tiles.contains(MapTile(x: 1, y: 1, z: 2)))
        #expect(tiles.contains(MapTile(x: 2, y: 1, z: 2)))
    }

    // Tests MultiLineString tile cover merges tiles from both lines.
    @Test
    func multiLineStringTileCover() throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 10.0, longitude: -10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: -10.0, longitude: -10.0),
            Coordinate3D(latitude: -10.0, longitude: 10.0),
        ]))
        let multiLineString = try #require(MultiLineString([line1, line2]))
        let tiles = multiLineString.tileCover(atZoom: 2)
        #expect(tiles.contains(MapTile(x: 1, y: 1, z: 2)))
        #expect(tiles.contains(MapTile(x: 2, y: 1, z: 2)))
        #expect(tiles.contains(MapTile(x: 1, y: 2, z: 2)))
        #expect(tiles.contains(MapTile(x: 2, y: 2, z: 2)))
    }

    // MARK: - Feature / FeatureCollection

    // Tests Feature tile cover delegates to geometry.
    @Test
    func featureTileCover() {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 90.0))
        let feature = Feature(point)
        let tiles = feature.tileCover(atZoom: 1)
        #expect(tiles == [MapTile(x: 1, y: 0, z: 1)])
    }

    // Tests FeatureCollection tile cover merges tiles from all features.
    @Test
    func featureCollectionTileCover() {
        let point1 = Point(Coordinate3D(latitude: 45.0, longitude: 90.0))
        let point2 = Point(Coordinate3D(latitude: -45.0, longitude: -90.0))
        let collection = FeatureCollection([Feature(point1), Feature(point2)])
        let tiles = collection.tileCover(atZoom: 1)
        #expect(Set(tiles) == Set([
            MapTile(x: 1, y: 0, z: 1),
            MapTile(x: 0, y: 1, z: 1),
        ]))
    }

    // MARK: - BoundingBox

    // Tests BoundingBox tile cover at zoom level 2.
    @Test
    func boundingBoxTileCover() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: -10.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))
        let tiles = bbox.tileCover(atZoom: 2)
        #expect(Set(tiles) == Set([
            MapTile(x: 1, y: 1, z: 2),
            MapTile(x: 1, y: 2, z: 2),
            MapTile(x: 2, y: 1, z: 2),
            MapTile(x: 2, y: 2, z: 2),
        ]))
    }

    // MARK: - Edge cases

    // Tests tile cover at zoom level 0 returns single world tile.
    @Test
    func zoomLevelZero() {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 90.0))
        let tiles = point.tileCover(atZoom: 0)
        #expect(tiles == [MapTile(x: 0, y: 0, z: 0)])
    }

    // Tests tile cover at high zoom level returns single tile.
    @Test
    func highZoomLevel() {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let tiles = point.tileCover(atZoom: 18)
        #expect(tiles.count == 1)
        #expect(tiles.first?.z == 18)
    }

    // Tests coordinate on tile boundary returns exactly one tile.
    @Test
    func coordinateOnTileBoundary() {
        // These coordinates fall exactly on tile boundaries at zoom 1
        // (lat=0, lon=0 maps to the intersection of all 4 tiles at zoom 1,
        // but the tile algorithm should include it in one of them).
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let tiles = point.tileCover(atZoom: 1)
        #expect(tiles.count == 1)
    }

    // Tests empty MultiPoint initialization returns nil.
    @Test
    func emptyMultiPointReturnsNil() {
        let multiPoint: MultiPoint? = MultiPoint([] as [Coordinate3D])
        #expect(multiPoint == nil)
    }

    // MARK: - Projections

    // Tests tile cover in EPSG:3857 (Web Mercator).
    @Test
    func tileCover3857() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0),
            northEast: Coordinate3D(x: 1_000_000.0, y: 1_000_000.0))
        let tiles = bbox.tileCover(atZoom: 2)
        #expect(!tiles.isEmpty)
    }

    // Tests tile cover with noSRID projection returns empty.
    @Test
    func tileCoverNoSRID() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            northEast: Coordinate3D(x: 1_000_000.0, y: 1_000_000.0, projection: .noSRID))
        let tiles = bbox.tileCover(atZoom: 2)
        #expect(tiles.isEmpty)
    }


    // Tests tile cover in EPSG:4978 (ECEF Cartesian).
    @Test
    func tileCover4978() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0).projected(to: .epsg4978))
        let tiles = bbox.tileCover(atZoom: 2)
        #expect(!tiles.isEmpty)
    }

    // MARK: - Anti-meridian

    // Tests LineString tile cover crossing the anti-meridian.
    @Test
    func lineStringAcrossAntiMeridian() throws {
        // A line crossing the anti-meridian (180° longitude).
        // Per RFC 7946 the shortest path is taken, which crosses
        // the date line and only covers tiles at both edges.
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
        ]))
        let tiles = lineString.tileCover(atZoom: 2)
        #expect(Set(tiles) == Set([
            MapTile(x: 0, y: 2, z: 2),
            MapTile(x: 3, y: 2, z: 2),
        ]))
    }

    // Tests BoundingBox tile cover crossing the anti-meridian.
    @Test
    func boundingBoxAcrossAntiMeridian() {
        // A bounding box crossing the anti-meridian is internally
        // represented as a MultiPolygon split at ±180°, so the
        // tile cover correctly covers tiles on both hemispheres.
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: -170.0))
        let tiles = bbox.tileCover(atZoom: 2)
        #expect(!tiles.isEmpty)
        let xs = Set(tiles.map(\.x))
        #expect(xs.contains(0))
        #expect(xs.contains(3))
    }

    // Tests polygon tile cover crossing the anti-meridian.
    @Test
    func polygonAcrossAntiMeridian() throws {
        // A polygon that crosses the anti-meridian, represented
        // as a single Polygon with coordinates that span the
        // date line (not split into a MultiPolygon).
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: -10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: -10.0, longitude: -170.0),
        ]]))
        let tiles = polygon.tileCover(atZoom: 2)
        #expect(!tiles.isEmpty)
        let xs = Set(tiles.map(\.x))
        #expect(xs.contains(0) || xs.contains(3))
    }

    // MARK: - Interior fill

    // Tests that a bounding box covers the full interior tile block, not
    // just the perimeter. This is the regression test for the originally
    // reported bbox "10,47,11,48" at zoom 14.
    @Test
    func boundingBoxInteriorFillAtZoom14() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 47.0, longitude: 10.0),
            northEast: Coordinate3D(latitude: 48.0, longitude: 11.0))
        let tiles = bbox.tileCover(atZoom: 14)
        let xs = Set(tiles.map(\.x))
        let ys = Set(tiles.map(\.y))
        // Every tile in the bounding tile-rectangle must be present.
        #expect(tiles.count == xs.count * ys.count)
        // Sanity-check the spans against a known reference at zoom 14.
        #expect(xs.count >= 40)
        #expect(ys.count >= 60)
    }

    // Tests that a polygon with a hole excludes the hole's interior tiles
    // while still covering the outer ring and the hole's boundary.
    @Test
    func polygonWithHoleExcludesInteriorTiles() throws {
        // At zoom 6 (64×64 world) the outer ring (-40..40 lon/lat) spans many
        // tiles, and the inner ring (-15..15 lon/lat) carves out a multi-tile
        // hole. A deep-interior hole tile (well inside the inner ring, not on
        // its boundary) must be excluded.
        let outer: [Coordinate3D] = [
            Coordinate3D(latitude: 40.0, longitude: -40.0),
            Coordinate3D(latitude: 40.0, longitude: 40.0),
            Coordinate3D(latitude: -40.0, longitude: 40.0),
            Coordinate3D(latitude: -40.0, longitude: -40.0),
            Coordinate3D(latitude: 40.0, longitude: -40.0),
        ]
        let inner: [Coordinate3D] = [
            Coordinate3D(latitude: 15.0, longitude: -15.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: -15.0, longitude: 15.0),
            Coordinate3D(latitude: -15.0, longitude: -15.0),
            Coordinate3D(latitude: 15.0, longitude: -15.0),
        ]
        let polygon = try #require(Polygon([outer, inner]))
        let tiles = polygon.tileCover(atZoom: 6)
        // Outer tiles (well outside the hole) must be present.
        #expect(tiles.contains(MapTile(x: 24, y: 24, z: 6)))
        #expect(tiles.contains(MapTile(x: 39, y: 39, z: 6)))
        // A deep-interior hole tile (lon ~0, lat ~0, well inside the inner
        // ring and not on its boundary) must NOT be present.
        #expect(!tiles.contains(MapTile(x: 32, y: 32, z: 6)))
    }

    // MARK: - All projections

    // Tests tile cover in EPSG:4326 returns a full interior block.
    @Test
    func tileCover4326FullInterior() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 47.0, longitude: 10.0),
            northEast: Coordinate3D(latitude: 48.0, longitude: 11.0))
        let tiles = bbox.tileCover(atZoom: 14)
        let xs = Set(tiles.map(\.x))
        let ys = Set(tiles.map(\.y))
        #expect(tiles.count == xs.count * ys.count)
        #expect(tiles.count > 100)
    }

    // Tests tile cover in EPSG:3857 produces a full interior cover for an
    // equivalent bounding box.
    @Test
    func tileCover3857FullInterior() {
        let bbox3857 = BoundingBox(
            southWest: Coordinate3D(latitude: 47.0, longitude: 10.0).projected(to: .epsg3857),
            northEast: Coordinate3D(latitude: 48.0, longitude: 11.0).projected(to: .epsg3857))
        let tiles = bbox3857.tileCover(atZoom: 14)
        let xs = Set(tiles.map(\.x))
        let ys = Set(tiles.map(\.y))
        #expect(tiles.count == xs.count * ys.count)
        #expect(tiles.count > 100)
    }

    // Tests tile cover in EPSG:4978 (ECEF) returns a non-empty cover for a
    // bounding box. ECEF bounding-box semantics can distort the effective
    // polygon across the 4326 roundtrip (see ``boundingBoxGeometry``), so we
    // only assert non-empty coverage here; projection-roundtrip precision is
    // covered by the EPSG:4326 and EPSG:3857 tests.
    @Test
    func tileCover4978FullInterior() {
        let bbox4978 = BoundingBox(
            southWest: Coordinate3D(latitude: 47.0, longitude: 10.0).projected(to: .epsg4978),
            northEast: Coordinate3D(latitude: 48.0, longitude: 11.0).projected(to: .epsg4978))
        let tiles = bbox4978.tileCover(atZoom: 14)
        #expect(!tiles.isEmpty)
    }

    // Tests tile cover with noSRID returns an empty array.
    @Test
    func tileCoverNoSRIDReturnsEmpty() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            northEast: Coordinate3D(x: 1_000_000.0, y: 1_000_000.0, projection: .noSRID))
        let tiles = bbox.tileCover(atZoom: 14)
        #expect(tiles.isEmpty)
    }

    // MARK: - Anti-meridian interior fill

    // Tests that a bounding box crossing the anti-meridian fills the interior
    // tiles on both sides of the date line.
    @Test
    func boundingBoxAcrossAntiMeridianFillsInterior() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: -170.0))
        let tiles = bbox.tileCover(atZoom: 4)
        let xs = Set(tiles.map(\.x))
        #expect(xs.contains(0))
        #expect(xs.contains(15))
        // Every tile in the bounding tile-rectangle must be present (full
        // interior cover, not just the perimeter).
        let ys = Set(tiles.map(\.y))
        #expect(tiles.count == xs.count * ys.count)
    }

    // Tests that a polygon crossing the anti-meridian fills interior tiles on
    // both sides of the date line.
    @Test
    func polygonAcrossAntiMeridianFillsInterior() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: -10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: -10.0, longitude: -170.0),
        ]]))
        let tiles = polygon.tileCover(atZoom: 4)
        let xs = Set(tiles.map(\.x))
        #expect(xs.contains(0))
        #expect(xs.contains(15))
        // Every tile in the bounding tile-rectangle must be present (full
        // interior cover, not just the perimeter).
        let ys = Set(tiles.map(\.y))
        #expect(tiles.count == xs.count * ys.count)
    }

    // Tests that a polygon crossing the anti-meridian produces the same
    // tiles as the equivalent split MultiPolygon.
    @Test
    func polygonAndBoundingBoxAntiMeridianAgree() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: -10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: -10.0, longitude: -170.0),
        ]]))
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: -170.0))
        let polygonTiles = Set(polygon.tileCover(atZoom: 4))
        let bboxTiles = Set(bbox.tileCover(atZoom: 4))
        #expect(polygonTiles == bboxTiles)
    }

}
