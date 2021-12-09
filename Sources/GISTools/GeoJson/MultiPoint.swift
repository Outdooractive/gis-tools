#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A GeoJSON `MultiPoint` object.
public struct MultiPoint: PointGeometry, EmptyCreatable {

    public var type: GeoJsonType {
        return .multiPoint
    }

    public let coordinates: [Coordinate3D]

    public var allCoordinates: [Coordinate3D] {
        coordinates
    }

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Any] = [:]

    public var points: [Point] {
        return coordinates.map { Point($0) }
    }

    public init() {
        self.coordinates = []
    }

    public init?(_ coordinates: [Coordinate3D], calculateBoundingBox: Bool = false) {
        guard !coordinates.isEmpty else { return nil }

        self.init(unchecked: coordinates, calculateBoundingBox: calculateBoundingBox)
    }

    public init(unchecked coordinates: [Coordinate3D], calculateBoundingBox: Bool = false) {
        self.coordinates = coordinates

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(_ points: [Point], calculateBoundingBox: Bool = false) {
        guard !points.isEmpty else { return nil }

        self.init(unchecked: points, calculateBoundingBox: calculateBoundingBox)
    }

    public init(unchecked points: [Point], calculateBoundingBox: Bool = false) {
        self.coordinates = points.map { $0.coordinate }

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Any],
              MultiPoint.isValid(geoJson: geoJson),
              let coordinates: [Coordinate3D] = MultiPoint.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinates = coordinates
        self.boundingBox = MultiPoint.tryCreate(json: geoJson["bbox"])

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
            "type": GeoJsonType.multiPoint.rawValue,
            "coordinates": coordinates.map { $0.asJson }
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
extension MultiPoint {

    public init?(_ coordinates: [CLLocationCoordinate2D], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ Coordinate3D($0) }), calculateBoundingBox: calculateBoundingBox)
    }

    public init?(_ coordinates: [CLLocation], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ Coordinate3D($0) }), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBox

extension MultiPoint {

    public func calculateBoundingBox() -> BoundingBox? {
        return BoundingBox(coordinates: coordinates)
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox,
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }
        return coordinates.contains { otherBoundingBox.contains($0) }
    }

}

extension MultiPoint: Equatable {

    public static func ==(
        lhs: MultiPoint,
        rhs: MultiPoint)
        -> Bool
    {
        return lhs.coordinates == rhs.coordinates
    }

}
