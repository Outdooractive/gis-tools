import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-line-merge

extension FeatureCollection {

    /// Merges connected LineStrings into longer LineStrings.
    ///
    /// Input features must be ``LineString`` or ``MultiLineString``. LineStrings
    /// that share an endpoint are merged into a single ``LineString``.
    ///
    /// At a junction with more than two incident lines, continuations are
    /// chosen by **angle**: the pair of segments that continues straightest is
    /// joined, leaving the branch as a separate line. The result is therefore
    /// independent of the input feature order (geometry-wise).
    ///
    /// Endpoints at `+extent` and `−extent` (the antimeridian for EPSG:4326,
    /// ±`originShift` for EPSG:3857) are treated as coincident.
    ///
    /// ## Metadata
    ///
    /// A merged line inherits the `id`, `properties` and foreign members of the
    /// **first input feature (in input order) that contributed a segment** to
    /// it. When one `MultiLineString` produces several merged lines, every
    /// result receives that feature's metadata. When several distinct features
    /// merge, the earliest feature wins; the other features' metadata is not
    /// copied.
    ///
    /// All projections are supported.
    ///
    /// - Returns: A ``FeatureCollection`` of ``LineString`` features.
    public func lineMerged() -> FeatureCollection {
        let result = LineMerge.merge(features: features, asMultiLineStrings: false)
        return FeatureCollection(result)
    }

}

// MARK: - Implementation

private enum LineMerge {

    /// Tolerance for treating two direction dot products as equal when
    /// selecting the straightest continuation at a junction.
    private static let parallelDotTolerance = 0.0000000001

    // MARK: - Model

    private enum End: Hashable {
        case start
        case end
    }

    private struct Occurrence: Hashable {
        let record: Int
        let end: End
    }

    private struct EndpointKey: Hashable {
        let x: Int64
        let y: Int64
    }

    private struct Record {
        let coordinates: [Coordinate3D]
        let featureIndex: Int
        let inputIndex: Int

        var start: Coordinate3D { coordinates[0] }
        var end: Coordinate3D { coordinates[coordinates.count - 1] }
    }

    // MARK: - Entry point

