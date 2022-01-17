#if !os(Linux)
import Foundation

func benchmark(title: String, block: () -> Void) {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    let time = CFAbsoluteTimeGetCurrent() - start

    print("\(title): \(time)s")
}
#endif
