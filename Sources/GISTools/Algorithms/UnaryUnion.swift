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
