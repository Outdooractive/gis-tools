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

    // MARK: - Algorithm comparison

    /// Tests a scenario where DBSCAN, K-means, and weighted K-means all produce
    /// measurably different results on the same data.
    ///
    /// Data: two dense clusters (A near origin, B near (10,0)), an outlier at (20,20),
    /// and one point in cluster A with extreme weight (1000).
    ///
    /// Expected behaviour:
    /// - DBSCAN: marks the outlier as noise, forms two clusters
    /// - K-means: assigns every point (no noise), centroid of cluster A is
    ///   the arithmetic mean of its members
    /// - Weighted K-means: centroid of cluster A is pulled toward the heavy point
    @Test
    func compareAlgorithms() async throws {
        var points: [Feature] = []
        // Cluster A (4 points, centroid ≈ (0.5, 0.25))
        points.append(Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0))))
        points.append(Feature(Point(Coordinate3D(latitude: 1.0, longitude: 0.0))))
        points.append(Feature(Point(Coordinate3D(latitude: 0.0, longitude: 1.0))))
        points.append(Feature(Point(Coordinate3D(latitude: 1.0, longitude: 1.0))))
        // Cluster B (4 points, centroid ≈ (10.5, 0.25))
        points.append(Feature(Point(Coordinate3D(latitude: 10.0, longitude: 0.0))))
        points.append(Feature(Point(Coordinate3D(latitude: 11.0, longitude: 0.0))))
        points.append(Feature(Point(Coordinate3D(latitude: 10.0, longitude: 1.0))))
        points.append(Feature(Point(Coordinate3D(latitude: 11.0, longitude: 1.0))))
        // Noise — too far from any cluster for DBSCAN
        points.append(Feature(Point(Coordinate3D(latitude: 20.0, longitude: 20.0))))

        var weighted = points
        weighted[0].properties["weight"] = 1000.0

        let fc = FeatureCollection(points)
        let wfc = FeatureCollection(weighted)

        // ---- DBSCAN ----
        // maxDistance=200km (~2° at the equator), minPts=3: each density-connected point needs ≥3 neighbors
        let dbscan = fc.dbscanClusters(maxDistance: 200_000.0, minPoints: 3)
        let dbscanClusters: Set<Int> = Set(dbscan.features.compactMap { $0.property(for: "cluster") })
        let dbscanNoise: [String] = dbscan.features.compactMap { $0.property(for: "dbscan") }
        #expect(dbscanClusters.count == 2)
        #expect(dbscanNoise.filter { $0 == "noise" }.count == 1)

        // ---- K-means ----
        // Every point is assigned, including the outlier
        let km = fc.kmeansClusters(numberOfClusters: 2)
        let kmClusters: Set<Int> = Set(km.features.compactMap { $0.property(for: "cluster") })
        #expect(kmClusters.count == 2)
        #expect(km.features.count == 9)

        // First point (0,0) is in cluster A; its centroid[ ] = [lon, lat]
        let kmCentroid: [Double]? = km.features[0].property(for: "centroid")
        if let centroidA = kmCentroid {
            // Arithmetic mean of (0,0), (1,0), (0,1), (1,1) → (0.5, 0.5)
            #expect(abs(centroidA[0] - 0.5) < 0.1)  // X / longitude
            #expect(abs(centroidA[1] - 0.5) < 0.1)  // Y / latitude
        }

        // ---- Weighted K-means ----
        // The heavy weight (1000) on (0,0) pulls its centroid toward the origin
        let wkm = wfc.kmeansClusters(numberOfClusters: 2, weightAttribute: "weight")
        let wkmCentroid: [Double]? = wkm.features[0].property(for: "centroid")

        if let centroidW = wkmCentroid {
            // Weighted centroid ≈ (0.001, 0.001) — almost exactly at (0,0)
            #expect(abs(centroidW[0]) < 0.05)
            #expect(abs(centroidW[1]) < 0.05)
        }

        // ---- Weighted centroid differs from unweighted ----
        if let cA = kmCentroid, let cW = wkmCentroid {
            let dx = cA[0] - cW[0]
            let dy = cA[1] - cW[1]
            #expect(sqrt(dx * dx + dy * dy) > 0.1)
        }

        // Uncomment to write per-cluster GeoJSON files for debugging:
