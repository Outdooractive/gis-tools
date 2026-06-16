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
                maxDistance: maxDistance)

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
                    minPoints: minPoints)
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

        // Extract coordinates
        let coords: [Coordinate3D] = features.compactMap {
            ($0.geometry as? Point)?.coordinate
        }
        guard coords.count == count,
              k <= count
        else { return self }

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
        for _ in 0..<maxIter {
            // Assign each point to nearest centroid, tracking indices
            var clusterIndices: [[Int]] = Array(repeating: [], count: k)
            for i in 0..<count {
                let coord = coords[i]
                var best = 0
                var bestDist = Double.greatestFiniteMagnitude
                for j in 0..<k {
                    let d = coord.distance(from: centroids[j])
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
                var sumLat: Double = 0.0
                var sumLon: Double = 0.0
                for i in indices {
                    let w = max(weights[i], 0.0)
                    let coord = coords[i]
                    weightSum += w
                    sumLat += w * coord.latitude
                    sumLon += w * coord.longitude
                }

                guard weightSum > 0 else { continue }

                let newCentroid = Coordinate3D(
                    latitude: sumLat / weightSum,
                    longitude: sumLon / weightSum)
                if centroids[j].latitude != newCentroid.latitude
                    || centroids[j].longitude != newCentroid.longitude
                {
                    centroids[j] = newCentroid
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
                let d = coord.distance(from: centroids[j])
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
        maxDistance: CLLocationDistance
    ) -> [Int] {
        guard let point = features[index].geometry as? Point else { return [] }

        let center = point.coordinate

        // Bounding box optimisation in the native coordinate system
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
        for i in 0..<features.count {
            guard i != index,
                  let neighbor = features[i].geometry as? Point
            else { continue }

            let neighborCoord = neighbor.coordinate
            if bbox.contains(neighborCoord) {
                let d = center.distance(from: neighborCoord)
                if d <= maxDistance {
                    result.append(i)
                }
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
        minPoints: Int
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
                    maxDistance: maxDistance)
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
