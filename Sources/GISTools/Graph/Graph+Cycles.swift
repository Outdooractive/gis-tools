#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Cycle detection

extension Graph {

    /// The curvature direction for cycle detection.
    public enum Curvature: Sendable {
        /// Only left turns are allowed (turn angle > `turnTolerance`).
        case left
        /// Only right turns are allowed (turn angle < -`turnTolerance`).
        case right
        /// Direction of turn is ignored.
        case ignore
    }

    /// Detects cycles in the graph starting from the given node.
    ///
    /// A cycle is a closed walk that returns to the start node without
    /// revisiting any intermediate node. Cycles are deduplicated by a canonical
    /// form that is invariant under rotation and (for undirected cycles)
    /// reversal, so each distinct cycle is reported exactly once per call.
    ///
    /// The three bounding limits keep the exponential search tractable on real
    /// road networks:
    /// - `maximumPathLength` caps the total path distance.
    /// - `maximumPathNodeCount` caps the number of nodes in the path.
    /// - `maximumFromSourceDistance` caps the straight-line distance from the
    ///   origin to the current node.
    ///
    /// - Parameters:
    ///   - source: The starting node.
    ///   - curvature: Restrict cycles to left/right turns only (default
    ///     `.ignore`).
    ///   - maximumPathLength: Maximum total path distance in meters.
    ///   - maximumPathNodeCount: Maximum number of nodes in a cycle.
    ///   - maximumFromSourceDistance: Maximum straight-line distance from the
    ///     origin in meters.
    ///   - turnTolerance: Minimum absolute turn angle in degrees for
    ///     `curvature` to take effect (default `5.0`).
    ///   - minTurnChord: Minimum distance in meters between the first and third
    ///     point of a turn for the angle to be evaluated; very short chords are
    ///     numerically unreliable (default `5.0`).
    /// - Returns: An array of cycles, each represented as a path of nodes where
    ///   the first and last node are the same.
    public func cycles(
        from source: Node,
        curvature: Curvature = .ignore,
        maximumPathLength: CLLocationDistance? = nil,
        maximumPathNodeCount: Int? = nil,
        maximumFromSourceDistance: CLLocationDistance? = nil,
        turnTolerance: CLLocationDegrees = 5.0,
        minTurnChord: CLLocationDistance = 5.0
    ) -> [[Node]] {
        var context = CycleSearchContext(
            curvature: curvature,
            turnTolerance: turnTolerance,
            minTurnChord: minTurnChord,
            maximumPathLength: maximumPathLength,
            maximumPathNodeCount: maximumPathNodeCount,
            maximumFromSourceDistance: maximumFromSourceDistance,
            isDirected: isDirected)

        var path: [Node] = [source]
        var pathIndices: Set<Int> = [source.index]
        var pathLength: CLLocationDistance = 0.0
        var cycles: [[Node]] = []
        var seenCanonical: Set<[Int]> = []

        detectCycles(
            origin: source,
            current: source,
            previous: nil,
            path: &path,
            pathIndices: &pathIndices,
            pathLength: &pathLength,
            context: &context,
            cycles: &cycles,
            seenCanonical: &seenCanonical)

        return cycles
    }

    // MARK: - Cycle detection internals

