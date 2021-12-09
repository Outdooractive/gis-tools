#if !os(Linux)
import CoreLocation
#endif
import Foundation
import XCTest

@testable import GISTools

final class ReverseTests: XCTestCase {

    func testLineString() {
        let lineString = LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 2.0, longitude: 2.0),
            Coordinate3D(latitude: 3.0, longitude: 3.0),
            Coordinate3D(latitude: 4.0, longitude: 4.0),
            Coordinate3D(latitude: 5.0, longitude: 5.0)
        ])!
        let lineStringReversed = lineString.reversed
        XCTAssertEqual(lineStringReversed.coordinates.map({ $0.latitude }), [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])

        let multiLineString = MultiLineString([
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 3.0, longitude: 3.0),
                Coordinate3D(latitude: 4.0, longitude: 4.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0)
            ],
            [
                Coordinate3D(latitude: 0.0, longitude: 0.0),
                Coordinate3D(latitude: 1.0, longitude: 1.0),
                Coordinate3D(latitude: 2.0, longitude: 2.0),
                Coordinate3D(latitude: 3.0, longitude: 3.0),
                Coordinate3D(latitude: 4.0, longitude: 4.0),
                Coordinate3D(latitude: 5.0, longitude: 5.0)
            ]
        ])!
        let multiLineStringReversed = multiLineString.reversed
        XCTAssertEqual(multiLineStringReversed.lineStrings[0].coordinates.map({ $0.latitude }), [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])
        XCTAssertEqual(multiLineStringReversed.lineStrings[1].coordinates.map({ $0.latitude }), [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])
    }

    func testFeatureCollection() {
        let featureCollection = FeatureCollection([
            Feature(
                LineString([
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                    Coordinate3D(latitude: 1.0, longitude: 1.0),
                    Coordinate3D(latitude: 2.0, longitude: 2.0),
                    Coordinate3D(latitude: 3.0, longitude: 3.0),
                    Coordinate3D(latitude: 4.0, longitude: 4.0),
                    Coordinate3D(latitude: 5.0, longitude: 5.0)
                ])!),
            Feature(Point(Coordinate3D(latitude: 20.0, longitude: 20.0))),
            Feature(MultiLineString([
                [
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                    Coordinate3D(latitude: 1.0, longitude: 1.0),
                    Coordinate3D(latitude: 2.0, longitude: 2.0),
                    Coordinate3D(latitude: 3.0, longitude: 3.0),
                    Coordinate3D(latitude: 4.0, longitude: 4.0),
                    Coordinate3D(latitude: 5.0, longitude: 5.0)
                ],
                [
                    Coordinate3D(latitude: 0.0, longitude: 0.0),
                    Coordinate3D(latitude: 1.0, longitude: 1.0),
                    Coordinate3D(latitude: 2.0, longitude: 2.0),
                    Coordinate3D(latitude: 3.0, longitude: 3.0),
                    Coordinate3D(latitude: 4.0, longitude: 4.0),
                    Coordinate3D(latitude: 5.0, longitude: 5.0)
                ]
            ])!),
            Feature(Point(Coordinate3D(latitude: 40.0, longitude: 40.0))),
        ])
        let reversed = featureCollection.reversed

        XCTAssertEqual(reversed.features.map({ $0.geometry.type }), [.point, .multiLineString, .point, .lineString])

        XCTAssertEqual(reversed.features[3].allCoordinates.map({ $0.latitude }), [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])
        XCTAssertEqual(reversed.features[2].allCoordinates, [Coordinate3D(latitude: 20.0, longitude: 20.0)])
        XCTAssertEqual((reversed.features[1].geometry as? MultiLineString)?.lineStrings[0].coordinates.map({ $0.latitude }), [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])
        XCTAssertEqual((reversed.features[1].geometry as? MultiLineString)?.lineStrings[1].coordinates.map({ $0.latitude }), [5.0, 4.0, 3.0, 2.0, 1.0, 0.0])
        XCTAssertEqual(reversed.features[0].allCoordinates, [Coordinate3D(latitude: 40.0, longitude: 40.0)])
    }

    static var allTests = [
        ("testLineString", testLineString),
        ("testFeatureCollection", testFeatureCollection),
    ]

}
