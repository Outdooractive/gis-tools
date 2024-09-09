#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-center

extension GeoJson {

    /// Returns the absolute center point of the receiver.
    public var center: Point? {
        guard let boundingBox = self.boundingBox ?? calculateBoundingBox() else { return nil }
        return Point(boundingBox.center)
    }

}

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-centroid

extension GeoJson {

    /// Calculates the centroid using the mean of all vertices. This lessens the effect
    /// of small islands and artifacts when calculating the centroid of a set of polygons.
    public var centroid: Point? {
        let allCoordinates = self.allCoordinates

        guard allCoordinates.isNotEmpty else { return nil }

        if allCoordinates.count == 1 {
            return Point(allCoordinates[0])
        }

        var sumLongitude: Double = 0.0
        var sumLatitude: Double = 0.0

        for coordinate in allCoordinates {
            sumLongitude += coordinate.longitude
            sumLatitude += coordinate.latitude
        }

        return Point(
            Coordinate3D(
                x: sumLongitude / Double(allCoordinates.count),
                y: sumLatitude / Double(allCoordinates.count),
                projection: projection))
    }

}

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-center-mean

extension FeatureCollection {

    /// Returns the mean center of the receiver. Can be weighted.
    ///
    /// - Parameter weightAttribute: The property name used to weight the center
    public func centerMean(weightAttribute: String? = nil) -> Point? {
        var sumLongitude: Double = 0.0
        var sumLatitude: Double = 0.0
        var sumWeights: Double = 0.0

        for feature in features {
            var weight: Double = 1.0
            if let weightAttribute = weightAttribute {
                weight = feature.property(for: weightAttribute) ?? 1.0
            }

            guard weight > 0.0 else { continue }

            for coordinate in feature.allCoordinates {
                sumLongitude += coordinate.longitude * weight
                sumLatitude += coordinate.latitude * weight
                sumWeights += weight
            }
        }

        guard sumWeights > 0.0 else { return nil }

        return Point(
            Coordinate3D(
                x: sumLongitude / sumWeights,
                y: sumLatitude / sumWeights,
                projection: projection))
    }

}
