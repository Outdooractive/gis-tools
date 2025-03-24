#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A GeoJSON bounding box.
public struct BoundingBox:
    GeoJsonReadable,
    CustomStringConvertible,
    Sendable
{

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

    /// The bounding box's `projection`.
    public let projection: Projection

    /// The bounding boxes south-west (bottom-left) coordinate.
    public var southWest: Coordinate3D
    /// The bounding boxes north-east (upper-right) coordinate.
    public var northEast: Coordinate3D

    /// The bounding boxes north-west (upper-left) coordinate.
    public var northWest: Coordinate3D {
        Coordinate3D(x: southWest.longitude, y: northEast.latitude, projection: projection)
    }

    /// The bounding boxes south-east (bottom-right) coordinate.
    public var southEast: Coordinate3D {
        Coordinate3D(x: northEast.longitude, y: southWest.latitude, projection: projection)
    }

    /// Create a bounding box from `coordinates` and an optional padding in kilometers.
    @available(*, deprecated, renamed: "init(coordinates:padding:)", message: "Padding is now expressed in meters")
    public init?(coordinates: [Coordinate3D], paddingKilometers: Double) {
        self.init(coordinates: coordinates, padding: paddingKilometers * 1000.0)
    }

    /// Create a bounding box from `coordinates` and an optional padding.
    ///
    /// - Parameters:
    ///    - padding: The padding, in meters
    public init?(coordinates: [Coordinate3D], padding: CLLocationDistance = 0.0) {
        guard !coordinates.isEmpty else { return nil }

        self.projection = coordinates.first?.projection ?? .epsg4326

        var southWest = Coordinate3D(x: .infinity, y: .infinity, projection: projection)
        var northEast = Coordinate3D(x: -.infinity, y: -.infinity, projection: projection)

        for currentLocation in coordinates {
            let currentLocationLatitude = currentLocation.latitude
            let currentLocationLongitude = currentLocation.longitude

            southWest.latitude = min(southWest.latitude, currentLocationLatitude)
            southWest.longitude = min(southWest.longitude, currentLocationLongitude)
            northEast.latitude = max(northEast.latitude, currentLocationLatitude)
            northEast.longitude = max(northEast.longitude, currentLocationLongitude)
        }

        if padding > 0.0 {
            switch projection {
            case .epsg3857:
                southWest.latitude -= padding
                northEast.latitude += padding
                southWest.longitude -= padding
                northEast.longitude += padding

            case .epsg4326:
                let latLongDegrees = GISTool.degrees(fromMeters: padding, atLatitude: southWest.latitude)

                southWest.latitude -= latLongDegrees.latitudeDegrees
                northEast.latitude += latLongDegrees.latitudeDegrees
                southWest.longitude -= latLongDegrees.longitudeDegrees
                northEast.longitude += latLongDegrees.longitudeDegrees

            case .noSRID:
                break // Don't know what to do -> ignore
            }
        }

        self.southWest = southWest
        self.northEast = northEast
    }

    /// Create a bounding box with a `southWest` and `northEast` coordinate.
    public init(southWest: Coordinate3D, northEast: Coordinate3D) {
        assert(southWest.projection == northEast.projection, "Projections must be the same")

        self.projection = southWest.projection
        self.southWest = southWest
        self.northEast = northEast
    }

    /// Create a bounding box from other bounding boxes.
    public init?(boundingBoxes: [BoundingBox]) {
        self.init(coordinates: boundingBoxes.flatMap({ [$0.southWest, $0.northEast] }))
    }

    /// Try to create a bounding box from some JSON.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    public init?(json: Any?) {
        self.projection = .epsg4326

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
    ///
    /// - important: Always projected to EPSG:4326, unless the coordinate has no SRID.
    public var asJson: [Double] {
        var bottomLeft: [Double] = (projection == .epsg4326 || projection == .noSRID
            ? [southWest.longitude, southWest.latitude]
            : [southWest.longitudeProjected(to: .epsg4326), southWest.latitudeProjected(to: .epsg4326)])
        var topRight: [Double] = (projection == .epsg4326 || projection == .noSRID
            ? [northEast.longitude, northEast.latitude]
            : [northEast.longitudeProjected(to: .epsg4326), northEast.latitudeProjected(to: .epsg4326)])

        if let bottomLeftAltitude = southWest.altitude,
           let topRightAltitude = northEast.altitude
        {
            bottomLeft.append(bottomLeftAltitude)
            topRight.append(topRightAltitude)
        }

        return bottomLeft + topRight
    }

    /// Returns a copy of the receiver with some padding in kilometers.
    @available(*, deprecated, renamed: "padded(_:)", message: "Padding is now expressed in meters")
    public func with(padding paddingKilometers: Double) -> BoundingBox {
        BoundingBox(
            coordinates: [southWest, northEast],
            paddingKilometers: paddingKilometers)!
    }

    /// Returns a copy of the receiver with some padding horizontally and vertically.
    ///
    /// - Parameters:
    ///    - padding: The padding, in meters
    public func padded(_ padding: CLLocationDistance) -> BoundingBox {
        BoundingBox(
            coordinates: [southWest, northEast],
            padding: padding)!
    }

    /// Returns a copy of the receiver expanded by `degrees`.
    @available(*, deprecated, renamed: "expanded(byDegrees:)", message: "Renamed to expaned(byDegrees:)")
    public func expand(_ degrees: CLLocationDegrees) -> BoundingBox {
        expanded(byDegrees: degrees)
    }

    /// Returns a copy of the receiver expanded by `degrees` horizontally and vertically.
    public func expanded(byDegrees degrees: CLLocationDegrees) -> BoundingBox {
        switch projection {
        case .epsg3857:
            return projected(to: .epsg4326).expanded(byDegrees: degrees).projected(to: .epsg3857)

        case .epsg4326:
            return BoundingBox(
                southWest: Coordinate3D(latitude: southWest.latitude - degrees, longitude: southWest.longitude - degrees),
                northEast: Coordinate3D(latitude: northEast.latitude + degrees, longitude: northEast.longitude + degrees))

        case .noSRID:
            return self // Don't know what to do -> ignore
        }
    }

    /// Returns a copy of the receiver expanded by `distance` diagonally.
    @available(*, deprecated, renamed: "expanded(byDistance:)", message: "Renamed to expaned(byDistance:)")
    public func expand(distance: CLLocationDistance) -> BoundingBox {
        expanded(byDistance: distance)
    }

    /// Returns a copy of the receiver expanded by `distance` diagonally.
    ///
    /// - Parameters:
    ///    - distance: The distance from the receiver, in meters
    public func expanded(byDistance distance: CLLocationDistance) -> BoundingBox {
        BoundingBox(
            southWest: southWest.destination(distance: distance, bearing: 225.0),
            northEast: northEast.destination(distance: distance, bearing: 45.0))
    }

    /// Returns a copy of the receiver that also includes `coordinate`.
    @available(*, deprecated, renamed: "expanded(byIncluding:)", message: "Renamed to expanded(byIncluding:)")
    public func expand(including coordinate: Coordinate3D) -> BoundingBox {
        expanded(byIncluding: coordinate)
    }

    /// Returns a copy of the receiver that also includes `coordinate`.
    public func expanded(byIncluding coordinate: Coordinate3D) -> BoundingBox {
        BoundingBox(coordinates: [southWest, northEast, coordinate.projected(to: projection)])!
    }

    /// Returns a copy of the receiver that also includes the other `boundingBox`.
    @available(*, deprecated, renamed: "expanded(byIncluding:)", message: "Renamed to expanded(byIncluding:)")
    public func expand(including boundingBox: BoundingBox) -> BoundingBox {
        expanded(byIncluding: boundingBox)
    }

    /// Returns a copy of the receiver that also includes the other `boundingBox`.
    public func expanded(byIncluding boundingBox: BoundingBox) -> BoundingBox {
        BoundingBox(coordinates: [
            southWest,
            northEast,
            boundingBox.southWest.projected(to: projection),
            boundingBox.northEast.projected(to: projection),
        ])!
    }

    /// A textual description of the bounding box.
    public var description: String {
        "BoundingBox<\(projection.description)>([[\(southWest.longitude),\(southWest.latitude)],[\(northEast.longitude),\(northEast.latitude)]])"
    }

}

