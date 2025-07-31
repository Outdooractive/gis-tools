import Foundation
@testable import GISTools
import Testing

struct BoundingBoxTests {

    // MARK: - Projection

    @Test
    func projection() async throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 30.0))
        #expect(boundingBox.projection == .epsg4326)

        let boundingBox3857 = boundingBox.projected(to: .epsg3857)
        #expect(boundingBox3857.projection == .epsg3857)
        #expect(boundingBox3857.southWest.projection == .epsg3857)
        #expect(boundingBox3857.northEast.projection == .epsg3857)
    }

    @Test
    func initWithCoordinatesEPSG4326() async throws {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 30.0, longitude: 30.0)

        let boundingBox: BoundingBox = try #require(BoundingBox(coordinates: [coordinate1, coordinate2]))
        #expect(boundingBox.projection == .epsg4326)
        #expect(boundingBox.southWest.projection == .epsg4326)
        #expect(boundingBox.northEast.projection == .epsg4326)
    }

    @Test
    func initWithCoordinatesEPSG3857() async throws {
        let coordinate1 = Coordinate3D(x: -7_903_683.846322424, y: 5_012_341.663847514)
        let coordinate2 = Coordinate3D(x: -10_859_458.446776, y: 4_235_169.496066)

        let boundingBox: BoundingBox = try #require(BoundingBox(coordinates: [coordinate1, coordinate2]))
        #expect(boundingBox.projection == .epsg3857)
        #expect(boundingBox.southWest.projection == .epsg3857)
        #expect(boundingBox.northEast.projection == .epsg3857)
    }

    // MARK: - contains(_:)

    @Test
    func contains() async throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 30.0))

        let point1 = Coordinate3D(latitude: 15.0, longitude: 15.0)
        let point2 = Coordinate3D(latitude: 45.0, longitude: 15.0)

        #expect(boundingBox.contains(point1))
        #expect(boundingBox.contains(point2) == false)
    }

    @Test
    func containsDateline1() async throws {
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

        #expect(boundingBox.contains(point1))
        #expect(boundingBox.contains(point2) == false)
        #expect(boundingBox.contains(point3))
    }

    @Test
    func containsDateline2() async throws {
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

        #expect(boundingBox.contains(point1))
        #expect(boundingBox.contains(point2) == false)
        #expect(boundingBox.contains(point3))
        #expect(boundingBox.contains(point4))
    }

    // MARK: - contains(_:) (rect)

    @Test
    func containsRect() async throws {
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

        #expect(boundingBox.contains(other1))
        #expect(boundingBox.contains(other2) == false)
    }

    @Test
    func containsRectDateline1() async throws {
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

        #expect(boundingBox.contains(other1))
        #expect(boundingBox.contains(other2) == false)
        #expect(boundingBox.contains(other3))
        #expect(boundingBox.contains(other4))
        #expect(boundingBox.contains(other5) == false)
    }

    @Test
    func containsRectDateline2() async throws {
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

        #expect(boundingBox.contains(other1))
        #expect(boundingBox.contains(other2) == false)
        #expect(boundingBox.contains(other3))
        #expect(boundingBox.contains(other4))
        #expect(boundingBox.contains(other5) == false)
    }

    // MARK: - intersects(_:)

    @Test
    func intersectsRect() async throws {
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

        #expect(boundingBox.intersects(other1))
        #expect(boundingBox.intersects(other2))
        #expect(boundingBox.intersects(other3))
        #expect(boundingBox.intersects(other4) == false)
    }

    @Test
    func intersectsRectDateline1() async throws {
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

        #expect(boundingBox.intersects(other1) == false)
        #expect(boundingBox.intersects(other2))
        #expect(boundingBox.intersects(other3))
        #expect(boundingBox.intersects(other4))
    }

    // MARK: - intersection(_:)

    @Test
    func intersection() async throws {
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

        #expect(boundingBox.intersection(other1) == other1)
        #expect(boundingBox.intersection(other2) == other2Result)
        #expect(boundingBox.intersection(other3) == other3Result)
        #expect(boundingBox.intersection(other4) == nil)
    }

    @Test
    func intersectionRectDateline1() async throws {
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

        #expect(boundingBox.intersection(other1) == nil)
        #expect(boundingBox.intersection(other2) == other2Result)
        #expect(boundingBox.intersection(other3) == other3Result)
        #expect(boundingBox.intersection(other4) == other4)
    }

    // MARK: - center

    @Test
    func center() async throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 20.0))
        let center = Coordinate3D(latitude: 10.150932342575627, longitude: 9.685895184381804)

        let point = boundingBox.center
        #expect(point == center)
    }

    @Test
    func centerDateline1() async throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 160.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: 190.0))
        let center = Coordinate3D(latitude: 15.501359566937001, longitude: 173.897886248014)

        let point = boundingBox.center
        #expect(point == center)
    }

    @Test
    func centerDateline2() async throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 160.0),
            northEast: Coordinate3D(
                latitude: 30.0,
                longitude: -170.0))
        let center = Coordinate3D(latitude: 15.501359566937001, longitude: 173.897886248014)

        let point = boundingBox.center
        #expect(point == center)
    }

    @Test
    func encodable() async throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: 0.0,
                longitude: 0.0),
            northEast: Coordinate3D(
                latitude: 20.0,
                longitude: 20.0))
        let boundingBoxData = try JSONEncoder().encode(boundingBox)

        #expect(String(data: boundingBoxData, encoding: .utf8) == "[0,0,20,20]")
    }

    @Test
    func decodable() async throws {
        let boundingBoxData =  try #require("[0,0,20,20]".data(using: .utf8))
        let decodedBoundingBox = try JSONDecoder().decode(BoundingBox.self, from: boundingBoxData)

        #expect(decodedBoundingBox.asJson == [0, 0, 20, 20])
    }

    // MARK: - Clamp

    @Test
    func clamped() async throws {
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(
                latitude: -95.0,
                longitude: -200.0),
            northEast: Coordinate3D(
                latitude: 120.0,
                longitude: 220.0))
        let clamped = boundingBox.clamped()

        #expect(clamped == BoundingBox.world)
    }

    // MARK: - Expanding

    @Test
    func expanding() async throws {
        let bbox1 = try #require(BoundingBox(coordinates: [.zero]))
        let bbox1_3857 = bbox1.projected(to: .epsg3857)

        // Note: Expands diagonally
        let bbox2_3857_distance = bbox1_3857.expanded(byDistance: 1000.0)
        let bbox2_degrees = bbox1.expanded(byDegrees: 1.0)

        #expect(abs(Coordinate3D.zero.distance(from: bbox2_3857_distance.southWest) - 1000.0) < 0.00001)
        #expect(abs(Coordinate3D.zero.distance(from: bbox2_3857_distance.northEast) - 1000.0) < 0.00001)
        #expect(bbox2_degrees.southWest == Coordinate3D(latitude: -1.0, longitude: -1.0))
        #expect(bbox2_degrees.northEast == Coordinate3D(latitude: 1.0, longitude: 1.0))

        let bbox2_distance = bbox1.expanded(byDistance: 1000.0)
        let bbox2_3857_degrees = bbox1_3857.expanded(byDegrees: 1.0)

        #expect(bbox2_distance.projected(to: .epsg3857) == bbox2_3857_distance)
        #expect(bbox2_degrees == bbox2_3857_degrees.projected(to: .epsg4326))

        // Note: Expanded horizontally and vertically
        let bbox3_3857 = try #require(BoundingBox(coordinates: [.zero.projected(to: .epsg3857)], padding: 1000.0))
        let bbox3_4326 = try #require(BoundingBox(coordinates: [.zero], padding: 1000.0))

        #expect(abs(bbox3_3857.southWest.x - -1000.0) < 0.00001)
        #expect(abs(bbox3_3857.southWest.y - -1000.0) < 0.00001)
        #expect(abs(bbox3_3857.northEast.x - 1000.0) < 0.00001)
        #expect(abs(bbox3_3857.northEast.x - 1000.0) < 0.00001)
        #expect(abs(bbox3_4326.projected(to: .epsg3857).southWest.x - bbox3_3857.southWest.x) < 0.00001)
        #expect(abs(bbox3_4326.projected(to: .epsg3857).southWest.y - bbox3_3857.southWest.y) < 0.00001)
        #expect(abs(bbox3_4326.projected(to: .epsg3857).northEast.x - bbox3_3857.northEast.x) < 0.00001)
        #expect(abs(bbox3_4326.projected(to: .epsg3857).northEast.y - bbox3_3857.northEast.y) < 0.00001)
    }

}
