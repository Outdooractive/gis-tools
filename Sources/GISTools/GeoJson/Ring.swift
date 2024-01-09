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
public struct Ring: Sendable {

    public var projection: Projection {
        coordinates.first?.projection ?? .noSRID
    }

    /// The receiver's coordinates.
    public let coordinates: [Coordinate3D]

    public var lineString: LineString {
        LineString(unchecked: coordinates)
    }

    /// Try to initialize a Ring with some coordinates.
    public init?(_ coordinates: [Coordinate3D]) {
        // TODO: Close the ring, if necessary
        guard coordinates.count >= 4 else { return nil }

        self.init(unchecked: coordinates)
    }

    /// Try to initialize a Ring with some coordinates, don't check the coordinates for validity.
    public init(unchecked coordinates: [Coordinate3D]) {
        self.coordinates = coordinates
    }

}

// MARK: - Projection

extension Ring: Projectable {

    public func projected(to newProjection: Projection) -> Ring {
        guard newProjection != projection else { return self }

        return Ring(unchecked: coordinates.map({ $0.projected(to: newProjection) }))
    }

}

// MARK: - BoundingBox

extension Ring {

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if otherBoundingBox.allCoordinates.contains(where: { contains($0) })
            || contains(otherBoundingBox.center)
        {
            return true
        }

        return lineString.intersects(otherBoundingBox)
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension Ring {

    /// Try to initialize a Ring with some coordinates.
    public init?(_ coordinates: [CLLocationCoordinate2D]) {
        self.init(coordinates.map({ Coordinate3D($0) }))
    }

    /// Try to initialize a Ring with some locations.
    public init?(_ coordinates: [CLLocation]) {
        self.init(coordinates.map({ Coordinate3D($0) }))
    }

}
#endif
