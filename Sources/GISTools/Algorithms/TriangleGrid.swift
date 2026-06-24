#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-triangle-grid

extension BoundingBox {

    /// Creates a grid of triangular polygons within the bounding box.
    /// Two triangles are created in each rectangular cell.
    ///
    /// - Parameter cellSide: Dimension of each grid cell side in meters (or native units for 3857/4978/noSRID).
    /// - Parameter mask: If provided, only triangles intersecting the mask geometry are returned.
    ///
    /// - Returns: A feature collection of triangular polygon features.
    public func triangleGrid(
        cellSide: CLLocationDistance,
        mask: (any GeoJson)? = nil
    ) -> FeatureCollection {
        TriangleGrid.grid(
            bbox: self,
            cellSide: cellSide,
            mask: mask)
    }

}

// MARK: - TriangleGrid namespace

private enum TriangleGrid {

    static func grid(
        bbox: BoundingBox,
        cellSide: CLLocationDistance,
        mask: (any GeoJson)?
    ) -> FeatureCollection {
        let projection = bbox.projection
        let coordinatesAreInMeters = projection == .epsg3857 || projection == .epsg4978 || projection == .noSRID

        let west = bbox.southWest.longitude
        let south = bbox.southWest.latitude
        let east = bbox.northEast.longitude
        let north = bbox.northEast.latitude

        let bboxWidth = east - west
        let bboxHeight = north - south

        let centerY = (south + north) / 2.0
        let centerX = (west + east) / 2.0

        let cellWidthDeg: Double
        let cellHeightDeg: Double
        if coordinatesAreInMeters {
            cellWidthDeg = cellSide
            cellHeightDeg = cellSide
        }
        else {
            let xDistance = Coordinate3D(latitude: centerY, longitude: west)
                .distance(to: Coordinate3D(latitude: centerY, longitude: east))
            cellWidthDeg = xDistance > 0.0 ? (cellSide / xDistance) * bboxWidth : bboxWidth

            let yDistance = Coordinate3D(latitude: south, longitude: centerX)
                .distance(to: Coordinate3D(latitude: north, longitude: centerX))
            cellHeightDeg = yDistance > 0.0 ? (cellSide / yDistance) * bboxHeight : bboxHeight
        }

        guard cellWidthDeg > 0.0, cellHeightDeg > 0.0 else { return FeatureCollection() }

        let columns = Int(floor(abs(bboxWidth) / cellWidthDeg))
        let rows = Int(floor(abs(bboxHeight) / cellHeightDeg))

        guard columns > 0, rows > 0 else { return FeatureCollection() }

        let deltaX = (bboxWidth - Double(columns) * cellWidthDeg) / 2.0
        let deltaY = (bboxHeight - Double(rows) * cellHeightDeg) / 2.0

        func coord(x: Double, y: Double) -> Coordinate3D {
            if coordinatesAreInMeters {
                Coordinate3D(x: x, y: y, projection: projection)
            }
            else {
                Coordinate3D(latitude: y, longitude: x)
            }
        }

        var results: [Feature] = []

        var currentX = west + deltaX
        for xi in 0 ..< columns {
            var currentY = south + deltaY
            for yi in 0 ..< rows {
                let cellTriangle1: Polygon
                let cellTriangle2: Polygon

                let isEvenX = xi % 2 == 0
                let isEvenY = yi % 2 == 0

                if isEvenX, isEvenY {
                    cellTriangle1 = Polygon(unchecked: [[
                        coord(x: currentX, y: currentY),
                        coord(x: currentX, y: currentY + cellHeightDeg),
                        coord(x: currentX + cellWidthDeg, y: currentY),
                        coord(x: currentX, y: currentY),
                    ]])
                    cellTriangle2 = Polygon(unchecked: [[
                        coord(x: currentX, y: currentY + cellHeightDeg),
                        coord(x: currentX + cellWidthDeg, y: currentY + cellHeightDeg),
                        coord(x: currentX + cellWidthDeg, y: currentY),
                        coord(x: currentX, y: currentY + cellHeightDeg),
                    ]])
                }
                else if isEvenX, !isEvenY {
                    cellTriangle1 = Polygon(unchecked: [[
                        coord(x: currentX, y: currentY),
                        coord(x: currentX + cellWidthDeg, y: currentY + cellHeightDeg),
                        coord(x: currentX + cellWidthDeg, y: currentY),
                        coord(x: currentX, y: currentY),
                    ]])
                    cellTriangle2 = Polygon(unchecked: [[
                        coord(x: currentX, y: currentY),
                        coord(x: currentX, y: currentY + cellHeightDeg),
                        coord(x: currentX + cellWidthDeg, y: currentY + cellHeightDeg),
                        coord(x: currentX, y: currentY),
                    ]])
                }
                else if !isEvenX, isEvenY {
                    cellTriangle1 = Polygon(unchecked: [[
                        coord(x: currentX, y: currentY),
                        coord(x: currentX, y: currentY + cellHeightDeg),
                        coord(x: currentX + cellWidthDeg, y: currentY + cellHeightDeg),
                        coord(x: currentX, y: currentY),
                    ]])
                    cellTriangle2 = Polygon(unchecked: [[
                        coord(x: currentX, y: currentY),
                        coord(x: currentX + cellWidthDeg, y: currentY + cellHeightDeg),
                        coord(x: currentX + cellWidthDeg, y: currentY),
                        coord(x: currentX, y: currentY),
                    ]])
                }
                else {
                    cellTriangle1 = Polygon(unchecked: [[
                        coord(x: currentX, y: currentY),
                        coord(x: currentX, y: currentY + cellHeightDeg),
                        coord(x: currentX + cellWidthDeg, y: currentY),
                        coord(x: currentX, y: currentY),
                    ]])
                    cellTriangle2 = Polygon(unchecked: [[
                        coord(x: currentX, y: currentY + cellHeightDeg),
                        coord(x: currentX + cellWidthDeg, y: currentY + cellHeightDeg),
                        coord(x: currentX + cellWidthDeg, y: currentY),
                        coord(x: currentX, y: currentY + cellHeightDeg),
                    ]])
                }

                if let mask {
                    if mask.intersects(cellTriangle1) {
                        results.append(Feature(cellTriangle1))
                    }
                    if mask.intersects(cellTriangle2) {
                        results.append(Feature(cellTriangle2))
                    }
                }
                else {
                    results.append(Feature(cellTriangle1))
                    results.append(Feature(cellTriangle2))
                }

                currentY += cellHeightDeg
            }
            currentX += cellWidthDeg
        }

        return FeatureCollection(results)
    }

}
