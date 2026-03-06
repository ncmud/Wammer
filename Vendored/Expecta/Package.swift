// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "Expecta",
    platforms: [.iOS(.v26)],
    products: [.library(name: "Expecta", targets: ["Expecta"])],
    targets: [
        .target(
            name: "Expecta",
            path: "Sources",
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags(["-fno-objc-arc"])
            ]
        )
    ]
)
