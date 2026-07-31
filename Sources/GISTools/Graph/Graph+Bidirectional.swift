#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Shortest path (bidirectional Dijkstra)

extension Graph {

    /// Finds the shortest path between two nodes using bidirectional
    /// Dijkstra's algorithm.
    ///
    /// Two Dijkstra searches run concurrently — one forward from `source`,
    /// one backward from `destination` (traversing edges in reverse) — and
    /// terminate as soon as the two frontiers meet in the middle. This
    /// roughly halves the explored area compared with
    /// ``shortestPath(from:to:blockedNodes:edgeFilter:)``, giving a typical
    /// ~2× speedup for point-to-point routing while still returning the
    /// optimal path.
    ///
    /// The termination condition `topForward + topBackward >= bestMeeting`
    /// (where `topForward`/`topBackward` are the minimum unsettled `g`-values
    /// at the two heap tops and `bestMeeting` is the cheapest path through a
    /// node settled by both searches) is the classic provably-optimal rule
    /// for bidirectional Dijkstra.
    ///
    /// For directed graphs the backward search follows one-way edges in
    /// reverse (i.e. it finds nodes that can *reach* the current node), so
    /// one-way restrictions are respected on the final path.
    ///
    /// - Parameters:
    ///   - source: The start node.
    ///   - destination: The target node.
    ///   - blockedNodes: An optional set of nodes to avoid.
    ///   - edgeFilter: An optional predicate that must accept an edge for it
    ///     to be traversable. Use this to restrict routing to certain feature
    ///     types (e.g. footways for hiking, cycleways for cycling).
    /// - Returns: The shortest path as an ordered array of nodes (including
    ///   `source` and `destination`), or an empty array if no path exists.
    public func bidirectionalShortestPath(
        from source: Node,
        to destination: Node,
        blockedNodes: Set<Node>? = nil,
        edgeFilter: ((Edge) -> Bool)? = nil
    ) -> [Node] {
        guard source.index >= 0,
              source.index < adjacencyList.count,
              destination.index >= 0,
              destination.index < adjacencyList.count
        else { return [] }

        if source == destination { return [source] }

        let blockedSet: Set<Int> = Set(blockedNodes?.map(\.index) ?? [])

        // Reverse adjacency: for each stored edge `from -> to`, record that
        // `to` can be reached backwards from `from`. The backward search uses
        // this to walk edges in reverse while still respecting one-way
        // direction (a one-way edge A->B lets the backward search step from B
        // back to A, because A can reach B).
        var reverseAdjacency: [[ReverseLink]] = Array(
            repeating: [],
            count: adjacencyList.count)
        for edgeList in adjacencyList {
            for edge in edgeList.edges {
                reverseAdjacency[edge.to.index].append(
                    ReverseLink(
                        from: edge.from.index,
                        weight: edge.weight,
                        edge: edge))
            }
        }

        var gForward: [Double] = Array(repeating: .infinity, count: adjacencyList.count)
        var gBackward: [Double] = Array(repeating: .infinity, count: adjacencyList.count)
        var predForward: [Int] = Array(repeating: -1, count: adjacencyList.count)
        var predBackward: [Int] = Array(repeating: -1, count: adjacencyList.count)
        var settledForward: Set<Int> = []
        var settledBackward: Set<Int> = []

        gForward[source.index] = 0.0
        gBackward[destination.index] = 0.0

        var heapForward = MinHeap<BidirectionalHeapEntry>()
        var heapBackward = MinHeap<BidirectionalHeapEntry>()
        heapForward.push(BidirectionalHeapEntry(gScore: 0.0, index: source.index))
        heapBackward.push(BidirectionalHeapEntry(gScore: 0.0, index: destination.index))

        // Best meeting cost found so far and the node at which it occurs.
        // Updated whenever a relaxation discovers a node that has already
        // been reached from the opposite side; checking only at *settle* time
        // misses the optimal meeting node when it is merely *relaxed* by one
        // side before the other settles it.
        var bestMeeting: Double = .infinity
        var bestMeetingIndex: Int = -1

        // Records a candidate meeting at `node`: if both sides have reached it,
        // the combined cost `gForward[node] + gBackward[node]` may improve on
        // the current best.
        func noteMeeting(_ node: Int) {
            let combined = gForward[node] + gBackward[node]
            if combined < bestMeeting {
                bestMeeting = combined
                bestMeetingIndex = node
            }
        }

        // Alternate forward / backward expansion until one side is exhausted
        // or the provable termination condition is met.
        while !heapForward.isEmpty || !heapBackward.isEmpty {
            let topForward = heapForward.peek?.gScore ?? .infinity
            let topBackward = heapBackward.peek?.gScore ?? .infinity

            if topForward + topBackward >= bestMeeting {
                break
            }

            // Expand the side with the cheaper frontier key (balances the
            // two searches so they meet near the middle).
            let expandForward: Bool
            if heapForward.isEmpty {
                expandForward = false
            }
            else if heapBackward.isEmpty {
                expandForward = true
            }
            else {
                expandForward = topForward <= topBackward
            }

            if expandForward,
               let entry = heapForward.pop()
            {
                let u = entry.index
                if settledForward.contains(u) { continue }
                settledForward.insert(u)

                // A node settled by both sides is a meeting candidate.
                if settledBackward.contains(u) { noteMeeting(u) }

                let currentG = gForward[u]
                for edge in adjacencyList[u].edges {
                    let v = edge.to.index
                    if blockedSet.contains(v) { continue }
                    if let edgeFilter, !edgeFilter(edge) { continue }

                    let relaxed = currentG + edge.weight
                    if relaxed < gForward[v] {
                        gForward[v] = relaxed
                        predForward[v] = u
                        heapForward.push(BidirectionalHeapEntry(gScore: relaxed, index: v))

                        // If the backward search has already reached `v`, the
                        // path source -> ... -> u -> v -> ... -> destination
                        // is a candidate for the best meeting.
                        if gBackward[v] < .infinity { noteMeeting(v) }
                    }
                }
            }
            else if !expandForward,
                    let entry = heapBackward.pop()
            {
                let v = entry.index
                if settledBackward.contains(v) { continue }
                settledBackward.insert(v)

                // A node settled by both sides is a meeting candidate.
                if settledForward.contains(v) { noteMeeting(v) }

                let currentG = gBackward[v]
                for link in reverseAdjacency[v] {
                    let u = link.from
                    if blockedSet.contains(u) { continue }
                    if let edgeFilter, !edgeFilter(link.edge) { continue }

                    let relaxed = currentG + link.weight
                    if relaxed < gBackward[u] {
                        gBackward[u] = relaxed
                        // `u`'s successor toward the destination is `v`.
                        predBackward[u] = v
                        heapBackward.push(BidirectionalHeapEntry(gScore: relaxed, index: u))

                        // If the forward search has already reached `u`, the
                        // path source -> ... -> u -> v -> ... -> destination
                        // is a candidate for the best meeting.
                        if gForward[u] < .infinity { noteMeeting(u) }
                    }
                }
            }
            else {
                break
            }
        }

        guard bestMeetingIndex >= 0,
              bestMeeting < .infinity
        else { return [] }

        // Reconstruct the forward half: source -> ... -> meeting.
        var forwardHalf: [Int] = []
        var index = bestMeetingIndex
        forwardHalf.append(index)
        while index != source.index, predForward[index] != -1 {
            index = predForward[index]
            forwardHalf.append(index)
        }
        forwardHalf.reverse()

        // Reconstruct the backward half: meeting -> ... -> destination.
        // `predBackward[meeting]` is the node after the meeting on the way to
        // the destination.
        var backwardHalf: [Int] = []
        index = predBackward[bestMeetingIndex]
        while index != -1 {
            backwardHalf.append(index)
            index = predBackward[index]
        }

        let pathIndices = forwardHalf + backwardHalf
        return pathIndices.map { adjacencyList[$0].node }
    }

    // MARK: - Bidirectional heap support

    struct ReverseLink {
        /// The node at the other (source) end of the reversed edge.
        let from: Int
        let weight: Double
        let edge: Edge
    }

    struct BidirectionalHeapEntry: Comparable {

        /// The settled `g`-cost from one end to this node.
        let gScore: Double
        let index: Int

        static func < (
            lhs: BidirectionalHeapEntry,
            rhs: BidirectionalHeapEntry
        ) -> Bool {
            if lhs.gScore != rhs.gScore {
                return lhs.gScore < rhs.gScore
            }
            return lhs.index < rhs.index
        }

    }

}
