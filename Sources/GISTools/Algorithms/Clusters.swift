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
    /// - Returns: A FeatureCollection with `cluster` (Int) and `centroid`
    ///   ([Double]) properties on each point.
    public func kmeansClusters(
        numberOfClusters: Int? = nil
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

        // Initialize centroids from first k points
        var centroids = Array(coords.prefix(k))

        // K-means iterations
        let maxIter = 100
        for _ in 0..<maxIter {
            // Assign each point to nearest centroid
            var clusters: [[Coordinate3D]] = Array(repeating: [], count: k)
            for coord in coords {
                var best = 0
                var bestDist = Double.greatestFiniteMagnitude
                for j in 0..<k {
                    let d = coord.distance(from: centroids[j])
                    if d < bestDist {
                        bestDist = d
                        best = j
                    }
                }
                clusters[best].append(coord)
            }

            // Recompute centroids
            var changed = false
            for j in 0..<k {
                guard !clusters[j].isEmpty else { continue }

                let sumLat = clusters[j].reduce(0.0) { $0 + $1.latitude }
                let sumLon = clusters[j].reduce(0.0) { $0 + $1.longitude }
                let newCentroid = Coordinate3D(
                    latitude: sumLat / Double(clusters[j].count),
                    longitude: sumLon / Double(clusters[j].count))
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

        // Approximate bounds: 1 degree ≈ 111 km at equator
        let delta = maxDistance / 111_000.0
        let bbox = BoundingBox(
            southWest: Coordinate3D(
                latitude: center.latitude - delta,
                longitude: center.longitude - delta),
            northEast: Coordinate3D(
                latitude: center.latitude + delta,
                longitude: center.longitude + delta))

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
