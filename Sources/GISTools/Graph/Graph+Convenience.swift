#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Convenience

extension Graph {

    /// Returns the total length (in meters) of a path by summing the edge
    /// weights between consecutive nodes.
    public func length(ofPath path: [Node]) -> CLLocationDistance {
        guard path.count >= 2 else { return 0.0 }

        var total: CLLocationDistance = 0.0
        for i in 1 ..< path.count {
            total += path[i].coordinate.distance(from: path[i - 1].coordinate)
        }
        return total
    }

}

extension Graph: CustomDebugStringConvertible {

    public var debugDescription: String {
        var rows: [String] = []
        for edgeList in adjacencyList {
            let edges = edgeList.edges
            guard edges.isNotEmpty else { continue }

            var row: [String] = []
            for edge in edges {
                let value = "\(edge.to.coordinate.asJsonString() ?? ""): \(edge.weight))"
                row.append(value)
            }

            rows.append("\(edgeList.node.coordinate.asJsonString() ?? "") -> [\(row.joined(separator: ", "))]")
        }
        return rows.joined(separator: "\n")
    }

}
