import Foundation

// MARK: Private

extension Set {

    /// Converts the Set to an Array
    var asArray: [Element] {
        Array(self)
    }

    /// A Boolean value indicating whether the collection is not empty.
    var isNotEmpty: Bool {
        !isEmpty
    }

}
