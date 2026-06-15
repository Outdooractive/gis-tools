#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension BoundingBox {

    /// Returns a *Coordinate* guaranteed to be on the surface of the bounding box.
    /// - Parameter from: The reference coordinate
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func nearestCoordinateOnFeature(
        from other: Coordinate3D,
        gridSize: Double? = nil
    ) -> (coordinate: Coordinate3D, distance: CLLocationDistance)? {
        let other = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let snappedGeometry = gridSize.map { self.boundingBoxGeometry.snappedToGrid(tolerance: $0) } ?? self.boundingBoxGeometry
        if self.contains(other) {
            return (coordinate: other, distance: 0.0)
        }
        return snappedGeometry.nearestCoordinateOnFeature(from: other)
    }

    /// Returns a *Point* guaranteed to be on the surface of the bounding box.
    /// - Parameter from: The reference point
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func nearestPointOnFeature(
        from other: Point,
        gridSize: Double? = nil
    ) -> (point: Point, distance: CLLocationDistance)? {
        self.nearestCoordinateOnFeature(from: other.coordinate, gridSize: gridSize).map {
            (point: Point($0.coordinate), distance: $0.distance)
        }
    }

}

extension GeoJson {

    /// Returns a *Point* guaranteed to be on the surface of the feature.
    /// - Parameter from: The reference point
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func nearestPointOnFeature(
        from other: Point,
        gridSize: Double? = nil
    ) -> (point: Point, distance: CLLocationDistance)? {
        if let nearest = nearestCoordinateOnFeature(from: other.coordinate, gridSize: gridSize) {
            return (point: Point(nearest.coordinate), distance: nearest.distance)
        }
        return nil
    }

    /// Returns a *Coordinate* guaranteed to be on the surface of the feature.
    /// - Parameter from: The reference coordinate
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    public func nearestCoordinateOnFeature(
        from other: Coordinate3D,
        gridSize: Double? = nil
    ) -> (coordinate: Coordinate3D, distance: CLLocationDistance)? {
        let geoJson = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        let other = gridSize.map { other.snappedToGrid(tolerance: $0) } ?? other
        let otherProjected = other.projected(to: geoJson.projection)

        switch geoJson {
        case let point as Point:
            return (coordinate: point.coordinate, distance: point.coordinate.distance(from: otherProjected))

        case let multiPoint as MultiPoint:
            return multiPoint.nearestCoordinate(from: otherProjected)

        case let lineString as LineString:
            return nearest(onSegments: lineString.lineSegments, from: otherProjected)

        case let multiLineString as MultiLineString:
            return nearest(onSegments: multiLineString.lineSegments, from: otherProjected)

        case let polygon as Polygon:
            if polygon.contains(otherProjected) {
                return (coordinate: otherProjected, distance: 0.0)
            }
            return nearest(onSegments: polygon.lineSegments, from: otherProjected)

        case let multiPolygon as MultiPolygon:
            if multiPolygon.contains(otherProjected) {
                return (coordinate: otherProjected, distance: 0.0)
            }
            return nearest(onSegments: multiPolygon.lineSegments, from: otherProjected)

        case let geometryCollection as GeometryCollection:
            return nearest(onGeometries: geometryCollection.geometries, from: otherProjected)

        case let feature as Feature:
            return feature.geometry.nearestCoordinateOnFeature(from: otherProjected)

        case let featureCollection as FeatureCollection:
            return nearest(onGeometries: featureCollection.features.map(\.geometry), from: otherProjected)

        default:
            return nil
        }
    }

    private func nearest(
        onSegments segments: [LineSegment],
        from other: Coordinate3D
    ) -> (coordinate: Coordinate3D, distance: CLLocationDistance)? {
        var bestCandidate: Coordinate3D?
        var bestDistance: CLLocationDistance = Double.greatestFiniteMagnitude

        for segment in segments {
            let nearest = segment.nearestCoordinateOnSegment(from: other)
            if nearest.distance < bestDistance {
                bestCandidate = nearest.coordinate
                bestDistance = nearest.distance
            }
        }

        guard let bestCandidate = bestCandidate else { return nil }
        return (coordinate: bestCandidate, distance: bestDistance)
    }

    private func nearest(
        onGeometries geometries: [GeoJsonGeometry],
        from other: Coordinate3D
    ) -> (coordinate: Coordinate3D, distance: CLLocationDistance)? {
        var bestCandidate: Coordinate3D?
        var bestDistance: CLLocationDistance = Double.greatestFiniteMagnitude

        for geometry in geometries {
            if let nearest = geometry.nearestCoordinateOnFeature(from: other),
               nearest.distance < bestDistance
            {
                bestCandidate = nearest.coordinate
                bestDistance = nearest.distance
            }
        }

        guard let bestCandidate = bestCandidate else { return nil }
        return (coordinate: bestCandidate, distance: bestDistance)
    }

}
