@testable import GISTools
import Testing

struct BoundingBoxClipTests {

    /// Validates clipping a single line segment to a bounding box.
    @Test
    func lineStringSingleLine() throws {
        let lineString = try TestData.lineString(package: "BoundingBoxClip", name: "SingleLine")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 39.095962936305476, longitude: -77.72552490234374),
            northEast: Coordinate3D(latitude: 39.59722324495565, longitude: -77.0361328125))
        let expected = try MultiLineString([
            TestData.lineString(package: "BoundingBoxClip", name: "SingleLineResult"),
        ])

        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped == expected)
    }

    /// Validates clipping a multi-segment line string to a bounding box.
    @Test
    func lineString() throws {
        let lineString = try TestData.lineString(package: "BoundingBoxClip", name: "LineString")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 36.29741818650811, longitude: -81.551513671875),
            northEast: Coordinate3D(latitude: 39.58875727696545, longitude: -76.475830078125))
        let expected = try TestData.multiLineString(package: "BoundingBoxClip", name: "LineStringResult")

        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped == expected)
    }

    /// Validates clipping a `MultiLineString` to a bounding box.
    @Test
    func multiLineString() throws {
        let lineString = try TestData.multiLineString(package: "BoundingBoxClip", name: "MultiLineString")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 38.49229419236133, longitude: -78.3929443359375),
            northEast: Coordinate3D(latitude: 39.56758783088905, longitude: -76.9097900390625))
        let expected = try TestData.multiLineString(package: "BoundingBoxClip", name: "MultiLineStringResult")

        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped == expected)
    }

    /// Validates clipping a `MultiPolygon` to a bounding box.
    @Test
    func multiPolygon() throws {
        let multiPolygon = try TestData.multiPolygon(package: "BoundingBoxClip", name: "MultiPolygon")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 36.2354121683998, longitude: -80.1123046875),
            northEast: Coordinate3D(latitude: 41.22824901518529, longitude: -76.959228515625))
        let expected = try TestData.multiPolygon(package: "BoundingBoxClip", name: "MultiPolygonResult")

        let clipped = multiPolygon.clipped(to: boundingBox)
        #expect(clipped?.polygons.count == expected.polygons.count)
        let actualArea = clipped?.area ?? 0.0
        #expect(abs(actualArea - expected.area) < max(0.001, expected.area * 0.000001))
    }

    /// Validates clipping a polygon with a crossing hole to a bounding box.
    @Test
    func polygonCrossingHole() throws {
        let polygon = try TestData.polygon(package: "BoundingBoxClip", name: "PolygonCrossingHole")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 36.34167804918315, longitude: -79.12353515625),
            northEast: Coordinate3D(latitude: 39.027718840211605, longitude: -76.739501953125))
        let expected = try TestData.polygon(package: "BoundingBoxClip", name: "PolygonCrossingHoleResult")

        let clipped = polygon.clipped(to: boundingBox)
        #expect(clipped?.polygons.count == 1)
        let actualArea = clipped?.area ?? 0.0
        #expect(abs(actualArea - expected.area) < max(0.001, expected.area * 0.000001))
    }

    /// Validates clipping a polygon with multiple holes to a bounding box.
    @Test
    func polygonHoles() throws {
        let polygon = try TestData.polygon(package: "BoundingBoxClip", name: "PolygonHoles")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: 36.38591277287651, longitude: -79.60693359375),
            northEast: Coordinate3D(latitude: 39.07890809706475, longitude: -76.717529296875))
        let expected = try TestData.polygon(package: "BoundingBoxClip", name: "PolygonHolesResult")

        let clipped = polygon.clipped(to: boundingBox)
        #expect(clipped?.polygons.count == 1)
        let actualArea = clipped?.area ?? 0.0
        #expect(abs(actualArea - expected.area) < max(0.001, expected.area * 0.000001))
    }

    /// Validates that clipping returns nil when the bounding box intersects at only a point (degenerate/invalid).
    @Test
    func polygonPointIntersection() throws {
        let polygon = try TestData.polygon(package: "BoundingBoxClip", name: "PolygonPointIntersection")
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(latitude: -31.98, longitude: 115.875),
            northEast: Coordinate3D(latitude: -31.975, longitude: 115.880))

        let clipped = polygon.clipped(to: boundingBox)
        #expect(clipped == nil) // invalid
    }

    // MARK: - Projections

    /// Validates clipping in EPSG:3857 projection.
    @Test
    func boundingBoxClip3857() throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0, projection: .epsg3857),
        ]))
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(x: -100_000.0, y: -100_000.0, projection: .epsg3857),
            northEast: Coordinate3D(x: 500_000.0, y: 500_000.0, projection: .epsg3857))
        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped != nil)
    }

    /// Validates clipping in noSRID projection.
    @Test
    func boundingBoxClipNoSRID() throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0, projection: .noSRID),
        ]))
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(x: -100_000.0, y: -100_000.0, projection: .noSRID),
            northEast: Coordinate3D(x: 500_000.0, y: 500_000.0, projection: .noSRID))
        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped != nil)
    }

    /// Validates clipping in EPSG:4978 projection.
    @Test
    func boundingBoxClip4978() throws {
        let lineString = try #require(LineString([
            Coordinate3D(x: 0.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 1_000_000.0, y: 1_000_000.0, z: 0.0, projection: .epsg4978),
        ]))
        let boundingBox = BoundingBox(
            southWest: Coordinate3D(x: -100_000.0, y: -100_000.0, z: 0.0, projection: .epsg4978),
            northEast: Coordinate3D(x: 500_000.0, y: 500_000.0, z: 0.0, projection: .epsg4978))
        let clipped = lineString.clipped(to: boundingBox)
        #expect(clipped != nil)
    }

    /// Clipping a point at the Earth's center (0,0,0) in EPSG:4978 to the
    /// world tile bounding box should return the point unchanged, since the
    /// ECEF AABB of the full Mercator viewable globe contains the origin.
    @Test
    func worldBoundingBoxClip4978() throws {
        let world = MapTile(x: 0, y: 0, z: 0).boundingBox(projection: .epsg4978)
        let point = Feature(Point(Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857).projected(to: .epsg4978)))
        let result = try #require(point.clipped(to: world))

        #expect(result == point)
    }

    // MARK: - Antimeridian

    /// All geometries with coordinates well inside the world-spanning bounding box
    /// at z=0 in EPSG:4326 must survive clipping without being dropped.
    /// The bbox below is exactly what MapTile(x:0, y:0, z:0).boundingBox(.epsg4326) produces.
    @Test(arguments: [
        "Point",
        "MultiPoint",
        "LineString",
        "Polygon",
    ] as [String])
    func insideWorldBox(_ label: String) throws {
        let bbox = MapTile(x: 0, y: 0, z: 0).boundingBox(projection: .epsg4326)
        let coords = [
            Coordinate3D(latitude: 48.8566, longitude: 2.3522),
            Coordinate3D(latitude: 52.5200, longitude: 13.4050),
            Coordinate3D(latitude: 47.3769, longitude: 8.5417),
        ]
        let geom: Feature
        switch label {
        case "Point":
            geom = Feature(Point(coords[0]))
        case "MultiPoint":
            geom = try Feature(#require(MultiPoint(coords)))
        case "LineString":
            geom = try Feature(#require(LineString(coords)))
        case "Polygon":
            geom = Feature(Polygon([coords + [coords[0]]])!)
        default:
            return
        }
        let clipped = geom.clipped(to: bbox)
        #expect(clipped != nil, "\(label) was dropped")
    }

    /// Validates clipping near the antimeridian.
    @Test
    func antimeridian() throws {
        let lineString = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 175.0),
            Coordinate3D(latitude: 10.0, longitude: 179.0),
        ]))
        let bbox = BoundingBox.world
        let clipped = lineString.clipped(to: bbox)
        #expect(clipped != nil)
    }

    // MARK: - Audit regressions

    @Test
    func crossingBoundingBoxClipsIntoTwoParts() throws {
        let polygon = try #require(Polygon([[
            Coordinate3D(latitude: -5.0, longitude: 170.0),
            Coordinate3D(latitude: 5.0, longitude: 170.0),
            Coordinate3D(latitude: 5.0, longitude: -170.0),
            Coordinate3D(latitude: -5.0, longitude: -170.0),
            Coordinate3D(latitude: -5.0, longitude: 170.0),
        ]]))
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: 175.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: -175.0))

        let clipped = try #require(polygon.clipped(to: box))
        #expect(clipped.polygons.count == 2)
        // swiftformat:disable:next preferKeyPath
        #expect(clipped.polygons.allSatisfy({ $0.isValid }))
        // 10 degrees of latitude x 5 degrees on each side of the seam.
        let expected = try #require(Polygon([[
            Coordinate3D(latitude: -5.0, longitude: 175.0),
            Coordinate3D(latitude: 5.0, longitude: 175.0),
            Coordinate3D(latitude: 5.0, longitude: 180.0),
            Coordinate3D(latitude: -5.0, longitude: 180.0),
            Coordinate3D(latitude: -5.0, longitude: 175.0),
        ]]))
        #expect(abs(clipped.area - 2.0 * expected.area) < max(0.001, expected.area * 0.00001))
    }

    @Test
    func holeCrossingClipEdgeBecomesNotch() throws {
        func coordinate(_ x: Double, _ y: Double) -> Coordinate3D {
            Coordinate3D(x: x, y: y, projection: .noSRID)
        }
        let polygon = try #require(Polygon([
            [
                coordinate(0.0, 0.0),
                coordinate(10.0, 0.0),
                coordinate(10.0, 10.0),
                coordinate(0.0, 10.0),
                coordinate(0.0, 0.0),
            ],
            [
                coordinate(5.0, 5.0),
                coordinate(15.0, 5.0),
                coordinate(15.0, 15.0),
                coordinate(5.0, 15.0),
                coordinate(5.0, 5.0),
            ],
        ]))
        let box = BoundingBox(
            southWest: coordinate(0.0, 0.0),
            northEast: coordinate(10.0, 10.0))

        let clipped = try #require(polygon.clipped(to: box))
        #expect(clipped.polygons.count == 1)
        #expect(clipped.polygons[0].isValid)
        // Outer 100 minus the 5x5 part of the hole inside the box.
        #expect(abs(clipped.area - 75.0) < 0.000001)
    }

    @Test
    func uShapeSplitsIntoDisconnectedParts() throws {
        func coordinate(_ x: Double, _ y: Double) -> Coordinate3D {
            Coordinate3D(x: x, y: y, projection: .noSRID)
        }
        let polygon = try #require(Polygon([[
            coordinate(0.0, 0.0),
            coordinate(10.0, 0.0),
            coordinate(10.0, 10.0),
            coordinate(7.0, 10.0),
            coordinate(7.0, 3.0),
            coordinate(3.0, 3.0),
            coordinate(3.0, 10.0),
            coordinate(0.0, 10.0),
            coordinate(0.0, 0.0),
        ]]))
        let box = BoundingBox(
            southWest: coordinate(-1.0, 5.0),
            northEast: coordinate(11.0, 11.0))

        let clipped = try #require(polygon.clipped(to: box))
        #expect(clipped.polygons.count == 2)
        // swiftformat:disable:next preferKeyPath
        #expect(clipped.polygons.allSatisfy({ $0.isValid }))
        #expect(abs(clipped.area - 30.0) < 0.000001, "area \(clipped.area), polygons \(clipped.polygons.map(\.coordinates))")
    }

    @Test
    func crossProjectionClip4978UsesProjectedBox() throws {
        let polygon4326 = try #require(Polygon([[
            Coordinate3D(latitude: -1.0, longitude: -1.0),
            Coordinate3D(latitude: -1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: 1.0),
            Coordinate3D(latitude: 1.0, longitude: -1.0),
            Coordinate3D(latitude: -1.0, longitude: -1.0),
        ]]))
        let polygon4978 = polygon4326.projected(to: .epsg4978)
        let box4326 = BoundingBox(
            southWest: Coordinate3D(latitude: -0.5, longitude: -0.5),
            northEast: Coordinate3D(latitude: 0.5, longitude: 0.5))

        let clipped = try #require(polygon4978.clipped(to: box4326))
        #expect(clipped.projection == .epsg4978)
        #expect(clipped.polygons.isNotEmpty)
        let back = clipped.projected(to: .epsg4326)
        // swiftformat:disable:next preferKeyPath
        #expect(back.polygons.allSatisfy({ $0.isValid }))
        let expected = try #require(Polygon([[
            Coordinate3D(latitude: -0.5, longitude: -0.5),
            Coordinate3D(latitude: -0.5, longitude: 0.5),
            Coordinate3D(latitude: 0.5, longitude: 0.5),
            Coordinate3D(latitude: 0.5, longitude: -0.5),
            Coordinate3D(latitude: -0.5, longitude: -0.5),
        ]]))
        #expect(abs(back.area - expected.area) < expected.area * 0.01)
    }

    @Test
    func lineInsideCrossingBoxIsKept() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
        ]))
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: -5.0, longitude: 175.0),
            northEast: Coordinate3D(latitude: 5.0, longitude: -175.0))

        let clipped = try #require(line.clipped(to: box))
        #expect(clipped.lineStrings.count == 2)
        // Each side contributes one degree at the equator.
        #expect(abs(clipped.length - 2.0 * 111_195.0) < 2000.0)
    }

    @Test
    func lineInsideCrossingBox3857IsKept() throws {
        let shift = GISTool.originShift
        let line = try #require(LineString([
            Coordinate3D(x: shift - 1000.0, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: -shift + 1000.0, y: 0.0, projection: .epsg3857),
        ]))
        let box = BoundingBox(
            southWest: Coordinate3D(x: shift - 5000.0, y: -10000.0, projection: .epsg3857),
            northEast: Coordinate3D(x: -shift + 5000.0, y: 10000.0, projection: .epsg3857))

        let clipped = try #require(line.clipped(to: box))
        #expect(clipped.lineStrings.count == 2)
        #expect(abs(clipped.length - 2000.0) < 0.001)
    }

    @Test
    func multiLineStringInsideCrossingBoxIsKept() throws {
        let line1 = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
        ]))
        let line2 = try #require(LineString([
            Coordinate3D(latitude: 1.0, longitude: -179.0),
            Coordinate3D(latitude: 1.0, longitude: 179.0),
        ]))
        let multi = try #require(MultiLineString([line1, line2]))
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: -5.0, longitude: 175.0),
            northEast: Coordinate3D(latitude: 5.0, longitude: -175.0))

        let clipped = try #require(multi.clipped(to: box))
        #expect(clipped.lineStrings.count == 4)
    }

    @Test
    func lineClippingIn4978UsesProjectedBox() throws {
        var line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 10.0).projected(to: .epsg4978),
        ]))
        line.foreignMembers = ["source": "test"]
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: -1.0, longitude: -1.0),
            northEast: Coordinate3D(latitude: 1.0, longitude: 11.0))

        let clipped = try #require(line.clipped(to: box))
        #expect(clipped.projection == .epsg4978)
        #expect(clipped.foreignMembers["source"] as? String == "test")

        let back = clipped.projected(to: .epsg4326)
        #expect(back.lineStrings.isNotEmpty)
        for coordinate in back.allCoordinates {
            #expect(coordinate.latitude >= -1.000001)
            #expect(coordinate.latitude <= 1.000001)
            #expect(coordinate.longitude >= -1.000001)
            #expect(coordinate.longitude <= 11.000001)
        }
    }

    @Test
    func multiLineStringClippingIn4978DropsOutsideParts() throws {
        let inside = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 10.0).projected(to: .epsg4978),
        ]))
        let outside = try #require(LineString([
            Coordinate3D(latitude: 20.0, longitude: 20.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 30.0, longitude: 30.0).projected(to: .epsg4978),
        ]))
        let multi = try #require(MultiLineString([inside, outside]))
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: -1.0, longitude: -1.0),
            northEast: Coordinate3D(latitude: 1.0, longitude: 11.0))

        let clipped = try #require(multi.clipped(to: box))
        #expect(clipped.projection == .epsg4978)
        #expect(clipped.lineStrings.count == 1)

        let back = clipped.projected(to: .epsg4326)
        #expect(back.allCoordinates.count == 2)
    }

}
