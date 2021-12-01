#if !os(Linux)
import CoreLocation
#endif
import Foundation

public struct Polygon: PolygonGeometry, EmptyCreatable {

    public var type: GeoJsonType {
        return .polygon
    }

    public let coordinates: [[Coordinate3D]]

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Any] = [:]

    public var polygons: [Polygon] {
        return [self]
    }

    public var outerRing: Ring? {
        guard !coordinates.isEmpty else { return nil }
        return Ring(coordinates[0])
    }

    public var innerRings: [Ring]? {
        guard coordinates.count > 1 else { return nil }
        return Array(coordinates.suffix(from: 1)).compactMap { Ring($0) }
    }

    public var rings: [Ring] {
        return coordinates.compactMap { Ring($0) }
    }

    public init() {
        self.coordinates = []
    }

    public init?(_ coordinates: [[Coordinate3D]], calculateBoundingBox: Bool = false) {
        guard !coordinates.isEmpty,
              coordinates[0].count >= 3
        else { return nil }

        self.init(unchecked: coordinates, calculateBoundingBox: calculateBoundingBox)
    }

    public init(unchecked coordinates: [[Coordinate3D]], calculateBoundingBox: Bool = false) {
        self.coordinates = coordinates

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(_ rings: [Ring], calculateBoundingBox: Bool = false) {
        guard !rings.isEmpty else { return nil }

        self.init(unchecked: rings, calculateBoundingBox: calculateBoundingBox)
    }

    public init(unchecked rings: [Ring], calculateBoundingBox: Bool = false) {
        self.coordinates = rings.map { $0.coordinates }

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Any],
              Polygon.isValid(geoJson: geoJson),
              let coordinates: [[Coordinate3D]] = Polygon.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinates = coordinates
        self.boundingBox = Polygon.tryCreate(json: geoJson["bbox"])

        if calculateBoundingBox && self.boundingBox == nil {
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
            "type": GeoJsonType.polygon.rawValue,
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

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension Polygon {

    public init?(_ coordinates: [[CLLocationCoordinate2D]], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ $0.map({ Coordinate3D($0) }) }), calculateBoundingBox: calculateBoundingBox)
    }

    public init?(_ coordinates: [[CLLocation]], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ $0.map({ Coordinate3D($0) }) }), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBox

extension Polygon {

    public func calculateBoundingBox() -> BoundingBox? {
        guard let coordinates = outerRing?.coordinates else { return nil }
        return BoundingBox(coordinates: coordinates)
    }

    // TODO: This is not (entirely) correct, needs improvement
    // Check if one the of the bounding box corners or the center is inside the polygon
    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox,
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }

        guard let outerRing = self.outerRing else { return false }

        return outerRing.contains(otherBoundingBox.center)
            || outerRing.contains(otherBoundingBox.northWest)
            || outerRing.contains(otherBoundingBox.northEast)
            || outerRing.contains(otherBoundingBox.southEast)
            || outerRing.contains(otherBoundingBox.southWest)
    }

}

extension Polygon {

    public var hasValidCoordinates: Bool {
        return !coordinates.isEmpty
            && coordinates[0].count >= 3
    }

    public static func isValid(geoJson: [String: Any]) -> Bool {
        return checkIsValid(geoJson: geoJson, ofType: .polygon)
    }

}

extension Polygon: Equatable {

    public static func ==(
        lhs: Polygon,
        rhs: Polygon)
        -> Bool
    {
        // TODO: The coordinats might be shifted (like [1, 2, 3] => [3, 1, 2])
        return lhs.coordinates == rhs.coordinates
    }

}
