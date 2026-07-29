#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// An undirected or directed graph built from `LineString` features.
///
/// Nodes are created at each line segment endpoint. Multiple distinct nodes at
/// the same coordinate (within ``nodeTolerance`` meters) are merged via a
/// spatial hash, giving near O(1) deduplication during construction.
///
/// The graph supports:
/// - Shortest-path search via Dijkstra's algorithm (binary-heap, O((V+E) log V)),
///   optionally restricted by an `edgeFilter` (e.g. for hiking/cycling routing)
///   and/or `blockedNodes`.
/// - Cycle detection with curvature constraints and bounding limits, using
///   canonical deduplication that correctly handles rotation and reversal.
/// - Inserting nodes on edges at arbitrary positions (perpendicular foot).
/// - Breadth-first / depth-first traversal and connected-component partitioning.
///
/// When `isDirected` is `true`, features carrying a truthy `onewayProperty`
/// (default `"oneway"`) become one-way edges in the LineString's order; all
/// other edges remain bidirectional.
///
/// - Important: `Graph` is a value type with copy-on-write semantics.
public struct Graph: Sendable {

    // MARK: - Adjacency storage

    struct EdgeList: Sendable {
        var node: Node
        var edges: [Edge] = []

        init(node: Node) {
            self.node = node
        }
    }

    var adjacencyList: [EdgeList] = []

    // MARK: - Spatial index for node deduplication / lookup

    /// A simple uniform-grid spatial hash over node coordinates.
    ///
    /// Cell size is derived from ``nodeTolerance`` so that any two nodes within
    /// `nodeTolerance` meters are guaranteed to share or be adjacent cells.
    /// Lookup of an existing node is O(1) average.
    struct SpatialIndex: Sendable {

        struct Key: Hashable, Sendable {
            let lat: Int
            let lon: Int
        }

        var cells: [Key: [Int]] = [:]
        let cellLatDegrees: Double
        let cellLonDegrees: Double
        let referenceLatitude: Double

        /// `tolerance` is in meters. Cell size is chosen so a `tolerance`-radius
        /// search is covered by the 3x3 neighborhood of cells.
        init(tolerance: Double, referenceLatitude: Double) {
            self.referenceLatitude = referenceLatitude.clamped(to: -89.0 ... 89.0)
            // meters -> degrees. 1 degree latitude ~= 111_320 m.
            cellLatDegrees = max(tolerance / 111_320.0, 0.0000001)
            // longitude degrees shrink with cos(latitude).
            let cosLat = cos(self.referenceLatitude * .pi / 180.0)
            cellLonDegrees = max(tolerance / (111_320.0 * max(cosLat, 0.0000001)), 0.0000001)
        }

        func key(for coordinate: Coordinate3D) -> Key {
            Key(
                lat: Int((coordinate.latitude / cellLatDegrees).rounded()),
                lon: Int((coordinate.longitude / cellLonDegrees).rounded()))
        }

        mutating func insert(nodeIndex: Int, coordinate: Coordinate3D) {
            let k = key(for: coordinate)
            cells[k, default: []].append(nodeIndex)
        }

        /// Returns candidate node indices whose stored coordinate is within
        /// `tolerance` meters of `coordinate`. The caller must verify the
        /// actual distance.
        func candidates(near coordinate: Coordinate3D) -> [Int] {
            let k = key(for: coordinate)
            var result: [Int] = []
            for dLat in -1 ... 1 {
                for dLon in -1 ... 1 {
                    let nk = Key(lat: k.lat + dLat, lon: k.lon + dLon)
                    if let bucket = cells[nk] {
                        result.append(contentsOf: bucket)
                    }
                }
            }
            return result
        }
    }

    var spatialIndex: SpatialIndex

    // MARK: - Configuration

    /// The distance threshold (in meters) for treating two nodes as the same
    /// location. Used by ``createNode(at:)`` and ``nodeOnEdge(near:)``.
    /// The default is 1.0 meter.
    public var nodeTolerance: CLLocationDistance

