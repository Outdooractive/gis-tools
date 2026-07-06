import Foundation

// MARK: Private

extension String {

    /// Tries to convert a String to an Int
    ///
    /// Allowes code like `optionalString?.toInt()`
    var toInt: Int? {
        return Int(self)
    }

    /// Tries to convert a String to a Double
    ///
    /// Allowes code like `optionalString?.toDouble()`
    var toDouble: Double? {
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
    var nilIfEmpty: String? {
        guard !isEmpty else { return nil }
        return self
    }

    /// Encodes the string as UTF-8 data.
    var asUTF8EncodedData: Data? {
        self.data(using: .utf8)
    }

    /// Returns `true` when the string is not empty.
    @inlinable
    var isNotEmpty: Bool {
        !isEmpty
    }

    /// Returns a Boolean value indicating whether the string matches the given regular expression.
    ///
    /// Supports optional `/i` suffix for case-insensitive matching, similar to JavaScript.
    /// - Parameter regex: A regular expression pattern, optionally wrapped in `/` delimiters
    ///   with `/i` for case-insensitive matching.
    /// - Returns: `true` if the string matches the pattern, `false` otherwise.
    func matches(_ regex: String) -> Bool {
        var options: String.CompareOptions = .regularExpression

        var regex = regex
        if regex.hasPrefix("/") {
            regex.removeFirst()

            if regex.hasSuffix("/i") {
                options.insert(.caseInsensitive)
                regex.removeLast(2)
            }
            else if regex.hasSuffix("/") {
                regex.removeLast()
            }
        }

        return self.range(of: regex, options: options) != nil
    }

}
