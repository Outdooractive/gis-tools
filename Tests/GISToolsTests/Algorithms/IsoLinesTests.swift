import Testing
import Foundation
@testable import GISTools

struct IsoLinesTests {

    /// Generate a 5x5 grid of points with a simple conical z-value = distance from center
    private func makeGrid(
        minLon: Double = 0.0,
        maxLon: Double = 4.0,
        minLat: Double = 0.0,
        maxLat: Double = 4.0,
        projection: Projection = .epsg4326
    ) -> FeatureCollection {
        let cx = (minLon + maxLon) / 2.0
        let cy = (minLat + maxLat) / 2.0
        var features: [Feature] = []
        for lat in stride(from: minLat, through: maxLat, by: 1.0) {
            for lon in stride(from: minLon, through: maxLon, by: 1.0) {
                let dx = lon - cx
                let dy = lat - cy
                let z = sqrt(dx * dx + dy * dy)  // distance from center
                let coord: Coordinate3D
                if projection == .epsg4978 {
                    // Build an axis-aligned grid in ECEF space anchored near
                    // the Earth's surface at (lat=0, lon=0). The grid
                    // dimensions are ~100 km scaled to degrees at the equator.
                    let scale = 111_320.0  // meters per degree at equator
                    coord = Coordinate3D(
                        x: 6_378_137.0 + lon * scale,
                        y: lat * scale,
                        z: z,
                        projection: .epsg4978)
                }
                else {
                    coord = Coordinate3D(x: lon, y: lat, z: z, projection: projection)
                }
                let feature = Feature(Point(coord))
                features.append(feature)
            }
        }
        return FeatureCollection(features)
    }

    @Test
    func testBasicIsolines() {
        let grid = makeGrid()
        let result = grid.isolines(breaks: [1.0, 2.0])

        #expect(result.features.count == 2)
        // Break values set as properties
        #expect(result.features[0].properties["break"] as? Double == 1.0)
        #expect(result.features[1].properties["break"] as? Double == 2.0)
        // Each feature should be a MultiLineString
        for feature in result.features {
            #expect(feature.geometry is MultiLineString)
        }
    }

    @Test
    func testSingleBreak() {
        let grid = makeGrid()
        let result = grid.isolines(breaks: [1.5])

        #expect(result.features.count == 1)
        #expect(result.features[0].geometry is MultiLineString)
        let mls = result.features[0].geometry as! MultiLineString
        #expect(!mls.lineStrings.isEmpty)
    }

    @Test
    func testFlatGridGeneratesNoLines() {
        var features: [Feature] = []
        for lat in stride(from: 0.0, through: 4.0, by: 1.0) {
            for lon in stride(from: 0.0, through: 4.0, by: 1.0) {
                let coord = Coordinate3D(x: lon, y: lat, z: 42.0)  // all same value
                let feature = Feature(Point(coord))
                features.append(feature)
            }
        }
        let grid = FeatureCollection(features)
        let result = grid.isolines(breaks: [1.0])
        #expect(result.features.isEmpty)
    }

    @Test
    func testBreakEqualsAllValues() {
        let grid = makeGrid()
        // Break above all values — no lines expected
        let result = grid.isolines(breaks: [10.0])
        #expect(result.features.isEmpty)
    }

    @Test
    func testBreakBelowAllValues() {
        let grid = makeGrid()
        let result = grid.isolines(breaks: [-1.0])
        #expect(result.features.isEmpty)
    }

    @Test
    func testMinimalGrid() {
        // 2x2 grid (4 points) — minimal viable grid
        var features: [Feature] = []
        for (lon, lat, z) in [(0.0, 0.0, 0.0), (1.0, 0.0, 1.0),
                               (0.0, 1.0, 1.0), (1.0, 1.0, 2.0)] {
            let coord = Coordinate3D(x: lon, y: lat, z: z)
            let feature = Feature(Point(coord))
            features.append(feature)
        }
        let grid = FeatureCollection(features)
        let result = grid.isolines(breaks: [0.5])
        #expect(result.features.count == 1)
        let mls = result.features[0].geometry as! MultiLineString
        #expect(!mls.lineStrings.isEmpty)
    }

    @Test
    func testTooFewPoints() {
        var features: [Feature] = []
        features.append(Feature(Point(Coordinate3D(x: 0, y: 0))))
        features.append(Feature(Point(Coordinate3D(x: 1, y: 0))))
        features.append(Feature(Point(Coordinate3D(x: 0, y: 1))))
        let grid = FeatureCollection(features)
        let result = grid.isolines(breaks: [1.0])
        #expect(result.features.isEmpty)
    }

    @Test
    func testIsoLinesWithGridSize() {
        // Slightly irregular spacing — gridSize snaps to a regular grid
        var features: [Feature] = []
        for lat in stride(from: 0.0, through: 4.0, by: 1.0) {
            for lon in stride(from: 0.0, through: 4.0, by: 1.0) {
                // Add small sub-integer offset
                let dx = (lon + 0.3) - 2.0
                let dy = (lat + 0.3) - 2.0
                let z = sqrt(dx * dx + dy * dy)
                let coord = Coordinate3D(x: lon + 0.3, y: lat + 0.3, z: z)
                let feature = Feature(Point(coord))
                features.append(feature)
            }
        }
        let grid = FeatureCollection(features)
        let result = grid.isolines(breaks: [1.0], gridSize: 1.0)
        #expect(result.features.count == 1)
    }

    @Test
    func testAllBreaksSorted() {
        let grid = makeGrid()
        let result = grid.isolines(breaks: [2.0, 0.5, 1.0])
        #expect(result.features.count == 3)
        let breakValues = result.features.compactMap { $0.properties["break"] as? Double }
        #expect(breakValues == breakValues.sorted())
    }

    @Test
    func testMissingAltitudeReturnsEmpty() {
        // Points without altitude should be skipped
        var features: [Feature] = []
        for lat in stride(from: 0.0, through: 4.0, by: 1.0) {
            for lon in stride(from: 0.0, through: 4.0, by: 1.0) {
                let coord = Coordinate3D(x: lon, y: lat)  // no z
                let feature = Feature(Point(coord))
                features.append(feature)
            }
        }
        let grid = FeatureCollection(features)
        let result = grid.isolines(breaks: [1.0])
        #expect(result.features.isEmpty)
    }

    // MARK: - Projections

    @Test
    func isoLines4978() {
        let grid = makeGrid(projection: .epsg4978)
        let result = grid.isolines(breaks: [1.0, 2.0])

        #expect(result.features.count == 2)
        if result.features.count >= 2 {
            #expect(result.features[0].properties["break"] as? Double == 1.0)
            #expect(result.features[1].properties["break"] as? Double == 2.0)
        }
    }

    @Test
    func isoLines3857() {
        let grid = makeGrid(projection: .epsg3857)
        let result = grid.isolines(breaks: [1.0, 2.0])

        #expect(result.features.count == 2)
    }

}