// MARK: - Projection

extension BoundingBox: Projectable {

    /// Reproject this bounding box.
    public func projected(to newProjection: Projection) -> BoundingBox {
        guard newProjection != projection else { return self }

        return BoundingBox(
            southWest: southWest.projected(to: newProjection),
            northEast: northEast.projected(to: newProjection))
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension BoundingBox {

    /// Create a bounding box from `coordinates` and an optional padding in kilometers.
    @available(*, deprecated, renamed: "init(coordinates:padding:)", message: "Padding is now expressed in meters")
    public init?(coordinates: [CLLocationCoordinate2D], paddingKilometers: Double) {
        self.init(coordinates: coordinates.map({ Coordinate3D($0) }), paddingKilometers: paddingKilometers)
    }

    /// Create a bounding box from `coordinates` and an optional padding.
    ///
    /// - Parameters:
    ///    - padding: The padding, in meters
    public init?(coordinates: [CLLocationCoordinate2D], padding: Double = 0.0) {
        self.init(coordinates: coordinates.map({ Coordinate3D($0) }), padding: padding)
    }

    /// Create a bounding box from a south-west and north-east coordinate.
    public init(southWest: CLLocationCoordinate2D, northEast: CLLocationCoordinate2D) {
        self.init(southWest: Coordinate3D(southWest), northEast: Coordinate3D(northEast))
    }

    /// Create a bounding box from `locations` and an optional padding in kilometers.
    @available(*, deprecated, renamed: "init(locations:padding:)", message: "Padding is now expressed in meters")
    public init?(locations: [CLLocation], paddingKilometers: Double = 0.0) {
        self.init(coordinates: locations.map({ Coordinate3D($0) }), paddingKilometers: paddingKilometers)
    }

    /// Create a bounding box from `locations` and an optional padding.
    ///
    /// - Parameters:
    ///    - padding: The padding, in meters
    public init?(locations: [CLLocation], padding: Double = 0.0) {
        self.init(coordinates: locations.map({ Coordinate3D($0) }), padding: padding)
    }

    /// Create a bounding box from a south-west and north-east coordinate.
    public init(southWest: CLLocation, northEast: CLLocation) {
        self.init(southWest: Coordinate3D(southWest), northEast: Coordinate3D(northEast))
    }

}
#endif

// MARK: - Convenience

extension BoundingBox {

    /// All of the bounding box's corner coordinates.
    var allCoordinates: [Coordinate3D] {
        [southWest, northWest, northEast, southEast]
    }

    /// Converts the bounding box to a `Polygon` object.
    public var boundingBoxPolygon: Polygon {
        Polygon([[southWest, northWest, northEast, southEast, southWest]])!
    }

    /// The geodesic center of the bounding box.
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
        switch projection {
        case .epsg3857, .noSRID:
            return (width: northEast.longitude - southWest.longitude,
                    height: northEast.latitude - southWest.latitude)

        case .epsg4326:
            let boundingBox = self.normalized()
            let bearingAngle = boundingBox.southWest.bearing(to: boundingBox.northEast)
            let diagonalLength = boundingBox.southWest.distance(from: boundingBox.northEast)

            return (width: diagonalLength * sin(bearingAngle.degreesToRadians),
                    height: diagonalLength * cos(bearingAngle.degreesToRadians))
        }
    }

}

// MARK: - Helpers

extension BoundingBox {

