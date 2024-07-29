#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension FeatureCollection {

    /// Enumerate all properties in the FeatureCollection with feature index..
    ///
    /// - Parameter callback: The callback function
    public func enumerateProperties(_ callback: (_ featureIndex: Int, _ properties: [String: Sendable]) -> Void)  {
        for (featureIndex, feature) in features.enumerated() {
            callback(featureIndex, feature.properties)
        }
    }

}
