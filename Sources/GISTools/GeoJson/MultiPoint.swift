#if !os(Linux)
import CoreLocation
#endif
import Foundation

public struct MultiPoint: PointGeometry {

    public var type: GeoJsonType {
        return .multiPoint
    }

    public let coordinates: [Coordinate3D]

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Any] = [:]

    public var points: [Point] {
        return coordinates.map { Point($0) }
    }

    public init(_ coordinates: [Coordinate3D], calculateBoundingBox: Bool = false) {
        self.coordinates = coordinates

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init(_ points: [Point], calculateBoundingBox: Bool = false) {
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

    public func asJson() -> Any {
        var result: [String: Any] = [
            "type": GeoJsonType.multiPoint.rawValue,
            "coordinates": coordinates.map { $0.asJson() }
        ]
        if let boundingBox = boundingBox {
            result["bbox"] = boundingBox.asJson()
        }
        result.merge(foreignMembers) { (current, new) in
            return current
        }
        return result
    }

}

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

extension MultiPoint {

    public var hasValidCoordinates: Bool {
        return !coordinates.isEmpty
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        return checkIsValid(geoJson: geoJson, ofType: .multiPoint)
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
