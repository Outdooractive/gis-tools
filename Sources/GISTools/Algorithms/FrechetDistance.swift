#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

/// The distance function used for Fréchet distance calculations.
public enum FrechetDistanceFunction {

    /// Use the eudlidean distance.
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

extension LineString {

    /// Fréchet distance between two geometries.
    ///
    /// - Parameter other: The other geometry of equal type.
    /// - Parameter distanceFunction: The algorithm to use for distance calculations.
    /// - Parameter segmentLength: This value adds intermediate points to the geometry for improved matching, in meters.
    ///
    /// - Returns: The Fréchet distance between the two geometries.
    public func frechetDistance(
        from other: LineString,
        distanceFunction: FrechetDistanceFunction = .haversine,
        segmentLength: CLLocationDistance? = nil
    ) -> Double {
        var firstLine = self
        var secondLine = other.projected(to: projection)

        if let segmentLength {
            firstLine = firstLine.evenlyDivided(segmentLength: segmentLength)
            secondLine = secondLine.evenlyDivided(segmentLength: segmentLength)
        }

        let p = firstLine.allCoordinates
        let q = secondLine.allCoordinates

        var ca: [Double] = Array(repeating: -1.0, count: p.count * q.count)

        func index(_ pI: Int, _ qI: Int) -> Int {
            (pI * q.count) + qI
        }

        for i in 0 ..< p.count {
            for j in 0 ..< q.count {
                let distance = distanceFunction.distance(between: p[i], and: q[j])

                ca[index(i, j)] = if i > 0, j > 0 {
                    max([ca[index(i - 1, j)], ca[index(i - 1, j - 1)], ca[index(i, j - 1)]].min() ?? -1.0, distance)
                }
                else if i > 0, j == 0 {
                    max(ca[index(i - 1, 0)], distance)
                }
                else if i == 0, j > 0 {
                    max(ca[index(0, j - 1)], distance)
                }
                else if i == 0, j == 0 {
                    distance
                }
                else {
                    Double.infinity
                }
            }
        }

        return ca[index(p.count - 1, q.count - 1)]
    }

}
