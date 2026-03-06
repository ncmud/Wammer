// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "DAKeyboardControl",
    platforms: [.iOS(.v26)],
    products: [.library(name: "DAKeyboardControl", targets: ["DAKeyboardControl"])],
    targets: [
        .target(
            name: "DAKeyboardControl",
            path: "Sources",
            publicHeadersPath: "include"
        )
    ]
)
