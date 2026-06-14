#if canImport(CoreLocation)
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
    ///
    /// - Returns: The mean center, or `nil`.
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

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-center-of-mass

extension GeoJson {

    /// Returns the center of mass of the receiver.
    ///
    /// Uses the centroid of polygon formula (signed area method) for polygons,
    /// and falls back to the convex hull's center of mass for other geometries.
    public var centerOfMass: Point? {
        if let feature = self as? Feature {
            return feature.geometry.centerOfMass
        }

        switch type {
        case .point:
            return (self as? Point).map { Point($0.coordinate) }

        case .polygon:
            return polygonCenterOfMass(allCoordinates: allCoordinates, projection: projection)

        default:
            if let hull = convexHull() {
                return hull.centerOfMass
            }
            return centroid
        }
    }

    private func polygonCenterOfMass(
        allCoordinates coords: [Coordinate3D],
        projection: Projection
    ) -> Point? {
        guard coords.isNotEmpty else { return nil }

        if coords.count == 1 {
            return Point(coords[0])
        }

        // Compute centroid for neutralization (to reduce rounding errors)
        var sumLat: Double = 0.0
        var sumLon: Double = 0.0
        for coord in coords {
            sumLat += coord.latitude
            sumLon += coord.longitude
        }
        let centerLat = sumLat / Double(coords.count)
        let centerLon = sumLon / Double(coords.count)

        // Neutralized signed area computation
        var sx: Double = 0.0
        var sy: Double = 0.0
        var sArea: Double = 0.0

        for i in 0..<(coords.count - 1) {
            let xi = coords[i].longitude - centerLon
            let yi = coords[i].latitude - centerLat
            let xj = coords[i + 1].longitude - centerLon
            let yj = coords[i + 1].latitude - centerLat

            let a = xi * yj - xj * yi
            sArea += a
            sx += (xi + xj) * a
            sy += (yi + yj) * a
        }

        // Shape has no area: fallback on centroid
        if sArea == 0.0 {
            return Point(Coordinate3D(
                x: centerLon,
                y: centerLat,
                projection: projection))
        }

        let area = sArea * 0.5
        let areaFactor = 1.0 / (6.0 * area)

        return Point(Coordinate3D(
            x: centerLon + areaFactor * sx,
            y: centerLat + areaFactor * sy,
            projection: projection))
    }

}
