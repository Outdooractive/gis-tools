@testable import GISTools
import Testing

struct BooleanOverlapTests {

    @Test
    func isFalse() async throws {
        let lineString1 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse1_1")
        let lineString2 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse1_2")

        let lineString3 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse2_1")
        let lineString4 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse2_2")

        let lineString5 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse3_1")
        let lineString6 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapFalse3_2")

        let multiPoint1 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse4_1")
        let multiPoint2 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse4_2")

        let multiPoint3 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse6_1")
        let multiPoint4 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapFalse6_2")

//        let polygon1 = TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse5_1")
//        let polygon2 = TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse5_2")

        let polygon3 = try TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse7_1")
        let polygon4 = try TestData.polygon(package: "BooleanOverlap", name: "OverlapFalse7_2")

        #expect(lineString1.isOverlapping(with: lineString2) == false)
        #expect(lineString3.isOverlapping(with: lineString4) == false)
        #expect(lineString5.isOverlapping(with: lineString6) == false)
        #expect(multiPoint1.isOverlapping(with: multiPoint2) == false)
        #expect(multiPoint3.isOverlapping(with: multiPoint4) == false)

        // TODO: This test will fail because the coordinates are shifted. The Polygon equality check has to
        // be updated first (see the TODO there)
//        #expect(polygon1.isOverlapping(with: polygon2) == false)
        #expect(polygon3.isOverlapping(with: polygon4) == false)
    }

    @Test
    func isTrue() async throws {
        let lineString1 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue1_1")
        let lineString2 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue1_2")

        let lineString3 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue2_1")
        let lineString4 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue2_2")

        let lineString5 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue5_1")
        let lineString6 = try TestData.lineString(package: "BooleanOverlap", name: "OverlapTrue5_2")

        let multiPoint1 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapTrue3_1")
        let multiPoint2 = try TestData.multiPoint(package: "BooleanOverlap", name: "OverlapTrue3_2")

        let polygon1 = try TestData.polygon(package: "BooleanOverlap", name: "OverlapTrue4_1")
        let polygon2 = try TestData.polygon(package: "BooleanOverlap", name: "OverlapTrue4_2")

        #expect(lineString1.isOverlapping(with: lineString2))
        #expect(lineString3.isOverlapping(with: lineString4))
        #expect(lineString5.isOverlapping(with: lineString6))
        #expect(multiPoint1.isOverlapping(with: multiPoint2))
        #expect(polygon1.isOverlapping(with: polygon2))
    }

}
