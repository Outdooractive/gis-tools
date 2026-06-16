#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-flip

extension GeoJson {

    /// Flips the coordinates of the receiver by swapping latitude and longitude.
    ///
    /// Altitude and `m` values are preserved unchanged.
    ///
    /// - Returns: A new geometry with flipped coordinates.
    public func flipped() -> Self {
        transformedCoordinates { coordinate in
            Coordinate3D(
                latitude: coordinate.longitude,
                longitude: coordinate.latitude,
                altitude: coordinate.altitude,
                m: coordinate.m)
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
            latitude: longitude,
            longitude: latitude,
            altitude: altitude,
            m: m)
    }

}
