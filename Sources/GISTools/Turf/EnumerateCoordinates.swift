#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension FeatureCollection {

    /// Enumerate all coordinates in the FeatureCollection with feature and location index..
    ///
    /// - Parameter callback: The callback function
    public func enumerateCoordinates(_ callback: (_ featureIndex: Int, _ coordinateIndex: Int, _ coordinate: Coordinate3D) -> Void)  {
        for (featureIndex, feature) in self.features.enumerated() {
            for (coordinateIndex, coordinate) in feature.allCoordinates.enumerated() {
                callback(featureIndex, coordinateIndex, coordinate)
            }
        }
    }

}

extension Feature {

    /// Enumerate all coordinates in the Feature with  location index..
    ///
    /// - Parameter callback: The callback function
    public func enumerateCoordinates(_ callback: (_ coordinateIndex: Int, _ coordinate: Coordinate3D) -> Void)  {
        for (coordinateIndex, coordinate) in self.allCoordinates.enumerated() {
            callback(coordinateIndex, coordinate)
        }
    }

}

extension GeometryCollection {

    /// Enumerate all coordinates in the GeometryCollection with geometry and location index..
    ///
    /// - Parameter callback: The callback function
    public func enumerateCoordinates(_ callback: (_ geometryIndex: Int, _ coordinateIndex: Int, _ coordinate: Coordinate3D) -> Void)  {
        for (geometryIndex, geometry) in self.geometries.enumerated() {
            for (coordinateIndex, coordinate) in geometry.allCoordinates.enumerated() {
                callback(geometryIndex, coordinateIndex, coordinate)
            }
        }
    }

}

extension GeoJsonGeometry {

    /// Enumerate all coordinates in the Geometry with  location index..
    ///
    /// - Parameter callback: The callback function
    public func enumerateCoordinates(_ callback: (_ coordinateIndex: Int, _ coordinate: Coordinate3D) -> Void)  {
        for (coordinateIndex, coordinate) in self.allCoordinates.enumerated() {
            callback(coordinateIndex, coordinate)
        }
    }

}
