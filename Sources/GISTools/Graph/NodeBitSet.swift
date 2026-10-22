#if EnableGraphAPI
extension Graph {

    /// A compact membership set for node indices.
    ///
    /// Routing algorithms use this for visited/settled state. It stores one bit
    /// per node instead of one byte per node, which matters for large graphs
    /// and for bidirectional searches that keep two sets at once.
    struct NodeBitSet: Sendable {

        private var words: [UInt64]

        let count: Int

        init(count: Int) {
            precondition(count >= 0, "NodeBitSet count must be non-negative")

            self.count = count
            self.words = Array(
                repeating: 0,
                count: (count + 63) / 64)
        }

        /// The number of 64-bit words allocated by the receiver.
        var wordCount: Int {
            words.count
        }

        subscript(index: Int) -> Bool {
            get {
                let word = words[index >> 6]
                return word & (UInt64(1) << UInt64(index & 63)) != 0
            }
            set {
                let wordIndex = index >> 6
                let mask = UInt64(1) << UInt64(index & 63)

                if newValue {
                    words[wordIndex] |= mask
                }
                else {
                    words[wordIndex] &= ~mask
                }
            }
        }

    }

}
#endif
