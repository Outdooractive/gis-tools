#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-line-overlap

extension LineSegment {

    /// Indicates how one segment compares to another segment.
    public enum LineSegmentComparisonResult {
        case equal
        case equalReversed
        case notEqual
        case otherOnThis
        case otherPartialOverlapAtStart
        case otherPartialOverlapAtEnd
        case thisOnOther
    }

    /// Checks how the receiver and the other *LineSegment* lie in relation to each other.
    ///
    /// - Note: With `tolerance != 0.0` the segments in the result are not necessarily
    ///         parallel with each other. The result can then be filtered with ``LineSegment.isParallel``.
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

        if first == other.first, second == other.second {
            return .equal
        }
        else if first == other.second, second == other.first {
            return .equalReversed
        }
        else if tolerance == 0.0 {
            if other.checkIsOnSegment(first), other.checkIsOnSegment(second) {
                return .thisOnOther
            }
            else if checkIsOnSegment(other.first), checkIsOnSegment(other.second) {
                return .otherOnThis
            }
            else if other.first != second,
                    checkIsOnSegment(other.first),
                    other.checkIsOnSegment(second)
            {
                return .otherPartialOverlapAtEnd
            }
            else if other.second != first,
                    checkIsOnSegment(other.second),
                    other.checkIsOnSegment(first)
            {
                return .otherPartialOverlapAtStart
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
            else if other.first.distance(from: second) > tolerance,
                    nearestCoordinateOnSegment(from: other.first).distance <= tolerance,
                    other.nearestCoordinateOnSegment(from: second).distance <= tolerance
            {
                return .otherPartialOverlapAtEnd
            }
            else if other.second.distance(from: first) > tolerance,
                    nearestCoordinateOnSegment(from: other.second).distance <= tolerance,
                    other.nearestCoordinateOnSegment(from: first).distance <= tolerance
            {
                return .otherPartialOverlapAtStart
            }
        }

        return .notEqual
    }

}

extension GeoJson {

    /// Indicates how segments overlap
    public typealias SegmentOverlapResult = (
        kind: LineSegment.LineSegmentComparisonResult,
        segment: LineSegment,
        other: LineSegment)

    /// Returns the overlapping segments between the receiver and the other geometry.
    ///
    /// - Parameters:
    ///    - other: The other geometry, or `nil` for overlapping segments within the receiver
    ///    - tolerance: The tolerance, in meters
    public func overlappingSegments(
        with other: GeoJson,
        tolerance: CLLocationDistance = 0.0)
        -> [SegmentOverlapResult]
    {
        let tolerance = abs(tolerance)
        let other = other.projected(to: projection)

        var result: [SegmentOverlapResult] = []

        let tree: RTree<LineSegment> = RTree(other.lineSegments)

        for segment in lineSegments {
            guard let boundingBox = segment.boundingBox ?? segment.calculateBoundingBox() else { continue }

            let matches = tree.search(inBoundingBox: boundingBox)

            for match in matches {
                let comparison = segment.compare(other: match, tolerance: tolerance)

                guard comparison != .notEqual else { continue }

                result.append(SegmentOverlapResult(
                    kind: comparison,
                    segment: segment,
                    other: match))
            }
        }

        return result
    }

    /// Returns the overlapping segments within the receiver.
    ///
    /// - Parameters:
    ///    - tolerance: The tolerance, in meters
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
                if comparison == .notEqual { continue }

                result.insert(currentIndex)
                result.insert(nextIndex)
            }
        }

        return result.map { sortedSegments[$0] }
    }

}
