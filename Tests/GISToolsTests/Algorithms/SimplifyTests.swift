@testable import GISTools
import XCTest

final class SimplifyTests: XCTestCase {

    // TODO: More tests
    // https://github.com/Turfjs/turf/tree/master/packages/turf-simplify/test/in
    // https://github.com/Turfjs/turf/tree/master/packages/turf-simplify/test/out

    func testInvalidPolygons() {
        // TODO: Improve the polygon validity check

//        let polygon1 = MultiPolygon([[[Coordinate3D(latitude: 1.0, longitude: 0.0), Coordinate3D(latitude: 2.0, longitude: 0.0), Coordinate3D(latitude: 3.0, longitude: 0.0), Coordinate3D(latitude: 2.5, longitude: 0.0), Coordinate3D(latitude: 1.0, longitude: 0.0)]]])
//        let polygon2 = MultiPolygon([[[Coordinate3D(latitude: 1.0, longitude: 0.0), Coordinate3D(latitude: 1.0, longitude: 0.0), Coordinate3D(latitude: 2.0, longitude: 1.0), Coordinate3D(latitude: 1.0, longitude: 0.0)]]])
//
//        XCTAssertNil(polygon1?.simplified())
//        XCTAssertNil(polygon2?.simplified())
    }

    func testRingValidationBackoff() {
        let polygon = Polygon([[
            Coordinate3D(latitude: 47.602460344511684, longitude: 4.564821280446012),
            Coordinate3D(latitude: 47.639486027997926, longitude: 4.564821280446012),
            Coordinate3D(latitude: 47.639486027997926, longitude: 4.564821280446012),
            Coordinate3D(latitude: 47.602460344511684, longitude: 4.564821280446012),
        ]])

        // Check if we ran into an endless loop
        let startDate = Date()
        _ = polygon?.simplified(tolerance: 5.0, highQuality: false)
        XCTAssertTrue(fabs(startDate.timeIntervalSinceNow) < 0.5)
    }

}
