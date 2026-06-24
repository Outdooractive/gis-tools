#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-line-overlap

extension LineSegment {

    /// Indicates how one segment compares to another segment.
    public enum LineSegmentComparisonResult: Sendable {
        /// The two segments are equal.
        case equal
        /// The two segments are not equal.
        case notEqual
        /// The receiver's segment lies on the other segment.
        case thisOnOther
        /// The other segment lies on the receiver's segment.
        case otherOnThis
    }

    /// Checks how the receiver and the other *LineSegment* lie in relation to each other.
    ///
    /// - Parameters:
    /// - Parameter other: The other *LineSegment*
    /// - Parameter tolerance: The tolerance, in meters
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: A ``LineSegmentComparisonResult`` indicating how the segments relate.
    public func compare(
        _ other: LineSegment,
        tolerance: CLLocationDistance = 0.0,
        gridSize: Double? = nil
    ) -> LineSegmentComparisonResult {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let other = snappedOther.projected(to: snappedSelf.projection)
        let tolerance = abs(tolerance)

        if (snappedSelf.first == other.first && snappedSelf.second == other.second)
            || (snappedSelf.first == other.second && snappedSelf.second == other.first)
        {
            return .equal
        }
        else if tolerance == 0.0 {
            if other.checkIsOnSegment(snappedSelf.first), other.checkIsOnSegment(snappedSelf.second) {
                return .thisOnOther
            }
            else if snappedSelf.checkIsOnSegment(other.first), snappedSelf.checkIsOnSegment(other.second) {
                return .otherOnThis
            }
        }
        else if tolerance > 0.0 {
            if other.nearestCoordinateOnSegment(from: snappedSelf.first).distance <= tolerance,
               other.nearestCoordinateOnSegment(from: snappedSelf.second).distance <= tolerance
            {
                return .thisOnOther
            }
            else if snappedSelf.nearestCoordinateOnSegment(from: other.first).distance <= tolerance,
                    snappedSelf.nearestCoordinateOnSegment(from: other.second).distance <= tolerance
            {
                return .otherOnThis
            }
        }

        return .notEqual
    }

}

extension GeoJson {

    /// Returns the overlapping segments between the receiver and the other geometry.
    ///
    /// All projections are supported — the 2‑D segment comparison
    /// operates on raw ``longitude``/``latitude`` values (ECEF X/Y
    /// for EPSG:4978).
    ///
    /// - Parameters:
    /// - Parameter other: The other geometry
    /// - Parameter tolerance: The tolerance, in meters
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    ///
    /// - Returns: An array of overlapping line segments.
    public func overlappingSegments(
        with other: GeoJson,
        tolerance: CLLocationDistance = 0.0,
        gridSize: Double? = nil
    ) -> [LineSegment] {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let other = snappedOther.projected(to: snappedSelf.projection)
        let tolerance = abs(tolerance)

        var result: [LineSegment] = []

        let tree: RTree<LineSegment> = RTree(snappedSelf.lineSegments)

        for segment in other.lineSegments {
            guard let boundingBox = segment.boundingBox ?? segment.calculateBoundingBox() else { continue }

            for match in tree.search(inBoundingBox: boundingBox) {
                let comparison = segment.compare(match, tolerance: tolerance, gridSize: nil)

                if comparison == .equal {
                    result.append(segment)
                    break
                }
                else if comparison == .thisOnOther {
                    result.append(segment)
                    break
                }
                else if comparison == .otherOnThis {
                    result.append(match)
                }
            }
        }

        return result
    }

