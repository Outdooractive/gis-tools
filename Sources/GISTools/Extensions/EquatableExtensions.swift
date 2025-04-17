//
//  Created by Thomas Rasch on 21.04.23.
//

import Foundation

// MARK: Private

extension Equatable {

    func isIn(_ c: [Self]) -> Bool {
        return c.contains(self)
    }

    func isNotIn(_ c: [Self]) -> Bool {
        return !c.contains(self)
    }

}
