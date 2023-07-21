@testable import GISTools
import XCTest

final class MapTileTests: XCTestCase {

    func testTileFromCoordinate() {
        XCTAssertEqual(MapTile(coordinate: Coordinate3D(latitude: 0.0, longitude: 0.0), atZoom: 0),
                       MapTile(x: 0, y: 0, z: 0))

        XCTAssertEqual(MapTile(coordinate: Coordinate3D(latitude: 84.71, longitude: -178.0), atZoom: 10),
                       MapTile(x: 5, y: 10, z: 10))

        XCTAssertEqual(MapTile(coordinate: Coordinate3D(latitude: 1.0, longitude: 1.0), atZoom: 18),
                       MapTile(x: 131800, y: 130343, z: 18))

        XCTAssertEqual(MapTile(coordinate: Coordinate3D(latitude: -33.8566, longitude: 151.215), atZoom: 14),
                       MapTile(x: 15073, y: 9831, z: 14))

    }

    func testCenter() {
        let coordinate1 = MapTile(x: 138513, y: 91601, z: 18).centerCoordinate()
        XCTAssertEqual(coordinate1.latitude, 47.56031069944929, accuracy: 0.00001)
        XCTAssertEqual(coordinate1.longitude, 10.219345092773441, accuracy: 0.00001)

        let coordinate2 = MapTile(x: 15073, y: 9831, z: 14).centerCoordinate()
        XCTAssertEqual(coordinate2.latitude, -33.86129311351551, accuracy: 0.00001)
        XCTAssertEqual(coordinate2.longitude, 151.20483398437503, accuracy: 0.00001)

        let coordinate3 = MapTile(x: 0, y: 0, z: 0).centerCoordinate()
        XCTAssertEqual(coordinate3.latitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(coordinate3.longitude, 0.0, accuracy: 0.00001)

        // Tiles are not squares...
        let coordinate4 = MapTile(x: 0, y: 0, z: 1).centerCoordinate()
        XCTAssertEqual(coordinate4.latitude, 66.51326044311185, accuracy: 0.00001)
        XCTAssertEqual(coordinate4.longitude, -90.0, accuracy: 0.00001)
    }

    func testTileFromHQCoordinate() {
        let coordinate = Coordinate3D(latitude: 47.56, longitude: 10.22)

        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 0), MapTile(x: 0, y: 0, z: 0))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 1), MapTile(x: 1, y: 0, z: 1))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 2), MapTile(x: 2, y: 1, z: 2))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 3), MapTile(x: 4, y: 2, z: 3))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 4), MapTile(x: 8, y: 5, z: 4))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 5), MapTile(x: 16, y: 11, z: 5))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 6), MapTile(x: 33, y: 22, z: 6))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 7), MapTile(x: 67, y: 44, z: 7))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 8), MapTile(x: 135, y: 89, z: 8))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 9), MapTile(x: 270, y: 178, z: 9))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 10), MapTile(x: 541, y: 357, z: 10))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 11), MapTile(x: 1082, y: 715, z: 11))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 12), MapTile(x: 2164, y: 1431, z: 12))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 13), MapTile(x: 4328, y: 2862, z: 13))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 14), MapTile(x: 8657, y: 5725, z: 14))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 15), MapTile(x: 17314, y: 11450, z: 15))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 16), MapTile(x: 34628, y: 22900, z: 16))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 17), MapTile(x: 69256, y: 45800, z: 17))
        XCTAssertEqual(MapTile(coordinate: coordinate, atZoom: 18), MapTile(x: 138513, y: 91601, z: 18))
    }

    func testParent() {
        XCTAssertEqual(MapTile(x: 0, y: 0, z: 0).parent, MapTile(x: 0, y: 0, z: 0))
        XCTAssertEqual(MapTile(x: 1, y: 0, z: 1).parent, MapTile(x: 0, y: 0, z: 0))
        XCTAssertEqual(MapTile(x: 270, y: 178, z: 9).parent, MapTile(x: 135, y: 89, z: 8))
        XCTAssertEqual(MapTile(x: 138513, y: 91601, z: 18).parent, MapTile(x: 69256, y: 45800, z: 17))
    }

    func testChild() {
        XCTAssertEqual(MapTile(x: 0, y: 0, z: 0).child, MapTile(x: 0, y: 0, z: 1))
        XCTAssertEqual(MapTile(x: 1, y: 0, z: 1).child, MapTile(x: 2, y: 0, z: 2))
        XCTAssertEqual(MapTile(x: 270, y: 178, z: 9).child, MapTile(x: 540, y: 356, z: 10))
        XCTAssertEqual(MapTile(x: 69256, y: 45800, z: 17).child, MapTile(x: 138512, y: 91600, z: 18))
    }

    func testChildren() {
        XCTAssertEqual(MapTile(x: 0, y: 0, z: 0).children, [
            MapTile(x: 0, y: 0, z: 1),
            MapTile(x: 1, y: 0, z: 1),
            MapTile(x: 0, y: 1, z: 1),
            MapTile(x: 1, y: 1, z: 1),
        ])
        XCTAssertEqual(MapTile(x: 270, y: 178, z: 9).children, [
            MapTile(x: 540, y: 356, z: 10),
            MapTile(x: 541, y: 356, z: 10),
            MapTile(x: 540, y: 357, z: 10),
            MapTile(x: 541, y: 357, z: 10),
        ])
    }

    func testEpsg3857TileBounds() {
        let worldBounds = MapTile(x: 0, y: 0, z: 0).boundingBox(projection: .epsg3857)
        XCTAssertEqual(worldBounds.southWest.longitude, -GISTool.originShift, accuracy: 0.00001)
        XCTAssertEqual(worldBounds.southWest.latitude, -GISTool.originShift, accuracy: 0.00001)
        XCTAssertEqual(worldBounds.northEast.longitude, GISTool.originShift, accuracy: 0.00001)
        XCTAssertEqual(worldBounds.northEast.latitude, GISTool.originShift, accuracy: 0.00001)

        let z1Bounds = MapTile(x: 1, y: 0, z: 1).boundingBox(projection: .epsg3857)
        XCTAssertEqual(z1Bounds.southWest.longitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z1Bounds.southWest.latitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z1Bounds.northEast.longitude, GISTool.originShift, accuracy: 0.00001)
        XCTAssertEqual(z1Bounds.northEast.latitude, GISTool.originShift, accuracy: 0.00001)

        let z2Bounds = MapTile(x: 2, y: 1, z: 2).boundingBox(projection: .epsg3857)
        XCTAssertEqual(z2Bounds.southWest.longitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z2Bounds.southWest.latitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z2Bounds.northEast.longitude, GISTool.originShift / 2.0, accuracy: 0.00001)
        XCTAssertEqual(z2Bounds.northEast.latitude, GISTool.originShift / 2.0, accuracy: 0.00001)

        let z3Bounds = MapTile(x: 3, y: 3, z: 3).boundingBox(projection: .epsg3857)
        XCTAssertEqual(z3Bounds.southWest.longitude, -GISTool.originShift / 4.0, accuracy: 0.00001)
        XCTAssertEqual(z3Bounds.southWest.latitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z3Bounds.northEast.longitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z3Bounds.northEast.latitude, GISTool.originShift / 4.0, accuracy: 0.00001)

        let z32Bounds = MapTile(x: 2145960701, y: 1428172928, z: 32).boundingBox(projection: .epsg3857)
        XCTAssertEqual(z32Bounds.southWest.longitude, -14210.149281, accuracy: 0.00001)
        XCTAssertEqual(z32Bounds.southWest.latitude, 6711666.720463, accuracy: 0.00001)
        XCTAssertEqual(z32Bounds.northEast.longitude, -14210.139951, accuracy: 0.00001)
        XCTAssertEqual(z32Bounds.northEast.latitude, 6711666.729793, accuracy: 0.00001)
    }

    func testEpsg4236TileBounds() {
        let worldBounds = MapTile(x: 0, y: 0, z: 0).boundingBox()
        XCTAssertEqual(worldBounds.southWest.longitude, -180.0, accuracy: 0.00001)
        XCTAssertEqual(worldBounds.southWest.latitude, -85.051128, accuracy: 0.00001)
        XCTAssertEqual(worldBounds.northEast.longitude, 180.0, accuracy: 0.00001)
        XCTAssertEqual(worldBounds.northEast.latitude, 85.051128, accuracy: 0.00001)

        let z1Bounds = MapTile(x: 1, y: 0, z: 1).boundingBox()
        XCTAssertEqual(z1Bounds.southWest.longitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z1Bounds.southWest.latitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z1Bounds.northEast.longitude, 180.0, accuracy: 0.00001)
        XCTAssertEqual(z1Bounds.northEast.latitude, 85.051128, accuracy: 0.00001)

        let z2Bounds = MapTile(x: 2, y: 1, z: 2).boundingBox()
        XCTAssertEqual(z2Bounds.southWest.longitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z2Bounds.southWest.latitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z2Bounds.northEast.longitude, 90.0, accuracy: 0.00001)
        XCTAssertEqual(z2Bounds.northEast.latitude, 66.51326044311185, accuracy: 0.00001)

        let z3Bounds = MapTile(x: 3, y: 3, z: 3).boundingBox()
        XCTAssertEqual(z3Bounds.southWest.longitude, -45.0, accuracy: 0.00001)
        XCTAssertEqual(z3Bounds.southWest.latitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z3Bounds.northEast.longitude, 0.0, accuracy: 0.00001)
        XCTAssertEqual(z3Bounds.northEast.latitude, 40.979898069620155, accuracy: 0.00001)

        let z10Bounds = MapTile(x: 5, y: 10, z: 10).boundingBox()
        XCTAssertEqual(z10Bounds.southWest.longitude, -178.242187, accuracy: 0.00001)
        XCTAssertEqual(z10Bounds.southWest.latitude, 84.706048, accuracy: 0.00001)
        XCTAssertEqual(z10Bounds.northEast.longitude, -177.890625, accuracy: 0.00001)
        XCTAssertEqual(z10Bounds.northEast.latitude, 84.738387, accuracy: 0.00001)

        let z32Bounds = MapTile(x: 2145960701, y: 1428172928, z: 32).boundingBox()
        XCTAssertEqual(z32Bounds.southWest.longitude, -0.127651, accuracy: 0.00001)
        XCTAssertEqual(z32Bounds.southWest.latitude, 51.508094, accuracy: 0.00001)
        XCTAssertEqual(z32Bounds.northEast.longitude, -0.127651, accuracy: 0.00001)
        XCTAssertEqual(z32Bounds.northEast.latitude, 51.508094, accuracy: 0.00001)
    }

    func testMetersPerPixelAtEquator() {
        var mppAtZoomLevels: [Double] = Array(repeating: 0.0, count: 21)
        mppAtZoomLevels[0] = 156_543.03392804096

        for zoom in 1...20 {
            mppAtZoomLevels[zoom] = mppAtZoomLevels[zoom - 1] / 2.0

            XCTAssertEqual(MapTile.metersPerPixel(at: zoom),
                           mppAtZoomLevels[zoom],
                           accuracy: 0.00001)
        }

        // Alternative
        let worldTile = MapTile(x: 0, y: 0, z: 0)
        XCTAssertEqual(worldTile.metersPerPixel, mppAtZoomLevels[0], accuracy: 0.00001)
    }

    func testMetersPerPixelAt45() {
        var mppAtZoomLevels: [Double] = Array(repeating: 0.0, count: 21)
        mppAtZoomLevels[0] = 110_692.6408380335

        for zoom in 1...20 {
            mppAtZoomLevels[zoom] = mppAtZoomLevels[zoom - 1] / 2.0

            XCTAssertEqual(MapTile.metersPerPixel(at: zoom, latitude: 45.0),
                           mppAtZoomLevels[zoom],
                           accuracy: 0.00001)
        }
    }

    func testQquadkey() {
        let tiles = [
            MapTile(x: 1, y: 2, z: 3),
            MapTile(x: 67, y: 45, z: 7),
            MapTile(x: 1082, y: 715, z: 11),
            MapTile(x: 34626, y: 22899, z: 16),
        ]
        let quadkeys = [
            "021",
            "1202213",
            "12022113032",
            "1202211303220032",
        ]

        for i in 0..<tiles.count {
            XCTAssertEqual(tiles[i].quadkey, quadkeys[i])
        }
    }

    func testQuadkeyInit() {
        let quadkeys = [
            "021",
            "1202213",
            "12022113032",
            "1202211303220032",
        ]
        let tiles = [
            MapTile(x: 1, y: 2, z: 3),
            MapTile(x: 67, y: 45, z: 7),
            MapTile(x: 1082, y: 715, z: 11),
            MapTile(x: 34626, y: 22899, z: 16),
        ]

        for i in 0..<quadkeys.count {
            XCTAssertEqual(MapTile(quadkey: quadkeys[i])!, tiles[i])
        }

        // Invalid
        XCTAssertNil(MapTile(quadkey: "021X"))
    }

}
