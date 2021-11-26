import Foundation

// MARK: Private

extension FixedWidthInteger {

    /// Execute the block *n* times
    func times(perform: () throws -> Void) rethrows {
        for _ in 0 ..< self {
            try perform()
        }
    }

}
