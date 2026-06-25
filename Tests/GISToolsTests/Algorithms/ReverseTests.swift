@testable import GISTools
import Testing

struct ReverseTests {

    // Tests reversing coordinate order in LineString and MultiLineString.
    @Test
    func lineString() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
        ]))
        let lineStringReversed = lineString.reversed
        #expect(lineStringReversed.coordinates.map(\.latitude) == [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])

        let multiLineString = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 3.0, longitude: 3.0),
                Coordinate3D(latitude: 4.0, longitude: 4.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 3.0, longitude: 3.0),
                Coordinate3D(latitude: 4.0, longitude: 4.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ],
        ]))
        let multiLineStringReversed = multiLineString.reversed
        #expect(multiLineStringReversed.lineStrings[0].coordinates.map(\.latitude) == [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])
        #expect(multiLineStringReversed.lineStrings[1].coordinates.map(\.latitude) == [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])
    }

    // Tests reversing geometry order in FeatureCollection and coordinate order within each.
    @Test
    func featureCollection() async throws {
        let featureCollection = FeatureCollection([
            Feature(try #require(LineString([
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 3.0, longitude: 3.0),
                Coordinate3D(latitude: 4.0, longitude: 4.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
            ]))),
            Feature(Point(Coordinate3D(latitude: 20.0, longitude: 20.0))),
            Feature(try #require(MultiLineString([
                [
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                    Coordinate3D(latitude: 1.0, longitude: 1.0),
                    Coordinate3D(latitude: 2.0, longitude: 2.0),
                    Coordinate3D(latitude: 3.0, longitude: 3.0),
                    Coordinate3D(latitude: 4.0, longitude: 4.0),
                    Coordinate3D(latitude: 5.0, longitude: 5.0),
                ],
                [
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                    Coordinate3D(latitude: 1.0, longitude: 1.0),
                    Coordinate3D(latitude: 2.0, longitude: 2.0),
                    Coordinate3D(latitude: 3.0, longitude: 3.0),
                    Coordinate3D(latitude: 4.0, longitude: 4.0),
                    Coordinate3D(latitude: 5.0, longitude: 5.0),
                ],
            ]))),
            Feature(Point(Coordinate3D(latitude: 40.0, longitude: 40.0))),
        ])
        let reversed = featureCollection.reversed

        #expect(reversed.features.map(\.geometry.type) == [.point, .multiLineString, .point, .lineString])

        #expect(reversed.features[3].allCoordinates.map(\.latitude) == [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])
        #expect(reversed.features[2].allCoordinates == [Coordinate3D(latitude: 20.0, longitude: 20.0)])
        #expect((reversed.features[1].geometry as? MultiLineString)?.lineStrings[0].coordinates.map(\.latitude) == [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])
        #expect((reversed.features[1].geometry as? MultiLineString)?.lineStrings[1].coordinates.map(\.latitude) == [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])
        #expect(reversed.features[0].allCoordinates == [Coordinate3D(latitude: 40.0, longitude: 40.0)])
    }

    // Tests reversing coordinates within GeometryCollection geometries.
    @Test
    func geometryCollection() async throws {
        let geometryCollection = GeometryCollection([
            try #require(LineString([
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
            ])),
            Point(Coordinate3D(latitude: 20.0, longitude: 20.0)),
            try #require(MultiLineString([[
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
            ]])),
        ])
        let reversed = geometryCollection.reversed

        #expect(reversed.geometries[0].type == .lineString)
        #expect(reversed.geometries[1].type == .point)
        #expect(reversed.geometries[2].type == .multiLineString)

        #expect(reversed.geometries[0].allCoordinates.map(\.latitude) == [1.0, 0.0])
        #expect(reversed.geometries[1].allCoordinates.map(\.latitude) == [20.0])
        #expect(reversed.geometries[2].allCoordinates.map(\.latitude) == [1.0, 0.0])
    }

    // MARK: - Projections

    @Test
    func reverse3857() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 100_000.0, y: 100_000.0),
            Coordinate3D(x: 200_000.0, y: 0.0),
        ]))
        let reversed = lineString.reversed
        #expect(reversed.coordinates.count == 3)
    }

    // Validates reverse in EPSG:4978.
    @Test
    func reverse4978() async throws {
        let c0 = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let c1 = Coordinate3D(latitude: 1.0, longitude: 0.0).projected(to: .epsg4978)
        let c2 = Coordinate3D(latitude: 1.0, longitude: 1.0).projected(to: .epsg4978)
        let lineString = try #require(LineString([c0, c1, c2]))
        let reversed = lineString.reversed
        #expect(reversed.coordinates.count == 3)
    }

    // Validates reverse in noSRID.
    @Test
    func reverseNoSRID() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID),
        ]))
        let reversed = lineString.reversed
        #expect(reversed.coordinates.count == 3)
        #expect(reversed.coordinates.first == Coordinate3D(
            x: 100.0, y: 100.0, projection: .noSRID))
    }

    // MARK: - Edge cases

    @Test
    func reverseSinglePoint() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let reversed = point.reversed
        #expect(reversed.coordinate == point.coordinate)
    }

}
