@testable import GISTools
import Testing

struct MidPointTests {

    @Test
    func horizontalEquator() async throws {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 0.0, longitude: 10.0)
        let middle = coordinate1.midpoint(to: coordinate2)

        #expect(abs(coordinate1.distance(from: middle) - coordinate2.distance(from: middle)) < 0.000001)
    }

    @Test
    func verticalFromEquator() async throws {
        let coordinate1 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let middle = coordinate1.midpoint(to: coordinate2)

        #expect(abs(coordinate1.distance(from: middle) - coordinate2.distance(from: middle)) < 0.000001)
    }

    @Test
    func verticalToEquator() async throws {
        let coordinate1 = Coordinate3D(latitude: 10.0, longitude: 0.0)
        let coordinate2 = Coordinate3D(latitude: 0.0, longitude: 0.0)
        let middle = coordinate1.midpoint(to: coordinate2)

        #expect(abs(coordinate1.distance(from: middle) - coordinate2.distance(from: middle)) < 0.000001)
    }

    @Test
    func longDistance() async throws {
        let coordinate1 = Coordinate3D(latitude: 21.94304553343818, longitude: 22.5)
        let coordinate2 = Coordinate3D(latitude: 46.800059446787316, longitude: 92.10937499999999)
        let middle = coordinate1.midpoint(to: coordinate2)

        #expect(abs(coordinate1.distance(from: middle) - coordinate2.distance(from: middle)) < 0.000001)
    }

}
