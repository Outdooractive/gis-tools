#if !os(Linux)
import CoreLocation
#endif
import Foundation

public struct BoundingBox: GeoJsonConvertible {

    public static var world: BoundingBox {
        BoundingBox(southWest: Coordinate3D(latitude: -90.0, longitude: -180.0),
                    northEast: Coordinate3D(latitude: 90.0, longitude: 180.0))
    }

    public var southWest: Coordinate3D
    public var northEast: Coordinate3D

    public var northWest: Coordinate3D {
        return Coordinate3D(latitude: northEast.latitude, longitude: southWest.longitude)
    }

    public var southEast: Coordinate3D {
        return Coordinate3D(latitude: southWest.latitude, longitude: northEast.longitude)
    }

    public init(coordinates: [Coordinate3D]) {
        var southWest = Coordinate3D(latitude: .infinity, longitude: .infinity)
        var northEast = Coordinate3D(latitude: -.infinity, longitude: -.infinity)

        for currentLocation in coordinates {
            let currentLocation = currentLocation.normalized()

            southWest.latitude = min(southWest.latitude, currentLocation.latitude)
            southWest.longitude = min(southWest.longitude, currentLocation.longitude)
            northEast.latitude = max(northEast.latitude, currentLocation.latitude)
            northEast.longitude = max(northEast.longitude, currentLocation.longitude)
        }

        self.southWest = southWest
        self.northEast = northEast
    }

    public init(southWest: Coordinate3D, northEast: Coordinate3D) {
        self.southWest = southWest
        self.northEast = northEast
    }

    public init?(json: Any?) {
        guard let geoJsonCoordinates = json as? [Double] else { return nil }

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

    public func asJson() -> Any {
        if southWest.altitude != nil || northEast.altitude != nil {
            return [
                southWest.longitude,
                southWest.latitude,
                southWest.altitude ?? 0.0,
                northEast.longitude,
                northEast.latitude,
                northEast.altitude ?? 0.0
            ]
        }
        else {
            return [
                southWest.longitude,
                southWest.latitude,
                northEast.longitude,
                northEast.latitude
            ]
        }
    }

}

extension BoundingBox {

    public var boundingBoxPolygon: Polygon {
        return Polygon([[southWest, northWest, northEast, southEast, southWest]])!
    }

}

extension BoundingBox {

    /// The center of the coordinate bounds
    public var center: Coordinate3D {
        let boundingBox = self.normalized()

        let southWestLongitude = boundingBox.southWest.longitude
        var northEastLongitude = boundingBox.northEast.longitude

        while northEastLongitude < southWestLongitude {
            northEastLongitude += 360.0
        }

        let latitude = boundingBox.southWest.latitude + (boundingBox.northEast.latitude - boundingBox.southWest.latitude) / 2.0
        let longitude = southWestLongitude + (northEastLongitude - southWestLongitude) / 2.0

        return Coordinate3D(latitude: latitude, longitude: longitude).normalized()
    }

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

    public func contains(_ other: BoundingBox) -> Bool {
        return self.contains(other.southWest)
            && self.contains(other.northEast)
    }

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

    // Clamped to [-180.0, 180.0]
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

}

extension BoundingBox {

    public static func + (
        left: BoundingBox,
        right: BoundingBox)
        -> BoundingBox
    {
        return BoundingBox(
            southWest: Coordinate3D(
                latitude: min(left.southWest.latitude, right.southWest.latitude),
                longitude: min(left.southWest.longitude, right.southWest.longitude)),
            northEast: Coordinate3D(
                latitude: max(left.northEast.latitude, right.northEast.latitude),
                longitude: max(left.northEast.longitude, right.northEast.longitude)))
    }

}

extension BoundingBox: Equatable {

    public static func == (
        lhs: BoundingBox,
        rhs: BoundingBox)
        -> Bool
    {
        return lhs.northWest == rhs.northWest
            && lhs.southEast == rhs.southEast
    }

}

extension BoundingBox: Hashable {}
