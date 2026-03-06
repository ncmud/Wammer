// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "JASidePanels",
    platforms: [.iOS(.v26)],
    products: [.library(name: "JASidePanels", targets: ["JASidePanels"])],
    targets: [
        .target(
            name: "JASidePanels",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [.unsafeFlags(["-w"])]
        )
    ]
)
