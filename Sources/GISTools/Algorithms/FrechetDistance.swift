#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// Distance functions for ```LineString.frechetDistance```.
public enum FrechetDistanceFunction {
    /// Use the eudlidean distance (very fast, not very accurate).
    case euclidean
    /// Use the Haversine formula to account for global curvature.
    case haversine
    /// Use a rhumb line.
    case rhumbLine
    /// Use a custom distance function.
    case other((Coordinate3D, Coordinate3D) -> Double)
}

extension LineString {

    /// Fréchet  distance between to geometries.
    ///
    /// - Parameters:
    ///    - from: The other geometry of equal type
    ///    - distanceFunction: The algorithm to use for distance calculations
    ///    - tolerance: Affects the amount of simplification (in meters)
    ///
    /// - Returns: The frechet distance between the to geometries
    public func frechetDistance(
        from other: LineString,
        distanceFunction: FrechetDistanceFunction = .haversine,
        tolerance: CLLocationDistance? = nil)
        -> Double
    {
        let other = other.projected(to: projection)

        return 0.0
    }

}
