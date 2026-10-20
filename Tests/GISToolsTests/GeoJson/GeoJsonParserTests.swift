import Foundation
@testable import GISTools
import Testing

struct GeoJsonParserTests {

    private let validJson = #"""
    {"type":"FeatureCollection","features":[
      {"type":"Feature","geometry":null,"properties":{"a":1,"none":null}},
      {"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{"a":2}}
    ]}
    """#

    private let malformedJson = #"""
    {"type":"FeatureCollection","features":[
      {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0]]]},"properties":{}},
      {"type":"Feature","geometry":{"type":"Point","coordinates":["x",2]},"properties":{}},
      {"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{}}
    ]}
    """#

    // A clean document has no issues and preserves unlocated features.
    @Test
    func validDocumentHasNoIssues() async throws {
        let result = try GeoJsonParser.parse(jsonString: validJson)
        let collection = try #require(result.object as? FeatureCollection)

        #expect(result.issues.isEmpty)
        #expect(collection.features.count == 2)
        #expect(collection.features[0].geometry == nil)
        #expect(collection.features[1].geometry != nil)
    }

    // Lenient parsing returns the object and reports every malformed element.
    @Test
    func malformedFeaturesReportIssues() async throws {
        let result = try GeoJsonParser.parse(jsonString: malformedJson)
        let collection = try #require(result.object as? FeatureCollection)

        // The two-point ring is accepted by the lenient parser, while the
        // non-numeric point coordinate is dropped.
        #expect(collection.features.count == 2)
        #expect(result.issues.count == 2)

        let ringIssue = try #require(result.issues.first {
            $0.path == "/features/0/geometry/coordinates/0"
        })
        #expect(ringIssue.message.contains("four"))

        let coordinateIssue = try #require(result.issues.first {
            $0.path == "/features/1/geometry/coordinates/0"
        })
        #expect(coordinateIssue.message.contains("number"))
    }

    // Strict mode throws the first issue with its JSON Pointer path.
    @Test
    func strictModeThrowsFirstIssue() async throws {
        do {
            _ = try GeoJsonParser.parse(jsonString: malformedJson, mode: .strict)
            Issue.record("Expected GeoJsonParsingError")
        }
        catch let error as GeoJsonParsingError {
            #expect(error.issue.path == "/features/0/geometry/coordinates/0")
        }
    }

    // A missing geometry member is reported; an explicit null is not.
    @Test
    func missingGeometryReportsIssue() async throws {
        let json = #"""
        {"type":"FeatureCollection","features":[
          {"type":"Feature","properties":{"a":1}}
        ]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.count == 1)
        #expect(result.issues[0].path == "/features/0/geometry")
    }

    // Invalid nested positions report the exact path.
    @Test
    func nestedInvalidPositionReportsPath() async throws {
        let json = #"""
        {"type":"LineString","coordinates":[[0,0],[1,"x"]]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.count == 1)
        #expect(result.issues[0].path == "/coordinates/1/1")
    }

    // Invalid bounding boxes are reported without failing the whole parse.
    @Test
    func invalidBoundingBoxReportsIssue() async throws {
        let json = #"""
        {"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{},"bbox":[0,0,1]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.count == 1)
        #expect(result.issues[0].path == "/bbox")
        #expect(result.object != nil)
    }

    // The data and string overloads agree.
    @Test
    func dataOverload() async throws {
        let data = try #require(validJson.data(using: .utf8))
        let result = try GeoJsonParser.parse(jsonData: data)

        #expect(result.issues.isEmpty)
        #expect(result.object is FeatureCollection)
    }

    // A FeatureCollection only accepts Features, not bare geometries.
    @Test
    func featureCollectionRejectsGeometryElement() async throws {
        let json = #"""
        {"type":"FeatureCollection","features":[{"type":"Point","coordinates":[1,2]}]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.count == 1)
        #expect(result.issues[0].path == "/features/0")
        #expect(result.issues[0].message.contains("Feature"))
    }

    // A GeometryCollection only accepts geometries, not Features.
    @Test
    func geometryCollectionRejectsFeatureElement() async throws {
        let json = #"""
        {"type":"GeometryCollection","geometries":[{"type":"Feature","geometry":null,"properties":{}}]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.count == 1)
        #expect(result.issues[0].path == "/geometries/0")
        #expect(result.issues[0].message.contains("geometry"))
    }

    // MARK: - Typed parsing

    // Typed parsing returns the requested concrete type.
    @Test
    func typedParseReturnsConcreteType() async throws {
        let (collection, issues) = try GeoJsonParser.parse(
            jsonString: validJson,
            as: FeatureCollection.self)

        #expect(issues.isEmpty)
        let typed = try #require(collection)
        #expect(typed.features.count == 2)
    }

    // A type mismatch is reported and returns nil instead of the object.
    @Test
    func typedParseTypeMismatch() async throws {
        let pointJson = #"{"type":"Point","coordinates":[1,2]}"#
        let (collection, issues) = try GeoJsonParser.parse(
            jsonString: pointJson,
            as: FeatureCollection.self)

        #expect(collection == nil)
        #expect(issues.count == 1)
        #expect(issues[0].message.contains("FeatureCollection"))
    }

    // Strict typed parsing throws on a type mismatch.
    @Test
    func typedParseStrictTypeMismatchThrows() async throws {
        let pointJson = #"{"type":"Point","coordinates":[1,2]}"#

        #expect(throws: GeoJsonParsingError.self) {
            try GeoJsonParser.parse(
                jsonString: pointJson,
                as: FeatureCollection.self,
                mode: .strict)
        }
    }

    // The FeatureCollection convenience normalizes any GeoJSON object.
    @Test
    func featureCollectionConvenienceNormalizes() async throws {
        let pointJson = #"{"type":"Point","coordinates":[1,2]}"#
        var issues: [GeoJsonParseIssue] = []
        let collection = try #require(FeatureCollection(
            jsonString: pointJson,
            issues: &issues))

        #expect(issues.isEmpty)
        #expect(collection.features.count == 1)
        #expect(collection.features[0].geometry is Point)
    }

    // The FeatureCollection convenience reports malformed elements.
    @Test
    func featureCollectionConvenienceReportsIssues() async throws {
        var issues: [GeoJsonParseIssue] = []
        _ = FeatureCollection(jsonString: malformedJson, issues: &issues)

        #expect(issues.count == 2)
        #expect(issues[0].path == "/features/0/geometry/coordinates/0")
    }

    // Unreadable JSON throws in both modes.
    @Test
    func invalidJsonThrows() async throws {
        #expect(throws: GeoJsonParsingError.self) {
            try GeoJsonParser.parse(jsonData: Data([0x00, 0x01]))
        }
    }

    // Strict mode accepts a clean document.
    @Test
    func strictModeAcceptsValidDocument() async throws {
        let result = try GeoJsonParser.parse(jsonString: validJson, mode: .strict)

        #expect(result.issues.isEmpty)
        #expect(result.object is FeatureCollection)
    }

}
