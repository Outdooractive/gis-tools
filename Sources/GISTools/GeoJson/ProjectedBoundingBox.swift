#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A bounding box with projection.
public struct ProjectedBoundingBox {

    /// The bounding boxes south-west (bottom-left) coordinate.
    public var southWest: ProjectedCoordinate
    /// The bounding boxes north-east (upper-right) coordinate.
    public var northEast: ProjectedCoordinate
    /// The bounding box's `projection`.
    public let projection: Projection

    /// The bounding boxes north-west (upper-left) coordinate.
    public var northWest: ProjectedCoordinate {
        ProjectedCoordinate(latitude: northEast.latitude, longitude: southWest.longitude, projection: projection)
    }

    /// The bounding boxes south-east (bottom-right) coordinate.
    public var southEast: ProjectedCoordinate {
        ProjectedCoordinate(latitude: southWest.latitude, longitude: northEast.longitude, projection: projection)
    }

    /// Create a bounding box with a `southWest` and `northEast` coordinate as well as a `projection`.
    public init(
        southWest: ProjectedCoordinate,
        northEast: ProjectedCoordinate)
    {
        assert(southWest.projection == northEast.projection, "southWest and northEast coordinates MUST have the same projection")

        self.southWest = southWest
        self.northEast = northEast
        self.projection = southWest.projection
    }

    /// Returns a new bounding box expanded by `distance` diagonally.
    public func expand(distance: CLLocationDistance) -> ProjectedBoundingBox {
        ProjectedBoundingBox(
            southWest: southWest.destination(distance: distance, bearing: 225.0),
            northEast: northEast.destination(distance: distance, bearing: 45.0))
    }

    /// A textual representation of the receiver.
    public var description: String {
        "[\(projection.description), [\(southWest.longitude),\(southWest.latitude)],[\(northEast.longitude),\(northEast.latitude)]]"
    }

}

// MARK: - Convenience

extension ProjectedBoundingBox {

    /// Converts the projected bounding box to a `BoundingBox` object.
    public var boundingBox: BoundingBox {
        BoundingBox(
            southWest: southWest.coordinate3D,
            northEast: northEast.coordinate3D)
    }

    /// Check if the bounding box contains `coordinate`.
    public func contains(_ coordinate: ProjectedCoordinate) -> Bool {
        boundingBox.contains(coordinate.coordinate3D)
    }

    /// Check if the bounding box contains `coordinate`.
    public func contains(_ coordinate: Coordinate3D) -> Bool {
        boundingBox.contains(coordinate)
    }

    /// Check if this bounding box contains the other bounding box.
    public func contains(_ other: ProjectedBoundingBox) -> Bool {
        self.contains(other.southWest)
            && self.contains(other.northEast)
    }

}
