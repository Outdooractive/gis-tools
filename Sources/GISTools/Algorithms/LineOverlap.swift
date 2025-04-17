#if !os(Linux)
    import CoreLocation
#endif
import Foundation

extension LineSegment {

    /// Indicates how one segment compares to another segment.
    public enum LineSegmentComparisonResult: Comparable, Hashable {
        /// The two segments are exactly equal
        case equal
        /// The two segments are exactly equal, but in opposite directions.
        case equalReversed
        /// The segments are not equal, even with tolerance.
        case notEqual

        /// The second segment is fully included in the first segment.
        case otherOnThis
        /// The first segment is fully included in the second segment.
        case thisOnOther

        /// The segments partially overlap.
        case partialOverlap

        /// One of the segments is shorter than the tolerance
        case shortSegment
        /// One of the segments has zero length and will be skipped
        case zeroLengthSegment
    }

    /// Checks how the receiver and the other *LineSegment* lie in relation to each other.
    ///
    /// - Note: With `tolerance > 0.0` the segments in the result might not necessarily be
    ///         parallel with each other. The result can then be filtered with ``LineSegment.isParallel``.
    ///
    /// - Note: Altitude/z values will be ignored.
    ///
    /// - Parameters:
    ///    - other: The other *LineSegment*
    ///    - tolerance: The tolerance, in meters
    public func compare(
        other: LineSegment,
        tolerance: CLLocationDistance = 0.0)
        -> LineSegmentComparisonResult
    {
        let other = other.projected(to: projection)
        let tolerance = abs(tolerance)

        if first.equals(other: second, includingAltitude: false)
            || other.first.equals(other: other.second, includingAltitude: false)
        {
            return .zeroLengthSegment
        }

        if tolerance > 0.0,
           length <= tolerance
            || other.length <= tolerance
        {
            return .shortSegment
        }

        if first.equals(other: other.first, includingAltitude: false),
           second.equals(other: other.second, includingAltitude: false)
        {
            return .equal
        }

        if first.equals(other: other.second, includingAltitude: false),
           second.equals(other: other.first, includingAltitude: false)
        {
            return .equalReversed
        }

        // 1. No tolerance
        guard tolerance > 0.0 else {
            if other.checkIsOnSegment(first), other.checkIsOnSegment(second) {
                return .thisOnOther
            }

            if checkIsOnSegment(other.first), checkIsOnSegment(other.second) {
                return .otherOnThis
            }

            if other.second != first,
               checkIsOnSegment(other.second),
               other.checkIsOnSegment(first)
            {
                return .partialOverlap
            }

            if other.first != first,
               checkIsOnSegment(other.first),
               other.checkIsOnSegment(first)
            {
                return .partialOverlap
            }

            if other.first != second,
               checkIsOnSegment(other.first),
               other.checkIsOnSegment(second)
            {
                return .partialOverlap
            }

            if other.second != second,
               checkIsOnSegment(other.second),
               other.checkIsOnSegment(second)
            {
                return .partialOverlap
            }

            return .notEqual
        }

        // 2. with tolerance
        if other.nearestCoordinateOnSegment(from: first).distance <= tolerance,
           other.nearestCoordinateOnSegment(from: second).distance <= tolerance
        {
            return .thisOnOther
        }

        if nearestCoordinateOnSegment(from: other.first).distance <= tolerance,
           nearestCoordinateOnSegment(from: other.second).distance <= tolerance
        {
            return .otherOnThis
        }

        if other.first.distance(from: second) > tolerance,
           nearestCoordinateOnSegment(from: other.first).distance <= tolerance,
           other.nearestCoordinateOnSegment(from: second).distance <= tolerance
        {
            return .partialOverlap
        }

        if other.second.distance(from: first) > tolerance,
           nearestCoordinateOnSegment(from: other.second).distance <= tolerance,
           other.nearestCoordinateOnSegment(from: first).distance <= tolerance
        {
            return .partialOverlap
        }

        if other.first.distance(from: first) > tolerance,
           nearestCoordinateOnSegment(from: other.first).distance <= tolerance,
           other.nearestCoordinateOnSegment(from: first).distance <= tolerance
        {
            return .partialOverlap
        }

        if other.second.distance(from: second) > tolerance,
           nearestCoordinateOnSegment(from: other.second).distance <= tolerance,
           other.nearestCoordinateOnSegment(from: second).distance <= tolerance
        {
            return .partialOverlap
        }

        return .notEqual
    }

}

extension GeoJson {

    /// Indicates how segments overlap
    public typealias SegmentOverlapResult = (
        overlap: LineSegment.LineSegmentComparisonResult,
        segment: LineSegment,
        other: LineSegment)