    /// Check if the receiver contains `coordinate`.
    public func contains(_ coordinate: Coordinate3D) -> Bool {
        let boundingBox = self.normalized()
        let coordinate = coordinate.projected(to: projection).normalized()

        // self crosses the date line
        if boundingBox.southWest.longitude > boundingBox.northEast.longitude {
            switch projection {
            case .noSRID:
                return false

            case .epsg3857:
                let left = BoundingBox(
                    southWest: boundingBox.southWest,
                    northEast: Coordinate3D(x: GISTool.originShift, y: boundingBox.northEast.y))
                if left.contains(coordinate) { return true }
                let right = BoundingBox(
                    southWest: Coordinate3D(x: -GISTool.originShift, y: boundingBox.southWest.y),
                    northEast: boundingBox.northEast)
                return right.contains(coordinate)

            case .epsg4326:
                let left = BoundingBox(
                    southWest: boundingBox.southWest,
                    northEast: Coordinate3D(latitude: boundingBox.northEast.latitude, longitude: 180.0))
                if left.contains(coordinate) { return true }
                let right = BoundingBox(
                    southWest: Coordinate3D(latitude: boundingBox.southWest.latitude, longitude: -180.0),
                    northEast: boundingBox.northEast)
                return right.contains(coordinate)
            }
        }

        return coordinate.latitude >= boundingBox.southWest.latitude
            && coordinate.latitude <= boundingBox.northEast.latitude
            && coordinate.longitude >= boundingBox.southWest.longitude
            && coordinate.longitude <= boundingBox.northEast.longitude
    }