    static func merge(features: [Feature], asMultiLineStrings: Bool) -> [Feature] {
        var records: [Record] = []
        var recordFeatures: [Feature] = []

        for (featureIndex, feature) in features.enumerated() {
            if let lineString = feature.geometry as? LineString {
                appendRecord(
                    lineString.coordinates,
                    feature: feature,
                    featureIndex: featureIndex,
                    records: &records,
                    recordFeatures: &recordFeatures)
            }
            else if let multiLineString = feature.geometry as? MultiLineString {
                for lineString in multiLineString.lineStrings {
                    appendRecord(
                        lineString.coordinates,
                        feature: feature,
                        featureIndex: featureIndex,
                        records: &records,
                        recordFeatures: &recordFeatures)
                }
            }
        }

        guard records.isNotEmpty else { return [] }

        // Group the two endpoint occurrences of every record by their
        // quantized/wrapped coordinate.
        var occurrencesByNode: [EndpointKey: [Occurrence]] = [:]
        for recordIndex in records.indices {
            let record = records[recordIndex]
            occurrencesByNode[key(for: record.start), default: []].append(
                Occurrence(record: recordIndex, end: .start))
            occurrencesByNode[key(for: record.end), default: []].append(
                Occurrence(record: recordIndex, end: .end))
        }

        // Pair segment ends at each node from straightest to most bent. The
        // unmatched occurrence(s) at an odd/degree-3 junction become chain
        // ends, so a branch is not swallowed by a through route.
        var links: [Occurrence: Occurrence] = [:]
        for occurrences in occurrencesByNode.values {
            var remaining = occurrences
            while remaining.count >= 2 {
                var bestPair: (first: Occurrence, second: Occurrence)?
                var bestDot = Double.infinity

                for i in 0 ..< (remaining.count - 1) {
                    for j in (i + 1) ..< remaining.count {
                        let dot = directionDot(
                            remaining[i],
                            remaining[j],
                            records: records)
                        if dot < bestDot - LineMerge.parallelDotTolerance {
                            bestDot = dot
                            bestPair = (remaining[i], remaining[j])
                        }
                        else if abs(dot - bestDot) <= LineMerge.parallelDotTolerance,
                                let current = bestPair,
                                occurrenceOrderKey(remaining[i], records: records)
                                    < occurrenceOrderKey(current.first, records: records)
                        {
                            bestPair = (remaining[i], remaining[j])
                        }
                    }
                }

                guard let pair = bestPair else { break }
                remaining.removeAll { $0 == pair.first || $0 == pair.second }
                links[pair.first] = pair.second
                links[pair.second] = pair.first
            }
        }

        // Start open chains at the lexicographically smallest unmatched
        // endpoint, so reordering the input cannot flip or rotate them.
        var unmatched: [Occurrence] = occurrencesByNode.values.flatMap { occurrences in
            occurrences.filter { links[$0] == nil }
        }
        unmatched.sort {
            occurrenceOrderKey($0, records: records)
                < occurrenceOrderKey($1, records: records)
        }

        var visited: Set<Int> = []
        var chains: [[Int]] = []
        var orientations: [[End]] = []

        for start in unmatched where !visited.contains(start.record) {
            let chain = walk(
                from: start,
                entry: start.end,
                records: records,
                links: links,
                visited: &visited)
            if chain.records.isNotEmpty {
                chains.append(chain.records)
                orientations.append(chain.entries)
            }
        }

        // Remaining records are closed cycles.
        for recordIndex in records.indices where !visited.contains(recordIndex) {
            let chain = walk(
                from: Occurrence(record: recordIndex, end: .start),
                entry: .start,
                records: records,
                links: links,
                visited: &visited)
            if chain.records.isNotEmpty {
                chains.append(chain.records)
                orientations.append(chain.entries)
            }
        }

        var result: [Feature] = []
        for (chainIndex, indices) in chains.enumerated() {
            let entries = orientations[chainIndex]
            guard let coordinates = mergeCoordinates(
                indices,
                entries: entries,
                records: records),
                coordinates.count >= 2,
                let lineString = LineString(coordinates)
            else { continue }

            let geometry: any GeoJsonGeometry = asMultiLineStrings
                ? MultiLineString(unchecked: [lineString])
                : lineString
            result.append(feature(for: geometry, indices: indices, records: records, features: recordFeatures))
        }

        return result
    }

    // MARK: - Construction

    private static func appendRecord(
        _ coordinates: [Coordinate3D],
        feature: Feature,
        featureIndex: Int,
        records: inout [Record],
        recordFeatures: inout [Feature]
    ) {
        guard coordinates.count >= 2 else { return }
        records.append(Record(
            coordinates: coordinates,
            featureIndex: featureIndex,
            inputIndex: records.count))
        recordFeatures.append(feature)
    }

    // MARK: - Endpoint keys

    private static func key(for coordinate: Coordinate3D) -> EndpointKey {
        var x = coordinate.x

        if let extent = coordinate.projection.wraparoundExtent, extent > 0.0 {
            let period = 2.0 * extent
            x = x.truncatingRemainder(dividingBy: period)
            if x <= -extent {
                x += period
            }
            if x > extent {
                x -= period
            }
        }

        return EndpointKey(
            x: Int64((x / GISTool.equalityDelta).rounded()),
            y: Int64((coordinate.y / GISTool.equalityDelta).rounded()))
    }

    /// Direction pointing away from the occurrence's node along its segment.
    private static func direction(
        _ occurrence: Occurrence,
        records: [Record]
    ) -> (x: Double, y: Double) {
        let coordinates = records[occurrence.record].coordinates
        switch occurrence.end {
        case .start:
            return (
                coordinates[1].x - coordinates[0].x,
                coordinates[1].y - coordinates[0].y)
        case .end:
            let last = coordinates.count - 1
            return (
                coordinates[last - 1].x - coordinates[last].x,
                coordinates[last - 1].y - coordinates[last].y)
        }
    }

    /// `dir1 · dir2`: −1 for a perfectly straight-through pair.
    private static func directionDot(
        _ first: Occurrence,
        _ second: Occurrence,
        records: [Record]
    ) -> Double {
        let a = direction(first, records: records)
        let b = direction(second, records: records)
        let lengthA = sqrt(a.x * a.x + a.y * a.y)
        let lengthB = sqrt(b.x * b.x + b.y * b.y)
        guard lengthA > 0.0, lengthB > 0.0 else { return .infinity }
        return (a.x * b.x + a.y * b.y) / (lengthA * lengthB)
    }

