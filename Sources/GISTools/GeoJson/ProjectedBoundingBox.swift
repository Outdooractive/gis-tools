#if !os(Linux)
import CoreLocation
#endif
import Foundation

public struct ProjectedBoundingBox {

    /// The bounding boxes south-west (bottom-left) coordinate
    public var southWest: ProjectedCoordinate
    /// The bounding boxes north-east (upper-right) coordinate
    public var northEast: ProjectedCoordinate
    /// The bounding boxes `projection`
    public let projection: Projection

    /// The bounding boxes north-west (upper-left) coordinate
    public var northWest: ProjectedCoordinate {
        ProjectedCoordinate(latitude: northEast.latitude, longitude: southWest.longitude, projection: projection)
    }

    /// The bounding boxes south-east (bottom-right) coordinate
    public var southEast: ProjectedCoordinate {
        ProjectedCoordinate(latitude: southWest.latitude, longitude: northEast.longitude, projection: projection)
    }

    /// Create a bounding box with a `southWest` and `northEast` coordinate as well as a `projection`
    public init(
        southWest: ProjectedCoordinate,
        northEast: ProjectedCoordinate)
    {
        assert(southWest.projection == northEast.projection, "southWest and northEast coordinates MUST have the same projection")

        self.southWest = southWest
        self.northEast = northEast
        self.projection = southWest.projection
    }

    /// Returns a new bounding box expanded by `distance` diagonally
    public func expand(distance: CLLocationDistance) -> ProjectedBoundingBox {
        ProjectedBoundingBox(
            southWest: southWest.destination(distance: distance, bearing: 225.0),
            northEast: northEast.destination(distance: distance, bearing: 45.0))
    }

    public var description: String {
        "[\(projection.description), [\(southWest.longitude),\(southWest.latitude)],[\(northEast.longitude),\(northEast.latitude)]]"
    }

}
