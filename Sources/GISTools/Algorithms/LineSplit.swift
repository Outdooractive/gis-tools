#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-line-split

extension LineString {

    /// Splits the receiver at the points where it intersects another geometry.
    ///
    /// The result is a ``FeatureCollection`` of ``LineString`` segments between
    /// consecutive split points, preserving the order along the original line.
    /// If there are no intersections, the result contains the original line.
    ///
    /// - Parameter splitter: A ``Point``, ``MultiPoint``, ``LineString``, or ``MultiLineString``
    ///   whose intersections with this line define the split points.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Parameter tolerance: Minimum distance between split points in meters (default `1.0`).
    ///   Split points closer than this are merged; segments shorter than half this are dropped.
    /// - Returns: A ``FeatureCollection`` of ``LineString`` segments.
    public func lineSplit(
        with splitter: GeoJson,
        gridSize: Double? = nil,
        tolerance: CLLocationDistance = 1.0
    ) -> FeatureCollection {
        let snapped = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self

        guard let firstCoord = snapped.firstCoordinate,
              let lastCoord = snapped.lastCoordinate
        else { return FeatureCollection() }

        // Collect split points: from intersections and from point-on-line checks
        var splitCoords: [Coordinate3D] = []

        if let pointGeom = splitter as? PointGeometry {
            // Point/MultiPoint: check if each point is on the line
            for coord in pointGeom.allCoordinates {
                let projected = coord.projected(to: snapped.projection)
                if snapped.checkIsOnLine(projected) {
                    splitCoords.append(projected)
                }
            }
        }
        else {
            // LineString/MultiLineString etc.: use general intersection
            splitCoords = snapped.intersections(with: splitter, gridSize: gridSize).map(\.coordinate)
        }

        // Include the start and end as implicit split points
        var splitPoints: [(coordinate: Coordinate3D, distance: CLLocationDistance)] = [
            (firstCoord, 0.0),
            (lastCoord, snapped.length),
        ]

        for coord in splitCoords {
            guard let distance = snapped.distanceAlong(to: coord) else { continue }
            if splitPoints.contains(where: { abs($0.distance - distance) < tolerance }) { continue }
            splitPoints.append((coord, distance))
        }

        splitPoints.sort { $0.distance < $1.distance }

        var segments: [LineString] = []
        for i in 0..<(splitPoints.count - 1) {
            let startDist = splitPoints[i].distance
            let endDist = splitPoints[i + 1].distance

            // Skip segments shorter than half the tolerance
            guard abs(endDist - startDist) > tolerance * 0.5 else { continue }

            if let segment = snapped.sliceAlong(startDistance: startDist, stopDistance: endDist) {
                segments.append(segment)
            }
        }

        let features = segments.map { Feature($0) }
        return FeatureCollection(features)
    }

}