    /// Returns the overlapping segments with the receiver itself.
    ///
    /// This implementation has been optimized for finding self-overlaps.
    ///
    /// All projections are supported — the coordinate comparison uses
    /// ``Coordinate3D/distance(to:)`` which handles all CRS.
    ///
    /// - Note: Altitude values will be ignored.
    ///
    /// - Parameter tolerance: The tolerance, in meters. Using `0.0` will only return segments that *exactly* overlap.
    /// - Parameter segmentLength: This value adds intermediate points to the geometry for improved matching, in meters. Choosing this too small might lead to memory explosion.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    ///
    /// - Returns: All segments that at least overlap with one other segment. Each segment will
    ///            appear in the result only once.
    public func overlappingSegments(
        tolerance: CLLocationDistance,
        segmentLength: Double? = nil,
        gridSize: Double? = nil
    ) -> MultiLineString? {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let tolerance = abs(tolerance)
        let distanceFunction = FrechetDistanceFunction.haversine

        guard let line = if let segmentLength, segmentLength > 0.0 {
            LineString(snappedSelf.lineSegments)?.evenlyDivided(segmentLength: segmentLength)
        }
        else {
            LineString(snappedSelf.lineSegments)
        }
        else {
            return nil
        }

        let p = line.allCoordinates
        var ca: [OrderedIndexPair: Double] = [:]

        func index(_ pI: Int, _ qI: Int) -> OrderedIndexPair {
            .init(pI, qI)
        }

        // Distances between each coordinate pair
        for i in 0 ..< p.count {
            for j in i + 1 ..< p.count {
                let distance = distanceFunction.distance(between: p[i], and: p[j])
                if distance > tolerance { continue }
                ca[index(i, j)] = distance
            }
        }

        // Find coordinate pairs within the tolerance
        var pairs: Set<OrderedIndexPair> = []

        var i = 0
        outer: while i < p.count - 1 {
            defer { i += 1 }

            var j = i + 2
            while ca[index(i, j), default: Double.greatestFiniteMagnitude] <= tolerance {
                j += 1
                if j == p.count { break outer }
            }

            while j < p.count {
                defer { j += 1 }

                if ca[index(i, j), default: Double.greatestFiniteMagnitude] <= tolerance {
                    pairs.insert(index(i, j))
                }
            }
        }

        // Find overlapping segments
        var scratchList = pairs.sorted()
        var result: Set<OrderedIndexPair> = []
        while scratchList.isNotEmpty {
            let candidate = scratchList.removeFirst()

            if candidate.first > 0,
               candidate.second > 0,
               pairs.contains(index(candidate.first - 1, candidate.second - 1))
            {
                result.insert(index(candidate.first, candidate.first - 1))
                result.insert(index(candidate.second, candidate.second - 1))
                continue
            }

            if candidate.first > 0,
               candidate.second < p.count - 1,
               pairs.contains(index(candidate.first - 1, candidate.second + 1))
            {
                result.insert(index(candidate.first, candidate.first - 1))
                result.insert(index(candidate.second, candidate.second + 1))
                continue
            }

            if candidate.first < p.count - 1,
               candidate.second > 0,
               pairs.contains(index(candidate.first + 1, candidate.second - 1))
            {
                result.insert(index(candidate.first, candidate.first + 1))
                result.insert(index(candidate.second, candidate.second - 1))
                continue
            }

            if candidate.first < p.count - 1,
               candidate.second < p.count - 1,
               pairs.contains(index(candidate.first + 1, candidate.second + 1))
            {
                result.insert(index(candidate.first, candidate.first + 1))
                result.insert(index(candidate.second, candidate.second + 1))
                continue
            }
        }

        return MultiLineString(result.map({ LineString(unchecked: [p[$0.first], p[$0.second]]) }))
    }

    /// An estimate of how much the receiver overlaps with itself.
    ///
    /// All projections are supported — delegates to ``overlappingSegments(tolerance:segmentLength:gridSize:)``.
    ///
    /// - Parameter tolerance: The tolerance, in meters. Using `0.0` will only count segments that *exactly* overlap.
    /// - Parameter segmentLength: This value adds intermediate points to the geometry for improved matching, in meters. Choosing this too small might lead to memory explosion.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    ///
    /// - Returns: The length of all segments that overlap within `tolerance`.
    public func estimatedOverlap(
        tolerance: CLLocationDistance,
        segmentLength: Double? = nil,
        gridSize: Double? = nil
    ) -> Double {
        guard let result = overlappingSegments(tolerance: tolerance, segmentLength: segmentLength, gridSize: gridSize) else { return 0.0 }

        return result.length
    }

}

// MARK: - Private

/// A pair of indices used to track overlapping coordinate pairs.
private struct OrderedIndexPair: Hashable, Comparable, CustomStringConvertible {

    /// The first index of the pair.
    let first: Int
    /// The second index of the pair.
    let second: Int

    /// Creates an ordered index pair where the smaller value is stored as `first`.
    init(_ first: Int, _ second: Int) {
        self.first = min(first, second)
        self.second = max(first, second)
    }

    /// A textual representation of the pair.
    var description: String {
        "(\(first)-\(second))"
    }

    /// Returns true if the first pair precedes the second pair in lexicographic order.
    static func < (lhs: OrderedIndexPair, rhs: OrderedIndexPair) -> Bool {
        if lhs.first < rhs.first { return true }
        if lhs.first > rhs.first { return false }
        return lhs.second < rhs.second
    }

}
