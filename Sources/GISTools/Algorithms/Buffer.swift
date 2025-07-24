#if !os(Linux)
import CoreLocation
#endif
import Foundation

/// Line end styles for ```GeoJson.buffered(by:lineEndStyle:steps:formUnion:)```.
public enum BufferLineEndStyle: Sendable {

    /// Line ends will be flat.
    case flat

    /// Line ends will be rounded.
    case round

}

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
            let circles = multiPoint
                .points
                .compactMap({ $0.circle(radius: distance, steps: steps) })
            guard circles.isNotEmpty else { return nil }

            if unionType == .overlapping {
                // TODO: formUnion
            }

            return MultiPolygon(circles)

        // LineString
        case let lineString as LineString:
            let bufferedSegments = lineString
                .lineSegments
                .compactMap({
                    $0.buffered(
                        by: distance,
                        lineEndStyle: .flat,
                        unionType: .none)?
                    .polygons
                    .first
                })
            guard var multiPolygon = MultiPolygon(bufferedSegments) else { return nil }

            var bufferCoordinates = lineString.coordinates
            guard bufferCoordinates.count >= 2 else { return multiPolygon }

            if lineEndStyle == .flat {
                bufferCoordinates.removeFirst()
                bufferCoordinates.removeLast()
            }

            for coordinate in bufferCoordinates {
                guard let circle = coordinate.circle(radius: distance, steps: steps) else { continue }
                multiPolygon.appendPolygon(circle)
            }

            if unionType.isIn([.individual, .overlapping]) {
                // TODO: formUnion
            }

            return multiPolygon

        // MultiLineString
        case let multiLineString as MultiLineString:
            let bufferedLines = multiLineString
                .lineStrings
                .compactMap({
                    $0.buffered(
                        by: distance,
                        lineEndStyle: lineEndStyle,
                        unionType: unionType,
                        steps: steps)
                })
            guard bufferedLines.isNotEmpty else { return nil }

            if unionType == .overlapping {
                // TODO: formUnion
            }

            return MultiPolygon(bufferedLines.map(\.polygons).flatMap({ $0 }))

        // Polygon
        case let polygon as Polygon:
            let bufferCoordinates = polygon.allCoordinates
            let bufferedSegments = polygon
                .lineSegments
                .compactMap({
                    $0.buffered(
                        by: distance,
                        lineEndStyle: .flat,
                        unionType: .none)?
                    .polygons
                    .first
                })
            guard bufferCoordinates.count >= 2,
                  var multiPolygon = MultiPolygon(bufferedSegments)
            else { return nil }

            for coordinate in bufferCoordinates {
                guard let circle = coordinate.circle(radius: distance, steps: steps) else { continue }
                multiPolygon.appendPolygon(circle)
            }

            multiPolygon.appendPolygon(polygon)

            if unionType.isIn([.individual, .overlapping]) {
                // TODO: formUnion
            }

            return multiPolygon

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
            guard bufferedPolygons.isNotEmpty else { return nil }

            if unionType == .overlapping {
                // TODO: formUnion
            }

            return MultiPolygon(bufferedPolygons.map(\.polygons).flatMap({ $0 }))

        // GeometryCollection
        case let geometryCollection as GeometryCollection:
            let bufferPolygons = geometryCollection
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
            guard bufferPolygons.isNotEmpty else { return nil }

            if unionType == .overlapping {
                // TODO: formUnion
            }

            return MultiPolygon(bufferPolygons)

        // Feature
        case let feature as Feature:
            return feature.geometry.buffered(
                by: distance,
                lineEndStyle: lineEndStyle,
                unionType: unionType,
                steps: steps)

        // FeatureCollection
        case let featureCollection as FeatureCollection:
            let bufferPolygons = featureCollection
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
            guard bufferPolygons.isNotEmpty else { return nil }

            if unionType == .overlapping {
                // TODO: formUnion
            }

            return MultiPolygon(bufferPolygons)

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
    ///    - steps: The number of steps for the circles (default 64)
    ///    - formUnion: Whether to combine all overlapping buffers into one Polygon (default true)
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

        guard var multiPolygon = MultiPolygon([[corners]]) else { return nil }

        if lineEndStyle == .round,
           let firstCircle = first.circle(radius: distance, steps: steps),
           let secondCircle = second.circle(radius: distance, steps: steps)
        {
            multiPolygon.appendPolygon(firstCircle)
            multiPolygon.appendPolygon(secondCircle)
        }

        if unionType.isIn([.individual, .overlapping]) {
            // TODO: formUnion
        }

        return multiPolygon
    }

}
