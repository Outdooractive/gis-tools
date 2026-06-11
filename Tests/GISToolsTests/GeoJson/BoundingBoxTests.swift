import Foundation
@testable import GISTools
import Testing

struct BoundingBoxTests {

    // MARK: - Projection

    // Validates that projecting a bounding box correctly updates the projection property for both the box and its corners.
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

    // Validates that initializing a bounding box with EPSG:4326 coordinates sets the correct projection.
    @Test
    func initWithCoordinatesEPSG4326() async throws {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 30.0, longitude: 30.0)

        let boundingBox: BoundingBox = try #require(BoundingBox(coordinates: [coordinate1, coordinate2]))
        #expect(boundingBox.projection == .epsg4326)
        #expect(boundingBox.southWest.projection == .epsg4326)
        #expect(boundingBox.northEast.projection == .epsg4326)
    }

    // Validates that initializing a bounding box with EPSG:3857 coordinates sets the correct projection.
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

    // Validates that `contains` correctly determines whether a coordinate lies within the bounding box.
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

    // Validates that `contains` handles coordinates correctly when the bounding box crosses the anti-meridian with longitude > 180.
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

    // Validates that `contains` handles coordinates correctly when the bounding box crosses the anti-meridian with normalized longitude.
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

    // Validates that `contains` correctly determines whether another bounding box is fully contained.
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

    // Validates that `contains` correctly determines containment of another bounding box across the anti-meridian.
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

    // Validates that `contains` handles containment of another bounding box across the anti-meridian with normalized longitude.
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

    // Validates that `intersects` correctly determines whether two bounding boxes overlap.
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

    // Validates that `intersects` correctly determines overlap of bounding boxes across the anti-meridian.
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

    // Validates that `intersection` computes the overlapping region of two bounding boxes.
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

    // Validates that `intersection` correctly computes overlap of bounding boxes across the anti-meridian.
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

    // Validates that `center` returns the correct geographic center of a bounding box.
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

    // Validates that `center` computes the correct center when the bounding box crosses the anti-meridian with longitude > 180.
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

    // Validates that `center` computes the correct center when the bounding box crosses the anti-meridian with normalized longitude.
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

    // Validates that a bounding box encodes to the expected JSON array format.
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

    // Validates that a bounding box decodes correctly from a JSON array.
    @Test
    func decodable() async throws {
        let boundingBoxData =  try #require("[0,0,20,20]".data(using: .utf8))
        let decodedBoundingBox = try JSONDecoder().decode(BoundingBox.self, from: boundingBoxData)

        #expect(decodedBoundingBox.asJson == [0, 0, 20, 20])
    }

    // MARK: - Clamp

    // Validates that `clamped()` constrains a bounding box to within world bounds.
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

    // Validates that a bounding box can be expanded by distance and by degrees in both coordinate systems.
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

    // MARK: - boundingBoxGeometry

    // Validates that a non-wrapping bounding box produces a Polygon geometry.
    @Test
    func boundingBoxGeometryNormal() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let geometry = bbox.boundingBoxGeometry
        #expect(geometry is Polygon)

        let polygon = geometry as! Polygon
        #expect(polygon.coordinates.count == 1)
    }

    // Validates that a bounding box crossing the anti-meridian produces a MultiPolygon with two polygons.
    @Test
    func boundingBoxGeometryAntimeridian() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 40.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 50.0, longitude: -170.0))

        #expect(bbox.crossesAntiMeridian)

        let geometry = bbox.boundingBoxGeometry
        #expect(geometry is MultiPolygon)

        let multiPolygon = geometry as! MultiPolygon
        #expect(multiPolygon.polygons.count == 2)

        // Right polygon: from 170° to 180°
        let rightPolygon = multiPolygon.polygons[0]
        let rightCoords = rightPolygon.coordinates[0]
        #expect(rightCoords[0] == Coordinate3D(latitude: 40.0, longitude: 180.0))
        #expect(rightCoords[1] == Coordinate3D(latitude: 50.0, longitude: 180.0))
        #expect(rightCoords[2] == Coordinate3D(latitude: 50.0, longitude: 170.0))
        #expect(rightCoords[3] == Coordinate3D(latitude: 40.0, longitude: 170.0))

        // Left polygon: from -170° to -180°
        let leftPolygon = multiPolygon.polygons[1]
        let leftCoords = leftPolygon.coordinates[0]
        #expect(leftCoords[0] == Coordinate3D(latitude: 40.0, longitude: -170.0))
        #expect(leftCoords[1] == Coordinate3D(latitude: 50.0, longitude: -170.0))
        #expect(leftCoords[2] == Coordinate3D(latitude: 50.0, longitude: -180.0))
        #expect(leftCoords[3] == Coordinate3D(latitude: 40.0, longitude: -180.0))
    }

    // Validates that a bounding box crossing the anti-meridian produces a MultiPolygon with two polygons (asymmetric bbox).
    @Test
    func boundingBoxGeometryAntimeridian2() async throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -53.8, longitude: 155.3),
            northEast: Coordinate3D(latitude: -30.1, longitude: -174.4))

        #expect(bbox.crossesAntiMeridian)

        let geometry = bbox.boundingBoxGeometry
        #expect(geometry is MultiPolygon)

        let multiPolygon = geometry as! MultiPolygon
        #expect(multiPolygon.polygons.count == 2)
    }

    // Validates that the world bounding box produces a single Polygon and does not cross the anti-meridian.
    @Test
    func boundingBoxGeometryWorld() async throws {
        #expect(BoundingBox.world.crossesAntiMeridian == false)
        let geometry = BoundingBox.world.boundingBoxGeometry
        #expect(geometry is Polygon)
    }

}
