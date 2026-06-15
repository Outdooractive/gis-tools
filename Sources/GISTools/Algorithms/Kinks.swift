#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-kinks

extension GeoJson {

    /// Finds all self-intersection points in the geometry.
    ///
    /// Supports ``LineString``, ``MultiLineString``, ``Polygon``,
    /// and ``MultiPolygon``.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``MultiPoint`` with one point for each
    ///   self-intersection.
    public func kinks(gridSize: Double? = nil) -> MultiPoint {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let geometry = (snappedSelf as? Feature)?.geometry ?? (snappedSelf as? GeoJsonGeometry)

        let coordSets: [[Coordinate3D]]

        switch geometry {
        case let ls as LineString:
            coordSets = [ls.coordinates]
        case let mls as MultiLineString:
            coordSets = mls.coordinates
        case let polygon as Polygon:
            coordSets = polygon.coordinates
        case let mp as MultiPolygon:
            coordSets = mp.coordinates.flatMap { $0 }
        default:
            return MultiPoint()
        }

        var intersectionPoints: Set<Coordinate3D> = []

        for setIndex1 in 0..<coordSets.count {
            let line1 = coordSets[setIndex1]
            for setIndex2 in setIndex1..<coordSets.count {
                let line2 = coordSets[setIndex2]
                for i in 0..<(line1.count - 1) {
                    for k in (setIndex1 == setIndex2 ? i : 0)..<(line2.count - 1) {
                        if setIndex1 == setIndex2 {
                            // Adjacent segments share a vertex, not a kink
                            if abs(i - k) == 1 {
                                continue
                            }
                            // First and last segment in a closed ring share a vertex
                            if i == 0, k == line1.count - 2,
                               line1[i] == line1[line1.count - 1]
                            {
                                continue
                            }
                        }

                        let seg1 = LineSegment(
                            first: line1[i],
                            second: line1[i + 1])
                        let seg2 = LineSegment(
                            first: line2[k],
                            second: line2[k + 1])

                        if let intersection = seg1.intersection(seg2) {
                            intersectionPoints.insert(intersection)
                        }
                    }
                }
            }
        }

        return MultiPoint(unchecked: Array(intersectionPoints))
    }

}
