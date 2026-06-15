import Foundation

// Ported from https://github.com/Turfjs/turf/tree/master/packages/turf-sample

extension FeatureCollection {

    /// Returns a random subset of features from the collection.
    ///
    /// Uses the Fisher-Yates shuffle to select `size` features without replacement.
    ///
    /// - Parameter size: Number of features to select.
    /// - Returns: A new feature collection with `size` random features.
    /// - Precondition: `size` must be between 0 and the number of features in the collection.
    public func sample(size: Int) -> FeatureCollection {
        guard size > 0 else { return FeatureCollection() }

        let clampedSize = min(size, features.count)
        var shuffled = features
        for index in (shuffled.count - clampedSize ..< shuffled.count).reversed() {
            let randomIndex = Int.random(in: 0 ... index)
            shuffled.swapAt(index, randomIndex)
        }
        return FeatureCollection(Array(shuffled.suffix(clampedSize)))
    }

}
