#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A `LineSegment` is a line with exactly two coordinates.
public struct LineSegment: Sendable {

    public var boundingBox: BoundingBox?

    public let first: Coordinate3D
    public let second: Coordinate3D

    public init(
        first: Coordinate3D,
        second: Coordinate3D,
        calculateBoundingBox: Bool = false)
    {
        self.first = first
        self.second = second

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

}

extension LineSegment {

    public var coordinates: [Coordinate3D] {
        return [first, second]
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension LineSegment {

    public init(
        first: CLLocationCoordinate2D,
        second: CLLocationCoordinate2D,
        calculateBoundingBox: Bool = false)
    {
        self.init(first: Coordinate3D(first), second: Coordinate3D(second), calculateBoundingBox: calculateBoundingBox)
    }

    public init(
        first: CLLocation,
        second: CLLocation,
        calculateBoundingBox: Bool = false)
    {
        self.init(first: Coordinate3D(first), second: Coordinate3D(second), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBoxRepresentable

extension LineSegment: BoundingBoxRepresentable {

    public func calculateBoundingBox() -> BoundingBox? {
        return BoundingBox(coordinates: coordinates)
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox ?? calculateBoundingBox(),
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }

        // The bbox contains one of the end points
        if otherBoundingBox.contains(first)
            || otherBoundingBox.contains(second)
        {
            return true
        }

        // All points are outside of the bbox, on the same side
        if (first.latitude > otherBoundingBox.northEast.latitude && second.latitude > otherBoundingBox.northEast.latitude)
            || (first.latitude < otherBoundingBox.southEast.latitude && second.latitude < otherBoundingBox.southEast.latitude)
            || (first.longitude > otherBoundingBox.northEast.longitude && second.longitude > otherBoundingBox.northEast.longitude)
            || (first.longitude < otherBoundingBox.southEast.longitude && second.longitude < otherBoundingBox.southEast.longitude)
        {
            return false
        }

        for boundingBoxSegment in otherBoundingBox.lineSegments {
            if boundingBoxSegment.intersects(self) {
                return true
            }
        }

        return false
    }

}

// MARK: - Equatable

extension LineSegment: Equatable {

    public static func ==(
        lhs: LineSegment,
        rhs: LineSegment)
        -> Bool
    {
        return lhs.first == rhs.first
            && lhs.second == rhs.second
    }

}

// MARK: - Hashable

extension LineSegment: Hashable {}
