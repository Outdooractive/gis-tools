import Foundation

// MARK: - ALT landmark index

extension Graph {

    /// A reusable ALT (A*, landmarks, triangle inequality) index.
    ///
    /// The index precomputes shortest-path distances from a small set of
    /// landmark nodes. The maximum triangle-inequality difference is then used
    /// as an admissible A* heuristic.
    ///
    /// Undirected graphs need one distance table per landmark. Directed graphs
    /// also use distances measured against the reversed graph, so both
    /// forward and backward triangle inequalities are available.
    public struct LandmarkIndex: Sendable {

        private let graph: Graph
        private let forwardDistances: [[Double]]
        private let backwardDistances: [[Double]]?

        /// Builds an ALT index.
        ///
        /// - Parameters:
        ///   - graph: An undirected or directed graph.
        ///   - landmarkCount: Number of landmarks to precompute (default 4).
        /// - Returns: `nil` for empty graphs.
        public init?(_ graph: Graph, landmarkCount: Int = 4) {
            guard graph.nodeCount > 1 else { return nil }

            let component = graph.connectedComponents.max(by: { $0.count < $1.count })
                ?? graph.nodes
            guard component.isNotEmpty else { return nil }

            let count = min(max(landmarkCount, 1), component.count)
            var landmarks: [Node] = [component[0]]

            while landmarks.count < count {
                var bestNode = component[1]
                var bestDistance = -Double.infinity

                for node in component where !landmarks.contains(node) {
                    let nearest = landmarks.lazy
                        .map {
                            node.coordinate.distance(from: $0.coordinate)
                        }
                        .min() ?? 0.0

                    if nearest > bestDistance {
                        bestDistance = nearest
                        bestNode = node
                    }
                }

                landmarks.append(bestNode)
            }

            let reverseAdjacency = graph.hasDirectedEdges
                ? Self.reversedAdjacency(of: graph)
                : nil

            self.graph = graph
            self.forwardDistances = landmarks.map {
                Self.distances(
                    from: $0,
                    in: graph,
                    adjacency: nil)
            }
            self.backwardDistances = reverseAdjacency.map { reverse in
                landmarks.map {
                    Self.distances(
                        from: $0,
                        in: graph,
                        adjacency: reverse)
                }
            }
        }

        /// The number of precomputed landmarks.
        public var landmarkCount: Int {
            forwardDistances.count
        }

        /// Finds a shortest path using ALT A*.
        public func aStarPath(
            from source: Node,
            to destination: Node,
            blockedNodes: Set<Node>? = nil,
            edgeFilter: ((Edge) -> Bool)? = nil
        ) -> [Node] {
            guard source.index >= 0,
                  source.index < graph.nodeCount,
                  destination.index >= 0,
                  destination.index < graph.nodeCount
            else { return [] }

            if source == destination {
                return [source]
            }

            let blockedSet: Set<Int>? = blockedNodes.map { Set($0.map(\.index)) }
            let forwardDestination = forwardDistances.map {
                $0[destination.index]
            }
            let backwardDestination = backwardDistances?.map {
                $0[destination.index]
            }

            func heuristic(_ index: Int) -> Double {
                var value = 0.0

                for landmark in forwardDistances.indices {
                    let forwardNode = forwardDistances[landmark][index]
                    let forwardTarget = forwardDestination[landmark]

                    if forwardNode.isFinite, forwardTarget.isFinite {
                        if let backwardDistances, let backwardDestination {
                            let backwardNode = backwardDistances[landmark][index]
                            let backwardTarget = backwardDestination[landmark]

                            value = max(
                                value,
                                forwardTarget - forwardNode,
                                backwardNode - backwardTarget)
                        }
                        else {
                            value = max(value, abs(forwardNode - forwardTarget))
                        }
                    }
                }

                return max(value, 0.0)
            }

            var gScore = [Double](repeating: .infinity, count: graph.nodeCount)
            var predecessors = [Int](repeating: -1, count: graph.nodeCount)
            var visited = [Bool](repeating: false, count: graph.nodeCount)

            gScore[source.index] = 0.0

            var heap = MinHeap<AStarEntry>()
            heap.push(AStarEntry(
                fScore: heuristic(source.index),
                index: source.index))

            while let entry = heap.pop() {
                if visited[entry.index] {
                    continue
                }
                if entry.index == destination.index {
                    break
                }
                visited[entry.index] = true

                let currentG = gScore[entry.index]
                for edge in graph.adjacencyList[entry.index].edges {
                    let neighbor = edge.to.index
                    if let blockedSet, blockedSet.contains(neighbor) {
                        continue
                    }
                    if let edgeFilter, !edgeFilter(edge) {
                        continue
                    }

                    let relaxed = currentG + edge.weight
                    if relaxed < gScore[neighbor] {
                        gScore[neighbor] = relaxed
                        predecessors[neighbor] = entry.index
                        heap.push(AStarEntry(
                            fScore: relaxed + heuristic(neighbor),
                            index: neighbor))
                    }
                }
            }

            guard gScore[destination.index] < .infinity else { return [] }

            var path = [destination.index]
            var index = predecessors[destination.index]
            while index != -1, index != source.index {
                path.append(index)
                index = predecessors[index]
            }
            path.append(source.index)

            return path.reversed().map { graph.adjacencyList[$0].node }
        }

        // MARK: - Private

        private static func reversedAdjacency(
            of graph: Graph
        ) -> [[(to: Int, weight: Double)]] {
            var result = [[(to: Int, weight: Double)]](
                repeating: [],
                count: graph.nodeCount
            )

            for edgeList in graph.adjacencyList {
                for edge in edgeList.edges {
                    result[edge.to.index].append((
                        to: edge.from.index,
                        weight: edge.weight
                    ))
                }
            }

            return result
        }

        private static func distances(
            from source: Node,
            in graph: Graph,
            adjacency: [[(to: Int, weight: Double)]]?
        ) -> [Double] {
            var distances = [Double](repeating: .infinity, count: graph.nodeCount)
            var visited = [Bool](repeating: false, count: graph.nodeCount)
            var heap = MinHeap<HeapEntry>()

            distances[source.index] = 0.0
            heap.push(HeapEntry(distance: 0.0, index: source.index))

            while let entry = heap.pop() {
                if visited[entry.index] {
                    continue
                }
                visited[entry.index] = true

                if let adjacency {
                    for link in adjacency[entry.index] {
                        let neighbor = link.to
                        let relaxed = entry.distance + link.weight
                        if relaxed < distances[neighbor] {
                            distances[neighbor] = relaxed
                            heap.push(HeapEntry(
                                distance: relaxed,
                                index: neighbor))
                        }
                    }
                }
                else {
                    for edge in graph.adjacencyList[entry.index].edges {
                        let neighbor = edge.to.index
                        let relaxed = entry.distance + edge.weight
                        if relaxed < distances[neighbor] {
                            distances[neighbor] = relaxed
                            heap.push(HeapEntry(
                                distance: relaxed,
                                index: neighbor))
                        }
                    }
                }
            }

            return distances
        }

    }

    /// Builds an ALT landmark index.
    public func landmarkIndex(landmarkCount: Int = 4) -> LandmarkIndex? {
        LandmarkIndex(self, landmarkCount: landmarkCount)
    }

}
