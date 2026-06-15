import Foundation
@testable import GISTools
import Testing

struct SampleTests {

    @Test
    func sampleEmptyCollection() {
        let fc = FeatureCollection()
        let result = fc.sample(size: 0)
        #expect(result.features.isEmpty)
    }

    @Test
    func sampleSizeZero() {
        let points = BoundingBox.randomPoints(count: 10)
        let result = points.sample(size: 0)
        #expect(result.features.isEmpty)
    }

    @Test
    func sampleSizeOne() {
        let points = BoundingBox.randomPoints(count: 10)
        let result = points.sample(size: 1)
        #expect(result.features.count == 1)
    }

    @Test
    func sampleSizeExact() {
        let points = BoundingBox.randomPoints(count: 5)
        let result = points.sample(size: 5)
        #expect(result.features.count == 5)
    }

    @Test
    func sampleSizeClamped() {
        let points = BoundingBox.randomPoints(count: 3)
        let result = points.sample(size: 10)
        #expect(result.features.count == 3)
    }

    @Test
    func samplePreservesProperties() {
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

}
