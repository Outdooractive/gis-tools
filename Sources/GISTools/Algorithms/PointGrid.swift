#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-point-grid

extension BoundingBox {

    /// Creates a grid of points within the bounding box.
    ///
    /// - Parameter cellSide: Spacing between points in meters.
    /// - Parameter mask: If provided, only points intersecting the mask geometry are returned.
    ///
    /// - Returns: A feature collection of point features.
    public func pointGrid(
        cellSide: CLLocationDistance,
        mask: (any GeoJson)? = nil
    ) -> FeatureCollection {
        PointGrid.grid(
            bbox: self,
            cellSide: cellSide,
            mask: mask)
    }

}

// MARK: - PointGrid namespace

private enum PointGrid {

    static func grid(
        bbox: BoundingBox,
        cellSide: CLLocationDistance,
        mask: (any GeoJson)?
    ) -> FeatureCollection {
        let projection = bbox.projection
        guard projection != .noSRID else { return FeatureCollection() }
        let coordinatesAreInMeters = projection == .epsg3857

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

        var results: [Feature] = []

        var currentX = west + deltaX
        for _ in 0 ..< columns {
            var currentY = south + deltaY
            for _ in 0 ..< rows {
                let coord: Coordinate3D
                if coordinatesAreInMeters {
                    coord = Coordinate3D(x: currentX, y: currentY)
                }
                else {
                    coord = Coordinate3D(latitude: currentY, longitude: currentX)
                }
                let point = Point(coord)
                let feature = Feature(point)

                if let mask {
                    if mask.intersects(point) {
                        results.append(feature)
                    }
                }
                else {
                    results.append(feature)
                }

                currentY += cellHeightDeg
            }
            currentX += cellWidthDeg
        }

        return FeatureCollection(results)
    }

}
