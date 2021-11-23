#if !os(Linux)
import CoreLocation
#endif
import Foundation

// MARK: BoundingBox

public struct BoundingBox: GeoJsonConvertible, CustomStringConvertible {

    public static var world: BoundingBox {
        BoundingBox(southWest: Coordinate3D(latitude: -90.0, longitude: -180.0),
                    northEast: Coordinate3D(latitude: 90.0, longitude: 180.0))
    }

    public static var zero: BoundingBox {
        BoundingBox(coordinates: [Coordinate3D(latitude: 0.0, longitude: 0.0)])
    }

    public var southWest: Coordinate3D
    public var northEast: Coordinate3D

    public var northWest: Coordinate3D {
        Coordinate3D(latitude: northEast.latitude, longitude: southWest.longitude)
    }

    public var southEast: Coordinate3D {
        Coordinate3D(latitude: southWest.latitude, longitude: northEast.longitude)
    }

    public init(coordinates: [Coordinate3D], paddingKilometers: Double = 0.0) {
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

    public init(southWest: Coordinate3D, northEast: Coordinate3D) {
        self.southWest = southWest
        self.northEast = northEast
    }

    public init?(json: Any?) {
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
            return nil
        }
        // Not GeoJSON stanard
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

    public func asJson() -> Any {
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

    public func with(padding paddingKilometers: Double) -> BoundingBox {
        BoundingBox(
            coordinates: [southWest, northEast],
            paddingKilometers: paddingKilometers)
    }

    public var description: String {
        "[[\(southWest.longitude),\(southWest.latitude)],[\(northEast.longitude),\(northEast.latitude)]]"
    }

}

extension BoundingBox {

    public var boundingBoxPolygon: Polygon {
        Polygon([[southWest, northWest, northEast, southEast, southWest]])!
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
        self.contains(other.southWest)
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

    /// The area in square meters (approximation)
    public var area: Double {
        let leftSideLength = southWest.location.distance(from: CLLocation(latitude: northEast.latitude, longitude: southWest.longitude))
        let bottomSideLength = southWest.location.distance(from: CLLocation(latitude: southWest.latitude, longitude: northEast.longitude))

        return leftSideLength * bottomSideLength
    }

}

extension BoundingBox {

    // TODO: Date line
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
