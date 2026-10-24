import Foundation
@testable import GISTools
import Testing

struct GeoJsonDecoderTests {

    /// Validates the typed decoder builds every geometry type.
    @Test
    func decodesAllGeometryTypes() throws {
        let json = #"""
        {"type":"FeatureCollection","features":[
          {"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{}},
          {"type":"Feature","geometry":{"type":"MultiPoint","coordinates":[[1,2],[3,4]]},"properties":{}},
          {"type":"Feature","geometry":{"type":"LineString","coordinates":[[1,2],[3,4]]},"properties":{}},
          {"type":"Feature","geometry":{"type":"MultiLineString","coordinates":[[[1,2],[3,4]],[[5,6],[7,8]]]},"properties":{}},
          {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[0,1],[1,1],[0,0]]]},"properties":{}},
          {"type":"Feature","geometry":{"type":"MultiPolygon","coordinates":[[[[0,0],[0,1],[1,1],[0,0]]]]},"properties":{}},
          {"type":"Feature","geometry":{"type":"GeometryCollection","geometries":[{"type":"Point","coordinates":[9,9]}]},"properties":{}}
        ]}
        """#
        let collection = try #require(FeatureCollection(jsonData: Data(json.utf8)))

        #expect(collection.features.count == 7)
        #expect(collection.features[0].geometry is Point)
        #expect(collection.features[1].geometry is MultiPoint)
        #expect(collection.features[2].geometry is LineString)
        #expect(collection.features[3].geometry is MultiLineString)
        #expect(collection.features[4].geometry is Polygon)
        #expect(collection.features[5].geometry is MultiPolygon)
        #expect(collection.features[6].geometry is GeometryCollection)
    }

    /// Validates bounding boxes and foreign members on features, geometries and
    /// collections are preserved.
    @Test
    func preservesBoundingBoxesAndForeignMembers() throws {
        let json = #"""
        {"type":"FeatureCollection","bbox":[-10,-10,10,10],"source":"test","features":[
          {"type":"Feature","id":"a","geometry":{"type":"Point","coordinates":[1,2],"custom":1},"properties":{"p":1},"bbox":[0,0,1,2],"f":2}
        ]}
        """#
        let collection = try #require(FeatureCollection(jsonData: Data(json.utf8)))
        let feature = try #require(collection.features.first)
        let point = try #require(feature.geometry as? Point)

        #expect(collection.boundingBox != nil)
        #expect(collection.foreignMembers["source"] as? String == "test")
        #expect(feature.id == .string("a"))
        #expect(feature.boundingBox != nil)
        #expect(feature.foreignMembers["f"] as? Int == 2)
        #expect(point.foreignMembers["custom"] as? Int == 1)
        #expect(JSONValue(value: feature.properties["p"]) == .int(1))
    }

    /// Validates an unlocated feature decodes through the typed path.
    @Test
    func decodesUnlocatedFeature() throws {
        let json = #"""
        {"type":"Feature","geometry":null,"properties":{"a":1}}
        """#
        let feature = try #require(Feature(jsonData: Data(json.utf8)))

        #expect(feature.geometry == nil)
        #expect(JSONValue(value: feature.properties["a"]) == .int(1))
    }

    /// A bare geometry decodes through the typed path.
    @Test
    func decodesBareGeometry() throws {
        let json = #"{"type":"LineString","coordinates":[[1,2],[3,4]]}"#
        let line = try #require(LineString(jsonData: Data(json.utf8)))

        #expect(line.coordinates.count == 2)
        #expect(line.coordinates[0] == Coordinate3D(latitude: 2.0, longitude: 1.0))
    }

    // MARK: - Audit regressions

    @Test
    func malformedDocumentsAgreeAcrossEveryEntryPoint() throws {
        let documents = [
            #"{"type":"LineString","coordinates":[[0,0]]}"#,
            #"{"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0]]]},"properties":{}},{"type":"Feature","geometry":{"type":"Point","coordinates":["x",2]},"properties":{}},{"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{}}]}"#,
            #"{"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]}}"#,
            #"{"type":"MultiLineString","coordinates":[]}"#,
        ]

        for jsonString in documents {
            let data = Data(jsonString.utf8)
            let json = try? JSONSerialization.jsonObject(with: data)
            let parsed = try GeoJsonParser.parse(jsonString: jsonString)
            let expectedCount: Int? =
                if let collection = parsed.object as? FeatureCollection {
                    collection.features.count
                }
                else {
                    parsed.object == nil ? nil : 1
                }

            let fromData = FeatureCollection(jsonData: data)
            let fromString = FeatureCollection(jsonString: jsonString)
            let fromJSON = FeatureCollection(json: json)
            let readerObject = GeoJsonReader.geoJsonFrom(jsonData: data)
            let fromReader = readerObject as? FeatureCollection
                ?? readerObject.flatMap { FeatureCollection($0) }
            let fromDecoder = try? JSONDecoder().decode(FeatureCollection.self, from: data)

            #expect((fromData != nil) == (parsed.object != nil), "\(jsonString)")
            #expect(fromData?.features.count == expectedCount, "\(jsonString)")
            #expect(fromString?.features.count == expectedCount, "\(jsonString)")
            #expect(fromJSON?.features.count == expectedCount, "\(jsonString)")
            #expect(fromReader?.features.count == expectedCount, "\(jsonString)")
            #expect(fromDecoder?.features.count == expectedCount, "\(jsonString)")

            // Every surviving geometry must itself be structurally valid.
            for feature in fromData?.features ?? [] {
                if let geometry = feature.geometry {
                    #expect(geometry.isStructurallyValid, "\(jsonString): \(geometry)")
                }
            }
        }
    }

    @Test
    func validDocumentIsAcceptedByEveryEntryPoint() throws {
        let jsonString = #"{"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{"a":1}}]}"#
        let data = Data(jsonString.utf8)
        let json = try #require(try? JSONSerialization.jsonObject(with: data))

        #expect(FeatureCollection(jsonData: data)?.features.count == 1)
        #expect(FeatureCollection(jsonString: jsonString)?.features.count == 1)
        #expect(FeatureCollection(json: json)?.features.count == 1)
        #expect(GeoJsonReader.geoJsonFrom(jsonData: data) != nil)
        #expect((try? JSONDecoder().decode(FeatureCollection.self, from: data))?.features.count == 1)
    }

    @Test
    func decoderRejectsInvalidBoundingBoxAndUnsupportedTypes() {
        let invalidBox = Data(#"{"type":"Point","coordinates":[1,2],"bbox":[0,0,1]}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Point.self, from: invalidBox)
        }

        let unsupported = Data(#"{"type":"Circle","coordinates":[1,2]}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Point.self, from: unsupported)
        }

        let missingFeatureGeometry = Data(#"{"type":"Feature","properties":{}}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Feature.self, from: missingFeatureGeometry)
        }
    }

}
