#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-clockwise

extension Ring {

    /// Check whether or not the ring is clockwise.
    ///
    /// - Returns: `true` if the ring is clockwise, `false` otherwise.
    public var isClockwise: Bool {
        guard coordinates.count > 0 else { return false }

        var sum: Double = 0.0
        var previous: Coordinate3D?
        var current: Coordinate3D?

        for index in 1 ..< coordinates.count {
            previous = current ?? coordinates[0]
            current = coordinates[index]

            let lon1 = previous!.longitude < 0 ? previous!.longitude + 360.0 : previous!.longitude
            let lon2 = current!.longitude < 0 ? current!.longitude + 360.0 : current!.longitude

            sum += ((lon2 - lon1) * (current!.latitude + previous!.latitude))
        }

        return sum > 0
    }

    /// Check whether or not the ring is counter-clockwise.
    ///
    /// - Returns: `true` if the ring is counter-clockwise, `false` otherwise.
    public var isCounterClockwise: Bool {
        !isClockwise
    }

}
