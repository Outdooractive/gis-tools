import Foundation

/// A GeoJSON `GeometryCollection`.
public struct GeometryCollection: GeoJsonGeometry {

    /// The GeoJSON object type.
    public var type: GeoJsonType {
        .geometryCollection
    }

    /// The receiver's projection.
    public var projection: Projection {
        geometries.first?.projection ?? .noSRID
    }

    /// The GeometryCollection's geometry objects.
    public private(set) var geometries: [GeoJsonGeometry]

    /// All coordinates contained in the receiver.
    public var allCoordinates: [Coordinate3D] {
        geometries.flatMap(\.allCoordinates)
    }

    /// The receiver's bounding box.
    public var boundingBox: BoundingBox?

    /// Foreign members not defined in the GeoJSON specification.
    public var foreignMembers: [String: Sendable] = [:]

    /// Initialize a GeometryCollection with a geometry object.
    ///
    /// - Parameters:
    ///    - geometry: The geometry object
    ///    - calculateBoundingBox: When true, calculate the bounding box from the geometry
    public init(_ geometry: GeoJsonGeometry, calculateBoundingBox: Bool = false) {
        self.init([geometry], calculateBoundingBox: calculateBoundingBox)
    }

    /// Initialize a GeometryCollection with some geometry objects.
    ///
    /// - Parameters:
    ///    - geometries: The geometry objects
    ///    - calculateBoundingBox: When true, calculate the bounding box from the geometries
    public init(_ geometries: [GeoJsonGeometry], calculateBoundingBox: Bool = false) {
        self.geometries = geometries

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Try to initialize a GeometryCollection from any GeoJSON object.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    /// - Parameters:
    ///    - json: A GeoJSON object
    /// - Returns: A geometry collection, or `nil` if the input is invalid
    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    /// Try to initialize a GeometryCollection from any GeoJSON object.
    ///
    /// - Parameters:
    ///    - json: A GeoJSON object
    ///    - calculateBoundingBox: When true, calculate the bounding box from the coordinates
    /// - important: The source is expected to be in EPSG:4326.
    /// - Returns: A geometry collection, or `nil` if the input is invalid
    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson = json as? [String: Sendable],
              GeometryCollection.isValid(geoJson: geoJson),
              let geometries: [GeoJsonGeometry] = GeometryCollection.tryCreate(json: geoJson["geometries"])
        else { return nil }

        self.geometries = geometries
        self.boundingBox = GeometryCollection.tryCreate(json: geoJson["bbox"])

        if calculateBoundingBox {
            self.updateBoundingBox()
        }

        if geoJson.count > 2 {
            var foreignMembers = geoJson
            foreignMembers.removeValue(forKey: "type")
            foreignMembers.removeValue(forKey: "geometries")
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
            "type": GeoJsonType.geometryCollection.rawValue,
            "geometries": geometries.map { $0.asJson }
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

extension GeometryCollection {

    /// Update the receiver's bounding box.
    ///
    /// - Parameter onlyIfNecessary: Only update if the receiver doesn't already have one
    /// - Returns: The updated bounding box
    @discardableResult
    public mutating func updateBoundingBox(
        onlyIfNecessary ifNecessary: Bool = true
    ) -> BoundingBox? {
        mapGeometries { geometry in
            var geometry = geometry
            geometry.updateBoundingBox(onlyIfNecessary: ifNecessary)
            return geometry
        }

        if boundingBox != nil && ifNecessary { return boundingBox }

        boundingBox = calculateBoundingBox()
        return boundingBox
    }

    /// Calculate and return the receiver's bounding box by combining all geometry bounding boxes.
    ///
    /// - Returns: The calculated bounding box, or `nil` if there are no geometries
    public func calculateBoundingBox() -> BoundingBox? {
        let geometryBoundingBoxes: [BoundingBox] = geometries.compactMap({ $0.boundingBox ?? $0.calculateBoundingBox() })
        guard !geometryBoundingBoxes.isEmpty else { return nil }

        return geometryBoundingBoxes.reduce(geometryBoundingBoxes[0]) { (result, boundingBox) -> BoundingBox in
            return result + boundingBox
        }
    }

    /// Check if the receiver intersects the other bounding box.
    ///
    /// - Parameter otherBoundingBox: The bounding box to check
    /// - Returns: `true` if the bounding boxes intersect
    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox,
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }
        return geometries.contains { $0.intersects(otherBoundingBox) }
    }

}

extension GeometryCollection: Equatable {

