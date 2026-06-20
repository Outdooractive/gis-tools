import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-line-merge

extension FeatureCollection {

    /// Merges connected LineStrings into longer LineStrings.
    ///
    /// Input features must be ``LineString`` or ``MultiLineString``. LineStrings
    /// that share an endpoint (same coordinate) are merged into a single
    /// ``LineString``.
    ///
    /// - Returns: A ``FeatureCollection`` of ``LineString`` features.
    public func lineMerged() -> FeatureCollection {
        let result = LineMerge.merge(features: features, asMultiLineStrings: false)
        return FeatureCollection(result)
    }

}

// MARK: - Implementation

private enum LineMerge {

    struct LineRecord {
        let coords: [Coordinate3D]
        let start: Coordinate3D
        let end: Coordinate3D
        let index: Int
    }

    static func merge(features: [Feature], asMultiLineStrings: Bool) -> [Feature] {
        // Collect all LineStrings
        var records: [LineRecord] = []
        for feature in features {
            if let ls = feature.geometry as? LineString {
                let coords = ls.coordinates
                guard coords.count >= 2 else { continue }
                records.append(LineRecord(
                    coords: coords,
                    start: coords.first!,
                    end: coords.last!,
                    index: records.count))
            }
            else if let mls = feature.geometry as? MultiLineString {
                for ls in mls.lineStrings {
                    let coords = ls.coordinates
                    guard coords.count >= 2 else { continue }
                    records.append(LineRecord(
                        coords: coords,
                        start: coords.first!,
                        end: coords.last!,
                        index: records.count))
                }
            }
        }

        guard records.isNotEmpty else { return [] }

        // Build adjacency: records are adjacent if they share an endpoint
        var adjacency: [Int: [Int]] = [:]
        for i in 0..<records.count {
            for j in (i + 1)..<records.count {
                let a = records[i]
                let b = records[j]
                if a.start.isCoincident(to: b.start) || a.start.isCoincident(to: b.end)
                    || a.end.isCoincident(to: b.start) || a.end.isCoincident(to: b.end)
                {
                    adjacency[i, default: []].append(j)
                    adjacency[j, default: []].append(i)
                }
            }
        }

        // Walk connected components via DFS
        var visited = Set<Int>()
        var mergedFeatures: [Feature] = []

        for startIdx in 0..<records.count where !visited.contains(startIdx) {
            var component: [Int] = []
            var stack = [startIdx]
            while stack.isNotEmpty {
                let current = stack.removeLast()
                guard !visited.contains(current) else { continue }
                visited.insert(current)
                component.append(current)
                for neighbor in adjacency[current, default: []] where !visited.contains(neighbor) {
                    stack.append(neighbor)
                }
            }

            // Merge component into one or more lines
            let merged = mergeComponent(component, records: records, asMultiLineStrings: asMultiLineStrings)
            for geo in merged {
                mergedFeatures.append(Feature(geo))
            }
        }

        return mergedFeatures
    }

    /// Merge a connected component into one or more lines.
    private static func mergeComponent(
        _ indices: [Int],
        records: [LineRecord],
        asMultiLineStrings: Bool
    ) -> [GeoJsonGeometry] {
        guard indices.isNotEmpty else { return [] }

        let sortedIndices = indices.sorted()
        var remaining = Set(sortedIndices)
        var chains: [[Int]] = []

        while remaining.isNotEmpty {
            // Pick the smallest remaining index for deterministic behavior
            let firstIdx = remaining.min()!
            remaining.remove(firstIdx)
            var chain: [Int] = [firstIdx]
            var changed = true
            while changed {
                changed = false
                let chainStart = records[chain.first!].start
                let chainEnd = records[chain.last!].end

                for candidate in remaining.sorted() {
                    let rec = records[candidate]
                    let matchesEnd = rec.start.isCoincident(to: chainEnd)
                        || rec.end.isCoincident(to: chainEnd)

                    if matchesEnd {
                        chain.append(candidate)
                        remaining.remove(candidate)
                        changed = true
                        break
                    }

                    let matchesStart = rec.start.isCoincident(to: chainStart)
                        || rec.end.isCoincident(to: chainStart)

                    if matchesStart {
                        chain.insert(candidate, at: 0)
                        remaining.remove(candidate)
                        changed = true
                        break
                    }
                }
            }
            chains.append(chain)
        }

        var result: [any GeoJsonGeometry] = []
        for chain in chains {
            if let merged = mergeChain(chain, records: records, asMultiLineString: asMultiLineStrings) {
                result.append(merged)
            }
            else {
                // Chain can't merge — emit individual lines
                for idx in chain {
                    let rec = records[idx]
                    if let ls = LineString(rec.coords) {
                        result.append(asMultiLineStrings
                            ? MultiLineString(unchecked: [ls])
                            : ls)
                    }
                }
            }
        }
        return result
    }

    /// Merge a single chain of records into a LineString or MultiLineString.
    private static func mergeChain(
        _ indices: [Int],
        records: [LineRecord],
        asMultiLineString: Bool
    ) -> (any GeoJsonGeometry)? {
        guard indices.isNotEmpty else { return nil }

        var allCoords: [Coordinate3D] = []

        // Start with the first record in the correct orientation
        let first = records[indices[0]]
        allCoords.append(contentsOf: first.coords)
        var currentEnd = allCoords.last!

        for i in 1..<indices.count {
            let rec = records[indices[i]]
            let forwardMatch = rec.start.isCoincident(to: currentEnd)
            let backwardMatch = rec.end.isCoincident(to: currentEnd)

            if forwardMatch {
                // Append all coords except the duplicate start
                allCoords.append(contentsOf: rec.coords.dropFirst())
                currentEnd = allCoords.last!
            }
            else if backwardMatch {
                // Append reversed coords except the duplicate end
                allCoords.append(contentsOf: rec.coords.reversed().dropFirst())
                currentEnd = allCoords.last!
            }
            else {
                // Not connected to current chain — this shouldn't happen
                // Start a new segment
                guard allCoords.count >= 2 else {
                    allCoords = rec.coords
                    currentEnd = allCoords.last!
                    continue
                }
                return nil
            }
        }

        guard allCoords.count >= 2 else { return nil }
        guard let ls = LineString(allCoords) else { return nil }
        return asMultiLineString
            ? MultiLineString(unchecked: [ls])
            : ls
    }

}
