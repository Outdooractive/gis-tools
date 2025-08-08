#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// Line end styles for GeoJSON buffer.
public enum BufferLineEndStyle: Sendable {

    /// Line ends will be flat.
    case flat

    /// Line ends will be rounded.
    case round

}

/// Options for how to form an union of polygons.
public enum BufferUnionType: Sendable {

    /// Don't form a union from all geometries that make a buffer.
    case none

    /// Combine the buffered parts for each input geometry into one Polygon.
    case individual

    /// Combine all overlapping buffered geometries.
    case overlapping

}

extension GeoJson {

    // TODO: Antimeridian Cutting
    // TODO: formUnion
    // TODO: Negative distance?

    /// Returns the receiver with a buffer.
    ///
    /// - Parameters:
    ///    - distance: The buffer distance, in meters
    ///    - lineEndStyle: Controls how line ends will be drawn (default round)
    ///    - unionType: How to combine buffered geometries (default individual)
    ///    - steps: The number of steps for the circles (default 64)
    public func buffered(
        by distance: Double,
        lineEndStyle: BufferLineEndStyle = .round,
        unionType: BufferUnionType = .individual,
        steps: Int = 64
    ) -> MultiPolygon? {
        guard distance > 0.0 else { return nil }

        switch self {
        // Point
        case let point as Point:
            guard let circle = point.circle(radius: distance, steps: steps) else { return nil }
            return MultiPolygon([circle])

        // MultiPoint
        case let multiPoint as MultiPoint:
            let bufferedPoints = multiPoint
                .points
                .compactMap({ $0.circle(radius: distance, steps: steps) })
            guard bufferedPoints.isNotEmpty else { return nil }

            if unionType == .overlapping {
                return UnionHelper.union(polygons: bufferedPoints)
            }

            return MultiPolygon(bufferedPoints)

        // LineString
        case let lineString as LineString:
            var polygons = lineString
                .lineSegments
                .compactMap({
                    $0.buffered(
                        by: distance,
                        lineEndStyle: .flat,
                        unionType: .none)?
                    .polygons
                    .first
                })

            var bufferCoordinates = lineString.coordinates
            guard bufferCoordinates.count >= 2 else {
                return MultiPolygon(polygons)
            }

            if lineEndStyle == .flat {
                bufferCoordinates.removeFirst()
                bufferCoordinates.removeLast()
            }

            for coordinate in bufferCoordinates {
                guard let circle = coordinate.circle(radius: distance, steps: steps) else { continue }
                polygons.append(circle)
            }

            if unionType.isIn([.individual, .overlapping]) {
                return UnionHelper.union(polygons: polygons)
            }

            return MultiPolygon(polygons)

        // MultiLineString
        case let multiLineString as MultiLineString:
            let bufferedLineStrings = multiLineString
                .lineStrings
                .compactMap({
                    $0.buffered(
                        by: distance,
                        lineEndStyle: lineEndStyle,
                        unionType: unionType,
                        steps: steps)
                })
                .map(\.polygons)
                .flatMap({ $0 })
            guard bufferedLineStrings.isNotEmpty else { return nil }

            if unionType == .overlapping {
                return UnionHelper.union(polygons: bufferedLineStrings)
            }

            return MultiPolygon(bufferedLineStrings)

        // Polygon
        case let polygon as Polygon:
            let bufferCoordinates = polygon.allCoordinates
            guard bufferCoordinates.count >= 2 else { return nil }

            var polygons = polygon
                .lineSegments
                .compactMap({
                    $0.buffered(
                        by: distance,
                        lineEndStyle: .flat,
                        unionType: .none)?
                    .polygons
                    .first
                })

            for coordinate in bufferCoordinates {
                guard let circle = coordinate.circle(radius: distance, steps: steps) else { continue }
                polygons.append(circle)
            }

            polygons.append(polygon)

            if unionType.isIn([.individual, .overlapping]) {
                return UnionHelper.union(polygons: polygons)
            }

            return MultiPolygon(polygons)

        // MultiPolygon
        case let multiPolygon as MultiPolygon:
            let bufferedPolygons = multiPolygon
                .polygons
                .compactMap({
                    $0.buffered(
                        by: distance,
                        lineEndStyle: lineEndStyle,
                        unionType: unionType,
                        steps: steps)
                })
                .map(\.polygons)
                .flatMap({ $0 })
            guard bufferedPolygons.isNotEmpty else { return nil }

            if unionType == .overlapping {
                return UnionHelper.union(polygons: bufferedPolygons)
            }

            return MultiPolygon(bufferedPolygons)

        // GeometryCollection
        case let geometryCollection as GeometryCollection:
            let bufferedPolygons = geometryCollection
                .geometries
                .compactMap({
                    $0.buffered(
                        by: distance,
                        lineEndStyle: lineEndStyle,
                        unionType: unionType,
                        steps: steps)?
                    .polygons
                })
                .flatMap({ $0 })
            guard bufferedPolygons.isNotEmpty else { return nil }

            if unionType == .overlapping {
                return UnionHelper.union(polygons: bufferedPolygons)
            }

            return MultiPolygon(bufferedPolygons)

        // Feature
        case let feature as Feature:
            return feature.geometry.buffered(
                by: distance,
                lineEndStyle: lineEndStyle,
                unionType: unionType,
                steps: steps)

        // FeatureCollection
        case let featureCollection as FeatureCollection:
            let bufferedPolygons = featureCollection
                .features
                .compactMap({
                    $0.geometry.buffered(
                        by: distance,
                        lineEndStyle: lineEndStyle,
                        unionType: unionType,
                        steps: steps)?
                    .polygons
                })
                .flatMap({ $0 })
            guard bufferedPolygons.isNotEmpty else { return nil }

            if unionType == .overlapping {
                return UnionHelper.union(polygons: bufferedPolygons)
            }

            return MultiPolygon(bufferedPolygons)

        // Can't happen
        default:
            return nil
        }
    }

}

extension LineSegment {

    /// Returns the line segment with a buffer.
    ///
    /// - Parameters:
    ///    - distance: The buffer distance, in meters
    ///    - lineEndStyle: Controls how line ends will be drawn (default round)
    ///    - unionType: Whether to combine all overlapping buffers into one Polygon (default true)
    ///    - steps: The number of steps for the circles (default 64)
    public func buffered(
        by distance: Double,
        lineEndStyle: BufferLineEndStyle = .round,
        unionType: BufferUnionType = .individual,
        steps: Int = 64
    ) -> MultiPolygon? {
        guard distance > 0.0 else { return nil }

        let firstBearing = self.bearing
        let leftBearing = (firstBearing - 90.0).truncatingRemainder(dividingBy: 360.0)
        let rightBearing = (firstBearing + 90.0).truncatingRemainder(dividingBy: 360.0)

        let corners = [
            first.destination(distance: distance, bearing: leftBearing),
            second.destination(distance: distance, bearing: leftBearing),
            second.destination(distance: distance, bearing: rightBearing),
            first.destination(distance: distance, bearing: rightBearing),
            first.destination(distance: distance, bearing: leftBearing),
        ]

        var polygons = [Polygon([corners])!]

        if lineEndStyle == .round,
           let firstCircle = first.circle(radius: distance, steps: steps),
           let secondCircle = second.circle(radius: distance, steps: steps)
        {
            polygons.append(firstCircle)
            polygons.append(secondCircle)
        }

        if unionType == .none {
            return MultiPolygon(polygons)
        }

        return UnionHelper.union(polygons: polygons)
    }

}
