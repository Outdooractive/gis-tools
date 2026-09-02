import Foundation
@testable import GISTools
import Testing

/// Tests for the element-wise JSON coercion that replaced whole-dictionary
/// conditional casts (`json as? [String: Sendable]`).
///
/// The whole-dictionary cast funnels into the standard library's
/// `_dictionaryUpCast` on Darwin, which can trap (uncatchable
/// `EXC_BREAKPOINT`) for certain `JSONSerialization`-bridged layouts instead
/// of returning `nil`. The coercion must degrade gracefully for every value
/// shape instead, and must preserve number/boolean/string runtime types so
/// downstream `as? Int`/`as? Double`/`as? Bool` reads keep working.
struct JsonCoercionTests {

    // MARK: - Geometry parsing from JSON strings (JSONSerialization-bridged)

    // Validates that a Point parses from a JSON string (bridged NSNumber coordinates).
    @Test
    func parsePointFromString() async throws {
        let point = try #require(Point(jsonString: #"{"type":"Point","coordinates":[1.0,2.0]}"#))

        #expect(point.coordinate.longitude == 1.0)
        #expect(point.coordinate.latitude == 2.0)
    }

    // Validates that a Point with integer-valued (JSON integer) coordinates parses.
    @Test
    func parsePointWithIntegerCoordinates() async throws {
        let point = try #require(Point(jsonString: #"{"type":"Point","coordinates":[1,2]}"#))

        #expect(point.coordinate.longitude == 1.0)
        #expect(point.coordinate.latitude == 2.0)
    }

    // Validates that a Point with a null altitude placeholder and an `m` value parses.
    @Test
    func parsePointWithNullAltitudeAndM() async throws {
        let point = try #require(Point(jsonString: #"{"type":"Point","coordinates":[1.0,2.0,null,5.0]}"#))

        #expect(point.coordinate.altitude == nil)
        #expect(point.coordinate.m == 5.0)
    }

    // Validates that all geometry types parse from a single FeatureCollection.
    @Test
    func parseAllGeometryTypes() async throws {
        let jsonString = """
        {"type":"FeatureCollection","features":[
        {"type":"Feature","properties":{},"geometry":{"type":"Point","coordinates":[1.0,2.0]}},
        {"type":"Feature","properties":{},"geometry":{"type":"MultiPoint","coordinates":[[1.0,2.0],[3.0,4.0]]}},
        {"type":"Feature","properties":{},"geometry":{"type":"LineString","coordinates":[[1.0,2.0],[3.0,4.0]]}},
        {"type":"Feature","properties":{},"geometry":{"type":"MultiLineString","coordinates":[[[1.0,2.0],[3.0,4.0]]]}},
        {"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[0.0,0.0],[1.0,0.0],[1.0,1.0],[0.0,0.0]]]}},
        {"type":"Feature","properties":{},"geometry":{"type":"MultiPolygon","coordinates":[[[[0.0,0.0],[1.0,0.0],[1.0,1.0],[0.0,0.0]]]]}},
        {"type":"Feature","properties":{},"geometry":{"type":"GeometryCollection","geometries":[{"type":"Point","coordinates":[1.0,2.0]}]}}
        ]}
        """
        let featureCollection = try #require(FeatureCollection(jsonString: jsonString))

        #expect(featureCollection.features.count == 7)
        #expect(featureCollection.features[0].geometry.type == .point)
        #expect(featureCollection.features[1].geometry.type == .multiPoint)
        #expect(featureCollection.features[2].geometry.type == .lineString)
        #expect(featureCollection.features[3].geometry.type == .multiLineString)
        #expect(featureCollection.features[4].geometry.type == .polygon)
        #expect(featureCollection.features[5].geometry.type == .multiPolygon)
        #expect(featureCollection.features[6].geometry.type == .geometryCollection)
    }

    // MARK: - Bridged dictionary parsing (the crashing shapes)

