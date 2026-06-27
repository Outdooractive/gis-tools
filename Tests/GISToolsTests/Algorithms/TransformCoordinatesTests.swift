@testable import GISTools
import Testing

struct TransformCoordinatesTests {

    // Validates coordinate transformation across all geometry types (Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon, GeometryCollection, Feature, FeatureCollection).
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

    // MARK: - Projections

    // Validates coordinate transformation in EPSG:3857.
    @Test
    func transformCoordinates3857() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0),
            Coordinate3D(x: 500_000.0, y: 500_000.0),
        ]))
        let result = lineString.transformedCoordinates { coordinate in
            Coordinate3D(
                x: coordinate.x + 100_000.0,
                y: coordinate.y + 100_000.0,
                projection: coordinate.projection)
        }
        #expect(result.coordinates.count == 2)
    }

    // Validates coordinate transformation in EPSG:4978.
    @Test
    func transformCoordinates4978() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 1.0, longitude: 1.0).projected(to: .epsg4978),
        ]))
        let result = lineString.transformedCoordinates { coordinate in
            Coordinate3D(
                x: coordinate.x + 1_000.0,
                y: coordinate.y + 1_000.0,
                z: coordinate.z,
                projection: coordinate.projection)
        }
        #expect(result.coordinates.count == 2)
        #expect(result.coordinates[0].projection == .epsg4978)
    }

    // Validates coordinate transformation with noSRID.
    @Test
    func transformCoordinatesNoSRID() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 100.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 100.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))
        let result = polygon.transformedCoordinates { coordinate in
            Coordinate3D(
                x: coordinate.x * 2.0,
                y: coordinate.y * 2.0,
                projection: coordinate.projection)
        }
        #expect(result.allCoordinates.count == 5)
    }

    // MARK: - Antimeridian

    // Validates coordinate transformation across the antimeridian.
    @Test
    func antimeridian() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 170.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0)
        ]]))
        let result = polygon.transformedCoordinates { coordinate in
            Coordinate3D(
                latitude: coordinate.latitude + 1.0,
                longitude: coordinate.longitude)
        }
        #expect(result != polygon)
        for coord in result.allCoordinates {
            #expect(coord.latitude > 0.0)
        }
    }

}
