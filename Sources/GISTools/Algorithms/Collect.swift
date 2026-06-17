import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-collect

extension FeatureCollection {

    /// Collects property values from points that fall within each polygon feature
    /// and adds them as an array property.
    ///
    /// For each polygon feature in the receiver, this finds all points from
    /// `pointCollection` that lie inside it and collects the value of
    /// `inProperty` from each matching point. The resulting array is stored
    /// as `outProperty` on the polygon feature.
    ///
    /// - Parameter pointCollection: A ``FeatureCollection`` of ``Point`` features
    /// - Parameter inProperty: The property key to collect from matching points
    /// - Parameter outProperty: The property key to store the collected array on each polygon feature
    /// - Parameter gridSize: Snap coordinates to a grid of the given size before checking (default `nil`).
    /// - Returns: A new ``FeatureCollection`` with the collected property added to each polygon feature
    public func collect(
        from pointCollection: FeatureCollection,
        inProperty: String,
        outProperty: String,
        gridSize: Double? = nil
    ) -> FeatureCollection {
        let pointFeatures = pointCollection.features

        var result: [Feature] = []
        result.reserveCapacity(features.count)

        for polygonFeature in features {
            guard let polygon = polygonFeature.geometry as? PolygonGeometry else {
                result.append(polygonFeature)
                continue
            }

            let collected: [Sendable] = pointFeatures.compactMap { pointFeature in
                guard let point = pointFeature.geometry as? Point,
                      polygon.contains(point.coordinate, ignoringBoundary: false, gridSize: gridSize)
                else { return nil }

                return pointFeature.properties[inProperty]
            }

            var updated = polygonFeature
            updated.setProperty(collected, for: outProperty)
            result.append(updated)
        }

        return FeatureCollection(result)
    }

}
