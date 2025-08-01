@testable import GISTools
import Testing

struct MapTileTests {

    @Test
    func tileFromCoordinate() async throws {
        #expect(MapTile(coordinate: Coordinate3D(latitude: 0.0, longitude: 0.0), atZoom: 0) == MapTile(x: 0, y: 0, z: 0))

        #expect(MapTile(coordinate: Coordinate3D(latitude: 84.71, longitude: -178.0), atZoom: 10) == MapTile(x: 5, y: 10, z: 10))

        #expect(MapTile(coordinate: Coordinate3D(latitude: 1.0, longitude: 1.0), atZoom: 18) == MapTile(x: 131800, y: 130343, z: 18))

        #expect(MapTile(coordinate: Coordinate3D(latitude: -33.8566, longitude: 151.215), atZoom: 14) == MapTile(x: 15073, y: 9831, z: 14))
    }

    @Test
    func tileFromBoundingBox() async throws {
        let boundingBox1 = BoundingBox(
            southWest: Coordinate3D(latitude: 46.5, longitude: 10.5),
            northEast: Coordinate3D(latitude: 48.5, longitude: 11.0))
        let boundingBox2 = BoundingBox(
            southWest: Coordinate3D(latitude: 46.5, longitude: 10.5),
            northEast: Coordinate3D(latitude: 48.5, longitude: 11.25))
        let boundingBox3 = try #require(BoundingBox(coordinates: [Coordinate3D(latitude: 47.56, longitude: 10.22)]))

        #expect(MapTile(boundingBox: boundingBox1) == MapTile(x: 33, y: 22, z: 6))
        #expect(MapTile(boundingBox: boundingBox2) == MapTile(x: 8, y: 5, z: 4))

        #expect(MapTile(boundingBox: boundingBox3) == MapTile(x: 2269412997, y: 1500804469, z: 32))
        #expect(MapTile(boundingBox: boundingBox3, maxZoom: 14) == MapTile(x: 8657, y: 5725, z: 14))
        #expect(MapTile(boundingBox: boundingBox3, maxZoom: 8) == MapTile(x: 135, y: 89, z: 8))
        #expect(MapTile(boundingBox: boundingBox3, maxZoom: 4) == MapTile(x: 8, y: 5, z: 4))
        #expect(MapTile(boundingBox: boundingBox3, maxZoom: 0) == MapTile(x: 0, y: 0, z: 0))
    }

    @Test
    func center() async throws {
        let coordinate1 = MapTile(x: 138513, y: 91601, z: 18).centerCoordinate()
        #expect(abs(coordinate1.latitude - 47.56031069944929) < 0.00001)
        #expect(abs(coordinate1.longitude - 10.219345092773441) < 0.00001)

        let coordinate2 = MapTile(x: 15073, y: 9831, z: 14).centerCoordinate()
        #expect(abs(coordinate2.latitude - -33.86129311351551) < 0.00001)
        #expect(abs(coordinate2.longitude - 151.20483398437503) < 0.00001)

        let coordinate3 = MapTile(x: 0, y: 0, z: 0).centerCoordinate()
        #expect(abs(coordinate3.latitude) < 0.00001)
        #expect(abs(coordinate3.longitude) < 0.00001)

        // Tiles are not squares...
        let coordinate4 = MapTile(x: 0, y: 0, z: 1).centerCoordinate()
        #expect(abs(coordinate4.latitude - 66.51326044311185) < 0.00001)
        #expect(abs(coordinate4.longitude - -90.0) < 0.00001)
    }

    @Test
    func tileFromHQCoordinate() async throws {
        let coordinate = Coordinate3D(latitude: 47.56, longitude: 10.22)

        #expect(MapTile(coordinate: coordinate, atZoom: 0) == MapTile(x: 0, y: 0, z: 0))
        #expect(MapTile(coordinate: coordinate, atZoom: 1) == MapTile(x: 1, y: 0, z: 1))
        #expect(MapTile(coordinate: coordinate, atZoom: 2) == MapTile(x: 2, y: 1, z: 2))
        #expect(MapTile(coordinate: coordinate, atZoom: 3) == MapTile(x: 4, y: 2, z: 3))
        #expect(MapTile(coordinate: coordinate, atZoom: 4) == MapTile(x: 8, y: 5, z: 4))
        #expect(MapTile(coordinate: coordinate, atZoom: 5) == MapTile(x: 16, y: 11, z: 5))
        #expect(MapTile(coordinate: coordinate, atZoom: 6) == MapTile(x: 33, y: 22, z: 6))
        #expect(MapTile(coordinate: coordinate, atZoom: 7) == MapTile(x: 67, y: 44, z: 7))
        #expect(MapTile(coordinate: coordinate, atZoom: 8) == MapTile(x: 135, y: 89, z: 8))
        #expect(MapTile(coordinate: coordinate, atZoom: 9) == MapTile(x: 270, y: 178, z: 9))
        #expect(MapTile(coordinate: coordinate, atZoom: 10) == MapTile(x: 541, y: 357, z: 10))
        #expect(MapTile(coordinate: coordinate, atZoom: 11) == MapTile(x: 1082, y: 715, z: 11))
        #expect(MapTile(coordinate: coordinate, atZoom: 12) == MapTile(x: 2164, y: 1431, z: 12))
        #expect(MapTile(coordinate: coordinate, atZoom: 13) == MapTile(x: 4328, y: 2862, z: 13))
        #expect(MapTile(coordinate: coordinate, atZoom: 14) == MapTile(x: 8657, y: 5725, z: 14))
        #expect(MapTile(coordinate: coordinate, atZoom: 15) == MapTile(x: 17314, y: 11450, z: 15))
        #expect(MapTile(coordinate: coordinate, atZoom: 16) == MapTile(x: 34628, y: 22900, z: 16))
        #expect(MapTile(coordinate: coordinate, atZoom: 17) == MapTile(x: 69256, y: 45800, z: 17))
        #expect(MapTile(coordinate: coordinate, atZoom: 18) == MapTile(x: 138513, y: 91601, z: 18))
    }

