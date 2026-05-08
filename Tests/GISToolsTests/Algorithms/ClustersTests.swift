import Foundation
@testable import GISTools
import Testing

struct ClustersTests {

    // MARK: - DBSCAN

    @Test
    func dbscanBasic() async throws {
        let points: [Feature] = [
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0))),
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.1))),
            Feature(Point(Coordinate3D(latitude: 0.1, longitude: 0.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 10.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 10.1))),
            Feature(Point(Coordinate3D(latitude: 10.1, longitude: 10.0))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.dbscanClusters(maxDistance: 15_000.0, minPoints: 2)

        let c0: Int? = result.features[0].property(for: "cluster")
        #expect(c0 != nil)
        let c0Again: Int? = result.features[2].property(for: "cluster")
        #expect(c0Again == c0)

        let c1: Int? = result.features[3].property(for: "cluster")
        #expect(c1 != nil)
        #expect(c0 != c1)
    }

    @Test
    func dbscanNoise() async throws {
        let points: [Feature] = [
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0))),
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.1))),
            Feature(Point(Coordinate3D(latitude: 50.0, longitude: 50.0))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.dbscanClusters(maxDistance: 15_000.0, minPoints: 2)

        let dbscan: String? = result.features[2].property(for: "dbscan")
        #expect(dbscan == "noise")
    }

    @Test
    func dbscanEmpty() async throws {
        let fc = FeatureCollection()
        let result = fc.dbscanClusters(maxDistance: 1000.0)
        #expect(result.features.isEmpty)
    }

    // MARK: - K-means

    @Test
    func kmeansBasic() async throws {
        let points: [Feature] = [
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0))),
            Feature(Point(Coordinate3D(latitude: 0.1, longitude: 0.0))),
            Feature(Point(Coordinate3D(latitude: 10.0, longitude: 10.0))),
            Feature(Point(Coordinate3D(latitude: 10.1, longitude: 10.0))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.kmeansClusters(numberOfClusters: 2)

        let c0: Int? = result.features[0].property(for: "cluster")
        let c1: Int? = result.features[1].property(for: "cluster")
        let c2: Int? = result.features[2].property(for: "cluster")
        #expect(c0 != nil)
        #expect(c0 == c1)
        #expect(c0 != c2)

        let centroid: [Double]? = result.features[0].property(for: "centroid")
        #expect(centroid != nil)
    }

    @Test
    func kmeansEmpty() async throws {
        let fc = FeatureCollection()
        let result = fc.kmeansClusters(numberOfClusters: 2)
        #expect(result.features.isEmpty)
    }

    @Test
    func kmeansAutoK() async throws {
        let points: [Feature] = [
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0))),
            Feature(Point(Coordinate3D(latitude: 0.1, longitude: 0.0))),
            Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.1))),
            Feature(Point(Coordinate3D(latitude: 0.1, longitude: 0.1))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.kmeansClusters()

        let c0: Int? = result.features[0].property(for: "cluster")
        #expect(c0 != nil)
    }

}
