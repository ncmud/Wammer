import UIKit
import UserNotifications

@objc(WammerSceneDelegate)
class WammerSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    #if !os(visionOS)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    #endif

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .black
        window.rootViewController = ClientContainer()
        window.makeKeyAndVisible()
        self.window = window

        #if os(visionOS)
        let prefs = UIWindowScene.GeometryPreferences.Vision(size: CGSize(width: 1280, height: 960))
        windowScene.requestGeometryUpdate(prefs)
        #endif

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

    func sceneDidEnterBackground(_ scene: UIScene) {
        #if !os(visionOS)
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        #endif
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        #if !os(visionOS)
        endBackgroundTask()
        #endif
    }

    #if !os(visionOS)
    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
    #endif

    private func handleURL(_ url: URL) {
        guard url.scheme == "telnet", let host = url.host?.lowercased() else { return }

        var existingIdentifier = WorldStoreBridge.allWorlds()
            .first(where: { $0.hostname == host })?.identifier

        if existingIdentifier == nil {
            let port = Int16(url.port ?? 23)
            WorldStoreBridge.addWorld(hostname: host, name: "", port: port)

            existingIdentifier = WorldStoreBridge.allWorlds()
                .first(where: { $0.hostname == host })?.identifier
        }

        if let identifier = existingIdentifier {
            NotificationCenter.default.post(name: NSNotification.Name(kNotificationWorldChanged),
                                            object: identifier)
        }
    }
}
