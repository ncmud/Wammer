import UIKit
import UserNotifications

@objc(WammerSceneDelegate)
class WammerSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .black
        window.rootViewController = SSClientContainer()
        window.makeKeyAndVisible()
        self.window = window

        for urlContext in connectionOptions.urlContexts {
            handleURL(urlContext.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for urlContext in URLContexts {
            handleURL(urlContext.url)
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        SSRadialControl.validateRadialPositions()
    }

    private func handleURL(_ url: URL) {
        guard url.scheme == "telnet", let host = url.host?.lowercased() else { return }

        var existingIdentifier: String?
        for world in WorldStoreBridge.allWorlds() {
            guard let w = world as? MUDWorldBridge else { continue }
            if w.hostname == host {
                existingIdentifier = w.identifier
                break
            }
        }

        if existingIdentifier == nil {
            let port = Int16(url.port ?? 23)
            WorldStoreBridge.addWorld(hostname: host, name: "", port: port)

            for world in WorldStoreBridge.allWorlds() {
                guard let w = world as? MUDWorldBridge else { continue }
                if w.hostname == host {
                    existingIdentifier = w.identifier
                    break
                }
            }
        }

        if let identifier = existingIdentifier {
            NotificationCenter.default.post(name: NSNotification.Name(kNotificationWorldChanged),
                                            object: identifier)
        }
    }
}
