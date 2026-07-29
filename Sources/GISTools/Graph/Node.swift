#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// A node in a ``Graph``, identified by an index and a geographic coordinate.
///
/// Nodes are deduplicated during graph construction: coordinates within the
/// graph's ``Graph/nodeTolerance`` (default 1 meter) are merged into a single
/// node, so two `Node`s are equal iff their ``index`` is equal.
public struct Node: Hashable, Sendable {

    /// The node's unique index within its graph.
    public let index: Int

    /// The geographic coordinate of this node.
    public var coordinate: Coordinate3D

    /// Creates a node.
    /// - Parameters:
    ///   - index: The node index.
    ///   - coordinate: The geographic coordinate.
    public init(
        index: Int,
        coordinate: Coordinate3D
    ) {
        self.index = index
        self.coordinate = coordinate
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }

    public static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.index == rhs.index
    }

}

extension Node: CustomDebugStringConvertible {

    public var debugDescription: String {
        "\(index): \(coordinate.asJsonString() ?? "")"
    }

}