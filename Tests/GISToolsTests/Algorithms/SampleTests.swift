import Foundation
@testable import GISTools
import Testing

struct SampleTests {

    /// Tests that sampling an empty collection returns an empty collection.
    @Test
    func sampleEmptyCollection() async throws {
        let fc = FeatureCollection()
        let result = fc.sample(size: 0)
        #expect(result.features.isEmpty)
    }

    /// Tests that sampling with size zero returns an empty collection.
    @Test
    func sampleSizeZero() async throws {
        let points = BoundingBox.randomPoints(count: 10)
        let result = points.sample(size: 0)
        #expect(result.features.isEmpty)
    }

    /// Tests that sampling a single element returns one feature.
    @Test
    func sampleSizeOne() async throws {
        let points = BoundingBox.randomPoints(count: 10)
        let result = points.sample(size: 1)
        #expect(result.features.count == 1)
    }

    /// Tests that sampling exactly the collection size returns all features.
    @Test
    func sampleSizeExact() async throws {
        let points = BoundingBox.randomPoints(count: 5)
        let result = points.sample(size: 5)
        #expect(result.features.count == 5)
    }

    /// Tests that sampling a size larger than the collection is clamped.
    @Test
    func sampleSizeClamped() async throws {
        let points = BoundingBox.randomPoints(count: 3)
        let result = points.sample(size: 10)
        #expect(result.features.count == 3)
    }

    /// Tests that sampled features retain their properties.
    @Test
    func samplePreservesProperties() async throws {
        var features: [Feature] = []
        for i in 0 ..< 10 {
            var feature = Feature(Point(Coordinate3D(latitude: Double(i), longitude: 0.0)))
            feature.properties = ["id": i]
            features.append(feature)
        }
        let fc = FeatureCollection(features)
        let result = fc.sample(size: 3)
        #expect(result.features.count == 3)
        for feature in result.features {
            #expect(feature.properties["id"] != nil)
        }
    }
    // MARK: - EPSG:3857

    @Test
    func sample3857() async throws {
        let features = [
            Feature(Point(Coordinate3D(x: 0.0, y: 0.0))),
            Feature(Point(Coordinate3D(x: 100_000.0, y: 0.0))),
            Feature(Point(Coordinate3D(x: 0.0, y: 100_000.0))),
        ]
        let fc = FeatureCollection(features)
        let result = fc.sample(size: 2)
        #expect(result.features.count == 2)
    }

    @Test
    func sample4978() async throws {
        let p1 = Coordinate3D(latitude: 0.0, longitude: 0.0).projected(to: .epsg4978)
        let p2 = Coordinate3D(latitude: 1.0, longitude: 0.0).projected(to: .epsg4978)
        let p3 = Coordinate3D(latitude: 0.0, longitude: 1.0).projected(to: .epsg4978)
        let features = [
            Feature(Point(p1)),
            Feature(Point(p2)),
            Feature(Point(p3)),
        ]
        let fc = FeatureCollection(features)
        let result = fc.sample(size: 2)
        #expect(result.features.count == 2)
    }

}