    /// Geometry-only tie-breaker: the other endpoint of the occurrence.
    private static func occurrenceOrderKey(
        _ occurrence: Occurrence,
        records: [Record]
    ) -> (Int64, Int64, Int64, Int64) {
        let record = records[occurrence.record]
        let other = occurrence.end == .start ? record.end : record.start
        let node = occurrence.end == .start ? record.start : record.end
        return (
            key(for: node).x,
            key(for: node).y,
            key(for: other).x,
            key(for: other).y)
    }

    // MARK: - Chain walking

    private static func walk(
        from start: Occurrence,
        entry: End,
        records: [Record],
        links: [Occurrence: Occurrence],
        visited: inout Set<Int>
    ) -> (records: [Int], entries: [End]) {
        var chainRecords: [Int] = []
        var entries: [End] = []
        var current = start
        var currentEntry = entry

        while !visited.contains(current.record) {
            visited.insert(current.record)
            chainRecords.append(current.record)
            entries.append(currentEntry)

            let exit: End = currentEntry == .start ? .end : .start
            let exitOccurrence = Occurrence(record: current.record, end: exit)
            guard let next = links[exitOccurrence] else { break }
            if visited.contains(next.record) { break }

            current = next
            currentEntry = next.end
        }

        return (chainRecords, entries)
    }

    /// Concatenates the oriented records, dropping the duplicated joint
    /// coordinate at every connection.
    private static func mergeCoordinates(
        _ indices: [Int],
        entries: [End],
        records: [Record]
    ) -> [Coordinate3D]? {
        guard indices.count == entries.count else { return nil }

        var coordinates: [Coordinate3D] = []

        for (position, index) in indices.enumerated() {
            let record = records[index]
            let sequence = entries[position] == .start
                ? record.coordinates
                : record.coordinates.reversed()

            if coordinates.isEmpty {
                coordinates = Array(sequence)
            }
            else {
                coordinates.append(contentsOf: sequence.dropFirst())
            }
        }

        // A closed chain ends with the same coordinate it started with; keep
        // the ring closure for a LineString, but drop a non-closing duplicate
        // caused by two records sharing an endpoint.
        if coordinates.count > 1,
           key(for: coordinates[0]) == key(for: coordinates[coordinates.count - 1]),
           key(for: coordinates[0]) != key(for: coordinates[1])
        {
            return coordinates
        }

        return normalizeOrientation(coordinates)
    }

    /// Deterministically orient a chain: start at the lexicographically
    /// smallest endpoint (and for a closed ring, rotate to the smallest
    /// coordinate with a deterministic direction).
    private static func normalizeOrientation(_ coordinates: [Coordinate3D]) -> [Coordinate3D] {
        guard coordinates.count >= 2 else { return coordinates }

        let first = coordinates[0]
        let last = coordinates[coordinates.count - 1]
        let closed = key(for: first) == key(for: last)

        if closed {
            let ring = Array(coordinates.dropLast())
            guard ring.count >= 3 else { return coordinates }

            let startIndex = ring.indices.min {
                (ring[$0].x, ring[$0].y) < (ring[$1].x, ring[$1].y)
            } ?? 0
            var rotated = Array(ring[startIndex...]) + Array(ring[..<startIndex])

            // Choose the direction with the lexicographically smaller second
            // coordinate so the result does not depend on the input order.
            if rotated.count >= 3,
               (rotated[1].x, rotated[1].y) > (rotated[rotated.count - 1].x, rotated[rotated.count - 1].y)
            {
                rotated = [rotated[0]] + Array(rotated.dropFirst().reversed())
            }
            return rotated + [rotated[0]]
        }

        if (first.x, first.y) > (last.x, last.y) {
            return coordinates.reversed()
        }
        return coordinates
    }

    // MARK: - Metadata

    private static func feature(
        for geometry: any GeoJsonGeometry,
        indices: [Int],
        records: [Record],
        features: [Feature]
    ) -> Feature {
        let featureIndex = indices
            .map { records[$0].featureIndex }
            .min() ?? 0
        let source = features[featureIndex]

        var feature = Feature(
            geometry,
            id: source.id,
            properties: source.properties)
        feature.foreignMembers = source.foreignMembers
        return feature
    }

}
