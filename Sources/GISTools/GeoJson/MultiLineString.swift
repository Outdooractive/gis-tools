#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A GeoJSON `MultiLineString` object.
public struct MultiLineString: LineStringGeometry, EmptyCreatable {

    public var type: GeoJsonType {
        return .multiLineString
    }

    public var projection: Projection {
        coordinates.first?.first?.projection ?? .noSRID
    }

    /// The MultiLineString's coordinates.
    public let coordinates: [[Coordinate3D]]

    public var allCoordinates: [Coordinate3D] {
        coordinates.flatMap({ $0 })
    }

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Any] = [:]

    public var lineStrings: [LineString] {
        return coordinates.compactMap { LineString($0) }
    }

    public init() {
        self.coordinates = []
    }

    /// Try to initialize a MultiLineString with some coordinates.
    public init?(_ coordinates: [[Coordinate3D]], calculateBoundingBox: Bool = false) {
        guard !coordinates.isEmpty,
              coordinates[0].count >= 2
        else { return nil }

        self.init(unchecked: coordinates, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiLineString with some coordinates, don't check the coordinates for validity.
    public init(unchecked coordinates: [[Coordinate3D]], calculateBoundingBox: Bool = false) {
        self.coordinates = coordinates

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    /// Try to initialize a MultiLineString with some LineStrings.
    public init?(_ lineStrings: [LineString], calculateBoundingBox: Bool = false) {
        guard !lineStrings.isEmpty else { return nil }

        self.init(unchecked: lineStrings, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiLineString with some LineStrings, don't check the coordinates for validity.
    public init(unchecked lineStrings: [LineString], calculateBoundingBox: Bool = false) {
        self.coordinates = lineStrings.map { $0.coordinates }

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    /// Try to initialize a MultiLineString with some LineSegments. Each LineSegment will result in one LineString.
    public init?(_ lineSegments: [LineSegment], calculateBoundingBox: Bool = false) {
        guard !lineSegments.isEmpty else { return nil }

        self.init(unchecked: lineSegments, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiLineString with some LineSegments, don't check the coordinates for validity. Each LineSegment will result in one LineString.
    public init(unchecked lineSegments: [LineSegment], calculateBoundingBox: Bool = false) {
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

    public var asJson: [String: Any] {
        var result: [String: Any] = [
            "type": GeoJsonType.multiLineString.rawValue,
            "coordinates": coordinates.map { $0.map { $0.asJson } }
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

extension MultiLineString {

    /// The receiver's first coordinate.
    public var firstCoordinate: Coordinate3D? {
        return coordinates.first?.first
    }

    /// The receiver's last coordinate.
    public var lastCoordinate: Coordinate3D? {
        return coordinates.last?.last
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension MultiLineString {

    /// Try to initialize a MultiLineString with some coordinates.
    public init?(_ coordinates: [[CLLocationCoordinate2D]], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ $0.map({ Coordinate3D($0) }) }), calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiLineString with some locations.
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

extension MultiLineString: Equatable {

    public static func ==(
        lhs: MultiLineString,
        rhs: MultiLineString)
        -> Bool
    {
        return lhs.projection == rhs.projection
            && lhs.coordinates == rhs.coordinates
    }

}
