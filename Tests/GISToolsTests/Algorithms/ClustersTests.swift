import Foundation
@testable import GISTools
import Testing

struct ClustersTests {

    // MARK: - DBSCAN

    // Validates that DBSCAN clusters nearby points together and separates distant points into different clusters.
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

    // Validates that DBSCAN marks isolated points (fewer than minPoints within maxDistance) as noise.
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

    // Validates that DBSCAN returns an empty result for an empty feature collection.
    @Test
    func dbscanEmpty() async throws {
        let fc = FeatureCollection()
        let result = fc.dbscanClusters(maxDistance: 1000.0)
        #expect(result.features.isEmpty)
    }

    // MARK: - K-means

    // Validates that K-means clusters nearby points together and separates distant points.
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

    // Validates that K-means returns an empty result for an empty feature collection.
    @Test
    func kmeansEmpty() async throws {
        let fc = FeatureCollection()
        let result = fc.kmeansClusters(numberOfClusters: 2)
        #expect(result.features.isEmpty)
    }

    // Validates that K-means with automatic cluster count estimation produces clusters.
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

    // MARK: - Antimeridian

    @Test
    func antimeridian() async throws {
        let points: [Point] = [
            Point(Coordinate3D(latitude: 0.0, longitude: 178.0)),
            Point(Coordinate3D(latitude: 1.0, longitude: 178.5)),
            Point(Coordinate3D(latitude: 0.5, longitude: 179.0)),
            Point(Coordinate3D(latitude: 10.0, longitude: 179.0)),
            Point(Coordinate3D(latitude: 11.0, longitude: 178.5)),
        ]
        let fc = FeatureCollection(points.map({ Feature($0) }))
        let clustered = fc.dbscanClusters(maxDistance: 200_000.0, minPoints: 1)
        #expect(clustered.features.isNotEmpty)
    }

}
