#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-center

extension GeoJson {

    /// Returns the absolute center point of the receiver.
    ///
    /// When all coordinates have an ``altitude`` value, the result carries
    /// the midpoint altitude of the bounding box corners.
    public var center: Point? {
        guard let boundingBox = boundingBox ?? calculateBoundingBox() else { return nil }

        return Point(boundingBox.center)
    }

}

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-centroid

extension GeoJson {

    /// Calculates the centroid using the mean of all vertices. This lessens the effect
    /// of small islands and artifacts when calculating the centroid of a set of polygons.
    ///
    /// When all coordinates have an ``altitude`` value, the result carries the
    /// arithmetic mean of all altitudes.
    public var centroid: Point? {
        let allCoordinates = centroidCoordinates

        guard allCoordinates.isNotEmpty else { return nil }

        if allCoordinates.count == 1 {
            return Point(allCoordinates[0])
        }

        let hasAltitude = allCoordinates.allSatisfy({ $0.altitude != nil })

        // Antimeridian normalization only applies to EPSG:4326 where longitude is
        // in degrees. For other projections (3857, 4978, noSRID), longitude values
        // are in projection units and should not be wrapped.
        let spansAntimeridian: Bool
        if projection.isGeographic {
            let minLon = allCoordinates.map(\.longitude).min() ?? 0
            let maxLon = allCoordinates.map(\.longitude).max() ?? 0
            spansAntimeridian = (maxLon - minLon) > 180.0
        }
        else {
            spansAntimeridian = false
        }

        var sumX = 0.0
        var sumY = 0.0
        var sumZ = 0.0
        let n = allCoordinates.count - (allCoordinates.first == allCoordinates.last ? 1 : 0)

        for i in 0 ..< n {
            let coordinate = allCoordinates[i]
            let x = spansAntimeridian && coordinate.longitude < 0
                ? coordinate.longitude + 360.0
                : coordinate.longitude
            sumX += x
            sumY += coordinate.latitude
            if hasAltitude {
                sumZ += coordinate.altitude ?? 0.0
            }
        }

        var resultX = sumX / Double(n)
        if spansAntimeridian, resultX > 180.0 {
            resultX -= 360.0
        }

        return Point(
            Coordinate3D(
                x: resultX,
                y: sumY / Double(n),
                z: hasAltitude ? sumZ / Double(n) : nil,
                projection: projection))
    }

}

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-center-mean

extension FeatureCollection {

    /// Returns the mean center of the receiver. Can be weighted.
    ///
    /// When all coordinates have an ``altitude`` value, the result carries the
    /// weighted mean of all altitudes.
    ///
    /// - Parameter weightAttribute: The property name used to weight the center
    ///
    /// - Returns: The mean center, or `nil`.
    public func centerMean(weightAttribute: String? = nil) -> Point? {
        var sumLongitude = 0.0
        var sumLatitude = 0.0
        var sumAltitude = 0.0
        var sumWeights = 0.0
        var hasAltitude = true

        let allCoordinates = features.flatMap(\.allCoordinates)
        let minLongitude = allCoordinates.map(\.longitude).min() ?? 0.0
        let maxLongitude = allCoordinates.map(\.longitude).max() ?? 0.0
        let spansAntimeridian = projection.isGeographic
            && (maxLongitude - minLongitude) > 180.0

        for feature in features {
            var weight = 1.0
            if let weightAttribute = weightAttribute {
                weight = feature.property(for: weightAttribute) ?? 1.0
            }

            guard weight > 0.0 else { continue }

            for coordinate in feature.allCoordinates {
                if coordinate.altitude == nil {
                    hasAltitude = false
                }
                let longitude = spansAntimeridian && coordinate.longitude < 0
                    ? coordinate.longitude + 360.0
                    : coordinate.longitude
                sumLongitude += longitude * weight
                sumLatitude += coordinate.latitude * weight
                if hasAltitude, let alt = coordinate.altitude {
                    sumAltitude += alt * weight
                }
                sumWeights += weight
            }
        }

        guard sumWeights > 0.0 else { return nil }

        var longitude = sumLongitude / sumWeights
        if spansAntimeridian, longitude > 180.0 {
            longitude -= 360.0
        }

        return Point(
            Coordinate3D(
                x: longitude,
                y: sumLatitude / sumWeights,
                z: hasAltitude ? sumAltitude / sumWeights : nil,
                projection: projection))
    }

}

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-center-median

extension FeatureCollection {

