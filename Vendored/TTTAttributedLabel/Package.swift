// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "TTTAttributedLabel",
    platforms: [.iOS(.v26)],
    products: [.library(name: "TTTAttributedLabel", targets: ["TTTAttributedLabel"])],
    targets: [
        .target(
            name: "TTTAttributedLabel",
            path: "Sources",
            publicHeadersPath: "include"
        )
    ]
)
