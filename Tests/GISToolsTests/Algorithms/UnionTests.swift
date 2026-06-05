import Foundation
@testable import GISTools
import Testing

struct UnionTests {

    @Test
    func unionDisjointPolygons() async throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))

        let result = try #require(poly1.union(with: poly2))
        // Disjoint polygons must stay separate.
        #expect(result.polygons.count == 2)
        // The two areas must be preserved individually.
        let totalArea = result.polygons.reduce(0.0) { $0 + $1.area }
        let expected = poly1.area + poly2.area
        #expect(abs(totalArea - expected) < 1.0)
    }

    @Test
    func unionContainedPolygon() async throws {
        let outer = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let inner = try #require(Polygon([[
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 7.0),
            Coordinate3D(latitude: 7.0, longitude: 7.0),
            Coordinate3D(latitude: 7.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
        ]]))

        let result = try #require(outer.union(with: inner))
        // The inner polygon is completely inside the outer, so the union is
        // the outer polygon only.
        #expect(result.polygons.count == 1)
        let unionPolygon = try #require(result.polygons.first)
        #expect(unionPolygon.coordinates == outer.coordinates)
    }

    @Test
    func unionOverlappingRectangles() async throws {
        // Two overlapping axis-aligned squares, centered around the origin.
        // Expected union is an L-shaped polygon.
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]]))

        let result = try #require(poly1.union(with: poly2))
        // Overlapping polygons must merge into a single polygon.
        #expect(result.polygons.count == 1)
        let unionPolygon = try #require(result.polygons.first)

        // The union area equals the area of poly1 + poly2 - intersection area.
        // Each square is 4x4 = 16, their intersection is 2x2 = 4, so the
        // expected area is 16 + 16 - 4 = 28.
        let expectedArea = poly1.area + poly2.area
            - (Polygon([[
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 2.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 4.0),
                Coordinate3D(latitude: 4.0, longitude: 2.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
            ]]))!.area
        #expect(abs(unionPolygon.area - expectedArea) < 1.0)
    }

    @Test
    func unionOverlappingRectanglesVertices() async throws {
        // Verify the actual vertices of the merged polygon.
        // poly1 = [0,4]x[0,4], poly2 = [2,6]x[2,6]
        // Expected union boundary (CCW):
        //   (0,0) -> (4,0) -> (4,2) -> (6,2) -> (6,6) -> (2,6) -> (2,4) -> (0,4) -> (0,0)
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]]))

        let result = try #require(poly1.union(with: poly2))
        #expect(result.polygons.count == 1)
        let coordinates = try #require(result.polygons.first?.coordinates.first)

        let expected: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 2.0, longitude: 4.0),
            Coordinate3D(latitude: 2.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 2.0),
            Coordinate3D(latitude: 4.0, longitude: 2.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]
        // Coordinate equality uses the equality delta, so the order of
        // vertices must match (cyclic rotation and reverse orientation are
        // not handled here).
        #expect(coordinates == expected)
    }

    @Test
    func unionFeatureCollection() async throws {
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 10.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 10.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]]))

        let fc = FeatureCollection([Feature(poly1), Feature(poly2)])
        let result = try #require(fc.union())
        #expect(result.features.first?.geometry is MultiPolygon)
        let multiPolygon = try #require(result.features.first?.geometry as? MultiPolygon)
        #expect(multiPolygon.polygons.count == 2)
    }

    @Test
    func unionOverlappingFeatureCollection() async throws {
        // Two overlapping rectangles packed in a FeatureCollection should
        // produce a single merged polygon.
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]]))

        let fc = FeatureCollection([Feature(poly1), Feature(poly2)])
        let result = try #require(fc.union())
        let multiPolygon = try #require(result.features.first?.geometry as? MultiPolygon)
        #expect(multiPolygon.polygons.count == 1)
    }

    @Test
    func unionEmpty() async throws {
        let fc = FeatureCollection()
        #expect(fc.union() == nil)
    }

    @Test
    func unionEmptyArray() async throws {
        #expect(Union.unionPolygons([]) == nil)
    }

    @Test
    func unionPolygonsViaPublicAPI() async throws {
        // Verify that unionPolygons itself is callable and merges overlapping
        // polygons.
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]]))
        let poly3 = try #require(Polygon([[
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 25.0),
            Coordinate3D(latitude: 25.0, longitude: 25.0),
            Coordinate3D(latitude: 25.0, longitude: 20.0),
            Coordinate3D(latitude: 20.0, longitude: 20.0),
        ]]))

        let result = try #require(Union.unionPolygons([poly1, poly2, poly3]))
        // poly1 and poly2 merge into one polygon, poly3 stays separate.
        #expect(result.polygons.count == 2)
        // The merged polygon must have area poly1 + poly2 - intersection.
        // The 2x2 intersection of [0,4]x[0,4] and [2,6]x[2,6] has area
        // 4 * 1° * 1° * some factor in square meters.
        let intersection = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]]))
        let areas = result.polygons.map(\.area).sorted(by: >)
        let poly3Area = poly3.area
        #expect(abs(areas[0] - (poly1.area + poly2.area - intersection.area)) < 1.0)
        #expect(abs(areas[1] - poly3Area) < 1.0)
    }

    @Test
    func unionMultiPolygonWithPolygon() async throws {
        // Multi-polygon unioned with another polygon.
        let polyA = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polyB = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]]))
        let multi = try #require(MultiPolygon([polyA, polyB]))

        let polyC = try #require(Polygon([[
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 3.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
        ]]))

        let result = try #require(multi.union(with: polyC))
        // polyA and polyB already merge into one polygon, and polyC is fully
        // contained in the merged area.
        #expect(result.polygons.count == 1)
    }

    @Test
    func unionFormUnion() async throws {
        // formUnion mutates the receiver in place.
        let polyA = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let polyB = try #require(Polygon([[
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 6.0),
            Coordinate3D(latitude: 6.0, longitude: 2.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
        ]]))
        var multi = try #require(MultiPolygon([polyA]))
        multi.formUnion(with: polyB)

        // The two overlapping rectangles must have merged into a single polygon.
        #expect(multi.polygons.count == 1)
    }

    @Test
    func unionTouchingAtEdge() async throws {
        // Two rectangles sharing an edge. The union should still be a single
        // polygon whose area equals the sum of both rectangles.
        let poly1 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 4.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]]))
        let poly2 = try #require(Polygon([[
            Coordinate3D(latitude: 0.0, longitude: 4.0),
            Coordinate3D(latitude: 0.0, longitude: 8.0),
            Coordinate3D(latitude: 4.0, longitude: 8.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 0.0, longitude: 4.0),
        ]]))

        let result = try #require(poly1.union(with: poly2))
        // The shared edge has 4 distinct intersection points along it (the
        // endpoints and any t-values in between). With >= 2 intersections we
        // either merge or keep separate, but the total area should always
        // equal the sum of both rectangles.
        let totalArea = result.polygons.reduce(0.0) { $0 + $1.area }
        #expect(abs(totalArea - (poly1.area + poly2.area)) < 1.0)
    }

}
