#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// A GeoJSON `Point` object.
public struct Point: PointGeometry {

    /// The GeoJSON object type.
    public var type: GeoJsonType {
        .point
    }

    /// The receiver's projection.
    public var projection: Projection {
        coordinate.projection
    }

    /// The receiver's coordinate.
    public let coordinate: Coordinate3D

    /// All coordinates contained in the receiver.
    public var allCoordinates: [Coordinate3D] {
        [coordinate]
    }

    /// The receiver's bounding box.
    public var boundingBox: BoundingBox?

    /// Foreign members not defined in the GeoJSON specification.
    public var foreignMembers: [String: Sendable] = [:]

    /// The receiver represented as an array of Points (containing only itself).
    public var points: [Point] {
        [self]
    }

    /// Initialize a Point with a coordinate.
    public init(_ coordinate: Coordinate3D, calculateBoundingBox: Bool = false) {
        self.coordinate = coordinate

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Try to initialize a Point from any GeoJSON object.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    /// Try to initialize a Point from any GeoJSON object.
    ///
    /// - parameter json: A GeoJSON object.
    /// - parameter calculateBoundingBox: When true, calculate the bounding box from the coordinates.
    /// - important: The source is expected to be in EPSG:4326.
    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Sendable],
              Point.isValid(geoJson: geoJson),
              let coordinate: Coordinate3D = Point.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinate = coordinate
        self.boundingBox = Point.tryCreate(json: geoJson["bbox"])

        if calculateBoundingBox {
            self.updateBoundingBox()
        }

        if geoJson.count > 2 {
            var foreignMembers = geoJson
            foreignMembers.removeValue(forKey: "type")
            foreignMembers.removeValue(forKey: "coordinates")
            foreignMembers.removeValue(forKey: "bbox")
            self.foreignMembers = foreignMembers
        }
    }

    /// The receiver represented as a JSON dictionary.
    ///
    /// - important: Always projected to EPSG:4326, unless the receiver has no SRID.
    public var asJson: [String: Sendable] {
        var result: [String: Sendable] = [
            "type": GeoJsonType.point.rawValue,
            "coordinates": coordinate.asJson
        ]
        if let boundingBox = boundingBox {
            result["bbox"] = boundingBox.asJson
        }
        result.merge(foreignMembers) { (current, new) in
            return current
        }
        return result
   }

}

// MARK: - Projection

extension Point {

    /// Returns the receiver projected to a different projection.
    ///
    /// - parameter newProjection: The target projection.
    public func projected(to newProjection: Projection) -> Point {
        guard newProjection != projection else { return self }

        var point = Point(
            coordinate.projected(to: newProjection),
            calculateBoundingBox: (boundingBox != nil))
        point.foreignMembers = foreignMembers
        return point
    }

}

// MARK: - CoreLocation compatibility

#if canImport(CoreLocation)
extension Point {

    /// Initialize a Point with a coordinate.
    public init(_ coordinate: CLLocationCoordinate2D, calculateBoundingBox: Bool = false) {
        self.init(Coordinate3D(coordinate), calculateBoundingBox: calculateBoundingBox)
    }

    /// Initialize a Point with a location.
    public init(_ coordinate: CLLocation, calculateBoundingBox: Bool = false) {
        self.init(Coordinate3D(coordinate), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBox

extension Point {

    /// Calculate and return the receiver's bounding box.
    public func calculateBoundingBox() -> BoundingBox? {
        BoundingBox(coordinates: [coordinate])
    }

    /// Check if the receiver intersects the other bounding box.
    ///
    /// - parameter otherBoundingBox: The bounding box to check.
    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        otherBoundingBox.contains(coordinate)
    }

}

extension Point: Equatable {

    /// Check if two Points are equal.
    public static func ==(
        lhs: Point,
        rhs: Point
    ) -> Bool {
        return lhs.projection == rhs.projection
            && lhs.coordinate == rhs.coordinate
    }

}
