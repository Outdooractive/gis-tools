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

    /// A clean document has no issues and preserves unlocated features.
    @Test
    func validDocumentHasNoIssues() throws {
        let result = try GeoJsonParser.parse(jsonString: validJson)
        let collection = try #require(result.object as? FeatureCollection)

        #expect(result.issues.isEmpty)
        #expect(collection.features.count == 2)
        #expect(collection.features[0].geometry == nil)
        #expect(collection.features[1].geometry != nil)
    }

    /// Lenient parsing returns the object and reports every malformed element.
    @Test
    func malformedFeaturesReportIssues() throws {
        let result = try GeoJsonParser.parse(jsonString: malformedJson)
        let collection = try #require(result.object as? FeatureCollection)

        // Both the short ring and the non-numeric point coordinate are dropped.
        #expect(collection.features.count == 1)
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

    /// Strict mode throws the first issue with its JSON Pointer path.
    @Test
    func strictModeThrowsFirstIssue() throws {
        do {
            _ = try GeoJsonParser.parse(jsonString: malformedJson, mode: .strict)
            Issue.record("Expected GeoJsonParsingError")
        }
        catch let error as GeoJsonParsingError {
            #expect(error.issue.path == "/features/0/geometry/coordinates/0")
        }
    }

    /// A missing geometry member is reported; an explicit null is not.
    @Test
    func missingGeometryReportsIssue() throws {
        let json = #"""
        {"type":"FeatureCollection","features":[
          {"type":"Feature","properties":{"a":1}}
        ]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.count == 1)
        #expect(result.issues[0].path == "/features/0/geometry")
    }

    /// Invalid nested positions report the exact path.
    @Test
    func nestedInvalidPositionReportsPath() throws {
        let json = #"""
        {"type":"LineString","coordinates":[[0,0],[1,"x"]]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.count == 1)
        #expect(result.issues[0].path == "/coordinates/1/1")
    }

    /// Invalid bounding boxes are reported without failing the whole parse.
    @Test
    func invalidBoundingBoxReportsIssue() throws {
        let json = #"""
        {"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{},"bbox":[0,0,1]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.count == 1)
        #expect(result.issues[0].path == "/bbox")
        #expect(result.object != nil)
    }

    /// The data and string overloads agree.
    @Test
    func dataOverload() throws {
        let data = try #require(validJson.data(using: .utf8))
        let result = try GeoJsonParser.parse(jsonData: data)

        #expect(result.issues.isEmpty)
        #expect(result.object is FeatureCollection)
    }

    /// A FeatureCollection only accepts Features, not bare geometries.
    @Test
    func featureCollectionRejectsGeometryElement() throws {
        let json = #"""
        {"type":"FeatureCollection","features":[{"type":"Point","coordinates":[1,2]}]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.count == 1)
        #expect(result.issues[0].path == "/features/0")
        #expect(result.issues[0].message.contains("Feature"))
    }

    /// A GeometryCollection only accepts geometries, not Features.
    @Test
    func geometryCollectionRejectsFeatureElement() throws {
        let json = #"""
        {"type":"GeometryCollection","geometries":[{"type":"Feature","geometry":null,"properties":{}}]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.count == 1)
        #expect(result.issues[0].path == "/geometries/0")
        #expect(result.issues[0].message.contains("geometry"))
    }

    // MARK: - Typed parsing

    /// Typed parsing returns the requested concrete type.
    @Test
    func typedParseReturnsConcreteType() throws {
        let (collection, issues) = try GeoJsonParser.parse(
            jsonString: validJson,
            as: FeatureCollection.self)

        #expect(issues.isEmpty)
        let typed = try #require(collection)
        #expect(typed.features.count == 2)
    }

    /// A type mismatch is reported and returns nil instead of the object.
    @Test
    func typedParseTypeMismatch() throws {
        let pointJson = #"{"type":"Point","coordinates":[1,2]}"#
        let (collection, issues) = try GeoJsonParser.parse(
            jsonString: pointJson,
            as: FeatureCollection.self)

        #expect(collection == nil)
        #expect(issues.count == 1)
        #expect(issues[0].message.contains("FeatureCollection"))
    }

    /// Strict typed parsing throws on a type mismatch.
    @Test
    func typedParseStrictTypeMismatchThrows() throws {
        let pointJson = #"{"type":"Point","coordinates":[1,2]}"#

        #expect(throws: GeoJsonParsingError.self) {
            try GeoJsonParser.parse(
                jsonString: pointJson,
                as: FeatureCollection.self,
                mode: .strict)
        }
    }

    /// The FeatureCollection convenience normalizes any GeoJSON object.
    @Test
    func featureCollectionConvenienceNormalizes() throws {
        let pointJson = #"{"type":"Point","coordinates":[1,2]}"#
        var issues: [GeoJsonParseIssue] = []
        let collection = try #require(FeatureCollection(
            jsonString: pointJson,
            issues: &issues))

        #expect(issues.isEmpty)
        #expect(collection.features.count == 1)
        #expect(collection.features[0].geometry is Point)
    }

    /// The FeatureCollection convenience reports malformed elements.
    @Test
    func featureCollectionConvenienceReportsIssues() {
        var issues: [GeoJsonParseIssue] = []
        _ = FeatureCollection(jsonString: malformedJson, issues: &issues)

        #expect(issues.count == 2)
        #expect(issues[0].path == "/features/0/geometry/coordinates/0")
    }

    /// Unreadable JSON throws in both modes.
    @Test
    func invalidJsonThrows() throws {
        #expect(throws: GeoJsonParsingError.self) {
            try GeoJsonParser.parse(jsonData: Data([0x00, 0x01]))
        }
    }

    /// Strict mode accepts a clean document.
    @Test
    func strictModeAcceptsValidDocument() throws {
        let result = try GeoJsonParser.parse(jsonString: validJson, mode: .strict)

        #expect(result.issues.isEmpty)
        #expect(result.object is FeatureCollection)
    }

}

