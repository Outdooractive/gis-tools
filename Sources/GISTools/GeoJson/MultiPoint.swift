#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// A GeoJSON `MultiPoint` object.
public struct MultiPoint:
    PointGeometry,
    EmptyCreatable
{

    /// The GeoJSON object type.
    public var type: GeoJsonType {
        .multiPoint
    }

    /// The receiver's projection.
    public var projection: Projection {
        coordinates.first?.projection ?? .noSRID
    }

    /// The receiver's coordinates.
    public private(set) var coordinates: [Coordinate3D] {
        get {
            points.map { $0.coordinate }
        }
        set {
            points = newValue.compactMap({ Point($0) })
        }
    }

    /// All coordinates contained in the receiver.
    public var allCoordinates: [Coordinate3D] {
        coordinates
    }

    /// The receiver's bounding box.
    public var boundingBox: BoundingBox?

    /// Foreign members not defined in the GeoJSON specification.
    public var foreignMembers: [String: Sendable] = [:]

    /// The receiver's points.
    public private(set) var points: [Point] = []

    /// Initialize an empty MultiPoint.
    public init() {
        self.points = []
    }

    /// Try to initialize a MultiPoint with some coordinates.
    public init?(_ coordinates: [Coordinate3D], calculateBoundingBox: Bool = false) {
        guard !coordinates.isEmpty else { return nil }

        self.init(unchecked: coordinates, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiPoint with some coordinates, don't check the coordinates for validity.
    public init(unchecked coordinates: [Coordinate3D], calculateBoundingBox: Bool = false) {
        self.coordinates = coordinates

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Try to initialize a MultiPoint with some Points.
    public init?(_ points: [Point], calculateBoundingBox: Bool = false) {
        guard !points.isEmpty else { return nil }

        self.init(unchecked: points, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiPoint with some Points, don't check the coordinates for validity.
    public init(unchecked points: [Point], calculateBoundingBox: Bool = false) {
        self.points = points

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Try to initialize a MultiPoint from any GeoJSON object.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    /// Try to initialize a MultiPoint from any GeoJSON object.
    ///
    /// - parameter json: A GeoJSON object.
    /// - parameter calculateBoundingBox: When true, calculate the bounding box from the coordinates.
    /// - important: The source is expected to be in EPSG:4326.
    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Sendable],
              MultiPoint.isValid(geoJson: geoJson),
              let coordinates: [Coordinate3D] = MultiPoint.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinates = coordinates
        self.boundingBox = MultiPoint.tryCreate(json: geoJson["bbox"])

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
    public var asJson: [String: Sendable] {
        var result: [String: Sendable] = [
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

// MARK: - Projection

extension MultiPoint {

    /// Returns the receiver projected to a different projection.
    ///
    /// - parameter newProjection: The target projection.
    public func projected(to newProjection: Projection) -> MultiPoint {
        guard newProjection != projection else { return self }

        var multiPoint = MultiPoint(
            unchecked: coordinates.map({ $0.projected(to: newProjection) }),
            calculateBoundingBox: (boundingBox != nil))
        multiPoint.foreignMembers = foreignMembers
        return multiPoint
    }

}

// MARK: - CoreLocation compatibility

#if canImport(CoreLocation)
extension MultiPoint {

    /// Try to initialize a MultiPoint with some coordinates.
    public init?(_ coordinates: [CLLocationCoordinate2D], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ Coordinate3D($0) }), calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiPoint with some locations.
    public init?(_ coordinates: [CLLocation], calculateBoundingBox: Bool = false) {
        self.init(coordinates.map({ Coordinate3D($0) }), calculateBoundingBox: calculateBoundingBox)
    }

}
#endif

// MARK: - BoundingBox

extension MultiPoint {

    /// Update the receiver's bounding box.
    ///
    /// - parameter ifNecessary: Only update if the receiver doesn't already have one.
    @discardableResult
    public mutating func updateBoundingBox(
        onlyIfNecessary ifNecessary: Bool = true
    ) -> BoundingBox? {
        mapPoints { point in
            var point = point
            point.updateBoundingBox(onlyIfNecessary: ifNecessary)
            return point
        }

        if boundingBox != nil && ifNecessary { return boundingBox }

        boundingBox = calculateBoundingBox()
        return boundingBox
    }

    /// Calculate and return the receiver's bounding box.
    public func calculateBoundingBox() -> BoundingBox? {
        BoundingBox(coordinates: coordinates)
    }

    /// Check if the receiver intersects the other bounding box.
    ///
    /// - parameter otherBoundingBox: The bounding box to check.
    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox ?? calculateBoundingBox(),
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }

        return coordinates.contains { otherBoundingBox.contains($0) }
    }

}

extension MultiPoint: Equatable {

    /// Check if two MultiPoints are equal.
    public static func ==(
        lhs: MultiPoint,
        rhs: MultiPoint
    ) -> Bool {
        return lhs.projection == rhs.projection
            && lhs.coordinates == rhs.coordinates
    }

}

// MARK: - Points

extension MultiPoint {

    /// Insert a Point into the receiver.
    ///
    /// - note: `point` must be in the same projection as the receiver.
    public mutating func insertPoint(
        _ point: Point,
        atIndex index: Int
    ) {
        guard points.count == 0 || projection == point.projection else { return }

        if index < points.count {
            points.insert(point, at: index)
        }
        else {
            points.append(point)
        }

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }
    }

    /// Append a Point to the receiver.
    ///
    /// - note: `point` must be in the same projection as the receiver.
    public mutating func appendPoint(_ point: Point) {
        guard points.count == 0 || projection == point.projection else { return }

        points.append(point)

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }
    }

    /// Remove a Point from the receiver.
    @discardableResult
    public mutating func removePoint(at index: Int) -> Point? {
        guard index >= 0, index < points.count else { return nil }

        let removedGeometry = points.remove(at: index)

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }

        return removedGeometry
    }

    /// Map Points in-place.
    public mutating func mapPoints(_ transform: (Point) -> Point) {
        points = points.map(transform)
    }

    /// Map Points in-place, removing *nil* values.
    public mutating func compactMapPoints(_ transform: (Point) -> Point?) {
        points = points.compactMap(transform)
    }

    /// Filter Points in-place.
    public mutating func filterPoints(_ isIncluded: (Point) -> Bool) {
        points = points.filter(isIncluded)
    }

}
