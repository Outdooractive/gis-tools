#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-hex-grid

extension BoundingBox {

    /// Creates a grid of hexagonal (or triangular) polygons within the bounding box.
    /// Hexagons are flat-topped and aligned in an "odd-q" vertical grid.
    ///
    /// - Parameter cellSide: Length of the side of each hexagon in meters.
    /// - Parameter triangles: If `true`, returns triangles instead of hexagons (default `false`).
    /// - Parameter mask: If provided, only cells intersecting the mask geometry are returned.
    ///
    /// - Returns: A feature collection of hexagonal (or triangular) polygon features.
    public func hexGrid(
        cellSide: CLLocationDistance,
        triangles: Bool = false,
        mask: (any GeoJson)? = nil
    ) -> FeatureCollection {
        HexGrid.grid(
            bbox: self,
            cellSide: cellSide,
            triangles: triangles,
            mask: mask)
    }

}

// MARK: - HexGrid namespace

private enum HexGrid {

    static func grid(
        bbox: BoundingBox,
        cellSide: CLLocationDistance,
        triangles: Bool,
        mask: (any GeoJson)?
    ) -> FeatureCollection {
        let projection = bbox.projection
        guard projection != .noSRID else { return FeatureCollection() }
        let coordinatesAreInMeters = projection == .epsg3857

        let west = bbox.southWest.longitude
        let south = bbox.southWest.latitude
        let east = bbox.northEast.longitude
        let north = bbox.northEast.latitude

        let centerY = (south + north) / 2.0
        let centerX = (west + east) / 2.0

        let doubleCellMeters = cellSide * 2.0

        let cellWidth: Double
        let cellHeight: Double
        if coordinatesAreInMeters {
            cellWidth = doubleCellMeters
            cellHeight = doubleCellMeters
        }
        else {
            let xDistance = Coordinate3D(latitude: centerY, longitude: west)
                .distance(to: Coordinate3D(latitude: centerY, longitude: east))
            cellWidth = xDistance > 0.0 ? (doubleCellMeters / xDistance) * (east - west) : (east - west)

            let yDistance = Coordinate3D(latitude: south, longitude: centerX)
                .distance(to: Coordinate3D(latitude: north, longitude: centerX))
            cellHeight = yDistance > 0.0 ? (doubleCellMeters / yDistance) * (north - south) : (north - south)
        }

        let radius = cellWidth / 2.0

        let hexWidth = radius * 2.0
        let hexHeight = (sqrt(3.0) / 2.0) * cellHeight

        let boxWidth = east - west
        let boxHeight = north - south

        let xInterval = (3.0 / 4.0) * hexWidth
        let yInterval = hexHeight

        let xSpan = (boxWidth - hexWidth) / (hexWidth - radius / 2.0)
        guard xSpan.isFinite, xSpan >= 0.0 else { return FeatureCollection() }
        let xCount = Int(floor(xSpan))

        let xAdjust = (Double(xCount) * xInterval - radius / 2.0 - boxWidth) / 2.0 - radius / 2.0 + xInterval / 2.0

        let ySpan = (boxHeight - hexHeight) / hexHeight
        guard ySpan.isFinite, ySpan >= 0.0 else { return FeatureCollection() }
        let yCount = Int(floor(ySpan))

        var yAdjust = (boxHeight - Double(yCount) * hexHeight) / 2.0

        let hasOffsetY = Double(yCount) * hexHeight - boxHeight > hexHeight / 2.0
        if hasOffsetY {
            yAdjust -= hexHeight / 4.0
        }

        let angles = (0 ..< 6).map { i -> (cos: Double, sin: Double) in
            let angle = (2.0 * .pi / 6.0) * Double(i)
            return (cos(angle), sin(angle))
        }

        var results: [Feature] = []

        for x in 0 ... xCount {
            let isOdd = x % 2 == 1

            for y in 0 ... yCount {
                if y == 0, isOdd { continue }
                if y == 0, hasOffsetY { continue }

                let centerXPos = Double(x) * xInterval + west - xAdjust
                var centerYPos = Double(y) * yInterval + south + yAdjust

                if isOdd {
                    centerYPos -= hexHeight / 2.0
                }

                if triangles {
                    let triFeatures = HexGrid.hexTriangles(
                        centerX: centerXPos,
                        centerY: centerYPos,
                        rx: radius,
                        ry: cellHeight / 2.0,
                        angles: angles,
                        coordinatesAreInMeters: coordinatesAreInMeters)
                    for tri in triFeatures {
                        if let mask {
                            if mask.intersects(tri) {
                                results.append(Feature(tri))
                            }
                        }
                        else {
                            results.append(Feature(tri))
                        }
                    }
                }
                else {
                    let hex = HexGrid.hexagon(
                        centerX: centerXPos,
                        centerY: centerYPos,
                        rx: radius,
                        ry: cellHeight / 2.0,
                        angles: angles,
                        coordinatesAreInMeters: coordinatesAreInMeters)
                    if let mask {
                        if mask.intersects(hex) {
                            results.append(Feature(hex))
                        }
                    }
                    else {
                        results.append(Feature(hex))
                    }
                }
            }
        }

        return FeatureCollection(results)
    }

    // MARK: - Helpers

    private static func hexagon(
        centerX: Double,
        centerY: Double,
        rx: Double,
        ry: Double,
        angles: [(cos: Double, sin: Double)],
        coordinatesAreInMeters: Bool
    ) -> Polygon {
        let vertices = angles.map { angle in
            if coordinatesAreInMeters {
                Coordinate3D(x: centerX + rx * angle.cos, y: centerY + ry * angle.sin)
            }
            else {
                Coordinate3D(
                    latitude: centerY + ry * angle.sin,
                    longitude: centerX + rx * angle.cos)
            }
        }
        return Polygon(unchecked: [vertices + [vertices[0]]])
    }

    private static func hexTriangles(
        centerX: Double,
        centerY: Double,
        rx: Double,
        ry: Double,
        angles: [(cos: Double, sin: Double)],
        coordinatesAreInMeters: Bool
    ) -> [Polygon] {
        let center: Coordinate3D
        if coordinatesAreInMeters {
            center = Coordinate3D(x: centerX, y: centerY)
        }
        else {
            center = Coordinate3D(latitude: centerY, longitude: centerX)
        }
        let count = angles.count

        return (0 ..< count).map { i in
            let nextI = (i + 1) % count
            let p1: Coordinate3D
            let p2: Coordinate3D
            if coordinatesAreInMeters {
                p1 = Coordinate3D(x: centerX + rx * angles[i].cos, y: centerY + ry * angles[i].sin)
                p2 = Coordinate3D(x: centerX + rx * angles[nextI].cos, y: centerY + ry * angles[nextI].sin)
            }
            else {
                p1 = Coordinate3D(
                    latitude: centerY + ry * angles[i].sin,
                    longitude: centerX + rx * angles[i].cos)
                p2 = Coordinate3D(
                    latitude: centerY + ry * angles[nextI].sin,
                    longitude: centerX + rx * angles[nextI].cos)
            }
            return Polygon(unchecked: [[center, p1, p2, center]])
        }
    }

}