    #if !os(Linux)
    /// Check if the receiver contains `coordinate`.
    public func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        contains(Coordinate3D(coordinate))
    }

    /// Check if the receiver contains `coordinate`.
    public func contains(_ location: CLLocation) -> Bool {
        contains(Coordinate3D(location))
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
        let other = other.projected(to: projection).normalized()

        // self crosses date line
        if boundingBox.southWest.longitude > boundingBox.northEast.longitude {
            switch projection {
            case .noSRID:
                return false

            case .epsg3857:
                let left = BoundingBox(
                    southWest: boundingBox.southWest,
                    northEast: Coordinate3D(x: GISTool.originShift, y: boundingBox.northEast.y))
                if left.intersects(other) { return true }
                let right = BoundingBox(
                    southWest: Coordinate3D(x: -GISTool.originShift, y: boundingBox.southWest.y),
                    northEast: boundingBox.northEast)
                return right.intersects(other)

            case .epsg4326:
                let left = BoundingBox(
                    southWest: boundingBox.southWest,
                    northEast: Coordinate3D(latitude: boundingBox.northEast.latitude, longitude: 180.0))
                if left.intersects(other) { return true }
                let right = BoundingBox(
                    southWest: Coordinate3D(latitude: boundingBox.southWest.latitude, longitude: -180.0),
                    northEast: boundingBox.northEast)
                return right.intersects(other)
            }
        }
        // other crosses date line
        else if other.southWest.longitude > other.northEast.longitude {
            switch projection {
            case .noSRID:
                return false

            case .epsg3857:
                let left = BoundingBox(
                    southWest: other.southWest,
                    northEast: Coordinate3D(x: GISTool.originShift, y: other.northEast.y))
                if self.intersects(left) { return true }
                let right = BoundingBox(
                    southWest: Coordinate3D(x: -GISTool.originShift, y: other.southWest.y),
                    northEast: other.northEast)
                return self.intersects(right)

            case .epsg4326:
                let left = BoundingBox(
                    southWest: other.southWest,
                    northEast: Coordinate3D(latitude: other.northEast.latitude, longitude: 180.0))
                if self.intersects(left) { return true }
                let right = BoundingBox(
                    southWest: Coordinate3D(latitude: other.southWest.latitude, longitude: -180.0),
                    northEast: other.northEast)
                return self.intersects(right)
            }
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
        let other = other.projected(to: projection).normalized()

        // self crosses date line
        if boundingBox.southWest.longitude > boundingBox.northEast.longitude {
            let left: BoundingBox
            let right: BoundingBox

            switch projection {
            case .noSRID:
                return nil

            case .epsg3857:
                left = BoundingBox(
                    southWest: boundingBox.southWest,
                    northEast: Coordinate3D(x: GISTool.originShift, y: boundingBox.northEast.latitude))
                right = BoundingBox(
                    southWest: Coordinate3D(x: -GISTool.originShift, y: boundingBox.southWest.latitude),
                    northEast: boundingBox.northEast)

            case .epsg4326:
                left = BoundingBox(
                    southWest: boundingBox.southWest,
                    northEast: Coordinate3D(latitude: boundingBox.northEast.latitude, longitude: 180.0))
                right = BoundingBox(
                    southWest: Coordinate3D(latitude: boundingBox.southWest.latitude, longitude: -180.0),
                    northEast: boundingBox.northEast)
            }

            let leftIntersection = left.intersection(other)
            let rightIntersection = right.intersection(other)

            if let leftIntersection,
               let rightIntersection
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
            let left: BoundingBox
            let right: BoundingBox

            switch projection {
            case .noSRID:
                return nil

            case .epsg3857:
                left = BoundingBox(
                    southWest: other.southWest,
                    northEast: Coordinate3D(x: GISTool.originShift, y: other.northEast.y))
                right = BoundingBox(
                    southWest: Coordinate3D(x: -GISTool.originShift, y: other.southWest.y),
                    northEast: other.northEast)

            case .epsg4326:
                left = BoundingBox(
                    southWest: other.southWest,
                    northEast: Coordinate3D(latitude: other.northEast.latitude, longitude: 180.0))
                right = BoundingBox(
                    southWest: Coordinate3D(latitude: other.southWest.latitude, longitude: -180.0),
                    northEast: other.northEast)
            }

            let leftIntersection = self.intersection(left)
            let rightIntersection = self.intersection(right)

            if let leftIntersection,
               let rightIntersection
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
            if boundingBox.southWest.x <= other.northEast.x,
               boundingBox.northEast.x >= other.southWest.x,
               boundingBox.southWest.y <= other.northEast.y,
               boundingBox.northEast.y >= other.southWest.y
            {
                return BoundingBox(
                    southWest: Coordinate3D(
                        x: max(boundingBox.southWest.x, other.southWest.x),
                        y: max(boundingBox.southWest.y, other.southWest.y),
                        projection: projection),
                    northEast: Coordinate3D(
                        x: min(boundingBox.northEast.x, other.northEast.x),
                        y: min(boundingBox.northEast.y, other.northEast.y),
                        projection: projection))
            }
        }

        return nil
    }

    /// `true` if the receiver crosses the anti-meridian.
    public var crossesAntiMeridian: Bool {
        let boundingBox = self.normalized()

        return boundingBox.southWest.longitude > boundingBox.northEast.longitude
    }

}

// MARK: - Helpers

extension BoundingBox {

