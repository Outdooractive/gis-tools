import Foundation

/// A prepared polygonal geometry for repeated point and containment queries.
///
/// Preparing a polygon builds a latitude-bucket index for each ring and an
/// R-tree over its boundary segments. The index is immutable and can be reused
/// for repeated ``locate(_:)``, ``contains(_:)`` and ``covers(_:)`` calls.
///
/// One-shot predicates such as ``Polygon/locate(_:gridSize:)`` keep their
/// existing implementation. Use ``Polygon/prepared(gridSize:)`` when the same
/// geometry is queried repeatedly.
public struct PreparedPolygon: Sendable {

    /// The projection used by the prepared geometry.
    ///
    /// Geocentric inputs are prepared in EPSG:4326, matching the one-shot
    /// point-location path.
    public let projection: Projection

    /// The prepared geometry's bounding box.
    public let boundingBox: BoundingBox?

    /// Whether any prepared polygon crosses the antimeridian.
    public let crossesAntimeridian: Bool

    private let parts: [Part]
    private let sourcePolygons: [Polygon]
    private let sourceProjection: Projection
    private let gridSize: Double?

    /// Prepare a polygonal geometry for repeated queries.
    ///
    /// - Parameters:
    ///   - geometry: A `Polygon` or `MultiPolygon`
    ///   - gridSize: Snap the geometry to a grid of the given size before
    ///     preparing (default `nil`). Query coordinates are snapped to the
    ///     same grid.
    public init(
        _ geometry: PolygonGeometry,
        gridSize: Double? = nil
    ) {
        let sourcePolygons = geometry.polygons
        self.sourcePolygons = sourcePolygons
        self.sourceProjection = geometry.projection
        self.gridSize = gridSize

        let snappedPolygons = gridSize.map { size in
            sourcePolygons.map { $0.snappedToGrid(tolerance: size) }
        } ?? sourcePolygons

        let preparedProjection = geometry.projection.isGeocentric
            ? Projection.epsg4326
            : geometry.projection
        let preparedPolygons = preparedProjection == geometry.projection
            ? snappedPolygons
            : snappedPolygons.map { $0.projected(to: preparedProjection) }

        self.projection = preparedProjection
        self.parts = preparedPolygons.map { Part(polygon: $0) }
        self.boundingBox = BoundingBox(coordinates: preparedPolygons.flatMap(\.allCoordinates))
        self.crossesAntimeridian = preparedPolygons.contains { $0.crossesAntimeridian }
    }

    /// Determines where a coordinate lies relative to the prepared geometry.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Returns: `.interior`, `.boundary` or `.exterior`
    public func locate(_ coordinate: Coordinate3D) -> PointLocation {
        let snappedCoordinate = gridSize.map {
            coordinate.snappedToGrid(tolerance: $0)
        } ?? coordinate
        let preparedCoordinate = snappedCoordinate.projected(to: projection)

        var isOnBoundary = false

        for part in parts {
            switch part.locate(preparedCoordinate) {
            case .interior:
                return .interior

            case .boundary:
                isOnBoundary = true

            case .exterior:
                continue
            }
        }

        return isOnBoundary ? .boundary : .exterior
    }

    /// Determines if a coordinate lies in the interior of the prepared geometry.
    ///
    /// This uses the same OGC/PostGIS `ST_Contains` point semantics as
    /// ``Polygon/contains(_:gridSize:)``.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Returns: `true` if the coordinate is in the interior
    public func contains(_ coordinate: Coordinate3D) -> Bool {
        locate(coordinate) == .interior
    }

    /// Determines if a coordinate is covered by the prepared geometry.
    ///
    /// This uses the same OGC/PostGIS `ST_Covers` point semantics as
    /// ``Polygon/covers(_:gridSize:)``.
    ///
    /// - Parameter coordinate: The coordinate to check
    /// - Returns: `true` if the coordinate is in the interior or on the boundary
    public func covers(_ coordinate: Coordinate3D) -> Bool {
        locate(coordinate) != .exterior
    }

    /// Determines where a point lies relative to the prepared geometry.
    ///
    /// - Parameter point: The point to check
    /// - Returns: `.interior`, `.boundary` or `.exterior`
    public func locate(_ point: Point) -> PointLocation {
        locate(point.coordinate)
    }

    /// Determines if a point lies in the interior of the prepared geometry.
    ///
    /// - Parameter point: The point to check
    /// - Returns: `true` if the point is in the interior
    public func contains(_ point: Point) -> Bool {
        contains(point.coordinate)
    }

    /// Determines if a point is covered by the prepared geometry.
    ///
    /// - Parameter point: The point to check
    /// - Returns: `true` if the point is in the interior or on the boundary
    public func covers(_ point: Point) -> Bool {
        covers(point.coordinate)
    }