    /// Returns the overlapping segments between the receiver and the other geometry.
    ///
    /// - Note: Every match will be included in the result twice when comparing an object with itself.
    ///         I.e. when A-B overlap, the result will also include B-A.
    ///
    /// - Note: Altitude/z values will be ignored.
    ///
    /// - Parameters:
    ///    - other: The other geometry, or `nil` for overlapping segments with the receiver itself
    ///    - tolerance: The tolerance, in meters
    public func overlappingSegments(
        with other: GeoJson?,
        tolerance: CLLocationDistance = 0.0)
        -> [SegmentOverlapResult]
    {
        let tolerance = abs(tolerance)
        let isSelfMatching = other == nil
        let other = other?.projected(to: projection) ?? self

        var result: [SegmentOverlapResult] = []

        let tree: RTree<LineSegment> = RTree(other.lineSegments)

        for segment in lineSegments {
            guard let boundingBox = segment.boundingBox ?? segment.calculateBoundingBox() else { continue }

            let matches = tree.search(inBoundingBox: boundingBox)

            var hadSelfSegmentMatch = false

            for match in matches {
                // One match must always be the segment when
                // matching a geometry with itself
                if isSelfMatching,
                   !hadSelfSegmentMatch,
                   segment == match
                {
                    hadSelfSegmentMatch = true
                    continue
                }

                let comparison = segment.compare(other: match, tolerance: tolerance)

                guard comparison != .notEqual,
                      comparison != .shortSegment,
                      comparison != .zeroLengthSegment
                else { continue }

                result.append(SegmentOverlapResult(
                    overlap: comparison,
                    segment: segment,
                    other: match))
            }
        }

        return result
    }

    /// Returns the overlapping segments with the receiver itself.
    ///
    /// This implementation is streamlined for finding self-overlaps.
    ///
    /// - Note: Altitude values will be ignored.
    ///
    /// - Parameters:
    ///    - tolerance: The tolerance, in meters. Choosing this too small might lead to memory explosion.
    ///                 Using `0.0` will only return segments that *exactly* overlap.
    ///
    /// - Returns: All segments that at least overlap with one other segment. Each segment will
    ///            appear in the result only once.
    public func overlappingSegments(
        tolerance: CLLocationDistance = 0.0
    ) -> MultiLineString? {
        let tolerance = abs(tolerance)
        let distanceFunction = FrechetDistanceFunction.haversine

        guard let line = if tolerance > 0.0 {
            LineString(lineSegments)?.evenlyDivided(segmentLength: tolerance)
        }
        else {
            LineString(lineSegments)
        }
        else {
            return nil
        }

        let p = line.allCoordinates
        var ca: [IndexPair: Double] = [:]

        func index(_ pI: Int, _ qI: Int) -> IndexPair {
            .init(first: pI, second: qI)
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
        var pairs: Set<IndexPair> = []

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
                    pairs.insert(.init(first: i, second: j))
                }
            }
        }

        // Find overlapping segments
        var scratchList = pairs.sorted()
        var result: Set<IndexPair> = []
        while scratchList.isNotEmpty {
            let candidate = scratchList.removeFirst()

            if candidate.first > 0,
               candidate.second > 0,
               pairs.contains(.init(first: candidate.first - 1, second: candidate.second - 1))
            {
                result.insert(.init(first: candidate.first, second: candidate.first - 1))
                result.insert(.init(first: candidate.second, second: candidate.second - 1))
                continue
            }

            if candidate.first > 0,
               candidate.second < p.count - 1,
               pairs.contains(.init(first: candidate.first - 1, second: candidate.second + 1))
            {
                result.insert(.init(first: candidate.first, second: candidate.first - 1))
                result.insert(.init(first: candidate.second, second: candidate.second + 1))
                continue
            }

            if candidate.first < p.count - 1,
               candidate.second > 0,
               pairs.contains(.init(first: candidate.first + 1, second: candidate.second - 1))
            {
                result.insert(.init(first: candidate.first, second: candidate.first + 1))
                result.insert(.init(first: candidate.second, second: candidate.second - 1))
                continue
            }

            if candidate.first < p.count - 1,
               candidate.second < p.count - 1,
               pairs.contains(.init(first: candidate.first + 1, second: candidate.second + 1))
            {
                result.insert(.init(first: candidate.first, second: candidate.first + 1))
                result.insert(.init(first: candidate.second, second: candidate.second + 1))
                continue
            }
        }

        return MultiLineString(result.map({ LineString(unchecked: [p[$0.first], p[$0.second]]) }))
    }

    public func estimatedOverlap(
        tolerance: CLLocationDistance
    ) -> Double {
        guard let result = overlappingSegments(tolerance: tolerance) else { return 0.0 }

        return result.length
    }

}

// MARK: - Private

private struct IndexPair: Hashable, Comparable, CustomStringConvertible {

    let first: Int
    let second: Int

    init(first: Int, second: Int) {
        self.first = min(first, second)
        self.second = max(first, second)
    }

    var description: String {
        "(\(first)-\(second))"
    }

    static func < (lhs: IndexPair, rhs: IndexPair) -> Bool {
        if lhs.first < rhs.first { return true }
        if lhs.first > rhs.first { return false }
        return lhs.second < rhs.second
    }

}
