#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension FeatureCollection {

    private static let unknownValuePlaceholder: String = UUID().uuidString

    /// Creates a new FeatureCollection where all (Multi)Polygon features with the same property value
    /// are union'ed together. Features that are not (Multi)Polygon are removed from the result.
    ///
    /// This currently works only for properties with a String value.
    ///
    /// - Parameters:
    ///    - property: The `property` name with which the Features should be divided
    ///    - removeUnknown: Whether to remove features without the property from the result
    public func dissolved(
        by property: String,
        removeUnknown: Bool = false
    ) -> FeatureCollection {
        let dividedFeatures = divideFeatures { feature in
            guard feature.type.isIn([.polygon, .multiPolygon]) else { return nil }

            let value: String? = feature.property(for: property)
            if value == nil, removeUnknown {
                return nil
            }
            return value ?? Self.unknownValuePlaceholder // Improve this
        }

        var result: [Feature] = []
        for (key, features) in dividedFeatures {
            let polygons: [PolygonGeometry] = features.compactMap({ $0.geometry as? PolygonGeometry })
            let union = UnionHelper.union(polygons: polygons)
            let properties: [String: Sendable] = key == Self.unknownValuePlaceholder
                ? [:]
                : [property: key]
            result.append(Feature(union, properties: properties))
        }

        return FeatureCollection(result)
    }

}
