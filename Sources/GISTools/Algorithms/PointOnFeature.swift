#if !os(Linux)
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

    private func coordinateOnFeature(failOnMiss: Bool = false) -> Coordinate3D? {
        guard let centroidCoordinate = centroid?.coordinate else { return nil }

        switch self {
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
            if polygon.contains(centroidCoordinate) {
                return centroidCoordinate
            }

        case let multiPolygon as MultiPolygon:
            if multiPolygon.contains(centroidCoordinate) {
                return centroidCoordinate
            }

        case let geometryCollection as GeometryCollection:
            for geometry in geometryCollection.geometries {
                if let coordinate = geometry.coordinateOnFeature(failOnMiss: true) {
                    return coordinate
                }
            }

        case let feature as Feature:
            return feature.geometry.coordinateOnFeature()

        case let featureCollection as FeatureCollection:
            for feature in featureCollection.features {
                if let coordinate = feature.geometry.coordinateOnFeature(failOnMiss: true) {
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
