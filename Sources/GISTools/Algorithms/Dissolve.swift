#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension FeatureCollection {

    private static let unknownValuePlaceholder: String = UUID().uuidString

    /// Creates a new FeatureCollection where all (Multi)Polygon features with the same property value
    /// are union'ed together.
    ///
    /// - Parameters:
    ///    - by: The property name
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
            result.append(Feature(union, properties: [property: key]))
        }

        return FeatureCollection(result)
    }

}
