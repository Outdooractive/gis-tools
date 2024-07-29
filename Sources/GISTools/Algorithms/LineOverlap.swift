#if !os(Linux)
    import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-line-overlap

extension LineSegment {

    /// Indicates how one segment compares to another segment.
    public enum LineSegmentComparisonResult {
        /// The two segments are exactly equal
        case equal
        /// The two segments are exactly equal, but in opposite directions.
        case equalReversed
        /// The segments are not equal, even with tolerance.
        case notEqual
        /// The second segment is fully included in the first segment.
        case otherOnThis
        /// The other segment partially overlaps with the first segment
        /// at the first segment's start.
        case otherPartialOverlapAtStart
        /// The other segment partially overlaps with the first segment
        /// at the first segment's end.
        case otherPartialOverlapAtEnd
        /// One of the segments is shorter than the tolerance
        case shortSegment
        /// The first segment is fully included in the second segment.
        case thisOnOther
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

        if tolerance == 0.0 {
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
                return .otherPartialOverlapAtStart
            }

            if other.first != first,
               checkIsOnSegment(other.first),
               other.checkIsOnSegment(first)
            {
                return .otherPartialOverlapAtStart
            }

            if other.first != second,
               checkIsOnSegment(other.first),
               other.checkIsOnSegment(second)
            {
                return .otherPartialOverlapAtEnd
            }

            if other.second != second,
               checkIsOnSegment(other.second),
               other.checkIsOnSegment(second)
            {
                return .otherPartialOverlapAtEnd
            }
        }
        else if tolerance > 0.0 {
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
                return .otherPartialOverlapAtEnd
            }

            if other.second.distance(from: first) > tolerance,
               nearestCoordinateOnSegment(from: other.second).distance <= tolerance,
               other.nearestCoordinateOnSegment(from: first).distance <= tolerance
            {
                return .otherPartialOverlapAtStart
            }

            if other.first.distance(from: first) > tolerance,
               nearestCoordinateOnSegment(from: other.first).distance <= tolerance,
               other.nearestCoordinateOnSegment(from: first).distance <= tolerance
            {
                return .otherPartialOverlapAtStart
            }

            if other.second.distance(from: second) > tolerance,
               nearestCoordinateOnSegment(from: other.second).distance <= tolerance,
               other.nearestCoordinateOnSegment(from: second).distance <= tolerance
            {
                return .otherPartialOverlapAtEnd
            }
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
    ///    - tolerance: The tolerance, in meters
    ///
    /// - Returns: All segments that at least overlap with one other segment. Each segment will only be
    ///            in the result once.
    public func overlappingSegments(tolerance: CLLocationDistance = 0.0) -> [LineSegment] {
        let tolerance = abs(tolerance)
        let sortedSegments: [LineSegment] = lineSegments
            .map { lineSegment in
                var lineSegment = lineSegment
                lineSegment.updateBoundingBox()
                return lineSegment
            }
            .sorted { left, right in
                (left.boundingBox?.northEast.longitude ?? 0.0) < (right.boundingBox?.northEast.longitude ?? 0.0)
            }

        var result = IndexSet()

        for currentIndex in stride(from: sortedSegments.index(before: sortedSegments.endIndex), through: sortedSegments.startIndex, by: -1) {
            let current = sortedSegments[currentIndex]
            var currentMinX = current.boundingBox?.southWest.longitude ?? 0.0
            var currentMinY = current.boundingBox?.southWest.latitude ?? 0.0
            var currentMaxY = current.boundingBox?.northEast.latitude ?? 0.0

            if tolerance > 0.0 {
                let latLongDegrees = GISTool.degrees(
                    fromMeters: tolerance,
                    atLatitude: currentMinY)
                currentMinX -= latLongDegrees.longitudeDegrees
                currentMinY -= latLongDegrees.latitudeDegrees
                currentMaxY += latLongDegrees.latitudeDegrees
            }

            for nextIndex in stride(from: sortedSegments.index(before: currentIndex), through: sortedSegments.startIndex, by: -1) {
                let next = sortedSegments[nextIndex]
                let nextMaxX = next.boundingBox?.northEast.longitude ?? 0.0
                let nextMaxY = next.boundingBox?.northEast.latitude ?? 0.0
                let nextMinY = next.boundingBox?.southWest.latitude ?? 0.0

                guard nextMaxX >= currentMinX else { break }
                guard nextMaxY >= currentMinY, nextMinY <= currentMaxY else { continue }

                let comparison = current.compare(other: next, tolerance: tolerance)
                if comparison == .notEqual
                    || comparison == .shortSegment
                    || comparison == .zeroLengthSegment
                { continue }

                result.insert(currentIndex)
                result.insert(nextIndex)
            }
        }

        return result.map { sortedSegments[$0] }
    }

}
