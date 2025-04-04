#if !os(Linux)
    import CoreLocation
#endif
import Foundation

/// A `LineSegment` is a line with exactly two coordinates.
public struct LineSegment: Sendable {

    public var boundingBox: BoundingBox?

    public var projection: Projection {
        first.projection
    }

    /// The segment's first coordinate.
    public let first: Coordinate3D
    /// The segment's second coordinate.
    public let second: Coordinate3D

    /// The index within a `LineString`, if applicable.
    public let index: Int?

    /// Initialize a LineSegment with two coordinates.
    public init(
        first: Coordinate3D,
        second: Coordinate3D,
        index: Int? = nil,
        calculateBoundingBox: Bool = false)
    {
        assert(first.projection == second.projection, "Can't have different projections")

        self.first = first
        self.second = second
        self.index = index

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

}

extension LineSegment {

    /// The receiver's two coordinates.
    public var coordinates: [Coordinate3D] {
        [first, second]
    }

}

// MARK: - Projection

extension LineSegment: Projectable {

    public func projected(to newProjection: Projection) -> LineSegment {
        guard newProjection != projection else { return self }

        return LineSegment(
            first: first.projected(to: newProjection),
            second: second.projected(to: newProjection),
            index: index,
            calculateBoundingBox: (boundingBox != nil))
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension LineSegment {

    /// Initialize a LineSegment with two coordinates.
    public init(
        first: CLLocationCoordinate2D,
        second: CLLocationCoordinate2D,
        index: Int? = nil,
        calculateBoundingBox: Bool = false)
    {
        self.init(first: Coordinate3D(first),
                  second: Coordinate3D(second),
                  index: index,
                  calculateBoundingBox: calculateBoundingBox)
    }

    /// Initialize a LineSegment with two locations.
    public init(
        first: CLLocation,
        second: CLLocation,
        index: Int? = nil,
        calculateBoundingBox: Bool = false)
    {
        self.init(first: Coordinate3D(first),
                  second: Coordinate3D(second),
                  index: index,
                  calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBoxRepresentable

extension LineSegment: BoundingBoxRepresentable {

    public func calculateBoundingBox() -> BoundingBox? {
        BoundingBox(coordinates: coordinates)
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

    public static func == (
        lhs: LineSegment,
        rhs: LineSegment)
        -> Bool
    {
        lhs.first == rhs.first
            && lhs.second == rhs.second
    }

}

// MARK: - Hashable

extension LineSegment: Hashable {}
