@testable import GISTools
import Testing

struct EnumerateCoordinatesTests {

    @Test func featureCollection() {
        let a = Coordinate3D(latitude: 1.0, longitude: 2.0)
        let b = Coordinate3D(latitude: 3.0, longitude: 4.0)
        let c = Coordinate3D(latitude: 5.0, longitude: 6.0)
        let collection = FeatureCollection([
            Feature(Point(a)),
            Feature(LineString([b, c])!),
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

    @Test func feature() {
        let a = Coordinate3D(latitude: 1.0, longitude: 2.0)
        let b = Coordinate3D(latitude: 3.0, longitude: 4.0)
        let feature = Feature(LineString([a, b])!)

        var visited: [(Int, Coordinate3D)] = []
        feature.enumerateCoordinates { index, coord in
            visited.append((index, coord))
        }

        #expect(visited.count == 2)
        #expect(visited[0] == (0, a))
        #expect(visited[1] == (1, b))
    }

    @Test func geometryCollection() {
        let a = Coordinate3D(latitude: 1.0, longitude: 2.0)
        let b = Coordinate3D(latitude: 3.0, longitude: 4.0)
        let c = Coordinate3D(latitude: 5.0, longitude: 6.0)
        let collection = GeometryCollection([
            Point(a),
            LineString([b, c])!,
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

    @Test func geoJsonGeometry() {
        let a = Coordinate3D(latitude: 1.0, longitude: 2.0)
        let b = Coordinate3D(latitude: 3.0, longitude: 4.0)
        let lineString = LineString([a, b])!

        var visited: [(Int, Coordinate3D)] = []
        (lineString as GeoJsonGeometry).enumerateCoordinates { index, coord in
            visited.append((index, coord))
        }

        #expect(visited.count == 2)
        #expect(visited[0] == (0, a))
        #expect(visited[1] == (1, b))
    }

}
