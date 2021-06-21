import Foundation

/// For coordinates in mercator projections
public struct CoordinateXY {

    public var x: Double
    public var y: Double
    public var z: Double?

    /// Linear referencing or whatever you want it to use for.
    public var m: Double?

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
