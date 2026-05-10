import UIKit
import CocoaAsyncSocket
import MTHClient

@objc(SSMUDSocket) @objcMembers
final class SSMUDSocket: NSObject, GCDAsyncSocketDelegate {

    weak var delegate: SSMUDSocketDelegate?

    private let socket: GCDAsyncSocket
    private var telnetSession: TelnetClientSession?
    private let stringCoder = SSStringCoder()
    private let ansiEngine = SSANSIEngine()
    private var dataCache = ""
    private let parsingQueue = OperationQueue.ss_serial()!

    @objc var isSecure = false

    private var dedup = NAWSDeduplicator()
    private let dedupLock = NSLock()
    private var pendingInitialCharSize = CGSize(width: 80, height: 24)

    @objc var shouldEchoText: Bool {
        guard let session = telnetSession else { return true }
        return !session.serverEcho
    }

    // MARK: - Init

    @objc init(socket: GCDAsyncSocket) {
        self.socket = socket
        super.init()
        self.socket.setDelegate(self, delegateQueue: DispatchQueue.global(qos: .default))
    }

    deinit {
        parsingQueue.cancelAllOperations()
        socket.setDelegate(nil, delegateQueue: nil)
        delegate = nil
        socket.disconnect()
    }

    // MARK: - Connection Lifecycle

    @objc func connect(toHostname hostname: String, onPort port: UInt, error: NSErrorPointer) -> Bool {
        // Pull the current cell-grid from the delegate (on the caller's thread,
        // expected to be main) so the initial NAWS subnegotiation reflects the
        // real terminal size and not an 80x24 placeholder.
        if let pulled = delegate?.mudsocketCurrentCharSize?(self),
           pulled.width.isFinite, pulled.height.isFinite,
           pulled.width >= 1, pulled.height >= 1 {
            pendingInitialCharSize = pulled
            #if DEBUG
            NSLog("NAWS: pulled initial char size from delegate: %dx%d",
                  Int(pulled.width), Int(pulled.height))
            #endif
        } else {
            #if DEBUG
            NSLog("NAWS: delegate returned no usable char size; falling back to %dx%d",
                  Int(pendingInitialCharSize.width), Int(pendingInitialCharSize.height))
            #endif
        }

        resetDedup()

        do {
            try socket.connect(toHost: hostname, onPort: UInt16(port), withTimeout: 30)
            return true
        } catch let err as NSError {
            error?.pointee = err
            return false
        } catch {
            return false
        }
    }

    @objc func isDisconnected() -> Bool {
        socket.isDisconnected()
    }

    @objc func disconnect() {
        socket.disconnect()
    }

    @objc func resetSocket() {
        socket.setDelegate(nil, delegateQueue: nil)
    }

    // MARK: - Send

    @objc func sendUserCommands(_ commands: [Any]) {
        guard socket.isConnected() else { return }
        ansiEngine.defaultTextColor = SSThemes.sharedThemer().value(forThemeKey: kThemeFontColor) as? UIColor
        let data = stringCoder.data(forUserCommands: commands)!
        socket.write(data, withTimeout: -1, tag: 0)
    }

    @objc(sendNAWSWithSize:) func sendNAWS(with size: CGSize) {
        guard size.width.isFinite, size.height.isFinite,
              size.width >= 1, size.height >= 1 else {
            #if DEBUG
            NSLog("NAWS: rejected request with invalid size %@", NSCoder.string(for: size))
            #endif
            return
        }
        let cols = Int(size.width)
        let rows = Int(size.height)

        let shouldSend: Bool = {
            dedupLock.lock()
            defer { dedupLock.unlock() }
            return dedup.shouldSend(cols: cols, rows: rows)
        }()
        guard shouldSend else {
            #if DEBUG
            NSLog("NAWS: dedup suppressed %dx%d (matches last sent)", cols, rows)
            #endif
            return
        }

        #if DEBUG
        let connected = telnetSession != nil
        NSLog("NAWS: sending %dx%d (telnetSession=%@)",
              cols, rows, connected ? "active" : "nil")
        #endif
        telnetSession?.sendWindowSize(width: cols, height: rows)
    }

    private func resetDedup() {
        dedupLock.lock()
        dedup.reset()
        dedupLock.unlock()
    }

    private func seedDedup(cols: Int, rows: Int) {
        dedupLock.lock()
        _ = dedup.shouldSend(cols: cols, rows: rows)
        dedupLock.unlock()
    }

    // MARK: - GCDAsyncSocketDelegate

    func socketDidSecure(_ sock: GCDAsyncSocket) {
        let secureLine = SSAttributedLineGroup(
            attributedString: NSAttributedString.worldString(for: NSLocalizedString("SSL_SUCCESS", comment: ""))
        )!
        let del = delegate
        DispatchQueue.main.async {
            del?.mudsocket(self, didReceive: secureLine)
        }
    }

    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        let initialWidth = max(1, Int(pendingInitialCharSize.width))
        let initialHeight = max(1, Int(pendingInitialCharSize.height))

        telnetSession = TelnetClientSession(
            delegate: self,
            terminalType: "Wammer",
            windowWidth: initialWidth,
            windowHeight: initialHeight,
            mttsFlags: 271
        )

        // Seed the dedup so a redundant sendNAWS from the first viewDidLayoutSubviews
        // (which often matches the size we just baked into the session) is suppressed.
        seedDedup(cols: initialWidth, rows: initialHeight)

