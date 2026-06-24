#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-boolean-intersects

extension GeoJson {

    /// Compares two geometries and returns true if they intersect.
    ///
    /// All projections are supported. Delegates to ``isDisjoint(with:)``.
    ///
    /// - Parameter other: The other geometry
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    ///
    /// - Returns: `true` if the geometries intersect, `false` otherwise.
    public func intersects(_ other: GeoJson, gridSize: Double? = nil) -> Bool {
        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let snappedOther = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        return !snappedSelf.isDisjoint(with: snappedOther)
    }

}
