import Foundation

/// A GeoJSON `FeatureCollection`.
public struct FeatureCollection:
    GeoJson,
    EmptyCreatable
{

    public var type: GeoJsonType {
        .featureCollection
    }

    public var projection: Projection {
        features.first?.projection ?? .noSRID
    }

    /// The FeatureCollection's Feature objects.
    public private(set) var features: [Feature]

    public var allCoordinates: [Coordinate3D] {
        features.flatMap(\.allCoordinates)
    }

    public var boundingBox: BoundingBox?

    public var foreignMembers: [String: Sendable] = [:]

    public init() {
        self.features = []
    }

    /// Initialize a FeatureCollection with one Feature.
    public init(_ feature: Feature, calculateBoundingBox: Bool = false) {
        self.init([feature], calculateBoundingBox: calculateBoundingBox)
    }

    /// Initialize a FeatureCollection with some Features.
    public init(_ features: [Feature], calculateBoundingBox: Bool = false) {
        self.features = features

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Initialize a FeatureCollection with some geometry objects.
    public init(_ geometries: [GeoJsonGeometry], calculateBoundingBox: Bool = false) {
        self.features = geometries.compactMap { Feature($0) }

        if calculateBoundingBox {
            self.updateBoundingBox()
        }
    }

    /// Normalize any GeoJSON object into a FeatureCollection.
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

    public init?(json: Any?) {
        self.init(json: json, calculateBoundingBox: false)
    }

    /// This initializer is slightly different to the other initializers
    /// because it will accept any valid GeoJSON object and normalize
    /// it into a FeatureCollection.
    ///
    /// - important: The source is expected to be in EPSG:4326.
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

    @discardableResult
    public mutating func updateBoundingBox(onlyIfNecessary ifNecessary: Bool = true) -> BoundingBox? {
        mapFeatures { feature in
            var feature = feature
            feature.updateBoundingBox(onlyIfNecessary: ifNecessary)
            return feature
        }

        if boundingBox != nil && ifNecessary { return boundingBox }

        boundingBox = calculateBoundingBox()
        return boundingBox
    }

    public func calculateBoundingBox() -> BoundingBox? {
        let featureBoundingBoxes: [BoundingBox] = features.compactMap({ $0.boundingBox ?? $0.calculateBoundingBox() })
        guard !featureBoundingBoxes.isEmpty else { return nil}

        return featureBoundingBoxes.reduce(featureBoundingBoxes[0]) { (result, boundingBox) -> BoundingBox in
            return result + boundingBox
        }
    }

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

    public static func ==(
        lhs: FeatureCollection,
        rhs: FeatureCollection)
        -> Bool
    {
        return lhs.projection == rhs.projection
            && lhs.features == rhs.features
    }

}

// MARK: - Projection

extension FeatureCollection {

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
    public mutating func insertFeature(_ feature: Feature, atIndex index: Int) {
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
    public mutating func appendFeature(_ feature: Feature) {
        guard features.count == 0 || projection == feature.projection else { return }

        features.append(feature)

        if boundingBox != nil {
            updateBoundingBox(onlyIfNecessary: false)
        }
    }

    /// Remove a Feature from the receiver.
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
    public mutating func mapFeatures(_ transform: (Feature) -> Feature) {
        features = features.map(transform)
    }

    /// Map Features in-place, removing *nil* values.
    public mutating func compactMapFeatures(_ transform: (Feature) -> Feature?) {
        features = features.compactMap(transform)
    }

    /// Filter Features in-place.
    public mutating func filterFeatures(_ isIncluded: (Feature) -> Bool) {
        features = features.filter(isIncluded)
    }

}
