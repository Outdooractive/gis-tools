import Foundation

extension UtmDefinition {

    /// The lowest latitude covered by the UTM grid.
    private static let minimumLatitude = -80.0

    /// The highest latitude covered by the UTM grid.
    private static let maximumLatitude = 84.0

    /// Returns the UTM zone containing the given WGS84 coordinate.
    ///
    /// Returns the *standard* EPSG zone (EPSG:326xx/327xx) selected by the
    /// coordinate's longitude, except in the two EPSG-defined regions where
    /// the banding deviates from the regular 6° grid:
    ///
    /// - **Norway** (56°N–64°N, 3°E–12°E): covered by zone 32 (the "32V"
    ///   exception) instead of zones 31/32 splitting the country.
    /// - **Svalbard** (72°N–84°N): 3°-wide zones 31/33/35/37 and the 9°-wide
    ///   zone 32 (the "31X/32X/33X/35X/37X" exceptions) keep the archipelago
    ///   and adjacent seas in whole zones.
    ///
    /// Coordinates on the antimeridian (±180°) select zone 1. Coordinates
    /// outside `−80° ≤ latitude ≤ 84°` lie in the Universal Polar
    /// Stereographic regions, which are outside the UTM grid, and return
    /// `nil`. Zone selection is a function of the coordinate's latitude and
    /// longitude values, so pass WGS84 coordinates when converting from
    /// another starting projection.
    ///
    /// The returned definition can be used directly for conversion via
    /// ``forward(_:)``/``inverse(_:)`` or through its ``Swift/Projection``.
    ///
    /// - Parameter coordinate: a WGS84 latitude/longitude coordinate
    /// - Returns: The zone definition containing the coordinate, or `nil`
    ///   for coordinates outside the UTM latitude range
    ///
    /// ## Example
    ///
    /// ```swift
    /// let oslo = Coordinate3D(latitude: 59.91149, longitude: 10.75793)
    /// let zone = UtmDefinition.zone(for: oslo)
    /// // zone?.zone == 32 (the Norwegian exception; standard banding would
    /// // return 31 at longitude 10°E)
    /// ```
    static func zone(for coordinate: Coordinate3D) -> UtmDefinition? {
        guard coordinate.latitude >= minimumLatitude,
              coordinate.latitude <= maximumLatitude
        else { return nil }

        // Normalize the longitude to the canonical [-180, 180) range; the
        // antimeridian (both +180 and -180) falls into zone 1.
        let shifted = coordinate.longitude + 180.0
        let longitudeNormalized = shifted - (floor(shifted / 360.0) * 360.0) - 180.0
        let latitude = coordinate.latitude

        // Regular 6° banding.
        var zone = Int((longitudeNormalized + 180.0) / 6.0) + 1

        // The EPSG "Norway" exception: the 56–64°N / 3–12°E sector is
        // covered entirely by zone 32.
        if latitude >= 56.0,
           latitude < 64.0,
           longitudeNormalized >= 3.0,
           longitudeNormalized < 12.0 {
            zone = 32
        }

        // The EPSG "Svalbard" exceptions: the 72–84°N band is re-banded
        // into 3° (zones 31/33/35/37) and 9° (zone 32) sectors.
        if latitude >= 72.0,
           latitude < 84.0 {
            if longitudeNormalized >= 0.0,
               longitudeNormalized < 9.0 {
                zone = 31
            }
            else if longitudeNormalized >= 9.0,
                    longitudeNormalized < 21.0 {
                zone = 33
            }
            else if longitudeNormalized >= 21.0,
                    longitudeNormalized < 33.0 {
                zone = 35
            }
            else if longitudeNormalized >= 33.0,
                    longitudeNormalized < 42.0 {
                zone = 37
            }
        }

        let hemisphere: UtmHemisphere = latitude >= 0.0 ? .north : .south
        return UtmDefinition(zone: zone, hemisphere: hemisphere)
    }

}

// MARK: - Projection

extension Projection {

    /// Returns the UTM zone projection containing the given WGS84 coordinate,
    /// using the EPSG banding including the Norway ("32V") and Svalbard
    /// ("31X/32X/33X/35X/37X") exceptions.
    ///
    /// See ``UtmDefinition/zone(for:)`` for the full documentation.
    ///
    /// - Parameter coordinate: a WGS84 latitude/longitude coordinate
    /// - Returns: The zone's projection, or `nil` for coordinates outside
    ///   the UTM latitude range (−80° to 84°)
    public static func utmZone(for coordinate: Coordinate3D) -> Projection? {
        UtmDefinition.zone(for: coordinate)?.projection
    }

}
