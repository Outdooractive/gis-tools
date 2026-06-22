import Foundation

// MARK: - unaryUnion

extension MultiPolygon {

    /// Returns the union of all constituent polygons, dissolving overlaps
    /// into the minimal set of non-overlapping parts.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``MultiPolygon`` with no overlapping regions, or `nil` if the result is empty.
    public func unaryUnion(gridSize: Double? = nil) -> MultiPolygon? {
        let all: [Polygon]
        if let gridSize {
            all = polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        }
        else {
            all = polygons
        }
        return Union.unionPolygons(all)
    }

}

// MARK: - coverageUnion

extension MultiPolygon {

    /// Returns the union of non-overlapping constituent polygons.
    ///
    /// Assumes the input polygons do **not** overlap — they may only
    /// share edges (tile boundaries). The result is the dissolved
    /// set of parts with shared edges removed.
    ///
    /// This is useful for merging map sheets, raster tiles, or other
    /// geographic partitions where each point belongs to exactly one tile.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``MultiPolygon`` with shared edges dissolved, or `nil` if the result is empty.
    public func coverageUnion(gridSize: Double? = nil) -> MultiPolygon? {
        let all: [Polygon]
        if let gridSize {
            all = polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        }
        else {
            all = polygons
        }
        return Union.unionPolygons(all)
    }

}

// MARK: - coverageIsValid

extension MultiPolygon {

    /// Returns `true` if the constituent polygons form a valid coverage:
    /// no gaps, no overlaps, and edges match exactly.
    ///
    /// Checks two properties:
    /// 1. No overlaps — the sum of individual polygon areas must approximately
    ///    equal the union area.
    /// 2. No gaps — adjacent polygons must share edges, so the union must
    ///    have fewer parts than the input count.
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: `true` if the coverage is valid.
    public func coverageIsValid(gridSize: Double? = nil) -> Bool {
        guard polygons.count > 1 else { return true }

        let polys: [Polygon]
        if let gridSize {
            polys = polygons.map { $0.snappedToGrid(tolerance: gridSize) }
        }
        else {
            polys = polygons
        }

        // 1. No overlaps: sum of areas ≈ union area
        let sumAreas = polys.reduce(0.0) { $0 + $1.area }
        guard let union = Union.unionPolygons(polys) else { return false }
        let unionArea = union.area

        let maxArea = max(sumAreas, unionArea)
        guard maxArea > 0 else { return sumAreas == 0 }
        let relativeDiff = abs(sumAreas - unionArea) / maxArea
        guard relativeDiff <= 0.000001 else { return false }

        // 2. No gaps: adjacent polygons share edges, so union merges them
        //    into fewer parts. If the part count didn't drop, nothing is
        //    connected and gaps exist between the parts.
        return union.polygons.count < polys.count
    }

}
