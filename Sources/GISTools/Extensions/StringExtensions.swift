import Foundation

extension String {

    /// Tries to convert a String to an Int
    ///
    /// Allowes code like `optionalString?.toInt()`
    func toInt() -> Int? {
        return Int(self)
    }

    /// Tries to convert a String to a Double
    ///
    /// Allowes code like `optionalString?.toDouble()`
    func toDouble() -> Double? {
        return Double(self)
    }

    /// Trims white space and new line characters
    mutating func trim() {
        self = self.trimmed()
    }

    /// Trims white space and new line characters, returns a new string
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The string, or nil if it is empty
    func nilIfEmpty() -> String? {
        guard !isEmpty else { return nil }
        return self
    }

}
