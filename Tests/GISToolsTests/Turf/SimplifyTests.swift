#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

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

    static var allTests = [
        ("testInvalidPolygons", testInvalidPolygons),
    ]

}
