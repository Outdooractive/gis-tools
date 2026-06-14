#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-square-grid

extension BoundingBox {

    /// Creates a grid of square polygons.
    ///
    /// - Parameter cellSide: Length of each cell side in meters.
    /// - Parameter mask: If provided, only cells intersecting the mask geometry are returned.
    ///
    /// - Returns: A feature collection of square polygon features.
    public func squareGrid(
        cellSide: CLLocationDistance,
        mask: (any GeoJson)? = nil
    ) -> FeatureCollection {
        rectangleGrid(
            cellWidth: cellSide,
            cellHeight: cellSide,
            mask: mask)
    }

}
