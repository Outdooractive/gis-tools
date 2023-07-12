#if !os(Linux)
import CoreLocation
#endif
import Foundation

// MARK: BoundingBox

/// A GeoJSON bounding box.
public struct BoundingBox: GeoJsonReadable, CustomStringConvertible, Sendable {

    /// A bounding box spanning across the whole world.
    public static var world: BoundingBox {
        BoundingBox(southWest: Coordinate3D(latitude: -90.0, longitude: -180.0),
                    northEast: Coordinate3D(latitude: 90.0, longitude: 180.0))
    }

    /// An empty bounding box around (0,0).
    public static var zero: BoundingBox {
        BoundingBox(southWest: Coordinate3D(latitude: 0.0, longitude: 0.0),
                    northEast: Coordinate3D(latitude: 0.0, longitude: 0.0))
    }

    /// The bounding boxes south-west (bottom-left) coordinate.
    public var southWest: Coordinate3D
    /// The bounding boxes north-east (upper-right) coordinate.
    public var northEast: Coordinate3D

    /// The bounding boxes north-west (upper-left) coordinate.
    public var northWest: Coordinate3D {
        Coordinate3D(latitude: northEast.latitude, longitude: southWest.longitude)
    }

    /// The bounding boxes south-east (bottom-right) coordinate.
    public var southEast: Coordinate3D {
        Coordinate3D(latitude: southWest.latitude, longitude: northEast.longitude)
    }

    /// Create a bounding box from `coordinates` and an optional padding in kilometers.
    public init?(coordinates: [Coordinate3D], paddingKilometers: Double = 0.0) {
        guard !coordinates.isEmpty else { return nil }

        var southWest = Coordinate3D(latitude: .infinity, longitude: .infinity)
        var northEast = Coordinate3D(latitude: -.infinity, longitude: -.infinity)

        for currentLocation in coordinates {
            let currentLocation = currentLocation.normalized()

            southWest.latitude = min(southWest.latitude, currentLocation.latitude)
            southWest.longitude = min(southWest.longitude, currentLocation.longitude)
            northEast.latitude = max(northEast.latitude, currentLocation.latitude)
            northEast.longitude = max(northEast.longitude, currentLocation.longitude)
        }

        if paddingKilometers > 0.0 {
            // Length of one minute at this latitude
            let oneDegreeLongitudeDistanceInKilometers: Double = cos(southWest.latitude * Double.pi / 180.0) * 111.0
            let oneDegreeLatitudeDistanceInKilometers: Double = 111.0

            let longitudeDistance: Double = (paddingKilometers / oneDegreeLongitudeDistanceInKilometers)
            let latitudeDistance: Double = (paddingKilometers / oneDegreeLatitudeDistanceInKilometers)

            southWest.latitude -= latitudeDistance
            northEast.latitude += latitudeDistance
            southWest.longitude -= longitudeDistance
            northEast.longitude += longitudeDistance
        }

        self.southWest = southWest
        self.northEast = northEast
    }

    /// Create a bounding box with a `southWest` and `northEast` coordinate.
    public init(southWest: Coordinate3D, northEast: Coordinate3D) {
        self.southWest = southWest
        self.northEast = northEast
    }

    /// Create a bounding box from other bounding boxes.
    public init?(boundingBoxes: [BoundingBox]) {
        self.init(coordinates: boundingBoxes.flatMap({ [$0.southWest, $0.northEast] }))
    }

    /// Try to create a bounding box from some JSON.
    public init?(json: Any?) {
        // GeoJSON
        if let geoJsonCoordinates = json as? [Double] {
            if geoJsonCoordinates.count == 4 {
                self.southWest = Coordinate3D(latitude: geoJsonCoordinates[1], longitude: geoJsonCoordinates[0])
                self.northEast = Coordinate3D(latitude: geoJsonCoordinates[3], longitude: geoJsonCoordinates[2])
            }
            else if geoJsonCoordinates.count == 6 {
                // With altitudes
                self.southWest = Coordinate3D(latitude: geoJsonCoordinates[1], longitude: geoJsonCoordinates[0], altitude: geoJsonCoordinates[2])
                self.northEast = Coordinate3D(latitude: geoJsonCoordinates[4], longitude: geoJsonCoordinates[3], altitude: geoJsonCoordinates[5])
            }
            else {
                return nil
            }
        }
        // Not GeoJSON
        else if let geoJsonCoordinates = json as? [[Double]],
                !geoJsonCoordinates.isEmpty
        {
            let coordinates = geoJsonCoordinates.compactMap { Coordinate3D(json: $0) }
            guard coordinates.count == 2 else { return nil }

            self.southWest = coordinates[0]
            self.northEast = coordinates[1]
        }
        else {
            return nil
        }
    }

