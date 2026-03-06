// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "SPLUserActivity",
    platforms: [.iOS(.v26)],
    products: [.library(name: "SPLUserActivity", targets: ["SPLUserActivity"])],
    targets: [
        .target(
            name: "SPLUserActivity",
            path: "Sources",
            publicHeadersPath: "include"
        )
    ]
)
