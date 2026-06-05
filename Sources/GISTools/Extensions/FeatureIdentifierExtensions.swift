import Foundation

// MARK: Public

extension Feature.Identifier {

    /// Returns the feature identifier as an ``Int64`` value, or ``nil`` if it cannot be represented.
    public var int64Value: Int64? {
        switch self {
        case .int(let int): Int64(exactly: int)
        case .uint(let uint): Int64(exactly: uint)
        default: nil
        }
    }

    /// Returns the feature identifier as a ``UInt64`` value, or ``nil`` if it cannot be represented.
    public var uint64Value: UInt64? {
        switch self {
        case .int(let int): UInt64(exactly: int)
        case .uint(let uint): UInt64(exactly: uint)
        default: nil
        }
    }

}
