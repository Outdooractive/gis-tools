#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-flip

extension GeoJson {

    /// Flips the coordinates of the receiver by swapping latitude and longitude.
    ///
    /// Altitude and `m` values are preserved unchanged.
    /// The output projection always matches the input projection.
    ///
    /// - Returns: A new geometry with flipped coordinates.
    public func flipped() -> Self {
        transformedCoordinates { coordinate in
            Coordinate3D(
                x: coordinate.latitude,
                y: coordinate.longitude,
                z: coordinate.altitude,
                m: coordinate.m,
                projection: coordinate.projection)
        }
    }

    /// Flips the coordinates of the receiver in-place.
    public mutating func flip() {
        self = flipped()
    }

}

extension Coordinate3D {

    /// Returns a copy of this coordinate with latitude and longitude swapped.
    public func flipped() -> Coordinate3D {
        Coordinate3D(
            x: latitude,
            y: longitude,
            z: altitude,
            m: m,
            projection: projection)
    }

}
