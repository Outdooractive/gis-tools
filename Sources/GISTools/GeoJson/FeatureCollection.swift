import Foundation

/// A GeoJSON `FeatureCollection`.
public struct FeatureCollection:
    GeoJson,
    EmptyCreatable
{

    /// The GeoJSON object type.
    public var type: GeoJsonType {
        .featureCollection
    }

    /// The receiver's projection.
    public var projection: Projection {
        features.first?.projection ?? .noSRID
    }

    /// The FeatureCollection's Feature objects.
    public private(set) var features: [Feature]

    /// All of the receiver's coordinates.
    public var allCoordinates: [Coordinate3D] {
        features.flatMap(\.allCoordinates)
    }

    /// The receiver's bounding box.
    public var boundingBox: BoundingBox?

    /// Foreign members of the receiver.
    public var foreignMembers: [String: Sendable] = [:]

    /// Create an empty FeatureCollection.
    public init() {
        self.features = []
    }

    /// Initialize a FeatureCollection with one Feature.
    ///
    /// - Parameters:
    ///    - feature: The feature to include
    ///    - calculateBoundingBox: When true, calculate the bounding box from the feature
    public init(_ feature: Feature, calculateBoundingBox: Bool = false) {
        self.init([feature], calculateBoundingBox: calculateBoundingBox)
    }

    /// Initialize a FeatureCollection with some Features.
    ///
    /// - Parameters:
    ///    - features: The features to include
    ///    - calculateBoundingBox: When true, calculate the bounding box from the features
    public init(_ features: [Feature], calculateBoundingBox: Bool = false) {
        self.features = features

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Initialize a FeatureCollection with some geometry objects.
    ///
    /// - Parameters:
    ///    - geometries: The geometry objects to create features from
    ///    - calculateBoundingBox: When true, calculate the bounding box from the geometries
    public init(_ geometries: [GeoJsonGeometry], calculateBoundingBox: Bool = false) {
        self.features = geometries.compactMap { Feature($0) }

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Normalize any GeoJSON object into a FeatureCollection.
    ///
    /// - Parameters:
    ///    - geoJson: Any GeoJSON object (FeatureCollection, Feature, or geometry)
    ///    - calculateBoundingBox: When true, calculate the bounding box from the features
    /// - Returns: A feature collection, or `nil` if the input is not a valid GeoJSON object
    public init?(_ geoJson: GeoJson?, calculateBoundingBox: Bool = false) {
        guard let geoJson = geoJson else { return nil }

        switch geoJson {
        case let featureCollection as FeatureCollection:
            self.features = featureCollection.features
            self.boundingBox = featureCollection.boundingBox
            self.foreignMembers = featureCollection.foreignMembers

        case let feature as Feature:
            self.features = [feature]
            self.boundingBox = feature.boundingBox

        case let geometry as GeoJsonGeometry:
            self.features = [Feature(geometry)]
            self.boundingBox = geometry.boundingBox

        default:
            return nil
        }

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Try to initialize a FeatureCollection from any JSON object.
    ///
    /// - Parameters:
    ///    - json: A GeoJSON object
    /// - Returns: A feature collection, or `nil` if the input is invalid
    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    /// This initializer is slightly different to the other initializers
    /// because it will accept any valid GeoJSON object and normalize
    /// it into a FeatureCollection.
    ///
    /// - important: The source is expected to be in EPSG:4326.
    /// - Parameters:
    ///    - json: A GeoJSON object
    ///    - calculateBoundingBox: When true, calculate the bounding box from the features
    /// - Returns: A feature collection, or `nil` if the input is invalid
    public init?(json: Any?, calculateBoundingBox: Bool = false) {
        guard let geoJson: GeoJson = FeatureCollection.tryCreate(json: json) else { return nil }
        self.init(geoJson, calculateBoundingBox: calculateBoundingBox)
    }

    // To prevent an infinite recursion.
    init?(geoJson: [String: Sendable], calculateBoundingBox: Bool = false) {
        guard FeatureCollection.isValid(geoJson: geoJson),
              let features: [Feature] = FeatureCollection.tryCreate(json: geoJson["features"])
        else { return nil }

        self.features = features
        self.boundingBox = FeatureCollection.tryCreate(json: geoJson["bbox"])

        if calculateBoundingBox {
            self.updateBoundingBox()
        }

        if geoJson.count > 2 {
            var foreignMembers = geoJson
            foreignMembers.removeValue(forKey: "type")
            foreignMembers.removeValue(forKey: "features")
            foreignMembers.removeValue(forKey: "bbox")
            self.foreignMembers = foreignMembers
        }
    }

    /// The receiver as a JSON object.
    ///
    /// - Returns: A GeoJSON dictionary
    public var asJson: [String: Sendable] {
        var result: [String: Sendable] = [
            "type": GeoJsonType.featureCollection.rawValue,
            "features": features.map { $0.asJson }
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

extension FeatureCollection {

    /// Update the bounding box, optionally only if it hasn't been calculated yet.
    ///
    /// - Parameter onlyIfNecessary: Only update if the receiver doesn't already have one
    /// - Returns: The updated bounding box
    @discardableResult
    public mutating func updateBoundingBox(
        onlyIfNecessary ifNecessary: Bool = true
    ) -> BoundingBox? {
        mapFeatures { feature in
            var feature = feature
            feature.updateBoundingBox(onlyIfNecessary: ifNecessary)
            return feature
        }

        if boundingBox != nil && ifNecessary { return boundingBox }

        boundingBox = calculateBoundingBox()
        return boundingBox
    }

    /// Calculate the bounding box from the receiver's features.
    ///
    /// - Returns: The calculated bounding box, or `nil` if there are no features
    public func calculateBoundingBox() -> BoundingBox? {
        let featureBoundingBoxes: [BoundingBox] = features.compactMap({ $0.boundingBox ?? $0.calculateBoundingBox() })
        guard !featureBoundingBoxes.isEmpty else { return nil}

        return featureBoundingBoxes.reduce(featureBoundingBoxes[0]) { (result, boundingBox) -> BoundingBox in
            return result + boundingBox
        }
    }

    /// Check if the receiver intersects with the given bounding box.
    ///
    /// - Parameter otherBoundingBox: The bounding box to check
    /// - Returns: `true` if the bounding boxes intersect
    public func intersects(_ otherBoundingBox: BoundingBox) -> Bool {
        if let boundingBox = boundingBox ?? calculateBoundingBox(),
           !boundingBox.intersects(otherBoundingBox)
        {
            return false
        }

        return features.contains { $0.geometry.intersects(otherBoundingBox) }
    }

}

extension FeatureCollection: Equatable {

    /// Two feature collections are equal when their projections and features are equal.
    public static func ==(
        lhs: FeatureCollection,
        rhs: FeatureCollection
    ) -> Bool {
        return lhs.projection == rhs.projection
            && lhs.features == rhs.features
    }

}

// MARK: - Projection

extension FeatureCollection {

    /// Reproject the receiver.
    ///
    /// - Parameter newProjection: The target projection
    /// - Returns: A new feature collection in the requested projection
    public func projected(to newProjection: Projection) -> FeatureCollection {
        guard newProjection != projection else { return self }

        var featureCollection = FeatureCollection(
            features.map({ $0.projected(to: newProjection) }),
            calculateBoundingBox: (boundingBox != nil))
        featureCollection.foreignMembers = foreignMembers
        return featureCollection
    }

}

// MARK: - Features

extension FeatureCollection {

    /// Insert a Feature into the receiver.
    ///
    /// - note: `feature` must be in the same projection as the receiver.
    /// - Parameters:
    ///    - feature: The feature to insert
    ///    - index: The index at which to insert
    public mutating func insertFeature(
        _ feature: Feature,
        atIndex index: Int
    ) {
        guard features.count == 0 || projection == feature.projection else { return }

        if index < features.count {
            features.insert(feature, at: index)
        }
        else {
            features.append(feature)
        }

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }
    }

    /// Append a Feature to the receiver.
    ///
    /// - note: `feature` must be in the same projection as the receiver.
    /// - Parameters:
    ///    - feature: The feature to append
    public mutating func appendFeature(_ feature: Feature) {
        guard features.count == 0 || projection == feature.projection else { return }

        features.append(feature)

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }
    }

    /// Remove a Feature from the receiver.
    ///
    /// - Parameters:
    ///    - index: The index of the feature to remove
    /// - Returns: The removed feature, or `nil` if the index is out of bounds
    @discardableResult
    public mutating func removeFeature(at index: Int) -> Feature? {
        guard index >= 0, index < features.count else { return nil }

        let removedFeature = features.remove(at: index)

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }

        return removedFeature
    }

    /// Map Features in-place.
    ///
    /// - Parameters:
    ///    - transform: The closure to apply to each feature
    public mutating func mapFeatures(_ transform: (Feature) -> Feature) {
        features = features.map(transform)
    }

    /// Map Features in-place, removing *nil* values.
    ///
    /// - Parameters:
    ///    - transform: The closure to apply to each feature
    public mutating func compactMapFeatures(_ transform: (Feature) -> Feature?) {
        features = features.compactMap(transform)
    }

    /// Filter Features in-place.
    ///
    /// - Parameters:
    ///    - isIncluded: The closure to test each feature
    public mutating func filterFeatures(_ isIncluded: (Feature) -> Bool) {
        features = features.filter(isIncluded)
    }

    /// Divide Features by a property value.
    ///
    /// Features where the `key` function returns nil will be discarded.
    /// - Parameters:
    ///    - key: A closure that returns a grouping key for each feature
    /// - Returns: A dictionary mapping keys to arrays of features
    public func divideFeatures<T: Hashable>(by key: (Feature) -> T?) -> [T: [Feature]] {
        return features.reduce(into: [:]) { partialResult, feature in
            guard let key = key(feature) else { return }

            partialResult[key, default: []].append(feature)
        }
    }

}
