import Foundation

// MARK: - Make Valid

extension GeoJson {

    /// Repairs an invalid geometry, returning a valid geometry of the same type if possible.
    ///
    /// For polygons, this:
    /// 1. Removes duplicate and collinear points
    /// 2. Closes open rings
    /// 3. Splits self-intersecting rings into simple rings
    /// 4. Fixes ring orientation (outer CCW, inner CW per GeoJSON spec)
    /// 5. If splitting produces multiple components, returns the largest one
    ///
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before processing.
    /// - Returns: A valid geometry of the same type, or `nil` if repair is impossible.
    public func madeValid(
        gridSize: Double? = nil
    ) -> Self? {
        switch self {
        case let point as Point:
            return point as? Self

        case let multiPoint as MultiPoint:
            return multiPoint as? Self

        case let lineString as LineString:
            return lineString.madeValidLineString(gridSize: gridSize) as? Self

        case let multiLineString as MultiLineString:
            return multiLineString.madeValidMultiLineString(gridSize: gridSize) as? Self

        case let polygon as Polygon:
            return MakeValid.makeValid(polygon, gridSize: gridSize) as? Self

        case let multiPolygon as MultiPolygon:
            let valid = multiPolygon.polygons.compactMap { MakeValid.makeValid($0, gridSize: gridSize) }
            guard valid.isNotEmpty else { return nil }
            let result = MultiPolygon(unchecked: valid, calculateBoundingBox: multiPolygon.boundingBox != nil)
            return result as? Self

        case let geometryCollection as GeometryCollection:
            let valid = geometryCollection.geometries.compactMap { $0.madeValid(gridSize: gridSize) }
            let result = GeometryCollection(valid, calculateBoundingBox: geometryCollection.boundingBox != nil)
            return result as? Self

        case let feature as Feature:
            guard let validGeometry = feature.geometry.madeValid(gridSize: gridSize) else { return nil }
            var newFeature = Feature(
                validGeometry,
                id: feature.id,
                properties: feature.properties,
                calculateBoundingBox: feature.boundingBox != nil)
            newFeature.foreignMembers = feature.foreignMembers
            return newFeature as? Self

        case let featureCollection as FeatureCollection:
            let valid = featureCollection.features.compactMap { $0.madeValid(gridSize: gridSize) }
            guard valid.isNotEmpty else { return nil }
            var newCollection = FeatureCollection(
                valid,
                calculateBoundingBox: featureCollection.boundingBox != nil)
            newCollection.foreignMembers = featureCollection.foreignMembers
            return newCollection as? Self

        default:
            return self
        }
    }

}

// MARK: - Private helpers

extension LineString {

    fileprivate func madeValidLineString(gridSize: Double? = nil) -> LineString {
        cleaned(removeDuplicates: true, removeCollinear: false, gridSize: gridSize)
    }

}

extension MultiLineString {

    fileprivate func madeValidMultiLineString(gridSize: Double? = nil) -> MultiLineString {
        cleaned(removeDuplicates: true, removeCollinear: false, gridSize: gridSize)
    }

}

// MARK: - Private

private enum MakeValid {

    /// Repair a single polygon.
    static func makeValid(
        _ polygon: Polygon,
        gridSize: Double? = nil
    ) -> Polygon? {
        // 1. Clean: deduplicate, close rings
        let cleaned = polygon.cleaned(removeDuplicates: true, removeCollinear: false, gridSize: gridSize)

        // 2. Unkink: split self-intersecting rings into simple polygons
        let unkinked = cleaned.unkinked(gridSize: gridSize)
        guard unkinked.isNotEmpty else {
            let rewinded = cleaned.withWindingOrder(.counterClockwise)
            return rewinded.isValid ? rewinded : nil
        }

        // 3. Fix winding order on each result
        let valid = unkinked.compactMap { p -> Polygon? in
            let r = p.withWindingOrder(.counterClockwise)
            return r.isValid ? r : nil
        }
        guard valid.isNotEmpty else {
            let rewinded = cleaned.withWindingOrder(.counterClockwise)
            return rewinded.isValid ? rewinded : nil
        }

        // 4. Return the largest valid polygon (discards slivers from splitting)
        return valid.max(by: { $0.area < $1.area })
    }

}
