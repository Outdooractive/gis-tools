#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Node on edge

extension Graph {

    /// Finds a node on the nearest edge to the given coordinate, splitting that
    /// edge.
    ///
    /// A bounding-box query around `coordinate` selects candidate edges via the
    /// spatial index, then the perpendicular foot of `coordinate` on each
    /// candidate segment is computed. If a nearby edge is found, a new node is
    /// inserted at the foot, linking to both endpoints.
    /// - Parameter coordinate: The coordinate to snap to the nearest edge.
    /// - Parameter tolerance: The maximum distance (in meters) for a match
    ///   (default: ``nodeTolerance``).
    /// - Returns: The newly inserted node, or `nil` if no edge is within
    ///   `tolerance`.
    public mutating func nodeOnEdge(
        near coordinate: Coordinate3D,
        tolerance: CLLocationDistance? = nil
    ) -> Node? {
        let tol = tolerance ?? nodeTolerance

        // Gather candidate edges from nodes within `tol` + a safety margin of
        // the longest possible incident edge. We use a generous initial radius
        // and fall back to scanning all nodes if nothing is found nearby.
        let searchRadius = max(tol, 50.0)
        var candidateEdges: [(edge: Edge, pairID: Int)] = []
        var seenPairs: Set<Int> = []

        for candidateIndex in spatialIndex.candidates(near: coordinate) {
            let node = adjacencyList[candidateIndex].node
            guard node.coordinate.distance(from: coordinate) <= searchRadius else { continue }

            for edge in adjacencyList[candidateIndex].edges {
                let a = min(edge.from.index, edge.to.index)
                let b = max(edge.from.index, edge.to.index)
                let pairID = a &* 1_000_003 &+ b
                if seenPairs.insert(pairID).inserted {
                    candidateEdges.append((edge, pairID))
                }
            }
        }

        if candidateEdges.isEmpty {
            // Fallback: scan all edges. Keeps correctness for sparse graphs
            // where the spatial cell size is small relative to edge lengths.
            for edgeList in adjacencyList {
                for edge in edgeList.edges {
                    let a = min(edge.from.index, edge.to.index)
                    let b = max(edge.from.index, edge.to.index)
                    let pairID = a &* 1_000_003 &+ b
                    if seenPairs.insert(pairID).inserted {
                        candidateEdges.append((edge, pairID))
                    }
                }
            }
        }

        var bestEdge: Edge?
        var bestEdgeFoot: Coordinate3D?
        var bestEdgeDistance: CLLocationDistance = .greatestFiniteMagnitude

        for candidate in candidateEdges {
            let edge = candidate.edge
            let segment = LineSegment(first: edge.from.coordinate, second: edge.to.coordinate)

            guard let foot = segment.perpendicularFoot(from: coordinate, clampToEnds: true) else { continue }

            let distance = foot.distance(from: coordinate)
            if distance < bestEdgeDistance {
                bestEdgeDistance = distance
                bestEdge = edge
                bestEdgeFoot = foot
            }
            if distance <= tol {
                break
            }
        }

        guard let bestEdge = bestEdge,
              bestEdgeDistance <= tol,
              let bestEdgeFoot = bestEdgeFoot
        else { return nil }

        let source = createNode(at: bestEdgeFoot)

        // Re-link endpoints through the new node, preserving directionality.
        if bestEdge.isDirected {
            // Replace the original directed edge with two directed edges
            // following the same orientation.
            removeDirectedEdge(from: bestEdge.from, to: bestEdge.to)
            addDirectedEdge(from: bestEdge.from, to: source, feature: bestEdge.feature, isDirected: true)
            addDirectedEdge(from: source, to: bestEdge.to, feature: bestEdge.feature, isDirected: true)
        }
        else {
            removeUndirectedEdge(from: bestEdge.from, to: bestEdge.to)
            addUndirectedEdge(from: bestEdge.from, to: source, feature: bestEdge.feature)
            addUndirectedEdge(from: source, to: bestEdge.to, feature: bestEdge.feature)
        }

        return source
    }

}
