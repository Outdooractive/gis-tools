#if !os(Linux)
import CoreLocation
#endif
import Foundation

// MARK: - ScaleAnchor

// Ported from https://github.com/Turfjs/turf/blob/master/packages/turf-transform-scale

/// The anchor from where a scale operation takes place.
public enum ScaleAnchor: Sendable {
    case southWest
    case southEast
    case northWest
    case northEast
    case center
    case centroid
    case coordinate(Coordinate3D)
    case point(Point)
}

extension GeoJson {

    /// Scale the receiver from a given point by a factor of scaling (ex: factor=2 would make the
    /// GeoJSON 200% larger). If the receiver is a *FeatureCollection*, the origin point will
    /// be calculated based on each individual Feature.
    ///
    /// - Parameters:
    ///    - factor: The scaling factor, positive or negative
    ///    - anchor: The anchor from which the scaling will occur
    public func transformedScale(
        factor: Double,
        anchor: ScaleAnchor = .centroid)
        -> Self
    {
        guard factor != 1.0 else { return self }

        var originIsPoint = false
        if case .coordinate = anchor {
            originIsPoint = true
        }

        // Scale each Feature separately
        if let featureCollection = self as? FeatureCollection,
            !originIsPoint
        {
            var newFeatureCollection = FeatureCollection(
                featureCollection.features.map({ $0.scaled(factor: factor, anchor: anchor) }),
                calculateBoundingBox: (featureCollection.boundingBox != nil))
            newFeatureCollection.foreignMembers = featureCollection.foreignMembers
            return newFeatureCollection as! Self
        }

        return scaled(factor: factor, anchor: anchor)
    }

    /// Scale the receiver from a given point by a factor of scaling (ex: factor=2 would make the
    /// GeoJSON 200% larger). If the receiver is a *FeatureCollection*, the origin point will
    /// be calculated based on each individual Feature.
    ///
    /// - Parameters:
    ///    - factor: The scaling factor, positive or negative
    ///    - anchor: The anchor from which the scaling will occur
    public mutating func transformScale(
        factor: Double,
        anchor: ScaleAnchor = .centroid)
    {
        self = transformedScale(factor: factor, anchor: anchor)
    }

    // MARK: - Internal

    private func scaled(
        factor: Double,
        anchor: ScaleAnchor = .centroid)
        -> Self
    {
        guard let origin = defineOrigin(anchor: anchor) else { return self }

        return transformedCoordinates({ (coordinate) in
            let originalDistance = origin.rhumbDistance(from: coordinate)
            let bearing = origin.rhumbBearing(to: coordinate)
            let newDistance = originalDistance * factor

            var newCoordinate = origin.rhumbDestination(distance: newDistance, bearing: bearing)
            if let altitude = coordinate.altitude {
                newCoordinate.altitude = altitude * factor
            }
            return newCoordinate
        })
    }

    private func defineOrigin(anchor: ScaleAnchor) -> Coordinate3D? {
        switch anchor {
        case .southWest:
            guard let boundingBox = self.boundingBox ?? calculateBoundingBox() else { return nil }
            return boundingBox.southWest

        case .southEast:
            guard let boundingBox = self.boundingBox ?? calculateBoundingBox() else { return nil }
            return boundingBox.southEast

        case .northWest:
            guard let boundingBox = self.boundingBox ?? calculateBoundingBox() else { return nil }
            return boundingBox.northWest

        case .northEast:
            guard let boundingBox = self.boundingBox ?? calculateBoundingBox() else { return nil }
            return boundingBox.northEast

        case .center:
            return center?.coordinate

        case .centroid:
            return centroid?.coordinate

        case let .coordinate(coordinate):
            return coordinate.projected(to: projection)

        case let .point(point):
            return point.coordinate.projected(to: projection)
        }
    }

}
