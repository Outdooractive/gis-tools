import Foundation

// Ported from GEOS SharedPathsOperation

extension GeoJson {

    /// Finds path segments that are common between the receiver and another geometry.
    ///
    /// Both geometries are decomposed into line segments. A segment from the first
    /// geometry is included in the result if an identical segment (same start and end,
    /// or reversed) exists in the second geometry.
    ///
    /// - Parameter other: The other geometry to compare against.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``MultiLineString`` of shared segments, or `nil` if none are found.
    public func sharedPaths(
        with other: GeoJson,
        gridSize: Double? = nil
    ) -> MultiLineString? {
        let a = gridSize.map { gs in self.snappedToGrid(tolerance: gs) } ?? self
        let b = gridSize.map { gs in other.snappedToGrid(tolerance: gs) } ?? other

        let segmentsA = a.lineSegments
        let segmentsB = b.lineSegments

        guard segmentsA.isNotEmpty,
              segmentsB.isNotEmpty
        else { return nil }

        var matched: [LineSegment] = []

        for segA in segmentsA {
            for segB in segmentsB {
                guard SharedPaths.segmentsMatch(segA, segB) else { continue }

                // Avoid adding the same segment twice
                let isDuplicate = matched.contains { existing in
                    SharedPaths.segmentsMatch(existing, segA)
                }
                if !isDuplicate {
                    matched.append(segA)
                }
                break
            }
        }

        guard matched.isNotEmpty else { return nil }

        let lineStrings: [LineString] = matched.map { seg in
            LineString(unchecked: [seg.first, seg.second])
        }
        return MultiLineString(unchecked: lineStrings)
    }

}

// MARK: - Implementation

private enum SharedPaths {

    /// Check if two segments match (same direction or reversed).
    static func segmentsMatch(_ a: LineSegment, _ b: LineSegment) -> Bool {
        let aFirst = a.first
        let aSecond = a.second
        let bFirst = b.first
        let bSecond = b.second

        // Same direction: a.first→a.second == b.first→b.second
        if aFirst.isCoincident(to: bFirst) && aSecond.isCoincident(to: bSecond) {
            return true
        }
        // Reversed: a.first→a.second == b.second→b.first
        if aFirst.isCoincident(to: bSecond) && aSecond.isCoincident(to: bFirst) {
            return true
        }
        return false
    }

}