        #if DEBUG
        NSLog("NAWS: connected to %@:%d, initial telnet window baked to %dx%d (dedup seeded)",
              host, port, initialWidth, initialHeight)
        #endif

        ansiEngine.defaultTextColor = SSThemes.sharedThemer().value(forThemeKey: kThemeFontColor) as? UIColor
        dataCache = ""

        if isSecure {
            sock.startTLS([
                kCFStreamSSLValidatesCertificateChain as String: false as NSNumber,
                GCDAsyncSocketSSLProtocolVersionMin: NSNumber(value: tls_protocol_version_t.TLSv12.rawValue),
            ])
        }

        let del = delegate
        if del?.responds(to: #selector(SSMUDSocketDelegate.mudsocketDidConnect(toHost:))) == true {
            DispatchQueue.global(qos: .default).async {
                del?.mudsocketDidConnect?(toHost: self)
            }
        }

        sock.readData(withTimeout: -1, tag: 0)
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: (any Error)?) {
        parsingQueue.ss_addBlockOperation { [weak self] _ in
            guard let self else { return }
            self.telnetSession = nil
            self.resetDedup()
            let del = self.delegate
            if del?.responds(to: #selector(SSMUDSocketDelegate.mudsocket(_:didDisconnectWithError:))) == true {
                DispatchQueue.global(qos: .default).async {
                    del?.mudsocket?(self, didDisconnectWithError: err as NSError?)
                }
            }
        }
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        parsingQueue.ss_addBlockOperation { [weak self] operation in
            guard let self, !(operation?.isCancelled ?? true) else { return }

            let bytes = [UInt8](data)
            guard let session = self.telnetSession else { return }

            let cleanBytes = session.processInput(bytes)

            if !cleanBytes.isEmpty {
                let cleanData = Data(cleanBytes)
                let string = self.stringCoder.stringByDecodingData(withCurrentEncoding: cleanData) ?? ""
                self.processReceivedString(string, operation: operation)
            }
        }

        sock.readData(withTimeout: -1, tag: 0)
    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
    }

    // MARK: - String Processing

    private func processReceivedString(_ string: String, operation: SSBlockOperation?) {
        guard !string.isEmpty, !(operation?.isCancelled ?? true) else { return }

        let fullStr = stringBySplittingAndCachingString(string)

        guard !fullStr.isEmpty, !(operation?.isCancelled ?? true) else { return }

        let group = ansiEngine.parseANSIString(fullStr)!

        guard !(operation?.isCancelled ?? true) else { return }

        let del = delegate
        DispatchQueue.main.async {
            del?.mudsocket(self, didReceive: group)
        }
    }

    private func stringBySplittingAndCachingString(_ string: String) -> String {
        var fullStr = ""

        if !dataCache.isEmpty {
            fullStr.append(dataCache)
            dataCache = ""
        }

        fullStr.append(string)

        guard !fullStr.isEmpty else { return "" }

        let searchStr = String(kANSIEscapeCSI.prefix(1))
        guard let csiRange = fullStr.range(of: searchStr, options: .backwards) else {
            return fullStr
        }

        let searchRange = csiRange.lowerBound..<fullStr.endIndex
        let terminationSet = NSCharacterSet.csiTermination() as CharacterSet
        if fullStr.rangeOfCharacter(from: terminationSet, range: searchRange) == nil {
            dataCache = String(fullStr[csiRange.lowerBound...])
            fullStr = String(fullStr[..<csiRange.lowerBound])
        }

        return fullStr
    }
}

// MARK: - TelnetClientDelegate

extension SSMUDSocket: TelnetClientDelegate {

    func write(data: [UInt8]) {
        socket.write(Data(data), withTimeout: -1, tag: 0)
    }

    func onLocalEchoChanged(enabled: Bool) {
        // shouldEchoText is computed from telnetSession.serverEcho
    }

    func onGMCPNegotiated() {
        telnetSession?.sendGMCP(
            module: "Core.Hello",
            json: #"{"client":"Wammer","version":"\#(Bundle.main.appVersion)"}"#
        )
    }

    func onGMCPReceived(module: String, json: String) {
        var payload: [AnyHashable: Any] = [:]
        if !json.isEmpty, let jsonData = json.data(using: .utf8) {
            if let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [AnyHashable: Any] {
                payload = parsed
            }
        }
        let del = delegate
        if del?.responds(to: #selector(SSMUDSocketDelegate.mudsocket(_:receivedGMCPModule:data:))) == true {
            DispatchQueue.main.async {
                del?.mudsocket?(self, receivedGMCPModule: module, data: payload)
            }
        }
    }

    func onMSDPVariable(name: String, value: String) {
    }

    func onMSSPReceived(data: [String: String]) {
        let del = delegate
        if del?.responds(to: #selector(SSMUDSocketDelegate.mudsocket(_:receivedMSSPData:))) == true {
            DispatchQueue.main.async {
                del?.mudsocket?(self, receivedMSSPData: data as [AnyHashable: Any])
            }
        }
    }

    func onPromptReceived() {
        guard !dataCache.isEmpty else { return }
        let prompt = dataCache
        dataCache = ""

        let group = ansiEngine.parseANSIString(prompt)!
        let del = delegate
        DispatchQueue.main.async {
            del?.mudsocket(self, didReceive: group)
        }
    }

    func onBellReceived() {
    }

    func log(message: String) {
        #if DEBUG
        NSLog("MTH: %@", message)
        #endif
    }
}
