//
//  Created by Thomas Rasch on 06.12.21.
//

import Foundation

func benchmark(title: String, block: () -> Void) {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    let time = CFAbsoluteTimeGetCurrent() - start
    print("\(title): \(time)s")
}
