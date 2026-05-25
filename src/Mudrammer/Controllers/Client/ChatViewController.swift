import UIKit

/// Read-only viewer for chat lines captured from GMCP `Comm.Channel.*` packets.
/// Presented as a sheet from `SSClientViewController` once the connected MUD has
/// emitted at least one chat packet on this session.
@objc(ChatViewController)
final class ChatViewController: UIViewController {

    private let chatCapture: GMCPChatCapture
    private let tableView: SSTextTableView
    private let dataSource: SPLTerminalDataSource

    @objc init(chatCapture: GMCPChatCapture) {
        self.chatCapture = chatCapture
        self.tableView = SSTextTableView(frame: .zero)
        self.dataSource = SPLTerminalDataSource(items: nil)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Present the chat log as a sheet (medium/large detents) wrapped in a navigation controller.
    /// visionOS uses its own modal presentation style and does not support `UISheetPresentationController` detents.
    @objc static func presentSheet(from presenter: UIViewController, chatCapture: GMCPChatCapture) {
        let vc = ChatViewController(chatCapture: chatCapture)
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        #if !os(visionOS)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.selectedDetentIdentifier = .medium
        }
        #endif
        presenter.present(nav, animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        dataSource.tableView = nil
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("CHAT_LOG_TITLE", comment: "Chat log nav title")

        applyThemeBackground()
        configureTableView()
        configureDataSource()
        configureNavigationItem()

        // Seed with anything already captured before the view was opened.
        if !chatCapture.capturedLines.isEmpty {
            for group in chatCapture.capturedLines {
                dataSource.append(group)
            }
            scrollToBottomSoon()
        }

        let nc = NotificationCenter.default
        nc.addObserver(
            self,
            selector: #selector(chatCaptureDidCapture(_:)),
            name: GMCPChatCapture.didCaptureChatNotification,
            object: chatCapture
        )
        nc.addObserver(
            self,
            selector: #selector(chatCaptureDidClear(_:)),
            name: GMCPChatCapture.didClearChatNotification,
            object: chatCapture
        )
    }

    // MARK: - Setup

    private func configureTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureDataSource() {
        dataSource.cellClass = SSTextViewCell.self
        dataSource.rowAnimation = .none
        dataSource.tableActionBlock = { _, _, _ in false }
        dataSource.cellConfigureBlock = { cell, line, _, _ in
            guard let cell = cell as? SSTextViewCell,
                  let line = line as? SSAttributedLineGroupItem else {
                return
            }
            if let linkColor = SSThemes.sharedThemer().value(forThemeKey: kThemeLinkColor) as? UIColor {
                cell.textView.linkAttributes = [
                    kCTForegroundColorAttributeName as String: linkColor.cgColor,
                ]
            }
            if let fontColor = SSThemes.sharedThemer().value(forThemeKey: kThemeFontColor) as? UIColor {
                cell.textView.activeLinkAttributes = [
                    kCTForegroundColorAttributeName as String: fontColor.cgColor,
                ]
            }
            if let text = line.line, text.length > 0 {
                cell.textView.text = text
                cell.textView.accessibilityLabel = text.string
            } else {
                cell.textView.text = nil
                cell.textView.accessibilityLabel = nil
            }
        }
        dataSource.tableView = tableView
    }

    private func configureNavigationItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("CHAT_LOG_CLEAR", comment: "Clear chat log"),
            style: .plain,
            target: self,
            action: #selector(clearTapped)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
    }

    private func applyThemeBackground() {
        if let bg = SSThemes.sharedThemer().value(forThemeKey: kThemeBackgroundColor) as? UIColor {
            view.backgroundColor = bg
            tableView.backgroundColor = bg
        }
    }

    // MARK: - Notifications

    @objc private func chatCaptureDidCapture(_ notification: Notification) {
        guard let group = notification.userInfo?[GMCPChatCapture.lineGroupUserInfoKey] as? SSAttributedLineGroup else {
            return
        }
        let wasNearBottom = tableView.isNearBottom
        dataSource.append(group)
        if wasNearBottom {
            scrollToBottomSoon()
        }
    }

    @objc private func chatCaptureDidClear(_ notification: Notification) {
        dataSource.clearItems()
    }

    // MARK: - Actions

    @objc private func clearTapped() {
        chatCapture.clear()
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }

    // MARK: - Helpers

    private func scrollToBottomSoon() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToBottom()
        }
    }
}
