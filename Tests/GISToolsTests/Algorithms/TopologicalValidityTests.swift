import Foundation
@testable import GISTools
import Testing

struct TopologicalValidityTests {

    private func square(
        minX: Double = 0.0,
        minY: Double = 0.0,
        maxX: Double = 10.0,
        maxY: Double = 10.0,
        projection: Projection = .epsg4326,
    ) -> Polygon {
        Polygon(unchecked: [[
            Coordinate3D(x: minX, y: minY, projection: projection),
            Coordinate3D(x: maxX, y: minY, projection: projection),
            Coordinate3D(x: maxX, y: maxY, projection: projection),
            Coordinate3D(x: minX, y: maxY, projection: projection),
            Coordinate3D(x: minX, y: minY, projection: projection),
        ]])
    }

    // MARK: - Structural vs topological

    @Test
    func structuralValidityDoesNotImplyTopologicalValidity() {
        let unclosed = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]])

        #expect(unclosed.isStructurallyValid)
        #expect(unclosed.isValid == false)
        #expect(unclosed.isValidReason != nil)
    }

    @Test
    func validPolygon() {
        let polygon = square()
        #expect(polygon.isValid)
        #expect(polygon.isValidReason == nil)
        #expect(polygon.isSimple)
    }

    @Test(arguments: [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID])
    func validPolygonAcrossProjections(projection: Projection) {
        let polygon: Polygon =
            switch projection {
            case .epsg4978:
                square().projected(to: .epsg4978)
            case .epsg4326:
                square()
            default:
                square(
                    minX: 0.0,
                    minY: 0.0,
                    maxX: 1000.0,
                    maxY: 1000.0,
                    projection: projection)
            }

        #expect(polygon.isValid)
        #expect(polygon.isSimple)
    }

    // MARK: - Invalid polygons

    @Test
    func selfIntersectingPolygon() {
        let bowtie = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])

        #expect(bowtie.isValid == false)
        #expect(bowtie.isSimple == false)
        #expect(bowtie.isValidReason != nil)
    }

    @Test
    func holeOutsideShell() {
        let polygon = Polygon(unchecked: [
            square().coordinates[0],
            [
                Coordinate3D(latitude: 20.0, longitude: 20.0),
                Coordinate3D(latitude: 20.0, longitude: 25.0),
                Coordinate3D(latitude: 25.0, longitude: 25.0),
                Coordinate3D(latitude: 25.0, longitude: 20.0),
                Coordinate3D(latitude: 20.0, longitude: 20.0),
            ],
        ])

        #expect(polygon.isValid == false)
        #expect(polygon.isValidReason != nil)
    }

    @Test
    func overlappingHoles() {
        let polygon = Polygon(unchecked: [
            square().coordinates[0],
            [
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 2.0, longitude: 8.0),
                Coordinate3D(latitude: 8.0, longitude: 8.0),
                Coordinate3D(latitude: 8.0, longitude: 2.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
            ],
            [
                Coordinate3D(latitude: 4.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 9.0),
                Coordinate3D(latitude: 9.0, longitude: 9.0),
                Coordinate3D(latitude: 9.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 4.0),
            ],
        ])

        #expect(polygon.isValid == false)
    }

    @Test
    func nestedHoles() {
        let polygon = Polygon(unchecked: [
            square().coordinates[0],
            [
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 2.0, longitude: 8.0),
                Coordinate3D(latitude: 8.0, longitude: 8.0),
                Coordinate3D(latitude: 8.0, longitude: 2.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
            ],
            [
                Coordinate3D(latitude: 4.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 6.0),
                Coordinate3D(latitude: 6.0, longitude: 6.0),
                Coordinate3D(latitude: 6.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 4.0),
            ],
        ])

        #expect(polygon.isValid == false)
    }

    @Test
    func overlappingMultiPolygonComponents() {
        let multiPolygon = MultiPolygon(unchecked: [
            square(),
            square(minX: 5.0, minY: 5.0, maxX: 15.0, maxY: 15.0),
        ])

        #expect(multiPolygon.isValid == false)
    }

    // MARK: - Simple

    @Test
    func lineSimplicity() {
        let simple = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ])
        let crossing = LineString(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ])

        #expect(simple.isSimple)
        #expect(crossing.isSimple == false)
        #expect(crossing.isValid)
    }

    @Test
    func duplicateMultiPointIsNotSimple() {
        let multiPoint = MultiPoint(unchecked: [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ])

        #expect(multiPoint.isValid)
        #expect(multiPoint.isSimple == false)
    }

    // MARK: - Wrappers

    @Test
    func wrappersUseTopologicalValidity() {
        let invalidPolygon = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]])
        let invalid = Feature(invalidPolygon)
        let collection = FeatureCollection([invalid])

        #expect(invalid.isValid == false)
        #expect(collection.isValid == false)
        #expect(collection.isValidReason != nil)
    }

}

// MARK: - Audit regressions

extension TopologicalValidityTests {

    @Test
    func zeroLengthLineIsInvalid() throws {
        let coordinate = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let line = try #require(LineString([coordinate, coordinate]))

        #expect(line.isStructurallyValid)
        #expect(!line.isValid)
        #expect(line.isValidReason?.contains("zero-length") == true)
    }

    @Test
    func multiPolygonWithSharedEdgeIsInvalid() throws {
        let first = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let second = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
        ]]))
        let multiPolygon = try #require(MultiPolygon([first, second]))

        #expect(multiPolygon.isStructurallyValid)
        #expect(!multiPolygon.isValid)
    }

    @Test
    func explicitRingFailureReasons() {
        let unclosed = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
        ]])
        #expect(unclosed.isValidReason?.contains("not closed") == true)

        let twoPoints = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        #expect(twoPoints.isValidReason?.contains("four positions") == true)

        let zeroArea = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])
        #expect(zeroArea.isValidReason?.contains("zero area") == true)
    }

    @Test
    func holeCrossingShellIsInvalid() {
        let polygon = Polygon(unchecked: [
            square().coordinates[0],
            [
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 15.0, longitude: 15.0),
                Coordinate3D(latitude: 15.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ])
        #expect(!polygon.isValid)
        #expect(polygon.isValidReason?.contains("crosses") == true)
    }

    @Test
    func crossingMultiLineStringIsNotSimple() throws {
        let multiLine = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
            ],
            [
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
            ],
        ]))
        #expect(!multiLine.isSimple)
    }

    @Test
    func emptyMultiPolygonHasReason() {
        let multiPolygon = MultiPolygon()
        #expect(!multiPolygon.isValid)
        #expect(multiPolygon.isValidReason?.contains("no polygons") == true)
    }

    @Test
    func geocentricInvalidPolygonIsRejected() {
        let bowtie = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]).projected(to: .epsg4978)
        #expect(!bowtie.isValid)
    }

    @Test
    func geometryCollectionReportsInvalidMember() {
        let valid = square()
        let invalid = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
        ]])
        let collection = GeometryCollection([valid, invalid])
        #expect(!collection.isValid)
        #expect(collection.isValidReason?.contains("closed") == true)
    }

    @Test
    func multiPolygonWithSharedVertexIsValid() throws {
        let first = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let second = try #require(Polygon([[
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]]))
        let multiPolygon = try #require(MultiPolygon([first, second]))
        #expect(multiPolygon.isValid)
    }

}
