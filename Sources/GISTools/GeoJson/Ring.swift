#if canImport(CoreLocation)
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

    /// The receiver's projection.
    public var projection: Projection {
        coordinates.first?.projection ?? .noSRID
    }

    /// The receiver's coordinates.
    public let coordinates: [Coordinate3D]

    /// The receiver as a LineString.
    public var lineString: LineString {
        LineString(unchecked: coordinates)
    }

    /// Try to initialize a Ring with some coordinates.
    ///
    /// - Parameters:
    ///    - coordinates: The coordinates forming the ring (will be closed automatically if needed)
    /// - Returns: A ring, or `nil` if there are fewer than 4 positions
    public init?(_ coordinates: [Coordinate3D]) {
        // Close the ring, if necessary
        var coordinates = coordinates
        if coordinates.count >= 3,
           coordinates.first != coordinates.last
        {
            coordinates.append(coordinates[0])
        }

        guard coordinates.count >= 4 else { return nil }

        self.init(unchecked: coordinates)
    }

    /// Try to initialize a Ring with some coordinates, don't check the coordinates for validity.
    ///
    /// - Parameters:
    ///    - coordinates: The coordinates forming the ring
    public init(unchecked coordinates: [Coordinate3D]) {
        self.coordinates = coordinates
    }

    /// The Ring's circumference.
    ///
    /// - Returns: The circumference in meters
    public var circumference: CLLocationDistance {
        guard coordinates.count >= 2 else { return 0.0 }

        return lineString.length
    }

}

// MARK: - Equatable

extension Ring: Equatable {

    /// Check if two Rings are equal, accounting for shifted start vertices.
    ///
    /// Two rings are equal if they contain the same vertices, regardless
    /// of which vertex appears first.
    public static func ==(lhs: Ring, rhs: Ring) -> Bool {
        lhs.projection == rhs.projection
        && (lhs.coordinates == rhs.coordinates
            || lhs.coordinates.compareShifted(rhs.coordinates))
    }

}

extension [Coordinate3D] {

    /// Compare two coordinate arrays as closed rings, treating them as
    /// equal when one is a rotation of the other.
    func compareShifted(_ other: Self) -> Bool {
        guard count == other.count,
              count >= 2
        else { return false }

        let a = dropLast()
        let b = other.dropLast()
        guard a.count == b.count else { return false }

        if a.first == b.first { return a == b }

        let doubled = a + a
        let len = b.count
        guard len <= doubled.count else { return false }

        outer: for start in 0...(doubled.count - len) {
            for i in 0..<len {
                if doubled[start + i] != b[i] {
                    continue outer
                }
            }
            return true
        }

        return false
    }

}

// MARK: - Projection

extension Ring: Projectable {

    /// Reproject the receiver.
    ///
    /// - Parameter newProjection: The target projection
    /// - Returns: A new ring in the requested projection
    public func projected(to newProjection: Projection) -> Ring {
        guard newProjection != projection else { return self }

        return Ring(unchecked: coordinates.map({ $0.projected(to: newProjection) }))
    }

}

// MARK: - BoundingBox

extension Ring {

    /// Check if the receiver intersects the given bounding box.
    ///
    /// - Parameter otherBoundingBox: The bounding box to check
    /// - Returns: `true` if the bounding boxes intersect
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

#if canImport(CoreLocation)
extension Ring {

    /// Try to initialize a Ring with some coordinates.
    ///
    /// - Parameters:
    ///    - coordinates: The coordinates forming the ring
    /// - Returns: A ring, or `nil` if there are fewer than 4 positions
    public init?(_ coordinates: [CLLocationCoordinate2D]) {
        self.init(coordinates.map({ Coordinate3D($0) }))
    }

    /// Try to initialize a Ring with some locations.
    ///
    /// - Parameters:
    ///    - coordinates: The locations forming the ring
    /// - Returns: A ring, or `nil` if there are fewer than 4 positions
    public init?(_ coordinates: [CLLocation]) {
        self.init(coordinates.map({ Coordinate3D($0) }))
    }

}
#endif
