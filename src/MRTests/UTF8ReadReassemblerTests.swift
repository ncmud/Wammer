import Foundation
import Testing
@testable import Wammer

@Suite struct UTF8ReadReassemblerTests {

    @Test func wholeCharactersPassThrough() {
        var reassembler = UTF8ReadReassembler()
        let bytes = Array("Account: Jake \u{2550}\u{2022}".utf8)
        #expect(reassembler.decodableBytes(bytes, holdIncompleteTail: true) == bytes)
    }

    @Test func splitBoxDrawingCharacterWaitsForItsLastByte() {
        var reassembler = UTF8ReadReassembler()
        let first = reassembler.decodableBytes(Array("ab".utf8) + [0xE2, 0x95], holdIncompleteTail: true)
        #expect(first == Array("ab".utf8))

        let second = reassembler.decodableBytes([0x90] + Array("cd".utf8), holdIncompleteTail: true)
        #expect(String(bytes: second, encoding: .utf8) == "\u{2550}cd")
    }

    @Test(arguments: [1, 2, 3])
    func splitFourByteCharacterWaitsForItsLastByte(splitAt: Int) {
        var reassembler = UTF8ReadReassembler()
        let emoji = Array("\u{1F600}".utf8)

        let first = reassembler.decodableBytes(Array(emoji[..<splitAt]), holdIncompleteTail: true)
        #expect(first.isEmpty)

        let second = reassembler.decodableBytes(Array(emoji[splitAt...]), holdIncompleteTail: true)
        #expect(second == emoji)
    }

    @Test func everySplitPointDecodesCleanly() {
        let text = "\u{2554}\u{2550}\u{2557} \u{2022} caf\u{E9} \u{2014} \u{1F600} x"
        let bytes = Array(text.utf8)

        for splitAt in 0...bytes.count {
            var reassembler = UTF8ReadReassembler()
            let first = reassembler.decodableBytes(Array(bytes[..<splitAt]), holdIncompleteTail: true)
            let second = reassembler.decodableBytes(Array(bytes[splitAt...]), holdIncompleteTail: true)

            let firstText = String(bytes: first, encoding: .utf8)
            let secondText = String(bytes: second, encoding: .utf8)
            #expect(firstText != nil, "split at \(splitAt)")
            #expect(secondText != nil, "split at \(splitAt)")
            #expect((firstText ?? "") + (secondText ?? "") == text, "split at \(splitAt)")
        }
    }

    @Test func otherEncodingsReleaseEveryByte() {
        var reassembler = UTF8ReadReassembler()
        let bytes: [UInt8] = [0x41, 0xE2, 0x95]
        #expect(reassembler.decodableBytes(bytes, holdIncompleteTail: false) == bytes)
    }

    @Test func switchingAwayFromUTF8ReleasesHeldBytes() {
        var reassembler = UTF8ReadReassembler()
        _ = reassembler.decodableBytes([0x41, 0xE2], holdIncompleteTail: true)
        #expect(reassembler.decodableBytes([0x42], holdIncompleteTail: false) == [0xE2, 0x42])
    }

    @Test func bytesThatCannotStartUTF8AreNotHeld() {
        var reassembler = UTF8ReadReassembler()
        #expect(reassembler.decodableBytes([0x41, 0xC0], holdIncompleteTail: true) == [0x41, 0xC0])
        #expect(reassembler.decodableBytes([0x41, 0xF8], holdIncompleteTail: true) == [0x41, 0xF8])
        #expect(reassembler.decodableBytes([0x80, 0x80, 0x80, 0x80], holdIncompleteTail: true) == [0x80, 0x80, 0x80, 0x80])
    }

    @Test func resetDropsHeldBytes() {
        var reassembler = UTF8ReadReassembler()
        _ = reassembler.decodableBytes([0xE2, 0x95], holdIncompleteTail: true)
        reassembler.reset()
        #expect(reassembler.decodableBytes(Array("ok".utf8), holdIncompleteTail: true) == Array("ok".utf8))
    }
}
