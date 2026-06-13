#if canImport(CoreLocation)
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

        /// The coordinate is at the center of the bounding box.
        public static let center = CoordinatePosition(rawValue: 1 << 0)
        /// The coordinate is in the top region of the bounding box.
        public static let top = CoordinatePosition(rawValue: 1 << 1)
        /// The coordinate is in the right region of the bounding box.
        public static let right = CoordinatePosition(rawValue: 1 << 2)
        /// The coordinate is in the bottom region of the bounding box.
        public static let bottom = CoordinatePosition(rawValue: 1 << 3)
        /// The coordinate is in the left region of the bounding box.
        public static let left = CoordinatePosition(rawValue: 1 << 4)
        /// The coordinate is outside the bounding box.
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
    public func position(of point: Point) -> CoordinatePosition {
        position(of: point.coordinate)
    }

    // MARK: - CoreLocation compatibility

#if canImport(CoreLocation)

    /// Returns the relative position of a coordinate with regards to the bounding box.
    public func position(of coordinate: CLLocationCoordinate2D) -> CoordinatePosition {
        position(of: Coordinate3D(coordinate))
    }

    /// Returns the relative position of a location with regards to the bounding box.
    public func position(of coordinate: CLLocation) -> CoordinatePosition {
        position(of: Coordinate3D(coordinate))
    }

#endif

}
