#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-boolean-disjoint

extension GeoJson {

    /// Compares two geometries and returns true if they are disjoint.
    ///
    /// - Parameters:
    ///    - other: The other geometry
    ///
    /// - Returns: *true* if the geometries don't overlap, *false* otherwise.
    public func isDisjoint(with other: GeoJson) -> Bool {
        if let otherBoundingBox = other.boundingBox ?? other.calculateBoundingBox(),
           !intersects(otherBoundingBox)
        {
            return true
        }

        return switch self {
        case let point as PointGeometry:
            point.isPointDisjoint(with: other)

        case let lineString as LineStringGeometry:
            lineString.isLineStringDisjoint(with: other)

        case let polygon as PolygonGeometry:
            polygon.isPolygonDisjoint(with: other)

        case let geometryCollection as GeometryCollection:
            geometryCollection.geometries.allSatisfy { $0.isDisjoint(with: other) }

        case let feature as Feature:
            feature.geometry.isDisjoint(with: other)

        case let featureCollection as FeatureCollection:
            featureCollection.features.allSatisfy { $0.isDisjoint(with: other) }

        default:
            true
        }
    }

}

// MARK: - Private helpers

extension PointGeometry {

    fileprivate func isPointDisjoint(with other: GeoJson) -> Bool {
        let other = other.projected(to: projection)

        switch other {
        case let otherPoint as PointGeometry:
            for coordinate in allCoordinates {
                if otherPoint.allCoordinates.contains(coordinate) {
                    return false
                }
            }

        case let otherLineString as LineStringGeometry:
            for coordinate in allCoordinates {
                if otherLineString.checkIsOnLine(coordinate) {
                    return false
                }
            }

        case let otherPolygon as PolygonGeometry:
            for coordinate in allCoordinates {
                if otherPolygon.contains(coordinate, ignoreBoundary: false) {
                    return false
                }
            }

        case let otherGeometryCollection as GeometryCollection:
            return otherGeometryCollection.geometries.allSatisfy { $0.isDisjoint(with: self) }

        case let otherFeature as Feature:
            return otherFeature.geometry.isDisjoint(with: self)

        case let otherFeatureCollection as FeatureCollection:
            return otherFeatureCollection.features.allSatisfy { $0.isDisjoint(with: self) }

        default:
            return true
        }

        return true
    }

}

extension LineStringGeometry {

    private func intersects(_ other: LineStringGeometry) -> Bool {
        let other = other.projected(to: projection)

        for lineSegment in lineSegments {
            for otherLineSegment in other.lineSegments {
                if lineSegment.intersects(otherLineSegment) {
                    return true
                }
            }
        }

        return false
    }

    fileprivate func isLineStringDisjoint(with other: GeoJson) -> Bool {
        let other = other.projected(to: projection)

        switch other {
        case let otherPoint as PointGeometry:
            for lineString in lineStrings {
                guard otherPoint.isDisjoint(with: lineString) else {
                    return false
                }
            }

        case let otherLineString as LineStringGeometry:
            for lineString in lineStrings {
                if lineString.intersects(otherLineString) {
                    return false
                }
            }

        case let otherPolygon as PolygonGeometry:
            // Any point inside the polygon
            for coordinate in allCoordinates {
                if otherPolygon.contains(coordinate, ignoreBoundary: false) {
                    return false
                }
            }

            // Any line crosses the polygon
            for lineString in lineStrings {
                for otherLineString in otherPolygon.polygons.compactMap(\.outerRing?.lineString) {
                    if lineString.intersects(otherLineString) {
                        return false
                    }
                }
            }

        case let otherGeometryCollection as GeometryCollection:
            return otherGeometryCollection.geometries.allSatisfy { $0.isDisjoint(with: self) }

        case let otherFeature as Feature:
            return otherFeature.geometry.isDisjoint(with: self)

        case let otherFeatureCollection as FeatureCollection:
            return otherFeatureCollection.features.allSatisfy { $0.isDisjoint(with: self) }

        default:
            return true
        }

        return true
    }

}

extension PolygonGeometry {

    fileprivate func isPolygonDisjoint(with other: GeoJson) -> Bool {
        let other = other.projected(to: projection)

        switch other {
        case let otherPoint as PointGeometry:
            for polygon in polygons {
                guard otherPoint.isDisjoint(with: polygon) else {
                    return false
                }
            }

        case let otherLineString as LineStringGeometry:
            for polygon in polygons {
                guard otherLineString.isDisjoint(with: polygon) else {
                    return false
                }
            }

        case let otherPolygon as PolygonGeometry:
            // Any point inside the polygon
            for polygon in polygons {
                guard let coordinates = polygon.outerRing?.coordinates else {
                    continue
                }

                for coordinate in coordinates {
                    if otherPolygon.contains(coordinate, ignoreBoundary: false) {
                        return false
                    }
                }
            }

            for polygon in otherPolygon.polygons {
                guard let coordinates = polygon.outerRing?.coordinates else {
                    continue
                }

                for coordinate in coordinates {
                    if self.contains(coordinate, ignoreBoundary: false) {
                        return false
                    }
                }
            }

            // Any line crosses the polygon
            for polygon in polygons {
                guard let lineString = polygon.outerRing?.lineString else {
                    continue
                }
                guard lineString.isDisjoint(with: otherPolygon) else {
                    return false
                }
            }

        case let otherGeometryCollection as GeometryCollection:
            return otherGeometryCollection.geometries.allSatisfy { $0.isDisjoint(with: self) }

        case let otherFeature as Feature:
            return otherFeature.geometry.isDisjoint(with: self)

        case let otherFeatureCollection as FeatureCollection:
            return otherFeatureCollection.features.allSatisfy { $0.isDisjoint(with: self) }

        default:
            return true
        }

        return true
    }

}
