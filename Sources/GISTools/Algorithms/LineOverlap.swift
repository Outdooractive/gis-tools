#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-line-overlap

extension LineSegment {

    /// Indicates how one segment compares to another segment.
    public enum LineSegmentComparisonResult: Sendable {
        case equal
        case notEqual
        case thisOnOther
        case otherOnThis
    }

    /// Checks how the receiver and the other *LineSegment* lie in relation to each other.
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

        if (first == other.first && second == other.second)
            || (first == other.second && second == other.first)
        {
            return .equal
        }
        else if tolerance == 0.0 {
            if other.checkIsOnSegment(first), other.checkIsOnSegment(second) {
                return .thisOnOther
            }
            else if checkIsOnSegment(other.first), checkIsOnSegment(other.second) {
                return .otherOnThis
            }
        }
        else if tolerance > 0.0 {
            if other.nearestCoordinateOnSegment(from: first).distance <= tolerance,
               other.nearestCoordinateOnSegment(from: second).distance <= tolerance
            {
                return .thisOnOther
            }
            else if nearestCoordinateOnSegment(from: other.first).distance <= tolerance,
                    nearestCoordinateOnSegment(from: other.second).distance <= tolerance
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
    /// - Parameters:
    ///    - other: The other geometry
    ///    - tolerance: The tolerance, in meters
    public func overlappingSegments(
        with other: GeoJson,
        tolerance: CLLocationDistance = 0.0)
        -> [LineSegment]
    {
        let other = other.projected(to: projection)
        let tolerance = abs(tolerance)

        var result: [LineSegment] = []

        let tree: RTree<LineSegment> = RTree(lineSegments)

        for segment in other.lineSegments {
            guard let boundingBox = segment.boundingBox ?? segment.calculateBoundingBox() else { continue }

            for match in tree.search(inBoundingBox: boundingBox) {
                let comparison = segment.compare(other: match, tolerance: tolerance)

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
    /// - Note: Altitude values will be ignored.
    ///
    /// - Parameters:
    ///    - tolerance: The tolerance, in meters. Using `0.0` will only return segments that *exactly* overlap.
    ///    - segmentLength: This value adds intermediate points to the geometry for improved matching, in meters. Choosing this too small might lead to memory explosion.
    ///
    /// - Returns: All segments that at least overlap with one other segment. Each segment will
    ///            appear in the result only once.
    public func overlappingSegments(
        tolerance: CLLocationDistance,
        segmentLength: Double? = nil
    ) -> MultiLineString? {
        let tolerance = abs(tolerance)
        let distanceFunction = FrechetDistanceFunction.haversine

        guard let line = if let segmentLength, segmentLength > 0.0 {
            LineString(lineSegments)?.evenlyDivided(segmentLength: segmentLength)
        }
        else {
            LineString(lineSegments)
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
    /// - Parameters:
    ///    - tolerance: The tolerance, in meters. Using `0.0` will only count segments that *exactly* overlap.
    ///    - segmentLength: This value adds intermediate points to the geometry for improved matching, in meters. Choosing this too small might lead to memory explosion.
    ///
    /// - Returns: The length of all segments that overlap within `tolerance`.
    public func estimatedOverlap(
        tolerance: CLLocationDistance,
        segmentLength: Double? = nil
    ) -> Double {
        guard let result = overlappingSegments(tolerance: tolerance, segmentLength: segmentLength) else { return 0.0 }

        return result.length
    }

}

// MARK: - Private

private struct OrderedIndexPair: Hashable, Comparable, CustomStringConvertible {

    let first: Int
    let second: Int

    init(_ first: Int, _ second: Int) {
        self.first = min(first, second)
        self.second = max(first, second)
    }

    var description: String {
        "(\(first)-\(second))"
    }

    static func < (lhs: OrderedIndexPair, rhs: OrderedIndexPair) -> Bool {
        if lhs.first < rhs.first { return true }
        if lhs.first > rhs.first { return false }
        return lhs.second < rhs.second
    }

}
