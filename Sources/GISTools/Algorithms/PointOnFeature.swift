#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-point-on-feature

extension GeoJson {

    /// Returns a *Point* guaranteed to be on the surface of the feature.
    public var pointOnFeature: Point? {
        if let coordinate = coordinateOnFeature() {
            return Point(coordinate)
        }
        return nil
    }

    /// Returns a *Coordinate3D* guaranteed to be on the surface of the feature.
    public var coordinateOnFeature: Coordinate3D? {
        coordinateOnFeature(failOnMiss: false)
    }

    /// Returns a *Point* guaranteed to be on the surface of the feature.
    /// - Parameter gridSize: A grid size to snap coordinates to before computing the point on feature.
    public func pointOnFeature(gridSize: Double? = nil) -> Point? {
        if let coordinate = coordinateOnFeature(failOnMiss: false, gridSize: gridSize) {
            return Point(coordinate)
        }
        return nil
    }

    /// Returns a *Coordinate3D* guaranteed to be on the surface of the feature.
    /// - Parameter gridSize: A grid size to snap coordinates to before computing the coordinate on feature.
    public func coordinateOnFeature(gridSize: Double? = nil) -> Coordinate3D? {
        coordinateOnFeature(failOnMiss: false, gridSize: gridSize)
    }

    private func coordinateOnFeature(failOnMiss: Bool = false, gridSize: Double? = nil) -> Coordinate3D? {
        let geoJson = gridSize.map { self.snappedToGrid(tolerance: $0) } ?? self
        guard let centroidCoordinate = geoJson.centroid?.coordinate else { return nil }

        switch geoJson {
        case let point as Point:
            return point.coordinate

        case let multiPoint as MultiPoint:
            for coordinate in multiPoint.coordinates {
                if coordinate == centroidCoordinate {
                    return centroidCoordinate
                }
            }

        case let lineString as LineString:
            for segment in lineString.lineSegments {
                if segment.checkIsOnSegment(centroidCoordinate) {
                    return centroidCoordinate
                }
            }

        case let multiLineString as MultiLineString:
            for segment in multiLineString.lineSegments {
                if segment.checkIsOnSegment(centroidCoordinate) {
                    return centroidCoordinate
                }
            }

        case let polygon as Polygon:
            if polygon.crossesAntimeridian {
                // Shift negative longitudes to [0, 360) so the polygon is
                // contiguous and the centroid/contains check works correctly.
                let normalizedRings = polygon.coordinates.map { ring in
                    ring.map { coord in
                        Coordinate3D(
                            latitude: coord.latitude,
                            longitude: coord.longitude < 0.0 ? coord.longitude + 360.0 : coord.longitude)
                    }
                }
                let normalized = Polygon(unchecked: normalizedRings, calculateBoundingBox: false)
                if let coordinate = normalized.coordinateOnFeature(failOnMiss: true, gridSize: nil) {
                    var result = coordinate
                    if result.longitude > 180.0 {
                        result.longitude -= 360.0
                    }
                    return result
                }
            }
            else if polygon.contains(centroidCoordinate) {
                return centroidCoordinate
            }

        case let multiPolygon as MultiPolygon:
            if multiPolygon.polygons.contains(where: { $0.crossesAntimeridian }) {
                // Normalize each polygon that crosses the antimeridian
                let normalized = MultiPolygon(unchecked: multiPolygon.polygons.map { polygon in
                    guard polygon.crossesAntimeridian else { return polygon }
                    let normalizedRings = polygon.coordinates.map { ring in
                        ring.map { coord in
                            Coordinate3D(
                                latitude: coord.latitude,
                                longitude: coord.longitude < 0.0 ? coord.longitude + 360.0 : coord.longitude)
                        }
                    }
                    return Polygon(unchecked: normalizedRings, calculateBoundingBox: false)
                })
                if let coordinate = normalized.coordinateOnFeature(failOnMiss: true, gridSize: nil) {
                    var result = coordinate
                    if result.longitude > 180.0 {
                        result.longitude -= 360.0
                    }
                    return result
                }
            }
            else if multiPolygon.contains(centroidCoordinate) {
                return centroidCoordinate
            }

        case let geometryCollection as GeometryCollection:
            for geometry in geometryCollection.geometries {
                if let coordinate = geometry.coordinateOnFeature(failOnMiss: true, gridSize: nil) {
                    return coordinate
                }
            }

        case let feature as Feature:
            return feature.geometry.coordinateOnFeature(gridSize: nil)

        case let featureCollection as FeatureCollection:
            for feature in featureCollection.features {
                if let coordinate = feature.geometry.coordinateOnFeature(failOnMiss: true, gridSize: nil) {
                    return coordinate
                }
            }

        default:
            break
        }

        if failOnMiss {
            return nil
        }

        return nearestCoordinate(from: centroidCoordinate)?.coordinate
    }

}
