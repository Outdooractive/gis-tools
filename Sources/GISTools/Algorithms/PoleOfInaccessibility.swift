#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/mapbox/polylabel

extension Polygon {

    /// Finds the pole of inaccessibility — the most distant internal point
    /// from the polygon outline.
    ///
    /// Uses the polylabel algorithm with a priority-queue grid search.
    ///
    /// - Parameter precision: Precision in meters. Internally converted to CRS units
    ///   (degrees for ``Projection/epsg4326``, meters for ``Projection/epsg3857``).
    ///   Default `1.0`.
    /// - Parameter gridSize: An optional grid size for snapping inputs
    /// - Returns: The pole point, or `nil` if no outer ring exists.
    public func poleOfInaccessibility(precision: CLLocationDistance = 1.0, gridSize: Double? = nil) -> Point? {
        // Convert meter precision to CRS units
        let crsPrecision: Double = {
            switch projection {
            case .epsg4326, .epsg4978:
                return precision / 111_325.0
            case .epsg3857, .noSRID:
                return precision
            }
        }()

        let snappedSelf = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self

        guard let outerRing = snappedSelf.outerRing else { return nil }

        // The antimeridian cross check only makes sense for EPSG:4326.
        // For other projections the longitude values are not in degrees,
        // so a span > 180° does not indicate a date-line crossing.
        if projection == .epsg4326, snappedSelf.crossesAntimeridian {
            // Shift negative longitudes to [0, 360) so the polygon is
            // contiguous and the grid-search algorithm works correctly.
            let normalizedRings = snappedSelf.coordinates.map { ring in
                ring.map { coord in
                    Coordinate3D(
                        latitude: coord.latitude,
                        longitude: coord.longitude < 0.0 ? coord.longitude + 360.0 : coord.longitude)
                }
            }
            let normalized = Polygon(unchecked: normalizedRings, calculateBoundingBox: false)
            if let pole = normalized.poleOfInaccessibility(precision: precision, gridSize: nil) {
                var result = pole
                if result.coordinate.longitude > 180.0 {
                    result = Point(Coordinate3D(
                        latitude: result.coordinate.latitude,
                        longitude: result.coordinate.longitude - 360.0))
                }
                return result
            }
            return nil
        }

        let coords = outerRing.coordinates
        guard coords.count >= 4 else { return nil }

        // Bounding box
        var minX = Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var maxY = -Double.greatestFiniteMagnitude

        for coord in coords {
            let x = coord.longitude
            let y = coord.latitude
            if x < minX { minX = x }
            if y < minY { minY = y }
            if x > maxX { maxX = x }
            if y > maxY { maxY = y }
        }

        let width = maxX - minX
        let height = maxY - minY
        let cellSize = max(crsPrecision, min(width, height))

        if cellSize == crsPrecision {
            return Point(Coordinate3D(latitude: minY, longitude: minX))
        }

        var queue: [PQCell] = []
        var bestCell = snappedSelf.centroidCell()

        let bboxCell = PQCell(
            x: minX + width / 2,
            y: minY + height / 2,
            h: 0,
            polygon: snappedSelf)
        if bboxCell.d > bestCell.d {
            bestCell = bboxCell
        }

        // Cover with initial grid
        var h = cellSize / 2
        var x = minX
        while x < maxX {
            var y = minY
            while y < maxY {
                let cell = PQCell(
                    x: x + h,
                    y: y + h,
                    h: h,
                    polygon: snappedSelf)
                if cell.max > bestCell.d + crsPrecision {
                    insertSorted(&queue, cell)
                }
                if cell.d > bestCell.d {
                    bestCell = cell
                }
                y += cellSize
            }
            x += cellSize
        }

        while queue.isNotEmpty {
            let cell = queue.removeLast()

            if cell.max - bestCell.d <= crsPrecision {
                continue
            }
            if cell.d > bestCell.d {
                bestCell = cell
            }

            h = cell.h / 2

            let c1 = PQCell(x: cell.x - h, y: cell.y - h, h: h, polygon: snappedSelf)
            let c2 = PQCell(x: cell.x + h, y: cell.y - h, h: h, polygon: snappedSelf)
            let c3 = PQCell(x: cell.x - h, y: cell.y + h, h: h, polygon: snappedSelf)
            let c4 = PQCell(x: cell.x + h, y: cell.y + h, h: h, polygon: snappedSelf)

            for c in [c1, c2, c3, c4] {
                if c.d > bestCell.d {
                    bestCell = c
                }
                // Only insert if the child could meaningfully improve bestD.
                // The child's maximum reachable d is cell.d + cell.h/2 (moving
                // at most cell.h/2 toward the true optimum). If even that bound
                // is within precision of bestD, skip the insertion.
                if c.max > bestCell.d + crsPrecision,
                   cell.d + cell.h / 2.0 > bestCell.d - crsPrecision
                {
                    insertSorted(&queue, c)
                }
            }
        }

        return Point(Coordinate3D(latitude: bestCell.y, longitude: bestCell.x))
    }

