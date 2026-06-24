#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-polygon-tangents

extension Polygon {

    /// Finds the two tangent points of this polygon from an external point.
    ///
    /// The result is a ``MultiPoint`` containing the two points on the polygon's
    /// boundary where lines from the given point are tangent to the polygon.
    /// Returns `nil` if the point is inside the polygon or if the polygon has
    /// no outer ring.
    ///
    /// All projections are supported. The tangent-finding algorithm uses
    /// cross products on native XY values.
    ///
    /// - Parameter point: An external point
    /// - Returns: A ``MultiPoint`` with the two tangent points, or `nil`
    public func tangentPoints(to point: Coordinate3D) -> MultiPoint? {
        guard let ring = outerRing else { return nil }
        let coords = ring.coordinates

        guard coords.count >= 3 else { return nil }

        // Project both to the same coordinate system
        let point = point.projected(to: projection)
        let projectedCoords = coords.map { $0.projected(to: projection) }

        // Skip the closing coordinate (last == first)
        let vertices = Array(projectedCoords.dropLast())
        guard vertices.count >= 3 else { return nil }

        // Determine whether to shift longitudes for antimeridian handling.
        // Only applies to EPSG:4326. For meter-based CRS the coordinate
        // values are already in projection units (meters).
        let spansAntimeridian: Bool
        let pointOnFarSide: Bool
        if projection == .epsg4326 {
            let minLon = vertices.map(\.longitude).min() ?? 0
            let maxLon = vertices.map(\.longitude).max() ?? 0
            let centroidLon = (minLon + maxLon) / 2.0
            spansAntimeridian = (maxLon - minLon) > 180.0
            pointOnFarSide = abs(point.longitude - centroidLon) > 180.0
        }
        else {
            spansAntimeridian = false
            pointOnFarSide = false
        }

        let shiftedPoint: Coordinate3D
        var shiftedVertices = vertices
        var shouldUnshift = false

        if spansAntimeridian {
            shouldUnshift = true
            shiftedPoint = Coordinate3D(
                x: point.longitude < 0 ? point.longitude + 360.0 : point.longitude,
                y: point.latitude,
                z: point.altitude,
                m: point.m,
                projection: projection)
            shiftedVertices = vertices.map { coord in
                let newLon = coord.longitude < 0 ? coord.longitude + 360.0 : coord.longitude
                return Coordinate3D(x: newLon, y: coord.latitude, z: coord.altitude, m: coord.m, projection: projection)
            }
        }
        else if pointOnFarSide {
            // Shift the point so it approaches the polygon across the date line
            shouldUnshift = true
            let shift = point.longitude < (vertices.map(\.longitude).min()! + vertices.map(\.longitude).max()!) / 2.0 ? 360.0 : -360.0
            shiftedPoint = Coordinate3D(
                x: point.longitude + shift,
                y: point.latitude,
                z: point.altitude,
                m: point.m,
                projection: projection)
            shiftedVertices = vertices
        }
        else {
            shiftedPoint = point
        }

        guard !isInside(shiftedPoint, vertices: shiftedVertices) else { return nil }

        guard let rightIdx = findTangent(vertices: shiftedVertices, point: shiftedPoint, direction: 1),
              let leftIdx = findTangent(vertices: shiftedVertices, point: shiftedPoint, direction: -1)
        else { return nil }

        // Unshift tangents back to original longitude range
        func unshift(_ coord: Coordinate3D) -> Coordinate3D {
            guard shouldUnshift, abs(coord.longitude) > 180.0 else { return coord }
            return Coordinate3D(x: coord.longitude - 360.0, y: coord.latitude,
                                z: coord.altitude, m: coord.m, projection: projection)
        }
        return MultiPoint([unshift(shiftedVertices[rightIdx]), unshift(shiftedVertices[leftIdx])])
    }

}

// MARK: - Helpers

extension Polygon {

    /// Checks if `point` is inside the convex polygon defined by `vertices`.
    private func isInside(_ point: Coordinate3D, vertices: [Coordinate3D]) -> Bool {
        guard vertices.count >= 3 else { return false }
        let sign = crossProduct(vertices[0], vertices[1], point) > 0.0
        for i in 1..<vertices.count {
            let j = (i + 1) % vertices.count
            let s = crossProduct(vertices[i], vertices[j], point)
            if s == 0.0 { continue }
            if (s > 0.0) != sign { return false }
        }
        return true
    }

    /// Cross product of vectors (a→b) × (a→p).
    /// Positive = counter-clockwise turn, negative = clockwise.
    private func crossProduct(_ a: Coordinate3D, _ b: Coordinate3D, _ p: Coordinate3D) -> Double {
        (b.longitude - a.longitude) * (p.latitude - a.latitude)
            - (b.latitude - a.latitude) * (p.longitude - a.longitude)
    }

    /// Linear scan for a tangent vertex in the given direction.
    /// Direction 1 = right tangent (point is left of both adjacent edges).
    /// Direction -1 = left tangent (point is right of both adjacent edges).
    private func findTangent(
        vertices: [Coordinate3D],
        point: Coordinate3D,
        direction: Int
    ) -> Int? {
        let n = vertices.count
        guard n >= 2 else { return nil }

        let dir = Double(direction)

        for i in 0..<n {
            let prev = (i - 1 + n) % n
            let next = (i + 1) % n

            let cpPrev = dir * crossProduct(point, vertices[i], vertices[prev])
            let cpNext = dir * crossProduct(point, vertices[i], vertices[next])

            if cpPrev >= 0 && cpNext >= 0 {
                return i
            }
        }

        return nil
    }

}
