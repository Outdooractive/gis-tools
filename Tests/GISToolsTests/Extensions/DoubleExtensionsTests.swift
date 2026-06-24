@testable import GISTools
import Testing

struct DoubleExtensionsTests {

    // Verifies Double.rounded(precision:) produces correct rounding at precisions 0 through 6.
    @Test
    func rounding() async throws {
        let number1 = 123.45678987654
        #expect(number1.rounded(precision: 0) == 123.0)
        #expect(number1.rounded(precision: 1) == 123.5)
        #expect(number1.rounded(precision: 2) == 123.46)
        #expect(number1.rounded(precision: 3) == 123.457)
        #expect(number1.rounded(precision: 4) == 123.4568)
        #expect(number1.rounded(precision: 5) == 123.45679)
        #expect(number1.rounded(precision: 6) == 123.45679)

        let number2 = 9.87654321
        #expect(number2.rounded(precision: 0) == 10.0)
        #expect(number2.rounded(precision: 1) == 9.9)
        #expect(number2.rounded(precision: 2) == 9.88)
        #expect(number2.rounded(precision: 3) == 9.877)
        #expect(number2.rounded(precision: 4) == 9.8765)
        #expect(number2.rounded(precision: 5) == 9.87654)
        #expect(number2.rounded(precision: 6) == 9.876543)
    }

    // Verifies that a negative precision argument leaves the number unchanged.
    @Test
    func roundingInvalidPrecision() async throws {
        let number = 123.456
        #expect(number.rounded(precision: -5) == number)
    }

    // MARK: - Degrees / Radians

    // Verifies degreesToRadians for common angles.
    @Test
    func degreesToRadians() async throws {
        #expect(abs(0.0.degreesToRadians - 0.0) < 0.0000001)
        #expect(abs(180.0.degreesToRadians - .pi) < 0.0000001)
        #expect(abs(360.0.degreesToRadians - 0.0) < 0.0000001)
        #expect(abs(90.0.degreesToRadians - (.pi / 2.0)) < 0.0000001)
        #expect(abs(45.0.degreesToRadians - (.pi / 4.0)) < 0.0000001)
        #expect(abs((-90.0).degreesToRadians - (-.pi / 2.0)) < 0.0000001)
    }

    // Verifies radiansToDegrees for common angles.
    @Test
    func radiansToDegrees() async throws {
        #expect(abs(0.0.radiansToDegrees - 0.0) < 0.0000001)
        #expect(abs(Double.pi.radiansToDegrees - 180.0) < 0.0000001)
        #expect(abs((2.0 * .pi).radiansToDegrees - 0.0) < 0.0000001)
        #expect(abs((.pi / 2.0).radiansToDegrees - 90.0) < 0.0000001)
        #expect(abs((.pi / 4.0).radiansToDegrees - 45.0) < 0.0000001)
        // Angles equivalent to 270° after remainder normalization.
        #expect(abs((-0.5 * .pi).radiansToDegrees - (-90.0)) < 0.0000001)
    }

    // MARK: - Length conversions

    // Verifies lengthToRadians for all supported units.
    @Test
    func lengthToRadians() async throws {
        // 1 meter ≈ 1 / earthRadius radians
        let oneMeter = 1.0.lengthToRadians(unit: .meters)
        #expect(oneMeter != nil)
        #expect(abs(oneMeter! - (1.0 / GISTool.earthRadius)) < 0.0000001)

        let oneKilometer = 1.0.lengthToRadians(unit: .kilometers)
        #expect(oneKilometer != nil)
        #expect(abs(oneKilometer! - (1000.0 / GISTool.earthRadius)) < 0.0000001)

        let zeroMeters = 0.0.lengthToRadians(unit: .meters)
        #expect(zeroMeters == 0.0)
    }

    // Verifies radiansToLength converts back correctly for meters.
    @Test
    func radiansToLength() async throws {
        let radians = 1.0 / GISTool.earthRadius
        let meters = radians.radiansToLength(unit: .meters)
        #expect(meters != nil)
        #expect(abs(meters! - 1.0) < 0.0000001)

        let zeroRadians = 0.0.radiansToLength(unit: .meters)
        #expect(zeroRadians == 0.0)
    }

    // Verifies lengthToDegrees for common units.
    @Test
    func lengthToDegrees() async throws {
        let oneMeter = 1.0.lengthToDegrees(unit: .meters)
        #expect(oneMeter != nil)
        #expect(oneMeter! > 0.0)

        let zeroMeters = 0.0.lengthToDegrees(unit: .meters)
        #expect(zeroMeters == 0.0)
    }

    // MARK: - Conversions

    // Verifies GISTool.convertToMeters for all supported length units with positive and negative values.
    @Test
    func conversions() async throws {
        // 1 unit
        #expect(abs(GISTool.convertToMeters(1.0, .meters) - GISTool.convert(length: 1.0, from: .meters, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(1.0, .kilometers) - GISTool.convert(length: 1.0, from: .kilometers, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(1.0, .centimeters) - GISTool.convert(length: 1.0, from: .centimeters, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(1.0, .millimeters) - GISTool.convert(length: 1.0, from: .millimeters, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(1.0, .inches) - GISTool.convert(length: 1.0, from: .inches, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(1.0, .feet) - GISTool.convert(length: 1.0, from: .feet, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(1.0, .yards) - GISTool.convert(length: 1.0, from: .yards, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(1.0, .miles) - GISTool.convert(length: 1.0, from: .miles, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(1.0, .nauticalMiles) - GISTool.convert(length: 1.0, from: .nauticalMiles, to: .meters)!) < 0.001)

        // pi units
        #expect(abs(GISTool.convertToMeters(Double.pi, .meters) - GISTool.convert(length: Double.pi, from: .meters, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(Double.pi, .kilometers) - GISTool.convert(length: Double.pi, from: .kilometers, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(Double.pi, .centimeters) - GISTool.convert(length: Double.pi, from: .centimeters, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(Double.pi, .millimeters) - GISTool.convert(length: Double.pi, from: .millimeters, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(Double.pi, .inches) - GISTool.convert(length: Double.pi, from: .inches, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(Double.pi, .feet) - GISTool.convert(length: Double.pi, from: .feet, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(Double.pi, .yards) - GISTool.convert(length: Double.pi, from: .yards, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(Double.pi, .miles) - GISTool.convert(length: Double.pi, from: .miles, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(Double.pi, .nauticalMiles) - GISTool.convert(length: Double.pi, from: .nauticalMiles, to: .meters)!) < 0.001)

        // -1 unit
        #expect(abs(GISTool.convertToMeters(-1.0, .meters) - -GISTool.convert(length: 1.0, from: .meters, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(-1.0, .kilometers) - -GISTool.convert(length: 1.0, from: .kilometers, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(-1.0, .centimeters) - -GISTool.convert(length: 1.0, from: .centimeters, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(-1.0, .millimeters) - -GISTool.convert(length: 1.0, from: .millimeters, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(-1.0, .inches) - -GISTool.convert(length: 1.0, from: .inches, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(-1.0, .feet) - -GISTool.convert(length: 1.0, from: .feet, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(-1.0, .yards) - -GISTool.convert(length: 1.0, from: .yards, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(-1.0, .miles) - -GISTool.convert(length: 1.0, from: .miles, to: .meters)!) < 0.001)
        #expect(abs(GISTool.convertToMeters(-1.0, .nauticalMiles) - -GISTool.convert(length: 1.0, from: .nauticalMiles, to: .meters)!) < 0.001)
    }

}
