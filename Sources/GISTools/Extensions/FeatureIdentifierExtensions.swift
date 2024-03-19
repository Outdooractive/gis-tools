import Foundation

// MARK: Public

extension Feature.Identifier {

    public var int64Value: Int64? {
        switch self {
        case .int(let int): Int64(exactly: int)
        case .uint(let uint): Int64(exactly: uint)
        default: nil
        }
    }

    public var uint64Value: UInt64? {
        switch self {
        case .int(let int): UInt64(exactly: int)
        case .uint(let uint): UInt64(exactly: uint)
        default: nil
        }
    }

}
