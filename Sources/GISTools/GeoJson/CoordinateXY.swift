import Foundation

/// A coordinate in mercator projection.
public struct CoordinateXY: CustomStringConvertible, Sendable {

    /// The coordinates easting.
    public var x: Double
    /// The coordinates northing.
    public var y: Double
    /// The coordinates altitude.
    public var z: Double?

    /// Linear referencing or whatever you want it to use for.
    public var m: Double?

    public init(
        x: Double,
        y: Double,
        z: Double? = nil,
        m: Double? = nil)
    {
        self.x = x
        self.y = y
        self.z = z
        self.m = m
    }

    /// A textual representation of the receiver.
    public var description: String {
        var compontents: [String] = [
            "x: \(x)",
            "y: \(y)",
        ]
        if let altitude = z {
            compontents.append("z: \(altitude)")
        }
        if let m = m {
            compontents.append("m: \(m)")
        }
        return "CoordinateXY(\(compontents.joined(separator: ", ")))"
    }

}

extension CoordinateXY {

    /// Clamped to [[-20037508.342789244, -20037508.342789244], [20037508.342789244, 20037508.342789244]]
    public mutating func clamp() {
        self = self.clamped()
    }

    /// Clamped to [[-20037508.342789244, -20037508.342789244], [20037508.342789244, 20037508.342789244]]
    public func clamped() -> CoordinateXY {
        guard x < -Projection.originShift || x > Projection.originShift
                || y < -Projection.originShift || y > Projection.originShift
        else { return self }

        return CoordinateXY(
            x: min(Projection.originShift, max(-Projection.originShift, x)),
            y: min(Projection.originShift, max(-Projection.originShift, y)),
            z: z,
            m: m)
    }

}

extension CoordinateXY: Equatable {

    public static func == (
        lhs: CoordinateXY,
        rhs: CoordinateXY)
        -> Bool
    {
        return abs(lhs.x - rhs.x) < GISTool.equalityDelta
            && abs(lhs.y - rhs.y) < GISTool.equalityDelta
            && lhs.z == rhs.z
    }

}

extension CoordinateXY: Hashable {}
