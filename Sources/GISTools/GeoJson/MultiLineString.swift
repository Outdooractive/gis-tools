#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// A GeoJSON `MultiLineString` object.
public struct MultiLineString:
    LineStringGeometry,
    EmptyCreatable
{

    public var type: GeoJsonType {
        .multiLineString
    }

    public var projection: Projection {
        coordinates.first?.first?.projection ?? .noSRID
    }

    /// The MultiLineString's coordinates.
    public private(set) var coordinates: [[Coordinate3D]] {
        get {
            lineStrings.map { $0.coordinates }
        }
        set {
            lineStrings = newValue.compactMap({ LineString($0) })
        }
    }

    public var allCoordinates: [Coordinate3D] {
        coordinates.flatMap({ $0 })
    }

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Sendable] = [:]

    public private(set) var lineStrings: [LineString] = []

    public init() {
        self.lineStrings = []
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
            self.updateBoundingBox()
        }
    }

    /// Try to initialize a MultiLineString with some LineStrings.
    public init?(_ lineStrings: [LineString], calculateBoundingBox: Bool = false) {
        guard !lineStrings.isEmpty else { return nil }

        self.init(unchecked: lineStrings, calculateBoundingBox: calculateBoundingBox)
    }

    /// Try to initialize a MultiLineString with some LineStrings, don't check the coordinates for validity.
    public init(unchecked lineStrings: [LineString], calculateBoundingBox: Bool = false) {
        self.lineStrings = lineStrings

        if calculateBoundingBox {
            self.updateBoundingBox()
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
            self.updateBoundingBox()
        }
    }

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Sendable],
              MultiLineString.isValid(geoJson: geoJson),
              let coordinates: [[Coordinate3D]] = MultiLineString.tryCreate(json: geoJson["coordinates"])
        else { return nil }

        self.coordinates = coordinates
        self.boundingBox = MultiLineString.tryCreate(json: geoJson["bbox"])

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
        coordinates.first?.first
    }

    /// The receiver's last coordinate.
    public var lastCoordinate: Coordinate3D? {
        coordinates.last?.last
    }

}

// MARK: - Projection

extension MultiLineString {

    public func projected(to newProjection: Projection) -> MultiLineString {
        guard newProjection != projection else { return self }

        var lineString = MultiLineString(
            unchecked: coordinates.map({ $0.map({ $0.projected(to: newProjection) }) }),
            calculateBoundingBox: (boundingBox != nil))
        lineString.foreignMembers = foreignMembers
        return lineString
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

    @discardableResult
    public mutating func updateBoundingBox(onlyIfNecessary ifNecessary: Bool = true) -> BoundingBox? {
        mapLinestrings { linestring in
            var linestring = linestring
            linestring.updateBoundingBox(onlyIfNecessary: ifNecessary)
            return linestring
        }

        if boundingBox != nil && ifNecessary { return boundingBox }

        boundingBox = calculateBoundingBox()
        return boundingBox
    }

    public func calculateBoundingBox() -> BoundingBox? {
        let flattened: [Coordinate3D] = Array(coordinates.joined())
        return BoundingBox(coordinates: flattened)
    }

    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox ?? calculateBoundingBox(),
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

// MARK: - LineStrings

extension MultiLineString {

    /// Insert a LineString into the receiver.
    ///
    /// - note: `linestring` must be in the same projection as the receiver.
    public mutating func insertLineString(_ lineString: LineString, atIndex index: Int) {
        guard lineStrings.count == 0 || projection == lineString.projection else { return }

        if index < lineStrings.count {
            lineStrings.insert(lineString, at: index)
        }
        else {
            lineStrings.append(lineString)
        }

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }
    }

    /// Append a LineString to the receiver.
    ///
    /// - note: `linestring` must be in the same projection as the receiver.
    public mutating func appendLineString(_ lineString: LineString) {
        guard lineStrings.count == 0 || projection == lineString.projection else { return }

        lineStrings.append(lineString)

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }
    }

    /// Remove a LineString from the receiver.
    @discardableResult
    public mutating func removeLineString(at index: Int) -> LineString? {
        guard index >= 0, index < lineStrings.count else { return nil }

        let removedGeometry = lineStrings.remove(at: index)

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }

        return removedGeometry
    }

    /// Map Linestrings in-place.
    public mutating func mapLinestrings(_ transform: (LineString) -> LineString) {
        lineStrings = lineStrings.map(transform)
    }

    /// Map Linestrings in-place, removing *nil* values.
    public mutating func compactMapLinestrings(_ transform: (LineString) -> LineString?) {
        lineStrings = lineStrings.compactMap(transform)
    }

    /// Filter Linestrings in-place.
    public mutating func filterLinestrings(_ isIncluded: (LineString) -> Bool) {
        lineStrings = lineStrings.filter(isIncluded)
    }

}
