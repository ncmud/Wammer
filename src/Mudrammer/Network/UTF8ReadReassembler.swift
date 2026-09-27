import Foundation

/// Holds back a UTF-8 character that a socket read split in two, so every
/// run of bytes handed to the decoder ends on a whole character.
struct UTF8ReadReassembler {
    private var pending: [UInt8] = []

    /// Joins `bytes` onto anything held from the previous read and returns
    /// the bytes that are ready to decode.
    ///
    /// - Parameters:
    ///   - bytes: The next run of bytes from the server.
    ///   - holdIncompleteTail: Pass `true` while decoding as UTF-8 so an
    ///     unfinished trailing character waits for the next call. Pass `false`
    ///     for any other encoding to release everything, including bytes held
    ///     from an earlier call.
    mutating func decodableBytes(_ bytes: [UInt8], holdIncompleteTail: Bool) -> [UInt8] {
        var joined = pending + bytes
        pending = []
        guard holdIncompleteTail else { return joined }

        let tailStart = Self.incompleteTailStart(of: joined)
        pending = Array(joined[tailStart...])
        joined.removeSubrange(tailStart...)
        return joined
    }

    mutating func reset() {
        pending = []
    }

    /// The index where an unfinished UTF-8 sequence at the end of `bytes`
    /// begins, or `bytes.count` when `bytes` ends on a whole character or on
    /// bytes that cannot start a UTF-8 sequence.
    static func incompleteTailStart(of bytes: [UInt8]) -> Int {
        var lead = bytes.count - 1
        while lead >= 0, bytes.count - lead <= 3, bytes[lead] & 0xC0 == 0x80 {
            lead -= 1
        }
        guard lead >= 0 else { return bytes.count }

        let length: Int
        switch bytes[lead] {
        case 0xC2...0xDF: length = 2
        case 0xE0...0xEF: length = 3
        case 0xF0...0xF4: length = 4
        default: return bytes.count
        }
        return bytes.count - lead < length ? lead : bytes.count
    }
}
