import Foundation
import Testing
@testable import GISTools

/// Differential fixtures generated from Shapely/GEOS by
/// `scripts/generate_property_fixtures.py`.
struct PropertyDifferentialTests {

    @Test
    func overlayMatchesShapelyFixtures() throws {
        let fixtures = try loadFixtures()
        for (index, fixture) in fixtures.overlay.enumerated() {
            let a = try polygon(fixture.a)
            let b = try polygon(fixture.b)

            assertArea(
                area(of: a.intersection(with: b)),
                fixture.intersectionArea,
                label: "overlay \(index) intersection")
            assertArea(
                area(of: a.difference(with: b)),
                fixture.differenceArea,
                label: "overlay \(index) difference")
            assertArea(
                a.union(with: b)?.area ?? 0.0,
                fixture.unionArea,
                label: "overlay \(index) union")
            assertArea(
                area(of: a.symmetricDifference(with: b)),
                fixture.symmetricDifferenceArea,
                label: "overlay \(index) symmetric difference")
        }
    }

    @Test
    func bufferMatchesShapelyFixtures() throws {
        let fixtures = try loadFixtures()
        for (index, fixture) in fixtures.buffer.enumerated() {
            let polygon = try polygon(fixture.polygon)
            let buffer = try #require(
                polygon.buffered(by: fixture.distance, steps: 64),
                "buffer \(index) returned nil")
            assertArea(
                buffer.area,
                fixture.area,
                label: "buffer \(index) area",
                relativeTolerance: 0.02)
        }
    }

    @Test
    func polygonizeMatchesShapelyFixtures() throws {
        let fixtures = try loadFixtures()
        for (index, fixture) in fixtures.polygonize.enumerated() {
            let lines = try fixture.lines.map { coordinates -> LineString in
                try #require(LineString(coordinates.map {
                    Coordinate3D(x: $0[0], y: $0[1], projection: .epsg3857)
                }))
            }
            let result = FeatureCollection(lines.map { Feature($0) }).polygonized()
            let areas = result.features
                .compactMap { $0.geometry as? Polygon }
                .map(\.area)
                .sorted()

            #expect(areas.count == fixture.areas.count, "polygonize \(index) count")
            for (area, expected) in zip(areas, fixture.areas) {
                assertArea(area, expected, label: "polygonize \(index) area")
            }
        }
    }

    private func area(of geometry: (any PolygonGeometry)?) -> Double {
        guard let geometry else { return 0.0 }
        if let polygon = geometry as? Polygon {
            return polygon.area
        }
        if let multiPolygon = geometry as? MultiPolygon {
            return multiPolygon.area
        }
        return 0.0
    }

    private func polygon(_ ring: [[Double]]) throws -> Polygon {
        let coordinates = ring.map {
            Coordinate3D(x: $0[0], y: $0[1], projection: .epsg3857)
        }
        return try #require(Polygon([coordinates]))
    }

    private func assertArea(
        _ actual: Double,
        _ expected: Double,
        label: String,
        relativeTolerance: Double = 0.005
    ) {
        let tolerance = max(1.0, abs(expected) * relativeTolerance)
        #expect(
            abs(actual - expected) <= tolerance,
            "\(label): actual \(actual), expected \(expected), tolerance \(tolerance)")
    }

    private func loadFixtures() throws -> Fixtures {
        let data = try TestData.dataFromFile(
            package: "Property",
            name: "DifferentialOperations")
        return try JSONDecoder().decode(Fixtures.self, from: data)
    }

}

private struct Fixtures: Decodable {
    let overlay: [OverlayFixture]
    let buffer: [BufferFixture]
    let polygonize: [PolygonizeFixture]
}

private struct OverlayFixture: Decodable {
    let a: [[Double]]
    let b: [[Double]]
    let intersectionArea: Double
    let differenceArea: Double
    let unionArea: Double
    let symmetricDifferenceArea: Double
}

private struct BufferFixture: Decodable {
    let polygon: [[Double]]
    let distance: Double
    let area: Double
}

private struct PolygonizeFixture: Decodable {
    let lines: [[[Double]]]
    let areas: [Double]
}
