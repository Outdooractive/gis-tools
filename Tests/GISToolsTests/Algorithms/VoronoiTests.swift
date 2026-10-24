import Testing
import Foundation
@testable import GISTools

struct VoronoiTests {

    // MARK: - Reference tests

    private static let voronoiFixtures = [
        "ThreePoints",
        "FourPoints",
    ]

    @Test(arguments: voronoiFixtures)
    private func turfVoronoiFixture(_ name: String) async throws {
        let fc = try TestData.featureCollection(package: "Voronoi", name: name)
        let bbox = try TestData.boundingBox(package: "Voronoi", name: name + "Bbox")

        let result = fc.voronoiDiagram(boundingBox: bbox)

        #expect(result.features.count == fc.features.count,
                "\(name): expected \(fc.features.count) cells, got \(result.features.count)")

        for (i, feature) in result.features.enumerated() {
            let cell = try #require(feature.geometry as? Polygon,
                                    "\(name): cell \(i) is not a polygon")
            #expect(cell.isStructurallyValid,
                    "\(name): cell \(i) is invalid")
        }
    }

    // Validates that 3 points produce 3 Voronoi cells within the bounding box.
    @Test
    func testThreePoints() throws {
        let points = [
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 15.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 15.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)

        for feature in result.features {
            let poly = try #require(feature.geometry as? Polygon)
            #expect(poly.coordinates[0].count >= 4)
            #expect(poly.projection == .epsg4326)
        }
    }

    // Validates that 4 points at the corners produce cells filling the bounding box.
    @Test
    func testFourPoints() {
        let points = [
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 15.0))),
            Feature(Point(Coordinate3D(latitude: 15.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 15.0, longitude: 15.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 4)
    }

    // Validates that points exactly on the bounding box edge still produce valid cells.
    @Test
    func testPointsOnBboxEdge() {
        let points = [
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0))),
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 10.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 0.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)
    }

    // Validates that one and two distinct sites are handled directly instead
    // of producing an empty collection.
    @Test
    func testOneOrTwoPoints() throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let oneSite = Coordinate3D(latitude: 5.0, longitude: 5.0)
        let one = FeatureCollection([Feature(Point(oneSite))])
            .voronoiDiagram(boundingBox: bbox)
        #expect(one.features.count == 1)
        let oneCell = try #require(one.features.first?.geometry as? Polygon)
        #expect(oneCell.covers(oneSite))
        #expect(abs(oneCell.area - geometryArea(bbox.boundingBoxGeometry)) < 0.001)

        let firstSite = Coordinate3D(latitude: 5.0, longitude: 5.0)
        let secondSite = Coordinate3D(latitude: 10.0, longitude: 10.0)
        let two = FeatureCollection([
            Feature(Point(firstSite)),
            Feature(Point(secondSite)),
        ]).voronoiDiagram(boundingBox: bbox)
        #expect(two.features.count == 2)
        let firstCell = try #require(two.features[0].geometry as? Polygon)
        let secondCell = try #require(two.features[1].geometry as? Polygon)
        #expect(firstCell.covers(firstSite))
        #expect(secondCell.covers(secondSite))
        let boxArea = geometryArea(bbox.boundingBoxGeometry)
        #expect(abs(firstCell.area + secondCell.area - boxArea) < max(0.001, boxArea * 0.000001))
    }

    // Validates that an empty FeatureCollection returns an empty result.
    @Test
    func testEmptyPoints() {
        let fc = FeatureCollection()
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.isEmpty)
    }

    // Validates that the Voronoi cells do not extend outside the bounding box.
    @Test
    func testCellsWithinBbox() {
        let points = [
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 15.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 15.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 10.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        for feature in result.features {
            guard let poly = feature.geometry as? Polygon else {
                Issue.record("Expected Polygon")
                continue
            }
            for coord in poly.allCoordinates {
                #expect(coord.latitude >= 0.0 - 0.0000000001)
                #expect(coord.latitude <= 20.0 + 0.0000000001)
                #expect(coord.longitude >= 0.0 - 0.0000000001)
                #expect(coord.longitude <= 20.0 + 0.0000000001)
            }
        }
    }

    // Validates a Voronoi diagram with points on both sides of the antimeridian,
    // within a world-spanning bounding box.
    @Test
    func testAntimeridianWorldBbox() {
        let points = [
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: -170.0))),
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 180.0))),
            Feature(Point(Coordinate3D(latitude: -5.0, longitude: 170.0))),
            Feature(Point(Coordinate3D(latitude: -5.0, longitude: -175.0))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox.world

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 4)

        for feature in result.features {
            let poly = feature.geometry as? Polygon
            #expect(poly != nil)
            #expect(poly?.coordinates[0].count ?? 0 >= 4)
        }
    }

    // Validates a Voronoi diagram with an antimeridian-crossing bounding box,
    // covering the region from lon=170 to lon=-170 (across the date line).
    @Test
    func testAntimeridianCrossingBbox() {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: -170.0))

        let points = [
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 175.0))),
            Feature(Point(Coordinate3D(latitude: -5.0, longitude: 175.0))),
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: -175.0))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)

        for feature in result.features {
            let poly = feature.geometry as? Polygon
            #expect(poly != nil)
        }
    }

    // MARK: - Projections

    // Validates that points in EPSG:3857 produce a valid Voronoi diagram.
    @Test
    func voronoi3857() throws {
        let points = [
            Feature(Point(Coordinate3D(x: 500.0, y: 500.0, projection: .epsg3857))),
            Feature(Point(Coordinate3D(x: 1500.0, y: 500.0, projection: .epsg3857))),
            Feature(Point(Coordinate3D(x: 1000.0, y: 1500.0, projection: .epsg3857))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857),
            northEast: Coordinate3D(x: 2000.0, y: 2000.0, projection: .epsg3857))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)

        for feature in result.features {
            let poly = try #require(feature.geometry as? Polygon)
            #expect(poly.coordinates[0].count >= 4)
            #expect(poly.projection == .epsg3857)
        }
    }

    // Validates that points in noSRID produce a valid Voronoi diagram.
    @Test
    func voronoiNoSRID() throws {
        let points = [
            Feature(Point(Coordinate3D(x: 500.0, y: 500.0, projection: .noSRID))),
            Feature(Point(Coordinate3D(x: 1500.0, y: 500.0, projection: .noSRID))),
            Feature(Point(Coordinate3D(x: 1000.0, y: 1500.0, projection: .noSRID))),
        ]
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(x: 0.0, y: 0.0, projection: .noSRID),
            northEast: Coordinate3D(x: 2000.0, y: 2000.0, projection: .noSRID))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)

        for feature in result.features {
            let poly = try #require(feature.geometry as? Polygon)
            #expect(poly.coordinates[0].count >= 4)
            #expect(poly.projection == .noSRID)
        }
    }


    // Validates Voronoi in EPSG:4978.
    @Test
    func voronoi4978() throws {
        let coords: [Coordinate3D] = [
            Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 0.0, longitude: 1.0).projected(to: .epsg4978),
            Coordinate3D(latitude: 1.0, longitude: 0.5).projected(to: .epsg4978),
        ]
        let points = coords.map { Feature(Point($0)) }
        let fc = FeatureCollection(points)
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -1.0, longitude: -1.0).projected(to: .epsg4978),
            northEast: Coordinate3D(latitude: 2.0, longitude: 2.0).projected(to: .epsg4978))

        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 3)

        for feature in result.features {
            let poly = try #require(feature.geometry as? Polygon)
            #expect(poly.coordinates[0].count >= 4)
            #expect(poly.projection == .epsg4978)
        }
    }

    // Validates a Voronoi diagram with points near the antimeridian and a
    // non-crossing bounding box covering longitudes 150 to 200 (normalized).
    @Test
    func testAntimeridianNonCrossingBbox() {
        // Longitude 200 normalizes to -160, so this bbox crosses the antimeridian
        // in normalized form: [-160, -20, 160, 20]
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -20.0, longitude: 160.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: -160.0))

        let points = [
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 165.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 170.0))),
            Feature(Point(Coordinate3D(latitude: -10.0, longitude: -170.0))),
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: -165.0))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 4)

        for feature in result.features {
            let poly = feature.geometry as? Polygon
            #expect(poly != nil)
        }
    }

}

