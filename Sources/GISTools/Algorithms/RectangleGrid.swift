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
        let projection = bbox.projection

        // For EPSG:3857 coordinates are in meters (cell dimensions too — use directly).
        // For EPSG:4326 and EPSG:4978 coordinates are in degrees
        // (geodetic for 4978, converted from ECEF) — convert cell from meters to degrees.
        // noSRID has no meaningful coordinate space for a grid.
        guard projection != .noSRID else { return FeatureCollection() }
        return gridProjected(
            bbox: bbox,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            mask: mask)
    }

    private static func gridProjected(
        bbox: BoundingBox,
        cellWidth: CLLocationDistance,
        cellHeight: CLLocationDistance,
        mask: (any GeoJson)?
    ) -> FeatureCollection {
        let projection = bbox.projection
        // For 3857: coordinates are in meters, cell dimensions are too — use directly.
        // For 4326/4978: coordinates are in degrees, convert cell from meters to degrees.
        let coordinatesAreInMeters = projection == .epsg3857

        let cellStepX: Double = coordinatesAreInMeters ? cellWidth : cellWidth / 111_325.0
        let cellStepY: Double = coordinatesAreInMeters ? cellHeight : cellHeight / 111_325.0

        let west = bbox.southWest.longitude
        let south = bbox.southWest.latitude
        let east = bbox.northEast.longitude
        let north = bbox.northEast.latitude

        let bboxWidth = east - west
        let bboxHeight = north - south

        let columns = Int(floor(abs(bboxWidth) / cellStepX))
        let rows = Int(floor(abs(bboxHeight) / cellStepY))

        guard columns > 0, rows > 0 else { return FeatureCollection() }

        let deltaX = (bboxWidth - Double(columns) * cellStepX) / 2.0
        let deltaY = (bboxHeight - Double(rows) * cellStepY) / 2.0

        var results: [Feature] = []

        var currentX = west + deltaX
        for _ in 0 ..< columns {
            var currentY = south + deltaY
            for _ in 0 ..< rows {
                let cellPoly: Polygon
                if coordinatesAreInMeters {
                    cellPoly = Polygon(unchecked: [[
                        Coordinate3D(x: currentX, y: currentY),
                        Coordinate3D(x: currentX, y: currentY + cellStepY),
                        Coordinate3D(x: currentX + cellStepX, y: currentY + cellStepY),
                        Coordinate3D(x: currentX + cellStepX, y: currentY),
                        Coordinate3D(x: currentX, y: currentY),
                    ]])
                }
                else {
                    cellPoly = Polygon(unchecked: [[
                        Coordinate3D(latitude: currentY, longitude: currentX),
                        Coordinate3D(latitude: currentY + cellStepY, longitude: currentX),
                        Coordinate3D(latitude: currentY + cellStepY, longitude: currentX + cellStepX),
                        Coordinate3D(latitude: currentY, longitude: currentX + cellStepX),
                        Coordinate3D(latitude: currentY, longitude: currentX),
                    ]])
                }

                if let mask {
                    if mask.intersects(cellPoly) {
                        results.append(Feature(cellPoly))
                    }
                }
                else {
                    results.append(Feature(cellPoly))
                }

                currentY += cellStepY
            }
            currentX += cellStepX
        }

        return FeatureCollection(results)
    }

}