    /// Dump the bounding box as JSON.
    public var asJson: [Double] {
        if southWest.altitude != nil || northEast.altitude != nil {
            return [
                southWest.longitude,
                southWest.latitude,
                southWest.altitude ?? 0.0,
                northEast.longitude,
                northEast.latitude,
                northEast.altitude ?? 0.0,
            ]
        }
        else {
            return [
                southWest.longitude,
                southWest.latitude,
                northEast.longitude,
                northEast.latitude,
            ]
        }
    }

    /// Returns a copy of the receiver with some padding in kilometers.
    public func with(padding paddingKilometers: Double) -> BoundingBox {
        BoundingBox(
            coordinates: [southWest, northEast],
            paddingKilometers: paddingKilometers)!
    }

    /// Returns a copy of the receiver expanded by `degrees`.
    public func expand(_ degrees: CLLocationDegrees) -> BoundingBox {
        BoundingBox(
            southWest: Coordinate3D(latitude: southWest.latitude - degrees, longitude: southWest.longitude - degrees),
            northEast: Coordinate3D(latitude: northEast.latitude + degrees, longitude: northEast.longitude + degrees))
    }

    /// Returns a copy of the receiver expanded by `distance` diagonally.
    public func expand(distance: CLLocationDistance) -> BoundingBox {
        BoundingBox(
            southWest: southWest.destination(distance: distance, bearing: 225.0),
            northEast: northEast.destination(distance: distance, bearing: 45.0))
    }

    /// Returns a copy of the receiver that also includes `coordinate`.
    public func expand(including coordinate: Coordinate3D) -> BoundingBox {
        return BoundingBox(coordinates: [southWest, northEast, coordinate])!
    }

    /// Returns a copy of the receiver that also includes the other `boundingBox`.
    public func expand(including boundingBox: BoundingBox) -> BoundingBox {
        return BoundingBox(coordinates: [southWest, northEast, boundingBox.southWest, boundingBox.northEast])!
    }

