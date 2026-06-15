#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-line-slice

extension LineString {

    /// Takes a start and stop point, and returns a subsection of the line in-between those points.
    /// The start and stop points don't need to fall exactly on the line.
    ///
    /// This can be useful for extracting only the part of a route between waypoints.
    ///
    /// - Parameter start: The starting point (defaults to the first coordinate if `nil`)
    /// - Parameter end: The stopping point (defaults to the last coordinate if `nil`)
    /// - Parameter gridSize: An optional grid size for snapping inputs
    ///
    /// - Returns: A `LineString` subsection, or `nil` if the line has fewer than 2 coordinates.
    public func slice(
        start: Coordinate3D? = nil,
        end: Coordinate3D? = nil,
        gridSize: Double? = nil
    ) -> LineString? {
        let snappedSelf: LineString
        let snappedStart: Coordinate3D?
        let snappedEnd: Coordinate3D?
        if let gridSize {
            snappedSelf = self.snappedToGrid(tolerance: gridSize)
            snappedStart = start.map { $0.snappedToGrid(tolerance: gridSize) }
            snappedEnd = end.map { $0.snappedToGrid(tolerance: gridSize) }
        } else {
            snappedSelf = self
            snappedStart = start
            snappedEnd = end
        }

        guard snappedSelf.coordinates.count >= 2 else { return nil }

        let start = snappedStart?.projected(to: projection)
        let end = snappedEnd?.projected(to: projection)

        var startVertex: (coordinate: Coordinate3D, index: Int, distance: CLLocationDistance)
        var endVertex: (coordinate: Coordinate3D, index: Int, distance: CLLocationDistance)

        // Find a start point
        if let start = start, let firstVertex = snappedSelf.nearestCoordinateOnLine(from: start) {
            startVertex = firstVertex
        }
        else if let start = snappedSelf.firstCoordinate {
            startVertex = (coordinate: start, index: 0, distance: 0)
        }
        else {
            return nil
        }

        // Find an end point
        if let end = end, let secondVertex = snappedSelf.nearestCoordinateOnLine(from: end) {
            endVertex = secondVertex
        }
        else if let end = snappedSelf.lastCoordinate {
            endVertex = (coordinate: end, index: snappedSelf.coordinates.count - 1, distance: 0)
        }
        else {
            return nil
        }

        if startVertex.index > endVertex.index {
            swap(&startVertex, &endVertex)
        }

        var clipCoordinates: [Coordinate3D] = [startVertex.coordinate]

        for index in (startVertex.index + 1) ..< endVertex.index + 1 {
            clipCoordinates.append(snappedSelf.coordinates[index])
        }

        if clipCoordinates.last != endVertex.coordinate {
            clipCoordinates.append(endVertex.coordinate)
        }

        return LineString(clipCoordinates)
    }

}

extension Feature {

    /// Takes a start and stop point, and returns a subsection of the line in-between those points.
    /// The start and stop points don't need to fall exactly on the line.
    ///
    /// This can be useful for extracting only the part of a route between waypoints.
    ///
    /// - Parameter start: The starting point
    /// - Parameter end: The stopping point
    /// - Parameter gridSize: An optional grid size for snapping inputs
    ///
    /// - Returns: A `Feature` subsection, or `nil`.
    public func slice(
        start: Coordinate3D? = nil,
        end: Coordinate3D? = nil,
        gridSize: Double? = nil
    ) -> Feature? {
        guard let lineString = geometry as? LineString,
              let lineSlice = lineString.slice(start: start, end: end, gridSize: gridSize)
        else { return nil }

        var newFeature = Feature(lineSlice, id: id, properties: properties, calculateBoundingBox: (self.boundingBox != nil))
        newFeature.foreignMembers = foreignMembers
        return newFeature
    }

}
