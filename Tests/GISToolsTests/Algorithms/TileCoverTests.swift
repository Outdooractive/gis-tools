@testable import GISTools
import Testing

struct TileCoverTests {

    // MARK: - Point

    @Test
    func pointTileCover() {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 90.0))
        let tiles = point.tileCover(atZoom: 1)
        #expect(tiles == [MapTile(x: 1, y: 0, z: 1)])
    }

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

    @Test
    func featureTileCover() {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 90.0))
        let feature = Feature(point)
        let tiles = feature.tileCover(atZoom: 1)
        #expect(tiles == [MapTile(x: 1, y: 0, z: 1)])
    }

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

    @Test
    func zoomLevelZero() {
        let point = Point(Coordinate3D(latitude: 45.0, longitude: 90.0))
        let tiles = point.tileCover(atZoom: 0)
        #expect(tiles == [MapTile(x: 0, y: 0, z: 0)])
    }

    @Test
    func highZoomLevel() {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let tiles = point.tileCover(atZoom: 18)
        #expect(tiles.count == 1)
        #expect(tiles.first?.z == 18)
    }

    @Test
    func coordinateOnTileBoundary() {
        // These coordinates fall exactly on tile boundaries at zoom 1
        // (lat=0, lon=0 maps to the intersection of all 4 tiles at zoom 1,
        // but the tile algorithm should include it in one of them).
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let tiles = point.tileCover(atZoom: 1)
        #expect(tiles.count == 1)
    }

    @Test
    func emptyMultiPointReturnsNil() {
        let multiPoint: MultiPoint? = MultiPoint([] as [Coordinate3D])
        #expect(multiPoint == nil)
    }

    // MARK: - Projections

    @Test
    func tileCover3857() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0),
            northEast: Coordinate3D(x: 1_000_000.0, y: 1_000_000.0))
        let tiles = bbox.tileCover(atZoom: 2)
        #expect(!tiles.isEmpty)
    }

    @Test
    func tileCoverNoSRID() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            northEast: Coordinate3D(x: 1_000_000.0, y: 1_000_000.0, projection: .noSRID))
        let tiles = bbox.tileCover(atZoom: 2)
        #expect(tiles.isEmpty)
    }


    @Test
    func tileCover4978() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0).projected(to: .epsg4978))
        let tiles = bbox.tileCover(atZoom: 2)
        #expect(!tiles.isEmpty)
    }

    // MARK: - Anti-meridian

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

}
