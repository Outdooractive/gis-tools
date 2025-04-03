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
        .multiPolygon
    }

    public var projection: Projection {
        coordinates.first?.first?.first?.projection ?? .noSRID
    }

    /// The receiver's coordinates.
    public private(set) var coordinates: [[[Coordinate3D]]] {
        get {
            polygons.map { $0.coordinates }
        }
        set {
            polygons = newValue.compactMap({ Polygon($0) })
        }
    }

    public var allCoordinates: [Coordinate3D] {
        coordinates.flatMap({ $0 }).flatMap({ $0 })
    }

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Sendable] = [:]

    public private(set) var polygons: [Polygon] = []

    public init() {
        self.polygons = []
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
            self.updateBoundingBox()
        }
    }

    /// Try to initialize a MultiPolygon with some Polygons.
    public init?(_ polygons: [Polygon], calculateBoundingBox: Bool = false) {
        guard !polygons.isEmpty else { return nil }

        self.init(unchecked: polygons, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiPolygon with some Polygons, don't check the coordinates for validity.
    public init(unchecked polygons: [Polygon], calculateBoundingBox: Bool = false) {
        self.polygons = polygons

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Sendable],
              MultiPolygon.isValid(geoJson: geoJson),
              let coordinates: [[[Coordinate3D]]] = MultiPolygon.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinates = coordinates
        self.boundingBox = MultiPolygon.tryCreate(json: geoJson["bbox"])

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

    @discardableResult
    public mutating func updateBoundingBox(onlyIfNecessary ifNecessary: Bool = true) -> BoundingBox? {
        mapPolygons { polygon in
            var polygon = polygon
            polygon.updateBoundingBox(onlyIfNecessary: ifNecessary)
            return polygon
        }

        if boundingBox != nil && ifNecessary { return boundingBox }

        boundingBox = calculateBoundingBox()
        return boundingBox
    }

    public func calculateBoundingBox() -> BoundingBox? {
        BoundingBox(coordinates: Array(coordinates.map({ $0.first ?? [] }).joined()))
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox ?? calculateBoundingBox(),
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

// MARK: - Polygons

extension MultiPolygon {

    /// Insert a Polygon into the receiver.
    ///
    /// - note: `polygon` must be in the same projection as the receiver.
    public mutating func insertPolygon(_ polygon: Polygon, atIndex index: Int) {
        guard polygons.count == 0 || projection == polygon.projection else { return }

        if index < polygons.count {
            polygons.insert(polygon, at: index)
        }
        else {
            polygons.append(polygon)
        }

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }
    }

    /// Append a Polygon to the receiver.
    ///
    /// - note: `polygon` must be in the same projection as the receiver.
    public mutating func appendPolygon(_ polygon: Polygon) {
        guard polygons.count == 0 || projection == polygon.projection else { return }

        polygons.append(polygon)

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }
    }

    /// Remove a Polygon from the receiver.
    @discardableResult
    public mutating func removePolygon(at index: Int) -> Polygon? {
        guard index >= 0, index < polygons.count else { return nil }

        let removedGeometry = polygons.remove(at: index)

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }

        return removedGeometry
    }

    /// Map Polygons in-place.
    public mutating func mapPolygons(_ transform: (Polygon) -> Polygon) {
        polygons = polygons.map(transform)
    }

    /// Map Polygons in-place, removing *nil* values.
    public mutating func compactMapPolygons(_ transform: (Polygon) -> Polygon?) {
        polygons = polygons.compactMap(transform)
    }

    /// Filter Polygons in-place.
    public mutating func filterPolygons(_ isIncluded: (Polygon) -> Bool) {
        polygons = polygons.filter(isIncluded)
    }

}
