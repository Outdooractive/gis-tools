#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A linear ring.
///
/// From the specification:
/// - A linear ring is a closed LineString with four or more positions.
/// - The first and last positions are equivalent, and they MUST contain
///   identical values; their representation SHOULD also be identical.
/// - A linear ring is the boundary of a surface or the boundary of a
///   hole in a surface.
/// - A linear ring MUST follow the right-hand rule with respect to the
///   area it bounds, i.e., exterior rings are counterclockwise, and
///   holes are clockwise.
public struct Ring {

    public let coordinates: [Coordinate3D]

    public init?(_ coordinates: [Coordinate3D]) {
        // TODO: Close the ring, if necessary
        guard coordinates.count >= 4 else { return nil }

        self.init(unchecked: coordinates)
    }

    public init(unchecked coordinates: [Coordinate3D]) {
        self.coordinates = coordinates
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension Ring {

    public init?(_ coordinates: [CLLocationCoordinate2D]) {
        self.init(coordinates.map({ Coordinate3D($0) }))
    }

    public init?(_ coordinates: [CLLocation]) {
        self.init(coordinates.map({ Coordinate3D($0) }))
    }

}
#endif
