import UIKit

@objc(SSMusicPickerViewController)
@objcMembers
class SSMusicPickerViewController: UITableViewController {

    var gmcpHandler: GMCPHandler?
    var currentWorldIdentifier: String?

    private var tracks: [[String: String]] = []

    init() {
        super.init(style: .plain)
        title = NSLocalizedString("BACKGROUND_MUSIC", comment: "")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        SSThemes.configureTable(tableView)
        tracks = MusicLibrary.shared.musicTrackDictionaries

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissPicker)
        )
    }

    @objc private func dismissPicker() {
        dismiss(animated: true)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(tracks.count, 1)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "TrackCell")
        SSThemes.configureCell(cell)

        if tracks.isEmpty {
            cell.textLabel?.text = NSLocalizedString("NO_MUSIC_TRACKS", comment: "")
            cell.textLabel?.textColor = cell.textLabel?.textColor.withAlphaComponent(0.6)
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = nil
            cell.imageView?.image = nil
            cell.selectionStyle = .none
        } else {
            let track = tracks[indexPath.row]
            cell.textLabel?.text = track["filename"]
            cell.textLabel?.numberOfLines = 1
            cell.detailTextLabel?.text = track["hostname"]
            cell.imageView?.image = UIImage(systemName: "music.note")
            cell.selectionStyle = .default
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !tracks.isEmpty else { return }

        let track = tracks[indexPath.row]
        guard let path = track["relativePath"] else { return }
        gmcpHandler?.startAmbient(relativePath: path)

        if let identifier = currentWorldIdentifier,
           let world = WorldStoreBridge.mudWorld(forIdentifier: identifier) {
            world.ambientMusicPath = path
            WorldStoreBridge.updateMUDWorld(world)
        }
        dismiss(animated: true)
    }
}