    /// A textual description of the bounding box.
    public var description: String {
        "[[\(southWest.longitude),\(southWest.latitude)],[\(northEast.longitude),\(northEast.latitude)]]"
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension BoundingBox {

    /// Create a bounding box from `coordinates` and an optional padding in kilometers.
    public init?(coordinates: [CLLocationCoordinate2D], paddingKilometers: Double = 0.0) {
        self.init(coordinates: coordinates.map({ Coordinate3D($0) }), paddingKilometers: paddingKilometers)
    }

    /// Create a bounding box from a south-west and north-east coordinate.
    public init(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        self.init(southWest: Coordinate3D(southWest), northEast: Coordinate3D(northEast))
    }

    /// Create a bounding box from `locations` and an optional padding in kilometers.
    public init?(locations: [CLLocation], paddingKilometers: Double = 0.0) {
        self.init(coordinates: locations.map({ Coordinate3D($0) }), paddingKilometers: paddingKilometers)
    }

    /// Create a bounding box from a south-west and north-east coordinate.
    public init(southWest: CLLocation, northEast: CLLocation) {
        self.init(southWest: Coordinate3D(southWest), northEast: Coordinate3D(northEast))
    }

}
#endif

// MARK: - Convenience

extension BoundingBox {

    /// Converts the bounding box to a `Polygon` object.
    public var boundingBoxPolygon: Polygon {
        Polygon([[southWest, northWest, northEast, southEast, southWest]])!
    }

}

extension BoundingBox {

    /// The center of the bounding box.
    public var center: Coordinate3D {
        let boundingBox = self.normalized()
        return boundingBox.southWest.midpoint(to: boundingBox.northEast)
    }

    /// The area in square meters (approximation).
    public var area: Double {
        let size = self.size
        return size.width * size.height
    }

    /// The size of the bounding box (width, height) in meters (approximation).
    public var size: (width: Double, height: Double) {
        let boundingBox = self.normalized()
        let bearingAngle = boundingBox.southWest.bearing(to: boundingBox.northEast)
        let diagonalLength = boundingBox.southWest.distance(from: boundingBox.northEast)

        return (width: diagonalLength * sin(bearingAngle.degreesToRadians),
                height: diagonalLength * cos(bearingAngle.degreesToRadians))
    }

    /// Check if the receiver contains `coordinate`.
    public func contains(_ coordinate: Coordinate3D) -> Bool {
        let boundingBox = self.normalized()
        let coordinate = coordinate.normalized()

        // self crosses the date line
        if boundingBox.southWest.longitude > boundingBox.northEast.longitude {
            let left = BoundingBox(
                southWest: boundingBox.southWest,
                northEast: Coordinate3D(latitude: boundingBox.northEast.latitude, longitude: 180.0))
            let right = BoundingBox(
                southWest: Coordinate3D(latitude: boundingBox.southWest.latitude, longitude: -180.0),
                northEast: boundingBox.northEast)

            return left.contains(coordinate)
                || right.contains(coordinate)
        }

        return coordinate.latitude >= boundingBox.southWest.latitude
            && coordinate.latitude <= boundingBox.northEast.latitude
            && coordinate.longitude >= boundingBox.southWest.longitude
            && coordinate.longitude <= boundingBox.northEast.longitude
    }

#if !os(Linux)
    /// Check if the receiver contains `coordinate`.
    public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return contains(Coordinate3D(coordinate))
    }

    /// Check if the receiver contains `coordinate`.
    public func contains(_ location: CLLocation) -> Bool {
        return contains(Coordinate3D(location))
    }
#endif

    /// Check if the receiver fully contains the other bounding box.
    public func contains(_ other: BoundingBox) -> Bool {
        self.contains(other.southWest)
            && self.contains(other.northEast)
    }

    /// Check if the receiver intersects with the other bounding box.
    public func intersects(_ other: BoundingBox) -> Bool {
        let boundingBox = self.normalized()
        let other = other.normalized()

        // self crosses date line
        if boundingBox.southWest.longitude > boundingBox.northEast.longitude {
            let left = BoundingBox(
                southWest: boundingBox.southWest,
                northEast: Coordinate3D(latitude: boundingBox.northEast.latitude, longitude: 180.0))
            let right = BoundingBox(
                southWest: Coordinate3D(latitude: boundingBox.southWest.latitude, longitude: -180.0),
                northEast: boundingBox.northEast)

            return left.intersects(other)
                || right.intersects(other)
        }
        // other crosses date line
        else if other.southWest.longitude > other.northEast.longitude {
            let left = BoundingBox(
                southWest: other.southWest,
                northEast: Coordinate3D(latitude: other.northEast.latitude, longitude: 180.0))
            let right = BoundingBox(
                southWest: Coordinate3D(latitude: other.southWest.latitude, longitude: -180.0),
                northEast: other.northEast)

            return self.intersects(left)
                || self.intersects(right)
        }
        else {
            return boundingBox.southWest.longitude <= other.northEast.longitude
                && boundingBox.northEast.longitude >= other.southWest.longitude
                && boundingBox.southWest.latitude <= other.northEast.latitude
                && boundingBox.northEast.latitude >= other.southWest.latitude
        }
    }

    /// Returns the intersection between the receiver and the other bounding box.
    public func intersection(_ other: BoundingBox) -> BoundingBox? {
        let boundingBox = self.normalized()
        let other = other.normalized()

        // self crosses date line
        if boundingBox.southWest.longitude > boundingBox.northEast.longitude {
            let left = BoundingBox(
                southWest: boundingBox.southWest,
                northEast: Coordinate3D(latitude: boundingBox.northEast.latitude, longitude: 180.0))
            let right = BoundingBox(
                southWest: Coordinate3D(latitude: boundingBox.southWest.latitude, longitude: -180.0),
                northEast: boundingBox.northEast)

            let leftIntersection = left.intersection(other)
            let rightIntersection = right.intersection(other)

            if let leftIntersection = leftIntersection,
               let rightIntersection = rightIntersection
            {
                return BoundingBox(
                    southWest: leftIntersection.southWest,
                    northEast: rightIntersection.northEast)
            }
            else if leftIntersection != nil {
                return leftIntersection
            }
            else if rightIntersection != nil {
                return rightIntersection
            }
        }
        // other crosses date line
        else if other.southWest.longitude > other.northEast.longitude {
            let left = BoundingBox(
                southWest: other.southWest,
                northEast: Coordinate3D(latitude: other.northEast.latitude, longitude: 180.0))
            let right = BoundingBox(
                southWest: Coordinate3D(latitude: other.southWest.latitude, longitude: -180.0),
                northEast: other.northEast)

            let leftIntersection = self.intersection(left)
            let rightIntersection = self.intersection(right)

            if let leftIntersection = leftIntersection,
               let rightIntersection = rightIntersection
            {
                return BoundingBox(
                    southWest: leftIntersection.southWest,
                    northEast: rightIntersection.northEast)
            }
            else if leftIntersection != nil {
                return leftIntersection
            }
            else if rightIntersection != nil {
                return rightIntersection
            }
        }
        else {
            if boundingBox.southWest.longitude <= other.northEast.longitude,
               boundingBox.northEast.longitude >= other.southWest.longitude,
               boundingBox.southWest.latitude <= other.northEast.latitude,
               boundingBox.northEast.latitude >= other.southWest.latitude
            {
                return BoundingBox(
                    southWest: Coordinate3D(
                        latitude: max(boundingBox.southWest.latitude, other.southWest.latitude),
                        longitude: max(boundingBox.southWest.longitude, other.southWest.longitude)),
                    northEast: Coordinate3D(
                        latitude: min(boundingBox.northEast.latitude, other.northEast.latitude),
                        longitude: min(boundingBox.northEast.longitude, other.northEast.longitude)))
            }
        }

        return nil
    }

    /// Clamped to [-180.0, 180.0].
    public mutating func normalize() {
        self = self.normalized()
    }

    /// Clamped to [-180.0, 180.0].
    public func normalized() -> BoundingBox {
        guard northEast.longitude - southWest.longitude < 360.0 else {
            return BoundingBox(
                southWest: Coordinate3D(latitude: southWest.latitude, longitude: -180.0),
                northEast: Coordinate3D(latitude: northEast.latitude, longitude: 180.0))
        }

        return BoundingBox(
            southWest: southWest.normalized(),
            northEast: northEast.normalized())
    }

    /// Clamped to [[-180,-90], [180,90]]
    public mutating func clamp() {
        self = self.clamped()
    }

    /// Clamped to [[-180,-90], [180,90]]
    public func clamped() -> BoundingBox {
        BoundingBox(
            southWest: southWest.clamped(),
            northEast: northEast.clamped())
    }

}

extension BoundingBox {

    // TODO: Date line
    /// Combine two bounding boxes.
    public static func + (
        left: BoundingBox,
        right: BoundingBox)
        -> BoundingBox
    {
        BoundingBox(
            southWest: Coordinate3D(
                latitude: min(left.southWest.latitude, right.southWest.latitude),
                longitude: min(left.southWest.longitude, right.southWest.longitude)),
            northEast: Coordinate3D(
                latitude: max(left.northEast.latitude, right.northEast.latitude),
                longitude: max(left.northEast.longitude, right.northEast.longitude)))
    }

    // TODO: Date line
    /// Combine two bounding boxes.
    public mutating func formUnion(_ other: BoundingBox) {
        let boundingBox = self.normalized()
        let other = other.normalized()

        self = boundingBox + other
    }

}

// MARK: - Equatable

extension BoundingBox: Equatable {

    public static func == (
        lhs: BoundingBox,
        rhs: BoundingBox)
        -> Bool
    {
        lhs.northWest == rhs.northWest
            && lhs.southEast == rhs.southEast
    }

}

// MARK: - Hashable

extension BoundingBox: Hashable {}
