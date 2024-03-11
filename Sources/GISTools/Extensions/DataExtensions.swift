import Foundation

// MARK: Private

extension Data {

    /// Parses data from a hex string
    init?(hex: String) {
        guard hex.count > 0, hex.count.isMultiple(of: 2) else { return nil }

        let chars = hex.map { $0 }
        let bytes = stride(from: 0, to: chars.count, by: 2)
            .map { String(chars[$0]) + String(chars[$0 + 1]) }
            .compactMap { UInt8($0, radix: 16) }

        guard hex.count / bytes.count == 2 else { return nil }

        self.init(bytes)
    }

    var asUTF8EncodedString: String? {
        String(data: self, encoding: .utf8)
    }

    /// The data, or nil if it is empty
    var nilIfEmpty: Data? {
        guard !isEmpty else { return nil }
        return self
    }

}