    // Validates that a Feature with inhomogeneous nested property values parses,
    // mimicking `JSONSerialization` output on Darwin.
    @Test
    func parseFeatureWithInhomogeneousProperties() async throws {
        let json: NSDictionary = [
            "type": "Feature",
            "id": NSNumber(value: 5),
            "properties": NSDictionary(dictionary: [
                "n": NSNumber(value: 42),
                "f": NSNumber(value: 3.14),
                "b": true,
                "null": NSNull(),
                "s": "x",
                "nested": ["a": [1, 2], "b": true, "c": NSNull()],
                "inhomogeneous": [1, "two", 3.0],
            ]),
            "geometry": NSDictionary(dictionary: [
                "type": "Point",
                "coordinates": [NSNumber(value: 1.5), NSNumber(value: 2.5)],
            ]),
        ]
        let feature = try #require(Feature(json: json))

        #expect(feature.id == .int(5))
        #expect(feature.properties["n"] as? Int == 42)
        #expect(feature.properties["f"] as? Double == 3.14)
        #expect(feature.properties["b"] as? Bool == true)
        #expect(feature.geometry.type == .point)
    }

    // Validates that NSNull property values degrade gracefully instead of crashing.
    @Test
    func parseFeatureWithNSNullProperties() async throws {
        let json: NSDictionary = [
            "type": "Feature",
            "properties": ["a": NSNull(), "b": NSNumber(value: 1)],
            "geometry": ["type": "Point", "coordinates": [1.0, 2.0]],
        ]
        let feature = try #require(Feature(json: json))

        #expect(feature.properties["a"] is NSNull)
        #expect(feature.properties["b"] as? Int == 1)
    }

    // Validates that a dictionary with non-string keys degrades to `nil`.
    @Test
    func parseWithNonStringKeysReturnsNil() {
        let json: NSDictionary = [
            "type": "Point",
            5: "non-string key",
            "coordinates": [1.0, 2.0],
        ]

        #expect(Point(json: json) == nil)
    }

    // Validates that a dictionary containing a non-JSON value degrades to `nil`.
    @Test
    func parseWithNonJsonValueReturnsNil() {
        let json: NSDictionary = [
            "type": "Feature",
            "geometry": ["type": "Point", "coordinates": [1.0, 2.0]],
            "properties": ["bad": NSObject()],
        ]

        #expect(Feature(json: json) == nil)
    }

    // MARK: - Property type preservation

    // Validates that integer-valued JSON properties preserve `as? Int` reads.
    @Test
    func propertyIntRead() async throws {
        let feature = try #require(Feature(jsonString: #"{"type":"Feature","properties":{"id":5,"count":0},"geometry":{"type":"Point","coordinates":[1.0,2.0]}}"#))

        #expect(feature.properties["id"] as? Int == 5)
        #expect(feature["id"] == 5)
        #expect(feature.properties["count"] as? Int == 0)
    }

    // Validates that float JSON properties preserve `as? Double` reads.
    @Test
    func propertyDoubleRead() async throws {
        let feature = try #require(Feature(jsonString: #"{"type":"Feature","properties":{"f":3.14},"geometry":{"type":"Point","coordinates":[1.0,2.0]}}"#))

        #expect(feature.properties["f"] as? Double == 3.14)
    }

    // Validates that boolean JSON properties preserve `as? Bool` reads,
    // and that `__NSCFBoolean`-style booleans don't read as `Int`.
    @Test
    func propertyBoolRead() async throws {
        let json: NSDictionary = [
            "type": "Feature",
            "properties": ["flag": true, "off": false],
            "geometry": ["type": "Point", "coordinates": [1.0, 2.0]],
        ]
        let feature = try #require(Feature(json: json))

        #expect(feature.properties["flag"] as? Bool == true)
        #expect(feature.properties["off"] as? Bool == false)
    }

    // Validates that nested foreign members survive parsing.
    @Test
    func foreignMemberPreservation() async throws {
        let json: NSDictionary = [
            "type": "Feature",
            "custom": ["deep": [1.0, 2.0, NSNull()]],
            "extra": "foreign",
            "geometry": ["type": "Point", "coordinates": [1.0, 2.0]],
        ]
        let feature = try #require(Feature(json: json))
        let nested: [String: Sendable]? = feature[foreignMember: "custom"]

        #expect(nested?["deep"] != nil)
    }

    // MARK: - BoundingBox parsing

