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
