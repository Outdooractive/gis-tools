#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A GeoJSON `MultiPolygon` object.
public struct MultiPolygon:
    PolygonGeometry,
    EmptyCreatable
{

    public var type: GeoJsonType {
        return .multiPolygon
    }

    public var projection: Projection {
        coordinates.first?.first?.first?.projection ?? .noSRID
    }

    /// The receiver's coordinates.
    public let coordinates: [[[Coordinate3D]]]

    public var allCoordinates: [Coordinate3D] {
        coordinates.flatMap({ $0 }).flatMap({ $0 })
    }

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Any] = [:]

    public var polygons: [Polygon] {
        return coordinates.compactMap { Polygon($0) }
    }

    public init() {
        self.coordinates = []
    }

    /// Try to initialize a MultiPolygon with some coordinates.
    public init?(_ coordinates: [[[Coordinate3D]]], calculateBoundingBox: Bool = false) {
        guard !coordinates.isEmpty,
              !coordinates[0].isEmpty,
              coordinates[0][0].count >= 3
        else { return nil }

        self.init(unchecked: coordinates, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiPolygon with some coordinates, don't check the coordinates for validity.
    public init(unchecked coordinates: [[[Coordinate3D]]], calculateBoundingBox: Bool = false) {
        self.coordinates = coordinates

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    /// Try to initialize a MultiPolygon with some Polygons.
    public init?(_ polygons: [Polygon], calculateBoundingBox: Bool = false) {
        guard !polygons.isEmpty else { return nil }

        self.init(unchecked: polygons, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiPolygon with some Polygons, don't check the coordinates for validity.
    public init(unchecked polygons: [Polygon], calculateBoundingBox: Bool = false) {
        self.coordinates = polygons.map { $0.coordinates }

        if calculateBoundingBox {
            self.boundingBox = self.calculateBoundingBox()
        }
    }

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Any],
              MultiPolygon.isValid(geoJson: geoJson),
              let coordinates: [[[Coordinate3D]]] = MultiPolygon.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinates = coordinates
        self.boundingBox = MultiPolygon.tryCreate(json: geoJson["bbox"])

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
            "type": GeoJsonType.multiPolygon.rawValue,
            "coordinates": coordinates.map { $0.map { $0.map { $0.asJson } } }
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

extension MultiPolygon {

    public func projected(to newProjection: Projection) -> MultiPolygon {
        guard newProjection != projection else { return self }

        var polygon = MultiPolygon(
            unchecked: coordinates.map({ $0.map({ $0.map({ $0.projected(to: newProjection) }) }) }),
            calculateBoundingBox: (boundingBox != nil))
        polygon.foreignMembers = foreignMembers
        return polygon
    }

}

// MARK: - CoreLocation compatibility

#if !os(Linux)
extension MultiPolygon {

    /// Try to initialize a MultiPolygon with some coordinates.
    public init?(_ coordinates: [[[CLLocationCoordinate2D]]], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ $0.map({ $0.map({ Coordinate3D($0) }) }) }), calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiPolygon with some locations.
    public init?(_ coordinates: [[[CLLocation]]], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ $0.map({ $0.map({ Coordinate3D($0) }) }) }), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBox

extension MultiPolygon {

    public func calculateBoundingBox() -> BoundingBox? {
        return BoundingBox(coordinates: Array(coordinates.map({ $0.first ?? [] }).joined()))
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox,
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }
        return polygons.contains { $0.intersects(otherBoundingBox) }
    }

}

extension MultiPolygon: Equatable {

    public static func ==(
        lhs: MultiPolygon,
        rhs: MultiPolygon)
        -> Bool
    {
        // TODO: The coordinats might be shifted (like [1, 2, 3] => [3, 1, 2])
        return lhs.projection == rhs.projection
            && lhs.coordinates == rhs.coordinates
    }

}
