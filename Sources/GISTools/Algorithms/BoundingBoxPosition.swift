#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension BoundingBox {

    /// Position of a coordinate in relation to a bounding box.
    public struct CoordinatePosition: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let center = CoordinatePosition(rawValue: 1 << 0)
        public static let top = CoordinatePosition(rawValue: 1 << 1)
        public static let right = CoordinatePosition(rawValue: 1 << 2)
        public static let bottom = CoordinatePosition(rawValue: 1 << 3)
        public static let left = CoordinatePosition(rawValue: 1 << 4)
        public static let outside = CoordinatePosition(rawValue: 1 << 5)
    }

    /// Returns the relative position of a coordinate with regards to the bounding box.
    public func position(of coordinate: Coordinate3D) -> CoordinatePosition {
        var position: CoordinatePosition = []

        if !contains(coordinate) {
            position.insert(.outside)
        }

        let latitudeSpan = northEast.latitude - southWest.latitude
        let longitudeSpan = northEast.longitude - southWest.longitude

        let topCutoff = southWest.latitude + (latitudeSpan * 0.65)
        if coordinate.latitude > topCutoff {
            position.insert(.top)
        }

        let rightCutoff = southWest.longitude + (longitudeSpan * 0.65)
        if coordinate.longitude > rightCutoff {
            position.insert(.right)
        }

        let bottomCutoff = southWest.latitude + (latitudeSpan * 0.35)
        if coordinate.latitude < bottomCutoff {
            position.insert(.bottom)
        }

        let leftCutoff = southWest.longitude + (longitudeSpan * 0.35)
        if coordinate.longitude < leftCutoff {
            position.insert(.left)
        }

        if position.isEmpty {
            position.insert(.center)
        }

        return position
    }

    /// Returns the relative position of a point with regards to the bounding box.
    public func postion(of point: Point) -> CoordinatePosition {
        position(of: point.coordinate)
    }

    // MARK: - CoreLocation compatibility

#if !os(Linux)

    /// Returns the relative position of a coordinate with regards to the bounding box.
    public func postion(of coordinate: CLLocationCoordinate2D) -> CoordinatePosition {
        position(of: Coordinate3D(coordinate))
    }

    /// Returns the relative position of a location with regards to the bounding box.
    public func postion(of coordinate: CLLocation) -> CoordinatePosition {
        position(of: Coordinate3D(coordinate))
    }

#endif

}
