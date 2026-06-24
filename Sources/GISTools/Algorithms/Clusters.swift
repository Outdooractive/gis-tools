#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-clusters-dbscan
// and https://github.com/Turfjs/turf/tree/master/packages/turf-clusters-kmeans

extension FeatureCollection {

    // MARK: - DBSCAN clustering

    /// Clusters points using the DBSCAN algorithm.
    ///
    /// Uses an R-tree spatial index for O(n log n) neighbourhood queries.
    /// Without the optimised indexing the underlying algorithm is O(n²).
    ///
    /// - Parameter maxDistance: Maximum distance between points in a cluster (meters).
    /// - Parameter minPoints: Minimum points to form a cluster (default 3).
    /// - Returns: A FeatureCollection with `cluster` (Int) and `dbscan`
    ///   ("core"|"edge"|"noise") properties on each point.
    public func dbscanClusters(
        maxDistance: CLLocationDistance,
        minPoints: Int = 3
    ) -> FeatureCollection {
        var features = self.features
        let count = features.count
        guard count > 0 else { return self }

        // Build spatial index for O(n log n) neighbourhood queries
        let indexed: [DBSCANIndexedPoint] = features.enumerated().compactMap { (i, f) in
            guard let p = f.geometry as? Point else { return nil }
            return DBSCANIndexedPoint(index: i, point: p)
        }
        let tree = RTree(indexed, nodeSize: 16)

        var visited = Array(repeating: false, count: count)
        var assigned = Array(repeating: false, count: count)
        var isNoise = Array(repeating: false, count: count)
        var clusterIds = Array(repeating: -1, count: count)
        var nextClusterId = 0

        for i in 0..<count {
            guard !visited[i] else { continue }
            visited[i] = true

            let neighbors = regionQuery(
                features: features,
                index: i,
                maxDistance: maxDistance,
                tree: tree)

            if neighbors.count >= minPoints {
                let clusterId = nextClusterId
                nextClusterId += 1
                expandCluster(
                    features: features,
                    clusterId: clusterId,
                    neighbors: neighbors,
                    visited: &visited,
                    assigned: &assigned,
                    clusterIds: &clusterIds,
                    isNoise: &isNoise,
                    maxDistance: maxDistance,
                    minPoints: minPoints,
                    tree: tree)
            }
            else {
                isNoise[i] = true
            }
        }

        for i in 0..<count {
            if clusterIds[i] >= 0 {
                features[i].setProperty(isNoise[i] ? "edge" : "core", for: "dbscan")
                features[i].setProperty(clusterIds[i], for: "cluster")
            }
            else {
                features[i].setProperty("noise", for: "dbscan")
            }
        }

        var result = FeatureCollection(features)
        if boundingBox != nil {
            result.updateBoundingBox(onlyIfNecessary: false)
        }
        return result
    }

    // MARK: - K-means clustering

