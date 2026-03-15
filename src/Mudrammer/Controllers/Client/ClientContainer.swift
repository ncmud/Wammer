import UIKit

@objc(SSClientContainer)
@objcMembers
class ClientContainer: UISplitViewController {

    // MARK: - Properties

    private var _worldDisplay: SSWorldDisplayController?

    override var worldDisplay: SSWorldDisplayController? {
        _worldDisplay
    }

    // MARK: - Init

    override init(style: UISplitViewController.Style = .doubleColumn) {
        super.init(style: .doubleColumn)
        commonInit()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(style: .doubleColumn)
        commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func commonInit() {
        #if os(visionOS)
        preferredDisplayMode = .secondaryOnly
        preferredSplitBehavior = .tile
        #else
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .overlay
        presentsWithGesture = true
        displayModeButtonVisibility = .automatic
        #endif
        preferredPrimaryColumnWidth = 220
        minimumPrimaryColumnWidth = 220
        maximumPrimaryColumnWidth = 280

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(urlTapped(_:)),
            name: NSNotification.Name(kNotificationURLTapped),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(selectedWorldDidChange(_:)),
            name: NSNotification.Name(kNotificationWorldChanged),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let displayController = SSWorldDisplayController()
        _worldDisplay = displayController
        setViewController(displayController, for: .primary)
        displayController.addClient(withWorld: nil)

        // addClient calls setDetailViewController via [self clientContainer],
        // but the parent chain may not be wired yet during viewDidLoad.
        // Explicitly set the secondary to ensure it's visible.
        if let selectedVC = displayController.selectedViewController {
            setDetailViewController(selectedVC)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            if !UserDefaults.standard.bool(forKey: kPrefInitialSetupComplete) {
                let welcome = SSWelcomeViewController()
                welcome.modalPresentationStyle = .fullScreen
                self.present(welcome, animated: false)
            }
        }
    }

    // MARK: - Notifications

    @objc private func urlTapped(_ notification: Notification) {
        guard let url = notification.object as? URL else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self, let worldDisplay = self._worldDisplay else { return }
            if url.scheme == "mailto" {
                UIApplication.shared.open(url)
            } else {
                guard let webView = SPLHandoffWebViewController(url: url) else { return }
                worldDisplay.currentVisibleClient?.hideKeyboard()
                worldDisplay.currentVisibleClient?.present(webView, animated: true)
            }
        }
    }