// MARK: - Audit regressions

extension VoronoiTests {

    @Test
    func cellsPreserveFeatureMetadata() throws {
        let features = [
            Feature(
                Point(Coordinate3D(latitude: 0.0, longitude: 0.0)),
                id: .string("a"),
                properties: ["name": "A"]),
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 10.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 5.0))),
        ]
        let collection = FeatureCollection(features)
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: -10.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))
        let result = collection.voronoiDiagram(boundingBox: bbox)
        let first = try #require(result.features.first)

        #expect(first.id == .string("a"))
        #expect(first.property(for: "name") as String? == "A")
    }


    private func geometryArea(_ geometry: any PolygonGeometry) -> Double {
        if let polygon = geometry as? Polygon { return polygon.area }
        if let multiPolygon = geometry as? MultiPolygon { return multiPolygon.area }
        return 0.0
    }

    private func unwrappedLongitudeSpan(_ polygon: Polygon) -> Double {
        let longitudes = polygon.outerRing?.coordinates.map(\.longitude) ?? []
        guard longitudes.count >= 2 else { return 0.0 }
        var unwrapped = longitudes
        for index in 1 ..< unwrapped.count {
            while unwrapped[index] - unwrapped[index - 1] > 180.0 {
                unwrapped[index] -= 360.0
            }
            while unwrapped[index - 1] - unwrapped[index] > 180.0 {
                unwrapped[index] += 360.0
            }
        }
        return (unwrapped.max() ?? 0.0) - (unwrapped.min() ?? 0.0)
    }

    /// Every cell contains its generating point, and the cells partition the
    /// bounding box (area sum equals the box area).
    @Test
    func cellsContainSitesAndPartitionBoundingBox() throws {
        let coordinates = [
            Coordinate3D(latitude: 5.0, longitude: 5.0),
            Coordinate3D(latitude: 5.0, longitude: 15.0),
            Coordinate3D(latitude: 15.0, longitude: 5.0),
            Coordinate3D(latitude: 15.0, longitude: 15.0),
            Coordinate3D(latitude: 10.0, longitude: 10.0),
        ]
        let features = coordinates.map { Feature(Point($0)) }
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 20.0, longitude: 20.0))

        let result = FeatureCollection(features).voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == coordinates.count)

        var areaSum = 0.0
        for (index, feature) in result.features.enumerated() {
            let cell = try #require(feature.geometry as? Polygon)
            #expect(cell.covers(coordinates[index]), "cell \(index) does not contain its site")
            areaSum += cell.area
        }

        let boxArea = geometryArea(bbox.boundingBoxGeometry)
        #expect(abs(areaSum - boxArea) < max(0.001, boxArea * 0.000001))
    }

    /// A crossing bounding box is unwrapped to its short span: cells do not
    /// span 340° and their area sums to the two-part box geometry.
    @Test
    func crossingBoundingBoxUsesShortSpan() throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: -170.0))
        let coordinates = [
            Coordinate3D(latitude: 5.0, longitude: 175.0),
            Coordinate3D(latitude: -5.0, longitude: 175.0),
            Coordinate3D(latitude: 5.0, longitude: -175.0),
            Coordinate3D(latitude: -5.0, longitude: -175.0),
        ]
        let features = coordinates.map { Feature(Point($0)) }

        let result = FeatureCollection(features).voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == coordinates.count)

        var areaSum = 0.0
        for (index, feature) in result.features.enumerated() {
            let cell = try #require(feature.geometry as? Polygon)
            #expect(unwrappedLongitudeSpan(cell) <= 20.000001, "cell \(index) spans the long way")
            #expect(cell.covers(coordinates[index]))
            areaSum += cell.area
        }

        let boxArea = geometryArea(bbox.boundingBoxGeometry)
        #expect(abs(areaSum - boxArea) < max(0.001, boxArea * 0.000001))
    }

    /// gridSize matches manual pre-snapping.
    @Test
    func gridSizeMatchesManualSnapping() throws {
        let coordinates = [
            Coordinate3D(latitude: 0.01, longitude: 0.01),
            Coordinate3D(latitude: 0.01, longitude: 10.02),
            Coordinate3D(latitude: 10.03, longitude: 5.04),
        ]
        let collection = FeatureCollection(coordinates.map { Feature(Point($0)) })
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -5.0, longitude: -5.0),
            northEast: Coordinate3D(latitude: 15.0, longitude: 15.0))

        let withParam = collection.voronoiDiagram(boundingBox: bbox, gridSize: 1.0)
        let manual = collection
            .snappedToGrid(tolerance: 1.0)
            .voronoiDiagram(boundingBox: bbox)

        #expect(withParam.features.count == manual.features.count)
        #expect(withParam.features.count > 0)
        for feature in withParam.features {
            #expect(feature.geometry is Polygon)
        }
    }

    /// The documented contract: one and two distinct sites produce one cell
    /// per site, and an empty collection produces no cells.
    @Test
    func fewerThanThreeDistinctSitesProduceCells() throws {
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 10.0))

        let one = FeatureCollection([Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0)))])
        let oneResult = one.voronoiDiagram(boundingBox: bbox)
        #expect(oneResult.features.count == 1)

        let two = FeatureCollection([
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 5.0))),
            Feature(Point(Coordinate3D(latitude: 5.0, longitude: 8.0))),
        ])
        let twoResult = two.voronoiDiagram(boundingBox: bbox)
        #expect(twoResult.features.count == 2)

        #expect(FeatureCollection().voronoiDiagram(boundingBox: bbox).features.isEmpty)
    }

    /// Duplicate sites collapse to the first feature, including its metadata,
    /// and the remaining distinct sites still produce cells.
    @Test
    func duplicateSitesProduceUniqueCells() throws {
        let first = Feature(
            Point(Coordinate3D(latitude: 0.0, longitude: 0.0)),
            id: .string("first"),
            properties: ["name": "first"])
        let duplicate = Feature(
            Point(Coordinate3D(latitude: 0.0, longitude: 0.0)),
            id: .string("duplicate"),
            properties: ["name": "duplicate"])
        let other = Feature(
            Point(Coordinate3D(latitude: 0.0, longitude: 10.0)),
            id: .string("other"))
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: -10.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 20.0))

        let result = FeatureCollection([first, duplicate, other])
            .voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 2)
        #expect(result.features[0].id == .string("first"))
        #expect(result.features[0].property(for: "name") as String? == "first")
        #expect(result.features[1].id == .string("other"))

        let firstCell = try #require(result.features[0].geometry as? Polygon)
        let otherCell = try #require(result.features[1].geometry as? Polygon)
        let firstPoint = try #require(first.geometry as? Point)
        let otherPoint = try #require(other.geometry as? Point)
        #expect(firstCell.covers(firstPoint))
        #expect(otherCell.covers(otherPoint))
        let boxArea = geometryArea(bbox.boundingBoxGeometry)
        #expect(abs(firstCell.area + otherCell.area - boxArea) < max(0.001, boxArea * 0.000001))

        let allDuplicate = FeatureCollection([
            first,
            duplicate,
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)), id: .string("third")),
        ]).voronoiDiagram(boundingBox: bbox)
        #expect(allDuplicate.features.count == 1)
        #expect(allDuplicate.features[0].id == .string("first"))
        let duplicateCell = try #require(allDuplicate.features[0].geometry as? Polygon)
        #expect(abs(duplicateCell.area - boxArea) < max(0.001, boxArea * 0.000001))
    }

    /// Collinear sites produce parallel strip cells instead of an empty
    /// result from a triangulation with no area.
    @Test
    func collinearSitesProduceStripCells() throws {
        let sites = [
            Coordinate3D(latitude: 5.0, longitude: 2.0),
            Coordinate3D(latitude: 5.0, longitude: 6.0),
            Coordinate3D(latitude: 5.0, longitude: 10.0),
            Coordinate3D(latitude: 5.0, longitude: 14.0),
            Coordinate3D(latitude: 5.0, longitude: 18.0),
        ]
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: 20.0))

        let result = FeatureCollection(sites.map { Feature(Point($0)) })
            .voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == sites.count)

        var areaSum = 0.0
        for (index, feature) in result.features.enumerated() {
            let cell = try #require(feature.geometry as? Polygon)
            #expect(cell.covers(sites[index]))
            #expect(cell.area > 0.0)
            areaSum += cell.area
        }
        let boxArea = geometryArea(bbox.boundingBoxGeometry)
        #expect(abs(areaSum - boxArea) < max(0.001, boxArea * 0.000001))
    }

    /// Duplicate and collinear handling stays correct in every projection.
    @Test
    func degenerateSitesAcrossProjections() throws {
        for projection in [Projection.epsg4326, .epsg3857, .epsg4978, .noSRID] {
            let sites = [
                coordinate(latitude: 0.0, longitude: 0.0, projection: projection),
                coordinate(latitude: 0.0, longitude: 10.0, projection: projection),
            ]
            let bbox = BoundingBox(
                southWest: coordinate(latitude: -10.0, longitude: -10.0, projection: projection),
                northEast: coordinate(latitude: 10.0, longitude: 20.0, projection: projection))

            let duplicates = FeatureCollection([
                Feature(Point(sites[0])),
                Feature(Point(sites[0])),
                Feature(Point(sites[1])),
            ]).voronoiDiagram(boundingBox: bbox)
            #expect(duplicates.features.count == 2, "\(projection)")

            let collinear = FeatureCollection([
                Feature(Point(sites[0])),
                Feature(Point(sites[1])),
                Feature(Point(coordinate(latitude: 0.0, longitude: 5.0, projection: projection))),
            ]).voronoiDiagram(boundingBox: bbox)
            #expect(collinear.features.count == 3, "\(projection)")
        }
    }

    /// Sites at +180° and −180° are the same site and duplicate coordinates
    /// must not suppress the diagram.
    @Test
    func duplicateSitesAcrossAntimeridian() throws {
        let seam = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 180.0)))
        let duplicate = Feature(Point(Coordinate3D(latitude: 0.0, longitude: -180.0)))
        let other = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 175.0)))
        let bbox = BoundingBox(
            southWest: Coordinate3D(latitude: -10.0, longitude: 170.0),
            northEast: Coordinate3D(latitude: 10.0, longitude: -170.0))

        let result = FeatureCollection([seam, duplicate, other])
            .voronoiDiagram(boundingBox: bbox)
        #expect(result.features.count == 2)
        let seamCell = try #require(result.features[0].geometry as? Polygon)
        let otherCell = try #require(result.features[1].geometry as? Polygon)
        let seamPoint = try #require(seam.geometry as? Point)
        let otherPoint = try #require(other.geometry as? Point)
        #expect(seamCell.covers(seamPoint))
        #expect(otherCell.covers(otherPoint))
    }

    private func coordinate(
        latitude: Double,
        longitude: Double,
        projection: Projection
    ) -> Coordinate3D {
        if projection == .noSRID {
            return Coordinate3D(x: longitude, y: latitude, projection: .noSRID)
        }
        return Coordinate3D(latitude: latitude, longitude: longitude)
            .projected(to: projection)
    }

}