    /// Takes a ``FeatureCollection`` and calculates the median center using the
    /// Weiszfeld algorithm. The median center is the point that requires the
    /// least total travel distance from all points in the dataset.
    ///
    /// When all coordinates have an ``altitude`` value, the result carries the
    /// median altitude computed with the same Weiszfeld iteration.
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
        var hasAltitude = true
        for feature in features {
            guard let centroid = feature.centroid else { continue }

            var weight = 1.0
            if let weightAttribute {
                weight = feature.property(for: weightAttribute) ?? 1.0
            }
            if weight > 0 {
                if centroid.coordinate.altitude == nil {
                    hasAltitude = false
                }
                centroids.append((centroid.coordinate, weight))
            }
        }

        guard centroids.isNotEmpty else { return nil }

        let minLon = centroids.map(\.coordinate.longitude).min() ?? 0.0
        let maxLon = centroids.map(\.coordinate.longitude).max() ?? 0.0
        let spansAntimeridian = projection.isGeographic
            && (maxLon - minLon) > 180.0

        if spansAntimeridian {
            centroids = centroids.map { coordinate, weight in
                let adjustedLon = coordinate.longitude < 0
                    ? coordinate.longitude + 360.0
                    : coordinate.longitude
                let adjusted = Coordinate3D(
                    x: adjustedLon,
                    y: coordinate.latitude,
                    z: coordinate.altitude,
                    m: coordinate.m,
                    projection: projection)
                return (adjusted, weight)
            }
        }

        let initialLon = meanCenter.coordinate.longitude
        let initialLat = meanCenter.coordinate.latitude
        let initialCandidate = Coordinate3D(
            x: spansAntimeridian && initialLon < 0 ? initialLon + 360.0 : initialLon,
            y: initialLat,
            z: meanCenter.coordinate.altitude,
            projection: projection)

        // Convert meter tolerance to CRS units
        let crsTolerance: Double = projection.crsLength(fromMeters: tolerance)

        guard var result = findMedian(
            candidate: initialCandidate,
            previousCandidate: Coordinate3D(
                x: 0.0,
                y: 0.0,
                projection: projection),
            centroids: centroids,
            tolerance: crsTolerance,
            counter: counter,
            hasAltitude: hasAltitude)
        else { return nil }

