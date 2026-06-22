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

        // Antimeridian normalization only applies to EPSG:4326 where longitude is
        // in degrees. For other projections (3857, 4978, noSRID), longitude values
        // are in projection units and should not be wrapped.
        let spansAntimeridian: Bool
        if projection == .epsg4326 {
            let minLon = allCoordinates.map(\.longitude).min() ?? 0
            let maxLon = allCoordinates.map(\.longitude).max() ?? 0
            spansAntimeridian = (maxLon - minLon) > 180.0
        }
        else {
            spansAntimeridian = false
        }

        var sumX: Double = 0.0
        var sumY: Double = 0.0

        for coordinate in allCoordinates {
            let x = spansAntimeridian && coordinate.longitude < 0
                ? coordinate.longitude + 360.0
                : coordinate.longitude
            sumX += x
            sumY += coordinate.latitude
        }

        var resultX = sumX / Double(allCoordinates.count)
        if spansAntimeridian && resultX > 180.0 {
            resultX -= 360.0
        }

        return Point(
            Coordinate3D(
                x: resultX,
                y: sumY / Double(allCoordinates.count),
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

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-center-median

extension FeatureCollection {

    /// Takes a ``FeatureCollection`` and calculates the median center using the
    /// Weiszfeld algorithm. The median center is the point that requires the
    /// least total travel distance from all points in the dataset.
    ///
    /// - Parameters:
    ///   - weightAttribute: The property name used to weight the center.
    ///   - tolerance: The convergence threshold in meters. Internally converted to
    ///     CRS units (degrees for ``Projection/epsg4326``, meters for ``Projection/epsg3857``).
    ///     Default `1.0`.
    ///   - counter: Maximum number of iterations (default: `10`).
    ///
    /// - Returns: The median center, or `nil` if the collection is empty.
    public func centerMedian(
        weightAttribute: String? = nil,
        tolerance: CLLocationDistance = 1.0,
        counter: Int = 10
    ) -> Point? {
        guard let meanCenter = centerMean(weightAttribute: weightAttribute) else {
            return nil
        }

        var centroids: [(coordinate: Coordinate3D, weight: Double)] = []
        for feature in features {
            guard let centroid = feature.centroid else { continue }
            var weight: Double = 1.0
            if let weightAttribute {
                weight = feature.property(for: weightAttribute) ?? 1.0
            }
            if weight > 0 {
                centroids.append((centroid.coordinate, weight))
            }
        }

        guard centroids.isNotEmpty else { return nil }

        let minLon = centroids.map(\.coordinate.longitude).min() ?? 0.0
        let maxLon = centroids.map(\.coordinate.longitude).max() ?? 0.0
        let spansAntimeridian = (maxLon - minLon) > 180.0

        if spansAntimeridian {
            centroids = centroids.map { (coordinate, weight) in
                let adjustedLon = coordinate.longitude < 0
                    ? coordinate.longitude + 360.0
                    : coordinate.longitude
                let adjusted = Coordinate3D(
                    x: adjustedLon,
                    y: coordinate.latitude,
                    projection: projection)
                return (adjusted, weight)
            }
        }

        let initialLon = meanCenter.coordinate.longitude
        let initialLat = meanCenter.coordinate.latitude
        let initialCandidate = Coordinate3D(
            x: spansAntimeridian && initialLon < 0 ? initialLon + 360.0 : initialLon,
            y: initialLat,
            projection: projection)

        // Convert meter tolerance to CRS units
        let crsTolerance: Double = {
            switch projection {
            case .epsg4326, .epsg4978:
                return tolerance / 111_325.0
            case .epsg3857, .noSRID:
                return tolerance
            }
        }()

        guard var result = findMedian(
            candidate: initialCandidate,
            previousCandidate: Coordinate3D(
                x: 0.0,
                y: 0.0,
                projection: projection),
            centroids: centroids,
            tolerance: crsTolerance,
            counter: counter) else { return nil }

        if spansAntimeridian && result.coordinate.longitude > 180.0 {
            result = Point(Coordinate3D(
                x: result.coordinate.longitude - 360.0,
                y: result.coordinate.latitude,
                projection: projection))
        }

        return result
    }

    /// - Parameter tolerance: Convergence threshold in CRS units (already converted from meters).
    private func findMedian(
        candidate: Coordinate3D,
        previousCandidate: Coordinate3D,
        centroids: [(coordinate: Coordinate3D, weight: Double)],
        tolerance: Double,
        counter: Int
    ) -> Point? {
        var sumX: Double = 0.0
        var sumY: Double = 0.0
        var sumK: Double = 0.0

        for (coordinate, weight) in centroids {
            var distance = coordinate.distance(from: candidate)
            if distance == 0 {
                distance = 1.0
            }
            let k = weight / distance
            sumX += coordinate.longitude * k
            sumY += coordinate.latitude * k
            sumK += k
        }

        guard sumK > 0.0 else { return nil }

        let newCandidate = Coordinate3D(
            x: sumX / sumK,
            y: sumY / sumK,
            projection: projection)

        if counter == 0 || centroids.count == 1 {
            return Point(newCandidate)
        }

        let deltaX = abs(newCandidate.longitude - previousCandidate.longitude)
        let deltaY = abs(newCandidate.latitude - previousCandidate.latitude)
        if deltaX < tolerance && deltaY < tolerance {
            return Point(newCandidate)
        }

        return findMedian(
            candidate: newCandidate,
            previousCandidate: candidate,
            centroids: centroids,
            tolerance: tolerance,
            counter: counter - 1)
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
