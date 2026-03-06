// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "QuickDialog",
    platforms: [.iOS(.v26)],
    products: [.library(name: "QuickDialog", targets: ["QuickDialog"])],
    targets: [
        .target(
            name: "QuickDialog",
            path: "Sources",
            publicHeadersPath: "include"
        )
    ]
)
