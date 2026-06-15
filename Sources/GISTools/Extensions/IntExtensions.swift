import Foundation

#if EnableMeterConversionExtensions && EnableMeasurementConversionExtensions
#error("EnableMeterConversionExtensions and EnableMeasurementConversionExtensions are mutually exclusive")
#endif

#if EnableMeasurementConversionExtensions

extension Int {

    /// The value as a measurement in millimeters.
    public var millimeters: Measurement<UnitLength> {
        Measurement(value: Double(self), unit: .millimeters)
    }

    /// The value as a measurement in centimeters.
    public var centimeters: Measurement<UnitLength> {
        Measurement(value: Double(self), unit: .centimeters)
    }

    /// The value as a measurement in meters.
    public var meters: Measurement<UnitLength> {
        Measurement(value: Double(self), unit: .meters)
    }

    /// The value as a measurement in kilometers.
    public var kilometers: Measurement<UnitLength> {
        Measurement(value: Double(self), unit: .kilometers)
    }

    /// The value as a measurement in inches.
    public var inches: Measurement<UnitLength> {
        Measurement(value: Double(self), unit: .inches)
    }

    /// The value as a measurement in feet.
    public var feet: Measurement<UnitLength> {
        Measurement(value: Double(self), unit: .feet)
    }

    /// The value as a measurement in yards.
    public var yards: Measurement<UnitLength> {
        Measurement(value: Double(self), unit: .yards)
    }

    /// The value as a measurement in miles.
    public var miles: Measurement<UnitLength> {
        Measurement(value: Double(self), unit: .miles)
    }

    /// The value as a measurement in nautical miles.
    public var nauticalMiles: Measurement<UnitLength> {
        Measurement(value: Double(self), unit: .nauticalMiles)
    }

}

#endif

#if EnableMeterConversionExtensions

// MARK: Public

extension Int {

    /// Convert millimeters to meters.
    public var millimeters: Double {
        Double(self) / 1000.0
    }

    /// Convert centimeters to meters.
    public var centimeters: Double {
        Double(self) / 100.0
    }

    /// Convert meters to meters (i.e. returns self as Double).
    public var meters: Double {
        Double(self)
    }

    /// Convert kilometers to meters.
    public var kilometers: Double {
        Double(self) * 1000.0
    }

    /// Convert inches to meters.
    public var inches: Double {
        Double(self) / 39.370
    }

    /// Convert feet to meters.
    public var feet: Double {
        Double(self) / 3.28084
    }

    /// Convert yards to meters.
    public var yards: Double {
        Double(self) / 1.0936
    }

    /// Convert miles to meters.
    public var miles: Double {
        Double(self) * 1609.344
    }

    /// Convert nautical miles to meters.
    public var nauticalMiles: Double {
        Double(self) * 1852.0
    }

}

#endif
