#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A GeoJSON `Point` object.
public struct Point: PointGeometry {

    public var type: GeoJsonType {
        return .point
    }

    public let coordinate: Coordinate3D

    public var allCoordinates: [Coordinate3D] {
        [coordinate]
    }

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Any] = [:]

    public var points: [Point] {
        return [self]
    }

    public init(_ coordinate: Coordinate3D, calculateBoundingBox: Bool = false) {
        self.coordinate = coordinate

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Any],
              Point.isValid(geoJson: geoJson),
              let coordinate: Coordinate3D = Point.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinate = coordinate
        self.boundingBox = Point.tryCreate(json: geoJson["bbox"])

        if calculateBoundingBox, self.boundingBox == nil {
            self.boundingBox = self.calculateBoundingBox()
        }

        if geoJson.count > 2 {
            var foreignMembers = geoJson
            foreignMembers.removeValue(forKey: "type")
            foreignMembers.removeValue(forKey: "coordinates")
            foreignMembers.removeValue(forKey: "bbox")
            self.foreignMembers = foreignMembers
        }
    }

    public var asJson: [String: Any] {
        var result: [String: Any] = [
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

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension Point {

    public init(_ coordinate: CLLocationCoordinate2D, calculateBoundingBox: Bool = false) {
        self.init(Coordinate3D(coordinate), calculateBoundingBox: calculateBoundingBox)
    }

    public init(_ coordinate: CLLocation, calculateBoundingBox: Bool = false) {
        self.init(Coordinate3D(coordinate), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBox

extension Point {

    public func calculateBoundingBox() -> BoundingBox? {
        return BoundingBox(coordinates: [coordinate])
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        return otherBoundingBox.contains(coordinate)
    }

}

extension Point: Equatable {

    public static func ==(
        lhs: Point,
        rhs: Point)
        -> Bool
    {
        return lhs.coordinate == rhs.coordinate
    }

}