        if spansAntimeridian, result.coordinate.longitude > 180.0 {
            result = Point(Coordinate3D(
                x: result.coordinate.longitude - 360.0,
                y: result.coordinate.latitude,
                z: result.coordinate.altitude,
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
        counter: Int,
        hasAltitude: Bool
    ) -> Point? {
        var sumX = 0.0
        var sumY = 0.0
        var sumZ = 0.0
        var sumK = 0.0

        for (coordinate, weight) in centroids {
            var distance = coordinate.distance(from: candidate)
            if distance == 0 {
                distance = 1.0
            }
            let k = weight / distance
            sumX += coordinate.longitude * k
            sumY += coordinate.latitude * k
            if hasAltitude {
                sumZ += (coordinate.altitude ?? 0.0) * k
            }
            sumK += k
        }

        guard sumK > 0.0 else { return nil }

        let newCandidate = Coordinate3D(
            x: sumX / sumK,
            y: sumY / sumK,
            z: hasAltitude ? sumZ / sumK : nil,
            projection: projection)

        if counter == 0 || centroids.count == 1 {
            return Point(newCandidate)
        }

        let deltaX = abs(newCandidate.longitude - previousCandidate.longitude)
        let deltaY = abs(newCandidate.latitude - previousCandidate.latitude)
        if deltaX < tolerance, deltaY < tolerance {
            return Point(newCandidate)
        }

        return findMedian(
            candidate: newCandidate,
            previousCandidate: candidate,
            centroids: centroids,
            tolerance: tolerance,
            counter: counter - 1,
            hasAltitude: hasAltitude)
    }

}

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-center-of-mass

extension GeoJson {

    /// Returns the center of mass of the receiver.
    ///
    /// Uses the centroid of polygon formula (signed area method) for polygons,
    /// and falls back to the convex hull's center of mass for other geometries.
    ///
    /// When all coordinates have an ``altitude`` value, the result carries the
    /// signed-area-weighted mean of all altitudes.
    public var centerOfMass: Point? {
        if let feature = self as? Feature {
            return feature.geometry?.centerOfMass
        }

        switch type {
        case .point:
            return (self as? Point).map { Point($0.coordinate) }

        case .polygon:
            return (self as? Polygon).flatMap(polygonCenterOfMass)

        case .multiPolygon:
            return (self as? MultiPolygon).flatMap(multiPolygonCenterOfMass)

        default:
            if let hull = convexHull() {
                return hull.centerOfMass
            }
            return centroid
        }
    }

    private func polygonCenterOfMass(_ polygon: Polygon) -> Point? {
        guard polygon.rings.isNotEmpty else { return nil }

        var totalArea = 0.0
        var sumX = 0.0
        var sumY = 0.0
        var sumZ = 0.0
        var weightedAltitude = 0.0

        for (index, ring) in polygon.rings.enumerated() {
            let area = abs(ring.area)
            guard area > GISTool.equalityDelta,
                  let center = ringCenter(ring.coordinates)
            else { continue }

            let sign = index == 0 ? 1.0 : -1.0
            totalArea += sign * area
            sumX += sign * area * center.x
            sumY += sign * area * center.y
            if let altitude = center.z {
                sumZ += sign * area * altitude
                weightedAltitude += sign * area
            }
        }

        guard totalArea > GISTool.equalityDelta else {
            return centroid
        }

        return Point(Coordinate3D(
            x: sumX / totalArea,
            y: sumY / totalArea,
            z: abs(weightedAltitude) > GISTool.equalityDelta ? sumZ / weightedAltitude : nil,
            projection: polygon.projection))
    }

    private func multiPolygonCenterOfMass(_ multiPolygon: MultiPolygon) -> Point? {
        var totalArea = 0.0
        var sumX = 0.0
        var sumY = 0.0
        var sumZ = 0.0
        var weightedAltitude = 0.0

        for polygon in multiPolygon.polygons {
            guard let center = polygonCenterOfMass(polygon) else { continue }

            let area = polygon.area
            guard area > GISTool.equalityDelta else { continue }

            totalArea += area
            sumX += area * center.coordinate.x
            sumY += area * center.coordinate.y
            if let altitude = center.coordinate.z {
                sumZ += area * altitude
                weightedAltitude += area
            }
        }

        guard totalArea > GISTool.equalityDelta else {
            return multiPolygon.centroid
        }

        return Point(Coordinate3D(
            x: sumX / totalArea,
            y: sumY / totalArea,
            z: abs(weightedAltitude) > GISTool.equalityDelta ? sumZ / weightedAltitude : nil,
            projection: multiPolygon.projection))
    }

    private func ringCenter(_ coordinates: [Coordinate3D]) -> Coordinate3D? {
        guard coordinates.count >= 3 else { return nil }

        var area = 0.0
        var sumX = 0.0
        var sumY = 0.0
        var sumZ = 0.0
        var hasAltitude = true

        for index in 0 ..< (coordinates.count - 1) {
            let first = coordinates[index]
            let second = coordinates[index + 1]
            let cross = (first.longitude * second.latitude)
                - (second.longitude * first.latitude)
            area += cross
            sumX += (first.longitude + second.longitude) * cross
            sumY += (first.latitude + second.latitude) * cross
            if let firstAltitude = first.altitude,
               let secondAltitude = second.altitude
            {
                sumZ += (firstAltitude + secondAltitude) * cross
            }
            else {
                hasAltitude = false
            }
        }

        guard abs(area) > GISTool.equalityDelta else { return nil }

        return Coordinate3D(
            x: sumX / (3.0 * area),
            y: sumY / (3.0 * area),
            z: hasAltitude ? sumZ / (3.0 * area) : nil,
            projection: coordinates[0].projection)
    }

    /// Coordinates used by the vertex centroid, excluding one closing vertex
    /// per polygon ring.
    private var centroidCoordinates: [Coordinate3D] {
        switch self {
        case let point as Point:
            return point.allCoordinates

        case let multiPoint as MultiPoint:
            return multiPoint.allCoordinates

        case let lineString as LineString:
            return lineString.allCoordinates

        case let multiLineString as MultiLineString:
            return multiLineString.allCoordinates

        case let polygon as Polygon:
            return polygon.rings.flatMap { ring in
                ring.coordinates.first == ring.coordinates.last
                    ? Array(ring.coordinates.dropLast())
                    : ring.coordinates
            }

        case let multiPolygon as MultiPolygon:
            return multiPolygon.polygons.flatMap { polygon in
                polygon.rings.flatMap { ring in
                    ring.coordinates.first == ring.coordinates.last
                        ? Array(ring.coordinates.dropLast())
                        : ring.coordinates
                }
            }

        case let collection as GeometryCollection:
            return collection.geometries.flatMap(\.centroidCoordinates)

        case let feature as Feature:
            return feature.geometry?.centroidCoordinates ?? []

        case let collection as FeatureCollection:
            return collection.features.flatMap { $0.geometry?.centroidCoordinates ?? [] }

        default:
            return allCoordinates
        }
    }

}
