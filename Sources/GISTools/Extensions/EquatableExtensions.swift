//
//  Created by Thomas Rasch on 21.04.23.
//

import Foundation

// MARK: Private

extension Equatable {

    /// Returns ``true`` if the value is contained in the specified array.
    func isIn(_ c: [Self]) -> Bool {
        return c.contains(self)
    }

    /// Returns ``true`` if the value is not contained in the specified array.
    func isNotIn(_ c: [Self]) -> Bool {
        return !c.contains(self)
    }

}
