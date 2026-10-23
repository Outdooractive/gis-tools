import Foundation
@testable import GISTools
import Testing

struct PreparedPolygonTests {

    // MARK: - Helpers

    private func square(
        minX: Double = 0.0,
        minY: Double = 0.0,
        maxX: Double = 10.0,
        maxY: Double = 10.0,
        projection: Projection = .epsg4326
    ) -> Polygon {
        Polygon(unchecked: [[
            Coordinate3D(x: minX, y: minY, projection: projection),
            Coordinate3D(x: maxX, y: minY, projection: projection),
            Coordinate3D(x: maxX, y: maxY, projection: projection),
            Coordinate3D(x: minX, y: maxY, projection: projection),
            Coordinate3D(x: minX, y: minY, projection: projection),
        ]], calculateBoundingBox: true)
    }

    private func polygonWithHole() -> Polygon {
        Polygon(unchecked: [
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
        ], calculateBoundingBox: true)
    }

    private func crossingSquare() -> Polygon {
        Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: -170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]])
    }

    private struct SeededRandom {

        private var state: UInt64

        init(seed: UInt64) {
            state = seed
        }

        mutating func next(in range: ClosedRange<Double>) -> Double {
            state = (state &* 6_364_136_223_846_793_005) &+ 1_442_695_040_888_963_407
            let value = Double(state >> 11) / Double(1 << 53)
            return range.lowerBound + value * (range.upperBound - range.lowerBound)
        }

    }

    // MARK: - Point location

    // Prepared point location must match the one-shot implementation for
    // interior, exterior and boundary points.
    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID])
    func pointLocationMatchesOneShot(projection: Projection) throws {
        let polygon = square(projection: projection)
        let prepared = polygon.prepared()

        let points: [Coordinate3D] = [
            Coordinate3D(x: 5.0, y: 5.0, projection: projection),
            Coordinate3D(x: -1.0, y: -1.0, projection: projection),
            Coordinate3D(x: 20.0, y: 20.0, projection: projection),
            Coordinate3D(x: 0.0, y: 5.0, projection: projection),
            Coordinate3D(x: 10.0, y: 5.0, projection: projection),
            Coordinate3D(x: 5.0, y: 0.0, projection: projection),
            Coordinate3D(x: 5.0, y: 10.0, projection: projection),
            Coordinate3D(x: 0.0, y: 0.0, projection: projection),
            Coordinate3D(x: 10.0, y: 10.0, projection: projection),
        ]

        for point in points {
            #expect(prepared.locate(point) == polygon.locate(point))
            #expect(prepared.contains(point) == polygon.contains(point))
            #expect(prepared.covers(point) == polygon.covers(point))
        }
    }

    // Holes and hole boundaries must match the one-shot implementation.
    @Test
    func holesMatchOneShot() {
        let polygon = polygonWithHole()
        let prepared = polygon.prepared()

        let points: [Coordinate3D] = [
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 3.0, longitude: 5.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 7.0, longitude: 5.0),
            Coordinate3D(latitude: 12.0, longitude: 5.0),
        ]

        for point in points {
            #expect(prepared.locate(point) == polygon.locate(point))
            #expect(prepared.contains(point) == polygon.contains(point))
            #expect(prepared.covers(point) == polygon.covers(point))
        }
    }

    // Antimeridian-crossing rings use the same wrapped coordinate frame.
    @Test
    func antimeridianMatchesOneShot() {
        let polygon = crossingSquare()
        let prepared = polygon.prepared()

        let points: [Coordinate3D] = [
            Coordinate3D(latitude: 5.0, longitude: 180.0),
            Coordinate3D(latitude: 5.0, longitude: -180.0),
            Coordinate3D(latitude: 5.0, longitude: 172.0),
            Coordinate3D(latitude: 5.0, longitude: -172.0),
            Coordinate3D(latitude: 5.0, longitude: 160.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 180.0),
        ]

        for point in points {
            #expect(prepared.locate(point) == polygon.locate(point))
            #expect(prepared.contains(point) == polygon.contains(point))
            #expect(prepared.covers(point) == polygon.covers(point))
        }
    }

    // A deliberately world-spanning edge is not treated as an antimeridian
    // crossing by the one-shot path, and the prepared path must agree.
    @Test
    func worldSpanningMatchesOneShot() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(latitude: -10.0, longitude: -180.0),
            Coordinate3D(latitude: -10.0, longitude: 180.0),
            Coordinate3D(latitude: 10.0, longitude: 180.0),
            Coordinate3D(latitude: 10.0, longitude: -180.0),
            Coordinate3D(latitude: -10.0, longitude: -180.0),
        ]])
        let prepared = polygon.prepared()

        let points: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: 180.0),
            Coordinate3D(latitude: 0.0, longitude: -180.0),
            Coordinate3D(latitude: 20.0, longitude: 0.0),
        ]

        for point in points {
            #expect(prepared.locate(point) == polygon.locate(point))
            #expect(prepared.contains(point) == polygon.contains(point))
            #expect(prepared.covers(point) == polygon.covers(point))
        }
    }

    // A larger concave ring exercises many latitude buckets and candidate
    // edges, including vertices and edges that lie exactly on a query row.
    @Test
    func concaveRingMatchesOneShot() {
        let count = 181
        let coordinates = (0 ..< count).map { index -> Coordinate3D in
            let angle = Double(index) / Double(count) * 2.0 * Double.pi
            let radius = index.isMultiple(of: 2) ? 8.0 : 5.0
            return Coordinate3D(
                latitude: radius * sin(angle),
                longitude: radius * cos(angle))
        }
        let polygon = Polygon(unchecked: [coordinates + [coordinates[0]]])
        let prepared = polygon.prepared()

        var random = SeededRandom(seed: 17)
        for _ in 0 ..< 500 {
            let point = Coordinate3D(
                latitude: random.next(in: -10.0 ... 10.0),
                longitude: random.next(in: -10.0 ... 10.0))
            #expect(prepared.locate(point) == polygon.locate(point))
        }
    }

    // Grid snapping is applied to the prepared geometry and to query points.
    @Test
    func gridSizeMatchesOneShot() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.1, longitude: 0.1),
            Coordinate3D(latitude: 0.1, longitude: 9.9),
            Coordinate3D(latitude: 9.9, longitude: 9.9),
            Coordinate3D(latitude: 9.9, longitude: 0.1),
            Coordinate3D(latitude: 0.1, longitude: 0.1),
        ]])
        let prepared = polygon.prepared(gridSize: 1.0)

        for x in stride(from: 0.0, through: 10.0, by: 0.5) {
            let point = Coordinate3D(x: x, y: 5.0, projection: .epsg4326)
            #expect(prepared.locate(point) == polygon.locate(point, gridSize: 1.0))
        }
    }

    // MultiPolygon point location follows the same precedence rules.
    @Test
    func multiPolygonPointLocation() {
        let multiPolygon = MultiPolygon(unchecked: [
            square(minX: 0.0, minY: 0.0, maxX: 4.0, maxY: 4.0),
            square(minX: 6.0, minY: 0.0, maxX: 10.0, maxY: 4.0),
        ])
        let prepared = multiPolygon.prepared()

        let points: [Coordinate3D] = [
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 8.0),
            Coordinate3D(latitude: 2.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 2.0),
            Coordinate3D(latitude: 10.0, longitude: 2.0),
        ]

        for point in points {
            #expect(prepared.locate(point) == multiPolygon.locate(point))
            #expect(prepared.contains(point) == multiPolygon.contains(point))
            #expect(prepared.covers(point) == multiPolygon.covers(point))
        }
    }

    // MARK: - Geometry coverage

    // Prepared polygon coverage matches the one-shot predicates.
    @Test
    func polygonCoverageMatchesOneShot() {
        let container = square(minX: 0.0, minY: 0.0, maxX: 10.0, maxY: 10.0)
        let others = [
            square(minX: 1.0, minY: 1.0, maxX: 9.0, maxY: 9.0),
            square(minX: 5.0, minY: 5.0, maxX: 15.0, maxY: 15.0),
            square(minX: 10.0, minY: 0.0, maxX: 20.0, maxY: 5.0),
            square(minX: 0.0, minY: 0.0, maxX: 10.0, maxY: 10.0),
        ]
        let prepared = container.prepared()

        for other in others {
            #expect(prepared.covers(other) == container.covers(other))
            #expect(prepared.contains(other) == container.contains(other))
        }

        let projectedOther = square(minX: 1.0, minY: 1.0, maxX: 9.0, maxY: 9.0)
            .projected(to: .epsg3857)
        #expect(prepared.covers(projectedOther) == container.covers(projectedOther))
        #expect(prepared.contains(projectedOther) == container.contains(projectedOther))
    }

    // Holes and multi-polygons are handled through coverage as well.
    @Test
    func coverageWithHolesAndMultiPolygons() {
        let container = polygonWithHole()
        let prepared = container.prepared()
        let inside = square(minX: 1.0, minY: 1.0, maxX: 2.0, maxY: 2.0)
        let inHole = square(minX: 4.0, minY: 4.0, maxX: 6.0, maxY: 6.0)
        let overlapping = square(minX: 2.0, minY: 2.0, maxX: 5.0, maxY: 5.0)

        for other in [inside, inHole, overlapping] {
            #expect(prepared.covers(other) == container.covers(other))
            #expect(prepared.contains(other) == container.contains(other))
        }

        let multi = MultiPolygon(unchecked: [
            square(minX: 0.0, minY: 0.0, maxX: 10.0, maxY: 10.0),
            square(minX: 20.0, minY: 0.0, maxX: 30.0, maxY: 10.0),
        ])
        let preparedMulti = multi.prepared()
        let other = MultiPolygon(unchecked: [
            square(minX: 1.0, minY: 1.0, maxX: 2.0, maxY: 2.0),
            square(minX: 21.0, minY: 1.0, maxX: 22.0, maxY: 2.0),
        ])

        #expect(preparedMulti.covers(other) == multi.covers(other))
        #expect(preparedMulti.contains(other) == multi.contains(other))
    }

    // Geocentric coverage keeps the original frame when the prepared index
    // uses EPSG:4326 internally.
    @Test
    func geocentricCoverageMatchesOneShot() {
        let container = square().projected(to: .epsg4978)
        let other = square(minX: 1.0, minY: 1.0, maxX: 2.0, maxY: 2.0)
            .projected(to: .epsg4978)
        let prepared = container.prepared()

        #expect(prepared.covers(other) == container.covers(other))
        #expect(prepared.contains(other) == container.contains(other))
    }

    // Antimeridian coverage falls back to the existing geometry-level path.
    @Test
    func antimeridianCoverageMatchesOneShot() {
        let container = crossingSquare()
        let prepared = container.prepared()
        let others = [
            Polygon(unchecked: [[
                Coordinate3D(latitude: 2.0, longitude: 172.0),
                Coordinate3D(latitude: 2.0, longitude: 178.0),
                Coordinate3D(latitude: 8.0, longitude: 178.0),
                Coordinate3D(latitude: 8.0, longitude: 172.0),
                Coordinate3D(latitude: 2.0, longitude: 172.0),
            ]]),
            crossingSquare(),
        ]

        for other in others {
            #expect(prepared.covers(other) == container.covers(other))
            #expect(prepared.contains(other) == container.contains(other))
        }
    }

    // Empty geometries have no prepared parts.
    @Test
    func emptyGeometry() {
        let empty = MultiPolygon()
        let prepared = empty.prepared()
        let point = Coordinate3D(latitude: 0.0, longitude: 0.0)

        #expect(prepared.locate(point) == .exterior)
        #expect(prepared.contains(point) == false)
        #expect(prepared.covers(point) == false)
    }

}

// MARK: - Audit regressions

extension PreparedPolygonTests {

    @Test
    func degenerateHorizontalRingDoesNotCrash() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 20.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        let prepared = polygon.prepared()

        #expect(prepared.locate(Coordinate3D(latitude: 0.0, longitude: 5.0)) == .exterior)
    }

}
