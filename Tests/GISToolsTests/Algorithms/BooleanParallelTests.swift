@testable import GISTools
import Testing

struct BooleanParallelTests {

    @Test
    func isTrue() async throws {
        let lineString1 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue1_1")
        let lineString2 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue1_2")

        let lineString3 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue2_1")
        let lineString4 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue2_1")

        let lineString5 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue3_1")
        let lineString6 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue3_1")

        let lineString7 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue4_1")
        let lineString8 = try TestData.lineString(package: "BooleanParallel", name: "LineStringTrue4_1")

        #expect(lineString1.isParallel(to: lineString2))
        #expect(lineString3.isParallel(to: lineString4))
        #expect(lineString5.isParallel(to: lineString6))
        #expect(lineString7.isParallel(to: lineString8))
    }

    @Test
    func isFalse() async throws {
        let lineString1 = try TestData.lineString(package: "BooleanParallel", name: "LineStringFalse1_1")
        let lineString2 = try TestData.lineString(package: "BooleanParallel", name: "LineStringFalse1_2")

        let lineString3 = try TestData.lineString(package: "BooleanParallel", name: "LineStringFalse2_1")
        let lineString4 = try TestData.lineString(package: "BooleanParallel", name: "LineStringFalse2_2")

        #expect(lineString1.isParallel(to: lineString2) == false)
        #expect(lineString3.isParallel(to: lineString4) == false)
    }

}
