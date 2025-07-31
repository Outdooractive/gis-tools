import Foundation
@testable import GISTools
import Testing

struct CoordinateTests {

    @Test
    func coordinate3DDescription() async throws {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0)
        #expect(coordinate.description == "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0)")

        let coordinateZ = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0)
        #expect(coordinateZ.description == "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0, altitude: 500.0)")

        let coordinateM = Coordinate3D(latitude: 15.0, longitude: 10.0, m: 1234)
        #expect(coordinateM.description == "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0, m: 1234.0)")

        let coordinateZM = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: 1234)
        #expect(coordinateZM.description == "Coordinate3D<EPSG:4326>(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: 1234.0)")
    }

    @Test
    func coordinateXYDescription() async throws {
        let coordinate = Coordinate3D(x: 10.0, y: 15.0)
        #expect(coordinate.description == "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0)")

        let coordinateZ = Coordinate3D(x: 10.0, y: 15.0, z: 500.0)
        #expect(coordinateZ.description == "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0, z: 500.0)")

        let coordinateM = Coordinate3D(x: 10.0, y: 15.0, m: 1234)
        #expect(coordinateM.description == "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0, m: 1234.0)")

        let coordinateZM = Coordinate3D(x: 10.0, y: 15.0, z: 500.0, m: 1234)
        #expect(coordinateZM.description == "Coordinate3D<EPSG:3857>(x: 10.0, y: 15.0, z: 500.0, m: 1234.0)")
    }

    @Test
    func encodable() async throws {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0)
        let coordinateData = try JSONEncoder().encode(coordinate)

        #expect(String(data: coordinateData, encoding: .utf8) == "[10,15]")
    }

    @Test
    func encodableNull() async throws {
        let coordinateM = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: nil, m: 1234)
        let coordinateZ = Coordinate3D(latitude: 15.0, longitude: 10.0, altitude: 500.0, m: nil)

        let coordinateDataM = try JSONEncoder().encode(coordinateM)
        let coordinateDataZ = try JSONEncoder().encode(coordinateZ)

        #expect(String(data: coordinateDataM, encoding: .utf8) == "[10,15,null,1234]")
        #expect(String(data: coordinateDataZ, encoding: .utf8) == "[10,15,500]")

        #expect(coordinateM.asMinimalJson == [10, 15])
        #expect(coordinateZ.asMinimalJson == [10, 15, 500])
    }

    @Test
    func encodable3857() async throws {
        let coordinate = Coordinate3D(latitude: 15.0, longitude: 10.0).projected(to: .epsg3857)
        let coordinateData = try JSONEncoder().encode(coordinate)
        let decodedCoordinate = try JSONDecoder().decode(Coordinate3D.self, from: coordinateData)

        #expect(abs(Double(decodedCoordinate.asJson[0]!) - 10.0) < 0.000001)
        #expect(abs(Double(decodedCoordinate.asJson[1]!) - 15.0) < 0.000001)
    }

    @Test
    func decodable() async throws {
        let coordinateData = try #require("[10,15]".data(using: .utf8))
        let decodedCoordinate = try JSONDecoder().decode(Coordinate3D.self, from: coordinateData)

        #expect(decodedCoordinate.asJson == [10.0, 15.0])
    }

    @Test
    func JSONDictionary() async throws {
        let decodedCoordinate = try #require(Coordinate3D(json: [
            "x": 10.0,
            "y": 15.0,
        ]))

        #expect(decodedCoordinate.asJson == [10.0, 15.0])
    }

    @Test
    func decodableInvalid() async throws {
        let coordinateData1 =  try #require("[10]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateData1)
        }

        let coordinateData2 =  try #require("[10,]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateData2)
        }

        let coordinateData3 =  try #require("[null,null]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateData3)
        }

        let coordinateData4 =  try #require("[]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateData4)
        }

        let coordinateData5 =  try #require("[,15]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateData5)
        }
    }

    @Test
    func JSONDictionaryInvalid() async throws {
        #expect(Coordinate3D(json: [
            "x": 10.0,
        ]) == nil)

        #expect(Coordinate3D(json: [
            "y": 15.0,
        ]) == nil)

        #expect(Coordinate3D(json: []) == nil)

        #expect(Coordinate3D(json: [
            "x": 10.0,
            "y": nil,
        ]) == nil)

        #expect(Coordinate3D(json: [
            "x": 10.0,
            "y": NSNull(),
        ]) == nil)
    }

    @Test
    func decodableInvalidNull() async throws {
        let coordinateDataM =  try #require("[10,null,null,1234]".data(using: .utf8))
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataM)
        }
    }

    @Test
    func decodableNull() async throws {
        let coordinateDataM =  try #require("[10,15,null,1234]".data(using: .utf8))
        let coordinateDataZ =  try #require("[10,15,500]".data(using: .utf8))
        let coordinateDataZM =  try #require("[10,15,500,null]".data(using: .utf8))

        let decodedCoordinateM = try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataM)
        let decodedCoordinateZ = try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataZ)
        let decodedCoordinateZM = try JSONDecoder().decode(Coordinate3D.self, from: coordinateDataZM)

        #expect(decodedCoordinateM.asJson == [10.0, 15.0, nil, 1234])
        #expect(decodedCoordinateM.asMinimalJson == [10.0, 15.0])
        #expect(decodedCoordinateZ.asJson == [10.0, 15.0, 500])
        #expect(decodedCoordinateZM.asJson == [10.0, 15.0, 500])
    }

    @Test
    func equalityWithAltitude() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 100.0)
        let b = Coordinate3D(latitude: -100.0, longitude: -100.0, altitude: 100.0)
        let c = Coordinate3D(latitude: 10.0, longitude: 10.0, altitude: 99.0)

        #expect(a == a)
        #expect(a != b)
        #expect(a != c)
        #expect(b != c)

        #expect(a.equals(other: a, includingAltitude: false))
        #expect(a.equals(other: a, includingAltitude: true))
        #expect(a.equals(other: c, includingAltitude: false))
        #expect(a.equals(other: c, includingAltitude: true) == false)
        #expect(a.equals(other: c, includingAltitude: true, altitudeDelta: 1.0))
        #expect(a.equals(other: c, includingAltitude: true, altitudeDelta: 0.5) == false)

        #expect(a.equals(other: b, includingAltitude: false) == false)
        #expect(a.equals(other: b, includingAltitude: true) == false)
    }

    @Test
    func equalityWithoutAltitude() async throws {
        let a = Coordinate3D(latitude: 10.0, longitude: 10.0)
        let b = Coordinate3D(latitude: -100.0, longitude: -100.0)

        #expect(a == a)
        #expect(a.equals(other: a, includingAltitude: false))
        #expect(a.equals(other: a, includingAltitude: true))
        #expect(a != b)
        #expect(a.equals(other: b, includingAltitude: false) == false)
        #expect(a.equals(other: b, includingAltitude: true) == false)
    }

}
