@testable import GISTools
import Testing

struct ReverseTests {

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

}
