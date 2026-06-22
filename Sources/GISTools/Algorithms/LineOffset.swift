#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-line-offset

extension LineString {

    /// Takes a line and returns a line at offset by the specified distance.
    ///
    /// A positive distance offsets to the right side of the line direction,
    /// a negative distance to the left side. The offset is computed in
    /// geographic (lon/lat) space using a degree approximation.
    ///
    /// - Parameter distance: Distance to offset the line (in meters)
    /// - Returns: The offset line, or `nil` if the line has fewer than two coordinates
    public func offset(
        by distance: CLLocationDistance
    ) -> LineString? {
        let coordinatesAreInMeters = projection == .epsg3857

        let offsetInCRS: Double
        if coordinatesAreInMeters {
            offsetInCRS = distance
        }
        else if let deg = distance.lengthToDegrees(unit: .meters), deg.isNormal {
            offsetInCRS = deg
        }
        else {
            return self
        }

        let workingCoords: [Coordinate3D] = coordinatesAreInMeters
            ? self.coordinates
            : projection == .epsg4326
                ? self.coordinates
                : self.coordinates.map { $0.projected(to: .epsg4326) }

        guard workingCoords.count >= 2 else { return nil }

        var segments: [(start: Coordinate3D, end: Coordinate3D)] = []
        var finalCoords: [Coordinate3D] = []

        for i in 0 ..< workingCoords.count - 1 {
            let segment = LineOffsetHelper.offsetSegment(
                workingCoords[i],
                workingCoords[i + 1],
                offsetInCRS,
                coordinatesAreInMeters: coordinatesAreInMeters)
            segments.append(segment)

            if i > 0 {
                if let intersection = LineOffsetHelper.intersectSegments(
                    segments[i - 1],
                    segment,
                    coordinatesAreInMeters: coordinatesAreInMeters)
                {
                    segments[i - 1].end = intersection
                    segments[i].start = intersection
                }
                finalCoords.append(segments[i - 1].start)
                if i == workingCoords.count - 2 {
                    finalCoords.append(segment.start)
                    finalCoords.append(segment.end)
                }
            }
            else if workingCoords.count == 2 {
                finalCoords.append(segment.start)
                finalCoords.append(segment.end)
            }
        }

        guard finalCoords.count >= 2 else { return nil }

        guard let result = LineString(finalCoords) else { return nil }

        if coordinatesAreInMeters || projection == .epsg4326 {
            return result
        }
        return result.projected(to: projection)
    }

}

extension MultiLineString {

    /// Takes a multi-line and returns a multi-line with each line offset by the specified distance.
    ///
    /// - Parameter distance: Distance to offset each line (in meters)
    /// - Returns: The offset multi-line, or `nil` if the result could not be constructed
    public func offset(
        by distance: CLLocationDistance
    ) -> MultiLineString? {
        let lineStrings = self.lineStrings.compactMap { $0.offset(by: distance) }
        guard lineStrings.isNotEmpty else { return nil }
        return MultiLineString(lineStrings)
    }

}

private enum LineOffsetHelper {

    /// Computes the offset of a single line segment perpendicular to its direction.
    static func offsetSegment(
        _ p1: Coordinate3D,
        _ p2: Coordinate3D,
        _ offset: Double,
        coordinatesAreInMeters: Bool
    ) -> (start: Coordinate3D, end: Coordinate3D) {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let len = sqrt(dx * dx + dy * dy)

        let outputProj: Projection = coordinatesAreInMeters ? .epsg3857 : .epsg4326

        guard len > .ulpOfOne else {
            return (
                Coordinate3D(x: p1.x + offset, y: p1.y, projection: outputProj),
                Coordinate3D(x: p2.x + offset, y: p2.y, projection: outputProj)
            )
        }

        let nx = offset * dy / len
        let ny = -offset * dx / len

        return (
            Coordinate3D(x: p1.x + nx, y: p1.y + ny, projection: outputProj),
            Coordinate3D(x: p2.x + nx, y: p2.y + ny, projection: outputProj)
        )
    }

    /// Computes the intersection of two infinite lines defined by segments.
    /// Returns `nil` if the lines are parallel (or collinear).
    static func intersectSegments(
        _ a: (start: Coordinate3D, end: Coordinate3D),
        _ b: (start: Coordinate3D, end: Coordinate3D),
        coordinatesAreInMeters: Bool
    ) -> Coordinate3D? {
        let ax = a.end.x - a.start.x
        let ay = a.end.y - a.start.y
        let bx = b.end.x - b.start.x
        let by = b.end.y - b.start.y

        let cross = ax * by - ay * bx

        guard abs(cross) > GISTool.equalityDelta else {
            return nil
        }

        let qmx = b.start.x - a.start.x
        let qmy = b.start.y - a.start.y

        let t = (qmx * by - qmy * bx) / cross

        return Coordinate3D(
            x: a.start.x + t * ax,
            y: a.start.y + t * ay,
            projection: coordinatesAreInMeters ? .epsg3857 : .epsg4326)
    }

}