    @Test
    func parent() async throws {
        #expect(MapTile(x: 0, y: 0, z: 0).parent == MapTile(x: 0, y: 0, z: 0))
        #expect(MapTile(x: 1, y: 0, z: 1).parent == MapTile(x: 0, y: 0, z: 0))
        #expect(MapTile(x: 270, y: 178, z: 9).parent == MapTile(x: 135, y: 89, z: 8))
        #expect(MapTile(x: 138513, y: 91601, z: 18).parent == MapTile(x: 69256, y: 45800, z: 17))
    }

    @Test
    func child() async throws {
        #expect(MapTile(x: 0, y: 0, z: 0).child == MapTile(x: 0, y: 0, z: 1))
        #expect(MapTile(x: 1, y: 0, z: 1).child == MapTile(x: 2, y: 0, z: 2))
        #expect(MapTile(x: 270, y: 178, z: 9).child == MapTile(x: 540, y: 356, z: 10))
        #expect(MapTile(x: 69256, y: 45800, z: 17).child == MapTile(x: 138512, y: 91600, z: 18))
    }

    @Test
    func children() async throws {
        #expect(MapTile(x: 0, y: 0, z: 0).children == [
            MapTile(x: 0, y: 0, z: 1),
            MapTile(x: 1, y: 0, z: 1),
            MapTile(x: 0, y: 1, z: 1),
            MapTile(x: 1, y: 1, z: 1),
        ])
        #expect(MapTile(x: 270, y: 178, z: 9).children == [
            MapTile(x: 540, y: 356, z: 10),
            MapTile(x: 541, y: 356, z: 10),
            MapTile(x: 540, y: 357, z: 10),
            MapTile(x: 541, y: 357, z: 10),
        ])
    }

    @Test
    func epsg3857TileBounds() async throws {
        let worldBounds = MapTile(x: 0, y: 0, z: 0).boundingBox(projection: .epsg3857)
        #expect(abs(worldBounds.southWest.longitude - -GISTool.originShift) < 0.00001)
        #expect(abs(worldBounds.southWest.latitude - -GISTool.originShift) < 0.00001)
        #expect(abs(worldBounds.northEast.longitude - GISTool.originShift) < 0.00001)
        #expect(abs(worldBounds.northEast.latitude - GISTool.originShift) < 0.00001)

        let z1Bounds = MapTile(x: 1, y: 0, z: 1).boundingBox(projection: .epsg3857)
        #expect(abs(z1Bounds.southWest.longitude) < 0.00001)
        #expect(abs(z1Bounds.southWest.latitude) < 0.00001)
        #expect(abs(z1Bounds.northEast.longitude - GISTool.originShift) < 0.00001)
        #expect(abs(z1Bounds.northEast.latitude - GISTool.originShift) < 0.00001)

        let z2Bounds = MapTile(x: 2, y: 1, z: 2).boundingBox(projection: .epsg3857)
        #expect(abs(z2Bounds.southWest.longitude) < 0.00001)
        #expect(abs(z2Bounds.southWest.latitude) < 0.00001)
        #expect(abs(z2Bounds.northEast.longitude - (GISTool.originShift / 2.0)) < 0.00001)
        #expect(abs(z2Bounds.northEast.latitude - (GISTool.originShift / 2.0)) < 0.00001)

        let z3Bounds = MapTile(x: 3, y: 3, z: 3).boundingBox(projection: .epsg3857)
        #expect(abs(z3Bounds.southWest.longitude - (-GISTool.originShift / 4.0)) < 0.00001)
        #expect(abs(z3Bounds.southWest.latitude) < 0.00001)
        #expect(abs(z3Bounds.northEast.longitude) < 0.00001)
        #expect(abs(z3Bounds.northEast.latitude - (GISTool.originShift / 4.0)) < 0.00001)

        let z32Bounds = MapTile(x: 2145960701, y: 1428172928, z: 32).boundingBox(projection: .epsg3857)
        #expect(abs(z32Bounds.southWest.longitude - -14210.149281) < 0.00001)
        #expect(abs(z32Bounds.southWest.latitude - 6711666.720463) < 0.00001)
        #expect(abs(z32Bounds.northEast.longitude - -14210.139951) < 0.00001)
        #expect(abs(z32Bounds.northEast.latitude - 6711666.729793) < 0.00001)
    }

    @Test
    func epsg4236TileBounds() async throws {
        let worldBounds = MapTile(x: 0, y: 0, z: 0).boundingBox()
        #expect(abs(worldBounds.southWest.longitude - -180.0) < 0.00001)
        #expect(abs(worldBounds.southWest.latitude - -85.051128) < 0.00001)
        #expect(abs(worldBounds.northEast.longitude - 180.0) < 0.00001)
        #expect(abs(worldBounds.northEast.latitude - 85.051128) < 0.00001)

        let z1Bounds = MapTile(x: 1, y: 0, z: 1).boundingBox()
        #expect(abs(z1Bounds.southWest.longitude) < 0.00001)
        #expect(abs(z1Bounds.southWest.latitude) < 0.00001)
        #expect(abs(z1Bounds.northEast.longitude - 180.0) < 0.00001)
        #expect(abs(z1Bounds.northEast.latitude - 85.051128) < 0.00001)

        let z2Bounds = MapTile(x: 2, y: 1, z: 2).boundingBox()
        #expect(abs(z2Bounds.southWest.longitude) < 0.00001)
        #expect(abs(z2Bounds.southWest.latitude) < 0.00001)
        #expect(abs(z2Bounds.northEast.longitude - 90.0) < 0.00001)
        #expect(abs(z2Bounds.northEast.latitude - 66.51326044311185) < 0.00001)

        let z3Bounds = MapTile(x: 3, y: 3, z: 3).boundingBox()
        #expect(abs(z3Bounds.southWest.longitude - -45.0) < 0.00001)
        #expect(abs(z3Bounds.southWest.latitude) < 0.00001)
        #expect(abs(z3Bounds.northEast.longitude) < 0.00001)
        #expect(abs(z3Bounds.northEast.latitude - 40.979898069620155) < 0.00001)

        let z10Bounds = MapTile(x: 5, y: 10, z: 10).boundingBox()
        #expect(abs(z10Bounds.southWest.longitude - -178.242187) < 0.00001)
        #expect(abs(z10Bounds.southWest.latitude - 84.706048) < 0.00001)
        #expect(abs(z10Bounds.northEast.longitude - -177.890625) < 0.00001)
        #expect(abs(z10Bounds.northEast.latitude - 84.738387) < 0.00001)

        let z32Bounds = MapTile(x: 2145960701, y: 1428172928, z: 32).boundingBox()
        #expect(abs(z32Bounds.southWest.longitude - -0.127651) < 0.00001)
        #expect(abs(z32Bounds.southWest.latitude - 51.508094) < 0.00001)
        #expect(abs(z32Bounds.northEast.longitude - -0.127651) < 0.00001)
        #expect(abs(z32Bounds.northEast.latitude - 51.508094) < 0.00001)
    }

    @Test
    func metersPerPixelAtEquator() async throws {
        let worldTile = MapTile(x: 0, y: 0, z: 0)
        let mppAtZoom0 = 156_543.03392804096

        #expect(abs(worldTile.metersPerPixel - mppAtZoom0) < 0.00001)
    }

    @Test
    func edgeCases() async throws {
        let coordinate = Coordinate3D(latitude: -90.0, longitude: -180.0)
        let tile = MapTile(coordinate: coordinate, atZoom: 14)

        #expect(tile == MapTile(x: 0, y: (1 << 14) - 1, z: 14))
    }

    @Test
    func quadkey() async throws {
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
            #expect(tiles[i].quadkey == quadkeys[i])
        }
    }

    @Test
    func quadkeyInit() async throws {
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
            #expect(MapTile(quadkey: quadkeys[i])! == tiles[i])
        }

        // Invalid
        #expect(MapTile(quadkey: "021X") == nil)
    }

    @Test
    func initFromString() async throws {
        #expect(MapTile(string: "3/1/2") == MapTile(x: 1, y: 2, z: 3))
        #expect(MapTile(string: "7/67/45") == MapTile(x: 67, y: 45, z: 7))
        #expect(MapTile(string: "11/1082/715") == MapTile(x: 1082, y: 715, z: 11))
        #expect(MapTile(string: "16/34626/22899") == MapTile(x: 34626, y: 22899, z: 16))
    }

}
