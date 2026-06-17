import Testing
import Foundation
@testable import GISTools

struct TesselateTests {

    // Validates that a triangle (3 vertices) tessellates into a single triangle.
    @Test
    func testTriangle() {
        let polygon = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = polygon.tesselated()
        #expect(result.features.count == 1)
    }

    // Validates that a square (4 vertices) tessellates into 2 triangles, each with 3 unique vertices.
    @Test
    func testSquare() {
        let polygon = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = polygon.tesselated()
        #expect(result.features.count == 2)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
        }
    }

    // Validates that a pentagon (5 vertices) tessellates into 3 triangles.
    @Test
    func testPentagon() {
        let polygon = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 10.0),
                Coordinate3D(latitude: 5.0, longitude: 15.0),
                Coordinate3D(latitude: 0.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = polygon.tesselated()
        #expect(result.features.count == 3)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
        }
    }

    // Validates that a hexagon (6 vertices) tessellates into 4 triangles (n − 2).
    @Test
    func testHexagon() {
        let polygon = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 0.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0),
                Coordinate3D(latitude: 3.0, longitude: 8.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: -2.0, longitude: 3.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = polygon.tesselated()
        #expect(result.features.count == 4)
    }

    // Validates that a polygon with a hole correctly bridges the hole and
    // produces valid triangles covering the ring-minus-hole area.
    @Test
    func testPolygonWithHole() {
        let polygon = Polygon([
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
        ])!

        let result = polygon.tesselated()
        #expect(result.features.count > 0)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
        }
    }

    // Validates that a MultiPolygon tessellates each constituent polygon
    // and merges the results (2 squares = 4 triangles).
    @Test
    func testMultiPolygon() {
        let multiPolygon = MultiPolygon([
            Polygon([
                [
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                    Coordinate3D(latitude: 5.0, longitude: 0.0),
                    Coordinate3D(latitude: 5.0, longitude: 5.0),
                    Coordinate3D(latitude: 0.0, longitude: 5.0),
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                ],
            ])!,
            Polygon([
                [
                    Coordinate3D(latitude: 10.0, longitude: 10.0),
                    Coordinate3D(latitude: 15.0, longitude: 10.0),
                    Coordinate3D(latitude: 15.0, longitude: 15.0),
                    Coordinate3D(latitude: 10.0, longitude: 15.0),
                    Coordinate3D(latitude: 10.0, longitude: 10.0),
                ],
            ])!,
        ])

        guard let multiPolygon else { return }
        let result = multiPolygon.tesselated()
        #expect(result.features.count == 4)
    }

    // Validates that an empty polygon returns an empty FeatureCollection.
    @Test
    func testEmptyPolygon() {
        let polygon = Polygon(unchecked: [[Coordinate3D]]())
        let result = polygon.tesselated()
        #expect(result.features.isEmpty)
    }

    // Validates that a concave (arrowhead) polygon tessellates correctly.
    @Test
    func testConcavePolygon() {
        let polygon = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 0.0),
                Coordinate3D(latitude: 10.0, longitude: 5.0),
                Coordinate3D(latitude: 5.0, longitude: 10.0),
                Coordinate3D(latitude: 0.0, longitude: 5.0),
                Coordinate3D(latitude: 0.0, longitude: 0.0),
            ],
        ])!

        let result = polygon.tesselated()
        #expect(result.features.count == 3)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
        }
    }

    // Validates tessellation of a polygon that crosses the antimeridian
    // (date line), spanning from longitude 170° to −170°.
    @Test
    func testAntimeridianPolygon() {
        let polygon = Polygon([
            [
                Coordinate3D(latitude: 0.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: 170.0),
                Coordinate3D(latitude: 10.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: -170.0),
                Coordinate3D(latitude: 0.0, longitude: 170.0),
            ],
        ])!

        let result = polygon.tesselated()
        // Square crossing antimeridian = 2 triangles
        #expect(result.features.count == 2)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
        }
    }

    // Validates tessellation of a polygon with a hole that crosses the
    // antimeridian (date line).
    @Test
    func testAntimeridianPolygonWithHole() {
        let polygon = Polygon([
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
        ])!

        let result = polygon.tesselated()
        #expect(result.features.count > 0)

        for feature in result.features {
            let tri = feature.geometry as! Polygon
            #expect(tri.coordinates[0].count == 4)
        }
    }

}
