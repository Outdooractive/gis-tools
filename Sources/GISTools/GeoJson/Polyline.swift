#if canImport(CoreLocation)
import CoreLocation
#endif
import Foundation

extension [Coordinate3D] {

    /// Encodes the coordinates to a Polyline with the given precision.
    ///
    /// The polyline format always uses EPSG:4326 (WGS84) coordinates.
    /// If the receiver uses a different projection, coordinates are
    /// converted to EPSG:4326 before encoding.
    ///
    /// - Parameters:
    ///    - precision: The encoding precision (default `GISTool.defaultPolylinePrecision`)
    /// - Returns: A Polyline-encoded string
    public func encodePolyline(
        precision: Double = GISTool.defaultPolylinePrecision
    ) -> String {
        let coords4326 = self.map { $0.projected(to: .epsg4326) }
        return Polyline.encode(coordinates: coords4326, precision: precision)
    }

}

extension String {

    /// Decodes a Polyline to coordinates with the given precision (must match the encoding precision).
    ///
    /// The polyline format always uses EPSG:4326 (WGS84) coordinates.
    /// Returned coordinates are in EPSG:4326.
    ///
    /// - Parameters:
    ///    - precision: The decoding precision (default `GISTool.defaultPolylinePrecision`)
    /// - Returns: An array of coordinates in EPSG:4326, or `nil` if decoding fails
    public func decodePolyline(
        precision: Double = GISTool.defaultPolylinePrecision
    ) -> [Coordinate3D]? {
        Polyline.decode(polyline: self, precision: precision)
    }

}

// Algorithm: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
enum Polyline {

    /// Encodes the coordinates to a Polyline with the given precision.
    ///
    /// The polyline format always uses EPSG:4326 (WGS84) coordinates.
    /// Input coordinates are expected to be in EPSG:4326; if not, project
    /// them before calling this method.
    ///
    /// - Parameters:
    ///    - coordinates: The coordinates to encode (EPSG:4326)
    ///    - precision: The encoding precision (default `GISTool.defaultPolylinePrecision`)
    /// - Returns: A Polyline-encoded string
    public static func encode(
        coordinates: [Coordinate3D],
        precision: Double = GISTool.defaultPolylinePrecision
    ) -> String {
        var previousIntLatitude = 0,
            previousIntLongitude = 0

        var result = ""

        for coordinate in coordinates {
            let intLatitude = (coordinate.latitude * precision).rounded().toInt
            let intLongitude = (coordinate.longitude * precision).rounded().toInt

            result += encodeInt(intLatitude - previousIntLatitude)
            result += encodeInt(intLongitude - previousIntLongitude)

            previousIntLatitude = intLatitude
            previousIntLongitude = intLongitude
        }

        return result
    }

    /// Decodes a Polyline to coordinates with the given precision (must match the encoding precision).
    ///
    /// The polyline format always uses EPSG:4326 (WGS84) coordinates.
    /// Returned coordinates are in EPSG:4326.
    ///
    /// - Parameters:
    ///    - polyline: The Polyline-encoded string to decode
    ///    - precision: The decoding precision (default `GISTool.defaultPolylinePrecision`)
    /// - Returns: An array of coordinates in EPSG:4326, or `nil` if decoding fails
    public static func decode(
        polyline: String,
        precision: Double = GISTool.defaultPolylinePrecision
    ) -> [Coordinate3D]? {
        guard let data = polyline.asUTF8EncodedData else { return nil }

        let length = data.count
        return data.withUnsafeBytes({ buffer -> [Coordinate3D]? in
            var coordinates: [Coordinate3D] = []

            var position = 0
            var latitude = 0.0
            var longitude = 0.0

            while position < length {
                guard
                    let currentLatitude = decodeValue(
                        buffer: buffer,
                        position: &position,
                        length: length,
                        precision: precision),
                    let currentLongitude = decodeValue(
                        buffer: buffer,
                        position: &position,
                        length: length,
                        precision: precision)
                else { return nil }

                latitude += currentLatitude
                longitude += currentLongitude

                coordinates.append(Coordinate3D(latitude: latitude, longitude: longitude))
            }

            return coordinates
        })
    }

    // MARK: - Private

    private static let firstBitBitmask = 0b0000_0001
    private static let fiveBitsBitmask = 0b0001_1111
    private static let sixthBitBitmask = 0b0010_0000
    private static let base64BaseValue = 63

    private static func encodeInt(_ value: Int) -> String {
        var value = value
        if value < 0 {
            value = value << 1
            value = ~value
        }
        else {
            value = value << 1
        }

        var result = ""
        var fiveBitChunk = 0

        repeat {
            fiveBitChunk = value & fiveBitsBitmask

            if value >= sixthBitBitmask {
                fiveBitChunk |= sixthBitBitmask
            }

            value = value >> 5
            fiveBitChunk += base64BaseValue

            result += String(UnicodeScalar(fiveBitChunk)!)
        }
        while value != 0

        return result
    }

    private static func decodeValue(
        buffer: UnsafeRawBufferPointer,
        position: inout Int,
        length: Int,
        precision: Double
    ) -> Double? {
        guard position < length else { return nil }

        var value = 0
        var scalar = 0
        var components = 0
        var fiveBitChunk = 0

        repeat {
            scalar = Int(buffer[position]) - base64BaseValue
            fiveBitChunk = scalar & fiveBitsBitmask

            value |= (fiveBitChunk << (5 * components))

            position += 1
            components += 1
        }
        while (scalar & sixthBitBitmask) == sixthBitBitmask
            && position < length
            && components < 6

        if components == 6,
           (scalar & sixthBitBitmask) == sixthBitBitmask
        {
            return nil
        }

        if (value & firstBitBitmask) == firstBitBitmask {
            value = ~(value >> 1)
        }
        else {
            value = value >> 1
        }

        return Double(value) / precision
    }

}
