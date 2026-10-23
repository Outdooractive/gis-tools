// MARK: - unaryUnion

extension MultiPolygon {

    /// Returns the union of all constituent polygons, dissolving overlaps
    /// into the minimal set of non-overlapping parts.
    ///
    /// All projections are supported. The internal union operates in
    /// EPSG:3857 for uniform Cartesian tolerances and projects the result back.
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
    /// All projections are supported. The internal union operates in
    /// EPSG:3857 for uniform Cartesian tolerances and projects the result back.
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

        // No overlaps or containment between distinct components.
        for i in polys.indices {
            for j in polys.indices where j > i {
                guard let firstBox = polys[i].boundingBox ?? polys[i].calculateBoundingBox(),
                      let secondBox = polys[j].boundingBox ?? polys[j].calculateBoundingBox(),
                      firstBox.intersects(secondBox)
                else { continue }

                if polys[i].isOverlapping(with: polys[j])
                    || polys[i].covers(polys[j])
                    || polys[j].covers(polys[i])
                {
                    return false
                }
            }
        }

        // The coverage must be edge-connected. Build components using shared
        // boundary segments; isolated polygons leave a gap.
        var parent = Array(polys.indices)

        func find(_ index: Int) -> Int {
            var index = index
            while parent[index] != index {
                parent[index] = parent[parent[index]]
                index = parent[index]
            }
            return index
        }

        func union(_ first: Int, _ second: Int) {
            let firstRoot = find(first)
            let secondRoot = find(second)
            if firstRoot != secondRoot {
                parent[secondRoot] = firstRoot
            }
        }

        for i in polys.indices {
            for j in polys.indices where j > i {
                if Self.shareEdge(polys[i], polys[j]) {
                    union(i, j)
                }
            }
        }

        let root = find(0)
        return polys.indices.allSatisfy { find($0) == root }
    }

    private static func shareEdge(_ first: Polygon, _ second: Polygon) -> Bool {
        for firstSegment in first.lineSegments {
            for secondSegment in second.lineSegments {
                let comparison = firstSegment.compare(
                    secondSegment,
                    tolerance: GISTool.equalityDelta)
                if comparison == .equal
                    || comparison == .thisOnOther
                    || comparison == .otherOnThis
                {
                    return true
                }
            }
        }
        return false
    }

}
