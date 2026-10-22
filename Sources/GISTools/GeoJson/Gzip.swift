import GISToolsCZlib
import Foundation

/// Transparent gzip decompression for GeoJSON `Data` entry points.
enum Gzip {

    private static let magicByte0: UInt8 = 0x1F
    private static let magicByte1: UInt8 = 0x8B
    private static let bufferSize = 64 * 1024

    /// Whether the data starts with the gzip magic bytes.
    static func isGzipped(_ data: Data) -> Bool {
        guard data.count >= 2 else { return false }

        return data[data.startIndex] == magicByte0
            && data[data.index(after: data.startIndex)] == magicByte1
    }

    /// Returns the decompressed data when the input is gzip-compressed;
    /// otherwise returns the input unchanged.
    ///
    /// Returns `nil` when the input looks like gzip but is corrupt or
    /// truncated.
    static func decompressIfNeeded(_ data: Data) -> Data? {
        guard isGzipped(data) else { return data }

        return decompress(data)
    }

    /// Decompresses a gzip stream.
    static func decompress(_ data: Data) -> Data? {
        var stream = z_stream()
        let initialization = inflateInit2_(
            &stream,
            15 + 32,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size))
        guard initialization == Z_OK else { return nil }

        defer {
            inflateEnd(&stream)
        }

        var result = Data()
        result.reserveCapacity(data.count * 4)

        return data.withUnsafeBytes { inputBuffer -> Data? in
            guard let inputBase = inputBuffer.bindMemory(to: Bytef.self).baseAddress
            else { return nil }

            stream.next_in = UnsafeMutablePointer(mutating: inputBase)
            stream.avail_in = uInt(inputBuffer.count)

            var output = [UInt8](repeating: 0, count: bufferSize)

            while true {
                let statusAndCount = output.withUnsafeMutableBytes { outputBuffer -> (Int32, Int) in
                    guard let outputBase = outputBuffer.bindMemory(to: Bytef.self).baseAddress
                    else { return (Z_BUF_ERROR, 0) }

                    stream.next_out = outputBase
                    stream.avail_out = uInt(outputBuffer.count)

                    let status = inflate(&stream, Z_NO_FLUSH)
                    let written = outputBuffer.count - Int(stream.avail_out)
                    return (status, written)
                }

                let (status, written) = statusAndCount
                if written > 0 {
                    result.append(contentsOf: output[0 ..< written])
                }

                if status == Z_STREAM_END {
                    return result
                }

                if status != Z_OK {
                    return nil
                }
            }
        }
    }

}