    /// Whether the graph treats `oneway`-tagged edges as directed.
    public let isDirected: Bool

    /// The feature property used to detect one-way edges when ``isDirected``
    /// is `true`. Default `"oneway"`.
    public let onewayProperty: String

    // MARK: - Initialization

    /// Creates a graph from the line segments in a feature collection.
    ///
    /// Only `LineString` and `MultiLineString` geometries are processed; nodes
    /// within ``nodeTolerance`` meters of each other are merged.
    ///
    /// - Parameters:
    ///   - featureCollection: The features to build the graph from.
    ///   - nodeTolerance: Distance threshold for node merging (default: 1.0
    ///     meter).
    ///   - isDirected: When `true`, features with a truthy `onewayProperty`
    ///     become one-way edges (default `false`).
    ///   - onewayProperty: The feature property key indicating one-way edges
    ///     (default `"oneway"`). Only consulted when `isDirected` is `true`.
    public init(
        featureCollection: FeatureCollection,
        nodeTolerance: CLLocationDistance = 1.0,
        isDirected: Bool = false,
        onewayProperty: String = "oneway"
    ) {
        self.nodeTolerance = nodeTolerance
        self.isDirected = isDirected
        self.onewayProperty = onewayProperty

        let referenceLatitude = featureCollection.features
            .compactMap({ ($0.geometry as? LineString)?.coordinates.first?.latitude })
            .first ?? 0.0
        self.spatialIndex = SpatialIndex(
            tolerance: nodeTolerance,
            referenceLatitude: referenceLatitude)

        for feature in featureCollection.features {
            switch feature.geometry {
            case let lineString as LineString:
                addLineString(lineString, feature: feature)
            case let multiLineString as MultiLineString:
                for ls in multiLineString.lineStrings {
                    addLineString(ls, feature: feature)
                }
            default:
                continue
            }
        }
    }

    /// Creates an empty graph.
    /// - Parameters:
    ///   - nodeTolerance: Distance threshold for node merging (default: 1.0
    ///     meter).
    ///   - isDirected: Whether the graph treats `oneway`-tagged edges as
    ///     directed (default `false`).
    ///   - onewayProperty: The feature property key indicating one-way edges
    ///     (default `"oneway"`).
    public init(
        nodeTolerance: CLLocationDistance = 1.0,
        isDirected: Bool = false,
        onewayProperty: String = "oneway"
    ) {
        self.nodeTolerance = nodeTolerance
        self.isDirected = isDirected
        self.onewayProperty = onewayProperty
        self.spatialIndex = SpatialIndex(tolerance: nodeTolerance, referenceLatitude: 0.0)
    }

    // MARK: - Private construction helpers

    mutating func addLineString(_ lineString: LineString, feature: Feature) {
        let oneway = isDirected && isOneway(feature)

        for segment in lineString.lineSegments {
            let sourceNode = createNode(at: segment.first)
            let destinationNode = createNode(at: segment.second)

            if sourceNode == destinationNode {
                continue
            }

            if oneway {
                addDirectedEdge(
                    from: sourceNode,
                    to: destinationNode,
                    feature: feature,
                    isDirected: true)
            }
            else {
                addUndirectedEdge(
                    from: sourceNode,
                    to: destinationNode,
                    feature: feature)
            }
        }
    }

    private func isOneway(_ feature: Feature) -> Bool {
        guard let value: Sendable = feature.property(for: onewayProperty) else { return false }
        if let s = value as? String {
            return s == "yes" || s == "1" || s == "true"
        }
        if let n = value as? Int {
            return n == 1
        }
        if let n = value as? Double {
            return n == 1.0
        }
        if let b = value as? Bool {
            return b
        }
        return false
    }

}

// MARK: - Comparable helpers

extension Comparable {

    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }

}
