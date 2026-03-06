// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "TOWebViewController",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [.library(name: "TOWebViewController", targets: ["TOWebViewController"])],
    targets: [
        .target(
            name: "TOWebViewController",
            path: "Sources",
            resources: [.process("Resources")],
            publicHeadersPath: "include"
        )
    ]
)
