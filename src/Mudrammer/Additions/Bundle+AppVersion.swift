import Foundation

extension Bundle {
    @objc var appVersion: String {
        let short = infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(short).\(build)"
    }
}
