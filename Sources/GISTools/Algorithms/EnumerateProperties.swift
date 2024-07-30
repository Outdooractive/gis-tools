#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension FeatureCollection {

    /// Enumerate over all Feature properties in the FeatureCollection.
    ///
    /// - Parameter callback: The callback function, called for each Feature with Feature index and properties
    public func enumerateProperties(_ callback: (_ featureIndex: Int, _ properties: [String: Sendable]) -> Void)  {
        for (featureIndex, feature) in features.enumerated() {
            callback(featureIndex, feature.properties)
        }
    }

    /// Creates a summary over all properties in the FeatureCollection.
    ///
    /// - Returns: A dictionary with all the keys found in all properties of the FeatureCollection,
    ///            and the values are the distinct values for each key.
    ///
    /// - Note: All valid JSON types are `Hashable`.
    public func propertiesSummary() -> [String: [AnyHashable]] {
        var keyValuePairs: [(String, Set<AnyHashable>)] = []

        for feature in features {
            for (key, value) in feature.properties {
                if let hashable = value as? AnyHashable {
                    keyValuePairs.append((key, Set([hashable])))
                }
            }
        }

        return Dictionary(keyValuePairs, uniquingKeysWith: { $0.union($1) })
            .mapValues(\.asArray)
    }

}
