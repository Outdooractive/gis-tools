import Foundation
@testable import GISTools
import Testing

struct FeatureIdentifierExtensionsTests {

    // MARK: - int64Value

    // Validates int64Value returns the Int value for an .int identifier.
    @Test
    func int64ValueInt() async throws {
        let id = Feature.Identifier.int(42)
        #expect(id.int64Value == 42)
    }

    // Verifies int64Value returns the UInt value for a .uint identifier.
    @Test
    func int64ValueUInt() async throws {
        let id = Feature.Identifier.uint(42)
        #expect(id.uint64Value == 42)
        #expect(id.int64Value == 42)
    }

    // Verifies int64Value converts Int.max to Int64.
    @Test
    func int64ValueMaxInt() async throws {
        let id = Feature.Identifier.int(.max)
        #expect(id.int64Value == Int64(Int.max))
    }

    // Verifies int64Value handles negative integer identifiers.
    @Test
    func int64ValueNegative() async throws {
        let id = Feature.Identifier.int(-1)
        #expect(id.int64Value == -1)
    }

    // Verifies int64Value returns nil when UInt exceeds Int64 range.
    @Test
    func int64ValueUIntTooLarge() async throws {
        let id = Feature.Identifier.uint(UInt(Int.max) + 1)
        #expect(id.int64Value == nil)
    }

    // Verifies int64Value returns nil for a string identifier.
    @Test
    func int64ValueString() async throws {
        let id = Feature.Identifier.string("abc")
        #expect(id.int64Value == nil)
        #expect(id.uint64Value == nil)
    }

    // Verifies int64Value returns nil for a double identifier.
    @Test
    func int64ValueDouble() async throws {
        let id = Feature.Identifier.double(3.14)
        #expect(id.int64Value == nil)
        #expect(id.uint64Value == nil)
    }

    // MARK: - uint64Value

    // Validates uint64Value returns the UInt value for a .uint identifier.
    @Test
    func uint64ValueUInt() async throws {
        let id = Feature.Identifier.uint(42)
        #expect(id.uint64Value == 42)
    }

    // Verifies uint64Value converts UInt.max to UInt64.
    @Test
    func uint64ValueMaxUInt() async throws {
        let id = Feature.Identifier.uint(.max)
        #expect(id.uint64Value == UInt64(UInt.max))
    }

    // Verifies uint64Value returns nil for a negative int identifier.
    @Test
    func uint64ValueNegative() async throws {
        let id = Feature.Identifier.int(-1)
        #expect(id.uint64Value == nil)
    }

    // Verifies int64Value and uint64Value both return 0 for zero identifiers.
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