    /// Clamped to [-180.0, 180.0].
    public mutating func normalize() {
        self = self.normalized()
    }

    /// Clamped to [-180.0, 180.0].
    public func normalized() -> BoundingBox {
        switch projection {
        case .noSRID:
            return self

        case .epsg3857:
            guard northEast.longitude - southWest.longitude < (2 * GISTool.originShift) else {
                return BoundingBox(
                    southWest: Coordinate3D(x: -GISTool.originShift, y: southWest.latitude),
                    northEast: Coordinate3D(x: GISTool.originShift, y: northEast.latitude))
            }

            return BoundingBox(
                southWest: southWest.normalized(),
                northEast: northEast.normalized())

        case .epsg4326:
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
        lhs: BoundingBox,
        rhs: BoundingBox)
        -> BoundingBox
    {
        let rhs = rhs.projected(to: lhs.projection)

        return BoundingBox(
            southWest: Coordinate3D(
                x: min(lhs.southWest.x, rhs.southWest.x),
                y: min(lhs.southWest.y, rhs.southWest.y),
                projection: lhs.projection),
            northEast: Coordinate3D(
                x: max(lhs.northEast.x, rhs.northEast.x),
                y: max(lhs.northEast.y, rhs.northEast.y),
                projection: lhs.projection))
    }

    // TODO: Date line
    /// Combine two bounding boxes.
    public mutating func formUnion(_ other: BoundingBox) {
        let boundingBox = self.normalized()
        let other = other.projected(to: projection).normalized()

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
        lhs.projection == rhs.projection
            && lhs.northWest == rhs.northWest
            && lhs.southEast == rhs.southEast
    }

}

// MARK: - Hashable

extension BoundingBox: Hashable {}
