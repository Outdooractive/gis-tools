#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-line-chunk

extension LineString {

    /// Divides a *LineString* into chunks of a specified length.
    /// If the line is shorter than the segment length then the original line is returned.
    ///
    /// - Parameter segmentLength: How long to make each segment, in meters
    /// - Parameter dropIntermediateCoordinates: Simplify the result so that each chunk has exactly two coordinates
    ///
    /// - Returns: The chunked line segments.
    public func chunked(
        segmentLength: CLLocationDistance,
        dropIntermediateCoordinates: Bool = false
    ) -> MultiLineString {
        guard self.isValid, segmentLength > 0.0 else {
            return MultiLineString()
        }

        var lineStrings: [LineString] = []

        let lineLength = self.length
        if lineLength < segmentLength {
            return MultiLineString([self]) ?? MultiLineString()
        }

        let numberOfSegments = Int(ceil(lineLength / segmentLength))
        var startDistance: CLLocationDistance = 0.0
        for _ in 0 ..< numberOfSegments {
            let stopDistance = startDistance + segmentLength
            guard let chunk = sliceAlong(startDistance: startDistance, stopDistance: stopDistance) else { break }

            if dropIntermediateCoordinates,
               let newChunk = LineString([chunk.firstCoordinate, chunk.lastCoordinate].compactMap({ $0 }))
            {
                lineStrings.append(newChunk)
            }
            else {
                lineStrings.append(chunk)
            }

            startDistance = stopDistance
        }

        return MultiLineString(lineStrings) ?? MultiLineString()
    }

    /// Divides a *LineString* into evenly spaced segments of a specified length.
    /// If the line is shorter than the segment length then the original line is returned.
    ///
    /// - Parameter segmentLength: How long to make each segment, in meters
    /// - Parameter dropIntermediateCoordinates: Simplify the result so that each chunk has exactly two coordinates
    ///
    /// - Returns: An evenly divided line string.
    public func evenlyDivided(
        segmentLength: CLLocationDistance,
        dropIntermediateCoordinates: Bool = false
    ) -> LineString {
        guard self.isValid, segmentLength > 0.0 else {
            return LineString()
        }

        return LineString(chunked(segmentLength: segmentLength, dropIntermediateCoordinates: dropIntermediateCoordinates).lineSegments) ?? self
    }

}

extension MultiLineString {

    /// Divides a *MultiLineString* into chunks of a specified length.
    /// If any line is shorter than the segment length then the original line is returned.
    ///
    /// - Parameter segmentLength: How long to make each segment, in meters
    /// - Parameter dropIntermediateCoordinates: Simplify the result so that each chunk has exactly two coordinates
    ///
    /// - Returns: The chunked multi-line segments.
    public func chunked(
        segmentLength: CLLocationDistance,
        dropIntermediateCoordinates: Bool = false
    ) -> MultiLineString {
        MultiLineString(lineStrings.flatMap({
            $0.chunked(segmentLength: segmentLength, dropIntermediateCoordinates: dropIntermediateCoordinates).lineStrings
        })) ?? self
    }

    /// Divides a *MultiLineString* into evenly spaced segments of a specified length.
    /// If the line is shorter than the segment length then the original line is returned.
    ///
    /// - Parameter segmentLength: How long to make each segment, in meters
    /// - Parameter dropIntermediateCoordinates: Simplify the result so that each chunk has exactly two coordinates
    ///
    /// - Returns: An evenly divided multi-line string.
    public func evenlyDivided(
        segmentLength: CLLocationDistance,
        dropIntermediateCoordinates: Bool = false
    ) -> MultiLineString {
        MultiLineString(lineStrings.map({
            LineString($0.chunked(segmentLength: segmentLength, dropIntermediateCoordinates: dropIntermediateCoordinates).lineSegments) ?? $0
        })) ?? self
    }

}

extension Feature {

    /// Divides a *Feature* containing a *LineString* or *MultiLineString*
    /// into a *FeatureCollection* of chunks of a specified length.
    /// If any line is shorter than the segment length then the original line is returned.
    ///
    /// - Parameter segmentLength: How long to make each segment, in meters
    /// - Parameter dropIntermediateCoordinates: Simplify the result so that each chunk has exactly two coordinates
    ///
    /// - Returns: A FeatureCollection of chunked line segments.
    public func chunked(
        segmentLength: CLLocationDistance,
        dropIntermediateCoordinates: Bool = false
    ) -> FeatureCollection {
        var features: [Feature]

        switch self.geometry {
        case let lineString as LineString:
            features = lineString.chunked(segmentLength: segmentLength, dropIntermediateCoordinates: dropIntermediateCoordinates).lineStrings.map({ Feature($0, id: id, properties: properties) })

        case let multiLineString as MultiLineString:
            features = multiLineString.chunked(segmentLength: segmentLength, dropIntermediateCoordinates: dropIntermediateCoordinates).lineStrings.map({ Feature($0, id: id, properties: properties) })

        default:
            features = [self]
        }

        return FeatureCollection(features)
    }

}

extension FeatureCollection {

    /// Returns a *FeatureCollection* containing a *LineString* or *MultiLineString* chunked into smaller parts.
    ///
    /// - Parameter segmentLength: How long to make each segment, in meters
    /// - Parameter dropIntermediateCoordinates: Simplify the result so that each chunk has exactly two coordinates
    ///
    /// - Returns: A FeatureCollection of chunked line segments.
    public func chunked(
        segmentLength: CLLocationDistance,
        dropIntermediateCoordinates: Bool = false
    ) -> FeatureCollection {
        var newFeatures: [Feature] = []

        for feature in features {
            newFeatures.append(contentsOf: feature.chunked(segmentLength: segmentLength, dropIntermediateCoordinates: dropIntermediateCoordinates).features)
        }

        return FeatureCollection(newFeatures)
    }

}
