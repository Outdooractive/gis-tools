import Foundation
@testable import GISTools
import Testing

struct SimplifyTests {

    // TODO: More tests
    // https://github.com/Turfjs/turf/tree/master/packages/turf-simplify/test/in
    // https://github.com/Turfjs/turf/tree/master/packages/turf-simplify/test/out

    // Validates that invalid polygons return nil when simplified.
    @Test
    func invalidPolygons() async throws {
        // TODO: Improve the polygon validity check

//        let polygon1 = MultiPolygon([[[Coordinate3D(latitude: 1.0, longitude: 0.0), Coordinate3D(latitude: 2.0, longitude: 0.0), Coordinate3D(latitude: 3.0, longitude: 0.0), Coordinate3D(latitude: 2.5, longitude: 0.0), Coordinate3D(latitude: 1.0, longitude: 0.0)]]])
//        let polygon2 = MultiPolygon([[[Coordinate3D(latitude: 1.0, longitude: 0.0), Coordinate3D(latitude: 1.0, longitude: 0.0), Coordinate3D(latitude: 2.0, longitude: 1.0), Coordinate3D(latitude: 1.0, longitude: 0.0)]]])
//
//        XCTAssertNil(polygon1?.simplified())
//        XCTAssertNil(polygon2?.simplified())
    }

    // Validates that simplification with degenerate rings does not enter an endless loop.
    @Test
    func ringValidationBackoff() async throws {
        let polygon = Polygon([[
            Coordinate3D(latitude: 47.602460344511684, longitude: 4.564821280446012),
            Coordinate3D(latitude: 47.639486027997926, longitude: 4.564821280446012),
            Coordinate3D(latitude: 47.639486027997926, longitude: 4.564821280446012),
            Coordinate3D(latitude: 47.602460344511684, longitude: 4.564821280446012),
        ]])

        // Check if we ran into an endless loop
        let startDate = Date()
        _ = polygon?.simplified(tolerance: 5.0, highQuality: false)
        #expect(abs(startDate.timeIntervalSinceNow) < 0.5)
    }

    // MARK: - gridSize

    // Validates that `simplified(tolerance:highQuality:gridSize:)` matches manual pre-snapping.
    @Test
    func simplifyWithGridSize() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0001, longitude: 0.0001),
            Coordinate3D(latitude: 5.0001, longitude: 5.0001),
            Coordinate3D(latitude: 10.0001, longitude: 10.0001),
        ]))
        let gridSize = 0.001

        let withParam = lineString.simplified(tolerance: 1.0, gridSize: gridSize)
        let snapped = lineString.snappedToGrid(tolerance: gridSize)
        let manual = snapped.simplified(tolerance: 1.0)
        #expect(withParam.coordinates == manual.coordinates)
    }

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 170.0),
            Coordinate3D(latitude: 5.0, longitude: 174.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
            Coordinate3D(latitude: 5.0, longitude: 174.0),
            Coordinate3D(latitude: 0.0, longitude: 170.0),
        ]))
        let simplified = lineString.simplified(tolerance: 1.0)
        #expect(!simplified.coordinates.isEmpty)
        for coord in simplified.coordinates {
            #expect(coord.latitude >= 0.0 && coord.latitude <= 10.0)
            #expect(coord.longitude >= 170.0 && coord.longitude <= 179.0)
        }
    }

}
