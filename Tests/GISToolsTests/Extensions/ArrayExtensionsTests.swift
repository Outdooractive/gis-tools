@testable import GISTools
import XCTest

final class ArrayExtensionsTests: XCTestCase {

    func testDistinctPairs() {
        let even: [Int] = [1, 2, 3, 4, 5, 6]
        let uneven: [Int] = [1, 2, 3, 4, 5]

        let evenPairs = even.distinctPairs()
        let unevenPairs = uneven.distinctPairs()

        XCTAssertEqual(evenPairs.count, 3)
        XCTAssertEqual(unevenPairs.count, 2)

        XCTAssertEqual(evenPairs[0].first, 1)
        XCTAssertEqual(evenPairs[0].second, 2)
        XCTAssertEqual(evenPairs[1].first, 3)
        XCTAssertEqual(evenPairs[1].second, 4)
        XCTAssertEqual(evenPairs[2].first, 5)
        XCTAssertEqual(evenPairs[2].second, 6)

        XCTAssertEqual(unevenPairs[0].first, 1)
        XCTAssertEqual(unevenPairs[0].second, 2)
        XCTAssertEqual(unevenPairs[1].first, 3)
        XCTAssertEqual(unevenPairs[1].second, 4)
    }

    func testSmallDistinctPairs() {
        let empty: [Int] = []
        let small = [1]

        let emptyPairs = empty.distinctPairs()
        let smallPairs = small.distinctPairs()

        XCTAssertEqual(emptyPairs.count, 0)
        XCTAssertEqual(smallPairs.count, 0)
    }

    func testOverlappingPairs() {
        let even: [Int] = [1, 2, 3, 4, 5, 6]
        let uneven: [Int] = [1, 2, 3, 4, 5]

        let evenPairs = even.overlappingPairs()
        let unevenPairs = uneven.overlappingPairs()

        XCTAssertEqual(evenPairs.count, 5)
        XCTAssertEqual(unevenPairs.count, 4)

        XCTAssertEqual(evenPairs[0].first, 1)
        XCTAssertEqual(evenPairs[0].second, 2)
        XCTAssertEqual(evenPairs[1].first, 2)
        XCTAssertEqual(evenPairs[1].second, 3)
        XCTAssertEqual(evenPairs[2].first, 3)
        XCTAssertEqual(evenPairs[2].second, 4)
        XCTAssertEqual(evenPairs[3].first, 4)
        XCTAssertEqual(evenPairs[3].second, 5)
        XCTAssertEqual(evenPairs[4].first, 5)
        XCTAssertEqual(evenPairs[4].second, 6)

        XCTAssertEqual(unevenPairs[0].first, 1)
        XCTAssertEqual(unevenPairs[0].second, 2)
        XCTAssertEqual(unevenPairs[1].first, 2)
        XCTAssertEqual(unevenPairs[1].second, 3)
        XCTAssertEqual(evenPairs[2].first, 3)
        XCTAssertEqual(evenPairs[2].second, 4)
        XCTAssertEqual(evenPairs[3].first, 4)
        XCTAssertEqual(evenPairs[3].second, 5)
    }

    func testSmallOverlappingPairs() {
        let empty: [Int] = []
        let small = [1]

        let emptyPairs = empty.overlappingPairs()
        let smallPairs = small.overlappingPairs()

        XCTAssertEqual(emptyPairs.count, 0)
        XCTAssertEqual(smallPairs.count, 0)
    }

    func testGet() {
        let array = [0, 1, 2, 3, 4, 5, 6]

        XCTAssertEqual(array.get(at: 0), 0)
        XCTAssertEqual(array.get(at: 4), 4)
        XCTAssertEqual(array.get(at: -1), 6)
        XCTAssertEqual(array.get(at: -5), 2)

        XCTAssertNil(array.get(at: 7))
        XCTAssertNil(array.get(at: -8))
    }

    static var allTests = [
        ("testPairs", testDistinctPairs),
        ("testSmallPairs", testSmallDistinctPairs),
        ("testOverlappingPairs", testOverlappingPairs),
        ("testSmallOverlappingPairs", testSmallOverlappingPairs),
        ("testGet", testGet),
    ]

}
