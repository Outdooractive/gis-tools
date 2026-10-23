import Foundation

extension Ring {

    /// Check whether or not the ring is clockwise.
    ///
    /// For ``Projection/epsg3857`` and ``Projection/epsg4978`` the coordinates
    /// are projected to ``Projection/epsg4326`` first, then geographic winding
    /// is tested. For ``Projection/noSRID`` the raw 2-D shoelace formula
    /// (without antimeridian normalisation) is applied.
    ///
    /// - Returns: `true` if the ring is clockwise, `false` otherwise.
    public var isClockwise: Bool {
        guard coordinates.isNotEmpty else { return false }

        if !projection.hasSRID {
            var sum = 0.0
            for i in 1 ..< coordinates.count {
                sum += (coordinates[i].longitude - coordinates[i - 1].longitude)
                    * (coordinates[i].latitude + coordinates[i - 1].latitude)
            }
            return sum > 0
        }

        let coords =
            if projection.isGeographic {
                coordinates
            }
            else {
                coordinates.map { $0.projected(to: .epsg4326) }
            }

        // Unwrap only actual seam crossings. Shifting every negative
        // longitude breaks small rings around the prime meridian.
        var unwrappedLongitudes = coords.map(\.longitude)
        for index in 1 ..< unwrappedLongitudes.count {
            var longitude = coords[index].longitude
            while longitude - unwrappedLongitudes[index - 1] > 180.0 {
                longitude -= 360.0
            }
            while unwrappedLongitudes[index - 1] - longitude > 180.0 {
                longitude += 360.0
            }
            unwrappedLongitudes[index] = longitude
        }

        var sum = 0.0
        for i in 1 ..< coords.count {
            sum += ((unwrappedLongitudes[i] - unwrappedLongitudes[i - 1])
                * (coords[i].latitude + coords[i - 1].latitude))
        }

        return sum > 0
    }

    /// Check whether or not the ring is counter-clockwise.
    ///
    /// - Returns: `true` if the ring is counter-clockwise, `false` otherwise.
    public var isCounterClockwise: Bool {
        !isClockwise
    }

}
