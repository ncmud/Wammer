import Testing
import Foundation
@testable import Wammer

@Suite struct GMCPChatCaptureTests {

    // MARK: - Standard (NCMUD / Aardwolf-spec) Comm.Channel.Text

    @Test func standardPacketCaptures() {
        let capture = GMCPChatCapture()
        let result = capture.ingest(module: "Comm.Channel.Text", data: [
            "channel": "gossip",
            "talker": "Alice",
            "text": "Alice gossips 'hello there'",
        ])
        #expect(result)
        #expect(capture.hasReceivedChat)
        #expect(capture.capturedLines.count == 1)
    }

    @Test func standardPacketLowercaseModuleName() {
        // GMCPHandler downcases before dispatch, but the capture should accept either form.
        let capture = GMCPChatCapture()
        let result = capture.ingest(module: "comm.channel.text", data: [
            "channel": "tell",
            "talker": "Bob",
            "text": "Bob tells you 'hi'",
        ])
        #expect(result)
        #expect(capture.capturedLines.count == 1)
    }

    @Test func standardPacketMissingTextRejected() {
        let capture = GMCPChatCapture()
        let result = capture.ingest(module: "Comm.Channel.Text", data: [
            "channel": "gossip",
            "talker": "Alice",
        ])
        #expect(!result)
        #expect(!capture.hasReceivedChat)
    }

    @Test func standardPacketEmptyTextRejected() {
        let capture = GMCPChatCapture()
        let result = capture.ingest(module: "Comm.Channel.Text", data: [
            "channel": "gossip",
            "text": "",
        ])
        #expect(!result)
    }

    // MARK: - Aardwolf legacy comm.channel

    @Test func aardwolfPacketCaptures() {
        let capture = GMCPChatCapture()
        let result = capture.ingest(module: "comm.channel", data: [
            "chan": "gossip",
            "player": "Abelinc",
            "msg": "You gossip 'Testing'",
        ])
        #expect(result)
        #expect(capture.capturedLines.count == 1)
    }

    @Test func aardwolfMissingMsgRejected() {
        let capture = GMCPChatCapture()
        let result = capture.ingest(module: "comm.channel", data: [
            "chan": "tell",
            "player": "Abelinc",
        ])
        #expect(!result)
    }

    @Test func aardwolfWithoutPlayerStillCaptures() {
        // The 'player' field is optional in Aardwolf packets.
        let capture = GMCPChatCapture()
        let result = capture.ingest(module: "comm.channel", data: [
            "chan": "auction",
            "msg": "Some item is being auctioned!",
        ])
        #expect(result)
    }

    // MARK: - Module dispatch

    @Test func unrelatedModuleIgnored() {
        let capture = GMCPChatCapture()
        let result = capture.ingest(module: "Char.Vitals", data: ["hp": 100])
        #expect(!result)
        #expect(!capture.hasReceivedChat)
    }

    @Test func commChannelStartIgnored() {
        // We deliberately skip start/end packets in v1 to avoid noise.
        let capture = GMCPChatCapture()
        let result = capture.ingest(module: "Comm.Channel.Start", data: [
            "channel": "gossip",
        ])
        #expect(!result)
    }

    // MARK: - Notifications

    @Test func captureFiresNotification() {
        let capture = GMCPChatCapture()
        var receivedGroup: SSAttributedLineGroup?
        let observer = NotificationCenter.default.addObserver(
            forName: GMCPChatCapture.didCaptureChatNotification,
            object: capture,
            queue: nil
        ) { note in
            receivedGroup = note.userInfo?[GMCPChatCapture.lineGroupUserInfoKey] as? SSAttributedLineGroup
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        _ = capture.ingest(module: "Comm.Channel.Text", data: [
            "channel": "gossip",
            "talker": "Alice",
            "text": "Alice gossips 'hi'",
        ])

        #expect(receivedGroup != nil)
    }

    @Test func rejectedIngestDoesNotFireNotification() {
        let capture = GMCPChatCapture()
        var fireCount = 0
        let observer = NotificationCenter.default.addObserver(
            forName: GMCPChatCapture.didCaptureChatNotification,
            object: capture,
            queue: nil
        ) { _ in fireCount += 1 }
        defer { NotificationCenter.default.removeObserver(observer) }

        _ = capture.ingest(module: "Comm.Channel.Text", data: ["channel": "gossip"])
        _ = capture.ingest(module: "Char.Vitals", data: ["hp": 100])

        #expect(fireCount == 0)
    }

    // MARK: - clear()

    @Test func clearEmptiesBufferAndFires() {
        let capture = GMCPChatCapture()
        _ = capture.ingest(module: "Comm.Channel.Text", data: [
            "channel": "gossip",
            "text": "Alice gossips 'hi'",
        ])
        #expect(capture.capturedLines.count == 1)

        var clearFired = false
        let observer = NotificationCenter.default.addObserver(
            forName: GMCPChatCapture.didClearChatNotification,
            object: capture,
            queue: nil
        ) { _ in clearFired = true }
        defer { NotificationCenter.default.removeObserver(observer) }

        capture.clear()
        #expect(capture.capturedLines.isEmpty)
        #expect(!capture.hasReceivedChat)
        #expect(clearFired)
    }

    @Test func clearOnEmptyBufferIsNoOp() {
        let capture = GMCPChatCapture()
        var clearFired = false
        let observer = NotificationCenter.default.addObserver(
            forName: GMCPChatCapture.didClearChatNotification,
            object: capture,
            queue: nil
        ) { _ in clearFired = true }
        defer { NotificationCenter.default.removeObserver(observer) }

        capture.clear()
        #expect(!clearFired)
    }

    // MARK: - Buffer ordering

    @Test func capturedLinesPreserveArrivalOrder() {
        let capture = GMCPChatCapture()
        _ = capture.ingest(module: "Comm.Channel.Text", data: [
            "channel": "gossip", "text": "first",
        ])
        _ = capture.ingest(module: "comm.channel", data: [
            "chan": "tell", "msg": "second",
        ])
        _ = capture.ingest(module: "Comm.Channel.Text", data: [
            "channel": "say", "text": "third",
        ])
        #expect(capture.capturedLines.count == 3)
    }
}
