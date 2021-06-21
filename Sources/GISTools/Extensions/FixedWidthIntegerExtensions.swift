import Foundation

extension FixedWidthInteger {

    /// Execute the block *n* times
    func times(perform: () throws -> Void) throws {
        for _ in 0 ..< self {
            try perform()
        }
    }

}
