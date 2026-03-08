import UIKit

extension UIViewController {
    /// Walk the parent/presenting chain to find the nearest ClientContainer.
    @objc var clientContainer: ClientContainer? {
        var vc: UIViewController? = self
        while let current = vc {
            if let container = current as? ClientContainer {
                return container
            }
            vc = current.parent ?? current.presentingViewController
        }

        // Fallback: walk from the window's root
        if let root = view.window?.rootViewController as? ClientContainer {
            return root
        }

        return nil
    }

    /// Shortcut for self.clientContainer.worldDisplay.
    @objc var worldDisplay: SSWorldDisplayController? {
        clientContainer?.worldDisplay
    }
}
