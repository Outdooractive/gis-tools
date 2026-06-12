#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// A GeoJSON `Polygon` object.
public struct Polygon:
    PolygonGeometry,
    EmptyCreatable
{

    /// The GeoJSON object type.
    public var type: GeoJsonType {
        .polygon
    }

    /// The receiver's projection.
    public var projection: Projection {
        coordinates.first?.first?.projection ?? .noSRID
    }

    /// The receiver's coordinates.
    public let coordinates: [[Coordinate3D]]

    /// All coordinates contained in the receiver.
    public var allCoordinates: [Coordinate3D] {
        coordinates.flatMap({ $0 })
    }

    /// The receiver's bounding box.
    public var boundingBox: BoundingBox?

    /// Foreign members not defined in the GeoJSON specification.
    public var foreignMembers: [String: Sendable] = [:]

    /// The receiver represented as an array of Polygons (containing only itself).
    public var polygons: [Polygon] {
        [self]
    }

    /// The receiver's outer ring.
    public var outerRing: Ring? {
        guard coordinates.isNotEmpty else { return nil }
        return Ring(coordinates[0])
    }

    /// All of the receiver's inner rings.
    public var innerRings: [Ring]? {
        guard coordinates.count > 1 else { return nil }
        return Array(coordinates.suffix(from: 1)).compactMap { Ring($0) }
    }

    /// All of the receiver's rings (outer + inner).
    public var rings: [Ring] {
        coordinates.compactMap { Ring($0) }
    }

    /// Initialize an empty Polygon.
    public init() {
        self.coordinates = []
    }

    /// Try to initialize a Polygon with some coordinates.
    ///
    /// - Parameters:
    ///    - coordinates: The ring coordinates (first array is the outer ring, subsequent are holes)
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    /// - Returns: A polygon, or `nil` if the coordinates are invalid
    public init?(_ coordinates: [[Coordinate3D]], calculateBoundingBox: Bool = false) {
        guard coordinates.isNotEmpty,
              coordinates[0].count >= 3
        else { return nil }

        self.init(unchecked: coordinates, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a Polygon with some coordinates, don't check the coordinates for validity.
    ///
    /// - Parameters:
    ///    - coordinates: The ring coordinates (first array is the outer ring, subsequent are holes)
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    public init(unchecked coordinates: [[Coordinate3D]], calculateBoundingBox: Bool = false) {
        self.coordinates = coordinates

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Try to initialize a Polygon with some Rings.
    ///
    /// - Parameters:
    ///    - rings: The rings (first is the outer ring, subsequent are holes)
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    /// - Returns: A polygon, or `nil` if the rings array is empty
    public init?(_ rings: [Ring], calculateBoundingBox: Bool = false) {
        guard rings.isNotEmpty else { return nil }

        self.init(unchecked: rings, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a Polygon with some Rings, don't check the coordinates for validity.
    ///
    /// - Parameters:
    ///    - rings: The rings (first is the outer ring, subsequent are holes)
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    public init(unchecked rings: [Ring], calculateBoundingBox: Bool = false) {
        self.coordinates = rings.map { $0.coordinates }

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Try to initialize a Polygon from any GeoJSON object.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    /// - Parameters:
    ///    - json: A GeoJSON object
    /// - Returns: A polygon, or `nil` if the input is invalid
    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    /// Try to initialize a Polygon from any GeoJSON object.
    ///
    /// - Parameters:
    ///    - json: A GeoJSON object
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    /// - important: The source is expected to be in EPSG:4326.
    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Sendable],
              Polygon.isValid(geoJson: geoJson),
              let coordinates: [[Coordinate3D]] = Polygon.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinates = coordinates
        self.boundingBox = Polygon.tryCreate(json: geoJson["bbox"])

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
    /// - Returns: A GeoJSON dictionary
    public var asJson: [String: Sendable] {
        var result: [String: Sendable] = [
            "type": GeoJsonType.polygon.rawValue,
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

// MARK: - Projection

extension Polygon {

    /// Returns the receiver projected to a different projection.
    ///
    /// - Parameter newProjection: The target projection.
    /// - Returns: A new polygon in the requested projection
    public func projected(to newProjection: Projection) -> Polygon {
        guard newProjection != projection else { return self }

        var polygon = Polygon(
            unchecked: coordinates.map({ $0.map({ $0.projected(to: newProjection) }) }),
            calculateBoundingBox: (boundingBox != nil))
        polygon.foreignMembers = foreignMembers
        return polygon
    }

}

// MARK: - CoreLocation compatibility

#if canImport(CoreLocation)
extension Polygon {

    /// Try to initialize a Polygon with some coordinates.
    ///
    /// - Parameters:
    ///    - coordinates: The ring coordinates (first array is the outer ring, subsequent are holes)
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    /// - Returns: A polygon, or `nil` if the coordinates are invalid
    public init?(_ coordinates: [[CLLocationCoordinate2D]], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ $0.map({ Coordinate3D($0) }) }), calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a Polygon with some locations.
    ///
    /// - Parameters:
    ///    - coordinates: The ring locations (first array is the outer ring, subsequent are holes)
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    /// - Returns: A polygon, or `nil` if the coordinates are invalid
    public init?(_ coordinates: [[CLLocation]], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ $0.map({ Coordinate3D($0) }) }), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBox

extension Polygon {

    /// Calculate and return the receiver's bounding box.
    ///
    /// - Returns: The calculated bounding box, or `nil` if there are no coordinates
    public func calculateBoundingBox() -> BoundingBox? {
        guard let coordinates = outerRing?.coordinates else { return nil }
        return BoundingBox(coordinates: coordinates)
    }

    /// Check if the receiver intersects the other bounding box.
    ///
    /// - Parameter otherBoundingBox: The bounding box to check.
    /// - Returns: `true` if the bounding boxes intersect
    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox ?? calculateBoundingBox(),
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }

        return outerRing?.intersects(otherBoundingBox) ?? false
    }

}

extension Polygon: Equatable {

    /// Check if two Polygons are equal.
    public static func ==(
        lhs: Polygon,
        rhs: Polygon
    ) -> Bool {
        // Fix: The coordinates might be shifted (like [1, 2, 3] => [3, 1, 2])
        return lhs.projection == rhs.projection
            && lhs.coordinates == rhs.coordinates
    }

}
