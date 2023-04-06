@testable import GISTools
import XCTest

final class CoordinateTests: XCTestCase {

    func testCoordinate3DDescription() {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0)
        XCTAssertEqual(coordinate.description, "Coordinate3D(longitude: 10.0, latitude: 15.0)")

        let coordinateZ = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0)
        XCTAssertEqual(coordinateZ.description, "Coordinate3D(longitude: 10.0, latitude: 15.0, altitude: 500.0)")

        let coordinateM = Coordinate3D(latitude: 15.0, longitude: 10.0, m: 1234)
        XCTAssertEqual(coordinateM.description, "Coordinate3D(longitude: 10.0, latitude: 15.0, m: 1234.0)")

        let coordinateZM = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: 1234)
        XCTAssertEqual(coordinateZM.description, "Coordinate3D(longitude: 10.0, latitude: 15.0, altitude: 500.0, m: 1234.0)")
    }

    func testCoordinateXYDescription() {
        let coordinate = CoordinateXY(x: 10.0, y: 15.0)
        XCTAssertEqual(coordinate.description, "CoordinateXY(x: 10.0, y: 15.0)")

        let coordinateZ = CoordinateXY(x: 10.0, y: 15.0, z: 500.0)
        XCTAssertEqual(coordinateZ.description, "CoordinateXY(x: 10.0, y: 15.0, z: 500.0)")

        let coordinateM = CoordinateXY(x: 10.0, y: 15.0, m: 1234)
        XCTAssertEqual(coordinateM.description, "CoordinateXY(x: 10.0, y: 15.0, m: 1234.0)")

        let coordinateZM = CoordinateXY(x: 10.0, y: 15.0, z: 500.0, m: 1234)
        XCTAssertEqual(coordinateZM.description, "CoordinateXY(x: 10.0, y: 15.0, z: 500.0, m: 1234.0)")
    }

}
