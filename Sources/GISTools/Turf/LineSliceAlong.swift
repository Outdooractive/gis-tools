#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-line-slice-along

extension LineString {

    /// Takes a specified distance along the line to a start point, and a specified distance along
    /// the line to a stop point and returns a subsection of the line in-between those points.
    ///
    /// This can be useful for extracting only the part of a route between two distances.
    ///
    /// - Parameters:
    ///   - startDistance: The distance along the line to the starting point, in meters
    ///   - stopDistance: The distance along the line to the ending point, in meters
    public func sliceAlong(
        startDistance: CLLocationDistance = 0.0,
        stopDistance: CLLocationDistance = .greatestFiniteMagnitude)
        -> LineString?
    {
        guard coordinates.count >= 2 else { return nil }

        var slice: [Coordinate3D] = []

        var travelled: CLLocationDistance = 0.0

        for (index, coordinate) in coordinates.enumerated() {
            if startDistance >= travelled, index == coordinates.count - 1 {
                break
            }

            if travelled > startDistance, slice.isEmpty {
                let overshot = startDistance - travelled
                if overshot == 0.0 {
                    slice.append(coordinate)
                    return LineString(slice)
                }

                let direction: CLLocationDirection = coordinate.bearing(to: coordinates[index - 1]) - 180.0
                let interpolated: Coordinate3D = coordinate.destination(distance: overshot, bearing: direction)
                slice.append(interpolated)
            }

            if travelled >= stopDistance {
                let overshot = stopDistance - travelled
                if overshot == 0.0 {
                    slice.append(coordinate)
                    return LineString(slice)
                }

                let direction: CLLocationDirection = coordinate.bearing(to: coordinates[index - 1]) - 180.0
                let interpolated: Coordinate3D = coordinate.destination(distance: overshot, bearing: direction)
                slice.append(interpolated)
                return LineString(slice)
            }

            if travelled >= startDistance {
                slice.append(coordinate)
            }

            if index == coordinates.count - 1 {
                return LineString(slice)
            }

            travelled += coordinate.distance(from: coordinates[index + 1])
        }

        if travelled < startDistance {
            return nil
        }

        return LineString([coordinates[coordinates.count - 1]])
    }

}

extension Feature {

    /// Takes a specified distance along the line to a start point, and a specified distance along
    /// the line to a stop point and returns a subsection of the line in-between those points.
    ///
    /// This can be useful for extracting only the part of a route between two distances.
    ///
    /// - Parameters:
    ///   - startDistance: The distance along the line to the starting point, in meters
    ///   - stopDistance: The distance along the line to the ending point, in meters
    public func sliceAlong(
        startDistance: CLLocationDistance,
        stopDistance: CLLocationDistance)
        -> Feature?
    {
        guard let lineString = geometry as? LineString,
              let lineSlice = lineString.sliceAlong(startDistance: startDistance, stopDistance: stopDistance)
        else { return nil }

        var newFeature = Feature(lineSlice, id: id, properties: properties, calculateBoundingBox: (self.boundingBox != nil))
        newFeature.foreignMembers = foreignMembers
        return newFeature
    }

}
