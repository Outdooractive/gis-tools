@testable import GISTools
import Testing

struct IntExtensionsTests {

    @Test
    func conversions() async throws {
        // 1 unit
        #expect(abs(1.meters - GISTool.convert(length: 1.0, from: .meters, to: .meters)!) < 0.001)
        #expect(abs(1.kilometers - GISTool.convert(length: 1.0, from: .kilometers, to: .meters)!) < 0.001)
        #expect(abs(1.centimeters - GISTool.convert(length: 1.0, from: .centimeters, to: .meters)!) < 0.001)
        #expect(abs(1.millimeters - GISTool.convert(length: 1.0, from: .millimeters, to: .meters)!) < 0.001)
        #expect(abs(1.inches - GISTool.convert(length: 1.0, from: .inches, to: .meters)!) < 0.001)
        #expect(abs(1.feet - GISTool.convert(length: 1.0, from: .feet, to: .meters)!) < 0.001)
        #expect(abs(1.yards - GISTool.convert(length: 1.0, from: .yards, to: .meters)!) < 0.001)
        #expect(abs(1.miles - GISTool.convert(length: 1.0, from: .miles, to: .meters)!) < 0.001)
        #expect(abs(1.nauticalMiles - GISTool.convert(length: 1.0, from: .nauticalmiles, to: .meters)!) < 0.001)

        // 314 units
        #expect(abs(314.meters - GISTool.convert(length: 314.0, from: .meters, to: .meters)!) < 0.001)
        #expect(abs(314.kilometers - GISTool.convert(length: 314.0, from: .kilometers, to: .meters)!) < 0.001)
        #expect(abs(314.centimeters - GISTool.convert(length: 314.0, from: .centimeters, to: .meters)!) < 0.001)
        #expect(abs(314.millimeters - GISTool.convert(length: 314.0, from: .millimeters, to: .meters)!) < 0.001)
        #expect(abs(314.inches - GISTool.convert(length: 314.0, from: .inches, to: .meters)!) < 0.001)
        #expect(abs(314.feet - GISTool.convert(length: 314.0, from: .feet, to: .meters)!) < 0.001)
        #expect(abs(314.yards - GISTool.convert(length: 314.0, from: .yards, to: .meters)!) < 0.001)
        #expect(abs(314.miles - GISTool.convert(length: 314.0, from: .miles, to: .meters)!) < 0.001)
        #expect(abs(314.nauticalMiles - GISTool.convert(length: 314.0, from: .nauticalmiles, to: .meters)!) < 0.001)

        // -1 unit
        #expect(abs(-1.meters - -GISTool.convert(length: 1.0, from: .meters, to: .meters)!) < 0.001)
        #expect(abs(-1.kilometers - -GISTool.convert(length: 1.0, from: .kilometers, to: .meters)!) < 0.001)
        #expect(abs(-1.centimeters - -GISTool.convert(length: 1.0, from: .centimeters, to: .meters)!) < 0.001)
        #expect(abs(-1.millimeters - -GISTool.convert(length: 1.0, from: .millimeters, to: .meters)!) < 0.001)
        #expect(abs(-1.inches - -GISTool.convert(length: 1.0, from: .inches, to: .meters)!) < 0.001)
        #expect(abs(-1.feet - -GISTool.convert(length: 1.0, from: .feet, to: .meters)!) < 0.001)
        #expect(abs(-1.yards - -GISTool.convert(length: 1.0, from: .yards, to: .meters)!) < 0.001)
        #expect(abs(-1.miles - -GISTool.convert(length: 1.0, from: .miles, to: .meters)!) < 0.001)
        #expect(abs(-1.nauticalMiles - -GISTool.convert(length: 1.0, from: .nauticalmiles, to: .meters)!) < 0.001)
    }

}
