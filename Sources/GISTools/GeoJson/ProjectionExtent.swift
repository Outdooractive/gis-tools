
/// The valid extent of a projection.
///
/// Coordinates inside the extent are within the projection's usable range;
/// ``Coordinate3D/isValid`` and ``Coordinate3D/clamped()`` use it.
public struct ProjectionExtent:
    Hashable,
    Sendable
{

    /// The smallest x (easting/longitude) value.
    public let minX: Double
    /// The smallest y (northing/latitude) value.
    public let minY: Double
    /// The largest x (easting/longitude) value.
    public let maxX: Double
    /// The largest y (northing/latitude) value.
    public let maxY: Double

    public init(
        minX: Double,
        minY: Double,
        maxX: Double,
        maxY: Double
    ) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }

}
