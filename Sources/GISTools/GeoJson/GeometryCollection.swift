#if !os(Linux)
import CoreLocation
#endif
import Foundation

public struct GeometryCollection: GeoJsonGeometry {

    public var type: GeoJsonType {
        return .geometryCollection
    }

    public let geometries: [GeoJsonGeometry]

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Any] = [:]

    public init(_ geometry: GeoJsonGeometry, calculateBoundingBox: Bool = false) {
        self.init([geometry], calculateBoundingBox: calculateBoundingBox)
    }

    public init(_ geometries: [GeoJsonGeometry], calculateBoundingBox: Bool = false) {
        self.geometries = geometries

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Any],
              GeometryCollection.isValid(geoJson: geoJson),
              let geometries: [GeoJsonGeometry] = GeometryCollection.tryCreate(json: geoJson["geometries"])
        else { return nil }

        self.geometries = geometries
        self.boundingBox = GeometryCollection.tryCreate(json: geoJson["bbox"])

        if calculateBoundingBox, self.boundingBox == nil {
            self.boundingBox = self.calculateBoundingBox()
        }

        if geoJson.count > 2 {
            var foreignMembers = geoJson
            foreignMembers.removeValue(forKey: "type")
            foreignMembers.removeValue(forKey: "geometries")
            foreignMembers.removeValue(forKey: "bbox")
            self.foreignMembers = foreignMembers
        }
    }

    public func asJson() -> [String: Any] {
        var result: [String: Any] = [
            "type": GeoJsonType.geometryCollection.rawValue,
            "geometries": geometries.map { $0.asJson() }
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

extension GeometryCollection {

    public func calculateBoundingBox() -> BoundingBox? {
        let geometryBoundingBoxes: [BoundingBox] = geometries.compactMap({ $0.boundingBox ?? $0.calculateBoundingBox() })
        guard !geometryBoundingBoxes.isEmpty else { return nil }

        return geometryBoundingBoxes.reduce(geometryBoundingBoxes[0]) { (result, boundingBox) -> BoundingBox in
            return result + boundingBox
        }
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox,
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }
        return geometries.contains { $0.intersects(otherBoundingBox) }
    }

}

extension GeometryCollection {

    public var hasValidCoordinates: Bool {
        return geometries.allSatisfy({ $0.hasValidCoordinates })
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        return checkIsValid(geoJson: geoJson, ofType: .geometryCollection)
    }

}

extension GeometryCollection: Equatable {

    public static func ==(
        lhs: GeometryCollection,
        rhs: GeometryCollection)
        -> Bool
    {
        return lhs.geometries.elementsEqual(rhs.geometries, by: { (left, right) -> Bool in
            return left.isEqualTo(right)
        })
    }

}
