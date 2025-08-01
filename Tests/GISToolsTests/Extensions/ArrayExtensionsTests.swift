@testable import GISTools
import Testing

struct ArrayExtensionsTests {

    @Test
    func distinctPairs() async throws {
        let even: [Int] = [1, 2, 3, 4, 5, 6]
        let uneven: [Int] = [1, 2, 3, 4, 5]

        let evenPairs = even.distinctPairs()
        let unevenPairs = uneven.distinctPairs()

        #expect(evenPairs.count == 3)
        #expect(unevenPairs.count == 2)

        #expect(evenPairs[0].first == 1)
        #expect(evenPairs[0].second == 2)
        #expect(evenPairs[1].first == 3)
        #expect(evenPairs[1].second == 4)
        #expect(evenPairs[2].first == 5)
        #expect(evenPairs[2].second == 6)

        #expect(unevenPairs[0].first == 1)
        #expect(unevenPairs[0].second == 2)
        #expect(unevenPairs[1].first == 3)
        #expect(unevenPairs[1].second == 4)
    }

    @Test
    func smallDistinctPairs() async throws {
        let empty: [Int] = []
        let small = [1]

        let emptyPairs = empty.distinctPairs()
        let smallPairs = small.distinctPairs()

        #expect(emptyPairs.count == 0)
        #expect(smallPairs.count == 1)
    }

    @Test
    func overlappingPairs() async throws {
        let even: [Int] = [1, 2, 3, 4, 5, 6]
        let uneven: [Int] = [1, 2, 3, 4, 5]

        let evenPairs = even.overlappingPairs()
        let unevenPairs = uneven.overlappingPairs()

        #expect(evenPairs.count == 5)
        #expect(unevenPairs.count == 4)

        #expect(evenPairs[0].first == 1)
        #expect(evenPairs[0].second == 2)
        #expect(evenPairs[1].first == 2)
        #expect(evenPairs[1].second == 3)
        #expect(evenPairs[2].first == 3)
        #expect(evenPairs[2].second == 4)
        #expect(evenPairs[3].first == 4)
        #expect(evenPairs[3].second == 5)
        #expect(evenPairs[4].first == 5)
        #expect(evenPairs[4].second == 6)

        #expect(unevenPairs[0].first == 1)
        #expect(unevenPairs[0].second == 2)
        #expect(unevenPairs[1].first == 2)
        #expect(unevenPairs[1].second == 3)
        #expect(evenPairs[2].first == 3)
        #expect(evenPairs[2].second == 4)
        #expect(evenPairs[3].first == 4)
        #expect(evenPairs[3].second == 5)
    }

    @Test
    func smallOverlappingPairs() async throws {
        let empty: [Int] = []
        let small = [1]

        let emptyPairs = empty.overlappingPairs()
        let smallPairs = small.overlappingPairs()

        #expect(emptyPairs.count == 0)
        #expect(smallPairs.count == 1)
    }

    @Test
    func get() async throws {
        let array = [0, 1, 2, 3, 4, 5, 6]

        #expect(array.get(at: 0) == 0)
        #expect(array.get(at: 4) == 4)
        #expect(array.get(at: -1) == 6)
        #expect(array.get(at: -5) == 2)

        #expect(array.get(at: 7) == nil)
        #expect(array.get(at: -8) == nil)
    }

}