    @objc private func selectedWorldDidChange(_ notification: Notification) {
        guard let worldIdentifier = notification.object as? String else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self, let worldDisplay = self._worldDisplay else { return }
            guard WorldStoreBridge.world(forIdentifier: worldIdentifier) != nil else { return }

            let currentClient = worldDisplay.selectedIndex

            let worldChangeBlock: () -> Void = {
                worldDisplay.client(at: currentClient)?.updateCurrentWorld(
                    worldIdentifier,
                    connectAfterUpdate: true
                )
            }

            if let client = worldDisplay.currentVisibleClient, client.isConnected {
                let desc = WorldStoreBridge.worldDescription(forIdentifier: worldIdentifier)
                SPLAlerts.splShowAlertView(
                    withTitle: String(format: NSLocalizedString("CONNECTING_TO_%@", comment: ""), desc ?? worldIdentifier),
                    message: String(format: NSLocalizedString("DISCONNECT_FROM_%@", comment: "Disconnect from"), client.hostname ?? ""),
                    cancelTitle: NSLocalizedString("CANCEL", comment: "Cancel"),
                    cancel: nil,
                    okTitle: NSLocalizedString("CONNECT", comment: "Connect"),
                    okBlock: worldChangeBlock,
                    presenting: self
                )
            } else {
                worldChangeBlock()
            }
        }
    }

    // MARK: - Panel management

    @objc(closeDrawerAnimated:)
    func closeDrawer(animated: Bool) {
        if isCollapsed {
            show(.secondary)
        } else {
            hide(.primary)
        }
    }

    @objc(showSidebarAnimated:)
    func showSidebar(animated: Bool) {
        show(.primary)
    }

    @objc func toggleSidebar() {
        if isCollapsed {
            show(.primary)
            return
        }
        #if os(visionOS)
        let shouldHide = displayMode == .oneBesideSecondary
        #else
        let shouldHide = displayMode == .oneBesideSecondary || displayMode == .oneOverSecondary
        #endif
        if shouldHide {
            hide(.primary)
        } else {
            show(.primary)
        }
    }

    @objc func setDetailViewController(_ viewController: UIViewController) {
        setViewController(viewController, for: .secondary)
    }

    // MARK: - Rotation

    override var shouldAutorotate: Bool {
        true
    }

    // MARK: - Mac Catalyst Menu Bar

    #if targetEnvironment(macCatalyst) || os(visionOS)
    override func buildMenu(with builder: any UIMenuBuilder) {
        super.buildMenu(with: builder)

        guard builder.system == UIMenuSystem.main else { return }

        builder.remove(menu: .format)

        let newWindowCommand = UIKeyCommand(
            title: NSLocalizedString("NEW_WINDOW", comment: "New Window"),
            action: #selector(menuNewWindow(_:)),
            input: "n",
            modifierFlags: .command
        )
        let newWindowMenu = UIMenu(title: "", options: .displayInline, children: [newWindowCommand])
        builder.insertChild(newWindowMenu, atStartOfMenu: .file)

        let reconnectCommand = UIKeyCommand(
            title: NSLocalizedString("RECONNECT", comment: "Reconnect"),
            action: #selector(menuReconnect(_:)),
            input: "r",
            modifierFlags: .command
        )
        let disconnectCommand = UIKeyCommand(
            title: NSLocalizedString("DISCONNECT", comment: "Disconnect"),
            action: #selector(menuDisconnect(_:)),
            input: "w",
            modifierFlags: .command
        )
        let cycleCommand = UIKeyCommand(
            title: NSLocalizedString("CYCLE_CONNECTIONS", comment: "Next Connection"),
            action: #selector(menuCycleConnections(_:)),
            input: "]",
            modifierFlags: .command
        )
        let clearCommand = UIKeyCommand(
            title: NSLocalizedString("CLEAR_SCREEN", comment: "Clear Screen"),
            action: #selector(menuClearScreen(_:)),
            input: "k",
            modifierFlags: .command
        )

        let connectionMenu = UIMenu(
            title: NSLocalizedString("CONNECTION", comment: "Connection"),
            children: [reconnectCommand, disconnectCommand, cycleCommand, clearCommand]
        )
        builder.insertSibling(connectionMenu, afterMenu: .file)

        let worldListCommand = UIKeyCommand(
            title: NSLocalizedString("WORLD_LIST", comment: "World List"),
            action: #selector(menuShowWorldList(_:)),
            input: "l",
            modifierFlags: .command
        )
        let worldListMenu = UIMenu(title: "", options: .displayInline, children: [worldListCommand])
        builder.insertChild(worldListMenu, atEndOfMenu: .file)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        let connected = worldDisplay?.currentVisibleClient?.isConnected ?? false

        if action == #selector(menuReconnect(_:)) {
            return !connected
        }
        if action == #selector(menuDisconnect(_:)) {
            return connected
        }
        if action == #selector(menuNewWindow(_:))
            || action == #selector(menuCycleConnections(_:))
            || action == #selector(menuClearScreen(_:))
            || action == #selector(menuShowWorldList(_:)) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }

    @objc func menuNewWindow(_ sender: Any) {
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: nil)
    }

    @objc func menuReconnect(_ sender: Any) {
        worldDisplay?.currentVisibleClient?.connect()
    }

    @objc func menuDisconnect(_ sender: Any) {
        worldDisplay?.currentVisibleClient?.disconnect()
    }

    @objc func menuCycleConnections(_ sender: Any) {
        worldDisplay?.selectNextWorld()
    }

    @objc func menuClearScreen(_ sender: Any) {
        worldDisplay?.currentVisibleClient?.clearText()
    }

    @objc func menuShowWorldList(_ sender: Any) {
        toggleSidebar()
    }
    #endif
}