//        let debugDir = URL(fileURLWithPath: "/tmp/cluster_debug")
//        try? FileManager.default.createDirectory(at: debugDir, withIntermediateDirectories: true)
//        let palette = ["#e6194b", "#3cb44b", "#4363d8", "#f58231", "#911eb4"]
//        func colorByCluster(_ fc: FeatureCollection) -> FeatureCollection {
//            var features = fc.features
//            for i in features.indices {
//                let clusterId: Int? = features[i].property(for: "cluster")
//                let color = palette[(clusterId ?? 0) % palette.count]
//                features[i].markerColor = color
//            }
//            return FeatureCollection(features)
//        }
//        func writeCluster(_ name: String, _ fc: FeatureCollection) {
//            guard let data = try? JSONEncoder().encode(colorByCluster(fc)) else { return }
//            try? data.write(to: debugDir.appendingPathComponent("\(name).geojson"))
//        }
//        writeCluster("dbscan_all", dbscan)
//        writeCluster("kmeans_all", km)
//        writeCluster("kmeans_weighted_all", wkm)
    }

    /// Weighted K-means changes cluster assignment (EPSG:4326).
    /// Without weights, points {0,9} form one cluster and {10,19} the other.
    /// A weight of 10 000 on (0,0) pulls that centroid so far left that point (9,0)
    /// switches to the other cluster.
    @Test
    func weightedKmeansChangesAssignmentEpsg4326() async throws {
        var p0 = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        var p1 = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 9.0)))
        var p2 = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 10.0)))
        var p3 = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 19.0)))
        p0.properties["w"] = 10_000.0
        let points = [p0, p1, p2, p3]
        let wPoints = [p0, p1, p2, p3]

        // seedIndex=1 so initial centroids are (9,0) and (10,0) — one per intended cluster
        let km = FeatureCollection(points).kmeansClusters(numberOfClusters: 2, seedIndex: 1)
        let wkm = FeatureCollection(wPoints).kmeansClusters(numberOfClusters: 2, weightAttribute: "w", seedIndex: 1)

        let c0km: Int? = km.features[0].property(for: "cluster")   // (0,0)
        let c1km: Int? = km.features[1].property(for: "cluster")   // (9,0)
        let c0wkm: Int? = wkm.features[0].property(for: "cluster") // (0,0)
        let c1wkm: Int? = wkm.features[1].property(for: "cluster") // (9,0)

        #expect(c0km == c1km)    // unweighted: (0,0) and (9,0) in the same cluster
        #expect(c0wkm != c1wkm)  // weighted: (9,0) flips to the other cluster
    }

    /// Weighted K-means changes cluster assignment (EPSG:3857, meters).
    @Test
    func weightedKmeansChangesAssignmentEpsg3857() async throws {
        var p0 = Feature(Point(Coordinate3D(x: 0.0, y: 0.0, projection: .epsg3857)))
        var p1 = Feature(Point(Coordinate3D(x: 9000.0, y: 0.0, projection: .epsg3857)))
        var p2 = Feature(Point(Coordinate3D(x: 10_000.0, y: 0.0, projection: .epsg3857)))
        var p3 = Feature(Point(Coordinate3D(x: 19_000.0, y: 0.0, projection: .epsg3857)))
        p0.properties["w"] = 10_000.0
        let points = [p0, p1, p2, p3]

        let km = FeatureCollection(points).kmeansClusters(numberOfClusters: 2, seedIndex: 1)
        let wkm = FeatureCollection(points).kmeansClusters(numberOfClusters: 2, weightAttribute: "w", seedIndex: 1)

        let c1km: Int? = km.features[1].property(for: "cluster")
        let c1wkm: Int? = wkm.features[1].property(for: "cluster")
        #expect(c1km == km.features[0].property(for: "cluster"))  // (9k,0) with (0,0) → same cluster
        #expect(c1wkm != wkm.features[0].property(for: "cluster")) // (9k,0) flips away
    }

    /// Weighted K-means changes cluster assignment (EPSG:4978, ECEF meters).
    @Test
    func weightedKmeansChangesAssignmentEpsg4978() async throws {
        var p0 = Feature(Point(Coordinate3D(x: 6_378_137.0, y: 0.0, z: 0.0, projection: .epsg4978)))
        var p1 = Feature(Point(Coordinate3D(x: 6_387_137.0, y: 0.0, z: 0.0, projection: .epsg4978)))
        var p2 = Feature(Point(Coordinate3D(x: 6_388_137.0, y: 0.0, z: 0.0, projection: .epsg4978)))
        var p3 = Feature(Point(Coordinate3D(x: 6_397_137.0, y: 0.0, z: 0.0, projection: .epsg4978)))
        p0.properties["w"] = 10_000.0
        let points = [p0, p1, p2, p3]

        let km = FeatureCollection(points).kmeansClusters(numberOfClusters: 2, seedIndex: 1)
        let wkm = FeatureCollection(points).kmeansClusters(numberOfClusters: 2, weightAttribute: "w", seedIndex: 1)

        let c1km: Int? = km.features[1].property(for: "cluster")
        let c1wkm: Int? = wkm.features[1].property(for: "cluster")
        #expect(c1km == km.features[0].property(for: "cluster"))  // unweighted: together
        #expect(c1wkm != wkm.features[0].property(for: "cluster")) // weighted: flips
    }

    /// Confirms that weighted K-means accepts both `Int` and `Double` property values as weights.
    @Test
    func weightedKmeansMixedIntDoubleWeights() async throws {
        // Some properties with Int values, some with Double — as happens with DBF read-back
        var p0 = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 0.0)))
        var p1 = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 9.0)))
        var p2 = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 10.0)))
        var p3 = Feature(Point(Coordinate3D(latitude: 0.0, longitude: 19.0)))
        p0.properties["w"] = 10_000    // Int
        p1.properties["w"] = 1.0        // Double
        p2.properties["w"] = 1          // Int
        p3.properties["w"] = 1.0        // Double

        let wkm = FeatureCollection([p0, p1, p2, p3]).kmeansClusters(
            numberOfClusters: 2, weightAttribute: "w", seedIndex: 1)

        let c0: Int? = wkm.features[0].property(for: "cluster")
        let c1: Int? = wkm.features[1].property(for: "cluster")
        #expect(c0 != c1)  // (9,0) flips away from heavy (0,0) — same as pure-Double test
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

        // Strip to only what geojson.io needs: marker colour + cluster info
        func stripToStyling(_ features: [Feature]) -> [Feature] {
            features.map { f in
                var s = Feature((f.geometry as? Point)!, id: nil, properties: [:])
                s.properties["marker-color"] = f.properties["marker-color"]
                s.properties["cluster"] = f.properties["cluster"]
                s.properties["dbscan"] = f.properties["dbscan"]
                return s
            }
        }

        for (projection, label) in projections {
            let projected = projection == .epsg4326 ? fc : fc.projected(to: projection)

            // K-means
            let kc = projected.kmeansClusters(numberOfClusters: 10)
            var kcFeatures = kc.features
            for i in 0..<kcFeatures.count {
                let clusterId: Int? = kcFeatures[i].property(for: "cluster")
                let color = palette[(clusterId ?? 0) % palette.count]
                kcFeatures[i].markerColor = color
            }
            let kcColored = FeatureCollection(stripToStyling(kcFeatures))
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
                kwFeatures[i].markerColor = color
            }
            let kwColored = FeatureCollection(stripToStyling(kwFeatures))
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
                    dcFeatures[i].markerColor = "#cccccc"
                }
                else if let clusterId {
                    let color = palette[clusterId % palette.count]
                    dcFeatures[i].markerColor = color
                }
            }
            let dcColored = FeatureCollection(stripToStyling(dcFeatures))
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