// MARK: - GeoJSON audit regressions

extension GeoJsonParserTests {

    /// The object-based typed parser and collection convenience initializers agree.
    @Test
    func parserObjectAndCollectionOverloads() throws {
        let json: [String: Sendable] = [
            "type": "Point",
            "coordinates": [1, 2],
        ]
        let (point, issues) = try GeoJsonParser.parse(
            json: json,
            as: Point.self)
        #expect(point?.coordinate == Coordinate3D(latitude: 2.0, longitude: 1.0))
        #expect(issues.isEmpty)

        var dataIssues: [GeoJsonParseIssue] = []
        let fromData = try #require(FeatureCollection(
            jsonData: Data(#"{"type":"Point","coordinates":[1,2]}"#.utf8),
            issues: &dataIssues))
        #expect(fromData.features.count == 1)
        #expect(dataIssues.isEmpty)

        var objectIssues: [GeoJsonParseIssue] = []
        let fromObject = try #require(FeatureCollection(
            json: json,
            issues: &objectIssues))
        #expect(fromObject.features.count == 1)
        #expect(objectIssues.isEmpty)
    }

    /// The required properties member is reported when absent.
    @Test
    func missingPropertiesIsReported() throws {
        let json = #"{"type":"Feature","geometry":null}"#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.contains { $0.path == "/properties" })
    }

    /// A missing geometry is reported, but validation continues with the other members.
    @Test
    func missingGeometryDoesNotStopValidation() throws {
        let json = #"""
        {"type":"Feature","properties":[],"bbox":[0,0,1]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)

        #expect(result.issues.contains { $0.path == "/geometry" })
        #expect(result.issues.contains { $0.path == "/properties" })
        #expect(result.issues.contains { $0.path == "/bbox" })
    }

    /// GeoJSON linear rings must be explicitly closed.
    @Test
    func unclosedRingIsReported() throws {
        let json = #"""
        {"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1]]]}
        """#
        let result = try GeoJsonParser.parse(jsonString: json)
        let issue = try #require(result.issues.first {
            $0.path == "/coordinates/0"
        })

        #expect(issue.message.contains("closed"))
    }

    /// Empty multi-geometry coordinate arrays are reported as malformed.
    @Test
    func emptyMultiGeometriesAreReported() throws {
        let lineString = try GeoJsonParser.parse(
            jsonString: #"{"type":"MultiLineString","coordinates":[]}"#)
        let polygon = try GeoJsonParser.parse(
            jsonString: #"{"type":"MultiPolygon","coordinates":[]}"#)

        #expect(lineString.issues.contains { $0.path == "/coordinates" })
        #expect(polygon.issues.contains { $0.path == "/coordinates" })
    }

    /// Foreign-member values on collections must be JSON-compatible.
    @Test
    func collectionForeignMemberMustBeJSONCompatible() throws {
        let json: [String: Sendable] = [
            "type": "FeatureCollection",
            "features": [Sendable](),
            "bad": Data([0x01]),
        ]
        let result = try GeoJsonParser.parse(json: json)

        #expect(result.issues.contains { $0.path == "/bad" })
    }

    /// Foreign-member values on geometries must be JSON-compatible.
    @Test
    func geometryForeignMemberMustBeJSONCompatible() throws {
        let json: [String: Sendable] = [
            "type": "Point",
            "coordinates": [1, 2],
            "bad": Data([0x01]),
        ]
        let result = try GeoJsonParser.parse(json: json)

        #expect(result.issues.contains { $0.path == "/bad" })
    }

    @Test
    func parserOverloadsAgree() throws {
        let data = try #require(#"{"type":"Point","coordinates":[1,2]}"#.data(using: .utf8))

        let fromData = try GeoJsonParser.parse(jsonData: data)
        let fromString = try GeoJsonParser.parse(
            jsonString: #"{"type":"Point","coordinates":[1,2]}"#)
        let fromObject = try GeoJsonParser.parse(json: ["type": "Point", "coordinates": [1, 2]] as [String: Sendable])

        #expect(fromData.object?.type == .point)
        #expect(fromString.object?.type == .point)
        #expect(fromObject.object?.type == .point)

        let typedData = try GeoJsonParser.parse(jsonData: data, as: Point.self)
        let typedString = try GeoJsonParser.parse(
            jsonString: #"{"type":"Point","coordinates":[1,2]}"#,
            as: Point.self)
        #expect(typedData.object != nil)
        #expect(typedString.object != nil)
    }

    @Test
    func parserIssueDescriptionEscapesJSONPointer() throws {
        let json: [String: Sendable] = [
            "type": "Feature",
            "geometry": ["type": "Point", "coordinates": [1, 2]] as [String: Sendable],
            "properties": [String: Sendable](),
            "a/b~c": Data([0x01]),
        ]
        let result = try GeoJsonParser.parse(json: json)
        let issue = try #require(result.issues.first {
            $0.path == "/a~1b~0c"
        })

        #expect(issue.description.contains("/a~1b~0c"))
        #expect(GeoJsonParsingError(issue: issue).errorDescription == issue.description)
    }

    @Test
    func nonObjectJSONAndMissingCoordinateContainers() throws {
        let nonObject = try GeoJsonParser.parse(json: 42)
        #expect(nonObject.object == nil)
        #expect(nonObject.issues.first?.message == "expected a JSON object")
        #expect(throws: GeoJsonParsingError.self) {
            try GeoJsonParser.parse(json: 42, mode: .strict)
        }

        let malformed: [(json: String, path: String)] = [
            (#"{"type":"MultiLineString"}"#, "/coordinates"),
            (#"{"type":"Polygon"}"#, "/coordinates"),
            (#"{"type":"MultiPolygon"}"#, "/coordinates"),
            (#"{"type":"GeometryCollection"}"#, "/geometries"),
        ]
        for item in malformed {
            let result = try GeoJsonParser.parse(jsonString: item.json)
            #expect(result.object == nil)
            #expect(result.issues.contains { $0.path == item.path }, "\(item.json)")
        }
    }

    @Test
    func invalidBoundingBoxAndFeatureCollectionIssues() throws {
        let invalidBox = #"{"type":"Feature","geometry":{"type":"Point","coordinates":[1,2]},"properties":{},"bbox":[0,0,1]}"#
        let result = try GeoJsonParser.parse(jsonString: invalidBox)
        #expect(result.issues.contains { $0.path == "/bbox" && $0.message.contains("four or six") })

        var issues: [GeoJsonParseIssue] = []
        let collection = FeatureCollection(
            jsonString: #"{"type":"Point","coordinates":[1,2]}"#,
            issues: &issues)
        #expect(collection?.features.count == 1)
        #expect(issues.isEmpty)
    }

}
