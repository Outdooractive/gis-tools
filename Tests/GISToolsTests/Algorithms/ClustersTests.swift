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

    // MARK: - Projection-specific

    /// Validates DBSCAN clustering works with EPSG:3857 (Web Mercator).
    @Test
    func dbscanEpsg3857() async throws {
        // Two clusters ~1 km apart in projected meters
        let points: [Feature] = [
            Feature(Point(Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857))),
            Feature(Point(Coordinate3D(x: 500.0, y: 0.0, projection: .epsg3857))),
            Feature(Point(Coordinate3D(x: 0.0, y: 500.0, projection: .epsg3857))),
            Feature(Point(Coordinate3D(x: 100_000.0, y: 100_000.0, projection: .epsg3857))),
            Feature(Point(Coordinate3D(x: 100_500.0, y: 100_000.0, projection: .epsg3857))),
            Feature(Point(Coordinate3D(x: 100_000.0, y: 100_500.0, projection: .epsg3857))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.dbscanClusters(maxDistance: 1000.0, minPoints: 2)

        let c0: Int? = result.features[0].property(for: "cluster")
        let c1: Int? = result.features[3].property(for: "cluster")
        #expect(c0 != nil)
        #expect(c1 != nil)
        #expect(c0 != c1)
    }

    /// Validates K-means clustering works with EPSG:3857 (Web Mercator).
    @Test
    func kmeansEpsg3857() async throws {
        let points: [Feature] = [
            Feature(Point(Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857))),
            Feature(Point(Coordinate3D(x: 1000.0, y: 0.0, projection: .epsg3857))),
            Feature(Point(Coordinate3D(x: 100_000.0, y: 100_000.0, projection: .epsg3857))),
            Feature(Point(Coordinate3D(x: 101_000.0, y: 100_000.0, projection: .epsg3857))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.kmeansClusters(numberOfClusters: 2)

        let c0: Int? = result.features[0].property(for: "cluster")
        let c2: Int? = result.features[2].property(for: "cluster")
        #expect(c0 != nil)
        #expect(c2 != nil)
        #expect(c0 != c2)
    }

    /// Validates DBSCAN clustering works with EPSG:4978 (ECEF).
    @Test
    func dbscanEpsg4978() async throws {
        // Points near Null Island in ECEF space
        let points: [Feature] = [
            Feature(Point(Coordinate3D(x: 6_378_137.0, y: 0.0, z: 0.0, projection: .epsg4978))),
            Feature(Point(Coordinate3D(x: 6_378_137.0, y: 500.0, z: 0.0, projection: .epsg4978))),
            Feature(Point(Coordinate3D(x: 6_378_137.0, y: 0.0, z: 500.0, projection: .epsg4978))),
            Feature(Point(Coordinate3D(x: -6_378_137.0, y: 0.0, z: 0.0, projection: .epsg4978))),
            Feature(Point(Coordinate3D(x: -6_378_137.0, y: 500.0, z: 0.0, projection: .epsg4978))),
            Feature(Point(Coordinate3D(x: -6_378_137.0, y: 0.0, z: 500.0, projection: .epsg4978))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.dbscanClusters(maxDistance: 1000.0, minPoints: 2)

        let c0: Int? = result.features[0].property(for: "cluster")
        let c3: Int? = result.features[3].property(for: "cluster")
        #expect(c0 != nil)
        #expect(c3 != nil)
        #expect(c0 != c3)
    }

    /// Validates K-means clustering works with EPSG:4978 (ECEF).
    @Test
    func kmeansEpsg4978() async throws {
        // Two clusters in ECEF: one near (6.3M, 0, 0), another near (0, 6.3M, 0)
        let points: [Feature] = [
            Feature(Point(Coordinate3D(x: 6_378_137.0, y: 0.0, z: 0.0, projection: .epsg4978))),
            Feature(Point(Coordinate3D(x: 6_378_137.0, y: 1000.0, z: 0.0, projection: .epsg4978))),
            Feature(Point(Coordinate3D(x: 0.0, y: 6_378_137.0, z: 0.0, projection: .epsg4978))),
            Feature(Point(Coordinate3D(x: 0.0, y: 6_378_137.0, z: 1000.0, projection: .epsg4978))),
        ]
        let fc = FeatureCollection(points)
        let result = fc.kmeansClusters(numberOfClusters: 2)

        let c0: Int? = result.features[0].property(for: "cluster")
        let c2: Int? = result.features[2].property(for: "cluster")
        #expect(c0 != nil)
        #expect(c2 != nil)
        #expect(c0 != c2)
    }

    // MARK: - Weighted K-means

    /// Validates weighted K-means shifts centroids toward higher-weight points.
    @Test
    func kmeansWeighted() async throws {
        var f1 = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        f1.properties = ["weight": 100.0]
        var f2 = Feature(Point(Coordinate3D(latitude: 0.1, longitude: 0.0)))
        f2.properties = ["weight": 1.0]
        var f3 = Feature(Point(Coordinate3D(latitude: 10.0, longitude: 10.0)))
        f3.properties = ["weight": 100.0]
        var f4 = Feature(Point(Coordinate3D(latitude: 10.1, longitude: 10.0)))
        f4.properties = ["weight": 1.0]
        let points = [f1, f2, f3, f4]
        let fc = FeatureCollection(points)
        let result = fc.kmeansClusters(numberOfClusters: 2, weightAttribute: "weight")

        for feature in result.features {
            let c: Int? = feature.property(for: "cluster")
            #expect(c != nil)
        }
        let c0: Int? = result.features[0].property(for: "cluster")
        let c1: Int? = result.features[1].property(for: "cluster")
        let c2: Int? = result.features[2].property(for: "cluster")
        #expect(c0 != nil && c1 != nil && c2 != nil)
        #expect(c0 == c1) // both heavy points in same cluster
        #expect(c0 != c2)
    }

    /// Validates weighted K-means with EPSG:3857.
    @Test
    func kmeansWeightedEpsg3857() async throws {
        var f1 = Feature(Point(Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857)))
        f1.properties = ["pop": 1000.0]
        var f2 = Feature(Point(Coordinate3D(x: 100.0, y: 0.0, projection: .epsg3857)))
        f2.properties = ["pop": 1.0]
        var f3 = Feature(Point(Coordinate3D(x: 100_000.0, y: 100_000.0, projection: .epsg3857)))
        f3.properties = ["pop": 1000.0]
        var f4 = Feature(Point(Coordinate3D(x: 100_100.0, y: 100_000.0, projection: .epsg3857)))
        f4.properties = ["pop": 1.0]
        let points = [f1, f2, f3, f4]
        let fc = FeatureCollection(points)
        let result = fc.kmeansClusters(numberOfClusters: 2, weightAttribute: "pop")

        for feature in result.features {
            let c: Int? = feature.property(for: "cluster")
            #expect(c != nil)
        }
        let c0: Int? = result.features[0].property(for: "cluster")
        let c2: Int? = result.features[2].property(for: "cluster")
        #expect(c0 != c2)
    }

    /// Validates weighted K-means with EPSG:4978 (ECEF).
    @Test
    func kmeansWeightedEpsg4978() async throws {
        var f1 = Feature(Point(Coordinate3D(x: 6_378_137.0, y: 0.0, z: 0.0, projection: .epsg4978)))
        f1.properties = ["pop": 1000.0]
        var f2 = Feature(Point(Coordinate3D(x: 6_378_237.0, y: 0.0, z: 0.0, projection: .epsg4978)))
        f2.properties = ["pop": 1.0]
        var f3 = Feature(Point(Coordinate3D(x: 0.0, y: 6_378_137.0, z: 0.0, projection: .epsg4978)))
        f3.properties = ["pop": 1000.0]
        var f4 = Feature(Point(Coordinate3D(x: 0.0, y: 6_378_237.0, z: 0.0, projection: .epsg4978)))
        f4.properties = ["pop": 1.0]
        let points = [f1, f2, f3, f4]
        let fc = FeatureCollection(points)
        let result = fc.kmeansClusters(numberOfClusters: 2, weightAttribute: "pop")

        for feature in result.features {
            let c: Int? = feature.property(for: "cluster")
            #expect(c != nil)
        }
        let c0: Int? = result.features[0].property(for: "cluster")
        let c2: Int? = result.features[2].property(for: "cluster")
        #expect(c0 != c2)
    }

    // MARK: - Natural Earth clustering (disabled, requires shapefile trait)

    /// Reads the Natural Earth shapefile, runs K-means and DBSCAN (k=10) on each
    /// supported projection, colours features by cluster, and writes GeoJSONs to
    /// `/tmp/natural_earth_clusters/`.
    @Test(.disabled("Enable to regenerate cluster GeoJSONs"))
    func clusterNaturalEarth() async throws {
        #if EnableShapefileSupport
        let url = TestData.shapefileUrl(package: "Shapefiles", name: "ne_10m_populated_places_simple")
        let fc = try ShapefileCoder.read(from: url)

        let palette = [
            "#e6194b", "#3cb44b", "#ffe119", "#4363d8", "#f58231",
            "#911eb4", "#42d4f4", "#f032e6", "#bfef45", "#fabed4",
        ]

        let outputDir = URL(fileURLWithPath: "/tmp/natural_earth_clusters")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let projections: [(Projection, String)] = [
            (.epsg4326, "4326"),
            (.epsg3857, "3857"),
            (.epsg4978, "4978"),
        ]

        for (projection, label) in projections {
            let projected = projection == .epsg4326 ? fc : fc.projected(to: projection)

            // K-means
            let kc = projected.kmeansClusters(numberOfClusters: 10)
            var kcFeatures = kc.features
            for i in 0..<kcFeatures.count {
                let clusterId: Int? = kcFeatures[i].property(for: "cluster")
                let color = palette[(clusterId ?? 0) % palette.count]
                kcFeatures[i].setProperty(color, for: "fill")
                kcFeatures[i].setProperty(0.4, for: "fill-opacity")
                kcFeatures[i].setProperty(color, for: "stroke")
                kcFeatures[i].setProperty(1.0, for: "stroke-width")
            }
            let kcColored = FeatureCollection(kcFeatures)
            let kmPath = outputDir.appendingPathComponent("kmeans_EPSG\(label).geojson")
            if let kmData = try? JSONEncoder().encode(kcColored) {
                try kmData.write(to: kmPath)
            }

            // Weighted K-means (by population)
            let kw = projected.kmeansClusters(numberOfClusters: 10, weightAttribute: "pop_max")
            var kwFeatures = kw.features
            for i in 0..<kwFeatures.count {
                let clusterId: Int? = kwFeatures[i].property(for: "cluster")
                let color = palette[(clusterId ?? 0) % palette.count]
                kwFeatures[i].setProperty(color, for: "fill")
                kwFeatures[i].setProperty(0.4, for: "fill-opacity")
                kwFeatures[i].setProperty(color, for: "stroke")
                kwFeatures[i].setProperty(1.0, for: "stroke-width")
            }
            let kwColored = FeatureCollection(kwFeatures)
            let kwPath = outputDir.appendingPathComponent("kmeans_weighted_popmax_EPSG\(label).geojson")
            if let kwData = try? JSONEncoder().encode(kwColored) {
                try kwData.write(to: kwPath)
            }

            // DBSCAN
            let dc = projected.dbscanClusters(maxDistance: 100_000.0, minPoints: 3)
            var dcFeatures = dc.features
            for i in 0..<dcFeatures.count {
                let clusterId: Int? = dcFeatures[i].property(for: "cluster")
                let dbscan: String? = dcFeatures[i].property(for: "dbscan")
                if dbscan == "noise" {
                    dcFeatures[i].setProperty("#cccccc", for: "fill")
                    dcFeatures[i].setProperty(0.2, for: "fill-opacity")
                    dcFeatures[i].setProperty("#999999", for: "stroke")
                    dcFeatures[i].setProperty(0.5, for: "stroke-width")
                }
                else if let clusterId {
                    let color = palette[clusterId % palette.count]
                    dcFeatures[i].setProperty(color, for: "fill")
                    dcFeatures[i].setProperty(0.4, for: "fill-opacity")
                    dcFeatures[i].setProperty(color, for: "stroke")
                    dcFeatures[i].setProperty(1.0, for: "stroke-width")
                }
            }
            let dcColored = FeatureCollection(dcFeatures)
            let dbPath = outputDir.appendingPathComponent("dbscan_EPSG\(label).geojson")
            if let dbData = try? JSONEncoder().encode(dcColored) {
                try dbData.write(to: dbPath)
            }

            print("Wrote EPSG:\(label) results to \(outputDir.path)")
        }
        #else
        print("Skipping — EnableShapefileSupport trait is not enabled")
        #endif
    }

}