    /// Check if two GeometryCollections are equal.
    public static func ==(
        lhs: GeometryCollection,
        rhs: GeometryCollection
    ) -> Bool {
        return lhs.projection == rhs.projection
            && lhs.geometries.elementsEqual(rhs.geometries, by: { (left, right) -> Bool in
                return left.isEqualTo(right)
            })
    }

}

// MARK: - Projection

extension GeometryCollection {

    /// Returns the receiver projected to a different projection.
    ///
    /// - Parameter newProjection: The target projection
    /// - Returns: A new geometry collection in the requested projection
    public func projected(to newProjection: Projection) -> GeometryCollection {
        guard newProjection != projection else { return self }

        var geometryCollection = GeometryCollection(
            geometries.map({ $0.projected(to: newProjection) }),
            calculateBoundingBox: (boundingBox != nil))
        geometryCollection.foreignMembers = foreignMembers
        return geometryCollection
    }

}

// MARK: - Geometries

extension GeometryCollection {

    /// Insert a GeoJsonGeometry into the receiver.
    ///
    /// - note: `geometry` must be in the same projection as the receiver.
    /// - Parameters:
    ///    - geometry: The geometry to insert
    ///    - index: The index at which to insert
    public mutating func insertGeometry(
        _ geometry: GeoJsonGeometry,
        atIndex index: Int
    ) {
        guard geometries.count == 0 || projection == geometry.projection else { return }

        if index < geometries.count {
            geometries.insert(geometry, at: index)
        }
        else {
            geometries.append(geometry)
        }

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }
    }

    /// Append a GeoJsonGeometry to the receiver.
    ///
    /// - note: `geometry` must be in the same projection as the receiver.
    /// - Parameters:
    ///    - geometry: The geometry to append
    public mutating func appendGeometry(_ geometry: GeoJsonGeometry) {
        guard geometries.count == 0 || projection == geometry.projection else { return }

        geometries.append(geometry)

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }
    }

    /// Remove a GeoJsonGeometry from the receiver.
    ///
    /// - Parameters:
    ///    - index: The index of the geometry to remove
    /// - Returns: The removed geometry, or `nil` if the index is out of bounds
    @discardableResult
    public mutating func removeGeometry(at index: Int) -> GeoJsonGeometry? {
        guard index >= 0, index < geometries.count else { return nil }

        let removedGeometry = geometries.remove(at: index)

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }

        return removedGeometry
    }

    /// Map Geometries in-place.
    ///
    /// - Parameters:
    ///    - transform: The closure to apply to each geometry
    public mutating func mapGeometries(_ transform: (GeoJsonGeometry) -> GeoJsonGeometry) {
        geometries = geometries.map(transform)
    }

    /// Map Geometries in-place, removing *nil* values.
    ///
    /// - Parameters:
    ///    - transform: The closure to apply to each geometry
    public mutating func compactMapGeometries(_ transform: (GeoJsonGeometry) -> GeoJsonGeometry?) {
        geometries = geometries.compactMap(transform)
    }

    /// Filter Geometries in-place.
    ///
    /// - Parameters:
    ///    - isIncluded: The closure to test each geometry
    public mutating func filterGeometries(_ isIncluded: (GeoJsonGeometry) -> Bool) {
        geometries = geometries.filter(isIncluded)
    }


}
