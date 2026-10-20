import Foundation
@testable import GISTools
import Testing

struct BooleanPointInPolygonTests {

    // MARK: - Ring.contains(_ coordinate)

    // Validates that `Ring.contains` returns true for a coordinate inside the ring.
    @Test
    func ringContainsCoordinateInside() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        #expect(ring.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
    }

    // Validates that `Ring.contains` returns false for a coordinate outside the ring.
    @Test
    func ringContainsCoordinateOutside() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        #expect(ring.contains(Coordinate3D(latitude: 20.0, longitude: 5.0)) == false)
    }

    // Validates the OGC boundary semantics of `Ring.contains` and `Ring.covers`.
    @Test
    func ringContainsCoordinateOnBoundary() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let onBoundary = Coordinate3D(latitude: 0.0, longitude: 5.0)
        let inside = Coordinate3D(latitude: 5.0, longitude: 5.0)
        let outside = Coordinate3D(latitude: 20.0, longitude: 5.0)

        // OGC contains: interior only.
        #expect(ring.contains(onBoundary) == false)
        #expect(ring.contains(inside))
        #expect(ring.contains(outside) == false)

        // OGC covers: boundary included.
        #expect(ring.covers(onBoundary))
        #expect(ring.covers(inside))
        #expect(ring.covers(outside) == false)

        #expect(ring.locate(onBoundary) == .boundary)
        #expect(ring.locate(inside) == .interior)
        #expect(ring.locate(outside) == .exterior)
    }

    // Validates that `Ring.contains` works correctly with `Point` instances.
    @Test
    func ringContainsPoint() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let pointInside = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let pointOutside = Point(Coordinate3D(latitude: 20.0, longitude: 5.0))
        #expect(ring.contains(pointInside))
        #expect(ring.contains(pointOutside) == false)
    }

    // MARK: - Ring (convex)

    // Validates that `Ring.contains` correctly determines point inclusion in a convex shape.
    @Test
    func ringContainsConvexShape() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        // Center
        #expect(ring.contains(Coordinate3D(latitude: 2.0, longitude: 2.0)))
        // Near corner but inside
        #expect(ring.contains(Coordinate3D(latitude: 0.5, longitude: 0.5)))
        // Just outside
        #expect(ring.contains(Coordinate3D(latitude: -1.0, longitude: 2.0)) == false)
    }

    // MARK: - Ring (concave / L-shaped)

    // Validates that `Ring.contains` correctly handles point inclusion in a concave (L-shaped) ring.
    @Test
    func ringContainsConcaveShape() async throws {
        let ring = try #require(Ring([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 4.0),
            Coordinate3D(latitude: 2.0, longitude: 4.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 6.0, longitude: 2.0),
            Coordinate3D(latitude: 6.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        // Inside the L-shaped area
        #expect(ring.contains(Coordinate3D(latitude: 1.0, longitude: 1.0)))
        #expect(ring.contains(Coordinate3D(latitude: 4.0, longitude: 1.0)))
        // Inside the "cutout" — not inside the ring
        #expect(ring.contains(Coordinate3D(latitude: 4.0, longitude: 3.0)) == false)
    }

    // MARK: - Polygon (with hole)

    // Validates that `Polygon.contains` correctly handles polygons with holes (points in the hole are excluded).
    @Test
    func polygonContainsWithHole() async throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 3.0, longitude: 3.0),
                Coordinate3D(latitude: 3.0, longitude: 7.0),
                Coordinate3D(latitude: 7.0, longitude: 7.0),
                Coordinate3D(latitude: 7.0, longitude: 3.0),
                Coordinate3D(latitude: 3.0, longitude: 3.0),
            ],
        ]))
        // Inside outer ring, outside hole
        #expect(polygon.contains(Coordinate3D(latitude: 1.0, longitude: 5.0)))
        // Inside the hole → not contained
        #expect(polygon.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)) == false)
        // Outside outer ring
        #expect(polygon.contains(Coordinate3D(latitude: 15.0, longitude: 5.0)) == false)
    }

    // A 10×10 square with a 4..6 square hole, in EPSG:4326.
    private func polygonWithHole4326() throws -> Polygon {
        try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 4.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 6.0),
                Coordinate3D(latitude: 6.0, longitude: 6.0),
                Coordinate3D(latitude: 6.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 4.0),
            ],
        ]))
    }

    // Validates that a point on a hole's boundary is treated as a boundary point,
    // not as a point inside the hole (issue #257).
    @Test
    func polygonWithHoleBoundarySemantics() async throws {
        let polygon = try polygonWithHole4326()

        let interior = Coordinate3D(latitude: 2.0, longitude: 2.0)
        let outerBoundary = Coordinate3D(latitude: 5.0, longitude: 0.0)
        let outerVertex = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let holeInterior = Coordinate3D(latitude: 5.0, longitude: 5.0)
        let holeBoundary = Coordinate3D(latitude: 4.0, longitude: 5.0)
        let holeVertex = Coordinate3D(latitude: 4.0, longitude: 4.0)

        // OGC covers: the hole boundary is part of the polygon.
        #expect(polygon.covers(interior))
        #expect(polygon.covers(outerBoundary))
        #expect(polygon.covers(outerVertex))
        #expect(polygon.covers(holeBoundary))
        #expect(polygon.covers(holeVertex))
        #expect(polygon.covers(holeInterior) == false)

        // OGC contains: interior only, no boundary point is inside.
        #expect(polygon.contains(interior))
        #expect(polygon.contains(outerBoundary) == false)
        #expect(polygon.contains(outerVertex) == false)
        #expect(polygon.contains(holeBoundary) == false)
        #expect(polygon.contains(holeVertex) == false)
        #expect(polygon.contains(holeInterior) == false)

        // The tri-state location makes the boundary cases explicit.
        #expect(polygon.locate(interior) == .interior)
        #expect(polygon.locate(outerBoundary) == .boundary)
        #expect(polygon.locate(outerVertex) == .boundary)
        #expect(polygon.locate(holeBoundary) == .boundary)
        #expect(polygon.locate(holeVertex) == .boundary)
        #expect(polygon.locate(holeInterior) == .exterior)
    }

    // Validates that neighbouring polygons with a shared hole boundary agree:
    // both cover the shared edge, and neither contains it in the interior-only mode.
    @Test
    func polygonWithHoleMatchesEnclave() async throws {
        let region = try polygonWithHole4326()
        let enclave = try #require(Polygon([[
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
        ]]))
        let sharedBoundary = Coordinate3D(latitude: 4.0, longitude: 5.0)

        #expect(region.covers(sharedBoundary))
        #expect(enclave.covers(sharedBoundary))
        #expect(region.contains(sharedBoundary) == false)
        #expect(enclave.contains(sharedBoundary) == false)
    }

    // Validates the same hole boundary semantics when accessed through a Feature
    // and a FeatureCollection.
    @Test
    func featureWithHoleBoundarySemantics() async throws {
        let feature = Feature(try polygonWithHole4326())
        let featureCollection = FeatureCollection([feature])
        let holeBoundary = Coordinate3D(latitude: 4.0, longitude: 5.0)

        #expect(feature.covers(holeBoundary))
        #expect(featureCollection.covers(holeBoundary))
        #expect(feature.contains(holeBoundary) == false)
        #expect(featureCollection.contains(holeBoundary) == false)
        #expect(feature.locate(holeBoundary) == .boundary)
        #expect(featureCollection.locate(holeBoundary) == .boundary)
    }

    // Validates that `Polygon.contains` works correctly with `Point` instances.
    @Test
    func polygonContainsPoint() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        #expect(polygon.contains(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))))
        #expect(polygon.contains(Point(Coordinate3D(latitude: 20.0, longitude: 5.0))) == false)
    }

    // MARK: - MultiPolygon

    // Validates that `MultiPolygon.contains` returns correct results for points inside any constituent polygon and false otherwise.
    @Test
    func multiPolygonContains() async throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]]))
        let mp = try #require(MultiPolygon([poly1, poly2]))

        #expect(mp.contains(Coordinate3D(latitude: 2.0, longitude: 2.0)))
        #expect(mp.contains(Coordinate3D(latitude: 12.0, longitude: 2.0)))
        #expect(mp.contains(Coordinate3D(latitude: 7.0, longitude: 2.0)) == false)
    }

    // Validates hole boundary semantics for a MultiPolygon.
    @Test
    func multiPolygonWithHoleBoundarySemantics() async throws {
        let polygon = try polygonWithHole4326()
        let multiPolygon = try #require(MultiPolygon([polygon]))
        let holeBoundary = Coordinate3D(latitude: 4.0, longitude: 5.0)

        #expect(multiPolygon.covers(holeBoundary))
        #expect(multiPolygon.contains(holeBoundary) == false)
        #expect(multiPolygon.locate(holeBoundary) == .boundary)
        #expect(multiPolygon.covers(Coordinate3D(latitude: 5.0, longitude: 5.0)) == false)
        #expect(multiPolygon.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)) == false)
        #expect(multiPolygon.locate(Coordinate3D(latitude: 5.0, longitude: 5.0)) == .exterior)
    }

    // MARK: - Feature

    // Validates that `Feature.contains` delegates correctly to its underlying polygon geometry.
    @Test
    func featureContains() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let feature = Feature(polygon)
        #expect(feature.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
        #expect(feature.contains(Coordinate3D(latitude: 20.0, longitude: 5.0)) == false)
    }

    // Validates that `Feature.contains` returns false when the feature wraps a non-polygon geometry.
    @Test
    func featureContainsNonPolygon() async throws {
        let point = Point(Coordinate3D(latitude: 5.0, longitude: 5.0))
        let feature = Feature(point)
        // Feature wraps a Point — not a PolygonGeometry, so always false
        #expect(feature.contains(point.coordinate) == false)
    }

    // MARK: - FeatureCollection

    // Validates that `FeatureCollection.contains` checks containment across all features in the collection.
    @Test
    func featureCollectionContains() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let fc = FeatureCollection([Feature(polygon)])
        #expect(fc.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
        #expect(fc.contains(Coordinate3D(latitude: 20.0, longitude: 5.0)) == false)
    }

    // MARK: - GeometryCollection

    // Validates that `Feature.contains` handles features whose geometry is a `GeometryCollection`.
    @Test
    func featureContainsGeometryCollection() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let feature = Feature(GeometryCollection([polygon]))

        #expect(feature.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
        #expect(feature.contains(Coordinate3D(latitude: 20.0, longitude: 5.0)) == false)
    }

    // Validates that `FeatureCollection.contains` finds features whose geometry is a `GeometryCollection`.
    @Test
    func featureCollectionContainsGeometryCollection() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let fc = FeatureCollection([Feature(GeometryCollection([polygon]))])

        #expect(fc.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
        #expect(fc.contains(Coordinate3D(latitude: 20.0, longitude: 5.0)) == false)
    }

    // Validates that nested `GeometryCollection`s resolve to their polygon members.
    @Test
    func geometryCollectionContainsNestedCollection() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let outer = GeometryCollection([GeometryCollection([polygon])])

        #expect(outer.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
        #expect(outer.contains(Coordinate3D(latitude: 20.0, longitude: 5.0)) == false)
        #expect(Feature(outer).contains(Coordinate3D(latitude: 5.0, longitude: 5.0)))
        #expect(outer.locate(Coordinate3D(latitude: 0.0, longitude: 5.0)) == .boundary)
        #expect(outer.locate(Coordinate3D(latitude: 20.0, longitude: 5.0)) == .exterior)
    }

    // Validates that a `GeometryCollection` containing only non-polygon geometries contains nothing.
    @Test
    func geometryCollectionContainsNonPolygon() async throws {
        let feature = Feature(GeometryCollection([Point(Coordinate3D(latitude: 5.0, longitude: 5.0))]))

        #expect(feature.contains(Coordinate3D(latitude: 5.0, longitude: 5.0)) == false)
    }

    // MARK: - Grid size

    // Validates that `contains(gridSize:)` on Polygon matches manual pre-snapping.
    @Test
    func polygonContainsWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let coord = Coordinate3D(latitude: 5.00005, longitude: 5.00005)
        let gridSize = 0.001

        let withParam = polygon.contains(coord, gridSize: gridSize)
        let snappedPolygon = polygon.snappedToGrid(tolerance: gridSize)
        let snappedCoord = Point(coord).snappedToGrid(tolerance: gridSize).coordinate
        let manual = snappedPolygon.contains(snappedCoord)
        #expect(withParam == manual)
    }

    // Validates that `contains(gridSize:)` on Feature matches manual pre-snapping.
    @Test
    func featureContainsWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let feature = Feature(polygon)
        let coord = Coordinate3D(latitude: 5.00005, longitude: 5.00005)
        let gridSize = 0.001

        let withParam = feature.contains(coord, gridSize: gridSize)
        let snappedFeature = feature.snappedToGrid(tolerance: gridSize)
        let snappedCoord = Point(coord).snappedToGrid(tolerance: gridSize).coordinate
        let manual = snappedFeature.contains(snappedCoord)
        #expect(withParam == manual)
    }

    // Validates that `contains(gridSize:)` on FeatureCollection matches manual pre-snapping.
    @Test
    func featureCollectionContainsWithGridSize() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
            Coordinate3D(latitude: 10.0001, longitude: 0.0001),
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
        ]]))
        let fc = FeatureCollection([Feature(polygon)])
        let coord = Coordinate3D(latitude: 5.00005, longitude: 5.00005)
        let gridSize = 0.001

        let withParam = fc.contains(coord, gridSize: gridSize)
        let snappedFc = fc.snappedToGrid(tolerance: gridSize)
        let snappedCoord = Point(coord).snappedToGrid(tolerance: gridSize).coordinate
        let manual = snappedFc.contains(snappedCoord)
        #expect(withParam == manual)
    }

    // MARK: - Projections

    // Point in polygon in EPSG:3857.
    @Test
    func pointInPolygon3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let point = Point(Coordinate3D(x: 500.0, y: 500.0))
        #expect(polygon.contains(point))
    }

    // Point in polygon in EPSG:4978.
    @Test
    func pointInPolygon4978() throws {
        let polygon4326 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polygon = polygon4326.projected(to: .epsg4978)
        let point = Point(Coordinate3D(latitude: 0.5, longitude: 0.5).projected(to: .epsg4978))

        #expect(polygon.contains(point))
        #expect(polygon.locate(point) == .interior)
    }

    // Feature with a GeometryCollection in EPSG:3857.
    @Test
    func featureContainsGeometryCollection3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ]]))
        let feature = Feature(GeometryCollection([polygon]))

        #expect(feature.contains(Coordinate3D(x: 500.0, y: 500.0)))
        #expect(feature.contains(Coordinate3D(x: 2_000.0, y: 500.0)) == false)
    }

    // Feature with a GeometryCollection in EPSG:4978.
    @Test
    func featureContainsGeometryCollection4978() throws {
        let ring = [
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ].map { $0.projected(to: .epsg4978) }
        let polygon = try #require(Polygon([ring]))
        let feature = Feature(GeometryCollection([polygon]))
        let inside = Coordinate3D(x: 500.0, y: 500.0).projected(to: .epsg4978)
        let outside = Coordinate3D(x: 5_000.0, y: 500.0).projected(to: .epsg4978)

        #expect(feature.contains(inside))
        #expect(feature.contains(outside) == false)
    }

    // Feature with a GeometryCollection in noSRID.
    @Test
    func featureContainsGeometryCollectionNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1_000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let feature = Feature(GeometryCollection([polygon]))

        #expect(feature.contains(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID)))
        #expect(feature.contains(Coordinate3D(x: 2_000.0, y: 500.0, projection: .noSRID)) == false)
    }

    // Hole boundary semantics in EPSG:3857.
    @Test
    func polygonWithHoleBoundary3857() throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(x: 0.0, y: 0.0),
                Coordinate3D(x: 0.0, y: 1_000.0),
                Coordinate3D(x: 1_000.0, y: 1_000.0),
                Coordinate3D(x: 1_000.0, y: 0.0),
                Coordinate3D(x: 0.0, y: 0.0),
            ],
            [
                Coordinate3D(x: 400.0, y: 400.0),
                Coordinate3D(x: 400.0, y: 600.0),
                Coordinate3D(x: 600.0, y: 600.0),
                Coordinate3D(x: 600.0, y: 400.0),
                Coordinate3D(x: 400.0, y: 400.0),
            ],
        ]))
        let holeBoundary = Coordinate3D(x: 400.0, y: 500.0)

        #expect(polygon.covers(holeBoundary))
        #expect(polygon.contains(holeBoundary) == false)
        #expect(polygon.locate(holeBoundary) == .boundary)
        #expect(polygon.covers(Coordinate3D(x: 500.0, y: 500.0)) == false)
    }

    // Hole boundary semantics in noSRID.
    @Test
    func polygonWithHoleBoundaryNoSRID() throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
                Coordinate3D(x: 0.0, y: 1_000.0, projection: .noSRID),
                Coordinate3D(x: 1_000.0, y: 1_000.0, projection: .noSRID),
                Coordinate3D(x: 1_000.0, y: 0.0, projection: .noSRID),
                Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            ],
            [
                Coordinate3D(x: 400.0, y: 400.0, projection: .noSRID),
                Coordinate3D(x: 400.0, y: 600.0, projection: .noSRID),
                Coordinate3D(x: 600.0, y: 600.0, projection: .noSRID),
                Coordinate3D(x: 600.0, y: 400.0, projection: .noSRID),
                Coordinate3D(x: 400.0, y: 400.0, projection: .noSRID),
            ],
        ]))
        let holeBoundary = Coordinate3D(x: 400.0, y: 500.0, projection: .noSRID)

        #expect(polygon.covers(holeBoundary))
        #expect(polygon.contains(holeBoundary) == false)
        #expect(polygon.locate(holeBoundary) == .boundary)
        #expect(polygon.covers(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID)) == false)
    }

    // Hole semantics in EPSG:4978. Boundary points are not tested here because
    // the projection round-trip does not preserve straight edges exactly.
    @Test
    func polygonWithHole4978() throws {
        let outer = [
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 0.0, y: 1_000.0),
            Coordinate3D(x: 1_000.0, y: 1_000.0),
            Coordinate3D(x: 1_000.0, y: 0.0),
            Coordinate3D(x: 0.0, y: 0.0),
        ].map { $0.projected(to: .epsg4978) }
        let hole = [
            Coordinate3D(x: 400.0, y: 400.0),
            Coordinate3D(x: 400.0, y: 600.0),
            Coordinate3D(x: 600.0, y: 600.0),
            Coordinate3D(x: 600.0, y: 400.0),
            Coordinate3D(x: 400.0, y: 400.0),
        ].map { $0.projected(to: .epsg4978) }
        let polygon = try #require(Polygon([outer, hole]))
        let interior = Coordinate3D(x: 200.0, y: 200.0).projected(to: .epsg4978)
        let holeInterior = Coordinate3D(x: 500.0, y: 500.0).projected(to: .epsg4978)
        let exterior = Coordinate3D(x: 2_000.0, y: 500.0).projected(to: .epsg4978)

        #expect(polygon.contains(interior))
        #expect(polygon.contains(holeInterior) == false)
        #expect(polygon.covers(holeInterior) == false)
        #expect(polygon.contains(exterior) == false)
    }

    // MARK: - Antimeridian

    // A 20°×20° polygon crossing ±180° with a 10°×10° hole that also crosses it.
    private func antimeridianPolygonWithHole() throws -> Polygon {
        try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 20.0, longitude: -170.0),
                Coordinate3D(latitude: 20.0, longitude: 170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
            [
                Coordinate3D(latitude: 5.0, longitude: 175.0),
                Coordinate3D(latitude: 5.0, longitude: -175.0),
                Coordinate3D(latitude: 15.0, longitude: -175.0),
                Coordinate3D(latitude: 15.0, longitude: 175.0),
                Coordinate3D(latitude: 5.0, longitude: 175.0),
            ],
        ]))
    }

    // Hole boundaries of an antimeridian-crossing polygon are classified
    // exactly like outer boundaries in EPSG:4326.
    @Test
    func antimeridianHoleBoundary4326() async throws {
        let polygon = try antimeridianPolygonWithHole()

        let interior = Coordinate3D(latitude: 2.0, longitude: 180.0)
        let outerBoundary = Coordinate3D(latitude: 0.0, longitude: 180.0)
        let holeEdge = Coordinate3D(latitude: 5.0, longitude: 180.0)
        let holeVertex = Coordinate3D(latitude: 5.0, longitude: 175.0)
        let holeVertexWest = Coordinate3D(latitude: 10.0, longitude: -175.0)
        let holeInterior = Coordinate3D(latitude: 10.0, longitude: 180.0)
        let exterior = Coordinate3D(latitude: 10.0, longitude: 160.0)

        // .boundary includes both +180 and -180 representations.
        #expect(polygon.locate(Coordinate3D(latitude: 5.0, longitude: -180.0)) == .boundary)
        #expect(polygon.locate(outerBoundary) == .boundary)
        #expect(polygon.locate(holeEdge) == .boundary)
        #expect(polygon.locate(holeVertex) == .boundary)
        #expect(polygon.locate(holeVertexWest) == .boundary)
        #expect(polygon.locate(interior) == .interior)
        #expect(polygon.locate(holeInterior) == .exterior)
        #expect(polygon.locate(exterior) == .exterior)

        // OGC covers: boundaries count.
        #expect(polygon.covers(outerBoundary))
        #expect(polygon.covers(holeEdge))
        #expect(polygon.covers(holeVertex))
        #expect(polygon.covers(holeVertexWest))
        #expect(polygon.covers(interior))
        #expect(polygon.covers(holeInterior) == false)
        #expect(polygon.covers(exterior) == false)

        // OGC contains: interior only.
        #expect(polygon.contains(interior))
        #expect(polygon.contains(outerBoundary) == false)
        #expect(polygon.contains(holeEdge) == false)
        #expect(polygon.contains(holeVertex) == false)
        #expect(polygon.contains(holeVertexWest) == false)
        #expect(polygon.contains(holeInterior) == false)
        #expect(polygon.contains(exterior) == false)
    }

    // Hole semantics in EPSG:3857. A raw antimeridian-crossing polygon is first
    // cut at ±180° (the supported representation for projected CRSs), then
    // projected to Web Mercator.
    @Test
    func antimeridianHole3857() throws {
        let parts = try antimeridianPolygonWithHole().cutAtAntimeridian()
        let eastPart = try #require(
            parts.features
                .compactMap { $0.geometry as? Polygon }
                .first { ($0.outerRing?.coordinates.first?.longitude ?? 0.0) >= 0.0 })
        let polygon = eastPart.projected(to: .epsg3857)

        let interior = Coordinate3D(latitude: 2.0, longitude: 178.0).projected(to: .epsg3857)
        let outerBoundary = Coordinate3D(latitude: 0.0, longitude: 180.0).projected(to: .epsg3857)
        let holeBoundary = Coordinate3D(latitude: 5.0, longitude: 180.0).projected(to: .epsg3857)
        let holeInterior = Coordinate3D(latitude: 10.0, longitude: 178.0).projected(to: .epsg3857)
        let exterior = Coordinate3D(latitude: 10.0, longitude: 160.0).projected(to: .epsg3857)

        #expect(polygon.locate(interior) == .interior)
        #expect(polygon.locate(outerBoundary) == .boundary)
        #expect(polygon.locate(holeBoundary) == .boundary)
        #expect(polygon.locate(holeInterior) == .exterior)
        #expect(polygon.locate(exterior) == .exterior)

        #expect(polygon.covers(holeBoundary))
        #expect(polygon.contains(holeBoundary) == false)
    }

    // Hole semantics for an antimeridian-crossing polygon in EPSG:4978.
    // Boundary points are not tested because the projection round-trip does
    // not preserve straight edges exactly (see #258).
    @Test
    func antimeridianHole4978() throws {
        let polygon = try antimeridianPolygonWithHole().projected(to: .epsg4978)
        let interior = Coordinate3D(latitude: 2.0, longitude: 180.0).projected(to: .epsg4978)
        let holeInterior = Coordinate3D(latitude: 10.0, longitude: 180.0).projected(to: .epsg4978)
        let exterior = Coordinate3D(latitude: 10.0, longitude: 160.0).projected(to: .epsg4978)

        #expect(polygon.locate(interior) == .interior)
        #expect(polygon.locate(holeInterior) == .exterior)
        #expect(polygon.locate(exterior) == .exterior)
    }

    // Point in polygon near antimeridian.
    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]]))
        #expect(polygon.contains(Coordinate3D(latitude: 5.0, longitude: 175.0)))
        #expect(polygon.contains(Coordinate3D(latitude: 5.0, longitude: 165.0)) == false)
    }

}
