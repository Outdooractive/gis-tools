#if !os(Linux)
import CoreLocation
#endif
import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-line-chunk

extension LineString {

    /// Divides a *LineString* into chunks of a specified length.
    /// If the line is shorter than the segment length then the original line is returned.
    ///
    /// - Parameter segmentLength: How long to make each segment, in meters
    public func chunked(segmentLength: CLLocationDistance) -> MultiLineString {
        guard self.isValid, segmentLength > 0.0 else {
            return MultiLineString()
        }

        var lineStrings: [LineString] = []

        let lineLength = self.length
        if lineLength < segmentLength {
            return MultiLineString([self]) ?? MultiLineString()
        }

        let numberOfSegments = Int(ceil(lineLength / segmentLength))
        for index in 0 ..< numberOfSegments {
            guard let chunk = sliceAlong(startDistance: segmentLength * Double(index), stopDistance: segmentLength * Double(index + 1)) else { break }
            lineStrings.append(chunk)
        }

        return MultiLineString(lineStrings) ?? MultiLineString()
    }

    /// Divides a *LineString* into evenly spaced segments of a specified length.
    /// If the line is shorter than the segment length then the original line is returned.
    ///
    /// - Parameter segmentLength: How long to make each segment, in meters
    public func evenlyDivided(segmentLength: CLLocationDistance) -> LineString {
        guard self.isValid, segmentLength > 0.0 else {
            return LineString()
        }

        return LineString(chunked(segmentLength: segmentLength).lineSegments) ?? self
    }

}

extension MultiLineString {

    /// Divides a *MultiLineString* into chunks of a specified length.
    /// If any line is shorter than the segment length then the original line is returned.
    ///
    /// - Parameter segmentLength: How long to make each segment, in meters
    public func chunked(segmentLength: CLLocationDistance) -> MultiLineString {
        MultiLineString(lineStrings.flatMap({ $0.chunked(segmentLength: segmentLength).lineStrings })) ?? self
    }

    /// Divides a *MultiLineString* into evenly spaced segments of a specified length.
    /// If the line is shorter than the segment length then the original line is returned.
    ///
    /// - Parameter segmentLength: How long to make each segment, in meters
    public func evenlyDivided(segmentLength: CLLocationDistance) -> MultiLineString {
        MultiLineString(lineStrings.map({
            LineString($0.chunked(segmentLength: segmentLength).lineSegments) ?? $0
        })) ?? self
    }

}

extension Feature {

    /// Divides a *Feature* containing a *LineString* or *MultiLineString*
    /// into a *FeatureCollection* of chunks of a specified length.
    /// If any line is shorter than the segment length then the original line is returned.
    ///
    /// - Parameter segmentLength: How long to make each segment, in meters
    public func chunked(segmentLength: CLLocationDistance) -> FeatureCollection {
        var features: [Feature]

        switch self.geometry {
        case let lineString as LineString:
            features = lineString.chunked(segmentLength: segmentLength).lineStrings.map({ Feature($0, id: id, properties: properties) })

        case let multiLineString as MultiLineString:
            features = multiLineString.chunked(segmentLength: segmentLength).lineStrings.map({ Feature($0, id: id, properties: properties) })

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
    public func chunked(segmentLength: CLLocationDistance) -> FeatureCollection {
        var newFeatures: [Feature] = []

        for feature in features {
            newFeatures.append(contentsOf: feature.chunked(segmentLength: segmentLength).features)
        }

        return FeatureCollection(newFeatures)
    }

}
