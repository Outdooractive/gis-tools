import Testing
import Foundation
@testable import GISTools

struct TesselateTests {

    // MARK: - Helpers

    private func triangleAreaSum(_ collection: FeatureCollection) -> Double {
        collection.features.reduce(0.0) { sum, feature in
            sum + ((feature.geometry as? Polygon)?.area ?? 0.0)
        }
    }

    private func expectAreaPreserved(
        _ collection: FeatureCollection,
        polygon: Polygon,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let expected = polygon.area
        let actual = triangleAreaSum(collection)
        let tolerance = max(0.000001, abs(expected) * 0.000001)
        #expect(
            abs(actual - expected) <= tolerance,
            "Triangle area sum \(actual) != polygon area \(expected)",
            sourceLocation: sourceLocation)
    }

    // MARK: - Reference tests

    private static let tessFixtures = [
        "Triangle",
        "Square",
        "ConcavePentagon",
        "PolygonWithHole",
        "LShape",
    ]

    @Test(arguments: tessFixtures)
    private func turfTesselateFixture(_ name: String) async throws {
        let polygon = try TestData.polygon(package: "Tesselate", name: name)
        let result = polygon.tesselated()

        #expect(result.features.isNotEmpty, "\(name): expected at least one triangle")
        // Every triangle must have exactly 3 coordinates + closing (4 total)
        for feature in result.features {
            if let tri = feature.geometry as? Polygon {
                #expect(tri.outerRing?.coordinates.count == 4,
                        "\(name): expected triangle with 4 coords, got \(tri.outerRing?.coordinates.count ?? 0)")
                #expect(tri.area >= 0.0, "\(name): triangle must not be inverted")
            }
        }

        expectAreaPreserved(result, polygon: polygon)
    }

    // Validates that a triangle (3 vertices) tessellates into a single triangle.
    @Test
    func testTriangle() throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = polygon.tesselated()
        #expect(result.features.count == 1)
    }

    // Validates that a square (4 vertices) tessellates into 2 triangles, each with 3 unique vertices.
    @Test
    func testSquare() throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = polygon.tesselated()
        #expect(result.features.count == 2)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
            #expect(tri.projection == .epsg4326)
        }
    }

    // Validates that a pentagon (5 vertices) tessellates into 3 triangles.
    @Test
    func testPentagon() throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = polygon.tesselated()
        #expect(result.features.count == 3)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
        }
    }

    // Validates that a hexagon (6 vertices) tessellates into 4 triangles (n − 2).
    @Test
    func testHexagon() throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 3.0, longitude: 8.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: -2.0, longitude: 3.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = polygon.tesselated()
        // (5, 0) is collinear in lon/lat but not on the ellipsoid; it is
        // kept so the spherical area is preserved.
        #expect(result.features.count == 4)
        expectAreaPreserved(result, polygon: polygon)
    }

    // Validates that a polygon with a hole correctly bridges the hole and
    // produces valid triangles covering the ring-minus-hole area.
    @Test
    func testPolygonWithHole() throws {
        let polygon = try #require(Polygon([
            // Outer ring
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
            // Inner ring (hole)
            [
                Coordinate3D(latitude: 3.0, longitude: 3.0),
                Coordinate3D(latitude: 3.0, longitude: 7.0),
                Coordinate3D(latitude: 7.0, longitude: 7.0),
                Coordinate3D(latitude: 7.0, longitude: 3.0),
                Coordinate3D(latitude: 3.0, longitude: 3.0),
            ],
        ]))

        let result = polygon.tesselated()
        #expect(result.features.count > 0)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
        }

        expectAreaPreserved(result, polygon: polygon)
    }

    // Validates that a MultiPolygon tessellates each constituent polygon
    // and merges the results (2 squares = 4 triangles).
    @Test
    func testMultiPolygon() throws {
        let multiPolygon = MultiPolygon([
            try #require(Polygon([
                [
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                    Coordinate3D(latitude: 5.0, longitude: 0.0),
                    Coordinate3D(latitude: 5.0, longitude: 5.0),
                    Coordinate3D(latitude: 0.0, longitude: 5.0),
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                ],
            ])),
            try #require(Polygon([
                [
                    Coordinate3D(latitude: 10.0, longitude: 10.0),
                    Coordinate3D(latitude: 15.0, longitude: 10.0),
                    Coordinate3D(latitude: 15.0, longitude: 15.0),
                    Coordinate3D(latitude: 10.0, longitude: 15.0),
                    Coordinate3D(latitude: 10.0, longitude: 10.0),
                ],
            ])),
        ])

        guard let multiPolygon else { return }
        let result = multiPolygon.tesselated()
        #expect(result.features.count == 4)
    }

    // Validates that an empty polygon returns an empty FeatureCollection.
    @Test
    func testEmptyPolygon() throws {
        let polygon = Polygon(unchecked: [[Coordinate3D]]())
        let result = polygon.tesselated()
        #expect(result.features.isEmpty)
    }

    // Validates that a concave (arrowhead) polygon tessellates correctly.
    @Test
    func testConcavePolygon() throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ]))

        let result = polygon.tesselated()
        #expect(result.features.count == 3)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
        }
    }

    // MARK: - Projections

    // Validates that a square in EPSG:3857 tessellates into 2 triangles.
    @Test
    func tesselate3857() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .epsg3857),
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
        ]]))

        let result = polygon.tesselated()
        #expect(result.features.count == 2)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
            #expect(tri.projection == .epsg3857)
        }
    }

    // Validates that a square in noSRID tessellates into 2 triangles.
    @Test
    func tesselateNoSRID() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1000.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 1000.0, projection: .noSRID),
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
        ]]))

        let result = polygon.tesselated()
        #expect(result.features.count == 2)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
            #expect(tri.projection == .noSRID)
        }
    }

    // Validates that a square in EPSG:4978 tessellates into 2 triangles.
    @Test
    func tesselate4978() async throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 0.009).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.009, longitude: 0.009).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.009, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
        ]]))

        let result = polygon.tesselated()
        #expect(result.features.count == 2)

        for feature in result.features {
            let tri = try #require(feature.geometry as? Polygon)
            #expect(tri.projection == .epsg4978)
        }
    }

    // Validates tessellation of a polygon that crosses the antimeridian
    // (date line), spanning from longitude 170° to −170°.
    @Test
    func testAntimeridianPolygon() throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ]))

        let result = polygon.tesselated()
        // Square crossing antimeridian = 2 triangles
        #expect(result.features.count == 2)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)

            // Every triangle must stay on the 20°-wide short side.
            let lons = tri.coordinates[0].map(\.longitude)
            var unwrapped = lons
            for index in 1 ..< unwrapped.count {
                while unwrapped[index] - unwrapped[index - 1] > 180.0 {
                    unwrapped[index] -= 360.0
                }
                while unwrapped[index - 1] - unwrapped[index] > 180.0 {
                    unwrapped[index] += 360.0
                }
            }
            #expect(
                (unwrapped.max() ?? 0.0) - (unwrapped.min() ?? 0.0) <= 20.0,
                "Triangle spans the long way around: \(lons)")
        }

        expectAreaPreserved(result, polygon: polygon)
    }

    // Validates tessellation of a polygon with a hole that crosses the
    // antimeridian (date line).
    @Test
    func testAntimeridianPolygonWithHole() throws {
        let polygon = try #require(Polygon([
            // Outer ring crossing antimeridian
            [
                Coordinate3D(latitude: -5.0, longitude: 175.0),
                Coordinate3D(latitude: 15.0, longitude: 175.0),
                Coordinate3D(latitude: 15.0, longitude: -175.0),
                Coordinate3D(latitude: -5.0, longitude: -175.0),
                Coordinate3D(latitude: -5.0, longitude: 175.0),
            ],
            // Hole entirely on one side of the antimeridian
            [
                Coordinate3D(latitude: 0.0, longitude: 177.0),
                Coordinate3D(latitude: 0.0, longitude: 179.0),
                Coordinate3D(latitude: 2.0, longitude: 179.0),
                Coordinate3D(latitude: 2.0, longitude: 177.0),
                Coordinate3D(latitude: 0.0, longitude: 177.0),
            ],
        ]))

        let result = polygon.tesselated()
        #expect(result.features.count > 0)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
        }

        expectAreaPreserved(result, polygon: polygon)
    }


    // MARK: - Audit regressions

    /// Multiple holes must all be bridged, not just the first one.
    @Test
    func multipleHoles() throws {
        let polygon = try #require(Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
            [
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 2.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 2.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
            ],
            [
                Coordinate3D(latitude: 6.0, longitude: 6.0),
                Coordinate3D(latitude: 6.0, longitude: 8.0),
                Coordinate3D(latitude: 8.0, longitude: 8.0),
                Coordinate3D(latitude: 8.0, longitude: 6.0),
                Coordinate3D(latitude: 6.0, longitude: 6.0),
            ],
        ]))

        let result = polygon.tesselated()
        #expect(result.features.isNotEmpty)
        expectAreaPreserved(result, polygon: polygon)
    }

    /// A polygon with a hole in a planar projection, ECEF and noSRID.
    @Test(arguments: [Projection.epsg3857, .epsg4978, .noSRID])
    func holeAcrossProjections(projection: Projection) throws {
        func coordinate(_ latitude: Double, _ longitude: Double) -> Coordinate3D {
            if projection == .noSRID {
                return Coordinate3D(x: longitude, y: latitude, projection: projection)
            }
            return Coordinate3D(latitude: latitude, longitude: longitude)
                .projected(to: projection)
        }

        let polygon = try #require(Polygon([
            [
                coordinate(0.0, 0.0),
                coordinate(0.0, 10.0),
                coordinate(10.0, 10.0),
                coordinate(10.0, 0.0),
                coordinate(0.0, 0.0),
            ],
            [
                coordinate(3.0, 3.0),
                coordinate(3.0, 7.0),
                coordinate(7.0, 7.0),
                coordinate(7.0, 3.0),
                coordinate(3.0, 3.0),
            ],
        ]))

        let result = polygon.tesselated()
        #expect(result.features.isNotEmpty)
        #expect(result.features.allSatisfy { ($0.geometry as? Polygon)?.projection == projection })
        expectAreaPreserved(result, polygon: polygon)
    }

    /// EPSG:3857 polygons that cross the wraparound axis must also stay on the
    /// short side and preserve area.
    @Test
    func antimeridianPolygon3857() throws {
        func coordinate(_ latitude: Double, _ longitude: Double) -> Coordinate3D {
            Coordinate3D(latitude: latitude, longitude: longitude)
                .projected(to: .epsg3857)
        }
        let polygon = try #require(Polygon([[
            coordinate(0.0, 170.0),
            coordinate(0.0, 190.0),
            coordinate(10.0, 190.0),
            coordinate(10.0, 170.0),
            coordinate(0.0, 170.0),
        ]]))

        let result = polygon.tesselated()
        #expect(result.features.count == 2)
        expectAreaPreserved(result, polygon: polygon)

        for feature in result.features {
            let triangle = try #require(feature.geometry as? Polygon)
            #expect(triangle.projection == .epsg3857)
            let xs = triangle.coordinates[0].map(\.longitude)
            #expect(xs.allSatisfy { abs($0) <= GISTool.originShift + 0.001 })
        }
    }

    /// A fully collinear ring has no area and must not emit inverted or
    /// overlapping triangles.
    @Test
    func collinearRingProducesNoArea() {
        let polygon = Polygon(unchecked: [[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]])

        let result = polygon.tesselated()
        let area = triangleAreaSum(result)
        #expect(abs(area) < 0.000001, "Collinear ring produced area \(area)")
        for feature in result.features {
            let triangle = feature.geometry as? Polygon
            #expect((triangle?.area ?? 0.0) >= 0.0)
        }
    }


}
