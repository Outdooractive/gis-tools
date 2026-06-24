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

        if projection == .noSRID {
            var sum: Double = 0.0
            for i in 1 ..< coordinates.count {
                sum += (coordinates[i].longitude - coordinates[i - 1].longitude)
                    * (coordinates[i].latitude + coordinates[i - 1].latitude)
            }
            return sum > 0
        }

        let coords = if projection == .epsg4326 {
            coordinates
        }
        else {
            coordinates.map { $0.projected(to: .epsg4326) }
        }

        var sum: Double = 0.0
        for i in 1 ..< coords.count {
            let lon1 = coords[i - 1].longitude < 0
                ? coords[i - 1].longitude + 360.0
                : coords[i - 1].longitude
            let lon2 = coords[i].longitude < 0
                ? coords[i].longitude + 360.0
                : coords[i].longitude
            sum += ((lon2 - lon1) * (coords[i].latitude + coords[i - 1].latitude))
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
