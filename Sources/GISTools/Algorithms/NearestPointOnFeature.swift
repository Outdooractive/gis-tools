#if !os(Linux)
import CoreLocation
#endif
import Foundation

extension BoundingBox {

    /// Returns a *Coordinate* guaranteed to be on the surface of the bounding box.
    public func nearestCoordinateOnFeature(
        from other: Coordinate3D)
        -> (coordinate: Coordinate3D, distance: CLLocationDistance)?
    {
        if self.contains(other) {
            return (coordinate: other, distance: 0.0)
        }
        return self.boundingBoxPolygon.nearestCoordinateOnFeature(from: other)
    }

    /// Returns a *Point* guaranteed to be on the surface of the bounding box.
    public func nearestPointOnFeature(
        from other: Point)
        -> (point: Point, distance: CLLocationDistance)?
    {
        if self.contains(other.coordinate) {
            return (point: other, distance: 0.0)
        }
        return self.boundingBoxPolygon.nearestPointOnFeature(from: other)
    }

}

extension GeoJson {

    /// Returns a *Point* guaranteed to be on the surface of the feature.
    public func nearestPointOnFeature(
        from other: Point)
        -> (point: Point, distance: CLLocationDistance)?
    {
        if let nearest = nearestCoordinateOnFeature(from: other.coordinate) {
            return (point: Point(nearest.coordinate), distance: nearest.distance)
        }
        return nil
    }

    /// Returns a *Coordinate* guaranteed to be on the surface of the feature.
    public func nearestCoordinateOnFeature(
        from other: Coordinate3D)
        -> (coordinate: Coordinate3D, distance: CLLocationDistance)?
    {
        let other = other.projected(to: projection)

        switch self {
        case let point as Point:
            return (coordinate: point.coordinate, distance: point.coordinate.distance(from: other))

        case let multiPoint as MultiPoint:
            return multiPoint.nearestCoordinate(from: other)

        case let lineString as LineString:
            return nearest(onSegments: lineString.lineSegments, from: other)

        case let multiLineString as MultiLineString:
            return nearest(onSegments: multiLineString.lineSegments, from: other)

        case let polygon as Polygon:
            if polygon.contains(other) {
                return (coordinate: other, distance: 0.0)
            }
            return nearest(onSegments: polygon.lineSegments, from: other)

        case let multiPolygon as MultiPolygon:
            if multiPolygon.contains(other) {
                return (coordinate: other, distance: 0.0)
            }
            return nearest(onSegments: multiPolygon.lineSegments, from: other)

        case let geometryCollection as GeometryCollection:
            return nearest(onGeometries: geometryCollection.geometries, from: other)

        case let feature as Feature:
            return feature.geometry.nearestCoordinateOnFeature(from: other)

        case let featureCollection as FeatureCollection:
            return nearest(onGeometries: featureCollection.features.map(\.geometry), from: other)

        default:
            return nil
        }
    }

    private func nearest(
        onSegments segments: [LineSegment],
        from other: Coordinate3D)
        -> (coordinate: Coordinate3D, distance: CLLocationDistance)?
    {
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
        from other: Coordinate3D)
        -> (coordinate: Coordinate3D, distance: CLLocationDistance)?
    {
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
