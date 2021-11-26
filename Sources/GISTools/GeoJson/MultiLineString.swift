#if !os(Linux)
import CoreLocation
#endif
import Foundation

public struct MultiLineString: LineStringGeometry, EmptyCreatable {

    public var type: GeoJsonType {
        return .multiLineString
    }

    public let coordinates: [[Coordinate3D]]

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Any] = [:]

    public var lineStrings: [LineString] {
        return coordinates.compactMap { LineString($0) }
    }

    public init() {
        self.coordinates = []
    }

    public init?(_ coordinates: [[Coordinate3D]], calculateBoundingBox: Bool = false) {
        guard !coordinates.isEmpty,
              coordinates[0].count >= 2
        else { return nil }

        self.coordinates = coordinates

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(_ lineStrings: [LineString], calculateBoundingBox: Bool = false) {
        guard !lineStrings.isEmpty else { return nil }

        self.coordinates = lineStrings.map { $0.coordinates }

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(_ lineSegments: [LineSegment], calculateBoundingBox: Bool = false) {
        guard !lineSegments.isEmpty else { return nil }

        self.coordinates = lineSegments.map({ $0.coordinates })

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Any],
              MultiLineString.isValid(geoJson: geoJson),
              let coordinates: [[Coordinate3D]] = MultiLineString.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinates = coordinates
        self.boundingBox = MultiLineString.tryCreate(json: geoJson["bbox"])

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

    public func asJson() -> [String: Any] {
        var result: [String: Any] = [
            "type": GeoJsonType.multiLineString.rawValue,
            "coordinates": coordinates.map { $0.map { $0.asJson() } }
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

extension MultiLineString {

    public var firstCoordinate: Coordinate3D? {
        return coordinates.first?.first
    }

    public var lastCoordinate: Coordinate3D? {
        return coordinates.last?.last
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension MultiLineString {

    public init?(_ coordinates: [[CLLocationCoordinate2D]], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ $0.map({ Coordinate3D($0) }) }), calculateBoundingBox: calculateBoundingBox)
    }

    public init?(_ coordinates: [[CLLocation]], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ $0.map({ Coordinate3D($0) }) }), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBox

extension MultiLineString {

    public func calculateBoundingBox() -> BoundingBox? {
        let flattened: [Coordinate3D] = Array(coordinates.joined())
        return BoundingBox(coordinates: flattened)
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox,
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }
        return lineStrings.contains { $0.intersects(otherBoundingBox) }
    }

}

extension MultiLineString {

    public var hasValidCoordinates: Bool {
        return lineStrings.allSatisfy({ $0.hasValidCoordinates })
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        return checkIsValid(geoJson: geoJson, ofType: .multiLineString)
    }

}

extension MultiLineString: Equatable {

    public static func ==(
        lhs: MultiLineString,
        rhs: MultiLineString)
        -> Bool
    {
        return lhs.coordinates == rhs.coordinates
    }

}
