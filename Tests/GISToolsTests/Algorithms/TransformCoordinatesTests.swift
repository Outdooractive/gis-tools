@testable import GISTools
import Testing

struct TransformCoordinatesTests {

    @Test
    func transformCoordinates() async throws {
        let transformer: (Coordinate3D) -> Coordinate3D = { coordinate in
            if let altitude = coordinate.altitude {
                return Coordinate3D(
                    latitude: coordinate.latitude * 2.0,
                    longitude: coordinate.longitude * 2.0,
                    altitude: altitude * 2.0)
            }
            else {
                return Coordinate3D(
                    latitude: coordinate.latitude * 2.0,
                    longitude: coordinate.longitude * 2.0)
            }
        }

        let point = Point(Coordinate3D(latitude: 100.0, longitude: 100.0, altitude: 1000.0))
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0)
        ]))
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0)
        ]))
        let multiLineString = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 100.0),
                Coordinate3D(latitude: 1.0, longitude: 101.0)
            ],
            [
                Coordinate3D(latitude: 2.0, longitude: 102.0),
                Coordinate3D(latitude: 3.0, longitude: 103.0)
            ]
        ]))
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 100.0),
            Coordinate3D(latitude: 0.0, longitude: 100.0)
        ]]))
        let multiPolygon = try #require(MultiPolygon([[
            [
                Coordinate3D(latitude: 2.0, longitude: 102.0),
                Coordinate3D(latitude: 2.0, longitude: 103.0),
                Coordinate3D(latitude: 3.0, longitude: 103.0),
                Coordinate3D(latitude: 3.0, longitude: 102.0),
                Coordinate3D(latitude: 2.0, longitude: 102.0)
            ]
        ], [
            [
                Coordinate3D(latitude: 0.0, longitude: 100.0),
                Coordinate3D(latitude: 0.0, longitude: 101.0),
                Coordinate3D(latitude: 1.0, longitude: 101.0),
                Coordinate3D(latitude: 1.0, longitude: 100.0),
                Coordinate3D(latitude: 0.0, longitude: 100.0)
            ], [
                Coordinate3D(latitude: 0.0, longitude: 100.2),
                Coordinate3D(latitude: 1.0, longitude: 100.2),
                Coordinate3D(latitude: 1.0, longitude: 100.8),
                Coordinate3D(latitude: 0.0, longitude: 100.8),
                Coordinate3D(latitude: 0.0, longitude: 100.2)
            ]
        ]]))
        let geometryCollection = GeometryCollection([point, lineString])
        let feature = Feature(point)
        let featureCollection = FeatureCollection([feature])

        let pointTransformed = point.transformedCoordinates(transformer)
        let multiPointTransformed = multiPoint.transformedCoordinates(transformer)
        let lineStringTransformed = lineString.transformedCoordinates(transformer)
        let multiLineStringTransformed = multiLineString.transformedCoordinates(transformer)
        let polygonTransformed = polygon.transformedCoordinates(transformer)
        let multiPolygonTransformed = multiPolygon.transformedCoordinates(transformer)
        let geometryCollectionTransformed = geometryCollection.transformedCoordinates(transformer)
        let featureTransformed = feature.transformedCoordinates(transformer)
        let featureCollectionTransformed = featureCollection.transformedCoordinates(transformer)

        let pointResult = Point(Coordinate3D(latitude: 200.0, longitude: 200.0, altitude: 2000.0))
        let multiPointResult = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 200.0),
            Coordinate3D(latitude: 2.0, longitude: 202.0)
        ]))
        let lineStringResult = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 200.0),
            Coordinate3D(latitude: 2.0, longitude: 202.0)
        ]))
        let multiLineStringResult = try #require(MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 200.0),
                Coordinate3D(latitude: 2.0, longitude: 202.0)
            ],
            [
                Coordinate3D(latitude: 4.0, longitude: 204.0),
                Coordinate3D(latitude: 6.0, longitude: 206.0)
            ]
        ]))
        let polygonResult = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 200.0),
            Coordinate3D(latitude: 0.0, longitude: 202.0),
            Coordinate3D(latitude: 2.0, longitude: 202.0),
            Coordinate3D(latitude: 2.0, longitude: 200.0),
            Coordinate3D(latitude: 0.0, longitude: 200.0)
        ]]))
        let multiPolygonResult = try #require(MultiPolygon([[
            [
                Coordinate3D(latitude: 4.0, longitude: 204.0),
                Coordinate3D(latitude: 4.0, longitude: 206.0),
                Coordinate3D(latitude: 6.0, longitude: 206.0),
                Coordinate3D(latitude: 6.0, longitude: 204.0),
                Coordinate3D(latitude: 4.0, longitude: 204.0)
            ]
        ], [
            [
                Coordinate3D(latitude: 0.0, longitude: 200.0),
                Coordinate3D(latitude: 0.0, longitude: 202.0),
                Coordinate3D(latitude: 2.0, longitude: 202.0),
                Coordinate3D(latitude: 2.0, longitude: 200.0),
                Coordinate3D(latitude: 0.0, longitude: 200.0)
            ], [
                Coordinate3D(latitude: 0.0, longitude: 200.4),
                Coordinate3D(latitude: 2.0, longitude: 200.4),
                Coordinate3D(latitude: 2.0, longitude: 201.6),
                Coordinate3D(latitude: 0.0, longitude: 201.6),
                Coordinate3D(latitude: 0.0, longitude: 200.4)
            ]
        ]]))
        let geometryCollectionResult = GeometryCollection([pointResult, lineStringResult])
        let featureResult = Feature(pointResult)
        let featureCollectionResult = FeatureCollection([featureResult])

        #expect(pointTransformed == pointResult)
        #expect(multiPointTransformed == multiPointResult)
        #expect(lineStringTransformed == lineStringResult)
        #expect(multiLineStringTransformed == multiLineStringResult)
        #expect(polygonTransformed == polygonResult)
        #expect(multiPolygonTransformed == multiPolygonResult)
        #expect(geometryCollectionTransformed == geometryCollectionResult)
        #expect(featureTransformed == featureResult)
        #expect(featureCollectionTransformed == featureCollectionResult)
    }

}