    /// Clusters points using the K-means algorithm.
    ///
    /// Runtime is O(k·n·i) where k = number of clusters, n = point count,
    /// and i = iterations (capped at 100, typically converges in <10).
    ///
    /// - Parameter numberOfClusters: Number of clusters (default `sqrt(n/2)`).
    /// - Parameter weightAttribute: Property key for point weights (optional).
    ///   When set, centroids are computed as the weighted mean, matching
    ///   PostGIS's `ST_ClusterKMeans` behaviour.
    /// - Parameter seedIndex: Index used to seed the initial centroids (default `0`).
    /// - Returns: A FeatureCollection with `cluster` (Int) and `centroid`
    ///   ([Double]) properties on each point.
    public func kmeansClusters(
        numberOfClusters: Int? = nil,
        weightAttribute: String? = nil,
        seedIndex: Int = 0
    ) -> FeatureCollection {
        var features = self.features
        let count = features.count
        guard count > 0 else { return self }

        let k = min(
            numberOfClusters ?? Int(round(sqrt(Double(count) / 2.0))),
            count)
        guard k > 0 else { return self }

        // Extract coordinates and detect projection once
        let coords: [Coordinate3D] = features.compactMap {
            ($0.geometry as? Point)?.coordinate
        }
        guard coords.count == count, k <= count else { return self }
        let proj = coords.first?.projection ?? .epsg4326

        // Build projection-specific squared-distance function
        let distSq: (Coordinate3D, Coordinate3D) -> Double
        if proj == .epsg4326 {
            distSq = { a, b in
                let dLat = (b.latitude - a.latitude).degreesToRadians
                let dLon = (b.longitude - a.longitude).degreesToRadians
                let lat1 = a.latitude.degreesToRadians
                let lat2 = b.latitude.degreesToRadians
                let sinDLat = sin(dLat / 2.0)
                let sinDLon = sin(dLon / 2.0)
                let h = sinDLat * sinDLat + cos(lat1) * cos(lat2) * sinDLon * sinDLon
                // h is in [0, 1]; return squared chord length
                return h
            }
        }
        else if proj == .epsg4978 {
            distSq = { a, b in
                let dx = a.longitude - b.longitude
                let dy = a.latitude - b.latitude
                let dz = (a.altitude ?? 0.0) - (b.altitude ?? 0.0)
                return dx * dx + dy * dy + dz * dz
            }
        }
        else {
            distSq = { a, b in
                let dx = a.longitude - b.longitude
                let dy = a.latitude - b.latitude
                return dx * dx + dy * dy
            }
        }

        // Read weights if weightAttribute is provided
        let weights: [Double]
        if let weightAttribute {
            weights = features.map { feature in
                let v = feature.properties[weightAttribute]
                if let d = v as? Double { return d }
                if let i = v as? Int { return Double(i) }
                return 1.0
            }
        }
        else {
            weights = Array(repeating: 1.0, count: count)
        }

        // Initialize centroids from seedIndex
        let start = min(seedIndex, count - k)
        var centroids = (start..<(start + k)).map { coords[$0] }

        // K-means iterations
        let maxIter = 100
        var clusterIndices: [[Int]] = Array(repeating: [], count: k)
        for _ in 0..<maxIter {
            // Clear previous assignments
            for j in 0..<k {
                clusterIndices[j].removeAll(keepingCapacity: true)
            }

            // Assign each point to nearest centroid (using squared distance for comparison)
            for i in 0..<count {
                let coord = coords[i]
                var best = 0
                var bestDist = Double.greatestFiniteMagnitude
                for j in 0..<k {
                    let d = distSq(coord, centroids[j])
                    if d < bestDist {
                        bestDist = d
                        best = j
                    }
                }
                clusterIndices[best].append(i)
            }

            // Recompute centroids (weighted if weightAttribute is provided)
            var changed = false
            for j in 0..<k {
                let indices = clusterIndices[j]
                guard !indices.isEmpty else { continue }

                var weightSum: Double = 0.0
                var sumX: Double = 0.0
                var sumY: Double = 0.0
                for i in indices {
                    let w = max(weights[i], 0.0)
                    weightSum += w
                    sumX += w * coords[i].longitude
                    sumY += w * coords[i].latitude
                }

                guard weightSum > 0 else { continue }

                let newX = sumX / weightSum
                let newY = sumY / weightSum
                if centroids[j].longitude != newX || centroids[j].latitude != newY {
                    centroids[j].longitude = newX
                    centroids[j].latitude = newY
                    changed = true
                }
            }
            if !changed { break }
        }

        // Assign final clusters + centroids
        for i in 0..<count {
            let coord = coords[i]
            var best = 0
            var bestDist = Double.greatestFiniteMagnitude
            for j in 0..<k {
                let d = distSq(coord, centroids[j])
                if d < bestDist {
                    bestDist = d
                    best = j
                }
            }
            features[i].setProperty(best, for: "cluster")
            features[i].setProperty(
                [centroids[best].longitude, centroids[best].latitude],
                for: "centroid")
        }

        var result = FeatureCollection(features)
        if boundingBox != nil {
            result.updateBoundingBox(onlyIfNecessary: false)
        }
        return result
    }

    // MARK: - DBSCAN helpers

    private func regionQuery(
        features: [Feature],
        index: Int,
        maxDistance: CLLocationDistance,
        tree: RTree<DBSCANIndexedPoint>
    ) -> [Int] {
        guard let point = features[index].geometry as? Point else { return [] }

        let center = point.coordinate

        let delta: Double
        switch center.projection {
        case .epsg4326:
            delta = maxDistance / 111_000.0
        case .epsg3857, .epsg4978, .noSRID:
            delta = maxDistance
        }
        let bbox = BoundingBox(
            southWest: Coordinate3D(
                x: center.longitude - delta,
                y: center.latitude - delta,
                projection: center.projection),
            northEast: Coordinate3D(
                x: center.longitude + delta,
                y: center.latitude + delta,
                projection: center.projection))

        var result: [Int] = []
        for candidate in tree.search(inBoundingBox: bbox) {
            let i = candidate.index
            guard i != index else { continue }
            let d = center.distance(from: candidate.point.coordinate)
            if d <= maxDistance {
                result.append(i)
            }
        }
        return result
    }

    private func expandCluster(
        features: [Feature],
        clusterId: Int,
        neighbors: [Int],
        visited: inout [Bool],
        assigned: inout [Bool],
        clusterIds: inout [Int],
        isNoise: inout [Bool],
        maxDistance: CLLocationDistance,
        minPoints: Int,
        tree: RTree<DBSCANIndexedPoint>
    ) {
        var queue = neighbors
        var idx = 0
        while idx < queue.count {
            let neighborIndex = queue[idx]
            idx += 1

            if !visited[neighborIndex] {
                visited[neighborIndex] = true
                let nextNeighbors = regionQuery(
                    features: features,
                    index: neighborIndex,
                    maxDistance: maxDistance,
                    tree: tree)
                if nextNeighbors.count >= minPoints,
                   isNoise[neighborIndex]
                {
                    isNoise[neighborIndex] = false
                }
                queue.append(contentsOf: nextNeighbors)
            }

            if !assigned[neighborIndex] {
                assigned[neighborIndex] = true
                clusterIds[neighborIndex] = clusterId
            }
        }
    }

}

// MARK: - R-tree helper for DBSCAN

private struct DBSCANIndexedPoint: BoundingBoxRepresentable {
    let index: Int
    let point: Point

    var projection: Projection { point.projection }

    var boundingBox: BoundingBox? {
        get { point.boundingBox ?? point.calculateBoundingBox() }
        set {}
    }

    func calculateBoundingBox() -> BoundingBox? {
        point.calculateBoundingBox()
    }

    mutating func updateBoundingBox(onlyIfNecessary: Bool) -> BoundingBox? {
        point.calculateBoundingBox()
    }

    func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        point.intersects(otherBoundingBox)
    }
}
