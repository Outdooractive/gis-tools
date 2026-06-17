import Foundation
import GISTools

/// GeoPackage extends standard WKB with a binary header before each geometry.
///
/// Header format:
/// - Magic: "GP" (2 bytes)
/// - Flags: envelope indicator + empty flag (1 byte)
/// - Envelope: 0, 4, 6, or 8 doubles depending on flags
/// - SRS ID: 4 bytes (integer)
///
/// Followed by standard Extended WKB.
enum WKBHeader {

    struct Header {
        let srid: Int
        let envelope: BoundingBox?
        let hasZ: Bool
        let hasM: Bool
        let isEmpty: Bool
        let wkbData: Data
    }

    /// Parse a GeoPackage WKB blob into its header and inner WKB payload.
    static func parse(_ data: Data) throws -> Header {
        guard data.count >= 8 else {
            throw GeoPackageError.invalidWKB("Data too short for header")
        }

        var offset = 0

        // Magic bytes "GP"
        let magic0 = data[offset]; offset += 1
        let magic1 = data[offset]; offset += 1
        guard magic0 == 0x47, magic1 == 0x50 else {  // "GP"
            throw GeoPackageError.invalidWKB("Missing GeoPackage magic bytes")
        }

        // Flags byte
        let flags = data[offset]; offset += 1
        let envelopeIndicator = Int(flags >> 1) & 0x07
        let empty = (flags & 0x01) != 0

        // Envelope (set of bounding boxes based on indicator)
        var envelope: BoundingBox?
        if envelopeIndicator >= 1 {
            // Read 2 doubles per coordinate dimension
            let doublesPerCoord: Int
            switch envelopeIndicator {
            case 1: doublesPerCoord = 2  // minx, maxx, miny, maxy
            case 2: doublesPerCoord = 3  // + minz, maxz
            case 3: doublesPerCoord = 4  // + minm, maxm
            case 4: doublesPerCoord = 4  // minx, maxx, miny, maxy, minz, maxz, minm, maxm
            default: doublesPerCoord = 2
            }

            let requiredDoubles: Int
            switch envelopeIndicator {
            case 1: requiredDoubles = 4
            case 2: requiredDoubles = 6
            case 3: requiredDoubles = 8
            case 4: requiredDoubles = 8
            default: requiredDoubles = 4
            }

            guard data.count >= offset + requiredDoubles * MemoryLayout<Double>.size else {
                throw GeoPackageError.invalidWKB("Data too short for envelope")
            }

            let doubles = data.withUnsafeBytes { rawBuf in
                let buf = rawBuf.bindMemory(to: Double.self)
                return (0..<requiredDoubles).map { buf[offset / MemoryLayout<Double>.size + $0] }
            }
            offset += requiredDoubles * MemoryLayout<Double>.size

            if requiredDoubles >= 4 {
                envelope = BoundingBox(
                    southWest: Coordinate3D(latitude: doubles[2], longitude: doubles[0]),
                    northEast: Coordinate3D(latitude: doubles[3], longitude: doubles[1]))
            }
        }

        // SRS ID (4 bytes, little-endian)
        guard data.count >= offset + 4 else {
            throw GeoPackageError.invalidWKB("Data too short for SRS ID")
        }
        let srid = Int(data[offset]) | (Int(data[offset+1]) << 8) | (Int(data[offset+2]) << 16) | (Int(data[offset+3]) << 24)
        offset += 4

        // Remaining data is the Extended WKB geometry
        let wkbData = data.subdata(in: offset..<data.count)
        guard !wkbData.isEmpty else {
            throw GeoPackageError.invalidWKB("Missing WKB geometry data")
        }

        // Determine Z/M from WKB geometry type
        let hasZ = (wkbData.count >= 5) ? ((wkbData[4] & 0x80) != 0) : false
        let hasM = (wkbData.count >= 5) ? ((wkbData[4] & 0x40) != 0) : false

        return Header(srid: srid, envelope: envelope, hasZ: hasZ, hasM: hasM, isEmpty: empty, wkbData: wkbData)
    }

    /// Prepend a GeoPackage header to a standard WKB payload.
    static func prependHeader(to wkb: Data, srid: Int, envelope: BoundingBox?) -> Data {
        var result = Data()

        // Magic "GP"
        result.append(contentsOf: [0x47, 0x50])

        // Flags byte
        var flags: UInt8 = 0
        if envelope != nil {
            flags |= 0x03  // envelope indicator = 1 (2D envelope), empty flag = false
        }
        result.append(flags)

        // Envelope: minx, maxx, miny, maxy
        if let envelope {
            withUnsafeBytes(of: envelope.southWest.longitude) { result.append(contentsOf: $0) }
            withUnsafeBytes(of: envelope.northEast.longitude) { result.append(contentsOf: $0) }
            withUnsafeBytes(of: envelope.southWest.latitude) { result.append(contentsOf: $0) }
            withUnsafeBytes(of: envelope.northEast.latitude) { result.append(contentsOf: $0) }
        }

        // SRS ID (4 bytes, little-endian)
        result.append(contentsOf: [
            UInt8(srid & 0xFF),
            UInt8((srid >> 8) & 0xFF),
            UInt8((srid >> 16) & 0xFF),
            UInt8((srid >> 24) & 0xFF),
        ])

        // Append the inner WKB
        result.append(wkb)

        return result
    }

}
