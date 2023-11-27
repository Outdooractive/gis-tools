#if !os(Linux)
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
    /// - Parameters:
    ///    - start: The starting point
    ///    - end: The stopping point
    public func slice(
        start: Coordinate3D? = nil,
        end: Coordinate3D? = nil)
        -> LineString?
    {
        guard coordinates.count >= 2 else { return nil }

        let start = start?.projected(to: projection)
        let end = end?.projected(to: projection)

        var startVertex: (coordinate: Coordinate3D, index: Int, distance: CLLocationDistance)
        var endVertex: (coordinate: Coordinate3D, index: Int, distance: CLLocationDistance)

        // Find a start point
        if let start = start, let firstVertex = nearestCoordinateOnLine(from: start) {
            startVertex = firstVertex
        }
        else if let start = firstCoordinate {
            startVertex = (coordinate: start, index: 0, distance: 0)
        }
        else {
            return nil
        }

        // Find an end point
        if let end = end, let secondVertex = nearestCoordinateOnLine(from: end) {
            endVertex = secondVertex
        }
        else if let end = lastCoordinate {
            endVertex = (coordinate: end, index: coordinates.count - 1, distance: 0)
        }
        else {
            return nil
        }

        if startVertex.index > endVertex.index {
            swap(&startVertex, &endVertex)
        }

        var clipCoordinates: [Coordinate3D] = [startVertex.coordinate]

        for index in (startVertex.index + 1) ..< endVertex.index + 1 {
            clipCoordinates.append(coordinates[index])
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
    /// - Parameters:
    ///    - start: The starting point
    ///    - end: The stopping point
    public func slice(
        start: Coordinate3D? = nil,
        end: Coordinate3D? = nil)
        -> Feature?
    {
        guard let lineString = geometry as? LineString,
              let lineSlice = lineString.slice(start: start, end: end)
        else { return nil }

        var newFeature = Feature(lineSlice, id: id, properties: properties, calculateBoundingBox: (self.boundingBox != nil))
        newFeature.foreignMembers = foreignMembers
        return newFeature
    }

}