    // Validates the flat GeoJSON bbox form (4 doubles).
    @Test
    func parseBoundingBoxFlat() async throws {
        let feature = try #require(Feature(jsonString: #"{"type":"Feature","bbox":[1.0,2.0,3.0,4.0],"geometry":{"type":"Point","coordinates":[2.0,3.0]}}"#))

        #expect(feature.boundingBox?.southWest == Coordinate3D(latitude: 2.0, longitude: 1.0))
        #expect(feature.boundingBox?.northEast == Coordinate3D(latitude: 4.0, longitude: 3.0))
    }

    // Validates the nested bbox form (2 coordinate arrays).
    @Test
    func parseBoundingBoxNested() async throws {
        let feature = try #require(Feature(jsonString: #"{"type":"Feature","bbox":[[1.0,2.0],[3.0,4.0]],"geometry":{"type":"Point","coordinates":[2.0,3.0]}}"#))

        #expect(feature.boundingBox?.southWest == Coordinate3D(latitude: 2.0, longitude: 1.0))
        #expect(feature.boundingBox?.northEast == Coordinate3D(latitude: 4.0, longitude: 3.0))
    }

    // MARK: - Malformed coordinates

    // Validates that malformed coordinate arrays return `nil` instead of crashing.
    @Test
    func malformedCoordinatesReturnNil() {
        #expect(Point(jsonString: #"{"type":"Point","coordinates":[1.0,"two"]}"#) == nil)
        #expect(Point(jsonString: #"{"type":"Point","coordinates":"not an array"}"#) == nil)
        #expect(Point(jsonString: #"{"type":"Point","coordinates":[1.0]}"#) == nil)
        #expect(Point(jsonString: #"{"type":"Point","coordinates":{}}"#) == nil)
        #expect(Point(jsonString: #"{"type":"Point"}"#) == nil)
    }

    // MARK: - Coercion helpers

    // Validates `JsonCoercion.dictionary` accepts and rejects the expected shapes.
    @Test
    func dictionaryCoercion() {
        #expect(JsonCoercion.dictionary(nil) == nil)
        #expect(JsonCoercion.dictionary("string") == nil)
        #expect(JsonCoercion.dictionary([1.0, 2.0]) == nil)

        let result = JsonCoercion.dictionary(["a": 1, "b": "x", "c": true, "d": NSNull(), "e": [1.0]])
        #expect(result?.count == 5)
        #expect(result?["a"] as? Int == 1)
        #expect(result?["b"] as? String == "x")
        #expect(result?["c"] as? Bool == true)
        #expect(result?["d"] is NSNull)
    }

    // Validates `JsonCoercion.coordinateArray` semantics.
    @Test
    func coordinateArrayCoercion() {
        #expect(JsonCoercion.coordinateArray(nil) == nil)
        #expect(JsonCoercion.coordinateArray([1.0, 2.0]) == [1.0, 2.0])
        #expect(JsonCoercion.coordinateArray([1, 2]) == [1.0, 2.0])
        #expect(JsonCoercion.coordinateArray([1.0, 2.0, NSNull()]) == [1.0, 2.0, nil])
        #expect(JsonCoercion.coordinateArray([1.0, "two"]) == nil)
        #expect(JsonCoercion.coordinateArray("x") == nil)
    }

    // Validates `JsonCoercion.array` semantics.
    @Test
    func arrayCoercion() {
        #expect(JsonCoercion.array(nil) == nil)
        #expect(JsonCoercion.array(["x"])?.count == 1)
        #expect(JsonCoercion.array([[1.0], [2.0]])?.count == 2)
        #expect(JsonCoercion.array("x") == nil)
    }

    // Validates `JsonCoercion.double` semantics.
    @Test
    func doubleCoercion() {
        #expect(JsonCoercion.double(nil) == nil)
        #expect(JsonCoercion.double(5) == 5.0)
        #expect(JsonCoercion.double(NSNumber(value: 2.5)) == 2.5)
        #expect(JsonCoercion.double(Float(2.5)) == 2.5)
        #expect(JsonCoercion.double("x") == nil)
        #expect(JsonCoercion.double(true) == nil)
    }

}