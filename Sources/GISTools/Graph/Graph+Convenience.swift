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

    /// Returns the graph as a `FeatureCollection`.
    ///
    /// Each unique edge becomes a ``LineString`` feature. If the edge
    /// carries an original feature reference, its `id` and `properties` are
    /// preserved. Directed edges receive a `"oneway"` property set to
    /// `"yes"`. A `"weight"` property records the edge weight in meters.
    ///
    /// This is useful for debugging the state of a graph after
    /// transformations, or for exporting results of graph operations back
    /// to standard GeoJSON tooling.
    public func toFeatureCollection() -> FeatureCollection {
        var features: [Feature] = []
        features.reserveCapacity(edges.count)

        for edge in edges {
            let lineString = LineString(unchecked: [
                edge.from.coordinate,
                edge.to.coordinate
            ])
            var props: [String: Sendable] = [:]
            if let original = edge.feature {
                props = original.properties
            }
            if edge.isDirected {
                props["oneway"] = "yes"
            }
            props["weight"] = edge.weight

            let feature = Feature(
                lineString,
                id: edge.feature?.id,
                properties: props)
            features.append(feature)
        }

        return FeatureCollection(features)
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