    /// Determines if the prepared geometry contains another polygonal geometry.
    ///
    /// This follows OGC `ST_Contains`: the other geometry must be covered and
    /// have a positive-area part.
    ///
    /// - Parameter other: The other polygonal geometry
    /// - Returns: `true` if the prepared geometry contains the other geometry
    public func contains(_ other: PolygonGeometry) -> Bool {
        if sourceProjection.isGeocentric
            || crossesAntimeridian
            || other.crossesAntimeridian
        {
            return originalGeometry.contains(other)
        }

        guard covers(other) else { return false }
        return other.polygons.contains { $0.area > 0.0 }
    }

    /// Determines if the prepared geometry covers another polygonal geometry.
    ///
    /// - Parameter other: The other polygonal geometry
    /// - Returns: `true` if every point of the other geometry is covered
    public func covers(_ other: PolygonGeometry) -> Bool {
        if sourceProjection.isGeocentric
            || crossesAntimeridian
            || other.crossesAntimeridian
        {
            return originalGeometry.covers(other)
        }

        return BooleanCovers.covers(self, other)
    }

    internal var coverageContainers: [CoverageContainer] {
        parts.map {
            CoverageContainer(
                geometry: $0.polygon,
                pointIndex: $0.pointIndex,
                barriers: $0.barriers)
        }
    }

    private var originalGeometry: GeoJsonGeometry {
        if sourcePolygons.count == 1 {
            return sourcePolygons[0]
        }
        return MultiPolygon(unchecked: sourcePolygons)
    }

}

// MARK: - Prepared parts

extension PreparedPolygon {

    fileprivate struct Part: Sendable {

        let polygon: Polygon
        let pointIndex: PointIndex
        let barriers: SegmentIndex

        init(polygon: Polygon) {
            self.polygon = polygon
            self.pointIndex = PointIndex(polygon: polygon)
            self.barriers = SegmentIndex(polygon.lineSegments)
        }

        func locate(_ coordinate: Coordinate3D) -> PointLocation {
            pointIndex.locate(coordinate)
        }

    }

    /// Prepared point-in-polygon index for a single polygon.
    struct PointIndex: Sendable {

        private let boundingBox: BoundingBox?
        private let crossesAntimeridian: Bool
        private let outerRing: RingIndex?
        private let innerRings: [RingIndex]

        init(polygon: Polygon) {
            self.boundingBox = polygon.boundingBox ?? polygon.calculateBoundingBox()
            self.crossesAntimeridian = polygon.crossesAntimeridian
            self.outerRing = polygon.outerRing.map { RingIndex($0) }
            self.innerRings = polygon.innerRings?.map { RingIndex($0) } ?? []
        }

        func locate(_ coordinate: Coordinate3D) -> PointLocation {
            if let boundingBox,
               !boundingBox.contains(coordinate),
               !crossesAntimeridian
            {
                return .exterior
            }

            guard let outerRing else { return .exterior }

            switch outerRing.locate(coordinate) {
            case .exterior:
                return .exterior

            case .boundary:
                return .boundary

            case .interior:
                break
            }

            for ring in innerRings {
                switch ring.locate(coordinate) {
                case .boundary:
                    return .boundary

                case .interior:
                    return .exterior

                case .exterior:
                    continue
                }
            }

            return .interior
        }

    }

