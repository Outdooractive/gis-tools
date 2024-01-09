@testable import GISTools
import XCTest

final class BoundingBoxTests: XCTestCase {

    // MARK: - Projection

    func testProjection() {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 30.0))
        XCTAssertEqual(boundingBox.projection, .epsg4326)

        let boundingBox3857 = boundingBox.projected(to: .epsg3857)
        XCTAssertEqual(boundingBox3857.projection, .epsg3857)
        XCTAssertEqual(boundingBox3857.southWest.projection, .epsg3857)
        XCTAssertEqual(boundingBox3857.northEast.projection, .epsg3857)
    }

    func testInitWithCoordinatesEPSG4326() throws {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 30.0, longitude: 30.0)

        let boundingBox: BoundingBox = try XCTUnwrap(BoundingBox(coordinates: [coordinate1, coordinate2]))
        XCTAssertEqual(boundingBox.projection, .epsg4326)
        XCTAssertEqual(boundingBox.southWest.projection, .epsg4326)
        XCTAssertEqual(boundingBox.northEast.projection, .epsg4326)
    }

    func testInitWithCoordinatesEPSG3857() throws {
        let coordinate1 = Coordinate3D(x: -7_903_683.846322424, y: 5_012_341.663847514)
        let coordinate2 = Coordinate3D(x: -10_859_458.446776, y: 4_235_169.496066)

        let boundingBox: BoundingBox = try XCTUnwrap(BoundingBox(coordinates: [coordinate1, coordinate2]))
        XCTAssertEqual(boundingBox.projection, .epsg3857)
        XCTAssertEqual(boundingBox.southWest.projection, .epsg3857)
        XCTAssertEqual(boundingBox.northEast.projection, .epsg3857)
    }

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
        XCTAssertEqual(point, center)
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
        XCTAssertEqual(point, center)
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
        XCTAssertEqual(point, center)
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

    // MARK: - Expanding

    func testExpanding() throws {
        let bbox1 = try XCTUnwrap(BoundingBox(coordinates: [.zero]))
        let bbox1_3857 = bbox1.projected(to: .epsg3857)

        // Note: Expands diagonally
        let bbox2_3857_distance = bbox1_3857.expanded(byDistance: 1000.0)
        let bbox2_degrees = bbox1.expanded(byDegrees: 1.0)

        XCTAssertEqual(Coordinate3D.zero.distance(from: bbox2_3857_distance.southWest), 1000.0, accuracy: 0.00001)
        XCTAssertEqual(Coordinate3D.zero.distance(from: bbox2_3857_distance.northEast), 1000.0, accuracy: 0.00001)
        XCTAssertEqual(bbox2_degrees.southWest, Coordinate3D(latitude: -1.0, longitude: -1.0))
        XCTAssertEqual(bbox2_degrees.northEast, Coordinate3D(latitude: 1.0, longitude: 1.0))

        let bbox2_distance = bbox1.expanded(byDistance: 1000.0)
        let bbox2_3857_degrees = bbox1_3857.expanded(byDegrees: 1.0)

        XCTAssertEqual(bbox2_distance.projected(to: .epsg3857), bbox2_3857_distance)
        XCTAssertEqual(bbox2_degrees, bbox2_3857_degrees.projected(to: .epsg4326))

        // Note: Expanded horizontally and vertically
        let bbox3_3857 = try XCTUnwrap(BoundingBox(coordinates: [.zero.projected(to: .epsg3857)], padding: 1000.0))
        let bbox3_4326 = try XCTUnwrap(BoundingBox(coordinates: [.zero], padding: 1000.0))

        XCTAssertEqual(bbox3_3857.southWest.x, -1000.0, accuracy: 0.00001)
        XCTAssertEqual(bbox3_3857.southWest.y, -1000.0, accuracy: 0.00001)
        XCTAssertEqual(bbox3_3857.northEast.x, 1000.0, accuracy: 0.00001)
        XCTAssertEqual(bbox3_3857.northEast.x, 1000.0, accuracy: 0.00001)
        XCTAssertEqual(bbox3_4326.projected(to: .epsg3857).southWest.x, bbox3_3857.southWest.x, accuracy: 0.00001)
        XCTAssertEqual(bbox3_4326.projected(to: .epsg3857).southWest.y, bbox3_3857.southWest.y, accuracy: 0.00001)
        XCTAssertEqual(bbox3_4326.projected(to: .epsg3857).northEast.x, bbox3_3857.northEast.x, accuracy: 0.00001)
        XCTAssertEqual(bbox3_4326.projected(to: .epsg3857).northEast.y, bbox3_3857.northEast.y, accuracy: 0.00001)
    }

}
