#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-point-on-line
// and from https://github.com/Turfjs/turf/blob/master/packages/turf-point-on-feature

extension LineSegment {

    /// Tests if *Coordinate3D* is on the segment.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    public func checkIsOnSegment(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        let coordinate = coordinate.projected(to: projection)
        let snapped = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate

        let ab = sqrt((snapped.second.longitude - snapped.first.longitude) * (snapped.second.longitude - snapped.first.longitude)
            + (snapped.second.latitude - snapped.first.latitude) * (snapped.second.latitude - snapped.first.latitude))
        let ap = sqrt((snappedCoordinate.longitude - snapped.first.longitude) * (snappedCoordinate.longitude - snapped.first.longitude)
            + (snappedCoordinate.latitude - snapped.first.latitude) * (snappedCoordinate.latitude - snapped.first.latitude))
        let pb = sqrt((snapped.second.longitude - snappedCoordinate.longitude) * (snapped.second.longitude - snappedCoordinate.longitude)
            + (snapped.second.latitude - snappedCoordinate.latitude) * (snapped.second.latitude - snappedCoordinate.latitude))

        return abs(ab - (ap + pb)) < GISTool.equalityDelta
    }

    /// Tests if *Point* is on the segment.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    public func checkIsOnSegment(_ point: Point, gridSize: Double? = nil) -> Bool {
        checkIsOnSegment(point.coordinate, gridSize: gridSize)
    }

}

extension LineStringGeometry {

    /// Tests if *Coordinate3D* is on the line.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    public func checkIsOnLine(_ coordinate: Coordinate3D, gridSize: Double? = nil) -> Bool {
        let snappedCoordinate = gridSize.map { coordinate.snappedToGrid(tolerance: $0) } ?? coordinate
        return lineSegments.contains { (segment) in
            segment.checkIsOnSegment(snappedCoordinate, gridSize: gridSize)
        }
    }

    /// Tests if *Point* is on the line.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    public func checkIsOnLine(_ point: Point, gridSize: Double? = nil) -> Bool {
        checkIsOnLine(point.coordinate, gridSize: gridSize)
    }

}
