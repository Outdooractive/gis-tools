#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

// MARK: Binary min-heap for graph algorithms

extension Graph {

    /// A `(distance, nodeIndex)` entry used as a heap element by Dijkstra and
    /// the algorithms that build on it (multi-criteria, betweenness,
    /// K-shortest-paths spur search).
    ///
    /// Ordered by distance, then by index for deterministic tie-breaking.
    struct HeapEntry: Comparable {

        let distance: Double
        let index: Int

        static func < (lhs: HeapEntry, rhs: HeapEntry) -> Bool {
            if lhs.distance != rhs.distance {
                return lhs.distance < rhs.distance
            }
            return lhs.index < rhs.index
        }

    }

    /// A simple binary min-heap.
    ///
    /// Not `Sendable`; intended only as a local scratch structure inside the
    /// graph's path-search algorithms. Push and pop are O(log n); `peek` is
    /// O(1). Element ordering follows the `Comparable` conformance of
    /// `Element`; ties are resolved by that conformance (e.g. index for
    /// ``HeapEntry``).
    struct MinHeap<Element: Comparable> {

        private var storage: [Element] = []

        var isEmpty: Bool {
            storage.isEmpty
        }

        /// The minimum element without removing it, or `nil` if empty.
        var peek: Element? {
            storage.isNotEmpty ? storage[0] : nil
        }

        mutating func push(_ element: Element) {
            storage.append(element)
            siftUp(storage.count - 1)
        }

        mutating func pop() -> Element? {
            guard storage.isNotEmpty else { return nil }

            storage.swapAt(0, storage.count - 1)
            let result = storage.removeLast()
            if storage.isNotEmpty {
                siftDown(0)
            }
            return result
        }

        private mutating func siftUp(_ index: Int) {
            var i = index
            while i > 0 {
                let parent = (i - 1) / 2
                if storage[i] < storage[parent] {
                    storage.swapAt(i, parent)
                    i = parent
                }
                else {
                    return
                }
            }
        }

        private mutating func siftDown(_ index: Int) {
            var i = index
            let n = storage.count
            while true {
                let left = 2 * i + 1
                let right = 2 * i + 2
                var smallest = i
                if left < n, storage[left] < storage[smallest] {
                    smallest = left
                }
                if right < n, storage[right] < storage[smallest] {
                    smallest = right
                }
                if smallest == i {
                    return
                }
                storage.swapAt(i, smallest)
                i = smallest
            }
        }

    }

}
