@testable import GISTools
import XCTest

final class CoordinateTests: XCTestCase {

    func testCoordinate3DDescription() {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0)
        XCTAssertEqual(coordinate.description, "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0)")

        let coordinateZ = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0)
        XCTAssertEqual(coordinateZ.description, "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0, altitude: 500.0)")

        let coordinateM = Coordinate3D(latitude: 15.0, longitude: 10.0, m: 1234)
        XCTAssertEqual(coordinateM.description, "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0, m: 1234.0)")

        let coordinateZM = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: 1234)
        XCTAssertEqual(coordinateZM.description, "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: 1234.0)")
    }

    func testCoordinateXYDescription() {
        let coordinate = Coordinate3D(x: 10.0, y: 15.0)
        XCTAssertEqual(coordinate.description, "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0)")

        let coordinateZ = Coordinate3D(x: 10.0, y: 15.0, z: 500.0)
        XCTAssertEqual(coordinateZ.description, "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0, z: 500.0)")

        let coordinateM = Coordinate3D(x: 10.0, y: 15.0, m: 1234)
        XCTAssertEqual(coordinateM.description, "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0, m: 1234.0)")

        let coordinateZM = Coordinate3D(x: 10.0, y: 15.0, z: 500.0, m: 1234)
        XCTAssertEqual(coordinateZM.description, "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0, z: 500.0, m: 1234.0)")
    }

    func testEncodable() throws {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0)
        let coordinateData = try JSONEncoder().encode(coordinate)

        XCTAssertEqual(String(data: coordinateData, encoding: .utf8), "[10,15]")
    }

    func testEncodableNull() throws {
        let coordinateM = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: nil, m: 1234)
        let coordinateZ = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: nil)

        let coordinateDataM = try JSONEncoder().encode(coordinateM)
        let coordinateDataZ = try JSONEncoder().encode(coordinateZ)

        XCTAssertEqual(String(data: coordinateDataM, encoding: .utf8), "[10,15,null,1234]")
        XCTAssertEqual(String(data: coordinateDataZ, encoding: .utf8), "[10,15,500]")
    }

    func testEncodable3857() throws {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0).projected(to: .epsg3857)
        let coordinateData = try JSONEncoder().encode(coordinate)
        let decodedCoordinate = try JSONDecoder().decode(Coordinate3D.self, from: coordinateData)

        XCTAssertEqual(Double(decodedCoordinate.asJson[0]!), 10.0, accuracy: 0.000001)
        XCTAssertEqual(Double(decodedCoordinate.asJson[1]!), 15.0, accuracy: 0.000001)
    }

    func testDecodable() throws {
        let coordinateData =  try XCTUnwrap("[10,15]".data(using: .utf8))
        let decodedCoordinate = try JSONDecoder().decode(Coordinate3D.self, from: coordinateData)

        XCTAssertEqual(decodedCoordinate.asJson, [10.0, 15.0])
    }

    func testDecodableInvalid() throws {
        let coordinateData1 =  try XCTUnwrap("[10]".data(using: .utf8))
        XCTAssertThrowsError(try JSONDecoder().decode(Coordinate3D.self, from: coordinateData1))

        let coordinateData2 =  try XCTUnwrap("[10,]".data(using: .utf8))
        XCTAssertThrowsError(try JSONDecoder().decode(Coordinate3D.self, from: coordinateData2))

        let coordinateData3 =  try XCTUnwrap("[null,null]".data(using: .utf8))
        XCTAssertThrowsError(try JSONDecoder().decode(Coordinate3D.self, from: coordinateData3))

        let coordinateData4 =  try XCTUnwrap("[]".data(using: .utf8))
        XCTAssertThrowsError(try JSONDecoder().decode(Coordinate3D.self, from: coordinateData4))

        let coordinateData5 =  try XCTUnwrap("[,15]".data(using: .utf8))
        XCTAssertThrowsError(try JSONDecoder().decode(Coordinate3D.self, from: coordinateData5))
    }

    func testDecodableInvalidNull() throws {
        let coordinateDataM =  try XCTUnwrap("[10,null,null,1234]".data(using: .utf8))
        XCTAssertThrowsError(try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataM))
    }

    func testDecodableNull() throws {
        let coordinateDataM =  try XCTUnwrap("[10,15,null,1234]".data(using: .utf8))
        let coordinateDataZ =  try XCTUnwrap("[10,15,500]".data(using: .utf8))
        let coordinateDataZM =  try XCTUnwrap("[10,15,500,null]".data(using: .utf8))

        let decodedCoordinateM = try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataM)
        let decodedCoordinateZ = try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataZ)
        let decodedCoordinateZM = try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataZM)

        XCTAssertEqual(decodedCoordinateM.asJson, [10.0, 15.0, nil, 1234])
        XCTAssertEqual(decodedCoordinateZ.asJson, [10.0, 15.0, 500])
        XCTAssertEqual(decodedCoordinateZM.asJson, [10.0, 15.0, 500])
    }

}
