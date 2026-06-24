#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: - Coordinate array cleaning

extension Array where Element == Coordinate3D {

    /// Removes redundant points from the coordinate array.
    ///
    /// - Parameters:
    ///   - removeDuplicates: Remove consecutive duplicate coordinates (default `true`).
    ///   - removeCollinear: Remove the middle point of three consecutive collinear points (default `false`).
    ///   - closeRing: If `true`, ensure the last coordinate equals the first (for polygon rings).
    ///   - openRing: If `true`, remove the closing duplicate when `last == first`.
    ///   - tolerance: Epsilon for coordinate equality and collinearity checks in meters (default `GISTool.equalityDelta`).
    /// - Returns: A cleaned copy of the array.
    public func cleaned(
        removeDuplicates: Bool = true,
        removeCollinear: Bool = false,
        closeRing: Bool = false,
        openRing: Bool = false,
        tolerance: CLLocationDistance = GISTool.equalityDelta
    ) -> [Coordinate3D] {
        // Convert meter tolerance to CRS units if coordinates are in degrees.
        // For 3857 and noSRID the coordinates are in meters already.
        let crsTolerance: Double = {
            guard let projection = first?.projection else { return tolerance }
            switch projection {
            case .epsg4326:
                return tolerance / 111_325.0
            case .epsg3857, .epsg4978, .noSRID:
                return tolerance
            }
        }()

        var result = self
        if removeDuplicates {
            result = CleanHelpers.deduplicate(result, tolerance: crsTolerance)
        }
        if removeCollinear {
            result = CleanHelpers.removeCollinearPoints(result, tolerance: crsTolerance)
        }

        if openRing, result.count >= 2 {
            if let first = result.first,
               let last = result.last,
               abs(first.longitude - last.longitude) <= crsTolerance,
               abs(first.latitude - last.latitude) <= crsTolerance
            {
                result.removeLast()
            }
        }

        if closeRing, result.count >= 2 {
            if let first = result.first,
               let last = result.last,
               abs(first.longitude - last.longitude) > crsTolerance
                || abs(first.latitude - last.latitude) > crsTolerance
            {
                result.append(first)
            }
        }

        return result
    }

}

// MARK: - LineString cleaning

extension LineString {

    /// Returns a copy with redundant coordinates removed.
    ///
    /// - Parameters:
    ///   - removeDuplicates: Remove consecutive duplicate coordinates (default `true`).
    ///   - removeCollinear: Remove the middle point of three consecutive collinear points (default `false`).
    ///   - gridSize: Snap coordinates to a grid of the given size before cleaning (default `nil`).
    /// - Returns: A cleaned copy.
    public func cleaned(
        removeDuplicates: Bool = true,
        removeCollinear: Bool = false,
        gridSize: Double? = nil
    ) -> LineString {
        var coords = self.coordinates
        if let gridSize {
            coords = coords.map { $0.snappedToGrid(tolerance: gridSize) }
        }
        coords = coords.cleaned(removeDuplicates: removeDuplicates, removeCollinear: removeCollinear)
        return LineString(unchecked: coords, calculateBoundingBox: boundingBox != nil)
    }

}

// MARK: - MultiLineString cleaning

extension MultiLineString {

    /// Returns a copy with redundant coordinates removed from each constituent line.
    public func cleaned(
        removeDuplicates: Bool = true,
        removeCollinear: Bool = false,
        gridSize: Double? = nil
    ) -> MultiLineString {
        let cleaned = lineStrings.map {
            $0.cleaned(
                removeDuplicates: removeDuplicates,
                removeCollinear: removeCollinear,
                gridSize: gridSize)
        }
        return MultiLineString(unchecked: cleaned, calculateBoundingBox: boundingBox != nil)
    }

}

// MARK: - Polygon cleaning

extension Polygon {

    /// Returns a copy with redundant coordinates removed from all rings.
    public func cleaned(
        removeDuplicates: Bool = true,
        removeCollinear: Bool = false,
        gridSize: Double? = nil
    ) -> Polygon {
        let coords: [[Coordinate3D]] = rings.map { ring in
            var cleaned = ring.coordinates.cleaned(
                removeDuplicates: removeDuplicates,
                removeCollinear: removeCollinear)
            if cleaned.count >= 3,
               cleaned.first != cleaned.last
            {
                cleaned.append(cleaned[0])
            }
            return cleaned
        }
        return Polygon(unchecked: coords, calculateBoundingBox: boundingBox != nil)
    }

}

// MARK: - MultiPolygon cleaning

extension MultiPolygon {

    /// Returns a copy with redundant coordinates removed from all rings.
    public func cleaned(
        removeDuplicates: Bool = true,
        removeCollinear: Bool = false,
        gridSize: Double? = nil
    ) -> MultiPolygon {
        let coords: [[[Coordinate3D]]] = polygons.map {
            $0.cleaned(
                removeDuplicates: removeDuplicates,
                removeCollinear: removeCollinear,
                gridSize: gridSize)
            .coordinates
        }
        return MultiPolygon(unchecked: coords, calculateBoundingBox: boundingBox != nil)
    }

}

// MARK: - Private helpers

private enum CleanHelpers {

    static func deduplicate(_ coords: [Coordinate3D], tolerance: Double) -> [Coordinate3D] {
        var result: [Coordinate3D] = []
        for coord in coords {
            if let last = result.last,
               abs(coord.longitude - last.longitude) <= tolerance,
               abs(coord.latitude - last.latitude) <= tolerance
            {
                continue
            }
            result.append(coord)
        }
        return result
    }

    static func removeCollinearPoints(_ coords: [Coordinate3D], tolerance: Double) -> [Coordinate3D] {
        guard coords.count >= 3 else { return coords }
        var result: [Coordinate3D] = [coords[0]]

        for i in 1..<(coords.count - 1) {
            let prev = result[result.count - 1]
            let curr = coords[i]
            let next = coords[i + 1]

            let cross = (curr.longitude - prev.longitude) * (next.latitude - curr.latitude)
                - (curr.latitude - prev.latitude) * (next.longitude - curr.longitude)

            if abs(cross) > tolerance {
                result.append(curr)
            }
        }

        result.append(coords[coords.count - 1])
        return result
    }

}
