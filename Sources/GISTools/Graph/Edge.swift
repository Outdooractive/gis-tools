#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// A directed edge between two ``Node``s in a ``Graph``.
///
/// In an undirected graph every connection is stored twice (once per
/// direction). In a directed graph, one-way edges are stored once (in the
/// permitted direction) and two-way edges are stored twice.
///
/// The edge ``weight`` defaults to the geodesic distance between the
/// endpoints and is recomputed lazily, so it stays consistent even if a
/// node coordinate is later updated.
public struct Edge: Hashable, Sendable {

    /// The source node.
    public let from: Node

    /// The destination node.
    public let to: Node

    /// An optional geo feature associated with this edge (e.g. the road segment
    /// it was built from).
    public let feature: Feature?

    /// Whether this edge is one-way (`from` -> `to` only).
    ///
    /// `false` means the edge represents one direction of a bidirectional
    /// connection; the reverse `Edge` is stored separately in the graph.
    public let isDirected: Bool

    /// The edge weight (typically the distance between the nodes in meters).
    public var weight: Double

    /// Creates a directed edge.
    /// - Parameters:
    ///   - from: The source node.
    ///   - to: The destination node.
    ///   - feature: An optional feature associated with this edge.
    ///   - isDirected: Whether this edge is one-way (default `false`).
    ///   - weight: An explicit weight; defaults to the geodesic distance
    ///     between `from` and `to`.
    public init(
        from: Node,
        to: Node,
        feature: Feature? = nil,
        isDirected: Bool = false,
        weight: Double? = nil
    ) {
        self.from = from
        self.to = to
        self.feature = feature
        self.isDirected = isDirected
        self.weight = weight ?? to.coordinate.distance(from: from.coordinate)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(from)
        hasher.combine(to)
        hasher.combine(isDirected)
    }

    public static func == (lhs: Edge, rhs: Edge) -> Bool {
        lhs.from == rhs.from
            && lhs.to == rhs.to
            && lhs.isDirected == rhs.isDirected
    }

}

extension Edge: CustomDebugStringConvertible {

    public var debugDescription: String {
        let dir = isDirected ? " ->" : " <->"
        return "\(from.debugDescription)\(dir) \(to.debugDescription) (\(weight))"
    }

}