#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-clockwise

extension Ring {

    /// Check whether or not the ring is clockwise.
    ///
    /// - Returns: *true* if the ring is clockwise, *false* otherwise.
    public var isClockwise: Bool {
        guard coordinates.count > 0 else { return false }

        var sum: Double = 0.0
        var previous: Coordinate3D?
        var current: Coordinate3D?

        for index in 1 ..< coordinates.count {
            previous = current ?? coordinates[0]
            current = coordinates[index]

            sum += ((current!.longitude - previous!.longitude) * (current!.latitude + previous!.latitude))
        }

        return sum > 0
    }

    /// Check whether or not the ring is counter-clockwise.
    ///
    /// - Returns: *true* if the ring is counter-clockwise, *false* otherwise.
    public var isCounterClockwise: Bool {
        !isClockwise
    }

}
