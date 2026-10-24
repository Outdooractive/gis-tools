#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-point-on-line
// and from https://github.com/Turfjs/turf/blob/master/packages/turf-point-on-feature

extension LineSegment {

    /// Tests if *Coordinate3D* is on the segment.
    /// - Parameter coordinate: The coordinate to test.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    public func checkIsOnSegment(
        _ coordinate: Coordinate3D,
        gridSize: Double? = nil
    ) -> Bool {
        let coordinate = coordinate.projected(to: projection)
        let snapped = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        var snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate
        var snappedSegment = snapped

        if let extent = projection.wraparoundExtent {
            let unwrapped = AntimeridianCutting.unwrapCoordinates(
                [snapped.first, snapped.second, snappedCoordinate],
                extent: extent)
            snappedSegment = LineSegment(first: unwrapped[0], second: unwrapped[1], index: snapped.index)
            snappedCoordinate = unwrapped[2]
        }

        let ab = sqrt((snappedSegment.second.longitude - snappedSegment.first.longitude) * (snappedSegment.second.longitude - snappedSegment.first.longitude)
            + (snappedSegment.second.latitude - snappedSegment.first.latitude) * (snappedSegment.second.latitude - snappedSegment.first.latitude))
        let ap = sqrt((snappedCoordinate.longitude - snappedSegment.first.longitude) * (snappedCoordinate.longitude - snappedSegment.first.longitude)
            + (snappedCoordinate.latitude - snappedSegment.first.latitude) * (snappedCoordinate.latitude - snappedSegment.first.latitude))
        let pb = sqrt((snappedSegment.second.longitude - snappedCoordinate.longitude) * (snappedSegment.second.longitude - snappedCoordinate.longitude)
            + (snappedSegment.second.latitude - snappedCoordinate.latitude) * (snappedSegment.second.latitude - snappedCoordinate.latitude))

        return abs(ab - (ap + pb)) < GISTool.equalityDelta
    }

    /// Tests if *Point* is on the segment.
    /// - Parameter point: The point to test.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    public func checkIsOnSegment(_ point: Point, gridSize: Double? = nil) -> Bool {
        checkIsOnSegment(point.coordinate, gridSize: gridSize)
    }

}

extension LineStringGeometry {

    /// Tests if *Coordinate3D* is on the line.
    /// - Parameter coordinate: The coordinate to test.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    public func checkIsOnLine(
        _ coordinate: Coordinate3D,
        gridSize: Double? = nil
    ) -> Bool {
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate
        return lineSegments.contains { (segment) in
            segment.checkIsOnSegment(snappedCoordinate, gridSize: gridSize)
        }
    }

    /// Tests if *Point* is on the line.
    /// - Parameter point: The point to test.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    public func checkIsOnLine(
        _ point: Point,
        gridSize: Double? = nil
    ) -> Bool {
        checkIsOnLine(point.coordinate, gridSize: gridSize)
    }

}