    func detectCycles(
        origin: Node,
        current: Node,
        previous: Node?,
        path: inout [Node],
        pathIndices: inout Set<Int>,
        pathLength: inout CLLocationDistance,
        context: inout CycleSearchContext,
        cycles: inout [[Node]],
        seenCanonical: inout Set<[Int]>
    ) {
        // Bounding limits (checked before expanding neighbors).
        if let maxNodes = context.maximumPathNodeCount,
            path.count > maxNodes
        {
            return
        }
        if let maxLength = context.maximumPathLength,
            pathLength > maxLength
        {
            return
        }
        if let maxFromSource = context.maximumFromSourceDistance,
           origin.coordinate.distance(from: current.coordinate) > maxFromSource
        {
            return
        }

        let edges = adjacencyList[current.index].edges

        for edge in edges {
            let neighborIndex = edge.to.index
            let neighbor = adjacencyList[neighborIndex].node

            // Don't immediately backtrack in undirected graphs.
            if let previous,
               neighbor == previous,
               !edge.isDirected
            {
                continue
            }

            // Closed cycle: neighbor is the origin.
            if neighbor == origin {
                let cycleLength = path.count + 1
                if cycleLength < 4 { continue } // need at least 3 distinct nodes

                // Curvature check on the closing turn.
                if context.curvature != .ignore,
                   path.count >= 2,
                   let firstCoord = path.get(at: -2)?.coordinate,
                   let secondCoord = path.get(at: -1)?.coordinate,
                   firstCoord.distance(from: neighbor.coordinate) > context.minTurnChord
                {
                    let angle = Coordinate3D.angleBetween(
                        first: firstCoord,
                        middle: secondCoord,
                        last: neighbor.coordinate)
                    if !context.allowsTurn(angle) { continue }
                }

                let canonical = canonicalCycle(path + [neighbor], isDirected: context.isDirected)
                if seenCanonical.insert(canonical).inserted {
                    cycles.append(path + [neighbor])
                }
                continue
            }

            // Skip already-visited intermediate nodes.
            if pathIndices.contains(neighborIndex) { continue }

            // Curvature check on the turn at `current`.
            if context.curvature != .ignore,
               path.count >= 2
            {
                let firstCoord = path[path.count - 2].coordinate
                let secondCoord = path[path.count - 1].coordinate
                if firstCoord.distance(from: neighbor.coordinate) > context.minTurnChord {
                    let angle = Coordinate3D.angleBetween(
                        first: firstCoord,
                        middle: secondCoord,
                        last: neighbor.coordinate)
                    if !context.allowsTurn(angle) { continue }
                }
            }

            let addedDistance = current.coordinate.distance(from: neighbor.coordinate)

            // Bounding limits (checked before recursing).
            if let maxLength = context.maximumPathLength,
               pathLength + addedDistance > maxLength
            {
                continue
            }
            if let maxNodes = context.maximumPathNodeCount,
               path.count + 1 > maxNodes
            {
                continue
            }

            path.append(neighbor)
            pathIndices.insert(neighborIndex)
            pathLength += addedDistance

            detectCycles(
                origin: origin,
                current: neighbor,
                previous: current,
                path: &path,
                pathIndices: &pathIndices,
                pathLength: &pathLength,
                context: &context,
                cycles: &cycles,
                seenCanonical: &seenCanonical)

            path.removeLast()
            pathIndices.remove(neighborIndex)
            pathLength -= addedDistance
        }
    }

    /// Builds a canonical key for a cycle that is invariant under rotation and
    /// (for undirected cycles) reversal.
    ///
    /// The closing node (which equals the origin) is dropped before
    /// canonicalization.
    func canonicalCycle(
        _ cycle: [Node],
        isDirected: Bool
    ) -> [Int] {
        // Drop the duplicate closing node.
        var indices = cycle.dropLast().map(\.index)
        guard let minIndex = indices.min(),
              let minPosition = indices.firstIndex(of: minIndex)
        else { return indices }

        // Rotate so the smallest index is first.
        indices = Array(indices[minPosition...]) + Array(indices[..<minPosition])

        if isDirected {
            // Direction matters; rotation only.
            return indices
        }

        // For undirected cycles, also consider the reversed orientation and
        // pick the lexicographically smaller one.
        var reversed = Array(indices.reversed())
        // Re-rotate the reversed array to start at the min index.
        if let rp = reversed.firstIndex(of: minIndex) {
            reversed = Array(reversed[rp...]) + Array(reversed[..<rp])
        }
        return lexicographicallySmaller(indices, reversed)
    }

    struct CycleSearchContext: Sendable {

        let curvature: Curvature
        let turnTolerance: CLLocationDegrees
        let minTurnChord: CLLocationDistance
        let maximumPathLength: CLLocationDistance?
        let maximumPathNodeCount: Int?
        let maximumFromSourceDistance: CLLocationDistance?
        let isDirected: Bool

        func allowsTurn(_ angle: CLLocationDegrees) -> Bool {
            switch curvature {
            case .left:
                return angle > turnTolerance
            case .right:
                return angle < -turnTolerance
            case .ignore:
                return true
            }
        }

    }

    // MARK: - Cycle canonicalization helper

    private func lexicographicallySmaller(_ a: [Int], _ b: [Int]) -> [Int] {
        let n = min(a.count, b.count)
        for i in 0 ..< n {
            if a[i] != b[i] {
                return a[i] < b[i] ? a : b
            }
        }
        return a.count <= b.count ? a : b
    }

}
