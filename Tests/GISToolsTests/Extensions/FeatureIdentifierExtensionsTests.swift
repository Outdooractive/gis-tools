import Foundation
@testable import GISTools
import Testing

struct FeatureIdentifierExtensionsTests {

    // MARK: - int64Value

    @Test
    func int64ValueInt() async throws {
        let id = Feature.Identifier.int(42)
        #expect(id.int64Value == 42)
    }

    @Test
    func int64ValueUInt() async throws {
        let id = Feature.Identifier.uint(42)
        #expect(id.uint64Value == 42)
        #expect(id.int64Value == 42)
    }

    @Test
    func int64ValueMaxInt() async throws {
        let id = Feature.Identifier.int(.max)
        #expect(id.int64Value == Int64(Int.max))
    }

    @Test
    func int64ValueNegative() async throws {
        let id = Feature.Identifier.int(-1)
        #expect(id.int64Value == -1)
    }

    @Test
    func int64ValueUIntTooLarge() async throws {
        let id = Feature.Identifier.uint(UInt(Int.max) + 1)
        #expect(id.int64Value == nil)
    }

    @Test
    func int64ValueString() async throws {
        let id = Feature.Identifier.string("abc")
        #expect(id.int64Value == nil)
        #expect(id.uint64Value == nil)
    }

    @Test
    func int64ValueDouble() async throws {
        let id = Feature.Identifier.double(3.14)
        #expect(id.int64Value == nil)
        #expect(id.uint64Value == nil)
    }

    // MARK: - uint64Value

    @Test
    func uint64ValueUInt() async throws {
        let id = Feature.Identifier.uint(42)
        #expect(id.uint64Value == 42)
    }

    @Test
    func uint64ValueMaxUInt() async throws {
        let id = Feature.Identifier.uint(.max)
        #expect(id.uint64Value == UInt64(UInt.max))
    }

    @Test
    func uint64ValueNegative() async throws {
        let id = Feature.Identifier.int(-1)
        #expect(id.uint64Value == nil)
    }

    @Test
    func uint64ValueZero() async throws {
        let intZero = Feature.Identifier.int(0)
        let uintZero = Feature.Identifier.uint(0)
        #expect(intZero.int64Value == 0)
        #expect(intZero.uint64Value == 0)
        #expect(uintZero.int64Value == 0)
        #expect(uintZero.uint64Value == 0)
    }

}
