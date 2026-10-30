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

    @Test
    func lineOnBoundingBoxBoundaryIsKept() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let clipped = try #require(line.clipped(to: box))
        #expect(clipped.lineStrings.count == 1)
        #expect(abs(clipped.length - line.length) < 0.001)
    }

    @Test
    func lineFullyOutsideBoxReturnsNil() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 20.0, longitude: 20.0),
            Coordinate3D(latitude: 30.0, longitude: 30.0),
        ]))
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        #expect(line.clipped(to: box) == nil)
    }

    @Test
    func multipointCrossingBoxKeepsOnlySeamPoints() throws {
        let multiPoint = try #require(MultiPoint([
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: 0.0),
        ]))
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: -5.0, longitude: 175.0),
            northEast: Coordinate3D(latitude: 5.0, longitude: -175.0))

        let clipped = try #require(multiPoint.clipped(to: box))
        #expect(clipped.coordinates.count == 2)
        #expect(clipped.coordinates.contains { abs($0.longitude - 179.0) < 0.000001 })
        #expect(clipped.coordinates.contains { abs($0.longitude + 179.0) < 0.000001 })
    }

    @Test
    func featureCollectionClipPreservesMetadata() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 0.0),
            Coordinate3D(latitude: 0.0, longitude: 10.0),
        ]))
        let feature = Feature(
            line,
            id: .string("route"),
            properties: ["name": "Route"],
            calculateBoundingBox: true)
        let collection = FeatureCollection([feature])
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: -1.0, longitude: 2.0),
            northEast: Coordinate3D(latitude: 1.0, longitude: 8.0))

        let clipped = try #require(collection.clipped(to: box))
        let clippedFeature = try #require(clipped.features.first)
        #expect(clippedFeature.id == .string("route"))
        #expect(clippedFeature.property(for: "name") as String? == "Route")
        #expect(clippedFeature.boundingBox != nil)
    }

    @Test
    func linePartiallyOutsideCrossingBoxIsTrimmed() throws {
        let line = try #require(LineString([
            Coordinate3D(latitude: 0.0, longitude: 160.0),
            Coordinate3D(latitude: 0.0, longitude: 179.0),
            Coordinate3D(latitude: 0.0, longitude: -179.0),
            Coordinate3D(latitude: 0.0, longitude: -160.0),
        ]))
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: -5.0, longitude: 175.0),
            northEast: Coordinate3D(latitude: 5.0, longitude: -175.0))

        let clipped = try #require(line.clipped(to: box))
        #expect(clipped.lineStrings.count == 2)
        #expect(clipped.lineStrings.allSatisfy { lineString in
            lineString.coordinates.allSatisfy {
                $0.longitude >= 175.0 || $0.longitude <= -175.0
            }
        })
    }

    // MARK: - Segments spanning more than 180° of longitude

    /// A segment spanning more than 180° of longitude is unwrapped across the
    /// antimeridian, so its short way runs through ±180° and it spans more
    /// than one world period. A box that covers both sides of the seam must
    /// keep both pieces instead of silently dropping one half.
    @Test
    func segmentSpanningMoreThanHalfTheWorldKeepsBothHalves() throws {
        let line = try #require(LineString([
            Coordinate3D(x: -100.0, y: 0.0, projection: .epsg4326),
            Coordinate3D(x: 100.0, y: 0.0, projection: .epsg4326),
        ]))
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: -85.0, longitude: -110.0),
            northEast: Coordinate3D(latitude: 85.0, longitude: 110.0))

        let clipped = try #require(line.clipped(to: box))
        #expect(clipped.lineStrings.count == 2)

        let endpoints = clipped.lineStrings.flatMap { lineString in
            [lineString.coordinates.first, lineString.coordinates.last]
                .compactMap { $0?.longitude }
        }
        // One piece runs -100 → -110, the other 110 → 100.
        #expect(endpoints.contains { abs($0 + 100.0) < 0.000001 })
        #expect(endpoints.contains { abs($0 + 110.0) < 0.000001 })
        #expect(endpoints.contains { abs($0 - 100.0) < 0.000001 })
        #expect(endpoints.contains { abs($0 - 110.0) < 0.000001 })

        // 10° on each side of the seam.
        let expectedLength = Self.equatorLength(from: -100.0, to: -110.0)
            + Self.equatorLength(from: 110.0, to: 100.0)
        let totalLength = clipped.lineStrings.reduce(0.0) { $0 + $1.length }
        #expect(abs(totalLength - expectedLength) < expectedLength * 0.000001)
    }

    /// The world box must keep a >180° segment intact (as the two
    /// antimeridian pieces), not truncate it to a stub near 180°.
    @Test
    func segmentSpanningMoreThanHalfTheWorldInsideWorldBoxIsKept() throws {
        let line = try #require(LineString([
            Coordinate3D(x: -100.0, y: 0.0, projection: .epsg4326),
            Coordinate3D(x: 100.0, y: 0.0, projection: .epsg4326),
        ]))

        let clipped = try #require(line.clipped(to: .world))
        #expect(clipped.lineStrings.count == 2)

        let endpoints = clipped.lineStrings.flatMap { lineString in
            [lineString.coordinates.first, lineString.coordinates.last]
                .compactMap { $0?.longitude }
        }
        #expect(endpoints.contains { abs($0 + 180.0) < 0.000001 })
        #expect(endpoints.contains { abs($0 - 180.0) < 0.000001 })

        // The short way through ±180° is 160° of longitude.
        let totalLength = clipped.lineStrings.reduce(0.0) { $0 + $1.length }
        #expect(abs(totalLength - line.length) < line.length * 0.000001)
    }

    /// Boxes ending exactly at 180° or at -180°, and boxes ending just inside
    /// either edge, must all keep both halves of a >180° segment.
    @Test(arguments: [
        (-180.0, 180.0),
        (-180.0, 179.999),
        (-179.999, 180.0),
        (-180.0, 170.0),
        (-170.0, 180.0),
    ] as [(Double, Double)])
    func segmentSpanningMoreThanHalfTheWorldAtWorldEdges(
        _ west: Double,
        _ east: Double,
    ) throws {
        let line = try #require(LineString([
            Coordinate3D(x: -100.0, y: 0.0, projection: .epsg4326),
            Coordinate3D(x: 100.0, y: 0.0, projection: .epsg4326),
        ]))
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: -85.0, longitude: west),
            northEast: Coordinate3D(latitude: 85.0, longitude: east))

        let clipped = try #require(line.clipped(to: box))
        #expect(clipped.lineStrings.count == 2)

        // Both vertices of the original segment must survive on their own side
        // of the seam, and every coordinate must stay inside the box.
        let coordinates = clipped.allCoordinates
        #expect(coordinates.contains { abs($0.longitude + 100.0) < 0.000001 })
        #expect(coordinates.contains { abs($0.longitude - 100.0) < 0.000001 })
        for coordinate in coordinates {
            #expect(coordinate.longitude >= west - 0.000001)
            #expect(coordinate.longitude <= east + 0.000001)
        }
    }

    /// A crossing box narrower than the segment trims the parts that leave the
    /// box but keeps everything inside it on both sides of the seam.
    @Test
    func segmentSpanningMoreThanHalfTheWorldIsTrimmedByNarrowBox() throws {
        let line = try #require(LineString([
            Coordinate3D(x: -100.0, y: 0.0, projection: .epsg4326),
            Coordinate3D(x: 100.0, y: 0.0, projection: .epsg4326),
        ]))
        let box = BoundingBox(
            southWest: Coordinate3D(latitude: -5.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 5.0, longitude: -170.0))

        let clipped = try #require(line.clipped(to: box))
        #expect(clipped.lineStrings.count == 2)

        for coordinate in clipped.allCoordinates {
            #expect(coordinate.longitude >= 170.0 - 0.000001 || coordinate.longitude <= -170.0 + 0.000001)
        }

        // 10° on each side of the seam.
        let expectedLength = Self.equatorLength(from: 170.0, to: 180.0)
            + Self.equatorLength(from: -180.0, to: -170.0)
        let totalLength = clipped.lineStrings.reduce(0.0) { $0 + $1.length }
        #expect(abs(totalLength - expectedLength) < expectedLength * 0.000001)
    }

    /// A >180° segment in EPSG:3857 behaves like the EPSG:4326 case.
    @Test
    func segmentSpanningMoreThanHalfTheWorld3857IsKept() throws {
        let shift = GISTool.originShift
        let line = try #require(LineString([
            Coordinate3D(x: -shift / 1.8, y: 0.0, projection: .epsg3857),
            Coordinate3D(x: shift / 1.8, y: 0.0, projection: .epsg3857),
        ]))
        let box = BoundingBox(
            southWest: Coordinate3D(x: -shift, y: -shift, projection: .epsg3857),
            northEast: Coordinate3D(x: shift, y: shift, projection: .epsg3857))

        let clipped = try #require(line.clipped(to: box))
        #expect(clipped.lineStrings.count == 2)

        let totalLength = clipped.lineStrings.reduce(0.0) { $0 + $1.length }
        #expect(abs(totalLength - line.length) < line.length * 0.000001)
    }

    /// A plain antimeridian-crossing line clipped against the world box must
    /// keep both sides of the seam. At z0 the clip box is the whole world, so
    /// this is the case that used to drop one half of a route.
    @Test
    func antimeridianCrossingLineInsideWorldBoxIsKept() throws {
        let line = try #require(LineString([
            Coordinate3D(x: 179.0, y: 0.0, projection: .epsg4326),
            Coordinate3D(x: -179.0, y: 0.0, projection: .epsg4326),
        ]))

        let clipped = try #require(line.clipped(to: .world))
        #expect(clipped.lineStrings.count == 2)

        let totalLength = clipped.lineStrings.reduce(0.0) { $0 + $1.length }
        #expect(abs(totalLength - line.length) < line.length * 0.000001)
    }

    /// The length of an equatorial segment between two longitudes.
    private static func equatorLength(from: Double, to: Double) -> Double {
        Coordinate3D(latitude: 0.0, longitude: from)
            .distance(to: Coordinate3D(latitude: 0.0, longitude: to))
    }

    /// A >180° segment in EPSG:4978 has no wraparound axis, so it is clipped
    /// as a plain axis-aligned segment.
    @Test
    func segmentSpanningMoreThanHalfTheWorld4978IsClippedFlat() throws {
        let line = try #require(LineString([
            Coordinate3D(x: -100.0, y: 0.0, z: 0.0, projection: .epsg4978),
            Coordinate3D(x: 100.0, y: 0.0, z: 0.0, projection: .epsg4978),
        ]))
        let box = BoundingBox(
            southWest: Coordinate3D(x: -110.0, y: -85.0, z: 0.0, projection: .epsg4978),
            northEast: Coordinate3D(x: 110.0, y: 85.0, z: 0.0, projection: .epsg4978))

        let clipped = try #require(line.clipped(to: box))
        #expect(clipped.lineStrings.count == 1)
        #expect(clipped.allCoordinates.count == 2)
    }

}
