import Foundation
@testable import GISTools
import Testing

struct GeometryCollectionTests {

    static let geometryCollectionJson = """
    {
        "type": "GeometryCollection",
        "geometries": [{
            "type": "Point",
            "coordinates": [100.0, 0.0]
        }, {
            "type": "LineString",
            "coordinates": [
                [101.0, 0.0],
                [102.0, 1.0]
            ]
        }],
        "other": "something else"
    }
    """

    // Validates loading a GeometryCollection from JSON and accessing its geometries and foreign members.
    @Test
    func loadJson() async throws {
        let geometryCollection = try #require(GeometryCollection(jsonString: GeometryCollectionTests.geometryCollectionJson))

        #expect(geometryCollection.type == GeoJsonType.geometryCollection)
        #expect(geometryCollection.projection == .epsg4326)
        #expect(geometryCollection.geometries.count == 2)
        #expect(geometryCollection.foreignMember(for: "other") == "something else")
        #expect(geometryCollection[foreignMember: "other"] == "something else")
    }

    // Validates creating a GeometryCollection from geometries and verifying its JSON string output.
    @Test
    func createJson() async throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 100.0))
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 101.0),
            Coordinate3D(latitude: 1.0, longitude: 102.0)
        ]))
        let geometryCollection = GeometryCollection([point, lineString])
        let string = try #require(geometryCollection.asJsonString())

        #expect(geometryCollection.projection == .epsg4326)
        #expect(string.contains("\"type\":\"GeometryCollection\""))
        #expect(string.contains("\"coordinates\":[100,0]"))
        #expect(string.contains("\"coordinates\":[[101,0],[102,1]]"))
    }

    // Validates that a GeometryCollection encodes to JSON data matching its jsonData output.
    @Test
    func encodable() async throws {
        let geometryCollection = try #require(GeometryCollection(jsonString: GeometryCollectionTests.geometryCollectionJson))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        #expect(try encoder.encode(geometryCollection) == geometryCollection.asJsonData(prettyPrinted: true))
    }

    // Validates that a GeometryCollection round-trips through JSON encoding and decoding.
    @Test
    func decodable() async throws {
        let geometryCollectionData = try #require(GeometryCollection(jsonString: GeometryCollectionTests.geometryCollectionJson)?.asJsonData(prettyPrinted: true))
        let geometryCollection = try JSONDecoder().decode(GeometryCollection.self, from: geometryCollectionData)

        #expect(geometryCollection.projection == .epsg4326)
        #expect(geometryCollectionData == geometryCollection.asJsonData(prettyPrinted: true))
    }

    // MARK: - Hashable

    // Validates that equal GeometryCollections have equal hashes and
    // deduplicate in sets.
    @Test
    func hashable() async throws {
        let geometries: [GeoJsonGeometry] = [
            Point(Coordinate3D(latitude: 47.3, longitude: 8.5)),
            try #require(LineString([
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
            ])),
        ]
        let geometryCollectionA = GeometryCollection(geometries)
        let geometryCollectionB = GeometryCollection(geometries)
        let geometryCollectionC = GeometryCollection([geometries[0]])

        #expect(geometryCollectionA == geometryCollectionB)
        #expect(geometryCollectionA.hashValue == geometryCollectionB.hashValue)
        #expect(geometryCollectionA != geometryCollectionC)

        let set: Set<GeometryCollection> = [geometryCollectionA, geometryCollectionB, geometryCollectionC]
        #expect(set.count == 2)
    }

}

// MARK: - GeoJSON audit regressions

extension GeometryCollectionTests {

    /// GeometryCollection mutation operations keep projections and bounding boxes consistent.
    @Test
    func geometryCollectionOperations() throws {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 1.0),
        ]))
        var collection = GeometryCollection([point], calculateBoundingBox: true)

        collection.appendGeometry(line)
        collection.insertGeometry(point, atIndex: 0)

        #expect(collection.geometries.count == 3)
        #expect(collection.boundingBox?.southWest.longitude == 0.0)
        #expect(collection.boundingBox?.northEast.longitude == 1.0)

        let removed = collection.removeGeometry(at: 1)
        #expect(removed?.type == .point)
        #expect(collection.geometries.count == 2)
        #expect(collection.boundingBox?.northEast.longitude == 1.0)

        collection.mapGeometries { geometry in
            geometry.type == .point
                ? Point(Coordinate3D(latitude: 0.0, longitude: 2.0))
                : geometry
        }
        #expect(collection.geometries.first?.allCoordinates.first?.longitude == 2.0)

        collection.compactMapGeometries { geometry in
            geometry.type == .point ? geometry : nil
        }
        #expect(collection.geometries.count == 1)

        collection.filterGeometries { _ in false }
        #expect(collection.geometries.isEmpty)
    }

}
// MARK: - Audit regressions

extension GeometryCollectionTests {

    /// Negative geometry insertion indices are ignored instead of trapping.
    @Test
    func negativeGeometryInsertionIndexIsIgnored() {
        let point = Point(Coordinate3D(latitude: 0.0, longitude: 0.0))
        var geometryCollection = GeometryCollection([point])

        geometryCollection.insertGeometry(point, atIndex: -1)

        #expect(geometryCollection.geometries.count == 1)
    }

    /// Foreign members survive a GeometryCollection JSON round trip.
    @Test
    func geometryCollectionForeignMembersSurviveJSONRoundTrip() throws {
        let json = #"""
        {"type":"GeometryCollection","geometries":[{"type":"Point","coordinates":[1,2]}],"source":"test"}
        """#
        let geometry = try JSONDecoder().decode(
            GeometryCollection.self,
            from: Data(json.utf8))

        #expect(geometry.foreignMember(for: "source") == "test")
    }

}
