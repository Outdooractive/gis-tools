#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension FeatureCollection {

    /// A sentinel key used internally to group features without a matching property value.
    private struct DissolveUnknown: Hashable, Sendable {}

    /// Creates a new FeatureCollection where all (Multi)Polygon features with the same
    /// property value are union'ed together. Features that are not (Multi)Polygon are
    /// removed from the result.
    ///
    /// The property value can be any standard JSON type (`String`, `Int`, `Double`,
    /// `Bool`, etc.) or any `Hashable & Sendable` type.
    ///
    /// - Parameter property: The property name by which features should be grouped
    /// - Parameter removeUnknown: Whether to remove features without the property from the result
    ///
    /// - Returns: A dissolved FeatureCollection.
    public func dissolved(
        by property: String,
        removeUnknown: Bool = false
    ) -> FeatureCollection {
        let unknownSentinel = AnyHashable(DissolveUnknown())

        let dividedFeatures: [AnyHashable: [Feature]] = divideFeatures { feature in
            guard feature.geometry.type.isIn([.polygon, .multiPolygon]) else { return nil }

            if let value = feature.properties[property],
               let hashable = Self.hashableValue(from: value)
            {
                return hashable
            }
            if removeUnknown {
                return nil
            }
            return unknownSentinel
        }

        var result: [Feature] = []
        for (key, features) in dividedFeatures {
            let polygons: [Polygon] = features
                .compactMap({ $0.geometry as? PolygonGeometry })
                .flatMap({ $0.polygons })
            guard let union = Union.unionPolygons(polygons) else { continue }

            let properties: [String: Sendable]
            if key == unknownSentinel {
                properties = [:]
            }
            else if let propertyValue = features.first?.properties[property] {
                properties = [property: propertyValue]
            }
            else {
                properties = [:]
            }
            result.append(Feature(union, properties: properties))
        }

        return FeatureCollection(result)
    }

    // MARK: - Private

    /// Attempt to wrap a `Sendable` property value into an `AnyHashable` key.
    ///
    /// Covers the standard JSON value types: `String`, `Int`, `Double`, `Bool`,
    /// `Float`, and their fixed-width variants.
    private static func hashableValue(from value: Sendable) -> AnyHashable? {
        switch value {
        case let v as String:   return AnyHashable(v)
        case let v as Int:      return AnyHashable(v)
        case let v as Int8:     return AnyHashable(v)
        case let v as Int16:    return AnyHashable(v)
        case let v as Int32:    return AnyHashable(v)
        case let v as Int64:    return AnyHashable(v)
        case let v as UInt:     return AnyHashable(v)
        case let v as UInt8:    return AnyHashable(v)
        case let v as UInt16:   return AnyHashable(v)
        case let v as UInt32:   return AnyHashable(v)
        case let v as UInt64:   return AnyHashable(v)
        case let v as Float:    return AnyHashable(v)
        case let v as Double:   return AnyHashable(v)
        case let v as Bool:     return AnyHashable(v)
        case let v as AnyHashable: return v
        default: return nil
        }
    }

}
