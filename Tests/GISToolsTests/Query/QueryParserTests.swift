@testable import GISTools
import Testing

struct QueryParserTests {

    private static let properties: [String: Sendable] = [
        "foo": [
            "bar": 1,
            "baz": UInt8(10),
        ] as [String: Sendable],
        "some": [
            "a",
            "b",
        ],
        "value": 1,
        "string": "Some name",
    ]

    private func result(for pipeline: [QueryParser.Expression]) -> Bool {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: Self.properties)
        return QueryParser(pipeline: pipeline).evaluate(on: feature)
    }

    private func pipeline(for query: String) -> [QueryParser.Expression] {
        QueryParser(string: query)?.pipeline ?? []
    }

    /// Tests value access expressions: `.key`, `.key.subkey`, array index, and missing keys.
    @Test
    func values() {
        #expect(result(for: [.value([.key("foo")])]))
        #expect(result(for: [.value([.key("foo"), .key("bar")])]))
        #expect(result(for: [.value([.key("foo"), .key("x")])]) == false)
        #expect(result(for: [.value([.key("foo.bar")])]) == false)
        #expect(result(for: [.value([.key("foo"), .index(0)])]) == false)
        #expect(result(for: [.value([.key("some"), .index(0)])]))
    }

    /// Tests that `evaluate()` returns false when the pipeline is nil.
    @Test
    func nilPipelineReturnsFalse() {
        let parser = QueryParser(pipeline: [])
        #expect(parser.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: [:])) == false)
    }

    /// Tests that a pipeline with more than one stack item at the end returns false.
    @Test
    func unbalancedStackReturnsFalse() {
        let pipeline: [QueryParser.Expression] = [
            .literal("a"), .literal("b"),
        ]
        #expect(result(for: pipeline) == false)
    }

    /// Tests parsing the `near(lat, lon, tolerance)` expression.
    @Test
    func near() {
        #expect(pipeline(for: "near(10.0, 20.0, 1000)") == [
            .near(Coordinate3D(latitude: 10.0, longitude: 20.0), 1000.0),
        ])
    }

    /// Tests `near()` evaluation with a feature at various distances.
    @Test
    func nearEvaluation() {
        let origin = Coordinate3D(latitude: 10.0, longitude: 20.0)
        let closeBy = Coordinate3D(latitude: 10.001, longitude: 20.001)
        let farAway = Coordinate3D(latitude: 30.0, longitude: 40.0)

        let parser = QueryParser(pipeline: [
            .near(origin, 200.0),
        ])

        #expect(parser.evaluate(on: Feature(Point(closeBy), properties: [:])))
        #expect(parser.evaluate(on: Feature(Point(farAway), properties: [:])) == false)
    }

    /// Tests that `near()` returns false when the feature has no geometry.
    @Test
    func nearWithoutGeometryReturnsFalse() {
        let parser = QueryParser(pipeline: [
            .near(Coordinate3D(latitude: 10.0, longitude: 20.0), 100.0),
        ])
        // A Point at (0,0) is too far from (10,20) with 100m tolerance.
        #expect(parser.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: [:])) == false)
    }

    /// Tests parsing the `within(minLon, minLat, maxLon, maxLat)` expression.
    @Test
    func withinParsing() {
        #expect(pipeline(for: "within(11.5, 3.8, 11.6, 3.9)") == [
            .within(BoundingBox(
                southWest: Coordinate3D(latitude: 3.8, longitude: 11.5),
                northEast: Coordinate3D(latitude: 3.9, longitude: 11.6))),
        ])
    }

    /// Tests the `within()` bounding box predicate at various positions.
    @Test
    func withinEvaluation() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 3.8, longitude: 11.5),
            northEast: Coordinate3D(latitude: 3.9, longitude: 11.6))
        let inside = Coordinate3D(latitude: 3.85, longitude: 11.55)
        let atCorner = Coordinate3D(latitude: 3.8, longitude: 11.5)
        let outside = Coordinate3D(latitude: 5.0, longitude: 10.0)

        let parser = QueryParser(pipeline: [.within(bbox)])
        #expect(parser.evaluate(on: Feature(Point(inside), properties: [:])))
        #expect(parser.evaluate(on: Feature(Point(atCorner), properties: [:])))
        #expect(parser.evaluate(on: Feature(Point(outside), properties: [:])) == false)
    }

    /// Tests `within()` with a polygon feature (geometry containment).
    @Test
    func withinPolygonGeometry() throws {
        let queryBox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        // A polygon fully inside the query box → within is true.
        let innerPoly = try #require(Polygon([[
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 7.0, longitude: 3.0),
            Coordinate3D(latitude: 7.0, longitude: 7.0),
            Coordinate3D(latitude: 3.0, longitude: 7.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ]]))
        let parser = QueryParser(pipeline: [.within(queryBox)])
        #expect(parser.evaluate(on: Feature(innerPoly, properties: [:])))

        // A polygon crossing the query box boundary → within is false.
        let crossingPoly = try #require(Polygon([[
            Coordinate3D(latitude: -5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: -5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: 5.0),
            Coordinate3D(latitude: -5.0, longitude: -5.0),
        ]]))
        #expect(parser.evaluate(on: Feature(crossingPoly, properties: [:])) == false)
    }

    /// Tests the `intersects()` bounding box predicate.
    @Test
    func intersectsEvaluation() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 3.8, longitude: 11.5),
            northEast: Coordinate3D(latitude: 3.9, longitude: 11.6))
        let inside = Coordinate3D(latitude: 3.85, longitude: 11.55)
        let outside = Coordinate3D(latitude: 5.0, longitude: 10.0)

        let parser = QueryParser(pipeline: [.intersects(bbox)])
        #expect(parser.evaluate(on: Feature(Point(inside), properties: [:])))
        #expect(parser.evaluate(on: Feature(Point(outside), properties: [:])) == false)
    }

    /// Tests parsing `intersects()` function.
    @Test
    func intersectsParsing() {
        #expect(pipeline(for: "intersects(11.5, 3.8, 11.6, 3.9)") == [
            .intersects(BoundingBox(
                southWest: Coordinate3D(latitude: 3.8, longitude: 11.5),
                northEast: Coordinate3D(latitude: 3.9, longitude: 11.6))),
        ])
    }

    /// Tests comparison operators: `==`, `!=`, `>`, `>=`, `<`, `<=`, and `=~` (regex).
    @Test
    func comparisons() {
        #expect(result(for: [.value([.key("value")]), .literal("bar"), .comparison(.equals)]) == false)
        #expect(result(for: [.value([.key("value")]), .literal(1), .comparison(.equals)]))
        #expect(result(for: [.value([.key("value")]), .literal(1.0), .comparison(.equals)]))
        #expect(result(for: [.value([.key("value")]), .literal(1), .comparison(.notEquals)]) == false)
        #expect(result(for: [.value([.key("value")]), .literal(1), .comparison(.greaterThan)]) == false)
        #expect(result(for: [.value([.key("value")]), .literal(1), .comparison(.greaterThanOrEqual)]))
        #expect(result(for: [.value([.key("value")]), .literal(0.5), .comparison(.greaterThanOrEqual)]))
        #expect(result(for: [.value([.key("value")]), .literal(1), .comparison(.lessThan)]) == false)
        #expect(result(for: [.value([.key("value")]), .literal(1), .comparison(.lessThanOrEqual)]))
        #expect(result(for: [.value([.key("value")]), .literal(1.5), .comparison(.lessThanOrEqual)]))
        #expect(result(for: [.value([.key("foo"), .key("baz")]), .literal(10), .comparison(.equals)]))
        #expect(result(for: [.value([.key("x")]), .literal(1), .comparison(.equals)]) == false)
        #expect(result(for: [.value([.key("string")]), .literal("name$"), .comparison(.regex)]))
        #expect(result(for: [.value([.key("string")]), .literal("/[Ss]ome/"), .comparison(.regex)]))
        #expect(result(for: [.value([.key("string")]), .literal("^some"), .comparison(.regex)]) == false)
        #expect(result(for: [.value([.key("string")]), .literal("/^some/i"), .comparison(.regex)]))
    }

    /// Tests cross-type comparisons (int vs double, uint vs int, etc.)
    @Test
    func crossTypeComparisons() {
        // Int(10) == UInt8(10) — different types but same value → true
        #expect(result(for: [.value([.key("foo"), .key("baz")]), .literal(10), .comparison(.equals)]))
        // UInt8(10) != Int(1) → true
        #expect(result(for: [.value([.key("foo"), .key("baz")]), .literal(1), .comparison(.notEquals)]))
        // UInt8(10) > 5 → true
        #expect(result(for: [.value([.key("foo"), .key("baz")]), .literal(5), .comparison(.greaterThan)]))
        // UInt8(10) < 20 → true
        #expect(result(for: [.value([.key("foo"), .key("baz")]), .literal(20), .comparison(.lessThan)]))
    }

    /// Tests string comparison operators: `=*` (contains), `=^` (startsWith), `=$` (endsWith).
    @Test
    func stringComparisons() {
        #expect(result(for: [.value([.key("string")]), .literal("name"), .comparison(.contains)]))
        #expect(result(for: [.value([.key("string")]), .literal("Name"), .comparison(.contains)]))
        #expect(result(for: [.value([.key("string")]), .literal("xyz"), .comparison(.contains)]) == false)

        #expect(result(for: [.value([.key("string")]), .literal("Some"), .comparison(.startsWith)]))
        #expect(result(for: [.value([.key("string")]), .literal("some"), .comparison(.startsWith)]))
        #expect(result(for: [.value([.key("string")]), .literal("name"), .comparison(.startsWith)]) == false)

        #expect(result(for: [.value([.key("string")]), .literal("name"), .comparison(.endsWith)]))
        #expect(result(for: [.value([.key("string")]), .literal("Name"), .comparison(.endsWith)]))
        #expect(result(for: [.value([.key("string")]), .literal("Some"), .comparison(.endsWith)]) == false)
    }

    /// Tests parsing of string comparison operators: `=*`, `=^`, `=$`.
    @Test
    func stringComparisonQueries() {
        #expect(pipeline(for: ".string =* \"name\"") == [.value([.key("string")]), .literal("name"), .comparison(.contains)])
        #expect(pipeline(for: ".string =^ \"Some\"") == [.value([.key("string")]), .literal("Some"), .comparison(.startsWith)])
        #expect(pipeline(for: ".string =$ \"name\"") == [.value([.key("string")]), .literal("name"), .comparison(.endsWith)])
    }

    /// Tests `in` evaluation with comma-containing string values (quoted).
    @Test
    func inOperatorWithCommas() throws {
        let props: [String: Sendable] = ["tags": "primary,a"]

        let p1 = QueryParser(pipeline: [
            .value([.key("tags")]), .literalSet(["primary,a", "secondary"]), .comparison(.in)])
        #expect(p1.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: props)))

        let p2 = QueryParser(pipeline: [
            .value([.key("tags")]), .literalSet(["primary", "secondary, x"]), .comparison(.in)])
        #expect(p2.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: props)) == false)
    }

    /// Tests the `in` set-membership operator.
    @Test
    func inOperator() {
        #expect(result(for: [.value([.key("value")]), .literalSet([1, 2]), .comparison(.in)]))
        #expect(result(for: [.value([.key("value")]), .literalSet([2, 3]), .comparison(.in)]) == false)

        let stringProps: [String: Sendable] = ["class": "primary"]
        let p1 = QueryParser(pipeline: [
            .value([.key("class")]), .literalSet(["primary", "secondary"]), .comparison(.in)])
        #expect(p1.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: stringProps)))

        let p2 = QueryParser(pipeline: [
            .value([.key("class")]), .literalSet(["tertiary"]), .comparison(.in)])
        #expect(p2.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: stringProps)) == false)
    }

    /// Tests parsing the `in` syntax with various value types.
    @Test
    func inParsing() throws {
        do {
            let parser = try #require(QueryParser(string: ".value in [1, 2]"))
            let pipeline = try #require(parser.pipeline)
            #expect(pipeline.count == 3)
            #expect(pipeline[0] == .value([.key("value")]))
            #expect(pipeline[2] == .comparison(.in))
        }

        // Single value in set
        let parser2 = try #require(QueryParser(string: ".class in [\"primary\"]"))
        #expect(parser2.pipeline?.count == 3)

        // Quoted strings in set
        let parser3 = try #require(QueryParser(string: ".class in ['a', 'b']"))
        #expect(parser3.pipeline?.count == 3)

        // Values with commas inside quotes (should not split on the comma)
        let parser4 = try #require(QueryParser(string: ".class in [\"primary,a\", \"secondary, b, c\"]"))
        let pipeline4 = try #require(parser4.pipeline)
        #expect(pipeline4.count == 3)
        if case let .literalSet(values) = pipeline4[1] {
            #expect(values.count == 2)
            #expect(values[0] as? String == "primary,a")
            #expect(values[1] as? String == "secondary, b, c")
        }
        else {
            Issue.record("Expected literalSet at index 1")
        }

        // Values with spaces inside quotes
        let parser5 = try #require(QueryParser(string: ".class in [\"value with spaces\", another]"))
        let pipeline5 = try #require(parser5.pipeline)
        if case let .literalSet(values) = pipeline5[1] {
            #expect(values.count == 2)
            #expect(values[0] as? String == "value with spaces")
            #expect(values[1] as? String == "another")
        }
        else {
            Issue.record("Expected literalSet at index 1")
        }

        // Single-quoted values with commas
        let parser6 = try #require(QueryParser(string: ".class in ['hello, world', 'foo']"))
        let pipeline6 = try #require(parser6.pipeline)
        if case let .literalSet(values) = pipeline6[1] {
            #expect(values.count == 2)
            #expect(values[0] as? String == "hello, world")
        }
        else {
            Issue.record("Expected literalSet at index 1")
        }
    }

    /// Tests the `exists` condition.
    @Test
    func existsCondition() {
        #expect(result(for: [.value([.key("foo")]), .condition(.exists)]))
        #expect(result(for: [.value([.key("value")]), .condition(.exists)]))
        #expect(result(for: [.value([.key("nonexistent")]), .condition(.exists)]) == false)
    }

    /// Tests `exists` combined with `not` — double negation.
    @Test
    func existsWithNot() {
        // .foo exists → true, not(.foo exists) → false
        #expect(result(for: [
            .value([.key("foo")]), .condition(.exists), .condition(.not),
        ]) == false)

        // .nonexistent exists → false, not(.nonexistent exists) → true
        #expect(result(for: [
            .value([.key("nonexistent")]), .condition(.exists), .condition(.not),
        ]))
    }

    /// Tests parsing the `exists` keyword.
    @Test
    func existsParsing() {
        #expect(pipeline(for: ".foo exists") == [
            .value([.key("foo")]),
            .condition(.exists),
        ])
    }

    /// Tests parsing `exists` combined with `and`.
    @Test
    func existsAndParsing() throws {
        #expect(pipeline(for: ".foo exists and .value exists") == [
            .value([.key("foo")]),
            .condition(.exists),
            .value([.key("value")]),
            .condition(.and),
            .condition(.exists),
        ])
    }

    /// Tests the `searchValues` (full-text search) evaluation.
    @Test
    func searchValuesEvaluation() {
        let props: [String: Sendable] = ["name": "Main Street", "type": "road"]

        // Match "Main" in a property value
        let p1 = QueryParser(pipeline: [.searchValues("Main")])
        #expect(p1.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: props)))

        // Case-insensitive
        let p2 = QueryParser(pipeline: [.searchValues("main")])
        #expect(p2.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: props)))

        // No match
        let p3 = QueryParser(pipeline: [.searchValues("nonexistent")])
        #expect(p3.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: props)) == false)

        // Empty search returns false
        let p4 = QueryParser(pipeline: [.searchValues("")])
        #expect(p4.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: props)) == false)
    }

    /// Tests that plain literal strings are converted to `searchValues`.
    @Test
    func literalToSearchValuesConversion() throws {
        let parser = try #require(QueryParser(string: "Main Street"))
        let pipeline = try #require(parser.pipeline)
        #expect(pipeline.count == 1)
        if case .searchValues(let text) = pipeline[0] {
            #expect(text == "Main Street")
        }
        else {
            Issue.record("Expected searchValues, got \(pipeline[0])")
        }

        // Multiple words join with spaces
        let parser2 = try #require(QueryParser(string: "hello   world"))
        let pipeline2 = try #require(parser2.pipeline)
        if case .searchValues(let text) = pipeline2[0] {
            #expect(text == "hello world")
        }
        else {
            Issue.record("Expected searchValues")
        }
    }

    /// Tests logical conditions: `and`, `or`, `not` in various combinations.
    @Test
    func conditions() {
        #expect(result(for: [
            .value([.key("foo"), .key("bar")]),
            .literal(1),
            .comparison(.equals),
            .value([.key("value")]),
            .literal(1),
            .comparison(.equals),
            .condition(.and),
        ]))
        #expect(result(for: [
            .value([.key("foo")]),
            .literal(1),
            .comparison(.equals),
            .value([.key("bar")]),
            .literal(2),
            .comparison(.equals),
            .condition(.or),
        ]) == false)
        #expect(result(for: [
            .value([.key("foo")]),
            .literal(1),
            .comparison(.equals),
            .value([.key("value")]),
            .literal(1),
            .comparison(.equals),
            .condition(.or),
        ]))
        #expect(result(for: [
            .value([.key("foo")]),
            .condition(.not),
        ]) == false)
        #expect(result(for: [
            .value([.key("foo")]),
            .value([.key("bar")]),
            .condition(.and),
            .condition(.not),
        ]))
        #expect(result(for: [
            .value([.key("foo")]),
            .value([.key("some")]),
            .condition(.and),
            .condition(.not),
        ]) == false)
        #expect(result(for: [
            .value([.key("foo")]),
            .value([.key("bar")]),
            .condition(.or),
            .condition(.not),
        ]) == false)
        #expect(result(for: [
            .value([.key("x")]),
            .value([.key("y")]),
            .condition(.or),
            .condition(.not),
        ]))
        #expect(result(for: [
            .value([.key("foo"), .key("bar")]),
            .condition(.not),
        ]) == false)
        #expect(result(for: [
            .value([.key("foo"), .key("x")]),
            .condition(.not),
        ]))
    }

    /// Tests double negation.
    @Test
    func doubleNegation() {
        // not(not(.foo)) → not(false) → true
        #expect(result(for: [
            .value([.key("foo")]),
            .condition(.not),
            .condition(.not),
        ]))

        // not(not(.nonexistent)) → not(true) → false
        #expect(result(for: [
            .value([.key("nonexistent")]),
            .condition(.not),
            .condition(.not),
        ]) == false)
    }

    /// Tests combining `in` with `and` and `or`.
    @Test
    func inCombinedWithConditions() {
        let props: [String: Sendable] = ["class": "primary", "value": 1]

        // .class in ["primary"] and .value == 1
        let p1 = QueryParser(pipeline: [
            .value([.key("class")]), .literalSet(["primary"]), .comparison(.in),
            .value([.key("value")]), .literal(1), .comparison(.equals),
            .condition(.and),
        ])
        #expect(p1.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: props)))

        // .class in ["secondary"] and .value == 1 → false
        let p2 = QueryParser(pipeline: [
            .value([.key("class")]), .literalSet(["secondary"]), .comparison(.in),
            .value([.key("value")]), .literal(1), .comparison(.equals),
            .condition(.and),
        ])
        #expect(p2.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: props)) == false)
    }

    /// Tests parsing dot-notation value expressions.
    @Test
    func valueQueries() {
        #expect(pipeline(for: ".foo") == [.value([.key("foo")])])
        #expect(pipeline(for: ".foo.bar") == [.value([.key("foo"), .key("bar")])])
        #expect(pipeline(for: ".foo.x") == [.value([.key("foo"), .key("x")])])
        #expect(pipeline(for: ".\"foo\".\"bar\"") == [.value([.key("foo"), .key("bar")])])
        #expect(pipeline(for: ".\"foo.bar\"") == [.value([.key("foo.bar")])])
        #expect(pipeline(for: ".foo.[0]") == [.value([.key("foo"), .index(0)])])
        #expect(pipeline(for: ".some.0") == [.value([.key("some"), .index(0)])])
    }

    /// Tests parsing value expressions with single-quoted and mixed keys.
    @Test
    func valueQueriesWithQuotes() {
        #expect(pipeline(for: ".'foo'") == [.value([.key("foo")])])
        #expect(pipeline(for: ".\"foo bar\"") == [.value([.key("foo bar")])])
        #expect(pipeline(for: ".foo.'bar baz'") == [.value([.key("foo"), .key("bar baz")])])
    }

    /// Tests parsing comparison expressions (`==`, `!=`, `>`, `>=`, `<`, `<=`, `=~`).
    @Test
    func comparisonQueries() {
        #expect(pipeline(for: ".value == \"bar\"") == [.value([.key("value")]), .literal("bar"), .comparison(.equals)])
        #expect(pipeline(for: ".value == 'bar'") == [.value([.key("value")]), .literal("bar"), .comparison(.equals)])
        #expect(pipeline(for: ".value == 'bar\"baz'") == [.value([.key("value")]), .literal("bar\"baz"), .comparison(.equals)])

        #expect(pipeline(for: ".value == 1") == [.value([.key("value")]), .literal(1), .comparison(.equals)])
        #expect(pipeline(for: ".value != 1") == [.value([.key("value")]), .literal(1), .comparison(.notEquals)])
        #expect(pipeline(for: ".value > 1") == [.value([.key("value")]), .literal(1), .comparison(.greaterThan)])
        #expect(pipeline(for: ".value >= 1") == [.value([.key("value")]), .literal(1), .comparison(.greaterThanOrEqual)])
        #expect(pipeline(for: ".value < 1") == [.value([.key("value")]), .literal(1), .comparison(.lessThan)])
        #expect(pipeline(for: ".value <= 1") == [.value([.key("value")]), .literal(1), .comparison(.lessThanOrEqual)])

        #expect(pipeline(for: ".string =~ /[Ss]ome/") == [.value([.key("string")]), .literal("/[Ss]ome/"), .comparison(.regex)])
        #expect(pipeline(for: ".string =~ /some/") == [.value([.key("string")]), .literal("/some/"), .comparison(.regex)])
        #expect(pipeline(for: ".string =~ /some/i") == [.value([.key("string")]), .literal("/some/i"), .comparison(.regex)])
        #expect(pipeline(for: ".string =~ \"^Some\"") == [.value([.key("string")]), .literal("^Some"), .comparison(.regex)])
    }

    /// Tests parsing the new string comparison operators.
    @Test
    func newComparisonQueries() {
        #expect(pipeline(for: ".string =* \"ame\"") == [.value([.key("string")]), .literal("ame"), .comparison(.contains)])
        #expect(pipeline(for: ".string =^ \"Some\"") == [.value([.key("string")]), .literal("Some"), .comparison(.startsWith)])
        #expect(pipeline(for: ".string =$ \"name\"") == [.value([.key("string")]), .literal("name"), .comparison(.endsWith)])
    }

    /// Tests parsing logical condition expressions (`and`, `or`, `not`).
    @Test
    func conditionQueries() {
        #expect(pipeline(for: ".foo.bar == 1 and .value == 1") == [
                .value([.key("foo"), .key("bar")]),
                .literal(1),
                .comparison(.equals),
                .value([.key("value")]),
                .literal(1),
                .comparison(.equals),
                .condition(.and),
            ])
        #expect(pipeline(for: ".foo == 1 or .bar == 2") == [
                .value([.key("foo")]),
                .literal(1),
                .comparison(.equals),
                .value([.key("bar")]),
                .literal(2),
                .comparison(.equals),
                .condition(.or),
            ])
        #expect(pipeline(for: ".foo == 1 or .value == 1") == [
                .value([.key("foo")]),
                .literal(1),
                .comparison(.equals),
                .value([.key("value")]),
                .literal(1),
                .comparison(.equals),
                .condition(.or),
            ])
        #expect(pipeline(for: ".foo not") == [
                .value([.key("foo")]),
                .condition(.not),
            ])
        #expect(pipeline(for: ".foo and .bar not") == [
                .value([.key("foo")]),
                .value([.key("bar")]),
                .condition(.and),
                .condition(.not),
            ])
        #expect(pipeline(for: ".foo or .bar not") == [
            .value([.key("foo")]),
            .value([.key("bar")]),
            .condition(.or),
            .condition(.not),
        ])
        #expect(pipeline(for: ".foo.bar not") == [
            .value([.key("foo"), .key("bar")]),
            .condition(.not),
        ])
        #expect(pipeline(for: ".foo == 'not'") == [
            .value([.key("foo")]),
            .literal("not"),
            .comparison(.equals),
        ])
    }

    /// Tests parsing a complex expression combining all operator types.
    @Test
    func complexQueryParsing() throws {
        // Combined: near + comparison + and
        let parser = try #require(QueryParser(string: ".value == 1 and near(10.0, 20.0, 500)"))
        let pipeline = try #require(parser.pipeline)
        #expect(pipeline.count == 5)
    }

    /// Tests parsing expressions with leading and trailing whitespace.
    @Test
    func whitespaceHandling() {
        #expect(pipeline(for: "  .foo  ") == [.value([.key("foo")])])
        #expect(pipeline(for: "  .foo == 1  ") == [.value([.key("foo")]), .literal(1), .comparison(.equals)])
        #expect(pipeline(for: "  near( 10.0 , 20.0 , 1000 )  ").first ==
            .near(Coordinate3D(latitude: 10.0, longitude: 20.0), 1000.0))
    }

    /// Tests that malformed queries return nil.
    @Test
    func invalidQueriesReturnNil() {
        // These degenerate inputs parse as search values, not nil,
        // so check that the pipeline is non-nil instead.
        #expect(QueryParser(string: "(") == nil)
        #expect(QueryParser(string: ".") != nil)
        #expect(QueryParser(string: "==") != nil)
        #expect(QueryParser(string: "near(") == nil)
        #expect(QueryParser(string: "near(1)") == nil)
        #expect(QueryParser(string: "within(") == nil)
        #expect(QueryParser(string: "within(1, 2, 3)") == nil) // needs 4 args
        #expect(QueryParser(string: ".foo in") == nil) // missing set
        #expect(QueryParser(string: ".foo in [") == nil) // incomplete set
        #expect(QueryParser(string: ".foo in [1,") == nil) // incomplete set
    }

    /// Tests that an empty pipeline returns false on evaluate.
    @Test
    func emptyPipelineReturnsFalse() {
        let parser = QueryParser(pipeline: [])
        #expect(parser.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: [:])) == false)
    }

    /// Tests query parser returns a search expression even for empty/whitespace strings.
    @Test
    func emptyQueryParsesToSearchValues() throws {
        let emptyParser = try #require(QueryParser(string: ""))
        if case .searchValues("") = try #require(emptyParser.pipeline?.first) {
            // expected: empty string becomes searchValues
        }
        else {
            Issue.record("Expected searchValues for empty query")
        }
    }

    // MARK: - Complex queries

    private let complexProps: [String: Sendable] = [
        "highway": "primary",
        "name": "Main Street",
        "maxspeed": 50,
        "lanes": 2,
        "surface": "asphalt",
        "oneway": true,
        "bridge": "yes",
        "tunnel": "no",
    ]

    /// Tests a complex query combining equality, string contains, and `and`.
    @Test
    func complexHighwayQuery() throws {
        let parser = try #require(QueryParser(string: ".highway == primary and .name =* \"Street\""))
        #expect(parser.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: complexProps)))
    }

    /// Tests a query combining `in` set membership with `and`.
    @Test
    func complexInAndComparison() throws {
        let parser = try #require(QueryParser(
            string: ".highway in [\"primary\", \"secondary\"] and .maxspeed >= 30"))
        #expect(parser.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: complexProps)))

        let parser2 = try #require(QueryParser(
            string: ".highway in [\"tertiary\"] or .maxspeed >= 30"))
        #expect(parser2.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: complexProps)))

        // Failing case
        let parser3 = try #require(QueryParser(
            string: ".highway in [\"tertiary\"] and .maxspeed >= 100"))
        #expect(parser3.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: complexProps)) == false)
    }

    /// Tests combining `exists`, `not`, and `in`.
    @Test
    func complexExistsAndNot() throws {
        // .bridge exists and .tunnel not exists → bridge=yes (truthy), tunnel=no (truthy) → true
        let parser = try #require(QueryParser(string: ".bridge exists and .tunnel exists"))
        #expect(parser.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: complexProps)) == true)

        // .bridge exists and .nonexistent not
        let parser2 = try #require(QueryParser(string: ".bridge exists and .nonexistent not"))
        #expect(parser2.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: complexProps)))
    }

    /// Tests a query using multiple comparisons with `and`/`or`.
    @Test
    func complexMultiCondition() throws {
        // .highway == primary and (.maxspeed > 30 or .lanes > 1)
        // RPN: .highway == primary .maxspeed 30 > .lanes 1 > or and
        let parser = try #require(QueryParser(
            string: ".highway == primary and .maxspeed > 30 or .lanes > 1"))
        // Note: without explicit grouping, `and` binds tighter due to RPN ordering:
        //   (.highway == primary and .maxspeed > 30) or .lanes > 1
        #expect(parser.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: complexProps)) == true)
    }

    /// Tests a query combining `in`, string operators, and spatial predicates.
    @Test
    func complexSpatialAndString() throws {
        let featureCoord = Coordinate3D(latitude: 10.5, longitude: 20.3)

        // near + string contains
        let parser1 = try #require(QueryParser(
            string: ".name =* \"Main\" and near(10.0, 20.0, 100000)"))
        #expect(parser1.evaluate(on: Feature(Point(featureCoord), properties: complexProps)))

        // within + ==
        let parser2 = try #require(QueryParser(
            string: ".highway == primary and within(20.0, 10.0, 21.0, 11.0)"))
        #expect(parser2.evaluate(on: Feature(Point(featureCoord), properties: complexProps)))

        // within + not matching
        let parser3 = try #require(QueryParser(
            string: ".highway == primary and within(30.0, 20.0, 31.0, 21.0)"))
        #expect(parser3.evaluate(on: Feature(Point(featureCoord), properties: complexProps)) == false)
    }

    /// Tests a query with `in` containing quoted commas, combined with `=^` prefix match.
    @Test
    func complexInWithCommasAndPrefix() throws {
        let parser = try #require(QueryParser(
            string: ".highway in [\"primary\", \"secondary, with, comma\"] and .name =^ \"Main\""))
        #expect(parser.evaluate(on: Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: complexProps)))
    }

    /// Tests parsing a query with all operator types in one string.
    @Test
    func complexAllOperatorsParsing() throws {
        let query = ".highway in [\"primary\", \"secondary\"] and .name =* \"Street\" and .maxspeed >= 30 and near(10.0, 20.0, 500)"
        let parser = try #require(QueryParser(string: query))
        let pipeline = try #require(parser.pipeline)
        // Should have: value, literalSet, in, value, literal, contains,
        //              value, literal, >=, near, and, and, and
        #expect(pipeline.count == 13)
    }

    // MARK: - Parenthesized groups

    @Test
    func parensInsideString() throws {
        #expect(QueryParser(string: #".name == "test(value)""#) != nil)
        #expect(QueryParser(string: ".name == 'test(value)'") != nil)
        #expect(QueryParser(string: #".name in ["a(b)", "c)d"]"#) != nil)
    }

    @Test
    func basicGrouping() throws {
        let expr = #"(.name == "a" AND .value == 1) OR .other == "b""#
        let parser = try #require(QueryParser(string: expr))
        #expect(parser.pipeline != nil)
    }

    @Test
    func groupingWithParensInStrings() throws {
        let expr = #"(.name == "test(a)" OR .value == 2) AND .other == "b""#
        let parser = try #require(QueryParser(string: expr))
        #expect(parser.pipeline != nil)
    }

    @Test
    func notBeforeGroup() throws {
        let expr = "NOT (.name == 'a' AND .value == 1)"
        let parser = try #require(QueryParser(string: expr))
        #expect(parser.pipeline != nil)
    }

    @Test
    func nestedGroups() throws {
        let expr = "( (.a == 1 AND .b == 2) OR (.c == 3 AND .d == 4) ) AND .e == 5"
        let parser = try #require(QueryParser(string: expr))
        #expect(parser.pipeline != nil)
    }

    @Test
    func unmatchedParensReturnNil() throws {
        #expect(QueryParser(string: ".name == \"a\")") == nil)
        #expect(QueryParser(string: "(.name == \"a\"") == nil)
    }

    @Test
    func groupedEvaluation() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: [
            "name": "Berlin",
            "value": 5,
        ])
        var parser = try #require(QueryParser(string: #"(.name == "Berlin" AND .value == 5) OR .other == "nope""#))
        #expect(parser.evaluate(on: feature))

        parser = try #require(QueryParser(string: #".name == "Berlin" AND (.value == 999 OR .other == "nope")"#))
        #expect(parser.evaluate(on: feature) == false)
    }

    @Test
    func parensAroundSingleExpression() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: ["a": 1])
        let parser = try #require(QueryParser(string: "(.a == 1)"))
        #expect(parser.evaluate(on: feature))
    }

    // MARK: - Edge cases

    @Test
    func stringEscaping() throws {
        #expect(QueryParser(string: #".name == "it's fine""#) != nil)
        #expect(QueryParser(string: ".name == 'he said \"hello\"'") != nil)
        #expect(QueryParser(string: #".tags in ["it's", '"hello"']"#) != nil)
        #expect(QueryParser(string: #".name == "   ""#) != nil)
        #expect(QueryParser(string: ".name == 'straße'") != nil)
        #expect(QueryParser(string: ".name == 'café'") != nil)
    }

    @Test
    func stringEscapingEvaluation() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: [
            "name": "it's fine",
            "greeting": "hello \"world\"",
            "unicode": "café",
        ])
        var parser = try #require(QueryParser(string: #".name == "it's fine""#))
        #expect(parser.evaluate(on: feature))
        parser = try #require(QueryParser(string: ".greeting == 'hello \"world\"'"))
        #expect(parser.evaluate(on: feature))
        parser = try #require(QueryParser(string: ".unicode == 'café'"))
        #expect(parser.evaluate(on: feature))
    }

    @Test
    func numericEdgeCases() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: [
            "large": Int.max,
            "small": Int.min,
            "negative": -42,
            "zero": 0,
        ])
        #expect(QueryParser(pipeline: [.value([.key("large")]), .literal(Int.max), .comparison(.equals)]).evaluate(on: feature))
        #expect(QueryParser(pipeline: [.value([.key("negative")]), .literal(-42), .comparison(.equals)]).evaluate(on: feature))
        #expect(QueryParser(pipeline: [.value([.key("zero")]), .literal(0), .comparison(.equals)]).evaluate(on: feature))
        let parser = try #require(QueryParser(string: ".negative == -42"))
        #expect(parser.evaluate(on: feature))
    }

    @Test
    func propertyAccessEdgeCases() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: [
            "a": ["b": ["c": ["d": 42]]] as [String: Sendable],
            "arr": [1, 2, 3],
            "empty_arr": [] as [Sendable],
        ])
        #expect(QueryParser(pipeline: [
            .value([.key("a"), .key("b"), .key("c"), .key("d")]), .literal(42), .comparison(.equals)]).evaluate(on: feature))
        #expect(QueryParser(pipeline: [
            .value([.key("arr"), .index(0)]), .literal(1), .comparison(.equals)]).evaluate(on: feature))
        #expect(QueryParser(pipeline: [
            .value([.key("arr"), .index(999)]), .literal(1), .comparison(.equals)]).evaluate(on: feature) == false)
        #expect(QueryParser(pipeline: [
            .value([.key("empty_arr"), .index(0)]), .literal(1), .comparison(.equals)]).evaluate(on: feature) == false)
        #expect(QueryParser(pipeline: [
            .value([.key("nonexistent")]), .literal(1), .comparison(.equals)]).evaluate(on: feature) == false)
    }

    @Test
    func spatialEdgeCases() throws {
        let origin = Coordinate3D(latitude: 10.0, longitude: 20.0)
        var parser = QueryParser(pipeline: [.near(origin, 0.0)])
        #expect(parser.evaluate(on: Feature(Point(origin), properties: [:])))
        parser = QueryParser(pipeline: [.near(origin, -1.0)])
        #expect(parser.evaluate(on: Feature(Point(Coordinate3D(latitude: 10.001, longitude: 20.001)), properties: [:])) == false)

        let point = Coordinate3D(latitude: 5.0, longitude: 10.0)
        let degenerate = BoundingBox(southWest: point, northEast: point)
        parser = QueryParser(pipeline: [.intersects(degenerate)])
        #expect(parser.evaluate(on: Feature(Point(point), properties: [:])))

        let poly = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 20.0),
            Coordinate3D(latitude: 11.0, longitude: 20.0),
            Coordinate3D(latitude: 11.0, longitude: 21.0),
            Coordinate3D(latitude: 10.0, longitude: 21.0),
            Coordinate3D(latitude: 10.0, longitude: 20.0),
        ]]))
        parser = QueryParser(pipeline: [.near(Coordinate3D(latitude: 10.5, longitude: 20.5), 1_000_000.0)])
        #expect(parser.evaluate(on: Feature(poly, properties: [:])))
    }

    @Test
    func booleanEdgeCases() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: ["a": 1, "b": 2, "c": 3])

        #expect(QueryParser(pipeline: [
            .value([.key("a")]), .condition(.not), .condition(.not), .condition(.not)]).evaluate(on: feature) == false)
        #expect(QueryParser(pipeline: [
            .value([.key("nonexistent")]), .condition(.not), .condition(.not)]).evaluate(on: feature) == false)
        #expect(QueryParser(pipeline: [
            .value([.key("a")]), .literal(1), .comparison(.equals),
            .value([.key("b")]), .literal(2), .comparison(.equals),
            .condition(.and),
            .value([.key("c")]), .literal(3), .comparison(.equals),
            .condition(.and),
        ]).evaluate(on: feature))
    }

    @Test
    func booleanChaining() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: ["a": 1, "b": 2, "c": 3, "d": 4, "e": 5, "f": 6, "g": 7, "h": 8, "i": 9, "j": 10])

        let query = ".a == 1 and .b == 2 and .c == 3 and .d == 4 and .e == 5 and .f == 6 and .g == 7 and .h == 8 and .i == 9 and .j == 10"
        var parser = try #require(QueryParser(string: query))
        #expect(parser.evaluate(on: feature))

        let queryFail = ".a == 1 and .b == 2 and .c == 3 and .d == 4 and .e == 5 and .f == 6 and .g == 7 and .h == 8 and .i == 9 and .j == 999"
        parser = try #require(QueryParser(string: queryFail))
        #expect(parser.evaluate(on: feature) == false)

        let condition = ".a == 1 and "
        let longQuery = String(repeating: condition, count: 100) + ".a == 1"
        parser = try #require(QueryParser(string: longQuery))
        #expect(parser.evaluate(on: feature))

        let veryLongQuery = String(repeating: condition, count: 1000) + ".a == 1"
        parser = try #require(QueryParser(string: veryLongQuery))
        #expect(parser.evaluate(on: feature))
    }

    @Test
    func keywordsAsValues() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: [
            "word_and": "and", "word_or": "or", "word_not": "not",
            "word_exists": "exists", "word_in": "in",
        ])
        #expect(try #require(QueryParser(string: #".word_and == "and""#)).evaluate(on: feature))
        #expect(try #require(QueryParser(string: ".word_or == 'or'")).evaluate(on: feature))
        #expect(try #require(QueryParser(string: #".word_not == "not""#)).evaluate(on: feature))
        #expect(try #require(QueryParser(string: ".word_exists == 'exists'")).evaluate(on: feature))
        #expect(try #require(QueryParser(string: #".word_in == "in""#)).evaluate(on: feature))
    }

    @Test
    func whitespaceEdgeCases() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: ["a": 1])
        #expect(try #require(QueryParser(string: ".a\t==\t1")).evaluate(on: feature))
        #expect(try #require(QueryParser(string: ".a\n==\n1")).evaluate(on: feature))
        #expect(try #require(QueryParser(string: "\n\n  .a   ==   1  \n")).evaluate(on: feature))
        #expect(try #require(QueryParser(string: ".a in [ 1 , 2 , 3 ]")).evaluate(on: feature))
    }

    @Test
    func caseInsensitiveKeywords() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: ["a": 1, "b": 2])
        #expect(try #require(QueryParser(string: ".a == 1 AND .b == 2")).evaluate(on: feature))
        #expect(try #require(QueryParser(string: ".a == 1 And .b == 2")).evaluate(on: feature))
        #expect(try #require(QueryParser(string: ".a == 1 OR .b == 2")).evaluate(on: feature))
        #expect(try #require(QueryParser(string: "NOT .a == 1")).evaluate(on: feature) == false)
    }

    @Test
    func osmLikeQueries() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 48.85, longitude: 2.35)), properties: [
            "highway": "primary", "name": "Rue de Rivoli", "maxspeed": 50,
            "oneway": true, "surface": "asphalt", "lanes": 4, "bridge": "yes",
        ])
        let queries: [(String, Bool)] = [
            (#".highway in ["primary", "secondary"] and .maxspeed >= 30 and .surface == "asphalt""#, true),
            (#".bridge exists and .oneway exists and .lanes >= 2"#, true),
            (#".highway == "motorway" and .surface == "concrete""#, false),
            ("near(48.85, 2.35, 1000) and .highway == \"primary\"",  true),
            (#".bridge exists and .tunnel not"#, true),
            (#"(.highway in ["primary", "secondary"] AND .surface == "asphalt") OR .bridge == "yes""#, true),
        ]
        for (query, expected) in queries {
            let parser = try #require(QueryParser(string: query))
            #expect(parser.evaluate(on: feature) == expected, "Failed for query: \(query)")
        }
    }

    @Test
    func existsWithVariousTypes() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: [
            "str": "", "zero": 0,
        ])
        #expect(QueryParser(pipeline: [.value([.key("str")]), .condition(.exists)]).evaluate(on: feature))
        #expect(QueryParser(pipeline: [.value([.key("zero")]), .condition(.exists)]).evaluate(on: feature))
        #expect(QueryParser(pipeline: [.value([.key("totally_missing")]), .condition(.exists)]).evaluate(on: feature) == false)
    }

    @Test
    func missingPropertyComparisons() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: ["only_key": 1])
        #expect(QueryParser(pipeline: [
            .value([.key("missing")]), .literal(1), .comparison(.equals)]).evaluate(on: feature) == false)
        #expect(QueryParser(pipeline: [
            .value([.key("missing")]), .literal(1), .comparison(.notEquals)]).evaluate(on: feature) == false)
        #expect(QueryParser(pipeline: [
            .value([.key("missing")]), .literal(1), .comparison(.greaterThan)]).evaluate(on: feature) == false)
        #expect(QueryParser(pipeline: [
            .value([.key("missing")]), .literal("x"), .comparison(.contains)]).evaluate(on: feature) == false)
        #expect(QueryParser(pipeline: [
            .value([.key("missing")]), .literalSet([1]), .comparison(.in)]).evaluate(on: feature) == false)
    }

    @Test
    func deeplyNestedParens() throws {
        let feature = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), properties: ["a": 1, "b": 2])
        #expect(try #require(QueryParser(string: "(((.a == 1))) AND (.b == 2)")).evaluate(on: feature))
        #expect(try #require(QueryParser(string: "((.a == 1 AND .b == 2) OR (.a == 999 AND .b == 999)) AND (.a == 1)")).evaluate(on: feature))
    }

}
