#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: - Polygon

extension Polygon {

    /// Returns the maximum inscribed circle — the largest circle that fits
    /// entirely inside the polygon — as a ``Polygon`` approximation.
    ///
    /// The center is the pole of inaccessibility (the point farthest from
    /// the polygon boundary). The radius is the geodesic distance from that
    /// point to the nearest boundary segment.
    ///
    /// - Parameter precision: Precision in meters for the pole-of-inaccessibility search (default `1.0`).
    /// - Parameter steps: The number of steps to approximate the circle (default `64`, minimum `3`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``Polygon`` approximating the maximum inscribed circle, or `nil`.
    public func maximumInscribedCircle(
        precision: CLLocationDistance = 1.0,
        steps: Int = 64,
        gridSize: Double? = nil
    ) -> Polygon? {
        guard let radius = maximumInscribedRadius(precision: precision, gridSize: gridSize),
              radius > 0.0,
              let center = poleOfInaccessibility(precision: precision, gridSize: gridSize)
        else { return nil }

        guard var circle = center.coordinate.circle(radius: radius, steps: max(3, steps))
        else { return nil }

        // Ensure the result has the same projection as the input
        if circle.projection != projection {
            circle = Polygon(
                unchecked: circle.coordinates.map { $0.map { $0.projected(to: projection) } },
                calculateBoundingBox: circle.boundingBox != nil)
        }
        return circle
    }

    /// Returns the radius of the maximum inscribed circle in meters.
    ///
    /// - Parameter precision: Precision in meters for the pole-of-inaccessibility search (default `1.0`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: The radius in meters, or `nil` if the polygon has no outer ring.
    public func maximumInscribedRadius(
        precision: CLLocationDistance = 1.0,
        gridSize: Double? = nil
    ) -> CLLocationDistance? {
        guard let pole = poleOfInaccessibility(precision: precision, gridSize: gridSize) else { return nil }

        let segments = lineSegments
        guard segments.isNotEmpty else { return nil }

        return segments
            .map { $0.distanceFrom(coordinate: pole.coordinate) }
            .min()
    }

}

// MARK: - MultiPolygon

extension MultiPolygon {

    /// Returns the maximum inscribed circle across all constituent polygons.
    ///
    /// - Parameter precision: Precision in meters for the pole-of-inaccessibility search (default `1.0`).
    /// - Parameter steps: The number of steps to approximate the circle (default `64`, minimum `3`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: A ``Polygon`` approximating the largest maximum inscribed circle, or `nil`.
    public func maximumInscribedCircle(
        precision: CLLocationDistance = 1.0,
        steps: Int = 64,
        gridSize: Double? = nil
    ) -> Polygon? {
        polygons
            .compactMap { $0.maximumInscribedCircle(precision: precision, steps: steps, gridSize: gridSize) }
            .max(by: { $0.area < $1.area })
    }

    /// Returns the largest maximum inscribed radius across all constituent polygons.
    ///
    /// - Parameter precision: Precision in meters for the pole-of-inaccessibility search (default `1.0`).
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before computing (default `nil`).
    /// - Returns: The radius in meters, or `nil` if the multi-polygon is empty.
    public func maximumInscribedRadius(
        precision: CLLocationDistance = 1.0,
        gridSize: Double? = nil
    ) -> CLLocationDistance? {
        polygons
            .compactMap { $0.maximumInscribedRadius(precision: precision, gridSize: gridSize) }
            .max()
    }

}
