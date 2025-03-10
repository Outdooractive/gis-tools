#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A GeoJSON `Point` object.
public struct Point: PointGeometry {

    public var type: GeoJsonType {
        .point
    }

    public var projection: Projection {
        coordinate.projection
    }

    /// The receiver's coordinate.
    public let coordinate: Coordinate3D

    public var allCoordinates: [Coordinate3D] {
        [coordinate]
    }

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Sendable] = [:]

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

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

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

#if !os(Linux)
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

    public func calculateBoundingBox() -> BoundingBox? {
        BoundingBox(coordinates: [coordinate])
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        otherBoundingBox.contains(coordinate)
    }

}

extension Point: Equatable {

    public static func ==(
        lhs: Point,
        rhs: Point)
        -> Bool
    {
        return lhs.projection == rhs.projection
            && lhs.coordinate == rhs.coordinate
    }

}
