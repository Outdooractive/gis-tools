#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// The distance function used for Hausdorff distance calculations.
public enum HausdorffDistanceFunction {

    /// Use the euclidean distance.
    case euclidean
    /// Use the Haversine formula to account for global curvature.
    case haversine
    /// Use a rhumb line.
    case rhumbLine
    /// Use a custom distance function.
    case other((Coordinate3D, Coordinate3D) -> CLLocationDistance)

    /// Calculates the distance between two coordinates using the selected method.
    ///
    /// - Parameter first: The first coordinate
    /// - Parameter second: The second coordinate
    ///
    /// - Returns: The distance between the two coordinates.
    public func distance(
        between first: Coordinate3D,
        and second: Coordinate3D
    ) -> CLLocationDistance {
        switch self {
        case .euclidean:
            sqrt(pow(first.longitude - second.longitude, 2.0) + pow(first.latitude - second.latitude, 2.0))
        case .haversine:
            first.distance(from: second)
        case .rhumbLine:
            first.rhumbDistance(from: second)
        case let .other(distanceFunction):
            distanceFunction(first, second)
        }
    }

}

extension GeoJson {

    /// Computes the Hausdorff distance between two geometries.
    ///
    /// The Hausdorff distance measures how far two subsets of a metric space
    /// are from each other. Unlike ``frechetDistance(from:distanceFunction:segmentLength:)``,
    /// Hausdorff only considers the maximum distance from any point in one set
    /// to the nearest point in the other set, without accounting for point ordering.
    ///
    /// - Parameter other: The other geometry.
    /// - Parameter distanceFunction: The algorithm to use for distance calculations (default `.haversine`).
    /// - Returns: The Hausdorff distance between the two geometries.
    public func hausdorffDistance(
        from other: GeoJson,
        distanceFunction: HausdorffDistanceFunction = .haversine
    ) -> Double {
        let pointsA = allCoordinates
        let pointsB = other.allCoordinates

        guard pointsA.isNotEmpty, pointsB.isNotEmpty else { return 0.0 }

        // Hausdorff distance: max(min(distance(a, b))) for both directions.
        func directedHausdorff(
            from a: [Coordinate3D],
            to b: [Coordinate3D]
        ) -> Double {
            var maxMinDist = 0.0
            for coordA in a {
                var minDist = Double.greatestFiniteMagnitude
                for coordB in b {
                    let dist = distanceFunction.distance(between: coordA, and: coordB)
                    if dist < minDist {
                        minDist = dist
                        if minDist == 0.0 { break }
                    }
                }
                if minDist > maxMinDist {
                    maxMinDist = minDist
                }
            }
            return maxMinDist
        }

        let dAB = directedHausdorff(from: pointsA, to: pointsB)
        let dBA = directedHausdorff(from: pointsB, to: pointsA)

        return max(dAB, dBA)
    }

}
