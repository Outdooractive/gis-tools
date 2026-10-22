#if EnableGraphAPI
@testable import GISTools
import Testing

/// ``Graph/NodeBitSet`` tests.
struct NodeBitSetTests {

    @Test
    func emptyBitSet() {
        let bits = Graph.NodeBitSet(count: 0)

        #expect(bits.wordCount == 0)
    }

    @Test
    func wordCount() {
        #expect(Graph.NodeBitSet(count: 1).wordCount == 1)
        #expect(Graph.NodeBitSet(count: 64).wordCount == 1)
        #expect(Graph.NodeBitSet(count: 65).wordCount == 2)

        let bits = Graph.NodeBitSet(count: 500_000)
        #expect(bits.wordCount == 7_813)
        #expect(
            bits.wordCount * MemoryLayout<UInt64>.stride == 62_504,
            "500k nodes should use about 62.5 KB, not 500 KB"
        )
    }

    @Test
    func setAndClearAcrossWordBoundaries() {
        var bits = Graph.NodeBitSet(count: 130)

        for index in [0, 1, 63, 64, 65, 127, 128, 129] {
            #expect(bits[index] == false)
            bits[index] = true
            #expect(bits[index])
        }

        for index in [0, 1, 63, 64, 65, 127, 128, 129] {
            bits[index] = false
            #expect(bits[index] == false)
        }
    }

    @Test
    func settingOneBitDoesNotAffectNeighbours() {
        var bits = Graph.NodeBitSet(count: 64)

        bits[32] = true

        #expect(bits[32])
        for index in 0 ..< 64 where index != 32 {
            #expect(bits[index] == false)
        }
    }

}
#endif