    // MARK: - Private

    /// Insert into a max-sorted array (largest .max at end)
    private func insertSorted(
        _ queue: inout [PQCell],
        _ cell: PQCell)
    {
        var lo = 0
        var hi = queue.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if queue[mid].max < cell.max {
                lo = mid + 1
            }
            else {
                hi = mid
            }
        }
        queue.insert(cell, at: lo)
    }

    /// Signed distance from point to polygon outline (negative if outside).
    fileprivate func pointToPolygonDist(
        x: Double,
        y: Double,
        rings: [[Coordinate3D]]
    ) -> Double {
        var inside = false
        var minDistSq = Double.greatestFiniteMagnitude

        for ring in rings {
            guard ring.count >= 2 else { continue }
            for i in 0..<(ring.count - 1) {
                let a = ring[i]
                let b = ring[i + 1]

                if (a.latitude > y) != (b.latitude > y),
                    x < (b.longitude - a.longitude) * (y - a.latitude) / (b.latitude - a.latitude) + a.longitude
                {
                    inside = !inside
                }

                minDistSq = min(minDistSq, segDistSq(px: x, py: y, a: a, b: b))
            }
        }

        if minDistSq == 0 {
            return 0
        }
        return (inside ? 1 : -1) * sqrt(minDistSq)
    }

    /// Squared distance from point to segment.
    private func segDistSq(
        px: Double,
        py: Double,
        a: Coordinate3D,
        b: Coordinate3D
    ) -> Double {
        var x = a.longitude
        var y = a.latitude
        let dx = b.longitude - x
        let dy = b.latitude - y

        if dx != 0 || dy != 0 {
            let t = ((px - x) * dx + (py - y) * dy) / (dx * dx + dy * dy)
            if t > 1 {
                x = b.longitude
                y = b.latitude
            }
            else if t > 0 {
                x += dx * t
                y += dy * t
            }
        }

        let ex = px - x
        let ey = py - y
        return ex * ex + ey * ey
    }

    /// Polygon centroid (outer ring area centroid).
    private func centroidCell() -> PQCell {
        let points = outerRing!.coordinates
        var area: Double = 0
        var cx: Double = 0
        var cy: Double = 0
        let n = points.count - 1

        for i in 0..<n {
            let a = points[i]
            let b = points[(i + 1) % n]
            let aLon = a.longitude
            let aLat = a.latitude
            let bLon = b.longitude
            let bLat = b.latitude
            let f = aLon * bLat - bLon * aLat
            cx += (aLon + bLon) * f
            cy += (aLat + bLat) * f
            area += f * 3
        }

        if area == 0 {
            return PQCell(
                x: points[0].longitude,
                y: points[0].latitude,
                h: 0,
                polygon: self)
        }

        let cell = PQCell(
            x: cx / area,
            y: cy / area,
            h: 0,
            polygon: self)
        if cell.d < 0 {
            return PQCell(
                x: points[0].longitude,
                y: points[0].latitude,
                h: 0,
                polygon: self)
        }
        return cell
    }

}

// MARK: - Priority queue cell

private struct PQCell {

    let x: Double
    let y: Double
    let h: Double
    let d: Double
    let max: Double

    init(x: Double,
         y: Double,
         h: Double,
         polygon: Polygon
    ) {
        self.x = x
        self.y = y
        self.h = h
        let rings = polygon.coordinates
        self.d = polygon.pointToPolygonDist(x: x, y: y, rings: rings)
        self.max = d + h * 1.4142135623730951 // √2
    }

}
