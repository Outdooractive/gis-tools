@testable import GISTools
import XCTest

final class RewindTests: XCTestCase {

    private static let lineStringClockwise = LineString([
        Coordinate3D(latitude: -20.0, longitude: 122.0),
        Coordinate3D(latitude: -15.0, longitude: 126.0),
        Coordinate3D(latitude: -14.0, longitude: 129.0),
        Coordinate3D(latitude: -15.0, longitude: 134.0),
        Coordinate3D(latitude: -20.0, longitude: 138.0),
        Coordinate3D(latitude: -25.0, longitude: 139.0),
        Coordinate3D(latitude: -30.0, longitude: 134.0),
        Coordinate3D(latitude: -30.0, longitude: 131.0),
        Coordinate3D(latitude: -29.0, longitude: 128.0),
        Coordinate3D(latitude: -27.0, longitude: 124.0),
    ])!

    private static let lineStringCounterClockwise = LineString([
        Coordinate3D(latitude: -27.0, longitude: 124.0),
        Coordinate3D(latitude: -29.0, longitude: 128.0),
        Coordinate3D(latitude: -30.0, longitude: 131.0),
        Coordinate3D(latitude: -30.0, longitude: 134.0),
        Coordinate3D(latitude: -25.0, longitude: 139.0),
        Coordinate3D(latitude: -20.0, longitude: 138.0),
        Coordinate3D(latitude: -15.0, longitude: 134.0),
        Coordinate3D(latitude: -14.0, longitude: 129.0),
        Coordinate3D(latitude: -15.0, longitude: 126.0),
        Coordinate3D(latitude: -20.0, longitude: 122.0),
    ])!

    private static let polygonClockwise = Polygon([[
        Coordinate3D(latitude: 0.0, longitude: 0.0),
        Coordinate3D(latitude: 1.0, longitude: 1.0),
        Coordinate3D(latitude: 0.0, longitude: 1.0),
        Coordinate3D(latitude: 0.0, longitude: 0.0),
    ]])!

    private static let polygonCounterClockwise = Polygon([[
        Coordinate3D(latitude: 0.0, longitude: 0.0),
        Coordinate3D(latitude: 0.0, longitude: 1.0),
        Coordinate3D(latitude: 1.0, longitude: 1.0),
        Coordinate3D(latitude: 0.0, longitude: 0.0),
    ]])!

    // MARK: -

    func testLineStringClockwise() {
        let lineStringRewinded = RewindTests.lineStringClockwise.rewinded
        XCTAssertEqual(lineStringRewinded, RewindTests.lineStringClockwise)
    }

    func testLineStringCounterClockwise() {
        let lineStringRewinded = RewindTests.lineStringCounterClockwise.rewinded
        XCTAssertEqual(lineStringRewinded.allCoordinates, RewindTests.lineStringClockwise.allCoordinates)
    }

    func testPolygonClockwise() {
        let polygonRewinded = RewindTests.polygonClockwise.rewinded
        XCTAssertEqual(polygonRewinded.allCoordinates, RewindTests.polygonCounterClockwise.allCoordinates)
    }

    func testPolygonCounterClockwise() {
        let polygonRewinded = RewindTests.polygonCounterClockwise.rewinded
        XCTAssertEqual(polygonRewinded, RewindTests.polygonCounterClockwise)
    }

    func testFeature() {
        let featureRewinded = Feature(RewindTests.lineStringCounterClockwise).rewinded
        let result = Feature(RewindTests.lineStringClockwise)
        XCTAssertEqual(featureRewinded, result)
    }

    func testFeatureCollection() {
        let featureCollectionRewinded = FeatureCollection([
            RewindTests.lineStringClockwise,
            RewindTests.lineStringCounterClockwise,
            RewindTests.polygonClockwise,
            RewindTests.polygonCounterClockwise,
        ]).rewinded
        let result = FeatureCollection([
            RewindTests.lineStringClockwise,
            RewindTests.lineStringClockwise,
            RewindTests.polygonCounterClockwise,
            RewindTests.polygonCounterClockwise,
        ])
        XCTAssertEqual(featureCollectionRewinded, result)
    }

    func testGeometryCollection() {
        let geometryCollectionRewinded = GeometryCollection([
            RewindTests.lineStringClockwise,
            RewindTests.lineStringCounterClockwise,
            RewindTests.polygonClockwise,
            RewindTests.polygonCounterClockwise,
        ]).rewinded
        let result = GeometryCollection([
            RewindTests.lineStringClockwise,
            RewindTests.lineStringClockwise,
            RewindTests.polygonCounterClockwise,
            RewindTests.polygonCounterClockwise,
        ])
        XCTAssertEqual(geometryCollectionRewinded, result)
    }

}
