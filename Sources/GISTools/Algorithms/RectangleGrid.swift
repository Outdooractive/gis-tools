#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-rectangle-grid

extension BoundingBox {

    /// Creates a grid of rectangular polygons.
    ///
    /// - Parameter cellWidth: Width of each cell in meters.
    /// - Parameter cellHeight: Height of each cell in meters.
    /// - Parameter mask: If provided, only cells intersecting the mask geometry are returned.
    ///
    /// - Returns: A feature collection of rectangular polygon features.
    public func rectangleGrid(
        cellWidth: CLLocationDistance,
        cellHeight: CLLocationDistance,
        mask: (any GeoJson)? = nil
    ) -> FeatureCollection {
        RectangleGrid.grid(
            bbox: self,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            mask: mask)
    }

}

// MARK: - RectangleGrid namespace

private enum RectangleGrid {

    static func grid(
        bbox: BoundingBox,
        cellWidth: CLLocationDistance,
        cellHeight: CLLocationDistance,
        mask: (any GeoJson)?
    ) -> FeatureCollection {
        let west = bbox.southWest.longitude
        let south = bbox.southWest.latitude
        let east = bbox.northEast.longitude
        let north = bbox.northEast.latitude

        let bboxWidth = east - west
        let bboxHeight = north - south

        let cellWidthDeg = cellWidth / 111_325.0
        let cellHeightDeg = cellHeight / 111_325.0

        let columns = Int(floor(abs(bboxWidth) / cellWidthDeg))
        let rows = Int(floor(abs(bboxHeight) / cellHeightDeg))

        guard columns > 0, rows > 0 else { return FeatureCollection() }

        let deltaX = (bboxWidth - Double(columns) * cellWidthDeg) / 2.0
        let deltaY = (bboxHeight - Double(rows) * cellHeightDeg) / 2.0

        var results: [Feature] = []

        var currentX = west + deltaX
        for _ in 0 ..< columns {
            var currentY = south + deltaY
            for _ in 0 ..< rows {
                let cellPoly = Polygon(unchecked: [[
                    Coordinate3D(latitude: currentY, longitude: currentX),
                    Coordinate3D(latitude: currentY + cellHeightDeg, longitude: currentX),
                    Coordinate3D(latitude: currentY + cellHeightDeg, longitude: currentX + cellWidthDeg),
                    Coordinate3D(latitude: currentY, longitude: currentX + cellWidthDeg),
                    Coordinate3D(latitude: currentY, longitude: currentX),
                ]])

                if let mask {
                    if mask.intersects(cellPoly) {
                        results.append(Feature(cellPoly))
                    }
                }
                else {
                    results.append(Feature(cellPoly))
                }

                currentY += cellHeightDeg
            }
            currentX += cellWidthDeg
        }

        return FeatureCollection(results)
    }

}
