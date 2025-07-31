@testable import GISTools
import Testing

struct BooleanDisjointTests {

    @Test
    func isTrue() async throws {
        let point1 = try TestData.point(package: "BooleanDisjoint", name: "Point1")
        let point2 = try TestData.point(package: "BooleanDisjoint", name: "Point2")
        let multiPoint1 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint1")
        let multiPoint2 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint2")
        let multiPoint3 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint3")
        let lineString1 = try TestData.lineString(package: "BooleanDisjoint", name: "LineString1")
        let lineString2 = try TestData.lineString(package: "BooleanDisjoint", name: "LineString2")
        let polygon1 = try TestData.polygon(package: "BooleanDisjoint", name: "Polygon1")
        let polygon2 = try TestData.polygon(package: "BooleanDisjoint", name: "Polygon2")
        let multiPolygon1 = try TestData.multiPolygon(package: "BooleanDisjoint", name: "MultiPolygon1")

        #expect(point1.isDisjoint(with: point2))
        #expect(point1.isDisjoint(with: multiPoint2))
        #expect(point1.isDisjoint(with: lineString2))
        #expect(point2.isDisjoint(with: point1))
        #expect(point2.isDisjoint(with: polygon1))
        #expect(point2.isDisjoint(with: multiPolygon1))

        #expect(multiPoint1.isDisjoint(with: multiPoint2))
        #expect(multiPoint2.isDisjoint(with: point1))
        #expect(multiPoint2.isDisjoint(with: multiPoint1))
        #expect(multiPoint3.isDisjoint(with: polygon1))

        #expect(lineString1.isDisjoint(with: lineString2))
        #expect(lineString1.isDisjoint(with: polygon1))
        #expect(lineString2.isDisjoint(with: point1))
        #expect(lineString2.isDisjoint(with: multiPoint1))
        #expect(lineString2.isDisjoint(with: lineString1))

        #expect(polygon1.isDisjoint(with: point2))
        #expect(polygon1.isDisjoint(with: multiPoint3))
        #expect(polygon1.isDisjoint(with: lineString1))
        #expect(polygon1.isDisjoint(with: polygon2))
        #expect(polygon2.isDisjoint(with: multiPolygon1))
        #expect(polygon2.isDisjoint(with: polygon1))

        #expect(multiPolygon1.isDisjoint(with: polygon2))
        #expect(multiPolygon1.isDisjoint(with: point2))
    }

    @Test
    func isFalse() async throws {
        let point3 = try TestData.point(package: "BooleanDisjoint", name: "Point3")
        let point4 = try TestData.point(package: "BooleanDisjoint", name: "Point4")
        let multiPoint2 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint2")
        let multiPoint4 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint4")
        let multiPoint5 = try TestData.multiPoint(package: "BooleanDisjoint", name: "MultiPoint5")
        let lineString2 = try TestData.lineString(package: "BooleanDisjoint", name: "LineString2")
        let lineString3 = try TestData.lineString(package: "BooleanDisjoint", name: "LineString3")
        let lineString4 = try TestData.lineString(package: "BooleanDisjoint", name: "LineString4")
        let polygon1 = try TestData.polygon(package: "BooleanDisjoint", name: "Polygon1")
        let polygon3 = try TestData.polygon(package: "BooleanDisjoint", name: "Polygon3")
        let multiPolygon1 = try TestData.multiPolygon(package: "BooleanDisjoint", name: "MultiPolygon1")

        #expect(point3.isDisjoint(with: lineString2) == false)
        #expect(point4.isDisjoint(with: lineString2) == false)

        #expect(multiPoint2.isDisjoint(with: multiPoint4) == false)
        #expect(multiPoint4.isDisjoint(with: lineString2) == false)
        #expect(multiPoint5.isDisjoint(with: polygon1) == false)

        #expect(lineString2.isDisjoint(with: point3) == false)
        #expect(lineString2.isDisjoint(with: point4) == false)
        #expect(lineString2.isDisjoint(with: lineString3) == false)
        #expect(lineString2.isDisjoint(with: multiPoint4) == false)
        #expect(lineString3.isDisjoint(with: lineString2) == false)
        #expect(lineString3.isDisjoint(with: polygon1) == false)
        #expect(lineString4.isDisjoint(with: polygon1) == false)

        #expect(polygon1.isDisjoint(with: multiPoint5) == false)
        #expect(polygon1.isDisjoint(with: lineString3) == false)
        #expect(polygon1.isDisjoint(with: lineString4) == false)
        #expect(polygon3.isDisjoint(with: multiPolygon1) == false)

        #expect(multiPolygon1.isDisjoint(with: polygon3) == false)
    }

}
