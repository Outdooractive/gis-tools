#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-points-within-polygon

extension PolygonGeometry {

    /// Finds coordinates that fall within the receiver.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    public func coordinatesWithin(_ coordinates: [Coordinate3D], gridSize: Double? = nil) -> [Coordinate3D] {
        guard let gridSize else {
            return coordinates.filter { contains($0, ignoringBoundary: false, gridSize: nil) }
        }
        let snappedSelf = self.snappedToGrid(tolerance: gridSize)
        return coordinates.filter { snappedSelf.contains($0.snappedToGrid(tolerance: gridSize), ignoringBoundary: false, gridSize: nil) }
    }

    /// Finds *Point*s that fall within the receiver.
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    public func pointsWithin(_ points: [Point], gridSize: Double? = nil) -> [Point] {
        guard let gridSize else {
            return points.filter { contains($0.coordinate, ignoringBoundary: false, gridSize: nil) }
        }
        let snappedSelf = self.snappedToGrid(tolerance: gridSize)
        return points.filter { snappedSelf.contains($0.coordinate.snappedToGrid(tolerance: gridSize), ignoringBoundary: false, gridSize: nil) }
    }

}
