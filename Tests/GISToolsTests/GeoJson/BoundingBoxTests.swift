@testable import GISTools
import XCTest

final class BoundingBoxTests: XCTestCase {

    // MARK: - contains(_:)

    func testContains() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 30.0))

        let point1 = Coordinate3D(latitude: 15.0, longitude: 15.0)
        let point2 = Coordinate3D(latitude: 45.0, longitude: 15.0)

        XCTAssertTrue(boundingBox.contains(point1))
        XCTAssertFalse(boundingBox.contains(point2))
    }

    func testContainsDateline1() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: -53.8,
                longitude: 155.3),
            northEast: Coordinate3D(
                latitude: -30.1,
                longitude: -174.4))

        let point1 = Coordinate3D(latitude: -45.0, longitude: 178.6)
        let point2 = Coordinate3D(latitude: -60.0, longitude: 178.6)
        let point3 = Coordinate3D(latitude: -45.0, longitude: 184.0)

        XCTAssertTrue(boundingBox.contains(point1))
        XCTAssertFalse(boundingBox.contains(point2))
        XCTAssertTrue(boundingBox.contains(point3))
    }

    func testContainsDateline2() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: -53.8,
                longitude: 155.3),
            northEast: Coordinate3D(
                latitude: -30.1,
                longitude: 188.4))

        let point1 = Coordinate3D(latitude: -45.4, longitude: 178.6)
        let point2 = Coordinate3D(latitude: -60.4, longitude: 178.6)
        let point3 = Coordinate3D(latitude: -45.0, longitude: -178.6)
        let point4 = Coordinate3D(latitude: -45.0, longitude: 184.0)

        XCTAssertTrue(boundingBox.contains(point1))
        XCTAssertFalse(boundingBox.contains(point2))
        XCTAssertTrue(boundingBox.contains(point3))
        XCTAssertTrue(boundingBox.contains(point4))
    }

    // MARK: - contains(_:) (rect)

    func testContainsRect() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 30.0))

        let other1 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 10.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 20.0))
        let other2 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 10.0),
            northEast: Coordinate3D(
                latitude: 40.0,
                longitude: 40.0))

        XCTAssertTrue(boundingBox.contains(other1))
        XCTAssertFalse(boundingBox.contains(other2))
    }

    func testContainsRectDateline1() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 160.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 190.0))

        let other1 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 170.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 175.0))
        let other2 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 170.0),
            northEast: Coordinate3D(
                latitude: 40.0,
                longitude: 175.0))
        let other3 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 170.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 185.0))
        let other4 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 170.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: -175.0))
        let other5 = BoundingBox(
            southWest: Coordinate3D(
                latitude: -10.0,
                longitude: -170.0),
            northEast: Coordinate3D(
                latitude: -20.0,
                longitude: -175.0))

        XCTAssertTrue(boundingBox.contains(other1))
        XCTAssertFalse(boundingBox.contains(other2))
        XCTAssertTrue(boundingBox.contains(other3))
        XCTAssertTrue(boundingBox.contains(other4))
        XCTAssertFalse(boundingBox.contains(other5))
    }

    func testContainsRectDateline2() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 160.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: -170.0))

        let other1 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 170.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 175.0))
        let other2 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 170.0),
            northEast: Coordinate3D(
                latitude: 40.0,
                longitude: 175.0))
        let other3 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 170.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 185.0))
        let other4 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 170.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: -175.0))
        let other5 = BoundingBox(
            southWest: Coordinate3D(
                latitude: -10.0,
                longitude: -170.0),
            northEast: Coordinate3D(
                latitude: -20.0,
                longitude: -175.0))

        XCTAssertTrue(boundingBox.contains(other1))
        XCTAssertFalse(boundingBox.contains(other2))
        XCTAssertTrue(boundingBox.contains(other3))
        XCTAssertTrue(boundingBox.contains(other4))
        XCTAssertFalse(boundingBox.contains(other5))
    }

    // MARK: - intersects(_:)

    func testIntersectsRect() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 30.0))

        let other1 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 10.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 20.0))
        let other2 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 10.0),
            northEast: Coordinate3D(
                latitude: 40.0,
                longitude: 40.0))
        let other3 = BoundingBox(
            southWest: Coordinate3D(
                latitude: -10.0,
                longitude: -10.0),
            northEast: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0))
        let other4 = BoundingBox(
            southWest: Coordinate3D(
                latitude: -100.0,
                longitude: -100.0),
            northEast: Coordinate3D(
                latitude: -80.0,
                longitude: -80.0))

        XCTAssertTrue(boundingBox.intersects(other1))
        XCTAssertTrue(boundingBox.intersects(other2))
        XCTAssertTrue(boundingBox.intersects(other3))
        XCTAssertFalse(boundingBox.intersects(other4))
    }

    func testIntersectsRectDateline1() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 160.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: -160.0))

        let other1 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 10.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 20.0))
        let other2 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 10.0),
            northEast: Coordinate3D(
                latitude: 40.0,
                longitude: 170.0))
        let other3 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 185.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 190.0))
        let other4 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 170.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: -175.0))

        XCTAssertFalse(boundingBox.intersects(other1))
        XCTAssertTrue(boundingBox.intersects(other2))
        XCTAssertTrue(boundingBox.intersects(other3))
        XCTAssertTrue(boundingBox.intersects(other4))
    }

    // MARK: - intersection(_:)

    func testIntersection() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 30.0))

        let other1 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 10.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 20.0))
        let other2 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 10.0),
            northEast: Coordinate3D(
                latitude: 40.0,
                longitude: 40.0))
        let other2Result = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 10.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 30.0))
        let other3 = BoundingBox(
            southWest: Coordinate3D(
                latitude: -10.0,
                longitude: -10.0),
            northEast: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0))
        let other3Result = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0))
        let other4 = BoundingBox(
            southWest: Coordinate3D(
                latitude: -100.0,
                longitude: -100.0),
            northEast: Coordinate3D(
                latitude: -80.0,
                longitude: -80.0))

        XCTAssertEqual(boundingBox.intersection(other1), other1)
        XCTAssertEqual(boundingBox.intersection(other2), other2Result)
        XCTAssertEqual(boundingBox.intersection(other3), other3Result)
        XCTAssertNil(boundingBox.intersection(other4))
    }

    func testIntersectionRectDateline1() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 160.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: -160.0))

        let other1 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 10.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 20.0))
        let other2 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 10.0),
            northEast: Coordinate3D(
                latitude: 40.0,
                longitude: 170.0))
        let other2Result = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 160.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 170.0))
        let other3 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 185.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 190.0))
        let other3Result = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: -175.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: -170.0))
        let other4 = BoundingBox(
            southWest: Coordinate3D(
                latitude: 10.0,
                longitude: 170.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: -175.0))

        XCTAssertNil(boundingBox.intersection(other1))
        XCTAssertEqual(boundingBox.intersection(other2), other2Result)
        XCTAssertEqual(boundingBox.intersection(other3), other3Result)
        XCTAssertEqual(boundingBox.intersection(other4), other4)
    }

    // MARK: - center

    func testCenter() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 20.0))
        let center = Coordinate3D(latitude: 10.150932342575627, longitude: 9.685895184381804)

        let point = boundingBox.center
        XCTAssertTrue(point == center, "\(point) != \(center)")
    }

    func testCenterDateline1() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 160.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 190.0))
        let center = Coordinate3D(latitude: 15.501359566937001, longitude: 173.897886248014)

        let point = boundingBox.center
        XCTAssertTrue(point == center, "\(point) != \(center)")
    }

    func testCenterDateline2() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 160.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: -170.0))
        let center = Coordinate3D(latitude: 15.501359566937001, longitude: 173.897886248014)

        let point = boundingBox.center
        XCTAssertTrue(point == center, "\(point) != \(center)")
    }

    func testEncodable() throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 20.0))
        let boundingBoxData = try JSONEncoder().encode(boundingBox)

        XCTAssertEqual(String(data: boundingBoxData, encoding: .utf8), "[0,0,20,20]")
    }

    func testDecodable() throws {
        let boundingBoxData =  try XCTUnwrap("[0,0,20,20]".data(using: .utf8))
        let decodedBoundingBox = try JSONDecoder().decode(BoundingBox.self, from: boundingBoxData)

        XCTAssertEqual(decodedBoundingBox.asJson, [0, 0, 20, 20])
    }

    // MARK: - Clamp

    func testClamped() throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: -95.0,
                longitude: -200.0),
            northEast: Coordinate3D(
                latitude: 120.0,
                longitude: 220.0))
        let clamped = boundingBox.clamped()

        XCTAssertEqual(clamped, BoundingBox.world)
    }

}