    fileprivate struct RingIndex: Sendable {

        private let coordinates: [Coordinate3D]
        private let count: Int
        private let crossesAntimeridian: Bool
        private let wraparoundWidth: Double
        private let minY: Double
        private let maxY: Double
        private let rowScale: Double
        private let rowCount: Int
        private let rows: [[Int]]

        init(_ ring: Ring) {
            let sourceCoordinates = ring.coordinates
            let isClosed = sourceCoordinates.count > 1
                && sourceCoordinates.first == sourceCoordinates.last
            let count = isClosed ? sourceCoordinates.count - 1 : sourceCoordinates.count
            let wraparoundExtent = ring.projection.wraparoundExtent

            var crossesAntimeridian = false
            if let wraparoundExtent, count > 0 {
                for i in 0 ..< count {
                    let j = (i + count - 1) % count
                    let delta = sourceCoordinates[i].longitude - sourceCoordinates[j].longitude
                    if abs(delta) > wraparoundExtent,
                       abs(delta) < (2.0 * wraparoundExtent)
                    {
                        crossesAntimeridian = true
                        break
                    }
                }
            }

            let wraparoundWidth = 2.0 * (wraparoundExtent ?? 0.0)
            let coordinates = crossesAntimeridian
                ? sourceCoordinates.map { coordinate in
                    guard coordinate.longitude < 0.0 else { return coordinate }
                    return Self.coordinate(coordinate, x: coordinate.longitude + wraparoundWidth)
                }
                : sourceCoordinates

            self.coordinates = coordinates
            self.count = count
            self.crossesAntimeridian = crossesAntimeridian
            self.wraparoundWidth = wraparoundWidth

            guard count >= 3,
                  let first = coordinates.first
            else {
                self.minY = 0.0
                self.maxY = 0.0
                self.rowScale = 0.0
                self.rowCount = 0
                self.rows = []
                return
            }

            var minY = first.latitude
            var maxY = first.latitude
            for coordinate in coordinates.dropFirst() {
                minY = min(minY, coordinate.latitude)
                maxY = max(maxY, coordinate.latitude)
            }

            guard maxY > minY else {
                self.minY = 0.0
                self.maxY = 0.0
                self.rowScale = 0.0
                self.rowCount = 0
                self.rows = []
                return
            }

            let rowCount = max(8, min(256, count / 4))
            let rowScale = Double(rowCount) / (maxY - minY)
            var rows = Array(repeating: [Int](), count: rowCount)

            for i in 0 ..< count {
                let j = (i + count - 1) % count
                let low = min(coordinates[j].latitude, coordinates[i].latitude)
                let high = max(coordinates[j].latitude, coordinates[i].latitude)
                let startRow = min(max(Int((low - minY) * rowScale), 0), rowCount - 1)
                let endRow = min(max(Int((high - minY) * rowScale), 0), rowCount - 1)

                for row in startRow ... endRow {
                    rows[row].append(i)
                }
            }

            self.minY = minY
            self.maxY = maxY
            self.rowScale = rowScale
            self.rowCount = rowCount
            self.rows = rows
        }

        func locate(_ coordinate: Coordinate3D) -> PointLocation {
            guard count >= 3,
                  coordinate.latitude >= minY,
                  coordinate.latitude <= maxY
            else { return .exterior }

            let row = min(max(Int((coordinate.latitude - minY) * rowScale), 0), rowCount - 1)
            var testLongitude = coordinate.longitude
            if crossesAntimeridian, testLongitude < 0.0 {
                testLongitude += wraparoundWidth
            }

            let pointY = coordinate.latitude
            var isInside = false

            for i in rows[row] {
                let j = (i + count - 1) % count
                let x1 = coordinates[j].longitude
                let y1 = coordinates[j].latitude
                let x2 = coordinates[i].longitude
                let y2 = coordinates[i].latitude

                if x1 < testLongitude, x2 < testLongitude {
                    continue
                }

                if x2 == testLongitude, y2 == pointY {
                    return .boundary
                }

                if y1 == pointY, y2 == pointY {
                    let minX = min(x1, x2)
                    let maxX = max(x1, x2)
                    if testLongitude >= minX, testLongitude <= maxX {
                        return .boundary
                    }
                    continue
                }

                let crossesRay = (y1 > pointY && y2 <= pointY)
                    || (y2 > pointY && y1 <= pointY)
                guard crossesRay else { continue }

                var orientation = PointInRing.orientationIndex(
                    x1, y1,
                    x2, y2,
                    testLongitude, pointY)
                if orientation == 0 {
                    return .boundary
                }
                if y2 < y1 {
                    orientation = -orientation
                }
                if orientation > 0 {
                    isInside.toggle()
                }
            }

            return isInside ? .interior : .exterior
        }

        private static func coordinate(
            _ coordinate: Coordinate3D,
            x: Double
        ) -> Coordinate3D {
            Coordinate3D(
                x: x,
                y: coordinate.latitude,
                z: coordinate.altitude,
                m: coordinate.m,
                projection: coordinate.projection)
        }

    }

}

// MARK: - Segment index

/// A spatial index over line segments used by coverage checks.
struct SegmentIndex: Sendable {

    private static let treeThreshold = 32

    private let segments: [LineSegment]
    private let tree: RTree<LineSegment>?

    init(_ segments: [LineSegment]) {
        self.segments = segments
        self.tree = segments.count > Self.treeThreshold ? RTree(segments) : nil
    }

    func candidates(for segment: LineSegment) -> [LineSegment] {
        guard let tree,
              let boundingBox = segment.boundingBox ?? segment.calculateBoundingBox()
        else { return segments }

        return tree.search(inBoundingBox: boundingBox)
    }

}

// MARK: - Convenience

extension Polygon {

    /// Prepare the polygon for repeated point and containment queries.
    ///
    /// - Parameter gridSize: Snap the geometry to a grid before preparing
    ///   (default `nil`)
    /// - Returns: A reusable prepared polygon
    public func prepared(gridSize: Double? = nil) -> PreparedPolygon {
        PreparedPolygon(self, gridSize: gridSize)
    }

}

extension MultiPolygon {

    /// Prepare the multi-polygon for repeated point and containment queries.
    ///
    /// - Parameter gridSize: Snap the geometry to a grid before preparing
    ///   (default `nil`)
    /// - Returns: A reusable prepared multi-polygon
    public func prepared(gridSize: Double? = nil) -> PreparedPolygon {
        PreparedPolygon(self, gridSize: gridSize)
    }

}
