@testable import GISTools
import Testing

struct EnumerateCoordinatesTests {

    // Tests coordinate enumeration over a FeatureCollection.
    @Test func featureCollection() throws {
        let a = Coordinate3D(latitude: 1.0, longitude: 2.0)
        let b = Coordinate3D(latitude: 3.0, longitude: 4.0)
        let c = Coordinate3D(latitude: 5.0, longitude: 6.0)
        let collection = FeatureCollection([
            Feature(Point(a)),
            Feature(try #require(LineString([b, c]))),
        ])

        var visited: [(Int, Int, Coordinate3D)] = []
        collection.enumerateCoordinates { featureIndex, coordIndex, coord in
            visited.append((featureIndex, coordIndex, coord))
        }

        #expect(visited.count == 3)
        #expect(visited[0] == (0, 0, a))
        #expect(visited[1] == (1, 0, b))
        #expect(visited[2] == (1, 1, c))
    }

    // Tests coordinate enumeration over a single Feature.
    @Test func feature() throws {
        let a = Coordinate3D(latitude: 1.0, longitude: 2.0)
        let b = Coordinate3D(latitude: 3.0, longitude: 4.0)
        let feature = Feature(try #require(LineString([a, b])))

        var visited: [(Int, Coordinate3D)] = []
        feature.enumerateCoordinates { index, coord in
            visited.append((index, coord))
        }

        #expect(visited.count == 2)
        #expect(visited[0] == (0, a))
        #expect(visited[1] == (1, b))
    }

    // Tests coordinate enumeration over a GeometryCollection.
    @Test func geometryCollection() throws {
        let a = Coordinate3D(latitude: 1.0, longitude: 2.0)
        let b = Coordinate3D(latitude: 3.0, longitude: 4.0)
        let c = Coordinate3D(latitude: 5.0, longitude: 6.0)
        let collection = GeometryCollection([
            Point(a),
            try #require(LineString([b, c])),
        ])

        var visited: [(Int, Int, Coordinate3D)] = []
        collection.enumerateCoordinates { geometryIndex, coordIndex, coord in
            visited.append((geometryIndex, coordIndex, coord))
        }

        #expect(visited.count == 3)
        #expect(visited[0] == (0, 0, a))
        #expect(visited[1] == (1, 0, b))
        #expect(visited[2] == (1, 1, c))
    }

    // Tests coordinate enumeration via GeoJsonGeometry protocol.
    @Test func geoJsonGeometry() throws {
        let a = Coordinate3D(latitude: 1.0, longitude: 2.0)
        let b = Coordinate3D(latitude: 3.0, longitude: 4.0)
        let lineString = try #require(LineString([a, b]))

        var visited: [(Int, Coordinate3D)] = []
        (lineString as GeoJsonGeometry).enumerateCoordinates { index, coord in
            visited.append((index, coord))
        }

        #expect(visited.count == 2)
        #expect(visited[0] == (0, a))
        #expect(visited[1] == (1, b))
    }

    // MARK: - Projections

    // Tests coordinate enumeration in EPSG:3857.
    @Test func enumerateCoordinates3857() throws {
        let a = Coordinate3D(x: 0.0, y: 0.0)
        let b = Coordinate3D(x: 100_000.0, y: 0.0)
        let c = Coordinate3D(x: 100_000.0, y: 100_000.0)
        let d = Coordinate3D(x: 0.0, y: 100_000.0)
        let polygon = try #require(Polygon([[a, b, c, d, a]]))

        var visited: [(Int, Coordinate3D)] = []
        polygon.enumerateCoordinates { index, coord in
            visited.append((index, coord))
        }

        #expect(visited.count == 5)
    }

    // Tests coordinate enumeration in EPSG:4978.
    @Test func enumerateCoordinates4978() throws {
        let a = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let b = Coordinate3D(latitude: 1.0, longitude: 0.0).projected(to: .epsg4978)
        let c = Coordinate3D(latitude: 1.0, longitude: 1.0).projected(to: .epsg4978)
        let d = Coordinate3D(latitude: 0.0, longitude: 1.0).projected(to: .epsg4978)
        let polygon = try #require(Polygon([[a, b, c, d, a]]))

        var visited: [(Int, Coordinate3D)] = []
        polygon.enumerateCoordinates { index, coord in
            visited.append((index, coord))
        }

        #expect(visited.count == 5)
    }

    // Tests coordinate enumeration with noSRID projection.
    @Test func enumerateCoordinatesNoSRID() throws {
        let a = Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID)
        let b = Coordinate3D(x: 10.0, y: 0.0, projection: .noSRID)
        let line = try #require(LineString([a, b]))

        var visited: [(Int, Coordinate3D)] = []
        line.enumerateCoordinates { index, coord in
            visited.append((index, coord))
        }

        #expect(visited.count == 2)
    }

}
