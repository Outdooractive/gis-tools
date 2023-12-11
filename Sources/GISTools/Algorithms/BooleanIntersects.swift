#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-intersects

extension GeoJson {

    /// Compares two geometries and returns true if they intersect.
    ///
    /// - Parameters:
    ///    - other: The other geometry
    ///
    /// - Returns: *true* if the geometries intersect, *false* otherwise.
    public func intersects(with other: GeoJson) -> Bool {
        !isDisjoint(with: other)
    }

}
